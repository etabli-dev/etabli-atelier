#!/usr/bin/env python3
import hashlib
import io
import json
from pathlib import Path
import tempfile
import tarfile
import unittest
import zipfile
import fetch_runtimes as runtimes

class RuntimePreparationTests(unittest.TestCase):
    def test_cache_integrity_and_offline_missing(self):
        with tempfile.TemporaryDirectory() as temporary:
            cache = Path(temporary)
            item = {'name': 'input', 'sha256': hashlib.sha256(b'good').hexdigest()}
            with self.assertRaises(FileNotFoundError): runtimes.fetch(item, cache, offline=True)
            (cache / 'input').write_bytes(b'bad')
            with self.assertRaises(ValueError): runtimes.fetch(item, cache, offline=True)
            (cache / 'input').write_bytes(b'good')
            self.assertEqual(runtimes.fetch(item, cache, offline=True), cache / 'input')

    def test_archive_traversal_rejected_before_output(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            artifact = root / 'webr.zip'
            with zipfile.ZipFile(artifact, 'w') as archive:
                archive.writestr('../escape', b'bad')
            with self.assertRaises(ValueError):
                runtimes.prepare({}, {'webr-0.6.0.zip': artifact}, root / 'staging')
            self.assertFalse((root / 'escape').exists())

    def miniature_inputs(self, root, corrupt_openblas=False):
        cached = {}
        for name in ['webr-LICENSE.md', 'shinylive-LICENSE.txt', 'pyodide-LICENSE.txt']:
            cached[name] = root / name
            cached[name].write_bytes(b'license')
        cached['webr-0.6.0.zip'] = root / 'webr.zip'
        with zipfile.ZipFile(cached['webr-0.6.0.zip'], 'w') as archive:
            archive.writestr('webr-0.6.0/webr.mjs', b'R loader')
        contents = {
            'scipy.whl': b'scipy', 'openblas.zip': b'openblas',
            'unrelated.whl': b'unrelated wheel', 'gdal.zip': b'unrelated library',
            'pyodide.mjs': b'loader', 'pyodide.asm.wasm': b'wasm',
            'python_stdlib.zip': b'stdlib', 'fonts/LICENSE': b'font license',
            'not-in-lock.whl': b'unlisted wheel',
        }
        package_lock = {'info': {'version': '0.27.7'}, 'packages': {}}
        for name, filename, dependencies in [
            ('scipy', 'scipy.whl', ['openblas']), ('openblas', 'openblas.zip', []),
            ('unrelated', 'unrelated.whl', []), ('gdal', 'gdal.zip', []),
        ]:
            package_lock['packages'][name] = {
                'file_name': filename, 'depends': dependencies,
                'sha256': hashlib.sha256(contents[filename]).hexdigest(),
            }
        contents['pyodide-lock.json'] = json.dumps(package_lock).encode()
        if corrupt_openblas:
            contents['openblas.zip'] = b'corrupted library'
        cached['shinylive-0.10.12.tar.gz'] = root / 'shinylive.tar.gz'
        with tarfile.open(cached['shinylive-0.10.12.tar.gz'], 'w:gz') as archive:
            for name, data in contents.items():
                info = tarfile.TarInfo('shinylive-0.10.12/shinylive/pyodide/' + name)
                info.size = len(data)
                archive.addfile(info, io.BytesIO(data))
        return {'application': 'atelier', 'python_packages': ['scipy']}, cached

    def test_prepare_selects_required_library_and_omits_unrelated_payloads(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            lock, cached = self.miniature_inputs(root)
            assets = runtimes.prepare(lock, cached, root / 'stage')
            pyodide = assets / 'runtimes/pyodide'
            self.assertEqual((pyodide / 'openblas.zip').read_bytes(), b'openblas')
            self.assertEqual((pyodide / 'scipy.whl').read_bytes(), b'scipy')
            self.assertFalse((pyodide / 'gdal.zip').exists())
            self.assertFalse((pyodide / 'unrelated.whl').exists())
            self.assertFalse((pyodide / 'not-in-lock.whl').exists())
            self.assertEqual((pyodide / 'python_stdlib.zip').read_bytes(), b'stdlib')
            self.assertEqual((pyodide / 'fonts/LICENSE').read_bytes(), b'font license')
            self.assertEqual((assets / 'runtimes/webr/webr.mjs').read_bytes(), b'R loader')

    def test_prepare_rejects_corrupt_required_library(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            lock, cached = self.miniature_inputs(root, corrupt_openblas=True)
            with self.assertRaisesRegex(ValueError, 'Package hash mismatch: openblas.zip'):
                runtimes.prepare(lock, cached, root / 'stage')

    def test_publish_removes_only_receipted_unchanged_excluded_payload(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            lock, cached = self.miniature_inputs(root)
            assets = runtimes.prepare(lock, cached, root / 'stage')
            repo = root / 'repo'
            old = repo / 'assets/runtimes/pyodide'
            old.mkdir(parents=True)
            (old / 'gdal.zip').write_bytes(b'old generated library')
            (old / 'personal.txt').write_bytes(b'preserved user file')
            (repo / 'tool').mkdir()
            (repo / 'tool/runtimes.prepared.json').write_text(json.dumps({'files': {
                'runtimes/pyodide/gdal.zip': runtimes.digest(old / 'gdal.zip'),
            }}))
            receipt = runtimes.publish_assets(assets, repo)
            self.assertFalse((old / 'gdal.zip').exists())
            self.assertEqual((old / 'personal.txt').read_bytes(), b'preserved user file')
            self.assertEqual((old / 'openblas.zip').read_bytes(), b'openblas')
            self.assertNotIn('runtimes/pyodide/gdal.zip', receipt)
            self.assertIn('runtimes/pyodide/openblas.zip', receipt)

    def test_publish_aborts_before_changes_when_excluded_payload_was_modified(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            lock, cached = self.miniature_inputs(root)
            assets = runtimes.prepare(lock, cached, root / 'stage')
            repo = root / 'repo'
            old = repo / 'assets/runtimes/pyodide'
            old.mkdir(parents=True)
            (old / 'gdal.zip').write_bytes(b'local changes')
            (old / 'pyodide.mjs').write_bytes(b'old loader')
            (repo / 'tool').mkdir()
            (repo / 'tool/runtimes.prepared.json').write_text(json.dumps({'files': {
                'runtimes/pyodide/gdal.zip': hashlib.sha256(b'original').hexdigest(),
            }}))
            with self.assertRaisesRegex(ValueError, 'modified or untracked'):
                runtimes.publish_assets(assets, repo)
            self.assertEqual((old / 'gdal.zip').read_bytes(), b'local changes')
            self.assertEqual((old / 'pyodide.mjs').read_bytes(), b'old loader')
            self.assertFalse((old / 'openblas.zip').exists())

    def test_publish_rejects_symlinked_parent_before_copy_or_cleanup(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            lock, cached = self.miniature_inputs(root)
            assets = runtimes.prepare(lock, cached, root / 'stage')
            repo = root / 'repo'
            (repo / 'assets/runtimes').mkdir(parents=True)
            outside = root / 'outside'
            outside.mkdir()
            (outside / 'gdal.zip').write_bytes(b'outside sentinel')
            (outside / 'pyodide.mjs').write_bytes(b'outside loader')
            (repo / 'assets/runtimes/pyodide').symlink_to(outside, target_is_directory=True)
            (repo / 'tool').mkdir()
            (repo / 'tool/runtimes.prepared.json').write_text(json.dumps({'files': {
                'runtimes/pyodide/gdal.zip': runtimes.digest(outside / 'gdal.zip'),
            }}))
            with self.assertRaisesRegex(ValueError, 'contains a symlink'):
                runtimes.publish_assets(assets, repo)
            self.assertEqual((outside / 'gdal.zip').read_bytes(), b'outside sentinel')
            self.assertEqual((outside / 'pyodide.mjs').read_bytes(), b'outside loader')
            self.assertFalse((outside / 'openblas.zip').exists())
            self.assertFalse((repo / 'assets/runtimes/webr').exists())

    def test_safe_paths_and_deterministic_output(self):
        for path in ['/absolute', '../outside', 'a/../../outside', 'a\\b', '']:
            with self.assertRaises(ValueError): runtimes.safe_name(path)
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary); source = root / 'source'; source.mkdir()
            (source / 'input').write_bytes(b'preserved')
            runtimes.deterministic_zip(source, root / 'one.zip')
            runtimes.deterministic_zip(source, root / 'two.zip')
            self.assertEqual((root / 'one.zip').read_bytes(), (root / 'two.zip').read_bytes())

if __name__ == '__main__': unittest.main()
