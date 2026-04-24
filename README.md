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

1. **v0.1** — substitute one underused colour slot with brown across all tools.
   Validate end-to-end pipeline (write qmd → push → restart → see brown).
2. **v0.2** — add a second slot for a different colour, parameterise.
3. **v0.3** — focus on highlighter (tool 18) since that's the opaque
   coloring-in use case; restrict the substitution to a slot only that tool
   uses.
4. **v1.0** — actual HSV picker UI. Requires injecting a new QML popup
   into the colour-foldout for highlighter/shader. Significantly more work
   than the prior versions; will need new identifier hashes added to the
   hashtab and likely the asivery `qmldiff` tool to compile from
   plain-name source.

## References

- [asivery/qmldiff](https://github.com/asivery/qmldiff) — the compiler tool
- [asivery/rm-xovi-extensions](https://github.com/asivery/rm-xovi-extensions) — qt-resource-rebuilder lives here
- [FouzR/xovi-extensions](https://github.com/FouzR/xovi-extensions) — `changeGreenColor.qmd`, `floating.qmd`, etc.
- `~/Documents/remarkable/ferrari/scratch/claude-notebook/` — the experiments
  that established shader/highlighter honour `color_rgba`.
