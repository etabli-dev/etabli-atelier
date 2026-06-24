// Copyright 2026 R. Heller
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_providers.dart';
import '../../data/settings_store.dart';
import '../../theme/coder_theme_atelier.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode mode = ref.watch(themeModeProvider);
    final KernelLanguage defaultKernel = ref.watch(activeKernelProvider);
    final double fontSize = ref.watch(fontSizeProvider);
    final TextTheme t = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text('Appearance', style: t.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text('Theme', style: t.labelLarge),
              ),
              SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text('Auto')),
                  ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                ],
                selected: {mode},
                onSelectionChanged: (sel) =>
                    ref.read(themeModeProvider.notifier).set(sel.first),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Editor', style: t.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Font size', style: t.labelLarge),
                  const Spacer(),
                  Text('${fontSize.toStringAsFixed(0)} pt', style: t.bodySmall),
                ],
              ),
              Slider(
                value: fontSize,
                min: FontSizeController.min,
                max: FontSizeController.max,
                divisions:
                    (FontSizeController.max - FontSizeController.min).round(),
                label: '${fontSize.toStringAsFixed(0)} pt',
                onChanged: (v) => ref.read(fontSizeProvider.notifier).set(v),
              ),
              Text(
                'preview <- mean(c(1, 2, 3))',
                style: TextStyle(
                  fontFamily: AppFonts.mono,
                  fontFamilyFallback: AppFonts.monoFallback,
                  fontSize: fontSize,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Kernel', style: t.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text('Default kernel', style: t.labelLarge),
              ),
              SegmentedButton<KernelLanguage>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: KernelLanguage.r, label: Text('R')),
                  ButtonSegment(
                      value: KernelLanguage.python, label: Text('Python')),
                ],
                selected: {defaultKernel},
                onSelectionChanged: (sel) async {
                  ref.read(activeKernelProvider.notifier).set(sel.first);
                  await ref
                      .read(settingsStoreProvider)
                      .setDefaultKernel(sel.first);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('About', style: t.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Établi Atelier', style: t.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Offline polyglot mobile IDE.\nR via WebR · Python via Pyodide.\nBoth on-device, no network required.',
                style: t.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('com.raban.etabli.atelier · v1.0.0', style: t.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: child,
      ),
    );
  }
}
