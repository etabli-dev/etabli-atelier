// Copyright 2026 R. Heller
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_providers.dart';
import '../../data/settings_store.dart';
import '../../kernel/kernel_controller.dart';
import '../../kernel/kernel_messages.dart';
import '../../l10n/l10n.dart';
import '../../theme/coder_theme_atelier.dart';

class ConsoleScreen extends ConsumerStatefulWidget {
  const ConsoleScreen({super.key});

  @override
  ConsumerState<ConsoleScreen> createState() => _ConsoleScreenState();
}

class _ConsoleScreenState extends ConsumerState<ConsoleScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _submit(KernelController kernel, KernelLanguage lang) async {
    final String code = _input.text;
    if (code.trim().isEmpty) return;
    _input.clear();
    await kernel.run(lang, code);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final KernelController kernel = ref.watch(kernelControllerProvider);
    final KernelLanguage lang = ref.watch(activeKernelProvider);
    final double fontSize = ref.watch(fontSizeProvider);

    return ListenableBuilder(
      listenable: kernel,
      builder: (context, _) {
        _scrollToBottom();
        final KernelState state = kernel.stateFor(lang);
        final AppLocalizations l = context.l10n;
        return Column(
          children: [
            _StatusBar(state: state, language: lang, kernel: kernel),
            const Divider(height: 1),
            Expanded(
              child: _OutputView(
                scroll: _scroll,
                lines: kernel.linesFor(lang),
                language: lang,
                fontSize: fontSize,
              ),
            ),
            const Divider(height: 1),
            _InputBar(
              controller: _input,
              focus: _focus,
              enabled: state == KernelState.ready,
              hint: enabled(state)
                  ? (lang == KernelLanguage.r
                        ? l.consoleHintR
                        : l.consoleHintPython)
                  : l.consoleNotReady,
              label: l.consoleInputLabel(kernelLabel(lang)),
              runLabel: l.commonRun,
              onSubmit: () => _submit(kernel, lang),
            ),
          ],
        );
      },
    );
  }

  bool enabled(KernelState s) => s == KernelState.ready;
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.state,
    required this.language,
    required this.kernel,
  });

  final KernelState state;
  final KernelLanguage language;
  final KernelController kernel;

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    final AtelierColors c = AtelierColors.of(context);
    final AppLocalizations l = context.l10n;
    final (Color color, String label) = switch (state) {
      KernelState.idle => (c.textMuted, l.kernelStateIdle),
      KernelState.loading => (c.warning, l.kernelStateLoading),
      KernelState.ready => (c.success, l.kernelStateReady),
      KernelState.error => (c.danger, l.kernelStateError),
    };
    final String name = language == KernelLanguage.r
        ? 'R · WebR'
        : 'Python · Pyodide';
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 9, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '$name  $label',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.labelMedium,
            ),
          ),
          IconButton(
            tooltip: l.consoleClear,
            icon: const Icon(Icons.cleaning_services_outlined, size: 18),
            onPressed: () => kernel.clear(language),
          ),
          IconButton(
            tooltip: language == KernelLanguage.r
                ? l.consoleRestartR
                : l.consoleRestartPython,
            icon: const Icon(Icons.restart_alt, size: 18),
            onPressed: () => kernel.restart(language),
          ),
        ],
      ),
    );
  }
}

class _OutputView extends StatelessWidget {
  const _OutputView({
    required this.scroll,
    required this.lines,
    required this.language,
    required this.fontSize,
  });
  final ScrollController scroll;
  final List<ConsoleLine> lines;
  final KernelLanguage language;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) {
      return Center(
        child: Text(
          context.l10n.consoleBooting,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    return ListView.builder(
      controller: scroll,
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: lines.length,
      itemBuilder: (context, i) =>
          _LineView(line: lines[i], language: language, fontSize: fontSize),
    );
  }
}

class _LineView extends StatelessWidget {
  const _LineView({
    required this.line,
    required this.language,
    required this.fontSize,
  });
  final ConsoleLine line;
  final KernelLanguage language;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final AtelierColors c = AtelierColors.of(context);
    final Color color = switch (line.stream) {
      ConsoleStream.stdout => c.text,
      ConsoleStream.stderr => c.danger,
      ConsoleStream.input => c.accent,
      ConsoleStream.prompt => c.textMuted,
      ConsoleStream.system => c.textMuted,
    };
    final String prefix = line.stream == ConsoleStream.input ? '> ' : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: SelectableText(
        '$prefix${line.display(context.l10n, language)}',
        style: TextStyle(
          fontFamily: AppFonts.mono,
          fontFamilyFallback: AppFonts.monoFallback,
          fontSize: fontSize,
          height: 1.35,
          color: color,
          fontStyle: line.stream == ConsoleStream.system
              ? FontStyle.italic
              : FontStyle.normal,
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.focus,
    required this.enabled,
    required this.hint,
    required this.label,
    required this.runLabel,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final bool enabled;
  final String hint;
  final String label;
  final String runLabel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: ExcludeSemantics(
              child: Text(
                '>',
                style: TextStyle(
                  fontFamily: AppFonts.mono,
                  color: AtelierColors.of(context).accent,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          Expanded(
            child: Semantics(
              label: label,
              child: CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.enter): enabled
                      ? onSubmit
                      : () {},
                },
                child: TextField(
                  controller: controller,
                  focusNode: focus,
                  enabled: enabled,
                  autofocus: false,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSubmit(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: InputDecoration(isDense: true, hintText: hint),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton(
            onPressed: enabled ? onSubmit : null,
            child: Text(runLabel, maxLines: 1, softWrap: false),
          ),
        ],
      ),
    );
  }
}
