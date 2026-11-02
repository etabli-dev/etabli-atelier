# Runtime provenance and redistribution

The application source is Apache-2.0. Bundled runtimes and packages retain their own licenses; the WebR binary is **GPL-3.0**, not Apache-2.0. Upstream notices are included under `assets/licenses/` and exposed through Settings → Open-source licenses.

| Component | Exact version | Source and license |
|---|---|---|
| WebR | 0.6.0 (R 4.6.0 observed in the runtime) | [Source tag](https://github.com/r-wasm/webr/tree/v0.6.0), [binary GPL-3.0 and other components](https://github.com/r-wasm/webr/blob/v0.6.0/LICENSE.md) |
| shinylive | 0.10.12 | [Source tag](https://github.com/posit-dev/shinylive/tree/v0.10.12), MIT; bundled R packages retain their licenses |
| Pyodide | 0.27.7 (Python 3.12.7) | [Source tag](https://github.com/pyodide/pyodide/tree/0.27.7), MPL-2.0; Python and wheels retain their licenses |

`tool/runtimes.lock.json` records canonical download URLs and SHA-256 digests. Inputs are WebR's official zip and Posit's official shinylive tarball; the latter includes both its R engine and Pyodide distribution. The fetcher verifies every input before writing application assets and writes a per-file receipt to ignored `tool/runtimes.prepared.json`. `--offline` requires a previously verified cache and makes no download request. Corrupt cached inputs fail without replacing application assets.

Atelier extracts WebR and selects NumPy, pandas, SciPy, matplotlib, scikit-learn, micropip and their transitive dependencies from the pinned Pyodide package lock. Every selected package payload, including the required OpenBLAS ZIP, is checked against that lock's hash. Package payloads outside the selected transitive closure are omitted regardless of archive extension. The runtime's other supporting files and font notices are retained. Additional package installation remains an explicitly online feature.

## Distribution gate

Automatic CI APK uploads are paused while complete corresponding-source delivery remains unverified. CI still prepares and verifies the pinned runtimes, runs analysis and tests, exercises offline browser execution and builds the Android APK; it retains screenshots and preparation receipts. Local development builds remain documented in README.md. Earlier CI artifacts and release files have not been removed, and their existence is not evidence that source delivery was completed.

Before resuming binary uploads, identify every included runtime/package version, collect its matching preferred source and build/install scripts, verify those materials against the exact binary inputs, and provide durable source-download directions beside each binary download. The WebR [upstream license](https://github.com/r-wasm/webr/blob/v0.6.0/LICENSE.md) describes its binary license and includes GPLv3 section 6. An upstream tag link alone is not a completed corresponding-source delivery. Preserve the binary-to-source inventory and verification evidence with the release. This is outstanding maintainer work; no source rebuild or distribution approval is claimed.

F-Droid main-repository acceptance is unverified; do not describe `scanignore` as approval of prebuilt runtimes. The draft recipe stays disabled pending a tested source-build path and reviewed release/signing plan. A private repository also requires verified signing, downloads and source delivery. See [FDROID_NOTES.md](FDROID_NOTES.md).

The suite's dated [source inventory](https://github.com/etabli-dev/.github/blob/main/docs/runtime-sources.md) and [machine-readable manifest](https://github.com/etabli-dev/.github/blob/main/docs/runtime-sources.json) record the collected archives, exact commits and remaining source-binding gaps. The inventory covers the pre-filter binary baseline and distinguishes Atelier's selected 22-package closure from its nine historical extra payloads. It is not a completed source-build or source-delivery claim.
