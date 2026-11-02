#!/usr/bin/env python3
"""Prepare pinned offline runtimes. Requires Python 3.9+, no third-party modules."""
# Copyright 2026 R. Heller
# SPDX-License-Identifier: Apache-2.0
import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import shutil
import tarfile
import tempfile
import urllib.request
import zipfile


def digest(path):
    h = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            h.update(block)
    return h.hexdigest()


def fetch(item, cache, offline=False):
    target = cache / item['name']
    if target.exists():
        if digest(target) != item['sha256']:
            raise ValueError('Checksum mismatch in cache: ' + str(target))
        return target
    if offline:
        raise FileNotFoundError('Not cached: ' + str(target))
    print('Downloading ' + item['name'], flush=True)
    with tempfile.NamedTemporaryFile(dir=cache, delete=False) as tmp:
        temp = Path(tmp.name)
    try:
        with urllib.request.urlopen(item['url'], timeout=120) as response, temp.open('wb') as out:
            shutil.copyfileobj(response, out)
        if digest(temp) != item['sha256']:
            raise ValueError('Checksum mismatch: ' + item['name'])
        temp.replace(target)
    finally:
        temp.unlink(missing_ok=True)
    return target


def safe_name(name):
    path = PurePosixPath(name)
    if path.is_absolute() or '..' in path.parts or '\\' in name or not path.parts:
        raise ValueError('Unsafe archive member: ' + name)
    return str(path)


def put(root, name, data):
    dest = root / safe_name(name)
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_bytes(data)


