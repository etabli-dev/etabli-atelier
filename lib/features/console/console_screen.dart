// Copyright 2026 R. Heller
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_providers.dart';
import '../../data/settings_store.dart';
import '../../kernel/kernel_controller.dart';
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
        return Column(
          children: [
            _StatusBar(state: state, language: lang, kernel: kernel),
            const Divider(height: 1),
            Expanded(
              child: _OutputView(
                  scroll: _scroll,
                  lines: kernel.linesFor(lang),
                  fontSize: fontSize),
            ),
            const Divider(height: 1),
            _InputBar(
              controller: _input,
              focus: _focus,
              enabled: state == KernelState.ready,
              hint: enabled(state)
                  ? (lang == KernelLanguage.r
                      ? 'Enter R expression…'
                      : 'Enter Python statement…')
                  : 'Kernel not ready',
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
    final (Color color, String label) = switch (state) {
      KernelState.idle => (AppColors.darkTextMuted, 'idle'),
      KernelState.loading => (AppColors.warning, 'loading…'),
      KernelState.ready => (AppColors.accent, 'ready'),
      KernelState.error => (AppColors.danger, 'error'),
    };
    final String name =
        language == KernelLanguage.r ? 'R · WebR' : 'Python · Pyodide';
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 9, color: color),
          const SizedBox(width: AppSpacing.sm),
          Text('$name  $label', style: t.labelMedium),
          const Spacer(),
          IconButton(
            tooltip: 'Clear console',
            icon: const Icon(Icons.cleaning_services_outlined, size: 18),
            onPressed: () => kernel.clear(language),
          ),
          IconButton(
            tooltip: language == KernelLanguage.r
                ? 'Force-restart R kernel'
                : 'Force-restart (reloads kernel host)',
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
    required this.fontSize,
  });
  final ScrollController scroll;
  final List<ConsoleLine> lines;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) {
      return Center(
        child: Text('Booting kernel…',
            style: Theme.of(context).textTheme.bodySmall),
      );
    }
    return ListView.builder(
      controller: scroll,
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: lines.length,
      itemBuilder: (context, i) => _LineView(line: lines[i], fontSize: fontSize),
    );
  }
}

class _LineView extends StatelessWidget {
  const _LineView({required this.line, required this.fontSize});
  final ConsoleLine line;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color base = isDark ? AppColors.darkText : AppColors.lightText;
    final Color muted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final Color color = switch (line.stream) {
      ConsoleStream.stdout => base,
      ConsoleStream.stderr => AppColors.danger,
      ConsoleStream.input => AppColors.accent,
      ConsoleStream.prompt => muted,
      ConsoleStream.system => muted,
    };
    final String prefix = line.stream == ConsoleStream.input ? '> ' : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: SelectableText(
        '$prefix${line.text}',
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
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final bool enabled;
  final String hint;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Text('>',
                style: TextStyle(
                  fontFamily: AppFonts.mono,
                  color: AppColors.accent,
                  fontSize: 15,
                )),
          ),
          Expanded(
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.enter):
                    enabled ? onSubmit : () {},
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
          const SizedBox(width: AppSpacing.sm),
          FilledButton(
            onPressed: enabled ? onSubmit : null,
            child: const Text('Run'),
          ),
        ],
      ),
    );
  }
}
