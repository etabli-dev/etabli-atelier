// Établi Atelier — centralized theme tokens.
//
// This is the SINGLE source of truth for colors, spacing, radii, borders and
// typography. Per the design spec ("Coder/Hugo" aesthetic): minimal,
// whitespace-heavy, monospaced, single teal/green accent, borders over shadows.
//
// Do NOT hardcode colors, paddings or font families anywhere else — reference
// these tokens. If you find yourself writing a raw Color(0x...) outside this
// file, add a token here instead.

import 'package:flutter/material.dart';

/// Raw color palette. Light/Dark variants are resolved via [AppTheme].
abstract final class AppColors {
  AppColors._();

  /// The one accent — teal/green. Same in both light and dark.
  static const Color accent = Color(0xFF28A745);
  static const Color accentMuted = Color(0xFF1E7E34);

  // Light surfaces.
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFAFAFA);
  static const Color lightSurfaceAlt = Color(0xFFF2F2F2);
  static const Color lightBorder = Color(0xFFE3E3E3);
  static const Color lightText = Color(0xFF1A1A1A);
  static const Color lightTextMuted = Color(0xFF6A6A6A);

  // Dark surfaces.
  static const Color darkBackground = Color(0xFF111315);
  static const Color darkSurface = Color(0xFF16191C);
  static const Color darkSurfaceAlt = Color(0xFF1D2125);
  static const Color darkBorder = Color(0xFF2A2F35);
  static const Color darkText = Color(0xFFE6E6E6);
  static const Color darkTextMuted = Color(0xFF8A9199);

  // Semantic (kernel/output) — used by console & warnings later.
  static const Color danger = Color(0xFFD73A49);
  static const Color warning = Color(0xFFE0A106);
  static const Color rAccent = Color(0xFF276DC3); // R blue
  static const Color pyAccent = Color(0xFFFFD43B); // Python yellow
}

/// Whitespace scale (4pt grid). Whitespace-heavy by design.
abstract final class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
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

  /// Bundled font family (registered in pubspec under this family name).
  /// Falls back to platform monospace if the asset is missing.
  static const String mono = 'JetBrainsMono';
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
