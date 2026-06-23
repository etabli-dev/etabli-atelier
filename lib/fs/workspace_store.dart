// Copyright 2026 Raban Heller
// SPDX-License-Identifier: Apache-2.0

// The canonical workspace — real files on device storage under the app's
// documents directory. This is the source of truth that survives restarts and
// that both kernels are mirrored against (see KernelController FS sync), so a
// .csv written in R becomes readable in Python and vice versa.
//
// Relative paths are kept POSIX-style ('/'-separated) because they double as
// in-kernel paths under /workspace.

import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Where the workspace is mounted inside each kernel's virtual filesystem.
const String kKernelWorkspaceRoot = '/workspace';

class WorkspaceEntry {
  const WorkspaceEntry({
    required this.relPath,
    required this.isDir,
    required this.size,
  });

  /// POSIX-style path relative to the workspace root (no leading slash).
  final String relPath;
  final bool isDir;
  final int size;

  String get name => p.posix.basename(relPath);
  int get depth => relPath.isEmpty ? 0 : relPath.split('/').length - 1;
}

class WorkspaceStore {
  WorkspaceStore._(this.root);

  final Directory root;

  static Future<WorkspaceStore> open() async {
    final Directory docs = await getApplicationDocumentsDirectory();
    final Directory root = Directory(p.join(docs.path, 'workspace'));
    if (!await root.exists()) {
      await root.create(recursive: true);
    }
    return WorkspaceStore._(root);
  }

  String _abs(String rel) => p.normalize(p.join(root.path, _toNative(rel)));
  static String _toNative(String posixRel) =>
      posixRel.split('/').join(Platform.pathSeparator);
  String _toRel(String abs) =>
      p.relative(abs, from: root.path).split(Platform.pathSeparator).join('/');

  /// All entries, recursive, folders-first then alphabetical.
  Future<List<WorkspaceEntry>> list() async {
    final List<WorkspaceEntry> out = <WorkspaceEntry>[];
    await for (final FileSystemEntity e in root.list(recursive: true)) {
      final bool isDir = e is Directory;
      int size = 0;
      if (e is File) {
        try {
          size = await e.length();
        } catch (_) {}
      }
      out.add(WorkspaceEntry(relPath: _toRel(e.path), isDir: isDir, size: size));
    }
    out.sort(_compare);
    return out;
  }

  static int _compare(WorkspaceEntry a, WorkspaceEntry b) {
    // Sort by path segments so children follow parents; folders before files
    // at each level.
    final List<String> as = a.relPath.split('/');
    final List<String> bs = b.relPath.split('/');
    final int n = as.length < bs.length ? as.length : bs.length;
    for (int i = 0; i < n; i++) {
      if (as[i] != bs[i]) {
        final bool aLeaf = i == as.length - 1;
        final bool bLeaf = i == bs.length - 1;
        // folders (non-leaf or dir) ahead of files when names differ
        if (aLeaf != bLeaf) return aLeaf ? 1 : -1;
        return as[i].toLowerCase().compareTo(bs[i].toLowerCase());
      }
    }
    return as.length - bs.length;
  }

  bool _isValidName(String name) =>
      name.isNotEmpty &&
      !name.contains('/') &&
      !name.contains('\\') &&
      name != '.' &&
      name != '..';

  Future<void> createFile(String rel) async {
    final File f = File(_abs(rel));
    await f.parent.create(recursive: true);
    if (!await f.exists()) await f.create();
  }

  Future<void> createDir(String rel) async {
    await Directory(_abs(rel)).create(recursive: true);
  }

  Future<void> rename(String rel, String newName) async {
    if (!_isValidName(newName)) {
      throw ArgumentError('Invalid name: $newName');
    }
    final String parent = p.posix.dirname(rel);
    final String dest = parent == '.' ? newName : '$parent/$newName';
    await _movePath(rel, dest);
  }

  /// Move [rel] into folder [destDirRel] (empty = root), keeping its name.
  Future<void> move(String rel, String destDirRel) async {
    final String name = p.posix.basename(rel);
    final String dest = destDirRel.isEmpty ? name : '$destDirRel/$name';
    await _movePath(rel, dest);
  }

  Future<void> _movePath(String rel, String destRel) async {
    final FileSystemEntity src =
        await _entityType(_abs(rel)) == FileSystemEntityType.directory
            ? Directory(_abs(rel))
            : File(_abs(rel));
    final String destAbs = _abs(destRel);
    await Directory(p.dirname(destAbs)).create(recursive: true);
    await src.rename(destAbs);
  }

  Future<void> delete(String rel) async {
    final String abs = _abs(rel);
    final FileSystemEntityType t = await _entityType(abs);
    if (t == FileSystemEntityType.directory) {
      await Directory(abs).delete(recursive: true);
    } else if (t == FileSystemEntityType.file) {
      await File(abs).delete();
    }
  }

  Future<Uint8List> readBytes(String rel) => File(_abs(rel)).readAsBytes();

  Future<void> writeBytes(String rel, List<int> bytes) async {
    final File f = File(_abs(rel));
    await f.parent.create(recursive: true);
    await f.writeAsBytes(bytes, flush: true);
  }

  Future<String> readText(String rel) => File(_abs(rel)).readAsString();

  Future<void> writeText(String rel, String text) async {
    final File f = File(_abs(rel));
    await f.parent.create(recursive: true);
    await f.writeAsString(text, flush: true);
  }

  /// Import an external file (from the device picker) into [destDirRel].
  Future<void> importFile(String sourcePath, {String destDirRel = ''}) async {
    final String name = p.basename(sourcePath);
    final String destRel = destDirRel.isEmpty ? name : '$destDirRel/$name';
    final File dest = File(_abs(destRel));
    await dest.parent.create(recursive: true);
    await File(sourcePath).copy(dest.path);
  }

  Future<bool> exists(String rel) async =>
      await _entityType(_abs(rel)) != FileSystemEntityType.notFound;

  Future<FileSystemEntityType> _entityType(String abs) =>
      FileSystemEntity.type(abs);
}
