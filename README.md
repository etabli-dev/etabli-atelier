# Établi Atelier

> Run R and Python on your phone, fully offline.

`Android` · iOS and desktop runners require platform verification · Apache-2.0 · Part of the [Établi Suite](https://github.com/etabli-dev)

Établi Atelier is an offline polyglot IDE that runs R (via WebR) and Python (via Pyodide) as switchable kernels inside an embedded runtime, with a shared virtual filesystem between the two. numpy, pandas, scipy, matplotlib and scikit-learn come pre-bundled. Capture base-R and matplotlib plots to PNG; additional R packages such as ggplot2 require a separate package installation. No account is required for local execution.

## Availability

Établi Atelier is **under active development**. There are no App Store, Google Play or F-Droid releases yet.

- **Android:** build a development APK using the commands below. Automatic CI APK uploads are paused pending the runtime source-delivery checks in [THIRD_PARTY.md](THIRD_PARTY.md); older release downloads do not establish current readiness.
- **App Store (iOS):** planned — not yet available.
- **Google Play:** planned — not yet available.
- **F-Droid:** planned — not yet available.
- **Desktop runners:** experimental; desktop builds and embedded-WebView support have not been verified in this refinement.

## Privacy

The bundled examples and runtimes work without an external connection. No analytics or account service is configured. Imported code runs with WebView capabilities and can request network resources; it is not an isolated sandbox for untrusted programs. Workspaces and imported sources are stored locally and may be included in platform backups. Dependencies and runtime notices are listed in THIRD_PARTY.md.

## Repository layout

```
lib/         app, features, data, theme, widgets
android/     Android runner
ios/         iOS runner
macos/ windows/ linux/    desktop runners
.fdroid.yml  disabled F-Droid draft; see FDROID_NOTES.md
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

## Reproduce the October 2026 verification

Prerequisites: Flutter **3.47.9** (Dart 3.13.7), Python 3.9+, Node 22+, JDK 17, Android SDK platform 36 and build-tools 35.0.0. Set `JAVA_HOME` and `ANDROID_HOME`. Xcode is additionally required for iOS builds.

```sh
python3 tool/test_fetch_runtimes.py
bash tool/fetch_runtimes.sh
flutter pub get --enforce-lockfile
flutter analyze
flutter test
npm --prefix tool ci
(cd tool && npx playwright install chromium)
npm --prefix tool test
flutter run
# Or build an Android test APK:
flutter build apk --debug --target-platform android-arm64
```

The first runtime preparation needs network access and roughly 500 MB of upstream downloads. It caches verified inputs under `~/.cache/etabli-runtimes`; use `--cache-dir PATH --offline` for a populated offline cache. Runtime tests boot the actual bundled code in Chromium, blocking external requests. This supplements Flutter tests but does not replace device/WebView testing.

Current repairs, observed checks and remaining distribution gates are recorded in [the refinement record](docs/refinement-2026-10.md). Runtime redistribution requirements are in [THIRD_PARTY.md](THIRD_PARTY.md).
