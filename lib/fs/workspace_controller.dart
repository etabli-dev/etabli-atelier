// Drives the file browser and keeps the canonical workspace mirrored with the
// kernels. Pushes the workspace into a kernel when it becomes ready / is
// switched to, and pulls kernel-written files back when a run completes.

import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/settings_store.dart';
import '../kernel/kernel_controller.dart';
import 'workspace_store.dart';

class WorkspaceController extends ChangeNotifier {
  WorkspaceController(this._store, this._kernel) {
    _kernel.onKernelReady = (lang) => pushToKernel(lang);
    _kernel.onRunComplete = (lang) => pullFromKernel(lang);
  }

  final WorkspaceStore _store;
  final KernelController _kernel;

  WorkspaceStore get store => _store;

  List<WorkspaceEntry> _entries = const [];
  List<WorkspaceEntry> get entries => _entries;

  bool _syncing = false;
  bool get syncing => _syncing;

  Future<void> refresh() async {
    _entries = await _store.list();
    notifyListeners();
  }

  // --- CRUD (delegate to store, then refresh) -----------------------------
  Future<void> createFile(String rel) async {
    await _store.createFile(rel);
    await refresh();
  }

  Future<void> createDir(String rel) async {
    await _store.createDir(rel);
    await refresh();
  }

  Future<void> rename(String rel, String newName) async {
    await _store.rename(rel, newName);
    await refresh();
  }

  Future<void> move(String rel, String destDirRel) async {
    await _store.move(rel, destDirRel);
    await refresh();
  }

  Future<void> delete(String rel) async {
    await _store.delete(rel);
    await refresh();
  }

  Future<void> importFiles(List<String> sourcePaths,
      {String destDirRel = ''}) async {
    for (final String src in sourcePaths) {
      await _store.importFile(src, destDirRel: destDirRel);
    }
    await refresh();
  }

  /// Folders only — used as move/import targets.
  List<String> folderTargets() =>
      ['', ..._entries.where((e) => e.isDir).map((e) => e.relPath)];

  // --- Kernel sync --------------------------------------------------------
  Future<void> pushToKernel(KernelLanguage lang) async {
    if (_kernel.stateFor(lang) != KernelState.ready) return;
    _setSyncing(true);
    try {
      final List<Map<String, String>> files = <Map<String, String>>[];
      for (final WorkspaceEntry e in await _store.list()) {
        if (e.isDir) continue;
        final bytes = await _store.readBytes(e.relPath);
        files.add({'path': e.relPath, 'b64': base64Encode(bytes)});
      }
      await _kernel.pushFiles(lang, files);
    } finally {
      _setSyncing(false);
    }
  }

  Future<void> pullFromKernel(KernelLanguage lang) async {
    if (_kernel.stateFor(lang) != KernelState.ready) return;
    _setSyncing(true);
    try {
      final List<Map<String, String>> files =
          await _kernel.snapshotFiles(lang);
      for (final Map<String, String> f in files) {
        final String path = f['path'] ?? '';
        if (path.isEmpty) continue;
        await _store.writeBytes(path, base64Decode(f['b64'] ?? ''));
      }
      await refresh();
    } finally {
      _setSyncing(false);
    }
  }

  void _setSyncing(bool v) {
    _syncing = v;
    notifyListeners();
  }
}
