// Copyright 2026 R. Heller
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:highlight/languages/python.dart' show python;
import 'package:highlight/languages/r.dart' show r;

import '../../app/app_providers.dart';
import '../../data/settings_store.dart';
import '../../fs/workspace_controller.dart';
import '../../kernel/kernel_controller.dart';
import '../../kernel/kernel_messages.dart';
import '../../l10n/l10n.dart';
import '../../theme/coder_theme_atelier.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

enum _BufferChoice { save, discard, cancel }

class _EditorScreenState extends ConsumerState<EditorScreen> {
  late final CodeController _code = CodeController(text: '', language: r);
  String? _loadedPath;
  String _savedText = '';
  String? _failedPath;
  String? _loadError;
  bool _loading = false;
  // Track which language the *controller* already has installed. Initialized
  // to R to match the CodeController(language: r) above so the first build's
  // _applyLanguage(R) is a no-op — assigning the same language anyway would
  // notify listeners (analyzeCode → localToGlobal) before the CodeField has
  // been laid out, tripping a `hasSize` assertion.
  KernelLanguage? _appliedLang = KernelLanguage.r;
  bool _outputOpen = true;
  // CodeController.analyzeCode runs async on construction and notifies its
  // listeners (the CodeField calls context.localToGlobal in its handler). On
  // the very first frame the CodeField's render box hasn't been laid out, so
  // we render a placeholder for one frame and mount the real field after.
  bool _editorReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _editorReady = true);
    });
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  WorkspaceController get _ws => ref.read(workspaceControllerProvider);
  KernelController get _kernel => ref.read(kernelControllerProvider);

  Future<void> _loadIfNeeded(String? path) async {
    if (!mounted) return;
    if (path == _loadedPath) {
      if (_loadError != null) {
        setState(() {
          _failedPath = null;
          _loadError = null;
        });
      }
      return;
    }
    if ((_loadError != null && path == _failedPath) || _loading) return;
    setState(() => _loading = true);
    try {
      if (_code.fullText != _savedText) {
        final choice = await _confirmFileSwitch(path);
        if (!mounted) return;
        if (choice != _BufferChoice.discard) {
          final saved =
              choice == _BufferChoice.save &&
              await _save(
                ref.read(activeKernelProvider),
                selectSavedFile: false,
              );
          if (!mounted) return;
          if (!saved) {
            _restoreOpenFile();
            return;
          }
        }
      }
      String content = '';
      if (path != null && await _ws.store.exists(path)) {
        content = await _ws.store.readText(path);
      }
      if (!mounted) return;
      setState(() {
        _code.fullText = content;
        _loadedPath = path;
        _savedText = content;
        _failedPath = null;
        _loadError = null;
      });
      // Select the file's kernel only after navigation and decoding succeed.
      // Canceling a file change must retain the current buffer's language.
      final name = path?.toLowerCase() ?? '';
      if (name.endsWith('.py')) {
        ref.read(activeKernelProvider.notifier).set(KernelLanguage.python);
      } else if (name.endsWith('.r') || name.endsWith('.rmd')) {
        ref.read(activeKernelProvider.notifier).set(KernelLanguage.r);
      }
    } catch (_) {
      // Do not associate the old buffer with a file that was never decoded.
      // Saving that buffer must continue to target its original file.
      if (mounted) {
        setState(() {
          _failedPath = path;
          // The path that failed; the message is localized when shown.
          _loadError = path ?? '';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _restoreOpenFile() {
    final selection = ref.read(openFileProvider.notifier);
    final path = _loadedPath;
    if (path == null) {
      selection.close();
    } else {
      selection.open(path);
    }
  }

  Future<_BufferChoice?> _confirmFileSwitch(String? nextPath) {
    final AppLocalizations l = context.l10n;
    final current = _loadedPath ?? l.editorThisScratch;
    final next = nextPath ?? l.editorNewScratch;
    return showDialog<_BufferChoice>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.editorUnsavedTitle),
        content: Text(l.editorUnsavedBody(current, next)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _BufferChoice.cancel),
            child: Text(l.commonCancel, maxLines: 1, softWrap: false),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _BufferChoice.discard),
            child: Text(l.commonDiscard, maxLines: 1, softWrap: false),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _BufferChoice.save),
            child: Text(l.commonSave, maxLines: 1, softWrap: false),
          ),
        ],
      ),
    );
  }

  void _applyLanguage(KernelLanguage lang) {
    if (_appliedLang == lang) return;
    _appliedLang = lang;
    // Defer the controller mutation by one frame. The CodeController's
    // analyzeCode notifies listeners which call context.localToGlobal on the
    // editor's render box; on the first build that box hasn't been laid out
    // yet and the call hits a `hasSize` assertion.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _code.language = lang == KernelLanguage.r ? r : python;
    });
  }

  Future<bool> _save(KernelLanguage lang, {bool selectSavedFile = true}) async {
    String? path = _loadedPath;
    if (path == null) {
      path = await _promptFilename(lang);
      if (path == null || !mounted) return false;
    }
    try {
      final text = _code.fullText;
      await _ws.store.writeText(path, text);
      if (!mounted) return true;
      // Associate a new buffer only after its bytes have been saved.
      _loadedPath = path;
      _savedText = text;
      if (selectSavedFile) ref.read(openFileProvider.notifier).open(path);
      await _ws.refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.editorSaved(path)),
            duration: const Duration(seconds: 1),
          ),
        );
      }
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.editorSaveFailed(path))),
        );
      }
      return false;
    }
  }

  Future<String?> _promptFilename(KernelLanguage lang) {
    final AppLocalizations l = context.l10n;
    final String ext = lang == KernelLanguage.r ? '.R' : '.py';
    final TextEditingController c = TextEditingController(
      text: '${l.editorUntitled}$ext',
    );
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.editorSaveAs, style: Theme.of(ctx).textTheme.titleSmall),
        content: TextField(
          controller: c,
          autofocus: true,
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.commonCancel, maxLines: 1, softWrap: false),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: Text(l.commonSave, maxLines: 1, softWrap: false),
          ),
        ],
      ),
    );
  }

  Future<void> _runFile(KernelLanguage lang) async {
    if (!_ensureReady(lang)) return;
    if (_loadedPath != null && !await _save(lang)) return;
    // Mirror the latest workspace into the kernel so file references resolve.
    await _ws.pushToKernel(lang);
    final String code = _code.fullText;
    if (code.trim().isEmpty) return;
    await _kernel.run(lang, lang == KernelLanguage.r ? '$code\n' : code);
    if (mounted) setState(() => _outputOpen = true);
  }

  Future<void> _runSelection(KernelLanguage lang) async {
    if (!_ensureReady(lang)) return;
    final String code = _selectedOrCurrentLine();
    if (code.trim().isEmpty) return;
    await _kernel.run(lang, lang == KernelLanguage.r ? '$code\n' : code);
    if (mounted) setState(() => _outputOpen = true);
  }

  String _selectedOrCurrentLine() {
    final String text = _code.text;
    final TextSelection sel = _code.selection;
    if (sel.isValid && !sel.isCollapsed) {
      return text.substring(sel.start, sel.end);
    }
    final int pos = sel.isValid ? sel.baseOffset : text.length;
    final int start = pos <= 0 ? 0 : text.lastIndexOf('\n', pos - 1) + 1;
    int end = text.indexOf('\n', pos);
    if (end == -1) end = text.length;
    return text.substring(start, end);
  }

  bool _ensureReady(KernelLanguage lang) {
    if (_kernel.stateFor(lang) == KernelState.ready) return true;
    ref.read(kernelControllerProvider).ensureStarted(lang);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.editorKernelStarting(kernelLabel(lang))),
        duration: const Duration(seconds: 2),
      ),
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final String? path = ref.watch(openFileProvider);
    final KernelLanguage lang = ref.watch(activeKernelProvider);
    final KernelController kernel = ref.watch(kernelControllerProvider);
    final double fontSize = ref.watch(fontSizeProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadIfNeeded(path));
    _applyLanguage(lang);

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final AtelierColors c = AtelierColors.of(context);
    final AppLocalizations l = context.l10n;

    return Column(
      children: [
        _EditorToolbar(
          fileName: _loadedPath ?? l.editorScratch,
          language: lang,
          onSave: _loading ? null : () => _save(lang),
          onRunFile: _loading ? null : () => _runFile(lang),
          onRunSelection: _loading ? null : () => _runSelection(lang),
        ),
        if (_loadError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l.editorOpenFailed(_loadError!),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _failedPath = null;
                    _loadIfNeeded(path);
                  },
                  child: Text(l.commonRetry, maxLines: 1, softWrap: false),
                ),
              ],
            ),
          ),
        const Divider(height: 1),
        Expanded(
          child: !_editorReady
              ? const SizedBox.shrink()
              : CodeTheme(
                  data: CodeThemeData(
                    styles: isDark ? atomOneDarkTheme : atomOneLightTheme,
                  ),
                  // CodeField has its own scroll views; wrapping it in
                  // SingleChildScrollView drops the internal ScrollController
                  // and logs "ScrollController not attached to any scroll
                  // views".
                  child: CodeField(
                    controller: _code,
                    readOnly: _loading,
                    expands: true,
                    wrap: false,
                    background: c.background,
                    textStyle: TextStyle(
                      fontFamily: AppFonts.mono,
                      fontFamilyFallback: AppFonts.monoFallback,
                      fontSize: fontSize,
                    ),
                    gutterStyle: GutterStyle(
                      textStyle: TextStyle(
                        fontFamily: AppFonts.mono,
                        fontSize: 13,
                        color: c.textMuted,
                      ),
                    ),
                  ),
                ),
        ),
        const Divider(height: 1),
        _OutputPanel(
          open: _outputOpen,
          language: lang,
          kernel: kernel,
          onToggle: () => setState(() => _outputOpen = !_outputOpen),
        ),
      ],
    );
  }
}

