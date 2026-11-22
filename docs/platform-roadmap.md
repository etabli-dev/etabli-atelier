# Platform roadmap

Établi Atelier · state as of 2026-11-08 · this is a plan. Observed results stay in the
[current status page](current-status.qmd) and the [refinement record](refinement-2026-10.md);
runtime licensing and the distribution gate are in
[THIRD_PARTY.md](https://github.com/etabli-dev/etabli-atelier/blob/main/THIRD_PARTY.md) and
[FDROID_NOTES.md](https://github.com/etabli-dev/etabli-atelier/blob/main/FDROID_NOTES.md).

## 1. Platform role

Établi Atelier is a **mobile-only** app for Android and iOS, **including tablets** (Android
tablets and iPad). Its point is running R and Python offline on a device that otherwise has
neither: no server, no connection, one shared workspace.

No Ubuntu/Debian, Windows or macOS application is planned. Desktops already have native R and
Python, RStudio, Positron, Jupyter and full browsers that can run WebR and Pyodide directly; a
desktop build of Atelier would be a weaker copy of tools that exist there.

| Platform | Role | Used for |
|---|---|---|
| Android (phones, tablets) | release target | signed APK on GitHub Releases, Google Play, F-Droid if a source-build route is found |
| iOS / iPadOS | release target | TestFlight, then App Store, subject to decisions D4 and D5 |
| Ubuntu/Debian, Windows, macOS | not planned | native R/Python, RStudio or Positron, Jupyter, or WebR/Pyodide in a browser |

## 2. Current state

| Platform | Status | Technology | How it is built | What is verified | Distribution |
|---|---|---|---|---|---|
| Android | in development | Flutter 3.47.9 / Dart 3.13.7; flutter_inappwebview 6.2.0-beta.3 on Android System WebView; WebR 0.6.0, Pyodide 0.27.7; minSdk 24, target 36; AGP 9.0.1, Gradle 9.1.0. Release builds use private keystore.properties when supplied and otherwise remain unsigned | `bash tool/fetch_runtimes.sh`, then `flutter build apk --debug --target-platform android-arm64`; CI `.github/workflows/app.yml` (ubuntu-24.04) | CI on 2026-10-31 (commit `1716676`): runtime preparation, analysis, Flutter tests, the offline R/Python journey in headless Chromium, APK build. Locally on an API 35 ARM64 emulator (2026-11-02, networking disabled): R and Python arithmetic, pandas/SciPy/scikit-learn, both plot examples, saved files kept across an in-place upgrade. Not verified: a physical device, 16 KB page-size execution, online package installation, release signing | GitHub Releases `v0.1.0` (2026-06-24): one APK signed with the Android debug key, built before the October–November changes; its release notes state a SHA-256 (`fb29d76f…`) that differs from the attached file (GitHub's asset digest `44635c86…` matches the file). Automatic CI APK uploads are paused by the THIRD_PARTY.md source-delivery gate |
| iOS | simulator compilation verified | Flutter iOS runner, deployment target 15.0; WKWebView; native file export share sheet | `flutter build ios --simulator --debug --no-codesign --no-pub`; macOS CI job added | Local unsigned simulator build, analyzer and 12 Flutter tests passed on 2026-11-08. Live kernel/share-sheet interaction on devices remains open | none |
| Ubuntu/Debian | not planned | generated Flutter `linux/` runner; the locked WebView plugin's Linux part is a 0.1.0 beta | never built (no CI job, no recorded build) | nothing | none |
| Windows | not planned | generated Flutter `windows/` runner | never built | nothing | none |
| macOS | not planned | generated Flutter `macos/` runner | never built | nothing | none |

## 3. Architecture

**Now.** One Dart codebase in `lib/` serves every runner:

- `lib/kernel/runtime_server.dart`: an in-app `InAppLocalhostServer` on port 51736 serves
  `assets/web/` and the prepared `assets/runtimes/` over `http://localhost`.
- `lib/kernel/kernel_host.dart` and `assets/web/kernel_host.js`: one WebView hosts WebR (over
  its PostMessage channel, so no SharedArrayBuffer or cross-origin isolation is needed) and
  Pyodide.
- `lib/fs/`: the workspace in app storage, mirrored into the runtimes' file system.
- `lib/features/`: Files, Editor, Console, Plots, Packages, Settings; `lib/app/shell.dart` is the
  responsive shell.
- Runtimes are prepared by `tool/fetch_runtimes.sh` from `tool/runtimes.lock.json` (pinned
  URLs and SHA-256) and are identical for Android and iOS.

Platform-specific parts are only the runner folders, the cleartext-to-localhost rules
(`android/app/src/main/res/xml/network_security_config.xml`, `NSAllowsLocalNetworking` in
`ios/Runner/Info.plist`) and the plugins (flutter_inappwebview, file_selector, path_provider,
hive, flutter_secure_storage).

**Target.** Unchanged: one Flutter codebase, Android and iOS runners as the only release
targets, desktop runner folders removed (section 4.7, recommendation). Platform differences
stay limited to runner configuration and, if decision D5 requires it, a build-time switch for
the online Packages pane on iOS.

## 4. Per-platform execution

### 4.1 Android

Android is ahead: iOS has no feature that Android lacks. The remaining Android work is release
readiness.

| # | Item | Where it stands | Work | Accepted when |
|---|---|---|---|---|
| A1 | Release signing | `android/app/build.gradle.kts`: release build type uses `signingConfigs.getByName("debug")` | Load `android/keystore.properties` when present, as the native Établi apps do (`android/app/build.gradle.kts` in etabli-doc); keep the debug fallback only for local `flutter run --release`. `.gitignore` already excludes keystores and `keystore.properties` | The release workflow fails unless `apksigner` shows the owner's certificate |
| A2 | Corresponding-source delivery for the GPL runtime | THIRD_PARTY.md "Distribution gate": open | Collect matching sources and build scripts for every bundled runtime and package version, verify them against the binary inputs, and publish a source archive or durable source download beside every binary | THIRD_PARTY.md records the gate as closed with evidence; every release carries its source bundle |
| A3 | Export of workspace files | Files can be created, imported, renamed, moved and deleted, but not exported | Add "Share/Save a copy" for files (Android share sheet or `ACTION_CREATE_DOCUMENT`; iOS share sheet), on both platforms | A saved script can be moved to another app or device; users can keep their files across the signing change in A1 |
| A4 | Release size | debug arm64 APK: 188,900,091 bytes (2026-11-02) | Build the release AAB, run `bundletool build-apks` and `bundletool get-size total`; if the base module exceeds Google Play's download-size limit, move the runtimes into a Play Asset Delivery install-time pack or reduce the bundled packages | Measured size recorded here and within the limit current at submission |
| A5 | ABIs | the verified debug build contains only the arm64 Flutter engine; the `v0.1.0` APK carried arm64-v8a, armeabi-v7a and x86_64 engines | Choose release ABIs (D6) | Each shipped ABI installed and run once |
| A6 | Device coverage | API 35 ARM64 emulator, 4 KB pages | Run the offline journey on one physical phone, one physical or emulated tablet and a 16 KB page-size emulator image | All pass; results in `docs/current-status.qmd` |
| A7 | Online package installation | not exercised on a device (journeys ran with networking disabled) | Install one R package (webR repository) and one Python package (PyPI) on a device; failures must be visible | Installed package loads; offline use unaffected |
| A8 | Pre-release WebView plugin | `pubspec.yaml` pins `flutter_inappwebview: 6.2.0-beta.3` | Move to a stable release once one supports the current toolchain; re-run all runtime tests | Lockfile on a stable version, CI green |

**Build and run**

```sh
python3 tool/test_fetch_runtimes.py
bash tool/fetch_runtimes.sh
flutter pub get --enforce-lockfile
flutter analyze
flutter test
npm --prefix tool ci
(cd tool && npx playwright install chromium)
npm --prefix tool test
flutter build apk --debug --target-platform android-arm64
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

Release candidate, after A1 and with `android/keystore.properties` in place:

```sh
flutter build appbundle --release --build-name="$VERSION" --build-number="$BUILD"
flutter build apk --release --split-per-abi --build-name="$VERSION" --build-number="$BUILD"
"$ANDROID_HOME/build-tools/35.0.0/apksigner" verify --print-certs build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
"$ANDROID_HOME/build-tools/35.0.0/zipalign" -c -P 16 -v 4 build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

**Packages and channels** (none of them before A2 is closed)

- *GitHub Releases:* signed APK per chosen ABI, the corresponding-source bundle and
  `SHA256SUMS`; the hashes in the release notes must equal GitHub's asset digests. A
  release-signed APK cannot update the debug-signed `v0.1.0` install, and uninstalling deletes
  the workspace: ship A3 first and tell users to export their files before uninstalling.
- *Google Play:* AAB with Play App Signing; internal testing, closed testing, production. Code
  that users write or install runs inside the WebView's JavaScript/WebAssembly engine; describe
  this and the two online package sources in the review notes and the privacy policy. The first
  upload of a new app is done in Play Console.
- *F-Droid:* the disabled `.fdroid.yml` draft and FDROID_NOTES.md list the blockers: the
  runtimes are prebuilt WebAssembly binaries (F-Droid's main repository builds from source),
  the GPL source delivery, version codes and signing. Treat F-Droid as the last Android channel.

**Signing prerequisites (owner):** an app signing key and an upload key per D1, kept outside
the repository with backups; a Google Play developer account (D3); privacy policy URL (D8). CI
secrets in a GitHub environment `release` with the owner as required reviewer:
`ANDROID_KEYSTORE_B64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`.

**CI**

- Keep `app.yml` as the per-push verification (APK uploads stay paused there).
- Add `.github/workflows/android-release.yml` once A1 and A2 are done: tags `v*` and
  `workflow_dispatch`; ubuntu-24.04; environment `release`; workflow `permissions: contents:
  read`, `contents: write` only on the job that creates the draft release; reuse the pinned
  `actions/checkout`, `actions/setup-java` and `subosito/flutter-action` SHAs from `app.yml`.
  Steps: prepare and verify runtimes, `flutter pub get --enforce-lockfile`, analyze, test,
  write the keystore into `$RUNNER_TEMP` and `android/keystore.properties`, build AAB and APKs,
  verify signature and 16 KB alignment, build the source bundle from A2, write `SHA256SUMS`,
  `gh release create "$GITHUB_REF_NAME" --draft` with APKs, source bundle and checksums; keep
  the AAB as a workflow artifact for Play; remove key material in an `if: always()` step.

**Acceptance criteria (Android)**

- A1–A8 closed as stated in the table.
- The installed release candidate passes the recorded offline journey (R, Python, pandas,
  SciPy, scikit-learn, both plots, saved file across restart and upgrade) on a phone, a tablet
  and a 16 KB page-size image, with networking disabled.
- `apksigner` shows the owner's certificate; 16 KB alignment passes; a draft GitHub release
  contains APKs, source bundle and matching checksums.
- Play: internal-track install works; pre-launch report shows no crash; Data safety answers
  match the artifact.

### 4.2 iOS

**Feature gap: verified on Android, never built or run on iOS.** Every feature lives in the
shared Dart code; on iOS each one still needs a build, platform configuration and a run.

| # | Feature | Where it exists | iOS work | Accepted when |
|---|---|---|---|---|
| I1 | The app builds for iOS | all of `lib/`, runner `ios/` | Add an `ios` job to `app.yml` on macos-15: prepare runtimes, `flutter pub get --enforce-lockfile`, `flutter build ios --release --no-codesign` | Job green |
| I2 | Offline R kernel (WebR 0.6.0) | `lib/kernel/`, `assets/web/kernel_host.js`; verified on the Android emulator | Run in WKWebView from the localhost server; add an `integration_test` smoke test (R `6*7`, Python `print(6*7)`) run on an iOS simulator in CI | `[1] 42` on the simulator in CI and on an iPhone |
| I3 | Offline Python kernel (Pyodide 0.27.7 with NumPy, pandas, SciPy, matplotlib, scikit-learn) | same | Same test path; measure WKWebView memory on the oldest supported iPhone | pandas sum, SciPy solve, scikit-learn prediction pass on device |
| I4 | Plots (base R and matplotlib to PNG) | `lib/features/plots/` | — | Both bundled examples render on iPhone and iPad |
| I5 | Workspace, editor unsaved-change guard, file import | `lib/fs/`, `lib/features/editor/`, `lib/features/files/` (file_selector) | Check that the document picker copies into the workspace and that files survive relaunch and app update | Saved file reopens after relaunch and after a TestFlight update |
| I6 | Online package installation | `lib/features/packages/`, `kernel_host.js` (`webR.installPackages`, micropip) | Subject to D5 (App Review guideline 2.5.2 on downloaded executable code) | Either works as on Android or is switched off on iOS by a build flag with an explanatory message |
| I7 | Export compliance declaration | Établi Vitrine's `ios/Runner/Info.plist` has it | Add `ITSAppUsesNonExemptEncryption` = false to `ios/Runner/Info.plist` (only system TLS is used) | Key present in the archived app |
| I8 | Minimum iOS version | project setting 13.0 | Set it to the oldest iOS whose WebKit boots both runtimes in I2/I3 (WebR and Pyodide document minimum Safari versions) | Value documented here and in the README |

**Build and run** (a Mac with Xcode, or CI on macos-15):

```sh
python3 tool/test_fetch_runtimes.py
bash tool/fetch_runtimes.sh
flutter pub get --enforce-lockfile
flutter build ios --release --no-codesign          # compile check
flutter devices && flutter run -d <simulator-id>   # local Mac only
```

Archive and upload to App Store Connect (TestFlight):

```sh
flutter build ios --release --no-codesign --build-name="$VERSION" --build-number="$BUILD"
xcodebuild archive -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release \
  -destination 'generic/platform=iOS' -archivePath build/Runner.xcarchive \
  DEVELOPMENT_TEAM="$APPLE_TEAM_ID" -allowProvisioningUpdates \
  -authenticationKeyPath "$ASC_KEY_PATH" -authenticationKeyID "$ASC_KEY_ID" \
  -authenticationKeyIssuerID "$ASC_ISSUER_ID"
xcodebuild -exportArchive -archivePath build/Runner.xcarchive -exportPath build/export \
  -exportOptionsPlist "$RUNNER_TEMP/export.plist" -allowProvisioningUpdates \
  -authenticationKeyPath "$ASC_KEY_PATH" -authenticationKeyID "$ASC_KEY_ID" \
  -authenticationKeyIssuerID "$ASC_ISSUER_ID"
```

`export.plist` sets `method` = `app-store-connect`, `destination` = `upload` and `teamID`; write
it at run time because `.gitignore` excludes `ExportOptions.plist`.

**Distribution path:** TestFlight internal testing → external TestFlight (Beta App Review) →
App Store. Before external testing, decide D4 (GPL-licensed WebR under Apple's terms) and D5
(online package installation). Listing needs iPhone and iPad screenshots, privacy policy and
support URLs, App Privacy answers and review notes explaining that users write and run their
own R/Python code, fully viewable and editable in the app. The runner already has a privacy
manifest (`ios/Runner/PrivacyInfo.xcprivacy`); check Xcode's privacy report of the archive,
which includes the plugins' manifests.

**Signing prerequisites (owner):** Apple Developer Program membership and Team ID (D3); bundle
ID `com.raban.etabli.atelier` registered with an App Store Connect app record; an App Store
Connect API team key (Key ID, Issuer ID, `.p8`) whose role may manage signing, or additionally
an Apple Distribution certificate as `.p12`. CI secrets in environment `release`:
`APPLE_TEAM_ID`, `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8_B64`, and if needed
`IOS_DIST_CERT_P12_B64`, `IOS_DIST_CERT_PASSWORD`.

**CI**

- I1 adds the `ios` compile job to `app.yml`; I2 adds the simulator smoke test (boot a
  simulator with `xcrun simctl`, then `flutter test integration_test -d <id>`). Neither needs an
  Apple account.
- Add `.github/workflows/ios-release.yml` (macos-15, tags `v*` and `workflow_dispatch`,
  environment `release`, `permissions: contents: read`) after D3–D5: prepare runtimes, build,
  archive, export and upload as above; delete key material in an `if: always()` step.

**Acceptance criteria (iOS)**

- I1–I8 closed as stated in the table.
- On an iPhone and an iPad (TestFlight build), with networking off: the same offline journey as
  Android, including saved files across relaunch and a TestFlight update.
- VoiceOver reaches every pane and the kernel switcher; the largest Dynamic Type size stays
  usable.
- App Review approves the submission.

### 4.3 Tablets (Android tablets and iPad)

**Now.** `lib/app/shell.dart` switches at 720 dp from a bottom navigation bar to a navigation
rail and shows one pane at a time; the editor and console keep their state across the switch
(regression in `test/editor_preservation_test.dart`, 800→600→800 dp). The iPad declares all four
orientations; Android does not lock orientation. The console sends on Enter; the editor has no
keyboard shortcuts.

**Target.**

- At expanded width (840 dp and wider): Editor and Console side by side, Files as a collapsible
  side panel, Plots next to the Console; the same state-preserving keyed workspace subtree as
  today.
- Hardware keyboard: Ctrl/Cmd+Enter runs the current file or selection, Ctrl/Cmd+S saves;
  pointer hover and text selection with a mouse or trackpad.
- iPad Split View and Slide Over: narrow windows fall back to the phone layout without losing
  the draft.
- Android tablets, foldables and ChromeOS devices receive the app from Google Play by default:
  test them or restrict them in Play Console's device catalog.

**Acceptance.** Widget tests at 360×800, 800×1280, 1280×800 and 1366×1024 logical pixels with
state kept across every transition; a run on one Android tablet (emulator acceptable before
release) and one iPad (TestFlight).

### 4.4 Ubuntu/Debian — not planned

No Linux application is planned: R and Python are first-class on Linux. Users install them from
the distribution (`apt install r-base python3`) or upstream, and use RStudio, Positron,
JupyterLab or a terminal. Without installing anything, the webR REPL and Pyodide or JupyterLite
run the same runtimes in a browser.

### 4.5 Windows — not planned

No Windows application is planned: R from CRAN and Python from python.org, with RStudio,
Positron or JupyterLab, give a complete environment; the browser options above also work.

### 4.6 macOS — not planned

No macOS application is planned: R from CRAN and Python from python.org or Homebrew, with
RStudio, Positron or JupyterLab. App Store Connect offers iPhone and iPad apps on Apple silicon
Macs by default; decision D10 covers whether to opt out until that is tested.

### 4.7 Existing desktop runner folders (recommendation for the owner)

`linux/`, `macos/` and `windows/` were generated by `flutter create`, came in with the source
import and have never been built or verified. **Recommendation: remove them in a later,
separate commit** (decision D9), not now. Reasons: they are not a target; keeping them suggests
desktop support that does not exist; they add work to every Flutter migration; and the F-Droid
draft already deletes them before building. If desktop support is ever wanted,
`flutter create --platforms=linux,macos,windows .` regenerates them in minutes.

Removal steps once approved: `git rm -r linux macos windows`; drop the three platform entries
from the `migration` list in `.metadata`; update the README layout block; confirm
`flutter analyze`, `flutter test`, the Android build and the iOS compile job still pass. Until
then the folders stay as unverified scaffolding and no CI job builds them.

## 5. Milestones

Owner decisions (section 6) can be prepared in parallel with M1–M4.

1. **M1 — iOS compiles in CI.** I1 and I7. *Exit:* the `ios` job is green on macos-15.
2. **M2 — iOS runtime smoke on a simulator.** I2/I3 test path in CI. *Exit:* R and Python
   evaluate on an iOS simulator in CI; any WKWebView blocker is recorded here.
3. **M3 — Release-ready code.** A1 (signing config), A3 (file export), tablet layout (4.3).
   *Exit:* tests for each, CI green, tablet emulator check.
4. **M4 — Source delivery.** A2. *Exit:* THIRD_PARTY.md gate closed with evidence.
5. **M5 — Android device acceptance.** A6, A7, A8. *Exit:* journeys pass on phone, tablet and
   16 KB image; recorded in `docs/current-status.qmd`.
6. **M6 — Signed Android release on GitHub.** Needs D1, D2, D6. Add `android-release.yml`.
   *Exit:* draft release with signed APKs, source bundle and matching checksums; README
   availability updated; CI APK uploads may resume.
7. **M7 — Google Play.** A4, D3, D8. *Exit:* internal track installed; closed test completed
   where required; production approved.
8. **M8 — TestFlight.** Needs D3, D4, D5, D7. I4–I6, I8 on devices. *Exit:* processed build on an
   iPhone and an iPad; the iOS journey passes.
9. **M9 — App Store.** *Exit:* App Review approved, release published.
10. **M10 — F-Droid.** Needs D11 and a source-build route for the runtimes. *Exit:* recipe
    enabled and accepted, or the decision not to publish recorded here.
11. **M11 — Desktop runner folders.** After D9, at any point. *Exit:* folders removed per 4.7,
    or kept with the reason recorded here.

## 6. Owner decisions and prerequisites

| ID | Decision or prerequisite | Recommendation |
|---|---|---|
| D1 | Android signing model: own app signing key uploaded to Play App Signing plus an upload key, or a Google-generated app signing key | Own app signing key, so GitHub and Play installs share one signature |
| D2 | Version scheme, reconciled with the `.fdroid.yml` draft (versionCode `100002` for arm64) and Flutter's per-ABI version codes | One documented scheme before the first signed build; it can never go backwards |
| D3 | Store accounts: Google Play developer account and Apple Developer Program | Check Play's rule for new personal accounts (currently a closed test with 12 opted-in testers for 14 days) |
| D4 | GPL-3.0 WebR under Apple's App Store and TestFlight terms | Get legal advice before external distribution: the FSF considers Apple's usage rules incompatible with the GPL. Options: proceed after advice; an iOS build without R (Python only); or no iOS release |
| D5 | Online package installation on iOS (App Review guideline 2.5.2) | Ship the first iOS version with the Packages pane switched off by a build flag, then try enabling it with explicit review notes |
| D6 | Release ABIs: arm64-v8a only, or also armeabi-v7a and x86_64 | arm64-v8a only on GitHub; the AAB may add x86_64 for ChromeOS if tested |
| D7 | Minimum iOS version (I8) | The oldest version that passes M2 and the device journey |
| D8 | Privacy policy and support URLs, disclosing the optional webR repository and PyPI connections | Host on the documentation site |
| D9 | `linux/`, `macos/`, `windows/` folders | Remove later in a separate commit (4.7) |
| D10 | Offer the iPad app on Apple silicon Macs | Opt out until tested |
| D11 | F-Droid route: source-build recipe for the runtimes in the main repository, own repository, or none | Decide after M6 |
| D12 | Where CI signing secrets live | Per-repository `release` environment with required reviewer |

## November 2026 implementation update

See [the Apple build and refinement record](apple-audit-2026-11-08.md) for completed source changes, exact verification and remaining device/signing gates. Earlier platform observations are historical; Xcode is now available on the audit Mac.
