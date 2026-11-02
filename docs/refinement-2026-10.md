# October 2026 refinement

## Purpose and acceptance criteria

Run R and Python offline with a persistent shared workspace, console and plots. Preserve existing user data. A clean checkout must prepare pinned runtimes, pass analysis and meaningful tests, and build an Android APK. Exercise the runtime in a browser with external network requests blocked, then retain physical-device/WebView and iOS checks as explicit gates.

## Confirmed findings and plan

1. **Release blocker — runtimes absent.** `tool/fetch_runtimes.sh` only created empty directories and printed a false checksum-verification message. Replace it with pinned downloads, SHA-256 checks, safe extraction and complete asset packaging. Validate the actual bundled kernels and sample apps.
2. **High — data integrity.** Workspace path handling allows parent traversal and follows symlinks; file moves and imports can overwrite existing files. Kernel startup marks the server ready after a bind failure. Add confinement and regression tests before exposing imported data to the runtime.
3. **Medium — provenance and reproducibility.** `THIRD_PARTY.md` has version placeholders and incorrectly describes the WebR binary license. Record actual versions, source URLs, binary checksums and upstream notices. Refresh the Flutter lockfile against the tested SDK and add CI.

## Baseline evidence

Flutter 3.47.9 / Dart 3.13.7. Frozen dependency resolution initially failed against this SDK; a normal resolution followed by a frozen install passed. Analysis passed; only two theme tests existed. No Xcode installation is available, so iOS compilation cannot be claimed.

## Implementation and verification

Completed local milestones:

- Workspace paths now reject traversal, symbolic links and accidental overwrite; file writes are staged. Runtime initialization reports failures and can retry. WebR filesystem/snapshot interoperability and R error recovery are corrected. WebView inspection is debug-only, with file/universal URL access disabled. The actual offline browser journey executes R arithmetic and plots, recovers after an R error, reads the shared workspace from Python, and exercises numpy, pandas, scipy, scikit-learn and matplotlib.
- Pinned runtime preparation verifies SHA-256, rejects unsafe extraction, caches inputs and produces deterministic assets. Three preparation regression tests pass.
- Flutter **9 tests pass**, analyzer passes, and the arm64 Android debug APK builds. Frozen dependency resolution passes with Flutter 3.47.9. The local browser smoke journey passes with external requests blocked; captured output was visually inspected.
- CI repeats installation, asset preparation, analysis, tests, runtime exercise and Android packaging. Local verification does not establish the remote CI result; inspect workflow runs for the source commit.
- OSV checked the exact resolved Pub package/version pairs for the three Flutter repositories on 2026-10-30: no matching advisories in 206 distinct pairs. This query does not audit the bundled native/WebAssembly dependencies or prove absence of vulnerabilities.

