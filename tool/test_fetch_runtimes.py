#!/usr/bin/env python3
import hashlib
from pathlib import Path
import tempfile
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
