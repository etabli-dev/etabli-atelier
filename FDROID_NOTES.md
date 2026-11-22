# F-Droid preparation status

No F-Droid submission or acceptance has been verified. The existing `.fdroid.yml` is explicitly disabled, with automatic update checks off. It is a historical draft: its v1.0 release reference and assumed release workflow must be reconciled with the approved release tag and signing/version-code plan before use.

The normal development build downloads pinned WebAssembly binaries using `bash tool/fetch_runtimes.sh`. Checksums, notices and provenance are in [THIRD_PARTY.md](THIRD_PARTY.md) and `tool/runtimes.lock.json`. This does not establish that an F-Droid source-build requirement has been met. Do not submit the draft as a completed recipe or use scanner exclusions as evidence of acceptance.

Before submission, produce a source-build recipe for the exact runtime inputs or agree an acceptable distribution route with the relevant repository. Prepare corresponding-source delivery for the GPL components, choose and securely back up the signing key, reconcile version codes with any existing installation, and test upgrades and runtime operation on devices. A private F-Droid repository also needs an actually signed index and verified downloads; it is not a guaranteed or already completed fallback.
