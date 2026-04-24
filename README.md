# freeColour

A xovi/qt-resource-rebuilder distribution that adds a free-form hex-ARGB
colour picker to xochitl's pen menus on reMarkable Paper Pro (firmware
3.26.0.68, both 11.8" ferrari and 7.3" Move porsche).

## What you get

Open any notebook → tap a pen → look for **"Pick custom color"** in the
colour menu. Three ways to pick:

- **Tap a recent swatch** — the top row shows your 8 most recent
  picks, seeded on first run with brown, tan, salmon, coral, sky,
  indigo, olive, teal. One tap, no drag.
- **Tap the rainbow swatch at the end of the row** — opens an HSV
  colour wheel overlay. Drag on the hue ring to set hue; drag in the
  inner square for saturation (left→right) and value (top→bottom).
  Release commits the pick, closes the overlay, and prepends it to
  recents.
- **Type a hex `AARRGGBB`** in the field — e.g. `FF8B4513` for saddle
  brown. Must be 8 hex digits (alpha first).

Backed by xochitl's ARGB(9) wildcard colour: highlighter and shader
strokes record `color_rgba=(R,G,B,A)` and the rasterizer renders them
faithfully. Solid pens may also honour the RGBA payload (per
[ingatellent#12](https://github.com/ingatellent/xovi-qmd-extensions/issues/12) —
"any pen can be a shader").

## Install

```sh
git clone <this repo> ~/Documents/remarkable/freeColour.plugin
cd ~/Documents/remarkable/freeColour.plugin
make install                      # USB (10.11.99.1) by default
make install DEVICE=<wlan-ip>     # WLAN
```

The Makefile pushes both qmds, restarts xochitl, and backs up the
device's existing `changeGreenColor.qmd` before overwriting it (so
`make restore` reverses cleanly).

## Uninstall / restore

```sh
make restore     # put original changeGreenColor back, drop addColorSelector, restart
make uninstall   # just drop addColorSelector (leaves our changeGreenColor in place)
make status      # list installed qmds + backups
```

## What's actually shipped

```
src/
├── changeGreenColor.qmd     # vendored from ingatellent (MIT) — REPLACE
│                            # on `ensureSelection` that lets tools hold
│                            # color=ARGB(9) + custom colorCode without
│                            # falling back to defaults.
├── addColorSelector.qmd     # vendored from ingatellent (MIT) — the
│                            # original hex-only picker; kept in tree for
│                            # reference but not installed by the Makefile.
└── freeColour.qml-diff      # OURS — preset palette + neutral default,
                             # forked from addColorSelector. Compiles via
                             # bin/compile-qmd.sh + reference/hashtab to
                             # build/freeColour.qmd.
```

The Makefile's `install` target compiles `src/freeColour.qml-diff` and
pushes `build/freeColour.qmd` alongside `src/changeGreenColor.qmd`,
removing any prior `addColorSelector.qmd` from the device (it's
superseded by our forked version).

## Compatibility

- **Firmware 3.26.0.68 only** — the qmd hashes are locked to that
  version's QML. Newer firmware will need ingatellent (or us) to
  republish against an updated hashtab.
- **Conflicts with FouzR's pre-3.26 `changeGreenColor.qmd`** — both
  patch the same `WritingTool.qml` AFFECT. The Makefile's `install`
  backs up + replaces the existing file; `restore` puts it back.

## Background — what was learned getting here

The first cut of this plugin (v0.1) cloned FouzR's
`changeGreenColor.qmd` substitution pattern. It loaded but did
nothing visible — `colorComponent` is a `Repeater` delegate with
`required property` properties bound to `colorModel` roles, and the
upstream Timer's writes to those properties get clobbered on the
model's next refresh (which fires on every pen-tool selection).

The fix is to edit binding **expressions** rather than write
properties — and ingatellent already shipped exactly that in
`addColorSelector.qmd`. `changeGreenColor.qmd` stays as scaffolding
because its `REPLACE` on `ensureSelection` is what allows
`color=ARGB(9)` + custom `colorCode` to survive the tool-switch
re-validation.

Full project decision log + slave reports + v1-broken history live
in `MASTER.md` and `SLAVE-*.md`.

## Roadmap

- **v1.0** ✓ — ship ingatellent's working pair.
- **v1.1** ✓ — preset palette + neutral default.
- **v1.2** ✓ — persistent recents row above the hex field.
- **v2.0** ✓ — HSV colour wheel replaces hex typing.
- **v2.1** — pre-seed `quickTool.json` with a brown highlighter slot
  for one-tap access from the floating toolbar.
- **v2.2** — re-test "any pen can be a shader" claim on solid pens
  now that the picker forces ARGB tagging. May unlock free-form RGB
  on every pen, not just highlighter/shader.

## Credits

- [ingatellent/xovi-qmd-extensions](https://github.com/ingatellent/xovi-qmd-extensions) — author of the working extensions we ship. MIT.
- [FouzR/xovi-extensions](https://github.com/FouzR/xovi-extensions) — source of the upstream `changeGreenColor.qmd` (byte-identical to ingatellent's 3.26 copy).
- [asivery/qmldiff](https://github.com/asivery/qmldiff) + `qt-resource-rebuilder` — the runtime that makes any of this possible.
- [rmscene](https://github.com/ricklupton/rmscene) — `.rm` v6 decoder used to verify stroke output during development.
