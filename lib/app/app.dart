// Copyright 2026 R. Heller
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../kernel/kernel_host.dart';
import '../l10n/app_localizations.dart';
import '../theme/appearance.dart';
import '../theme/coder_theme_atelier.dart';
import 'app_providers.dart';
import 'shell.dart';

class EtabliAtelierApp extends ConsumerWidget {
  const EtabliAtelierApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppearanceMode mode = ref.watch(appearanceModeProvider);
    final AccentChoice accent = ref.watch(accentProvider);
    final AppLanguage language = ref.watch(appLanguageProvider);
    return MaterialApp(
      title: 'Établi Atelier',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(Brightness.light, accent),
      darkTheme: AppTheme.build(Brightness.dark, accent),
      themeMode: mode.themeMode,
      // null follows the device; English (listed first) is the fallback for other device languages.
      locale: language.locale,
      supportedLocales: const [Locale('en'), Locale('de')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const KernelHost(child: AppShell()),
    );
  }
}
