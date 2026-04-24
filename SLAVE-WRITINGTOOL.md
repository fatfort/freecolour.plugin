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

DONE — 2026-04-24

### tl;dr

- Dumped the live `WritingTool.qml` by zstd-decoding the 1030 zstd
  frames embedded in `../ferrari/scratch/xochitl-3.26.0.68`. The
  clean source is at `../ferrari/scratch/qml-dump/files/WritingTool.qml`
  (17312 bytes, 479 lines). `PrimaryPenMenu.qml`, `SecondaryPenMenu.qml`
  and a stub `Toolbar.qml` slice are in the same dir.
- The upstream Timer pattern fails because it **writes to a `required
  property` on a Repeater delegate**. `colorComponent` is the delegate
  in `Repeater { model: colorModel; ArkControls.FoldoutGridItem { id:
  colorComponent; required property var rgb; required property int
  toolColor; required property var displayColor; … } }`. Required
  properties are driven by the model's roles; the Repeater re-asserts
  them on any model change (and the model is bound to `root.pen.tool`,
  which flips on every pen selection). The Timer fires once, the
  model's next refresh clobbers it. Dead on arrival.
- **Swatch tap → `penColorSelected` chain** (line 370):
  `onPressed: root.penColorSelected(rgb, toolColor)` fires on the
  delegate, which is relayed by the root's `onPenColorSelected` handler
  (line 460) to `root.toolbar.penColorSelected(rgb, paletteEnum)`.
  The swatch visual comes from `iconComponent: ArkControls.ColorSwatch
  { color: displayColor … }` (line 359–369).
- **Every identifier needed is already in `reference/hashtab`.** Confirmed
  via lookup: `colorComponent` (7060683329257607547), `iconComponent`
  (12414237232740172069), `onPressed` (254542253295368380), `color`
  (214622605608), `rgb` (197098340), `toolColor`
  (254549367717124902), `Line.ArgbCode` (1240201314318999894),
  `penColorSelected` (604284659367095156), `root` (6504254477),
  `onPenColorSelected` (15078258103192245841). No custom identifiers
  required.

### The three candidate injection points

#### A — Delegate-level binding rewrites (RECOMMENDED)

**AFFECT** `WritingTool.qml` → **TRAVERSE** `?#colorComponent` →
**REBUILD** the `onPressed` handler (substitute at tap time) **and**
**TRAVERSE** `iconComponent` → **REBUILD** `color` (substitute at
render time).

Why this works where the Timer doesn't: we're editing the **binding
expressions**, not *writing* to required properties. A `REBUILD`
changes the expression the QML engine evaluates. The engine re-evaluates
on every dependency change — and every re-evaluation runs our
substitution logic. The Repeater's model refresh doesn't undo the
patch; it only re-evaluates the (now-patched) binding.

Sketch (plain-name source for qmldiff — SLAVE-QMLDIFF compiles to hashes):

```
AFFECT "qrc:/qt/qml/xofm/libs/toolbar/qml/WritingTool.qml"

TRAVERSE ?#colorComponent
    // 1. Tap behaviour: when the pink delegate is tapped, emit brown.
    REBUILD onPressed
    LOCATE REPLACE
    INSERT {
        if (colorComponent.toolColor === Line.ArgbCode && colorComponent.rgb === 0xFFF29EFF) {
            root.penColorSelected(0xFF8B4513, Line.ArgbCode);
        } else {
            root.penColorSelected(colorComponent.rgb, colorComponent.toolColor);
        }
    }
    END REBUILD

    // 2. Swatch visual: when we're rendering the pink delegate, show brown.
    TRAVERSE iconComponent
        REBUILD color
        LOCATE BEFORE ALL
        INSERT { (colorComponent.toolColor === Line.ArgbCode && colorComponent.rgb === 0xFFF29EFF) ? "#8B4513" : }
        END REBUILD
    END TRAVERSE
END TRAVERSE

END AFFECT
```

