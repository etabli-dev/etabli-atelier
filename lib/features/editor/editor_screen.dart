// Copyright 2026 R. Heller
// SPDX-License-Identifier: Apache-2.0

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
          _loadError =
              'Could not open $path as text. The current buffer is retained.';
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
    final current = _loadedPath ?? 'this scratch buffer';
    final next = nextPath ?? 'a new scratch buffer';
    return showDialog<_BufferChoice>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved changes'),
        content: Text('Save changes to $current before opening $next?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _BufferChoice.cancel),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _BufferChoice.discard),
            child: const Text('Discard'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _BufferChoice.save),
            child: const Text('Save'),
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
            content: Text('Saved $path'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not save $path. The editor buffer is retained.',
            ),
          ),
        );
      }
      return false;
    }
  }

  Future<String?> _promptFilename(KernelLanguage lang) {
    final String ext = lang == KernelLanguage.r ? '.R' : '.py';
    final TextEditingController c = TextEditingController(text: 'untitled$ext');
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Save as', style: Theme.of(ctx).textTheme.titleSmall),
        content: TextField(
          controller: c,
          autofocus: true,
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: const Text('Save'),
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
        content: Text(
          '${lang == KernelLanguage.r ? 'R' : 'Python'} kernel is still starting…',
        ),
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

    return Column(
      children: [
        _EditorToolbar(
          fileName: _loadedPath ?? 'scratch buffer',
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
                    _loadError!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _failedPath = null;
                    _loadIfNeeded(path);
                  },
                  child: const Text('Retry'),
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
                    background: isDark
                        ? AppColors.darkBackground
                        : AppColors.lightBackground,
                    textStyle: TextStyle(
                      fontFamily: AppFonts.mono,
                      fontFamilyFallback: AppFonts.monoFallback,
                      fontSize: fontSize,
                    ),
                    gutterStyle: GutterStyle(
                      textStyle: TextStyle(
                        fontFamily: AppFonts.mono,
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
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
            tooltip: 'Save',
            icon: const Icon(Icons.save_outlined, size: 18),
            onPressed: onSave,
          ),
          TextButton.icon(
            onPressed: onRunSelection,
            icon: const Icon(Icons.subject, size: 16),
            label: const Text('Selection'),
          ),
          const SizedBox(width: AppSpacing.xs),
          FilledButton.icon(
            onPressed: onRunFile,
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('Run'),
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
                Icon(open ? Icons.expand_more : Icons.expand_less, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Output · ${language == KernelLanguage.r ? 'R' : 'Python'}',
                  style: t.labelMedium,
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Clear',
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
                final bool isDark =
                    Theme.of(context).brightness == Brightness.dark;
                return Container(
                  width: double.infinity,
                  color: isDark
                      ? AppColors.darkSurface
                      : AppColors.lightSurfaceAlt,
                  child: ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    itemCount: lines.length,
                    itemBuilder: (context, i) {
                      final ConsoleLine line = lines[lines.length - 1 - i];
                      final Color color = switch (line.stream) {
                        ConsoleStream.stderr => AppColors.danger,
                        ConsoleStream.input => AppColors.accent,
                        ConsoleStream.system =>
                          isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        _ => isDark ? AppColors.darkText : AppColors.lightText,
                      };
                      return Text(
                        line.stream == ConsoleStream.input
                            ? '> ${line.text}'
                            : line.text,
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
