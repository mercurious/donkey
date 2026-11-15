#!/bin/sh
# Assemble the release: dist/donkey/ (Donkey's home, as installed) and
# dist/donkey-aarch64.tar.gz with its .sha256. Builds the keyboard first
# unless build/bin/wvkbd-donkey is newer than its sources.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OUT="$ROOT/dist/donkey"
TARBALL="$ROOT/dist/donkey-aarch64.tar.gz"
KBD="$ROOT/build/bin/wvkbd-donkey"

stale=1
if [ -x "$KBD" ]; then
  stale=0
  for f in "$ROOT"/keyboard/* "$ROOT"/keyboard/patches/*; do
    [ "$f" -nt "$KBD" ] && stale=1
  done
fi
[ "$stale" = 1 ] && "$ROOT/keyboard/build.sh"

rm -rf "$OUT" "$TARBALL" "$TARBALL.sha256"
mkdir -p "$OUT/bin"
cp -R "$ROOT"/app/. "$OUT/"
cp -R "$ROOT/keyboard" "$OUT/"
cp "$ROOT/install.sh" "$ROOT/VERSION" "$ROOT/LICENSE" "$ROOT/README.md" "$OUT/"
cp "$KBD" "$OUT/bin/"
tar -C "$ROOT/dist" -czf "$TARBALL" donkey
(cd "$ROOT/dist" && sha256sum donkey-aarch64.tar.gz >donkey-aarch64.tar.gz.sha256)
echo "dist/donkey-aarch64.tar.gz"
