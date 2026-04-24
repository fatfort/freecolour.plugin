# freeColour

A xovi/qt-resource-rebuilder extension that adds free-form RGB colours to xochitl's pen tools on reMarkable Paper Pro.

## Status

Early. v1 substitutes a single chosen colour slot (e.g. `BROWN`) into xochitl's
tool palette by cloning the technique used in upstream `changeGreenColor.qmd`.
Future work targets a full HSV picker UI for the highlighter/shader tools.

## Why this is possible (and where it caps out)

The reMarkable Paper Pro renders strokes through a closed pipeline. Two findings
from on-device experiments:

- `BALLPOINT_2` and other solid pens read **only** `PenColor` enum. Writing
  `color_rgba` to a ballpoint stroke is silently ignored by the rasterizer.
- `SHADER` (tool 23) and `HIGHLIGHTER_2` (tool 18) carry a full RGBA tuple in
  the `.rm` v6 format and the rasterizer **honours arbitrary RGBA**. The
  toolbar's 6/8 colour presets are just hardcoded UI choices.

So free-form colour is reachable for shader and highlighter without binary
patching. Solid pens stay palette-locked; smaller scope than originally hoped
but still unlocks coloring-in on highlighter (opaque) and mixing on shader.

The hardware itself uses ~10 distinct CYMK-derived pigments and dithers
arbitrary RGB targets to the closest combination, so "brown" comes out as a
dithered MK+Y mix. Real brown, not red.

## Repo layout

```
freeColour.plugin/
├── README.md
├── Makefile              # build / install / restore
├── src/
│   └── freeColour.qmd    # the qmldiff source (currently in pre-hashed form)
└── reference/            # upstream files studied to build this
    ├── changeGreenColor.qmd   # template we're modelled on
    ├── floating.qmd           # full floating-toolbar example (reference)
    ├── gestureColourSettings.qmd
    ├── toolbar_icon.qmd
    └── hashtab                # binary hash↔name dictionary, locked to 3.26.0.68
```

## Target firmware

3.26.0.68 only (verified by hashtab header). Intended to work on both the
11.8" Paper Pro (ferrari) and the Paper Pro Move (porsche) since they share
a firmware/xochitl build.

## Architecture

`qt-resource-rebuilder.so` (an existing xovi extension on the device) loads
`*.qmd` files from `/home/root/xovi/exthome/qt-resource-rebuilder/` and
applies them as in-process patches to xochitl's QML resources at startup.

Our `freeColour.qmd` follows the `changeGreenColor.qmd` pattern: it
intercepts the tool-colour setter callback inside xochitl and substitutes
a chosen `originalToolColor` enum ID with a custom RGB value.

## Roadmap

The user's actual goal is **more slots, not substituted ones**. v0.1 is the
substitution approach because it's a 60-line clone of an existing extension.
v1 will be additive (new entries injected into the colour model) and is the
real target.

1. **v0.1** ✓ — substitute slot 5 (PINK) with brown via the changeGreenColor
   pattern. Preserves the upstream slot-10 green substitution. Brown is then
   reachable on highlighter (and shader, where it'll be translucent), at the
   cost of pink in those palettes. Solid pens that show slot 5 will draw
   yellow-ish (HIGHLIGHT enum default) when the brown swatch is tapped —
   known limitation of the enum-9 remap path.
2. **v0.2** — multi-substitution preset (e.g. PINK→brown, GRAY→tan, GREEN_2→olive)
   with one knob, still substitutive.
3. **v1.0** — additive: inject new entries into the colour model so the
   palette grows from 6/8/9 slots up to 12+, without giving anything up.
   Requires INSERT into the colorModel ListModel (not just REBUILD), and
   probably a new column or row in the picker layout. Likely needs new
   identifier hashes added to the hashtab — i.e. building `asivery/qmldiff`
   locally to compile plain-name source against a hashtab we generate
   ourselves from the xochitl QML resources.
4. **v2.0** — HSV picker popup for highlighter/shader specifically (the
   tools that honour `color_rgba`). Free-form colour, not just a fixed
   bigger palette.

## References

- [asivery/qmldiff](https://github.com/asivery/qmldiff) — the compiler tool
- [asivery/rm-xovi-extensions](https://github.com/asivery/rm-xovi-extensions) — qt-resource-rebuilder lives here
- [FouzR/xovi-extensions](https://github.com/FouzR/xovi-extensions) — `changeGreenColor.qmd`, `floating.qmd`, etc.
- `~/Documents/remarkable/ferrari/scratch/claude-notebook/` — the experiments
  that established shader/highlighter honour `color_rgba`.