Raw suite receipts: `atelier-analyze-r4, atelier-test-r2, atelier-workspace-r2, atelier-runtime-final, atelier-android-r4, atelier-runtime-preparation-tests` in `.refinement/2026-10-30/logs/`. First-use prerequisites and commands are in [README](https://github.com/etabli-dev/etabli-atelier/blob/main/README.md).

The host test, offline browser runtime and Android packaging gates are satisfied. Android WebView execution, physical-device lifecycle/share-sheet behavior, full iOS compilation and signed distribution remain external gates. The F-Droid draft is explicitly disabled; neither its old tag nor binary-runtime downloads constitute a completed source-build recipe. Before distribution, provide the corresponding GPL runtime source and tested source-build instructions, select the approved version/signing plan, then exercise upgrades and offline operation on devices. No signed application release or store submission occurred.

## Deferred work

Additional kernels, collaborative editing and new server-backed features are outside this repair release. Store acceptance and F-Droid approval require external review; a successful local build is not evidence of acceptance.

## Android runtime review: failed editor reads

Confirmed: opening invalid UTF-8 or an unreadable file retained the previous editor text but reassigned its save target to the failed file. A later Save could overwrite unrelated original bytes. Keep the previous buffer and its file association on read failure, show the failure with a retry action, and label the toolbar using the actual loaded target. Verify through the production editor with readable and invalid UTF-8 files, then save and check both files' bytes.

Failed writes now report an error while retaining the buffer; a new file is associated only after a successful write, and Run stops if saving fails. Verification: `atelier-editor-navigation-tests-r3` passed all 8 Flutter tests and `atelier-editor-navigation-analyze-r3` found no issues. The regression uses the production editor, saves after opening invalid UTF-8, confirms the original binary bytes are unchanged, and injects a subsequent write failure to verify both the draft and prior saved file survive.

The same review confirmed that switching to a readable file could silently replace unsaved edits. File changes now offer Save, Discard and Cancel. Cancel and unsuccessful saves restore the prior file selection; loading temporarily disables editing and run/save actions. The focused production-editor regression covers every choice, confirms successful saving before navigation, and checks that deliberate discard leaves the destination's prior on-disk contents intact. Unsaved drafts still require saving before force-stop or process termination.

Automatic R/Python selection now occurs only after the requested file successfully loads. Canceling navigation or failing to decode a file therefore retains the prior kernel selection. Mixed-language navigation and closing into a scratch buffer are covered by the same regression.

### Final shell integration review — 2026-10-31

The navigation shell previously disposed the editor when opening Files or Console, so a draft could disappear before the file-switch guard ran. The shell now retains pane state using an indexed stack, excluding hidden panes from focus and disabling their tickers. A regression through the real shell and file browser failed before this repair and passes afterward: canceling keeps the draft and kernel, visiting Console retains it, and saving before an R-to-Python file change preserves the original bytes. This supplements the direct editor tests.

Final shell verification: `atelier-shell-tests` passed all 9 Flutter tests, and `atelier-shell-analyze` reported no issues. The new shell test was first run against the prior implementation (`atelier-shell-preservation-baseline`, exit 1), where the unsaved-change dialog failed to appear after the buffer was lost. It passed after the repair (`atelier-shell-preservation`, exit 0).

The responsive-layout follow-up reproduced draft loss when the actual view crossed the 720dp navigation breakpoint (`atelier-shell-resize-baseline-r2`, exit 1: the buffer became empty). The shell now keeps one stable keyed workspace subtree while switching between rail and bottom navigation. The same real-shell regression covers 800-to-600-to-800dp transitions before exercising file changes.

The final shell including responsive transitions passes all 9 Flutter tests (`atelier-shell-tests-final`) and static analysis (`atelier-shell-analyze-final`) on 2026-10-31. The final Android package must use the `atelier-android-shell-final` build receipt; earlier builds predate the shell integration repair.

`atelier-android-shell-final` completed with exit 0 on 2026-10-31. The final arm64 debug APK is 229,312,353 bytes, SHA-256 `8186aac8c5fbd4e556f23ba12a5336e43280c7f45f25165bf4ec64cd543c8ad7`. Its source includes the complete editor and shell preservation repairs. Real Android offline R/Python execution and device lifecycle checks remain separate observations; a successful build is not evidence that those journeys ran.

### Published CI outcome — 2026-10-31

Published source commit `1716676a820a302b7d94d2c6fca92a710075e6ac` passed [application CI](https://github.com/etabli-dev/etabli-atelier/actions/runs/41200143039), including frozen dependency resolution, runtime preparation, analysis, all 9 Flutter tests, the offline browser R/Python journey and Android APK packaging. The [documentation Pages build/deployment](https://github.com/etabli-dev/etabli-atelier/actions/runs/41200143150) also passed. These are observed remote results for that source commit, separate from the local checks above.

The runtime journey ran in a browser; it does not establish Android WebView execution. Android runtime/device acceptance and full iOS compilation remain open, as do signing and store acceptance. The unsuccessful Android attempt is retained below.

### Android device attempt — 2026-10-31

The final APK installed successfully with `adb install -r` on the local API 35 arm64 emulator (4 KiB pages), preserving app data. The emulator could not sustain the subsequent Flutter UI pass: the first app startup timed out, window-service inspection timed out, and a bounded retry after stopping the separate test emulator and idle build JVMs produced a black screenshot and a null accessibility root. Android logged `DeadSystemException` across System UI, the keyboard, Courrier and other services, followed by system-server watchdog/lock contention during recovery. This is an environment failure, not evidence of an Atelier runtime defect or a passing journey.

Atelier's on-device offline R/Python arithmetic, plotting and editor lifecycle journeys were not reached. The nine passing Flutter tests and browser runtime smoke remain the observed behavior checks. Repeat the prepared R/Python and editor journeys on a responsive emulator or physical Android device before claiming Android runtime acceptance; API 36/16 KiB device execution and iOS remain unverified. Suite receipts and screenshots are in `.refinement/2026-10-30/android-local/` (`flutter-device-prep.json`, `flutter-api35-first-attempt.json`, `flutter-api35-retry.json`, `flutter-api35-system-failure.log`); runnable steps are in `FLUTTER_JOURNEYS.md` there.
