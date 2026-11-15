# Donkey's keyboard

`wvkbd-donkey` is [wvkbd](https://github.com/jjsullivan5196/wvkbd) v0.21
with two patches from `patches/`:

1. **Browse layouts.** `browse` (letters with a number row, plus `: / - @ .`
   on the bottom rows for typing addresses) and `browsesymbols`. Both have
   five even rows. The patch also widens the gaps between keys.
2. **Controller navigation.**
   - A focus ring you move with commands. It appears on the first
     controller input, and after that taps on the screen move it too.
   - `--control PATH` makes a FIFO that takes one command per line:
     `up down left right press shift layer backspace enter space
     cursor-left cursor-right show hide toggle`.
   - `--hook CMD` runs `CMD show` or `CMD hide` whenever the keyboard
     appears or disappears.
   - `--focus RRGGBB` sets the ring colour.

wvkbd v0.21's `--auto` mode does the rest: the keyboard shows itself when a
text field takes focus and hides itself when focus leaves.

Build it on an aarch64 host with podman:

```sh
keyboard/build.sh        # -> build/bin/wvkbd-donkey
```

## License

wvkbd is GPL-3.0-or-later, and so are Donkey's patches to it; see `COPYING`
in this directory. The rest of Donkey is MPL-2.0. Each binary release ships
`wvkbd-donkey` together with this directory, which is its complete
corresponding source: the upstream tag plus these patches.
