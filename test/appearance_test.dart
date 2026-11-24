// Copyright 2026 R. Heller
// SPDX-License-Identifier: AGPL-3.0-only

// The suite-wide appearance setting (etabli-doc ios/App/AppearanceModel.swift, scripts/check_appearance.swift):
// stored keys and fallbacks, the owner's colour table, WCAG contrast, and the rule that no background or
// selection tint is a yellow shade in any accent or mode.

import 'dart:io';
import 'dart:math' as math;

import 'package:etabli_atelier/data/settings_store.dart';
import 'package:etabli_atelier/theme/appearance.dart';
import 'package:etabli_atelier/theme/coder_theme_atelier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

double _luminance(int rgb) {
  double channel(int shift) {
    final double v = ((rgb >> shift) & 0xFF) / 255;
    return v <= 0.04045
        ? v / 12.92
        : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(16) + 0.7152 * channel(8) + 0.0722 * channel(0);
}

double _contrast(int a, int b) {
  final double x = _luminance(a), y = _luminance(b);
  return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
}

/// Hue in degrees (0..<360), null for a grey.
double? _hue(int rgb) {
  final double r = ((rgb >> 16) & 0xFF) / 255,
      g = ((rgb >> 8) & 0xFF) / 255,
      b = (rgb & 0xFF) / 255;
  final double high = math.max(r, math.max(g, b));
  final double delta = high - math.min(r, math.min(g, b));
  if (delta == 0) return null;
  final double sector = high == r
      ? (g - b) / delta
      : high == g
      ? (b - r) / delta + 2
      : (r - g) / delta + 4;
  final double degrees = sector * 60;
  return degrees < 0 ? degrees + 360 : degrees;
}

/// Chroma in 0–255 units (max − min channel).
int _chroma(int rgb) {
  final List<int> ch = [(rgb >> 16) & 0xFF, (rgb >> 8) & 0xFF, rgb & 0xFF];
  return ch.reduce(math.max) - ch.reduce(math.min);
}

/// A yellow shade: hue 30–70° with chroma of at least 8.
bool _isYellowish(int rgb) {
  final double? hue = _hue(rgb);
  return hue != null && hue >= 30 && hue <= 70 && _chroma(rgb) >= 8;
}

/// [top] drawn with its own alpha over the opaque [base], as 0xRRGGBB.
int _over(Color top, int base) {
  final double a = top.a;
  int channel(int shift, double v) =>
      ((v * 255) * a + ((base >> shift) & 0xFF) * (1 - a)).round() << shift;
  return channel(16, top.r) | channel(8, top.g) | channel(0, top.b);
}

/// Every background or selection tint the theme draws for [accent] in [b].
Map<String, Color> _tints(ThemeData theme) {
  const Set<WidgetState> selected = {WidgetState.selected};
  const Set<WidgetState> pressed = {WidgetState.pressed};
  return {
    'navigation bar indicator': theme.navigationBarTheme.indicatorColor!,
    'navigation rail indicator': theme.navigationRailTheme.indicatorColor!,
    'selected segment': theme.segmentedButtonTheme.style!.backgroundColor!
        .resolve(selected)!,
    'segment pressed': theme.segmentedButtonTheme.style!.overlayColor!.resolve(
      pressed,
    )!,
    'text button pressed': theme.textButtonTheme.style!.overlayColor!.resolve(
      pressed,
    )!,
    'text selection': theme.textSelectionTheme.selectionColor!,
    'slider overlay': theme.sliderTheme.overlayColor!,
    'primary container': theme.colorScheme.primaryContainer,
    'secondary container': theme.colorScheme.secondaryContainer,
    'tertiary container': theme.colorScheme.tertiaryContainer,
    'surface tint': theme.colorScheme.surfaceTint,
    'card': theme.cardTheme.color!,
    'dialog': theme.dialogTheme.backgroundColor!,
    'menu': theme.popupMenuTheme.color!,
    'input fill': theme.inputDecorationTheme.fillColor!,
    'scaffold': theme.scaffoldBackgroundColor,
  };
}

void main() {
  test('stored keys and raw values match the native apps', () {
    expect(AppearanceKeys.mode, 'appearance.mode');
    expect(AppearanceKeys.accent, 'appearance.accent');
    expect(AppearanceKeys.language, 'app.language');
    expect(AppearanceMode.values.map((m) => m.name), [
      'system',
      'light',
      'dark',
    ]);
    expect(AppLanguage.values.map((l) => l.name), ['system', 'de', 'en']);
    expect(AccentChoice.values.map((a) => a.name), [
      'coderBlue',
      'green',
      'yellow',
      'orange',
      'red',
      'purple',
      'graphite',
    ]);
  });

  test('missing and unknown stored values fall back to the defaults', () {
    expect(AppearanceMode.fromStored(null), AppearanceMode.system);
    expect(AppearanceMode.fromStored('dark'), AppearanceMode.dark);
    expect(AppearanceMode.fromStored('Dark'), AppearanceMode.system);
    expect(AppearanceMode.fromStored('auto'), AppearanceMode.system);
    expect(AccentChoice.fromStored(null), AccentChoice.coderBlue);
    expect(AccentChoice.fromStored('yellow'), AccentChoice.yellow);
    expect(AccentChoice.fromStored('teal'), AccentChoice.coderBlue);
    expect(AccentChoice.fromStored('brown'), AccentChoice.coderBlue);
    expect(AccentChoice.fromStored(''), AccentChoice.coderBlue);
    expect(AccentChoice.fromStored(42), AccentChoice.coderBlue);
    expect(AppLanguage.fromStored('de'), AppLanguage.de);
    expect(AppLanguage.fromStored('fr'), AppLanguage.system);
    expect(AppLanguage.fromStored('DE'), AppLanguage.system);
    expect(AppLanguage.de.locale, const Locale('de'));
    expect(AppLanguage.system.locale, isNull);
  });

  test('the colour table is the owner\'s set of 2026-11-24', () {
    const Map<AccentChoice, (int, int)> table = {
      AccentChoice.coderBlue: (0x1565C0, 0x42A5F5),
      AccentChoice.green: (0x2E7D32, 0x66BB6A),
      AccentChoice.yellow: (0x8C6200, 0xFFCA28),
      AccentChoice.orange: (0xBF360C, 0xFFA726),
      AccentChoice.red: (0xC62828, 0xE57373),
      AccentChoice.purple: (0x4527A0, 0xB39DDB),
      AccentChoice.graphite: (0x212121, 0xDADADA),
    };
    for (final AccentChoice a in AccentChoice.values) {
      expect((a.light, a.dark), table[a], reason: a.name);
    }
    expect(CoderPalette.backgroundLight, 0xFAFAFA);
    expect(CoderPalette.backgroundDark, 0x212121);
    expect(CoderPalette.foregroundLight, 0x212121);
    expect(CoderPalette.foregroundDark, 0xDADADA);
    expect(CoderPalette.surfaceLight, 0xE0E0E0);
    expect(CoderPalette.surfaceDark, 0x424242);
    expect(CoderPalette.onAccentLight, 0xFFFFFF);
    expect(CoderPalette.onAccentDark, 0x212121);
  });

  test(
    'every accent meets 4.5:1 on its background and with its on-accent text',
    () {
      for (final Brightness b in Brightness.values) {
        for (final AccentChoice a in AccentChoice.values) {
          final int accent = a.rgb(b);
          expect(
            _contrast(accent, CoderPalette.background(b)),
            greaterThanOrEqualTo(4.5),
            reason: '${a.name} on background ($b)',
          );
          expect(
            _contrast(accent, CoderPalette.onAccent(b)),
            greaterThanOrEqualTo(4.5),
            reason: '${a.name} with on-accent text ($b)',
          );
        }
        for (final int text in [
          CoderPalette.foreground(b),
          CoderPalette.muted(b),
        ]) {
          for (final int base in [
            CoderPalette.background(b),
            CoderPalette.surface(b),
          ]) {
            expect(
              _contrast(text, base),
              greaterThanOrEqualTo(4.5),
              reason: '$b neutrals',
            );
          }
        }
        for (final int state in [
          CoderPalette.success(b),
          CoderPalette.warning(b),
          CoderPalette.danger(b),
        ]) {
          expect(
            _contrast(state, CoderPalette.background(b)),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            _contrast(state, CoderPalette.onAccent(b)),
            greaterThanOrEqualTo(4.5),
          );
        }
      }
    },
  );

  test('yellow and orange draw selection tints in the neutral text colour', () {
    expect(_isYellowish(AccentChoice.yellow.light), isTrue);
    expect(_isYellowish(AccentChoice.yellow.dark), isTrue);
    expect(_hue(0xDADADA), isNull);
    for (final AccentChoice a in AccentChoice.values) {
      final bool neutral = a == AccentChoice.yellow || a == AccentChoice.orange;
      expect(a.hasNeutralSelection, neutral, reason: a.name);
      expect(a.selectionTint(Brightness.light), neutral ? 0x212121 : a.light);
      expect(a.selectionTint(Brightness.dark), neutral ? 0xDADADA : a.dark);
    }
  });

  test('no theme tint is a yellow shade in any accent or mode', () {
    for (final Brightness b in Brightness.values) {
      for (final AccentChoice a in AccentChoice.values) {
        final ThemeData theme = AppTheme.build(b, a);
        expect(
          theme.colorScheme.primary,
          a.color(b),
          reason: '${a.name} primary',
        );
        _tints(theme).forEach((name, tint) {
          for (final int base in [
            CoderPalette.background(b),
            CoderPalette.surface(b),
          ]) {
            final int drawn = _over(tint, base);
            expect(
              _isYellowish(drawn),
              isFalse,
              reason:
                  '${a.name} $name over ${base.toRadixString(16)} is ${drawn.toRadixString(16)} ($b)',
            );
          }
        });
      }
    }
  });

  group('settings store', () {
    late Directory dir;
    setUp(() async {
      dir = await Directory.systemTemp.createTemp('atelier-settings-');
      Hive.init(dir.path);
    });
    tearDown(() async {
      await Hive.close();
      await dir.delete(recursive: true);
    });

    test('persists mode, accent and language under the shared keys', () async {
      final Box box = await Hive.openBox('settings');
      final SettingsStore store = SettingsStore.withBox(box);
      expect(store.appearanceMode, AppearanceMode.system);
      expect(store.accent, AccentChoice.coderBlue);
      expect(store.language, AppLanguage.system);
      await store.setAppearanceMode(AppearanceMode.dark);
      await store.setAccent(AccentChoice.purple);
      await store.setLanguage(AppLanguage.de);
      expect(box.get('appearance.mode'), 'dark');
      expect(box.get('appearance.accent'), 'purple');
      expect(box.get('app.language'), 'de');
      await box.put('appearance.accent', 'teal');
      expect(store.accent, AccentChoice.coderBlue);
    });

    test('moves the earlier theme key once; a newer value wins', () async {
      final Box box = await Hive.openBox('settings');
      final SettingsStore store = SettingsStore.withBox(box);
      await box.put(SettingsStore.legacyThemeModeKey, 'light');
      await store.migrateLegacyMode();
      expect(box.get('appearance.mode'), 'light');
      expect(box.containsKey(SettingsStore.legacyThemeModeKey), isFalse);
      await box.put(SettingsStore.legacyThemeModeKey, 'dark');
      await store.migrateLegacyMode();
      expect(store.appearanceMode, AppearanceMode.light);
    });
  });
}
