# Apple build and roadmap refinement — 2026-11-08

Workspace files now offer **Share / save a copy…** from the file menu, using the native Android/iOS share sheet. The export reads canonical bytes through the existing workspace confinement checks and leaves the source unchanged. Binary preservation, missing source, traversal and symlink rejection have regression coverage. Native share-sheet interaction is a separate device acceptance check.

Android release builds now use private `android/keystore.properties` when supplied and otherwise remain unsigned. They no longer silently use the debug key. Existing debug installs must retain their data; export files before moving to a differently signed installation. No signing keys were changed or created.

The application workflow now includes an unsigned iOS simulator compilation job with pinned runtime preparation. Binary uploads remain disabled while the corresponding-source delivery gate is open.

Local runtime-preparation safeguards, locked dependency resolution, static analysis and all 12 Flutter tests passed, including three new export regression cases. The unsigned iOS simulator app compiled successfully with Xcode 27.2. Flutter migrated its minimum deployment target to iOS 15.0. Android debug and unsigned release builds are included in the final workflow. The native share sheet, WKWebView kernels and lifecycle still need physical-device acceptance; signing and corresponding-source release gates remain open.
