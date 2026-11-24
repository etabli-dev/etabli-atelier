// Copyright 2026 R. Heller
// SPDX-License-Identifier: AGPL-3.0-only

// The owner's appearance setting, the same in every Établi app: light, dark or the device's mode, an accent
// colour and the app language. Keys, raw values, colours and their order follow the native reference
// (etabli-doc ios/App/AppearanceModel.swift; owner decision of 2026-11-24, colour wheel). Stored as raw values;
// missing or unknown values (also the removed "teal" and "brown") fall back to the defaults and never crash.
// IDENTICAL across the Flutter Établi apps (Atelier, Courrier, Vitrine).

import 'package:flutter/material.dart';

/// The stored keys, shared with the native apps.
abstract final class AppearanceKeys {
  static const String mode = 'appearance.mode';
  static const String accent = 'appearance.accent';
  static const String language = 'app.language';
}

/// System, light or dark. Raw values: `system`, `light`, `dark`.
enum AppearanceMode {
  system,
  light,
  dark;

  /// The stored value, or [system] when it is missing or unknown.
  static AppearanceMode fromStored(Object? raw) =>
      values.firstWhere((m) => m.name == raw, orElse: () => system);

  ThemeMode get themeMode => switch (this) {
    system => ThemeMode.system,
    light => ThemeMode.light,
    dark => ThemeMode.dark,
  };
}

/// The app's language: the device's language, German or English. Raw values: `system`, `de`, `en`.
enum AppLanguage {
  system,
  de,
  en;

  /// The stored value, or [system] when it is missing or unknown.
  static AppLanguage fromStored(Object? raw) =>
      values.firstWhere((l) => l.name == raw, orElse: () => system);

  /// The fixed locale, or null for the device's language.
  Locale? get locale => switch (this) {
    system => null,
    de => const Locale('de'),
    en => const Locale('en'),
  };

  /// The language's name in its own language ("Deutsch" stays "Deutsch" in English), null for [system].
  String? get endonym => switch (this) {
    system => null,
    de => 'Deutsch',
    en => 'English',
  };
}

/// An accent colour with a value for light and for dark mode (0xRRGGBB), in the owner's order.
enum AccentChoice {
  /// Hugo Coder's `$link-color` / `$link-color-dark`; the default.
  coderBlue(0x1565C0, 0x42A5F5),
  green(0x2E7D32, 0x66BB6A),
  yellow(0x8C6200, 0xFFCA28),
  orange(0xBF360C, 0xFFA726),
  red(0xC62828, 0xE57373),
  purple(0x4527A0, 0xB39DDB),
  graphite(0x212121, 0xDADADA);

  const AccentChoice(this.light, this.dark);

  /// Light-mode value, at least 4.5:1 against the light background and with white on it.
  final int light;

  /// Dark-mode value, at least 4.5:1 against the dark background and with it as the text colour on it.
  final int dark;

  /// Opacity of selection fills (navigation indicators, selected segments, pressed text buttons).
  static const double selectionOpacity = 0.16;

  /// Opacity of the text-selection highlight in fields and the editor.
  static const double textSelectionOpacity = 0.32;

  /// The stored value, or [coderBlue] when it is missing or unknown.
  static AccentChoice fromStored(Object? raw) =>
      values.firstWhere((a) => a.name == raw, orElse: () => coderBlue);

  int rgb(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  Color color(Brightness brightness) => CoderPalette.color(rgb(brightness));

  /// Owner rule (2026-11-24): no yellow shade in any background. Yellow and orange therefore draw selection
  /// fills and tints in the mode's neutral text colour instead of their own; text and solid fills keep the
  /// accent.
  bool get hasNeutralSelection => this == yellow || this == orange;

  /// The colour of a selection fill or tint (drawn at low opacity): the accent, or for yellow and orange
  /// #212121 in light and #DADADA in dark mode.
  int selectionTint(Brightness brightness) => hasNeutralSelection
      ? CoderPalette.foreground(brightness)
      : rgb(brightness);

  Color selectionColor(Brightness brightness) =>
      CoderPalette.color(selectionTint(brightness));
}

/// The Hugo Coder theme's neutral colours (luizdepra/hugo-coder, assets/scss/_variables.scss), as 0xRRGGBB.
abstract final class CoderPalette {
  static const int backgroundLight = 0xFAFAFA; // $bg-color
  static const int backgroundDark = 0x212121; // $bg-color-dark
  static const int foregroundLight = 0x212121; // $fg-color
  static const int foregroundDark = 0xDADADA; // $fg-color-dark
  static const int surfaceLight = 0xE0E0E0; // $alt-bg-color
  static const int surfaceDark = 0x424242; // $alt-bg-color-dark
  static const int borderLight = 0xCCCCCC; // $darker-alt-bg-color
  static const int borderDark = 0x4F4F4F; // $lighter-alt-bg-color-dark

  /// Secondary text: Material grey 700 / 400, at least 4.5:1 on background and surface.
  static const int mutedLight = 0x616161;
  static const int mutedDark = 0xBDBDBD;

  /// Text and symbols on an accent fill: white in light mode, the dark background colour in dark mode.
  static const int onAccentLight = 0xFFFFFF;
  static const int onAccentDark = 0x212121;

  // State colours (do not follow the accent); at least 4.5:1 on background and with on-accent text.
  static const int successLight = 0x1B5E20;
  static const int successDark = 0x81C784;
  static const int warningLight = 0x805300;
  static const int warningDark = 0xFFCA28;
  static const int dangerLight = 0x9B3B3B;
  static const int dangerDark = 0xEF9A9A;

  static bool _dark(Brightness b) => b == Brightness.dark;
  static int background(Brightness b) =>
      _dark(b) ? backgroundDark : backgroundLight;
  static int foreground(Brightness b) =>
      _dark(b) ? foregroundDark : foregroundLight;
  static int surface(Brightness b) => _dark(b) ? surfaceDark : surfaceLight;
  static int border(Brightness b) => _dark(b) ? borderDark : borderLight;
  static int muted(Brightness b) => _dark(b) ? mutedDark : mutedLight;
  static int onAccent(Brightness b) => _dark(b) ? onAccentDark : onAccentLight;
  static int success(Brightness b) => _dark(b) ? successDark : successLight;
  static int warning(Brightness b) => _dark(b) ? warningDark : warningLight;
  static int danger(Brightness b) => _dark(b) ? dangerDark : dangerLight;

  /// An opaque [Color] from 0xRRGGBB.
  static Color color(int rgb) => Color(0xFF000000 | rgb);
}
