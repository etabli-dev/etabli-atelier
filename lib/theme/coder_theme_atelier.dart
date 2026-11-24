// Copyright 2026 R. Heller
// SPDX-License-Identifier: AGPL-3.0-only

// Établi Atelier — theme glue.
//
// The neutrals are the Hugo Coder palette and the accent is the user's choice (appearance.dart). Widgets read
// colours from the theme ([AtelierColors.of], `Theme.of(context).colorScheme`), never a fixed accent.
// Anything truly atelier-specific (the R/Python marks) lives here. No raw hex anywhere else in the codebase.

import 'package:flutter/material.dart';

import 'appearance.dart';
import 'coder_theme.dart';

/// Colours that are not part of the user's appearance choice.
abstract final class AppColors {
  AppColors._();

  // R blue and Python yellow are external project marks, drawn as small dots only.
  static const Color rAccent = Color(0xFF276DC3); // R blue
  static const Color pyAccent = Color(0xFFFFD43B); // Python yellow
}

/// The resolved palette of the current theme: Hugo Coder neutrals, the accent and the state colours.
@immutable
class AtelierColors extends ThemeExtension<AtelierColors> {
  const AtelierColors({
    required this.accent,
    required this.onAccent,
    required this.selection,
    required this.background,
    required this.surface,
    required this.border,
    required this.text,
    required this.textMuted,
    required this.success,
    required this.warning,
    required this.danger,
  });

  factory AtelierColors.resolve(Brightness b, AccentChoice accent) =>
      AtelierColors(
        accent: accent.color(b),
        onAccent: CoderPalette.color(CoderPalette.onAccent(b)),
        selection: accent.selectionColor(b),
        background: CoderPalette.color(CoderPalette.background(b)),
        surface: CoderPalette.color(CoderPalette.surface(b)),
        border: CoderPalette.color(CoderPalette.border(b)),
        text: CoderPalette.color(CoderPalette.foreground(b)),
        textMuted: CoderPalette.color(CoderPalette.muted(b)),
        success: CoderPalette.color(CoderPalette.success(b)),
        warning: CoderPalette.color(CoderPalette.warning(b)),
        danger: CoderPalette.color(CoderPalette.danger(b)),
      );

  /// The user's accent: text, icons, outlines and solid fills.
  final Color accent;

  /// Text and symbols on an accent (or danger) fill.
  final Color onAccent;

  /// The colour of selection fills and tints, to draw at [AccentChoice.selectionOpacity] (neutral for yellow
  /// and orange).
  final Color selection;
  final Color background;
  final Color surface;
  final Color border;
  final Color text;
  final Color textMuted;
  final Color success;
  final Color warning;
  final Color danger;

  /// [selection] at the selection-fill opacity.
  Color get selectionFill =>
      selection.withValues(alpha: AccentChoice.selectionOpacity);

  static AtelierColors of(BuildContext context) =>
      Theme.of(context).extension<AtelierColors>() ??
      AtelierColors.resolve(
        Theme.of(context).brightness,
        AccentChoice.coderBlue,
      );

  @override
  AtelierColors copyWith({
    Color? accent,
    Color? onAccent,
    Color? selection,
    Color? background,
    Color? surface,
    Color? border,
    Color? text,
    Color? textMuted,
    Color? success,
    Color? warning,
    Color? danger,
  }) => AtelierColors(
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    selection: selection ?? this.selection,
    background: background ?? this.background,
    surface: surface ?? this.surface,
    border: border ?? this.border,
    text: text ?? this.text,
    textMuted: textMuted ?? this.textMuted,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    danger: danger ?? this.danger,
  );

  @override
  AtelierColors lerp(AtelierColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AtelierColors(
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      selection: l(selection, other.selection),
      background: l(background, other.background),
      surface: l(surface, other.surface),
      border: l(border, other.border),
      text: l(text, other.text),
      textMuted: l(textMuted, other.textMuted),
      success: l(success, other.success),
      warning: l(warning, other.warning),
      danger: l(danger, other.danger),
    );
  }
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
    'Menlo',
    'monospace',
    'Consolas',
  ];
}

/// Builds the [ThemeData] for a mode and accent.
abstract final class AppTheme {
  AppTheme._();

  static ThemeData get light => build(Brightness.light, AccentChoice.coderBlue);
  static ThemeData get dark => build(Brightness.dark, AccentChoice.coderBlue);

