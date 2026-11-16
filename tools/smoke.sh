#!/bin/sh
# End-to-end smoke test on a device with Donkey installed. It drives the
# real session with no hands needed: it launches Donkey, presses keys
# through InputPlumber's virtual keyboard (the same device the controller
# profiles feed), and checks the keyboard, the profile swaps and the clean
# exit. Screenshots land in build/shots/.
#   DONKEY_HOST, DONKEY_KEY as for deploy.sh.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
HOST="${DONKEY_HOST:-root@sm8250-12gb.local}"
SSH_OPTS="${DONKEY_KEY:+-i $DONKEY_KEY}"
SHOTS="$ROOT/build/shots"

# shellcheck disable=SC2086
ssh $SSH_OPTS "$HOST" sh -s <<'EOF'
export XDG_RUNTIME_DIR=/run/0-runtime-dir WAYLAND_DISPLAY=wayland-1
export SWAYSOCK=/run/0-runtime-dir/sway-ipc.0.sock
IP=org.shadowblip.InputPlumber
PAD=/org/shadowblip/InputPlumber/CompositeDevice0
KBD=/org/shadowblip/InputPlumber/devices/target/keyboard0
fails=0

key() { busctl call $IP $KBD org.shadowblip.Input.Keyboard SendKey sb "$1" "$2"; }
tap() { key "$1" true; key "$1" false; }
profile() {
  busctl get-property $IP $PAD org.shadowblip.Input.CompositeDevice ProfileName |
    sed 's/^s "//; s/"$//'
}
check() {
  if [ "$2" = "$3" ]; then echo "PASS $1"; else echo "FAIL $1: got '$2', want '$3'"; fails=$((fails + 1)); fi
}
shot() { grim "/tmp/donkey-smoke-$1.png"; }
donkey_up() { swaymsg -t get_tree | grep -q '"app_id": "Donkey"'; }

rm -f /tmp/donkey-smoke-*.png
if [ -f /run/donkey/firefox.pid ]; then
  /storage/apps/donkey/exit.sh
  sleep 5
fi
start_ws=$(swaymsg -t get_workspaces -r | jq -r '.[] | select(.focused) | .name')
start_profile=$(profile)
if donkey_up; then
  echo "FAIL a Donkey window is already open; close it first"
  exit 1
fi

setsid /storage/roms/ports/Donkey.sh >/dev/null 2>&1 </dev/null &
i=0
while [ $i -lt 40 ] && ! donkey_up; do sleep 0.5; i=$((i + 1)); done
sleep 4
check "window appears" "$(donkey_up && echo yes)" yes
check "browse profile loaded" "$(profile)" "Donkey browse"
shot 1-browse

# Focus the address bar; the keyboard should appear by itself.
key KEY_LEFTCTRL true; tap KEY_L; key KEY_LEFTCTRL false
sleep 2
check "keys profile while keyboard is up" "$(profile)" "Donkey keys"
shot 2-keyboard

# D-pad right twice, then A: F16, F16, F17 through Sway to the keyboard.
tap KEY_F16; sleep 0.2; tap KEY_F16; sleep 0.2; tap KEY_F17
sleep 1
shot 3-typed

# Y hides the keyboard and hands the buttons back to browsing.
tap KEY_F24
sleep 2
check "browse profile after hiding" "$(profile)" "Donkey browse"
shot 4-hidden

# Home exits.
tap KEY_F23
i=0
while [ $i -lt 30 ] && donkey_up; do sleep 0.5; i=$((i + 1)); done
sleep 3
check "window closed" "$(donkey_up && echo yes || echo no)" no
check "keyboard stopped" "$(pidof wvkbd-donkey || echo none)" none
check "browser stopped" "$(pgrep -f /storage/apps/donkey/firefox/ >/dev/null && echo running || echo stopped)" stopped
check "workspace restored" "$(swaymsg -t get_workspaces -r | jq -r '.[] | select(.focused) | .name')" "$start_ws"
# InputPlumber takes a moment to come back after Donkey restarts it.
i=0
while [ $i -lt 20 ] && [ "$(profile)" != "$start_profile" ]; do sleep 0.5; i=$((i + 1)); done
check "controller restored" "$(profile)" "$start_profile"
echo "failures: $fails"
EOF

mkdir -p "$SHOTS"
# shellcheck disable=SC2086
scp -q $SSH_OPTS "$HOST:/tmp/donkey-smoke-*.png" "$SHOTS/"
echo "screenshots: build/shots/"
