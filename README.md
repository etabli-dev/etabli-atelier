# Établi Atelier

> Run R and Python on your phone, fully offline.

`iOS` `Android` `macOS` `Windows` `Linux` · Apache-2.0 · Part of the [Établi Suite](https://github.com/etabli-dev)

Établi Atelier is an offline polyglot IDE that runs R (via WebR) and Python (via Pyodide) as switchable kernels inside an embedded runtime, with a shared virtual filesystem between the two. numpy, pandas, scipy, matplotlib and scikit-learn come pre-bundled. Capture base-R, ggplot2 and matplotlib plots to PNG. No network, no analytics, no accounts.

## Availability

Établi Atelier is **under active development**. There are no App Store, Google Play or F-Droid releases yet.

- **Android:** install the current **development build** as a signed **APK** from **[GitHub Releases](../../releases)**.
- **App Store (iOS):** planned — not yet available.
- **Google Play:** planned — not yet available.
- **F-Droid:** planned — not yet available.
- **Desktop (macOS, Windows, Linux):** build from source.

## Privacy

No analytics. No third-party SDKs. No accounts. Credentials, where needed, live only in the platform secure store (iOS Keychain / Android EncryptedSharedPreferences). This app is fully offline.

## Repository layout

```
lib/         app, features, data, theme, widgets
android/     Android runner
ios/         iOS runner
macos/ windows/ linux/    desktop runners
.fdroid.yml  F-Droid build recipe (main-repo submission)
fastlane/    store + F-Droid listing metadata
```

## Tech

Dart 3.12+, flutter_riverpod, hive, flutter_inappwebview, flutter_code_editor

**Status:** In active development — not yet released; dev builds available as a signed APK via [GitHub Releases](../../releases).

## Support development

- 💚 **[Liberapay](https://liberapay.com/rabanheller/)** — recurring, 0% commission, to be shown on the F-Droid listing once published.

## License

Apache License 2.0 — see [LICENSE](LICENSE) and [NOTICE](NOTICE).

Copyright 2026 R. Heller.
