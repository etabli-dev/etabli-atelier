# Runtime provenance and redistribution

The application source is Apache-2.0. Bundled runtimes and packages retain their own licenses; the WebR binary is **GPL-3.0**, not Apache-2.0. Upstream notices are included under `assets/licenses/` and exposed through Settings → Open-source licenses.

| Component | Exact version | Source and license |
|---|---|---|
| WebR | 0.6.0 (R 4.6.0 observed in the runtime) | [Source tag](https://github.com/r-wasm/webr/tree/v0.6.0), [binary GPL-3.0 and other components](https://github.com/r-wasm/webr/blob/v0.6.0/LICENSE.md) |
| shinylive | 0.10.12 | [Source tag](https://github.com/posit-dev/shinylive/tree/v0.10.12), MIT; bundled R packages retain their licenses |
| Pyodide | 0.27.7 (Python 3.12.7) | [Source tag](https://github.com/pyodide/pyodide/tree/0.27.7), MPL-2.0; Python and wheels retain their licenses |

`tool/runtimes.lock.json` records canonical download URLs and SHA-256 digests. Inputs are WebR's official zip and Posit's official shinylive tarball; the latter includes both its R engine and Pyodide distribution. The fetcher verifies every input before writing application assets and writes a per-file receipt to ignored `tool/runtimes.prepared.json`. `--offline` requires a previously verified cache and makes no download request. Corrupt cached inputs fail without replacing application assets.

Atelier extracts WebR and selects NumPy, pandas, SciPy, matplotlib, scikit-learn, micropip and their transitive dependencies from the pinned Pyodide package lock. Selected wheels are checked again against that lock's hashes. The runtime's other supporting files and font notices are retained. Additional package installation remains an explicitly online feature.

## Distribution gate

These checks establish binary provenance, not a source build or store approval. Before publishing a binary, prepare and verify the corresponding-source materials for every bundled copyleft component, including the R package image, and review compatibility with the chosen distribution channel. An upstream tag link alone is not a completed corresponding-source delivery. F-Droid main-repository acceptance is unverified; do not describe `scanignore` as approval of prebuilt runtimes. See [FDROID_NOTES.md](FDROID_NOTES.md).