def deterministic_zip(source, target):
    target.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(target, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for path in sorted(source.rglob('*')):
            if path.is_file():
                entry = zipfile.ZipInfo(path.relative_to(source).as_posix(), (2026, 1, 1, 0, 0, 0))
                entry.compress_type = zipfile.ZIP_DEFLATED
                entry.external_attr = 0o100644 << 16
                archive.writestr(entry, path.read_bytes())


def prepare(lock, cached, stage):
    assets = stage / 'assets'
    webr = stage / 'webr'
    with zipfile.ZipFile(cached['webr-0.6.0.zip']) as archive:
        for entry in archive.infolist():
            if entry.is_dir():
                continue
            safe_name(entry.filename)
            prefix = 'webr-0.6.0/'
            if not entry.filename.startswith(prefix):
                raise ValueError('Unexpected WebR archive layout')
            put(webr, entry.filename[len(prefix):], archive.read(entry))
    put(webr, 'LICENSE.md', cached['webr-LICENSE.md'].read_bytes())

    with tarfile.open(cached['shinylive-0.10.12.tar.gz']) as archive:
        prefix = 'shinylive-0.10.12/'
        if lock['application'] == 'vitrine':
            engine = stage / 'engine'
            for entry in archive:
                safe_name(entry.name)
                if not entry.isfile():
                    continue
                if not entry.name.startswith(prefix):
                    raise ValueError('Unexpected shinylive archive layout')
                rel = entry.name[len(prefix):]
                # Vitrine runs R. Omit Python's 693 MB runtime and type checker.
                if rel.startswith(('shinylive/pyodide/', 'shinylive/pyright/')):
                    continue
                if rel.startswith('shinylive/') or rel == 'shinylive-sw.js':
                    put(engine, rel, archive.extractfile(entry).read())
            put(engine, 'LICENSE-shinylive.txt', cached['shinylive-LICENSE.txt'].read_bytes())
            put(engine, 'shinylive/webr/LICENSE.md', cached['webr-LICENSE.md'].read_bytes())
            for required in ['shinylive-sw.js', 'shinylive/shinylive.js', 'shinylive/webr/library.data.gz']:
                if not (engine / required).is_file():
                    raise ValueError('Missing runtime file: ' + required)
            deterministic_zip(engine, assets / 'shinylive-r/engine.zip')
            deterministic_zip(webr, assets / 'webr/webr-dist.zip')
        else:
            py_prefix = prefix + 'shinylive/pyodide/'
            package_lock = json.load(archive.extractfile(py_prefix + 'pyodide-lock.json'))
            if package_lock['info']['version'] != '0.27.7':
                raise ValueError('Unexpected Pyodide version')
            selected = set()

            def include(name):
                if name in selected:
                    return
                selected.add(name)
                for dep in package_lock['packages'][name]['depends']:
                    include(dep)

            for name in lock['python_packages']:
                include(name)
            packages = {package_lock['packages'][name]['file_name']: package_lock['packages'][name] for name in selected}
            all_payloads = {package['file_name'] for package in package_lock['packages'].values()}
            py = assets / 'runtimes/pyodide'
            for entry in archive:
                safe_name(entry.name)
                if not entry.isfile() or not entry.name.startswith(py_prefix):
                    continue
                rel = entry.name[len(py_prefix):]
                if (rel in all_payloads or rel.endswith('.whl')) and rel not in packages:
                    continue
                data = archive.extractfile(entry).read()
                if rel in packages and hashlib.sha256(data).hexdigest() != packages[rel]['sha256']:
                    raise ValueError('Package hash mismatch: ' + rel)
                put(py, rel, data)
            for required in list(packages) + ['pyodide.mjs', 'pyodide.asm.wasm', 'python_stdlib.zip']:
                if not (py / required).is_file():
                    raise ValueError('Missing Pyodide file: ' + required)
            put(py, 'LICENSE.txt', cached['pyodide-LICENSE.txt'].read_bytes())
            shutil.copytree(webr, assets / 'runtimes/webr')
    return assets


def publish_assets(prepared, repo):
    files = sorted(p for p in prepared.rglob('*') if p.is_file())
    previous_path = repo / 'tool/runtimes.prepared.json'
    previous = json.loads(previous_path.read_text())['files'] if previous_path.exists() else {}
    stale = []

    def checked_destination(relative):
        dest = repo / 'assets' / relative
        current = repo
        for part in dest.relative_to(repo).parts:
            current = current / part
            if current.is_symlink():
                raise ValueError('Runtime destination contains a symlink: ' + str(current))
        try:
            dest.resolve().relative_to(repo.resolve())
        except ValueError:
            raise ValueError('Runtime destination escapes repository: ' + str(dest))
        return dest

    # Validate the entire destination tree before any copying or stale cleanup.
    destinations = {file: checked_destination(file.relative_to(prepared)) for file in files}
    pyodide_lock = prepared / 'runtimes/pyodide/pyodide-lock.json'
    if pyodide_lock.exists():
        package_lock = json.loads(pyodide_lock.read_text())
        for package in package_lock['packages'].values():
            rel = 'runtimes/pyodide/' + safe_name(package['file_name'])
            existing = checked_destination(rel)
            if (prepared / rel).exists() or not existing.exists():
                continue
            # Only remove unchanged outputs identified by the prior receipt.
            # Check every candidate before publishing any new files.
            if (existing.is_symlink() or not existing.is_file()
                    or previous.get(rel) != digest(existing)):
                raise ValueError('Excluded runtime payload is modified or untracked: ' + rel)
            stale.append(existing)
    for file in files:
        dest = destinations[file]
        dest.parent.mkdir(parents=True, exist_ok=True)
        with tempfile.NamedTemporaryFile(dir=dest.parent, delete=False) as out:
            temp = Path(out.name)
            with file.open('rb') as source:
                shutil.copyfileobj(source, out)
        temp.replace(dest)
    for file in stale:
        file.unlink()
    return {file.relative_to(prepared).as_posix(): digest(file) for file in files}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--cache-dir', type=Path, default=Path.home() / '.cache/etabli-runtimes')
    parser.add_argument('--offline', action='store_true', help='Require every input in the verified cache')
    args = parser.parse_args()
    repo = Path(__file__).resolve().parent.parent
    lock = json.loads((repo / 'tool/runtimes.lock.json').read_text())
    args.cache_dir.mkdir(parents=True, exist_ok=True)
    cached = {a['name']: fetch(a, args.cache_dir, args.offline) for a in lock['artifacts']}
    with tempfile.TemporaryDirectory(prefix='etabli-runtimes-') as tmp:
        prepared = prepare(lock, cached, Path(tmp))
        # All downloads, hashes and archive contents pass before any app asset changes.
        receipt = publish_assets(prepared, repo)
        target = repo / 'tool/runtimes.prepared.json'
        target.write_text(json.dumps({'inputs': lock, 'files': receipt}, indent=2) + '\n')
    print(f'Prepared and verified {len(receipt)} runtime assets for {lock["application"]}.')


if __name__ == '__main__':
    main()