For pink → brown on highlighter (stated goal):
- `Line.ArgbCode` is enum 9 (the wildcard-RGB enum; highlighter uses it).
- Pink ARGB in the current highlighter palette: `0xFFF29EFF`.
- Brown: `0xFF8B4513`.
- The tap fires `penColorSelected(0xFF8B4513, 9)` → toolbar pen's
  `colorCode` becomes `0xFF8B4513` → rasterizer (already proven to
  honour `color_rgba` on enum 9 tools per MASTER Proven #1) renders
  brown strokes.

Edge case: the still-selected-indicator in `indicator.bodyColor`
(the small circle on the collapsed toolbar) is bound via
`colorModel.displayColor(root.pen.color, root.pen.colorCode)` — a
C++ call. That can't be hit from QML without further diffs. But it
re-evaluates whenever `root.pen.colorCode` changes, which happens
the moment the user taps the swatch, and since colorModel is
unchanged from upstream it will simply render `#F29EFF` (pink).
Acceptable for v1 — the user only cares about stroke colour. If
the collapsed-toolbar circle looks wrong we can add a parallel
`TRAVERSE ?#indicator / REBUILD bodyColor` substitution later.

#### B — Root signal handler substitution

**TRAVERSE** `?#root` → **REBUILD** `onPenColorSelected` (the arrow
function on line 460) to remap pink → brown before forwarding to
`root.toolbar.penColorSelected`.

```
TRAVERSE ?#root
    REBUILD onPenColorSelected
    LOCATE REPLACE
    INSERT (rgb, paletteEnum) => {
        if (paletteEnum === Line.ArgbCode && rgb === 0xFFF29EFF) {
            rgb = 0xFF8B4513;
        }
        root.toolbar.penColorSelected(rgb, paletteEnum);
    }
    END REBUILD
END TRAVERSE
```

Single-site chokepoint for *all* colour-selection dispatches
(delegate tap, `ensureSelection`'s defaulting path, any future
caller). Upside: robust. Downside: still needs A's iconComponent
colour rewrite to make the swatch look brown; a user who taps a
pink swatch and sees brown ink will be confused. Strictly weaker
than A for the pink→brown use case, but would be the right place
if we ever needed to intercept *all* colour-selection sites.

#### C — Visual-only iconComponent patch (rejected)

Just change the rendered colour. Rasterizer still gets pink's rgb,
strokes come out pink. Mentioned only to rule it out: the swatch
visual and the stroke rgb are separate data flows; patching the
visual without patching `onPressed` changes nothing meaningful
(and is actively misleading).

### Recommendation

Ship **A** in v1. Two `REBUILD`s, both against expression bindings
(no required-property writes), so the Repeater can't clobber them.
Covers both the visual and the emit. Graceful fallback (the
`else` branch + ternary `: displayColor`) means any delegate that
*isn't* the pink/ARGB one passes through untouched.

### Artifacts left for MASTER / SLAVE-QMLDIFF

- `../ferrari/scratch/qml-dump/files/WritingTool.qml` — the full
  479-line QML source. Required reading when writing the qmldiff
  source.
- `../ferrari/scratch/qml-dump/all-decompressed.bin` — all 1030 zstd
  frames concatenated (8.1 MB), with `==== OFFSET … SIZE … ====`
  headers. Useful if we later need to fish out `Toolbar.qml`,
  `PenColorModel`-adjacent QML, or other files without re-running
  the extractor.
- Decompression recipe (for future slaves):
  ```python
  import zstandard as zstd
  data = open("xochitl-3.26.0.68", "rb").read()
  dctx = zstd.ZstdDecompressor()
  # scan for b"\x28\xb5\x2f\xfd" frame magic, dctx.decompress each.
  ```
  1030 frames decompress cleanly; ~60% are QML fragments, the rest
  are compiled-QML bytecode blobs and assorted resource data.
