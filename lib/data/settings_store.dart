// Copyright 2026 Raban Heller
// SPDX-License-Identifier: Apache-2.0

// Lightweight settings persistence backed by Hive.
//
// Holds non-secret app preferences (theme, font size, default kernel). Secrets
// live in flutter_secure_storage instead — see SecretStore (added later).

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// The language a session/file is bound to. Two separate kernels — no interop.
enum KernelLanguage { r, python }

class SettingsStore {
  SettingsStore._(this._box);

  static const String _boxName = 'settings';
  static const String _kThemeMode = 'themeMode';
  static const String _kFontSize = 'fontSize';
  static const String _kDefaultKernel = 'defaultKernel';

  final Box _box;

  static Future<SettingsStore> open() async {
    final Box box = await Hive.openBox(_boxName);
    return SettingsStore._(box);
  }

  ThemeMode get themeMode {
    final String? raw = _box.get(_kThemeMode) as String?;
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      _box.put(_kThemeMode, mode.name);

  double get fontSize => (_box.get(_kFontSize) as num?)?.toDouble() ?? 14.0;
  Future<void> setFontSize(double size) => _box.put(_kFontSize, size);

  KernelLanguage get defaultKernel {
    final String? raw = _box.get(_kDefaultKernel) as String?;
    return raw == 'python' ? KernelLanguage.python : KernelLanguage.r;
  }

  Future<void> setDefaultKernel(KernelLanguage lang) =>
      _box.put(_kDefaultKernel, lang.name);
}
