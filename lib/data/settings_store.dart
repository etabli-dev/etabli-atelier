// Copyright 2026 R. Heller
// SPDX-License-Identifier: AGPL-3.0-only

// Lightweight settings persistence backed by Hive.
//
// Holds non-secret app preferences (appearance, app language, font size, default kernel). Secrets
// live in flutter_secure_storage instead — see SecretStore (added later).

import 'package:hive_flutter/hive_flutter.dart';

import '../theme/appearance.dart';

/// The language a session/file is bound to. Two separate kernels — no interop.
enum KernelLanguage { r, python }

class SettingsStore {
  SettingsStore._(this._box);

  /// A store over an already opened box (tests).
  SettingsStore.withBox(this._box);

  static const String _boxName = 'settings';

  /// The earlier Auto/Light/Dark key of this app; its values ("system", "light", "dark") are the same as
  /// [AppearanceMode]'s raw values.
  static const String legacyThemeModeKey = 'themeMode';
  static const String _kFontSize = 'fontSize';
  static const String _kDefaultKernel = 'defaultKernel';

  final Box _box;

  static Future<SettingsStore> open() async {
    final Box box = await Hive.openBox(_boxName);
    final SettingsStore store = SettingsStore._(box);
    await store.migrateLegacyMode();
    return store;
  }

  /// Moves a mode saved under the earlier key to [AppearanceKeys.mode] once; a value already there wins.
  Future<void> migrateLegacyMode() async {
    final Object? legacy = _box.get(legacyThemeModeKey);
    if (legacy == null) return;
    if (_box.get(AppearanceKeys.mode) == null) {
      await _box.put(
        AppearanceKeys.mode,
        AppearanceMode.fromStored(legacy).name,
      );
    }
    await _box.delete(legacyThemeModeKey);
  }

  AppearanceMode get appearanceMode =>
      AppearanceMode.fromStored(_box.get(AppearanceKeys.mode));
  Future<void> setAppearanceMode(AppearanceMode mode) =>
      _box.put(AppearanceKeys.mode, mode.name);

  AccentChoice get accent =>
      AccentChoice.fromStored(_box.get(AppearanceKeys.accent));
  Future<void> setAccent(AccentChoice accent) =>
      _box.put(AppearanceKeys.accent, accent.name);

  AppLanguage get language =>
      AppLanguage.fromStored(_box.get(AppearanceKeys.language));
  Future<void> setLanguage(AppLanguage language) =>
      _box.put(AppearanceKeys.language, language.name);

  double get fontSize => (_box.get(_kFontSize) as num?)?.toDouble() ?? 14.0;
  Future<void> setFontSize(double size) => _box.put(_kFontSize, size);

  KernelLanguage get defaultKernel {
    final String? raw = _box.get(_kDefaultKernel) as String?;
    return raw == 'python' ? KernelLanguage.python : KernelLanguage.r;
  }

  Future<void> setDefaultKernel(KernelLanguage lang) =>
      _box.put(_kDefaultKernel, lang.name);
}
