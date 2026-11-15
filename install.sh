#!/bin/sh
# Donkey setup. Runs from Donkey's home, the unpacked release:
#
#   tar -xzf donkey-aarch64.tar.gz -C /storage/apps
#   /storage/apps/donkey/install.sh                   fetch Firefox if missing, add Ports > Donkey
#   /storage/apps/donkey/install.sh --update-firefox  also replace Firefox with Mozilla's latest
#
# portmart runs it as the install hook (PORTMART_HOME set) and writes the
# Ports entry itself. Firefox comes straight from Mozilla, unmodified;
# Donkey never ships it.
set -eu

HOME_DIR=$(CDPATH= cd -- "$(dirname -- "$(readlink -f -- "$0")")" && pwd)
PORTS_DIR=${PORTS_DIR:-/storage/roms/ports}
FIREFOX_URL="${DONKEY_FIREFOX_URL:-https://download.mozilla.org/?product=firefox-latest-ssl&os=linux64-aarch64&lang=en-US}"

update_firefox=0
case "${1:-}" in
  "") ;;
  --update-firefox) update_firefox=1 ;;
  *) sed -n '2,10s/^# \{0,1\}//p' "$0" >&2; exit 2 ;;
esac

if [ "$(uname -m)" != aarch64 ]; then
  echo "Donkey needs an aarch64 device; this is $(uname -m)." >&2
  exit 1
fi

fetch_firefox() {
  work=$(mktemp -d "$HOME_DIR/.firefox-download.XXXXXX")
  trap 'rm -rf "$work"' EXIT
  echo "Downloading Firefox for Linux aarch64 from Mozilla..."
  curl -fL --retry 3 -o "$work/firefox.tar.xz" "$FIREFOX_URL"
  echo "Unpacking..."
  xz -dc "$work/firefox.tar.xz" | tar -x -C "$work"
  if [ ! -x "$work/firefox/firefox-bin" ]; then
    echo "The download did not contain firefox/firefox-bin." >&2
    exit 1
  fi
  rm -rf "$HOME_DIR/firefox"
  mv "$work/firefox" "$HOME_DIR/firefox"
}

mkdir -p "$HOME_DIR/logs"
if [ "$update_firefox" = 1 ] || [ ! -x "$HOME_DIR/firefox/firefox" ]; then
  fetch_firefox
fi
chmod +x "$HOME_DIR"/*.sh "$HOME_DIR"/bin/*

missing=$( (LD_LIBRARY_PATH="$HOME_DIR/firefox" ldd "$HOME_DIR/firefox/libxul.so"
  ldd "$HOME_DIR/bin/wvkbd-donkey") 2>&1 | grep 'not found' || true)
if [ -n "$missing" ]; then
  echo "Missing libraries:" >&2
  echo "$missing" >&2
  exit 1
fi

if [ -z "${PORTMART_HOME:-}" ]; then
  mkdir -p "$PORTS_DIR"
  printf '#!/bin/sh\nexec "%s/launch.sh" "$@"\n' "$HOME_DIR" >"$PORTS_DIR/Donkey.sh"
  chmod +x "$PORTS_DIR/Donkey.sh"
fi

version=$(sed -n 's/^Version=//p' "$HOME_DIR/firefox/application.ini" | head -n 1)
echo "Donkey $(cat "$HOME_DIR/VERSION") ready with Firefox $version in $HOME_DIR."
[ -n "${PORTMART_HOME:-}" ] ||
  echo "In EmulationStation: Start > Game Settings > Update Gamelists, then Ports > Donkey."
