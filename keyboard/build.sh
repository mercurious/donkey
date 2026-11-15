#!/bin/sh
# Build wvkbd-donkey: upstream wvkbd at a pinned tag plus Donkey's patches,
# compiled natively for aarch64 in a Fedora container.
# Output: build/bin/wvkbd-donkey (relative to the repo root).
set -eu

WVKBD_URL=https://github.com/jjsullivan5196/wvkbd
WVKBD_TAG=v0.21
IMAGE=donkey-keyboard-build

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT=$(dirname -- "$HERE")
SRC="$ROOT/build/wvkbd"

case "$(uname -m)" in
  aarch64 | arm64) ;;
  *) echo "build.sh builds natively; run it on an aarch64 host." >&2; exit 1 ;;
esac

podman build -q -t "$IMAGE" -f "$HERE/Containerfile" "$HERE" >/dev/null

rm -rf "$SRC"
git -c advice.detachedHead=false clone -q --depth 1 --branch "$WVKBD_TAG" \
  "$WVKBD_URL" "$SRC"
git -C "$SRC" apply "$HERE"/patches/*.patch

podman run --rm -v "$SRC":/src:Z -w /src "$IMAGE" \
  make -s LAYOUT=mobintl wvkbd-mobintl

mkdir -p "$ROOT/build/bin"
cp "$SRC/wvkbd-mobintl" "$ROOT/build/bin/wvkbd-donkey"
echo "built build/bin/wvkbd-donkey from wvkbd $WVKBD_TAG" >&2
