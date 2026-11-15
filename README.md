# Donkey

**Don**'t have a **key**board? Donkey sets up the Firefox web browser for
ROCKNIX handhelds. You get a dark on-screen keyboard you can type on with
the D-pad and face buttons, a toolbar big enough to read and tap, and a
controller layout made for browsing.

Donkey is a launcher and a set of configuration files. Its installer
downloads Mozilla's official Firefox build for Linux aarch64 straight from
Mozilla and runs it unmodified. Everything goes under `/storage`, so the
read-only ROCKNIX system is left alone.

## Status

| Device | ROCKNIX | Status |
|---|---|---|
| Retroid Pocket Flip 2 (SM8250) | nightly, Sway 1.11 | in development |

## Install

1. Copy `donkey-<version>.tar.gz` to the device and unpack it.
2. Over SSH:

   ```sh
   cd donkey-<version>
   ./install.sh
   ```

3. In EmulationStation: **Start → Game Settings → Update Gamelists**, then
   **Ports → Donkey**.

`./install.sh --update-firefox` swaps in Mozilla's latest Firefox. Firefox
also keeps itself up to date.

## Controls

The buttons do different jobs depending on whether the keyboard is up.

| Control | Browsing | Keyboard up |
|---|---|---|
| Right stick | pointer | pointer |
| A | click | type the key under the ring |
| R2 | click | click |
| L2 | context menu | Shift |
| B | back | backspace |
| X | reload | space |
| Y | show keyboard | hide keyboard |
| Start | address bar | Enter |
| Select | new tab | symbols layer |
| L1 / R1 | previous / next tab | move the text cursor |
| D-pad | arrow keys | move the ring |
| Left stick | page up / down | move the ring |
| L3 / R3 | zoom out / in | none |
| Home | exit Donkey | exit Donkey |

The keyboard opens by itself when a text field gets focus and closes when
focus leaves it. Touch works throughout. ROCKNIX's exit chord (L1 + Select
+ Start) also closes Donkey.

## Building

```sh
keyboard/build.sh            # wvkbd-donkey, needs an aarch64 host with podman
tools/package.sh             # dist/donkey-<version>.tar.gz
tools/deploy.sh              # package and install over SSH (DONKEY_HOST, DONKEY_KEY)
```

## License

Donkey's own files are under the Mozilla Public License 2.0 (`LICENSE`).
The keyboard in `keyboard/` is a patched build of
[wvkbd](https://github.com/jjsullivan5196/wvkbd) and is under GPL-3.0; its
source is the patches in that directory.

Firefox is a trademark of the Mozilla Foundation in the U.S. and other
countries. Donkey is not officially associated with Mozilla or its products.
Donkey downloads the Firefox web browser from Mozilla and does not
redistribute it.
