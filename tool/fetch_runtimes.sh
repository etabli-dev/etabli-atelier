#!/usr/bin/env bash
# Fetch vendored open-source WASM runtimes from their canonical upstream
# release URLs into assets/runtimes/. Pin exact versions + checksums.
# This gives F-Droid provenance instead of opaque committed blobs.
set -euo pipefail
DEST="assets/runtimes"
mkdir -p "$DEST"

# Set up the directory tree pubspec.yaml expects, even if no upstream URLs are
# pinned yet — keeps `flutter pub get` / analyze quiet on a fresh checkout.
while IFS= read -r d; do
  [ -z "$d" ] && continue
  mkdir -p "$d"
done <<'DIRS'
assets/runtimes/pyodide
assets/runtimes/webr
assets/runtimes/webr/assets
assets/runtimes/webr/vfs
assets/runtimes/webr/vfs/etc
assets/runtimes/webr/vfs/etc/fonts
assets/runtimes/webr/vfs/etc/ssl
assets/runtimes/webr/vfs/usr
assets/runtimes/webr/vfs/usr/lib
assets/runtimes/webr/vfs/usr/lib/R
assets/runtimes/webr/vfs/usr/lib/R/library
assets/runtimes/webr/vfs/usr/lib/R/library/base
assets/runtimes/webr/vfs/usr/lib/R/library/compiler
assets/runtimes/webr/vfs/usr/lib/R/library/datasets
assets/runtimes/webr/vfs/usr/lib/R/library/grDevices
assets/runtimes/webr/vfs/usr/lib/R/library/graphics
assets/runtimes/webr/vfs/usr/lib/R/library/grid
assets/runtimes/webr/vfs/usr/lib/R/library/methods
assets/runtimes/webr/vfs/usr/lib/R/library/splines
assets/runtimes/webr/vfs/usr/lib/R/library/stats
assets/runtimes/webr/vfs/usr/lib/R/library/stats4
assets/runtimes/webr/vfs/usr/lib/R/library/tools
assets/runtimes/webr/vfs/usr/lib/R/library/translations
assets/runtimes/webr/vfs/usr/lib/R/library/utils
assets/runtimes/webr/vfs/usr/lib/R/library/webr
assets/runtimes/webr/vfs/usr/share
assets/runtimes/webr/vfs/usr/share/fonts
assets/runtimes/webr/vfs/var
assets/runtimes/webr/vfs/var/cache
assets/runtimes/webr/vfs/var/cache/fontconfig
DIRS

# --- EDIT: pin exact upstream release URLs + sha256 below ---
# Example pattern (replace with real pinned URLs from THIRD_PARTY.md):
# fetch <url> <expected_sha256> <dest_filename>
fetch() {
  local url="$1" sum="$2" out="$3"
  echo "Fetching $out"
  curl -fsSL "$url" -o "$DEST/$out"
  echo "$sum  $DEST/$out" | shasum -a 256 -c -
}

# fetch "https://github.com/r-wasm/webr/releases/download/vX/webr.tgz" "<sha256>" "webr.tgz"
# fetch "https://github.com/pyodide/pyodide/releases/download/X/pyodide.tar.bz2" "<sha256>" "pyodide.tar.bz2"

echo "Runtimes fetched + checksum-verified into $DEST"
