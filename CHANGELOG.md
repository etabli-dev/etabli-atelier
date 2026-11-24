# Changelog

## Unreleased

### Added

- Settings → Appearance: the app language (System / Deutsch / English), the mode (System / Light / Dark) and
  an accent colour (Coder blue, Green, Yellow, Orange, Red, Purple, Graphite), the same keys, values and order
  as the other Établi apps. All three apply at once and are stored under `app.language`, `appearance.mode`
  and `appearance.accent`; unknown stored values fall back to System and Coder blue. The earlier theme
  setting carries over.
- German translation of every screen, menu, dialog, error, console notice and accessibility label
  (`lib/l10n/app_de.arb`); English stays the fallback for other device languages.
- `integration_test/tour_test.dart`: a screenshot tour of every pane, menu and dialog in English and German
  that also runs R and Python on the device's WebView.

### Changed

- Colours follow the Hugo Coder palette (background #FAFAFA / #212121, text #212121 / #DADADA, surface
  #E0E0E0 / #424242) with Coder blue as the default accent instead of the fixed green. Selection fills of
  the yellow and orange accents are neutral grey, so no background is tinted yellow.
- Labels never wrap or truncate on a 375-pt iPhone; the German Settings tab reads "Optionen" and keeps
  "Einstellungen" as its title and accessibility label.
- The bundled JetBrains Mono font is now actually used (the theme named a family that did not exist).
- The package log replaces its "installing" entry with the results instead of leaving an hourglass behind.
- A failed start of the local runtime server is shown in the console instead of "Booting kernel…" forever.
- iOS: declares English and German (`CFBundleLocalizations`) and `ITSAppUsesNonExemptEncryption` = false.
