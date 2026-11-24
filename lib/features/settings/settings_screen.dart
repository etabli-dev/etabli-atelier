// Copyright 2026 R. Heller
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_providers.dart';
import '../../data/settings_store.dart';
import '../../l10n/l10n.dart';
import '../../theme/appearance.dart';
import '../../theme/coder_theme_atelier.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final KernelLanguage defaultKernel = ref.watch(activeKernelProvider);
    final double fontSize = ref.watch(fontSizeProvider);
    final TextTheme t = Theme.of(context).textTheme;
    final AtelierColors c = AtelierColors.of(context);
    final AppLocalizations l = context.l10n;

    return ListView(
      // 16-pt sides keep all seven 44-pt accent swatches on one row on a 375-pt phone.
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      children: [
        _SectionTitle(l.settingsAppearance),
        const SizedBox(height: AppSpacing.sm),
        const _Card(child: AppearanceSection()),
        const SizedBox(height: AppSpacing.lg),
        _SectionTitle(l.settingsEditor),
        const SizedBox(height: AppSpacing.sm),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(l.settingsFontSize, style: t.labelLarge),
                  ),
                  Text('${fontSize.toStringAsFixed(0)} pt', style: t.bodySmall),
                ],
              ),
              Slider(
                value: fontSize,
                min: FontSizeController.min,
                max: FontSizeController.max,
                divisions: (FontSizeController.max - FontSizeController.min)
                    .round(),
                label: '${fontSize.toStringAsFixed(0)} pt',
                semanticFormatterCallback: (v) => '${v.toStringAsFixed(0)} pt',
                onChanged: (v) => ref.read(fontSizeProvider.notifier).set(v),
              ),
              Text(
                'preview <- mean(c(1, 2, 3))',
                style: TextStyle(
                  fontFamily: AppFonts.mono,
                  fontFamilyFallback: AppFonts.monoFallback,
                  fontSize: fontSize,
                  color: c.accent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _SectionTitle(l.settingsKernel),
        const SizedBox(height: AppSpacing.sm),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(l.settingsDefaultKernel, style: t.labelLarge),
              ),
              SegmentedButton<KernelLanguage>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: KernelLanguage.r,
                    label: Text('R', maxLines: 1, softWrap: false),
                  ),
                  ButtonSegment(
                    value: KernelLanguage.python,
                    label: Text('Python', maxLines: 1, softWrap: false),
                  ),
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
        _SectionTitle(l.settingsAbout),
        const SizedBox(height: AppSpacing.sm),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Établi Atelier', style: t.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(l.settingsAboutBody, style: t.bodySmall),
              const SizedBox(height: AppSpacing.sm),
              Text('com.raban.etabli.atelier · v1.0.0', style: t.bodySmall),
              TextButton(
                onPressed: () => showLicensePage(
                  context: context,
                  applicationName: 'Établi Atelier',
                ),
                child: Text(l.settingsLicenses, maxLines: 1, softWrap: false),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Settings → Appearance: the app language (menu), the mode (segmented) and the accent (swatches).
class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppearanceMode mode = ref.watch(appearanceModeProvider);
    final AccentChoice accent = ref.watch(accentProvider);
    final AppLanguage language = ref.watch(appLanguageProvider);
    final TextTheme t = Theme.of(context).textTheme;
    final AtelierColors c = AtelierColors.of(context);
    final AppLocalizations l = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(l.settingsLanguage, style: t.labelLarge)),
            const SizedBox(width: AppSpacing.sm),
            DropdownButton<AppLanguage>(
              key: const ValueKey('settings.appearance.language'),
              value: language,
              underline: const SizedBox.shrink(),
              borderRadius: const BorderRadius.all(AppRadius.mdRadius),
              dropdownColor: c.background,
              style: t.labelLarge,
              onChanged: (v) {
                if (v != null) ref.read(appLanguageProvider.notifier).set(v);
              },
              items: [
                for (final AppLanguage option in AppLanguage.values)
                  DropdownMenuItem(
                    value: option,
                    child: Text(
                      l.languageLabel(option),
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(l.settingsMode, style: t.labelLarge),
        ),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<AppearanceMode>(
            key: const ValueKey('settings.appearance.mode'),
            showSelectedIcon: false,
            segments: [
              for (final AppearanceMode option in AppearanceMode.values)
                ButtonSegment(
                  value: option,
                  label: Text(
                    l.modeLabel(option),
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
            ],
            selected: {mode},
            onSelectionChanged: (sel) =>
                ref.read(appearanceModeProvider.notifier).set(sel.first),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ExcludeSemantics(child: Text(l.settingsAccent, style: t.labelLarge)),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          children: [
            for (final AccentChoice option in AccentChoice.values)
              _Swatch(
                choice: option,
                selected: option == accent,
                label: l.accentLabel(option),
                hint: l.settingsAccent,
                onTap: () => ref.read(accentProvider.notifier).set(option),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(l.settingsAppearanceNote, style: t.bodySmall),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.choice,
    required this.selected,
    required this.label,
    required this.hint,
    required this.onTap,
  });

  final AccentChoice choice;
  final bool selected;
  final String label;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Brightness b = Theme.of(context).brightness;
    final AtelierColors c = AtelierColors.of(context);
    return Semantics(
      key: ValueKey('settings.appearance.accent.${choice.name}'),
      label: label,
      hint: hint,
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      excludeSemantics: true,
      onTap: onTap,
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: choice.color(b),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? c.text : c.border,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: selected
                    ? Icon(Icons.check, size: 18, color: c.onAccent)
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );
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
