# Donkey

Donkey sets up Mozilla's unmodified Firefox build as a handheld browser on
ROCKNIX. It provides a patched wvkbd on-screen keyboard, InputPlumber
controller profiles, and the Firefox profile defaults.

# Git
This repo lives at `mercurious/donkey`, with the noreply email
(`96538+mercurious@users.noreply.github.com`) as its git identity, and
starts on `main`. Commit locally after every turn; push after testing or
when the operator says to. The active `gh` account may switch to another
account: switch back to `mercurious` without commentary.

# Legal lines that shape the code
- **Never ship Firefox.** `install.sh` downloads it from Mozilla at install
  time. Never put a Firefox binary, omni.ja, or a modified Firefox in a
  release or in git.
- **Never put Firefox in the name.** Not in the project name or the port
  name, and no Firefox logo. "Donkey" is the user-facing name, and the
  `--name Donkey` app id stays. Prose may say "the Firefox web browser",
  with the trademark and not-affiliated lines from the README.
- **Firefox CSS stays MPL.** Our files are MPL-2.0, so CSS adapted from
  Firefox's own source can stay MPL as it is.
- **The keyboard is GPL-3.0** (`keyboard/`). A release ships the binary
  together with `keyboard/`, which is its complete source. Never vendor the
  patched wvkbd tree; keep it as patches on a pinned tag.

# ROCKNIX
ROCKNIX is not garden-variety Linux: BusyBox, a read-only system, and root
as the only user. Check your assumptions on the device.
`mercurious/etk` has detailed ROCKNIX docs and tools.
- **Dev device:** Retroid Pocket Flip 2, ssh alias `flip2-12g`
  (`root@sm8250-12gb.local`, key `~/.ssh/etk_rig`). The screen is 1920x1080
  landscape (DSI-1, transform 270) at scale 1. Donkey is installed there
  through portmart at `/storage/apps/donkey`.
- **Session:** Sway 1.11. `XDG_RUNTIME_DIR=/run/0-runtime-dir`,
  `WAYLAND_DISPLAY=wayland-1`, socket `sway-ipc.0.sock`. SSH sessions don't
  source `/etc/profile`; set these yourself.
- **Controller:** InputPlumber 0.82 at `CompositeDevice0`. Profiles load
  with `LoadProfilePath`. Restarting `inputplumber.service` restores the
  stock gamepad.
- **Fonts:** only Liberation (Sans, Serif, Mono), DejaVu Sans Condensed and
  Noto Sans CJK SC. There is no `fc-list`.
- **glibc** is 2.44, the same as Fedora 45, which is why
  `keyboard/Containerfile` builds natively on an aarch64 host.

# Validation with the owner
Never ask the owner-operator to do subordinate drudge work, such as
scripted button-press sequences or click-through checklists, just to tick
off an edge case or a control-surface uncertainty. Get validation honestly:
from the owner playing with it during normal use and reporting bugs, or
from our own instrumentation and tests.
- **Screenshots:** `grim` on the device, with the environment above.
- **Keyboard:** the control FIFO `/run/donkey/keyboard` takes the same
  commands the controller sends, so keyboard navigation is scriptable.
- **Buttons:** InputPlumber's `SendButtonChord` and `SendEvent` inject
  controller input.
