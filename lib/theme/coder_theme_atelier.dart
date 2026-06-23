// Copyright 2026 Raban Heller
// SPDX-License-Identifier: Apache-2.0

// Établi Atelier — atelier-specific theme glue.
//
// Central palette/spacing/typography come from `coder_theme.dart` (synced from
// `_style/tokens/coder-design-system.json` via tool/sync_style.sh). Anything
// truly atelier-specific (semantic colors for kernel state, R/Python brand
// accents) lives here. No raw hex anywhere else in the codebase.

import 'package:flutter/material.dart';

import 'coder_theme.dart';

/// Raw color palette. Central tokens (palette + accent) come from [Coder];
/// atelier-only semantic colors live below.
abstract final class AppColors {
  AppColors._();

  /// The one accent — teal/green. Same in both light and dark.
  static const Color accent = Coder.accentBase;
  static const Color accentMuted = Coder.accentDark;

  // Light surfaces (central tokens).
  static const Color lightBackground = Coder.lBackground;
  static const Color lightSurface = Coder.lSurface;
  static const Color lightSurfaceAlt = Coder.lSurfaceAlt;
  static const Color lightBorder = Coder.lBorder;
  static const Color lightText = Coder.lTextPrimary;
  static const Color lightTextMuted = Coder.lTextSecondary;

  // Dark surfaces (central tokens).
  static const Color darkBackground = Coder.dBackground;
  static const Color darkSurface = Coder.dSurface;
  static const Color darkSurfaceAlt = Coder.dSurfaceAlt;
  static const Color darkBorder = Coder.dBorder;
  static const Color darkText = Coder.dTextPrimary;
  static const Color darkTextMuted = Coder.dTextSecondary;

  // Atelier-specific semantic & brand colors. R blue and Python yellow are
  // external project marks and don't belong in the central token set.
  static const Color danger = Color(0xFFD73A49);
  static const Color warning = Color(0xFFE0A106);
  static const Color rAccent = Color(0xFF276DC3); // R blue
  static const Color pyAccent = Color(0xFFFFD43B); // Python yellow
}

/// Whitespace scale (4pt grid). Whitespace-heavy by design.
abstract final class AppSpacing {
  AppSpacing._();
  static const double xs = Coder.xs;
  static const double sm = Coder.sm;
  static const double md = Coder.md;
  static const double lg = Coder.lg;
  static const double xl = Coder.xl;
  static const double xxl = Coder.xxl;
}

/// Border radii — kept tight; the aesthetic favors crisp edges.
abstract final class AppRadius {
  AppRadius._();
  static const double sm = 4;
  static const double md = 6;
  static const Radius smRadius = Radius.circular(sm);
  static const Radius mdRadius = Radius.circular(md);
}

/// Borders over shadows. Single hairline width everywhere.
abstract final class AppBorders {
  AppBorders._();
  static const double width = 1;
}

/// Typography. Everything is monospaced — labels, code, data.
abstract final class AppFonts {
  AppFonts._();

  static const String mono = Coder.fontMono;
  static const List<String> monoFallback = <String>[
    'monospace',
    'Menlo',
    'Consolas',
  ];
}

/// Builds the two [ThemeData]s from the tokens above.
abstract final class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;

    final Color background =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final Color surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final Color border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final Color text = isDark ? AppColors.darkText : AppColors.lightText;
    final Color textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    final ColorScheme scheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.accent,
      onPrimary: Colors.white,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      error: AppColors.danger,
      onError: Colors.white,
      surface: surface,
      onSurface: text,
    );

    final TextTheme textTheme = _monoTextTheme(text, textMuted);

    final BorderSide hairline =
        BorderSide(color: border, width: AppBorders.width);
    final OutlineInputBorder inputBorder = OutlineInputBorder(
      borderRadius: const BorderRadius.all(AppRadius.smRadius),
      borderSide: hairline,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      fontFamily: AppFonts.mono,
      fontFamilyFallback: AppFonts.monoFallback,
      textTheme: textTheme,
      dividerTheme: DividerThemeData(
        color: border,
        thickness: AppBorders.width,
        space: AppBorders.width,
      ),
      // Borders over shadows: zero elevation everywhere.
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleMedium,
        shape: Border(bottom: hairline),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(AppRadius.mdRadius),
          side: hairline,
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        elevation: 0,
        indicatorColor: AppColors.accent.withValues(alpha: 0.16),
        selectedIconTheme: const IconThemeData(color: AppColors.accent),
        unselectedIconTheme: IconThemeData(color: textMuted),
        selectedLabelTextStyle:
            textTheme.labelMedium?.copyWith(color: AppColors.accent),
        unselectedLabelTextStyle:
            textTheme.labelMedium?.copyWith(color: textMuted),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        elevation: 0,
        height: 64,
        indicatorColor: AppColors.accent.withValues(alpha: 0.16),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected)
                ? AppColors.accent
                : textMuted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.accent
                : textMuted,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: textMuted),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: textTheme.labelLarge,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(AppRadius.smRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: hairline,
          textStyle: textTheme.labelLarge,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(AppRadius.smRadius),
          ),
        ),
      ),
      iconTheme: IconThemeData(color: text, size: 20),
      listTileTheme: ListTileThemeData(
        iconColor: textMuted,
        textColor: text,
        dense: true,
      ),
      splashFactory: NoSplash.splashFactory,
    );
  }

  static TextTheme _monoTextTheme(Color text, Color muted) {
    TextStyle base(double size, {FontWeight weight = FontWeight.w400}) =>
        TextStyle(
          fontFamily: AppFonts.mono,
          fontFamilyFallback: AppFonts.monoFallback,
          fontSize: size,
          fontWeight: weight,
          color: text,
          height: 1.4,
        );
    return TextTheme(
      titleLarge: base(20, weight: FontWeight.w600),
      titleMedium: base(16, weight: FontWeight.w600),
      titleSmall: base(14, weight: FontWeight.w600),
      bodyLarge: base(15),
      bodyMedium: base(14),
      bodySmall: base(13).copyWith(color: muted),
      labelLarge: base(14, weight: FontWeight.w500),
      labelMedium: base(13, weight: FontWeight.w500),
      labelSmall: base(11, weight: FontWeight.w500),
    );
  }
}
