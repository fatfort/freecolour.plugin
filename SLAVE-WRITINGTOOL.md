# SLAVE-WRITINGTOOL — find the real colour-swatch injection point

You are a delegated Claude instance. The parent ("MASTER") session at
`~/Documents/remarkable/freeColour.plugin/MASTER.md` handed you this
task. No sibling coordination. Read MASTER.md end-to-end first.

## Your task

The upstream `changeGreenColor.qmd` substitution mechanism doesn't
work on xochitl 3.26.0.68 (proof: porsche-without-plugin shows same
green as ferrari-with-plugin). The .qmd loads but the substitution
is a no-op. We need to find a working injection point for "intercept
the user's colour-swatch tap and substitute custom RGBA."

Read the actual current `WritingTool.qml` (and any related QML it
references), understand how a swatch tap flows from delegate →
`penColorSelected(rgb, enum)`, and propose 1–3 concrete injection
points that should actually work in 3.26.

## Working directory

```
~/Documents/remarkable/freeColour.plugin/
```

You'll also need:

- `../ferrari/scratch/xochitl-3.26.0.68` — the live xochitl binary
  (~23 MB) we already pulled. QML resources are embedded in this as
  Qt RCC sections.
- `reference/hashtab` — name ↔ hash dictionary. 20017 entries.
- `reference/decode_hashes.py` — Python parser for the hashtab.
- `reference/changeGreenColor.qmd` — the broken upstream pattern.
  Decoded names are at `reference/decode_hashes.py` output.

Launch:

```bash
cd ~/Documents/remarkable/freeColour.plugin && claude \
  --add-dir ~/Documents/remarkable/ferrari \
  --permission-mode acceptEdits --name writingtool
```

## What to figure out

1. **Extract the live `WritingTool.qml`** from the xochitl binary.
   Options, in order of likelihood:
   - Use `qmldiff dump-qml` if SLAVE-QMLDIFF has shipped its
     toolchain (check that slave's status). Fastest.
   - Use `qt-resource-rebuilder`'s debug-dump mode on the device
     itself: see `/home/root/xovi/scripts/debug` for hints, or
     enable verbose logging via env var. The rebuilder is at
     `/home/root/xovi/extensions.d/qt-resource-rebuilder.so`.
   - Roll a Qt RCC parser. The xochitl binary has standard Qt
     resource sections; `python3 -c "import struct; ..."` against
     the rcc magic bytes works. Slower but no toolchain dependency.
   - Last resort: install xochitl-rebuilt (the source-available
     pieces of xochitl are limited; this is unlikely to expose
     the QML).

2. **Read `WritingTool.qml`** end-to-end. Understand:
   - What is `colorComponent`? Is it instantiated by a Repeater
     bound to `colorModel`? If so, the upstream pattern's Timer
     (which writes `toolColor`, `rgb`, `displayColor` on the
     component) is being clobbered every time the model emits a
     refresh. That'd explain why the substitution is a no-op.
   - How does a swatch tap actually invoke `penColorSelected(rgb,
     enum)`? Trace the signal chain. Is it `MouseArea.onClicked`
     reading from `model.<field>`? From the component's properties?
     From a `colorModel.colorAt(index)` lookup?
   - Where else might colour data flow from? Check
     `PrimaryPenMenu.qml`, `SecondaryPenMenu.qml`, `Toolbar.qml` —
     all are visible in the qmldiff log we captured.

3. **Identify 1–3 candidate injection points** that should actually
   take effect. Each should specify:
   - Which QML file to AFFECT (the `[[hash]]` of its path).
   - Which element to TRAVERSE / REPLACE / REBUILD.
   - What to inject (pseudocode is fine; SLAVE-QMLDIFF's tooling
     will turn it into hashes).
   - Why this point works where the colorComponent Timer doesn't.
   - What it'd look like for our specific case: substitute pink
     (rgb `0xFFF29EFF`) with brown (rgb `0xFF8B4513`) on the
     highlighter.

## Background you need to know

- **rmscene names enum 9 "HIGHLIGHT"; xochitl actually calls it
  "ARGB"**. It's the wildcard colour that takes the per-stroke
  RGBA. Highlighter and shader swatches all use ARGB and
  differentiate by the rgb property. Pen-tool swatches use real
  enum values (BLACK=0, …).
- **What we already proved on the rasterizer side**: solid pens
  ignore `color_rgba` (only enum matters); highlighter / shader
  honour it. So a working substitution for the user's stated goal
  (brown for colouring-in) only needs to land on highlighter or
  shader swatches.
- **Highlighter palette RGBs**: Yellow `0xFFFFED75`, Green
  `0xFFACFF85`, Pink `0xFFF29EFF`. The user is OK sacrificing
  pink temporarily.

## Constraints

- Don't redeploy any qmd to the device yourself — that's MASTER's
  job once your findings + SLAVE-QMLDIFF's toolchain are both
  ready. Iteration on the device requires xochitl restarts which
  the user may notice; batch them.
- Don't commit the xochitl binary or any large QML dumps to this
  repo. Reference paths only. If you produce useful intermediate
  artifacts (decompressed QML files, etc.), put them in
  `../ferrari/scratch/qml-dump/`.
- If you can't extract `WritingTool.qml` cleanly, document what
  blocked you and propose what tooling would unblock it. Don't
  guess at injection points without reading the actual QML.

## Status

OPEN — not started yet.

(When you're done, append a "DONE — <date>" header and a short
summary: which injection point you recommend, why, and a sketch
of the qmldiff source that uses it. Master will then write the
real `src/freeColour.qmd` against your recommendation.)
