#!/bin/sh
# Donkey launcher: runs Mozilla's Firefox build as a handheld browser under
# ROCKNIX's Sway session, with Donkey's keyboard and controller layout.
# Everything Donkey changes on the way in is put back on the way out.

. /etc/profile

APP=/storage/apps/donkey
FIREFOX="$APP/firefox/firefox"
PROFILE=/storage/.mozilla/donkey
RUN=/run/donkey
FIFO="$RUN/keyboard"
LOG="$APP/logs/donkey.log"
WORKSPACE="97:donkey"

# Keycodes Sway sees for the function keys the controller profiles send
# (evdev code + 8). F13-F17, F19 and F21 only reach Sway while the keyboard
# is up; F23 and F24 work in both profiles.
KEY_F13=191 KEY_F14=192 KEY_F15=193 KEY_F16=194 KEY_F17=195
KEY_F19=197 KEY_F21=199 KEY_F23=201 KEY_F24=202

FIREFOX_PID=""
KEYBOARD_PID=""
PRIOR_WORKSPACE=""
TOUCHKB_WAS_ACTIVE=0
PAD_PROFILE_LOADED=0

if [ ! -x "$FIREFOX" ]; then
  echo "Donkey: Firefox is missing from $APP/firefox. Run install.sh." >&2
  exit 1
fi

mkdir -p "$APP/logs" "$RUN" "$PROFILE/chrome" \
  /storage/.cache /storage/.config /storage/.local/share
exec >>"$LOG" 2>&1
echo
echo "== Donkey $(cat "$APP/VERSION" 2>/dev/null) $(date '+%F %T')"

# Launched from EmulationStation these are already set; over SSH they are
# not, so find the running session.
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/0-runtime-dir}"
if [ -z "${WAYLAND_DISPLAY:-}" ]; then
  for sock in "$XDG_RUNTIME_DIR"/wayland-*; do
    case "$sock" in *.lock) continue ;; esac
    [ -S "$sock" ] && WAYLAND_DISPLAY=$(basename "$sock") && break
  done
fi
if [ -z "${SWAYSOCK:-}" ]; then
  for sock in "$XDG_RUNTIME_DIR"/sway-ipc.*.sock; do
    [ -S "$sock" ] && SWAYSOCK="$sock" && break
  done
fi
export WAYLAND_DISPLAY SWAYSOCK
echo "wayland=$WAYLAND_DISPLAY sway=$SWAYSOCK"

export HOME=/storage
export XDG_CACHE_HOME=/storage/.cache
export XDG_CONFIG_HOME=/storage/.config
export XDG_DATA_HOME=/storage/.local/share
export MOZ_ENABLE_WAYLAND=1
# Firefox bundles newer NSS than ROCKNIX; its own copies must win.
export LD_LIBRARY_PATH="$APP/firefox${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
# GTK's Wayland input method talks text-input-v3, which is how the keyboard
# learns that a text field has focus. ROCKNIX ships the module without the
# immodules.cache that lets GTK find it, so Donkey writes its own.
gtk-query-immodules-3.0 /usr/lib/gtk-3.0/3.0.0/immodules/im-wayland.so \
  >"$RUN/immodules.cache"
export GTK_IM_MODULE_FILE="$RUN/immodules.cache"
export GTK_IM_MODULE=wayland

# The composite controller InputPlumber manages; the keyboard hook needs it.
DONKEY_PAD=$(busctl tree org.shadowblip.InputPlumber 2>/dev/null |
  grep -o '/org/shadowblip/InputPlumber/CompositeDevice[0-9]*' | head -n 1)
export DONKEY_PAD

load_pad_profile() {
  [ -n "$DONKEY_PAD" ] || return 1
  busctl call org.shadowblip.InputPlumber "$DONKEY_PAD" \
    org.shadowblip.Input.CompositeDevice LoadProfilePath s "$1"
}

bind_keys() {
  for pair in "$KEY_F13 up" "$KEY_F14 down" "$KEY_F15 left" "$KEY_F16 right"; do
    set -- $pair
    swaymsg -q "bindcode $1 exec echo $2 > $FIFO"
  done
  swaymsg -q "bindcode --no-repeat $KEY_F17 exec echo press > $FIFO"
  swaymsg -q "bindcode --no-repeat $KEY_F19 exec echo shift > $FIFO"
  swaymsg -q "bindcode --no-repeat $KEY_F21 exec echo layer > $FIFO"
  swaymsg -q "bindcode --no-repeat $KEY_F24 exec echo toggle > $FIFO"
  swaymsg -q "bindcode --no-repeat $KEY_F23 exec $APP/exit.sh"
}

