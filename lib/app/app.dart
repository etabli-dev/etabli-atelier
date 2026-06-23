// Copyright 2026 Raban Heller
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../kernel/kernel_host.dart';
import '../theme/coder_theme_atelier.dart';
import 'app_providers.dart';
import 'shell.dart';

class EtabliAtelierApp extends ConsumerWidget {
  const EtabliAtelierApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode mode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'Établi Atelier',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      home: const KernelHost(child: AppShell()),
    );
  }
}