class _EditorToolbar extends StatelessWidget {
  const _EditorToolbar({
    required this.fileName,
    required this.language,
    required this.onSave,
    required this.onRunFile,
    required this.onRunSelection,
  });

  final String fileName;
  final KernelLanguage language;
  final VoidCallback? onSave;
  final VoidCallback? onRunFile;
  final VoidCallback? onRunSelection;

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    final AppLocalizations l = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Icon(Icons.description_outlined, size: 16, color: t.bodySmall?.color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              fileName,
              overflow: TextOverflow.ellipsis,
              style: t.labelMedium,
            ),
          ),
          IconButton(
            tooltip: l.commonSave,
            icon: const Icon(Icons.save_outlined, size: 18),
            onPressed: onSave,
          ),
          Tooltip(
            message: l.editorRunSelection,
            excludeFromSemantics: true,
            child: Semantics(
              label: l.editorRunSelection,
              excludeSemantics: true,
              button: true,
              enabled: onRunSelection != null,
              onTap: onRunSelection,
              child: TextButton.icon(
                onPressed: onRunSelection,
                icon: const Icon(Icons.subject, size: 16),
                label: Text(l.editorSelection, maxLines: 1, softWrap: false),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Tooltip(
            message: l.editorRunFile,
            excludeFromSemantics: true,
            child: Semantics(
              label: l.editorRunFile,
              excludeSemantics: true,
              button: true,
              enabled: onRunFile != null,
              onTap: onRunFile,
              child: FilledButton.icon(
                onPressed: onRunFile,
                icon: const Icon(Icons.play_arrow, size: 18),
                label: Text(l.commonRun, maxLines: 1, softWrap: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutputPanel extends StatelessWidget {
  const _OutputPanel({
    required this.open,
    required this.language,
    required this.kernel,
    required this.onToggle,
  });

  final bool open;
  final KernelLanguage language;
  final KernelController kernel;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    final AtelierColors c = AtelierColors.of(context);
    final AppLocalizations l = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  open ? Icons.expand_more : Icons.expand_less,
                  size: 18,
                  semanticLabel: open ? l.editorHideOutput : l.editorShowOutput,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l.editorOutput(kernelLabel(language)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.labelMedium,
                  ),
                ),
                IconButton(
                  tooltip: l.editorClearOutput,
                  icon: const Icon(Icons.cleaning_services_outlined, size: 16),
                  onPressed: () => kernel.clear(language),
                ),
              ],
            ),
          ),
        ),
        if (open)
          SizedBox(
            height: 160,
            child: ListenableBuilder(
              listenable: kernel,
              builder: (context, _) {
                final List<ConsoleLine> lines = kernel.linesFor(language);
                return Container(
                  width: double.infinity,
                  color: c.background,
                  child: ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    itemCount: lines.length,
                    itemBuilder: (context, i) {
                      final ConsoleLine line = lines[lines.length - 1 - i];
                      final Color color = switch (line.stream) {
                        ConsoleStream.stderr => c.danger,
                        ConsoleStream.input => c.accent,
                        ConsoleStream.system => c.textMuted,
                        _ => c.text,
                      };
                      final String text = line.display(l, language);
                      return Text(
                        line.stream == ConsoleStream.input ? '> $text' : text,
                        style: TextStyle(
                          fontFamily: AppFonts.mono,
                          fontFamilyFallback: AppFonts.monoFallback,
                          fontSize: 12.5,
                          height: 1.3,
                          color: color,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
