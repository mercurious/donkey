#!/bin/sh
# Assemble a release: dist/donkey-<version>/ and dist/donkey-<version>.tar.gz.
# Builds the keyboard first unless build/bin/wvkbd-donkey is newer than its
# patches.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
VERSION=$(cat "$ROOT/VERSION")
NAME="donkey-$VERSION"
OUT="$ROOT/dist/$NAME"
KBD="$ROOT/build/bin/wvkbd-donkey"

stale=1
if [ -x "$KBD" ]; then
  stale=0
  for f in "$ROOT"/keyboard/*; do
    [ "$f" -nt "$KBD" ] && stale=1
  done
  for f in "$ROOT"/keyboard/patches/*; do
    [ "$f" -nt "$KBD" ] && stale=1
  done
fi
[ "$stale" = 1 ] && "$ROOT/keyboard/build.sh"

rm -rf "$OUT" "$OUT.tar.gz"
mkdir -p "$OUT/bin"
cp -R "$ROOT/app" "$ROOT/keyboard" "$OUT/"
cp "$ROOT/install.sh" "$ROOT/VERSION" "$ROOT/LICENSE" "$ROOT/README.md" "$OUT/"
cp "$KBD" "$OUT/bin/"
tar -C "$ROOT/dist" -czf "$OUT.tar.gz" "$NAME"
echo "dist/$NAME.tar.gz"