unbind_keys() {
  for code in $KEY_F13 $KEY_F14 $KEY_F15 $KEY_F16; do
    swaymsg -q "unbindcode $code"
  done
  for code in $KEY_F17 $KEY_F19 $KEY_F21 $KEY_F24 $KEY_F23; do
    swaymsg -q "unbindcode --no-repeat $code"
  done
}

start_keyboard() {
  # ROCKNIX's own touch keyboard would claim the same input-method slot.
  if systemctl is-active --quiet touchkeyboard.service; then
    TOUCHKB_WAS_ACTIVE=1
    systemctl stop touchkeyboard.service
  fi
  "$APP/bin/wvkbd-donkey" --auto --hidden \
    -L 420 -H 420 -R 14 --fn "Liberation Sans 28" \
    --bg 15141a --fg 2b2a33 --fg-sp 3b3a45 \
    --press 5b5b66 --press-sp 5b5b66 \
    --text fbfbfe --text-sp fbfbfe --focus 00ddff \
    -l browse,browsesymbols --landscape-layers browse,browsesymbols \
    --control "$FIFO" --hook "$APP/keyboard-hook.sh" &
  KEYBOARD_PID=$!
}

cleanup() {
  trap - EXIT INT TERM HUP
  unbind_keys
  rm -f "$RUN/firefox.pid"
  if [ -n "$KEYBOARD_PID" ]; then
    kill "$KEYBOARD_PID" 2>/dev/null
    wait "$KEYBOARD_PID" 2>/dev/null
  fi
  [ "$TOUCHKB_WAS_ACTIVE" = 1 ] && systemctl start touchkeyboard.service
  # Restarting InputPlumber rebuilds the stock gamepad + keyboard targets,
  # which loading the default profile alone does not.
  [ "$PAD_PROFILE_LOADED" = 1 ] && systemctl restart inputplumber.service
  command -v set_kill >/dev/null && set_kill stop
  [ -n "$PRIOR_WORKSPACE" ] && swaymsg -q "workspace $PRIOR_WORKSPACE"
  echo "== Donkey closed $(date '+%F %T')"
}

on_signal() {
  [ -n "$FIREFOX_PID" ] && kill "$FIREFOX_PID" 2>/dev/null
  exit 130
}

trap cleanup EXIT
trap on_signal INT TERM HUP

# Donkey's defaults go back into the profile on every launch.
cp "$APP/profile/user.js" "$PROFILE/user.js"
cp "$APP/profile/chrome/userChrome.css" "$PROFILE/chrome/userChrome.css"

# ROCKNIX's global exit chord (L1 + Select + Start) also closes Donkey.
command -v set_kill >/dev/null && set_kill set "firefox firefox-bin"

load_pad_profile "$APP/controller/browse.yaml" && PAD_PROFILE_LOADED=1
start_keyboard
bind_keys

# Firefox gets its own tiled workspace rather than Sway fullscreen: a tiled
# window shrinks to make room for the keyboard instead of hiding under it.
PRIOR_WORKSPACE=$(swaymsg -t get_workspaces -r |
  jq -r '.[] | select(.focused) | .name' | head -n 1)
swaymsg -q "workspace $WORKSPACE"

"$FIREFOX" --no-remote --profile "$PROFILE" --name Donkey "$@" &
FIREFOX_PID=$!
echo "$FIREFOX_PID" >"$RUN/firefox.pid"

tries=0
while [ "$tries" -lt 20 ] && kill -0 "$FIREFOX_PID" 2>/dev/null; do
  if swaymsg -t get_tree | grep -q '"app_id": "Donkey"'; then
    swaymsg -q "[app_id=\"Donkey\"] move container to workspace $WORKSPACE"
    swaymsg -q "workspace $WORKSPACE"
    swaymsg -q '[app_id="Donkey"] focus, fullscreen disable'
    # A restored session can bring back several windows; tab them instead
    # of splitting a 5.5-inch screen between them.
    swaymsg -q layout tabbed
    break
  fi
  tries=$((tries + 1))
  sleep 0.5
done

wait "$FIREFOX_PID"
