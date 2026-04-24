# freeColour

A xovi/qt-resource-rebuilder distribution that adds a free-form hex-ARGB
colour picker to xochitl's pen menus on reMarkable Paper Pro (firmware
3.26.0.68, both 11.8" ferrari and 7.3" Move porsche).

## What you get

Open any notebook → tap a pen → look for **"Pick custom color"** in the
colour menu. Type any hex AARRGGBB (e.g. `FF8B4513` for saddle brown).
The selected pen draws strokes in that exact RGB.

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
├── changeGreenColor.qmd     # required prerequisite — the REPLACE on
│                            # `ensureSelection` that lets tools stay at
│                            # color=ARGB(9) with a custom colorCode
│                            # without falling back to defaults.
└── addColorSelector.qmd     # the picker UI: a "Pick custom color" menu
                             # item with a hex-input field that calls
                             # `penColorSelected(rgbValue, ARGB)` directly.
```

Both are vendored verbatim from
[ingatellent/xovi-qmd-extensions/3.26](https://github.com/ingatellent/xovi-qmd-extensions/tree/main/3.26)
(MIT licensed). We didn't write them; we packaged them with an
install Makefile and a project history that documents how we
arrived at "use the upstream that already works."

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

- **v1.0** ✓ — ship ingatellent's working pair (this).
- **v1.1** — pre-seed `quickTool.json` with a brown highlighter slot
  so the user gets one-tap brown from the floating toolbar without
  typing `8B4513` every time. SLAVE-ALTPATH validated the JSON
  schema; just need a small qmd that runs an XHR PUT on first load.
- **v1.2** — re-test "any pen can be a shader" claim on solid pens
  now that the picker's path forces ARGB tagging. May invalidate
  MASTER.md proven #2 (solid pens ignore RGBA) — if so, the picker
  unlocks free-form RGB on every pen, not just highlighter/shader.
- **v2.0** — local authoring of new qmds via `bin/compile-qmd.sh`
  and the `asivery/qmldiff` toolchain SLAVE-QMLDIFF set up. For
  example: replace the hex-typing UX with a HSV wheel popup (the
  ingatellent author flagged this as a future direction in #12).

## Credits

- [ingatellent/xovi-qmd-extensions](https://github.com/ingatellent/xovi-qmd-extensions) — author of the working extensions we ship. MIT.
- [FouzR/xovi-extensions](https://github.com/FouzR/xovi-extensions) — source of the upstream `changeGreenColor.qmd` (byte-identical to ingatellent's 3.26 copy).
- [asivery/qmldiff](https://github.com/asivery/qmldiff) + `qt-resource-rebuilder` — the runtime that makes any of this possible.
- [rmscene](https://github.com/ricklupton/rmscene) — `.rm` v6 decoder used to verify stroke output during development.
