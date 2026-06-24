// Copyright 2026 R. Heller
// SPDX-License-Identifier: Apache-2.0

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_providers.dart';
import '../../data/settings_store.dart';
import '../../fs/workspace_controller.dart';
import '../../fs/workspace_store.dart';
import '../../theme/coder_theme_atelier.dart';

class FilesScreen extends ConsumerStatefulWidget {
  const FilesScreen({super.key});

  @override
  ConsumerState<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends ConsumerState<FilesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(workspaceControllerProvider).refresh();
    });
  }

  WorkspaceController get _ws => ref.read(workspaceControllerProvider);

  Future<String?> _promptName(String title, {String initial = ''}) {
    final TextEditingController c = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: Theme.of(ctx).textTheme.titleSmall),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'name'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, c.text.trim()),
              child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _newFile() async {
    final String? name = await _promptName('New file');
    if (name != null && name.isNotEmpty) await _guard(() => _ws.createFile(name));
  }

  Future<void> _newFolder() async {
    final String? name = await _promptName('New folder');
    if (name != null && name.isNotEmpty) await _guard(() => _ws.createDir(name));
  }

  Future<void> _import() async {
    final List<XFile> files = await openFiles();
    final List<String> paths = files.map((f) => f.path).toList();
    if (paths.isNotEmpty) await _guard(() => _ws.importFiles(paths));
  }

  Future<void> _rename(WorkspaceEntry e) async {
    final String? name = await _promptName('Rename', initial: e.name);
    if (name != null && name.isNotEmpty && name != e.name) {
      await _guard(() => _ws.rename(e.relPath, name));
    }
  }

  Future<void> _move(WorkspaceEntry e) async {
    final List<String> targets = _ws
        .folderTargets()
        .where((t) => t != e.relPath && !t.startsWith('${e.relPath}/'))
        .toList();
    final String? dest = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Move "${e.name}" to…',
            style: Theme.of(ctx).textTheme.titleSmall),
        children: [
          for (final String t in targets)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, t),
              child: Text(t.isEmpty ? '/ (workspace root)' : '/$t',
                  style: Theme.of(ctx).textTheme.bodyMedium),
            ),
        ],
      ),
    );
    if (dest != null) await _guard(() => _ws.move(e.relPath, dest));
  }

  Future<void> _delete(WorkspaceEntry e) async {
    final bool ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Delete "${e.name}"?',
                style: Theme.of(ctx).textTheme.titleSmall),
            content: Text(
              e.isDir
                  ? 'The folder and all its contents will be removed.'
                  : 'This file will be removed.',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (ok) await _guard(() => _ws.delete(e.relPath));
  }

  void _open(WorkspaceEntry e) {
    if (e.isDir) return;
    ref.read(openFileProvider.notifier).open(e.relPath);
    final KernelLanguage? lang = _languageForName(e.name);
    if (lang != null) ref.read(activeKernelProvider.notifier).set(lang);
    ref.read(navIndexProvider.notifier).set(NavIndexController.editor);
  }

  static KernelLanguage? _languageForName(String name) {
    final String n = name.toLowerCase();
    if (n.endsWith('.py')) return KernelLanguage.python;
    if (n.endsWith('.r') || n.endsWith('.rmd')) return KernelLanguage.r;
    return null;
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final WorkspaceController ws = ref.watch(workspaceControllerProvider);
    final KernelLanguage lang = ref.watch(activeKernelProvider);

    return ListenableBuilder(
      listenable: ws,
      builder: (context, _) {
        return Column(
          children: [
            _Toolbar(
              syncing: ws.syncing,
              onNewFile: _newFile,
              onNewFolder: _newFolder,
              onImport: _import,
              onPull: () =>
                  _guard(() => ws.pullFromKernel(lang)),
              pullLabel: lang == KernelLanguage.r ? 'R' : 'Python',
            ),
            const Divider(height: 1),
            Expanded(
              child: ws.entries.isEmpty
                  ? Center(
                      child: Text('Workspace is empty.\nCreate or import a file.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall),
                    )
                  : ListView.builder(
                      itemCount: ws.entries.length,
                      itemBuilder: (context, i) => _EntryTile(
                        entry: ws.entries[i],
                        onOpen: () => _open(ws.entries[i]),
                        onRename: () => _rename(ws.entries[i]),
                        onMove: () => _move(ws.entries[i]),
                        onDelete: () => _delete(ws.entries[i]),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.syncing,
    required this.onNewFile,
    required this.onNewFolder,
    required this.onImport,
    required this.onPull,
    required this.pullLabel,
  });

  final bool syncing;
  final VoidCallback onNewFile;
  final VoidCallback onNewFolder;
  final VoidCallback onImport;
  final VoidCallback onPull;
  final String pullLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      child: Row(
        children: [
          IconButton(
              tooltip: 'New file',
              icon: const Icon(Icons.note_add_outlined, size: 20),
              onPressed: onNewFile),
          IconButton(
              tooltip: 'New folder',
              icon: const Icon(Icons.create_new_folder_outlined, size: 20),
              onPressed: onNewFolder),
          IconButton(
              tooltip: 'Import from device',
              icon: const Icon(Icons.file_download_outlined, size: 20),
              onPressed: onImport),
          const Spacer(),
          if (syncing)
            const Padding(
              padding: EdgeInsets.only(right: AppSpacing.sm),
              child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          TextButton.icon(
            onPressed: onPull,
            icon: const Icon(Icons.sync, size: 16),
            label: Text('Pull from $pullLabel'),
          ),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.entry,
    required this.onOpen,
    required this.onRename,
    required this.onMove,
    required this.onDelete,
  });

  final WorkspaceEntry entry;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onMove;
  final VoidCallback onDelete;

  String _humanSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    return InkWell(
      onTap: entry.isDir ? null : onOpen,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md + entry.depth * AppSpacing.md,
          right: AppSpacing.xs,
          top: 6,
          bottom: 6,
        ),
        child: Row(
          children: [
            Icon(
              entry.isDir ? Icons.folder_outlined : Icons.description_outlined,
              size: 18,
              color: entry.isDir ? AppColors.accent : t.bodyMedium?.color,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(entry.name, style: t.bodyMedium)),
            if (!entry.isDir)
              Text(_humanSize(entry.size), style: t.bodySmall),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18),
              onSelected: (v) => switch (v) {
                'rename' => onRename(),
                'move' => onMove(),
                'delete' => onDelete(),
                _ => null,
              },
              itemBuilder: (ctx) => const [
                PopupMenuItem(value: 'rename', child: Text('Rename')),
                PopupMenuItem(value: 'move', child: Text('Move…')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
