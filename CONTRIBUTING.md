# Contributing to Etabli Atelier

This project is dual-licensed: AGPL-3.0-only, or a commercial licence from the copyright
holder (etabli.dev@outlook.com). Please open an issue before proposing changes; contributions can only be accepted
under a written contributor agreement that allows the copyright holder to offer both licences.

## House rules
- **Privacy is a hard constraint.** No analytics, telemetry, or third-party SDKs.
- **Dependencies must be FOSS** and buildable from a trusted source — this is what
  keeps the app eligible for F-Droid. No Firebase, no GMS.
- **Shared design tokens.** Hugo Coder neutrals and the suite's accent set (default Coder blue),
  System/Light/Dark, in `lib/theme/appearance.dart`, identical in every Établi Flutter app. Don't fork the palette.
- **Every user-facing string in both languages.** Add it to `lib/l10n/app_en.arb` and `app_de.arb`, then run
  `flutter gen-l10n`. Labels must not wrap on a 375-pt phone in either language.

## Releases (maintainer)
Each release commit carries a matching tag (`v1.0`). Keep `fastlane/metadata/` current.
