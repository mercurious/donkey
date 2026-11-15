#!/bin/sh
# Donkey installer. Run it on the ROCKNIX device from the unpacked release:
#
#   ./install.sh                   install or update Donkey; fetch Firefox if missing
#   ./install.sh --update-firefox  also replace Firefox with Mozilla's latest
#
# Firefox comes straight from Mozilla, unmodified; Donkey never ships it.
set -eu

APP=/storage/apps/donkey
PORT=/storage/roms/ports/Donkey.sh
FIREFOX_URL="${DONKEY_FIREFOX_URL:-https://download.mozilla.org/?product=firefox-latest-ssl&os=linux64-aarch64&lang=en-US}"
SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

update_firefox=0
case "${1:-}" in
  "") ;;
  --update-firefox) update_firefox=1 ;;
  *) sed -n '2,7s/^# \{0,1\}//p' "$0" >&2; exit 2 ;;
esac

if [ "$(uname -m)" != aarch64 ]; then
  echo "Donkey needs an aarch64 device; this is $(uname -m)." >&2
  exit 1
fi

fetch_firefox() {
  work=$(mktemp -d /storage/.donkey-install.XXXXXX)
  trap 'rm -rf "$work"' EXIT
  echo "Downloading Firefox for Linux aarch64 from Mozilla..."
  curl -fL --retry 3 -o "$work/firefox.tar.xz" "$FIREFOX_URL"
  echo "Unpacking..."
  xz -dc "$work/firefox.tar.xz" | tar -x -C "$work"
  if [ ! -x "$work/firefox/firefox-bin" ]; then
    echo "The download did not contain firefox/firefox-bin." >&2
    exit 1
  fi
  rm -rf "$APP/firefox"
  mv "$work/firefox" "$APP/firefox"
}

mkdir -p "$APP/logs" "$(dirname "$PORT")"
if [ "$update_firefox" = 1 ] || [ ! -x "$APP/firefox/firefox" ]; then
  fetch_firefox
fi

# Donkey's own files: replaced wholesale, so removed files don't linger.
rm -rf "$APP/bin" "$APP/controller" "$APP/profile"
cp -R "$SRC/app/." "$APP/"
cp -R "$SRC/bin" "$APP/bin"
cp "$SRC/VERSION" "$APP/VERSION"
chmod +x "$APP"/*.sh "$APP"/bin/*

cat >"$PORT" <<EOF
#!/bin/sh
exec $APP/launch.sh "\$@"
EOF
chmod +x "$PORT"

missing=$( (LD_LIBRARY_PATH="$APP/firefox" ldd "$APP/firefox/libxul.so"
  ldd "$APP/bin/wvkbd-donkey") 2>&1 | grep 'not found' || true)
if [ -n "$missing" ]; then
  echo "Missing libraries:" >&2
  echo "$missing" >&2
  exit 1
fi

version=$(sed -n 's/^Version=//p' "$APP/firefox/application.ini" | head -n 1)
echo "Donkey $(cat "$APP/VERSION") installed with Firefox $version."
echo "In EmulationStation: Start > Game Settings > Update Gamelists, then Ports > Donkey."