  static ThemeData build(Brightness brightness, AccentChoice accentChoice) {
    final AtelierColors c = AtelierColors.resolve(brightness, accentChoice);
    final Color accent = c.accent;
    final Color selectionFill = c.selectionFill;

    // Containers (cards, dialogs, menus, bars) use the page background, so accent text on them keeps at
    // least 4.5:1; the Coder surface grey is reserved for input fields.
    final ColorScheme scheme = ColorScheme(
      brightness: brightness,
      primary: accent,
      onPrimary: c.onAccent,
      primaryContainer: selectionFill,
      onPrimaryContainer: c.text,
      secondary: accent,
      onSecondary: c.onAccent,
      secondaryContainer: selectionFill,
      onSecondaryContainer: c.text,
      tertiary: accent,
      onTertiary: c.onAccent,
      tertiaryContainer: selectionFill,
      onTertiaryContainer: c.text,
      error: c.danger,
      onError: c.onAccent,
      surface: c.background,
      onSurface: c.text,
      onSurfaceVariant: c.textMuted,
      surfaceContainerLowest: c.background,
      surfaceContainerLow: c.background,
      surfaceContainer: c.background,
      surfaceContainerHigh: c.background,
      surfaceContainerHighest: c.surface,
      outline: c.border,
      outlineVariant: c.border,
      inverseSurface: c.text,
      onInverseSurface: c.background,
      inversePrimary: accentChoice.color(
        brightness == Brightness.dark ? Brightness.light : Brightness.dark,
      ),
      // No accent tint on elevated surfaces (dialogs, menus): it would put a yellow shade in a background.
      surfaceTint: Colors.transparent,
      shadow: Colors.black,
      scrim: Colors.black,
    );

    final TextTheme textTheme = _monoTextTheme(c.text, c.textMuted);

    final BorderSide hairline = BorderSide(
      color: c.border,
      width: AppBorders.width,
    );
    final OutlineInputBorder inputBorder = OutlineInputBorder(
      borderRadius: const BorderRadius.all(AppRadius.smRadius),
      borderSide: hairline,
    );
    final WidgetStateProperty<Color?> selectionOverlay =
        WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.pressed) ||
                  states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.focused)
              ? selectionFill
              : null,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      extensions: <ThemeExtension<dynamic>>[c],
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      fontFamily: AppFonts.mono,
      fontFamilyFallback: AppFonts.monoFallback,
      textTheme: textTheme,
      dividerTheme: DividerThemeData(
        color: c.border,
        thickness: AppBorders.width,
        space: AppBorders.width,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: accent,
        selectionColor: c.selection.withValues(
          alpha: AccentChoice.textSelectionOpacity,
        ),
        selectionHandleColor: accent,
      ),
      // Borders over shadows: zero elevation everywhere.
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleMedium,
        shape: Border(bottom: hairline),
      ),
      cardTheme: CardThemeData(
        color: c.background,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(AppRadius.mdRadius),
          side: hairline,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(AppRadius.mdRadius),
          side: hairline,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: c.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(AppRadius.mdRadius),
          side: hairline,
        ),
        textStyle: textTheme.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.text,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: c.background),
        actionTextColor: c.background,
        behavior: SnackBarBehavior.floating,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: c.background,
        elevation: 0,
        indicatorColor: selectionFill,
        selectedIconTheme: IconThemeData(color: accent),
        unselectedIconTheme: IconThemeData(color: c.textMuted),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(color: accent),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: c.textMuted,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        indicatorColor: selectionFill,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected) ? accent : c.textMuted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? accent : c.textMuted,
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? selectionFill
                : Colors.transparent,
          ),
          // Labels on a selection fill stay in the text colour (at least 4.5:1 on every fill).
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) =>
                states.contains(WidgetState.disabled) ? c.textMuted : c.text,
          ),
          overlayColor: selectionOverlay,
          side: WidgetStatePropertyAll(hairline),
          textStyle: WidgetStatePropertyAll(textTheme.labelMedium),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: c.textMuted),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: c.onAccent,
          elevation: 0,
          textStyle: textTheme.labelLarge,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(AppRadius.smRadius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) =>
                states.contains(WidgetState.disabled) ? c.textMuted : accent,
          ),
          overlayColor: selectionOverlay,
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.text,
          side: hairline,
          textStyle: textTheme.labelLarge,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(AppRadius.smRadius),
          ),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: c.border,
        thumbColor: accent,
        overlayColor: selectionFill,
        valueIndicatorColor: accent,
        valueIndicatorTextStyle: textTheme.labelMedium?.copyWith(
          color: c.onAccent,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent,
        circularTrackColor: Colors.transparent,
        linearTrackColor: c.border,
      ),
      iconTheme: IconThemeData(color: c.text, size: 20),
      listTileTheme: ListTileThemeData(
        iconColor: c.textMuted,
        textColor: c.text,
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
