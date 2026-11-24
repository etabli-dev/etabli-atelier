// Copyright 2026 R. Heller
// SPDX-License-Identifier: AGPL-3.0-only
//
// coder_theme.dart - the suite's shared spacing, radius and type tokens.
// Colours are no longer fixed here: the Hugo Coder neutrals and the user's accent come from
// appearance.dart (the same model as the native apps' AppearanceModel.swift).

class Coder {
  static const xs = 4.0, sm = 8.0, md = 16.0, lg = 24.0, xl = 32.0, xxl = 48.0;
  static const radiusSm = 6.0, radiusMd = 10.0, radiusLg = 16.0;
  // The family name declared in pubspec.yaml for the bundled JetBrains Mono files.
  static const fontMono = 'JetBrainsMono';
}
