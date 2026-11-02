# October–November 2026 refinement

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

## Runtime artifact distribution review — 2026-11-02

Confirmed: application CI uploaded debug APKs containing GPL-licensed WebR binaries while complete corresponding-source delivery for the bundled runtime and R package image remained unverified. Pinned binary hashes and source-tag links do not close that distribution gate. Preserve all preparation, analysis, unit/runtime tests and APK-build checks; retain screenshots and preparation receipts, and pause automatic APK uploads until matching source materials and delivery instructions have been checked. Historical artifacts/releases are preserved and are not retroactively described as source-verified. Corresponding-source preparation and the disabled F-Droid recipe are deferred maintainer work, not an unavailable account or device prerequisite.

## Python runtime payload selection — 2026-11-02

The dependency filter previously removed unselected wheels but copied every other Pyodide archive. Nine unrelated lock-listed shared-library ZIPs (including GDAL and test libraries) added 38,201,437 bytes outside the selected dependency closure. The required OpenBLAS ZIP belongs to that closure and must remain. Filter every known package payload by the selected transitive closure regardless of extension, retain runtime/support files, and verify every selected payload against the upstream lock.

Existing prepared checkouts also need stale generated payloads removed. Before publishing any asset, verify excluded files against the previous preparation receipt; refuse changed or untracked payloads and symlinked destination paths. Preserve unmanaged files. Eight lightweight preparation tests pass, including real miniature-archive selection, required OpenBLAS/hash failure, stale-file preservation and outside-directory symlink rejection. The selection regression fails with the old filter. The acceptance criteria were actual asset preparation, offline browser runtime checks, rebuilt APK inspection and a focused installed-app recheck; the completed results are recorded below. The previous APK and preparation receipt are preserved separately.

### Installed Android baseline journey — 2026-11-02

The **pre-packaging-repair** debug APK, SHA-256 `8186aac8c5fbd4e556f23ba12a5336e43280c7f45f25165bf4ec64cd543c8ad7`, passed a scoped actual API 35 ARM64/4 KiB emulator journey with guest external networking disabled. R `6*7` printed `[1] 42`; Python `print(6*7)` printed `42`. The bundled R and NumPy/Matplotlib examples computed 200 draws and rendered real histograms inside the installed application. The Python example emitted the non-interactive Agg warning while its captured plot rendered successfully.

A new `Audit20261102.R` draft retained its exact text and R kernel when a switch to the Python sample was cancelled. Console/Editor navigation retained the draft; choosing Save before switching preserved the file, and its exact text reopened after force-stop/relaunch. Existing examples were unchanged. One initial splash observation returned a null accessibility root; the next bounded observation succeeded. This later success does not erase the October 31 system failure.

Screenshots, fresh hierarchies, process logs, saved-file bytes and the exact install receipt are retained in `.refinement/2026-10-30/android-local/games-flutter-20261102-pass1/` (`atelier-result.json`, `atelier-saved-files.json`, `RESULTS.md`) in the suite workspace. These results establish the scoped baseline APK's offline R/Python, plot and file-preservation behavior. They **do not verify the smaller replacement APK** from the subsequent packaging repair; that artifact requires its own hash-linked check. Physical-device lifecycle, actual share-sheet behavior, 16 KiB execution, full iOS compilation, corresponding-source delivery and signed distribution remain open.

### Prepared runtime and fresh package verification — 2026-11-02

On 2 November, checksum-verified offline preparation removed exactly nine unused Pyodide package ZIPs (38,201,437 asset bytes). All 543 retained asset files were byte-identical to the preserved baseline; all 22 selected package payloads, including OpenBLAS, still matched their pinned hashes. Eight focused preparation/publication tests passed. Actual offline browser execution passed R calculation, error recovery, shared files, SciPy linear solve, scikit-learn regression prediction, pandas sum and both R/Python plot checks; the tests now decode PNGs, require visible contrast on white and save original/composite images. Both final plots were visually checked. Two failed QA-helper attempts are retained; their asynchronous result handling was corrected without changing runtime implementation.

The fresh ARM64 debug APK is `1b5ac855de0a92c987e7c7f5064004dc197b27df5f240832226d580782a64a55` (188,900,091 bytes), down 40,412,262 bytes (17.6232%) from the preserved baseline. Total savings include removing package payloads and reclaiming old incremental ZIP gaps; compressed entry bytes fell 11,927,875. The first incremental APK and its build state were preserved before fresh packaging. All 504 retained prepared runtime entries and all native libraries inside the final APK match the old APK byte-for-byte. The valid Android Debug signature, minimum API 24 / target 36, ZIP 16 KiB alignment and all four 64-bit ELF segment alignment/offset-congruence checks passed. The Flutter engine is ARM64; pre-existing auxiliary JNI copies for other ABIs do not establish Flutter support for those architectures. This is static compatibility evidence, not a 16 KiB runtime test. Application/asset inputs stayed frozen. The subsequent installed replacement check below closes its separate device criterion; the earlier baseline pass belongs to APK `8186aac8c5fbd4e556f23ba12a5336e43280c7f45f25165bf4ec64cd543c8ad7`. Corresponding-source delivery remains incomplete and automatic APK uploads stay paused.

### Smaller APK upgrade/runtime verification — 2026-11-02

The final reduced debug APK (188,900,091 bytes; SHA-256 `1b5ac855de0a92c987e7c7f5064004dc197b27df5f240832226d580782a64a55`) replaced the previously tested `8186…` APK using `install -r` on the preserved API 35 ARM64/4 KiB emulator. The actual installed hash matched the final package receipt. `Audit20261102.R` and both bundled examples retained identical bytes before upgrade, immediately afterward, after runtime execution and after restart. The saved audit file's exact text also reopened in the real editor.

With guest external networking disabled, the installed UI produced R `[1] 42`, Python `42`, pandas sum 6, SciPy linear solve `[2.0, 3.0]` with OpenBLAS loaded, and scikit-learn prediction 8.0. Both bundled R and NumPy/Matplotlib examples computed 200 draws and rendered actual histograms. The existing Agg warning accompanied a successfully rendered Python plot. Screenshots, fresh hierarchies, installed/file hashes and logs are retained in the suite workspace `.refinement/2026-10-30/android-local/atelier-upgrade-20261102-pass1/` (`result.json`, `RESULTS.md`). Captured app logs contained no fatal/ANR markers and the crash buffer was empty.

This closes the reduced APK's scoped upgrade-preservation and offline runtime-package checks. Guest settings were restored and the owned emulator was stopped without clearing its userdata. Physical-device/16 KiB behavior, actual sharing, full iOS compilation, GPL corresponding-source delivery, private signing and store acceptance remain open. The earlier device baseline and failed October 31 attempt remain separate historical evidence.
