// Copyright 2026 R. Heller
// SPDX-License-Identifier: AGPL-3.0-only

// The app root with the settings screen: the app language, mode and accent apply at once and are stored.
// SettingsStore is faked in memory (Hive persistence is covered in appearance_test.dart), so the test needs
// no platform channels or file I/O.

import 'package:etabli_atelier/app/app_providers.dart';
import 'package:etabli_atelier/data/settings_store.dart';
import 'package:etabli_atelier/features/settings/settings_screen.dart';
import 'package:etabli_atelier/l10n/app_localizations.dart';
import 'package:etabli_atelier/theme/appearance.dart';
import 'package:etabli_atelier/theme/coder_theme_atelier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The app's MaterialApp wiring (lib/app/app.dart) around the settings screen, without the kernel WebView.
class _SettingsApp extends ConsumerWidget {
  const _SettingsApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AccentChoice accent = ref.watch(accentProvider);
    return MaterialApp(
      theme: AppTheme.build(Brightness.light, accent),
      darkTheme: AppTheme.build(Brightness.dark, accent),
      themeMode: ref.watch(appearanceModeProvider).themeMode,
      locale: ref.watch(appLanguageProvider).locale,
      supportedLocales: const [Locale('en'), Locale('de')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const Scaffold(body: SettingsScreen()),
    );
  }
}

/// Keeps the raw stored values, as the Hive box would.
class _MemorySettings implements SettingsStore {
  final Map<String, Object?> values = <String, Object?>{'app.language': 'en'};

  @override
  AppearanceMode get appearanceMode =>
      AppearanceMode.fromStored(values[AppearanceKeys.mode]);
  @override
  Future<void> setAppearanceMode(AppearanceMode mode) async =>
      values[AppearanceKeys.mode] = mode.name;
  @override
  AccentChoice get accent =>
      AccentChoice.fromStored(values[AppearanceKeys.accent]);
  @override
  Future<void> setAccent(AccentChoice accent) async =>
      values[AppearanceKeys.accent] = accent.name;
  @override
  AppLanguage get language =>
      AppLanguage.fromStored(values[AppearanceKeys.language]);
  @override
  Future<void> setLanguage(AppLanguage language) async =>
      values[AppearanceKeys.language] = language.name;
  @override
  double get fontSize => 14;
  @override
  KernelLanguage get defaultKernel => KernelLanguage.r;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('theme builds light and dark without throwing', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: const Scaffold(body: Text('Établi Atelier')),
        ),
      ),
    );
    expect(find.text('Établi Atelier'), findsOneWidget);
    expect(AppTheme.light.colorScheme.primary, const Color(0xFF1565C0));
    expect(AppTheme.dark.colorScheme.primary, const Color(0xFF42A5F5));
  });

  testWidgets('language, mode and accent switch at once and are stored', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375 * 3, 667 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final _MemorySettings store = _MemorySettings();
    final Map<String, Object?> box = store.values;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [settingsStoreProvider.overrideWithValue(store)],
        child: const _SettingsApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('App language'), findsOneWidget);

    // App language: English -> Deutsch, applied without a restart.
    await tester.tap(
      find.byKey(const ValueKey('settings.appearance.language')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deutsch').last);
    await tester.pumpAndSettle();
    expect(find.text('Darstellung'), findsOneWidget);
    expect(find.text('App-Sprache'), findsOneWidget);
    expect(find.text('Hell'), findsOneWidget);
    expect(find.text('Dunkel'), findsOneWidget);
    expect(box['app.language'], 'de');

    // Mode: Dunkel.
    await tester.tap(find.text('Dunkel'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('Darstellung'))).brightness,
      Brightness.dark,
    );
    expect(box['appearance.mode'], 'dark');

    // Accent: Violett, by its accessibility label.
    final SemanticsHandle semantics = tester.ensureSemantics();
    await tester.tap(find.bySemanticsLabel('Violett'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('Darstellung'))).colorScheme.primary,
      const Color(0xFFB39DDB),
    );
    expect(box['appearance.accent'], 'purple');
    semantics.dispose();

    // Back to the device's language.
    await tester.tap(
      find.byKey(const ValueKey('settings.appearance.language')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('System').last);
    await tester.pumpAndSettle();
    expect(box['app.language'], 'system');
    expect(tester.takeException(), isNull);
  });
}
