// Copyright 2026 R. Heller
// SPDX-License-Identifier: Apache-2.0
//
// coder_theme.dart - generated from _style/tokens/coder-design-system.json
// DO NOT hand-edit values. Re-derive from the central token file at build time
// (tool/sync_style.sh copies this in). Editing here causes drift across the suite.

import 'package:flutter/material.dart';

class Coder {
  static const accentBase = Color(0xFF28A745);
  static const accentDark = Color(0xFF1E7E34);
  static const accentLight = Color(0xFF48C76A);

  // light
  static const lBackground = Color(0xFFFFFFFF);
  static const lSurface = Color(0xFFF7F8FA);
  static const lSurfaceAlt = Color(0xFFEDEFF2);
  static const lTextPrimary = Color(0xFF1A1C1E);
  static const lTextSecondary = Color(0xFF5A5F66);
  static const lBorder = Color(0xFFD9DCE1);
  static const lError = Color(0xFFD32F2F);

  // dark
  static const dBackground = Color(0xFF121417);
  static const dSurface = Color(0xFF1A1D21);
  static const dSurfaceAlt = Color(0xFF22262B);
  static const dTextPrimary = Color(0xFFF2F4F6);
  static const dTextSecondary = Color(0xFFA6ACB3);
  static const dBorder = Color(0xFF33373D);
  static const dError = Color(0xFFEF5350);

  static const xs = 4.0, sm = 8.0, md = 16.0, lg = 24.0, xl = 32.0, xxl = 48.0;
  static const radiusSm = 6.0, radiusMd = 10.0, radiusLg = 16.0;
  static const fontMono = 'JetBrains Mono';

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final isDark = b == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentBase,
        brightness: b,
      ),
      scaffoldBackgroundColor: isDark ? dBackground : lBackground,
    );
  }
}
