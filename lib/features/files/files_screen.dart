// Copyright 2026 R. Heller
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:share_plus/share_plus.dart';

import '../../app/app_providers.dart';
import '../../data/settings_store.dart';
import '../../fs/workspace_controller.dart';
import '../../fs/workspace_store.dart';
import '../../fs/workspace_error_text.dart';
import '../../fs/workspace_export.dart';
import '../../kernel/kernel_messages.dart';
import '../../l10n/l10n.dart';
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
    final AppLocalizations l = context.l10n;
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: Theme.of(ctx).textTheme.titleSmall),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: InputDecoration(hintText: l.filesNameHint),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.commonCancel, maxLines: 1, softWrap: false),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: Text(l.commonOk, maxLines: 1, softWrap: false),
          ),
        ],
      ),
    );
  }

  Future<void> _newFile() async {
    final String? name = await _promptName(context.l10n.filesNewFile);
    if (name != null && name.isNotEmpty) {
      await _guard(() => _ws.createFile(name));
    }
  }

  Future<void> _newFolder() async {
    final String? name = await _promptName(context.l10n.filesNewFolder);
    if (name != null && name.isNotEmpty) {
      await _guard(() => _ws.createDir(name));
    }
  }

  Future<void> _import() async {
    final List<XFile> files = await openFiles();
    final List<String> paths = files.map((f) => f.path).toList();
    if (paths.isNotEmpty) await _guard(() => _ws.importFiles(paths));
  }

  Future<void> _export(WorkspaceEntry e) => _guard(() async {
    final data = await prepareWorkspaceExport(_ws.store, e.relPath);
    if (!mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(data.bytes, mimeType: 'application/octet-stream'),
        ],
        fileNameOverrides: [data.name],
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  });

  Future<void> _rename(WorkspaceEntry e) async {
    final String? name = await _promptName(
      context.l10n.filesRename,
      initial: e.name,
    );
    if (name != null && name.isNotEmpty && name != e.name) {
      await _guard(() => _ws.rename(e.relPath, name));
    }
  }

  Future<void> _move(WorkspaceEntry e) async {
    final List<String> targets = _ws
        .folderTargets()
        .where((t) => t != e.relPath && !t.startsWith('${e.relPath}/'))
        .toList();
    final AppLocalizations l = context.l10n;
    final String? dest = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(
          l.filesMoveTitle(e.name),
          style: Theme.of(ctx).textTheme.titleSmall,
        ),
        children: [
          for (final String t in targets)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, t),
              child: Text(
                t.isEmpty ? l.filesWorkspaceRoot : '/$t',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
            ),
        ],
      ),
    );
    if (dest != null) await _guard(() => _ws.move(e.relPath, dest));
  }

  Future<void> _delete(WorkspaceEntry e) async {
    final AppLocalizations l = context.l10n;
    final AtelierColors c = AtelierColors.of(context);
    final bool ok =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(
              l.filesDeleteTitle(e.name),
              style: Theme.of(ctx).textTheme.titleSmall,
            ),
            content: Text(
              e.isDir ? l.filesDeleteFolderBody : l.filesDeleteFileBody,
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l.commonCancel, maxLines: 1, softWrap: false),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: c.danger,
                  foregroundColor: c.onAccent,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l.commonDelete, maxLines: 1, softWrap: false),
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
    ref.read(navIndexProvider.notifier).set(NavIndexController.editor);
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(describeWorkspaceError(e, context.l10n))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final WorkspaceController ws = ref.watch(workspaceControllerProvider);
    final KernelLanguage lang = ref.watch(activeKernelProvider);
    final AppLocalizations l = context.l10n;

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
              onPull: () => _guard(() => ws.pullFromKernel(lang)),
              pullLabel: kernelLabel(lang),
            ),
            const Divider(height: 1),
            Expanded(
              child: ws.entries.isEmpty
                  ? Center(
                      child: Text(
                        l.filesEmpty,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    )
                  : ListView.builder(
                      itemCount: ws.entries.length,
                      itemBuilder: (context, i) => _EntryTile(
                        entry: ws.entries[i],
                        onOpen: () => _open(ws.entries[i]),
                        onRename: () => _rename(ws.entries[i]),
                        onMove: () => _move(ws.entries[i]),
                        onDelete: () => _delete(ws.entries[i]),
                        onExport: () => _export(ws.entries[i]),
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
    final AppLocalizations l = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: l.filesNewFile,
            icon: const Icon(Icons.note_add_outlined, size: 20),
            onPressed: onNewFile,
          ),
          IconButton(
            tooltip: l.filesNewFolder,
            icon: const Icon(Icons.create_new_folder_outlined, size: 20),
            onPressed: onNewFolder,
          ),
          IconButton(
            tooltip: l.filesImport,
            icon: const Icon(Icons.file_download_outlined, size: 20),
            onPressed: onImport,
          ),
          const Spacer(),
          if (syncing)
            const Padding(
              padding: EdgeInsets.only(right: AppSpacing.sm),
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          Tooltip(
            message: l.filesPullTooltip(pullLabel),
            child: TextButton.icon(
              onPressed: onPull,
              icon: const Icon(Icons.sync, size: 16),
              label: Text(l.filesPull(pullLabel), maxLines: 1, softWrap: false),
            ),
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
    required this.onExport,
  });

  final WorkspaceEntry entry;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onMove;
  final VoidCallback onDelete;
  final VoidCallback onExport;

  static String _humanSize(int bytes, String locale) {
    final NumberFormat one = NumberFormat('0.0', locale);
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${one.format(bytes / 1024)} KB';
    return '${one.format(bytes / (1024 * 1024))} MB';
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    final AtelierColors c = AtelierColors.of(context);
    final AppLocalizations l = context.l10n;
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
              color: entry.isDir ? c.accent : t.bodyMedium?.color,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(entry.name, style: t.bodyMedium)),
            if (!entry.isDir)
              Text(_humanSize(entry.size, l.localeName), style: t.bodySmall),
            PopupMenuButton<String>(
              tooltip: l.filesActions(entry.name),
              icon: const Icon(Icons.more_vert, size: 18),
              onSelected: (v) => switch (v) {
                'rename' => onRename(),
                'move' => onMove(),
                'delete' => onDelete(),
                'export' => onExport(),
                _ => null,
              },
              itemBuilder: (ctx) => [
                if (!entry.isDir)
                  PopupMenuItem(
                    value: 'export',
                    child: Text(l.filesShare, maxLines: 1, softWrap: false),
                  ),
                PopupMenuItem(
                  value: 'rename',
                  child: Text(l.filesRename, maxLines: 1, softWrap: false),
                ),
                PopupMenuItem(
                  value: 'move',
                  child: Text(l.filesMove, maxLines: 1, softWrap: false),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(l.commonDelete, maxLines: 1, softWrap: false),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
