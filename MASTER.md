# MASTER — freeColour project state

You are the **parent** Claude session for the freeColour xovi extension.
Per-task children that helped get us here have been folded into this file
and deleted (originals preserved in git history). When re-invoked, read
this file end-to-end first.

## What this project is

A xovi/qt-resource-rebuilder distribution that adds a free-form colour
picker to xochitl's pen menus on reMarkable Paper Pro (firmware
3.26.0.68, both 11.8" ferrari and 7.3" Move porsche). User goal: brown
for colouring-in (no slot in the stock palette).

## Status — v2.3 SHIPPED AND CONFIRMED WORKING ON FERRARI (2026-05-05)

Latest layer on the picker is a curated **favourites** palette:

- Two side-by-side blocks above the hex field. Recents (left, 4+5
  staggered, rainbow at end of row 2) and favourites (right, 15×2 = 30
  slots, FIFO).
- **Star button** right of the hex code (Canvas-painted polygon — the
  rMPP system font has no ★/☆ glyph, plain Text rendered the missing-
  glyph rectangle). Tap → "Name this colour?" popup with Yes / No,
  just save. Yes shows a TextInput and `Qt.inputMethod.show()`s the
  keyboard.
- **Press-and-hold any swatch** → name-display popup (centered on
  Overlay, self-sizing). Favourites also show a Canvas-painted trash
  button → "Remove this favourite?" confirmation.
- Persistence: `/home/root/.freeColour-favourites.json` as
  `{favourites:[{rgb,name}]}`, capacity 30. Recents continue at
  `/home/root/.freeColour-recent.json`, capacity 8.

Ferrari pen menu accommodates the wider grid (~800 px). Porsche **not
tested** at this layout; v2.4 needs a fork with smaller swatches or
fewer fav columns.

## Status — v1.0 SHIPPED AND CONFIRMED WORKING (2026-04-24)

Vendored from `ingatellent/xovi-qmd-extensions/3.26/` (MIT):

- `src/changeGreenColor.qmd` — enabling REPLACE on `ensureSelection`
  so tools can hold `color=ARGB(9)` + custom `colorCode` without
  falling back to the default. (Byte-identical to FouzR's pre-3.26
  file; FouzR's was always the right shape, just lacked a UI.)
- `src/addColorSelector.qmd` — adds a **"Pick custom color"** menu
  item with a hex AARRGGBB text field that calls
  `penColorSelected(rgbValue, ARGB)` directly.

Verified end-to-end on ferrari: typed `FF8B4513` → highlighter draws
brown. The .rm stroke records as `tool=HIGHLIGHTER_2, color=HIGHLIGHT(9),
rgba=(139,69,19,255)` — exact match.

**Gotchas users will hit:**
- The hex field requires **8 hex digits** (alpha first). Typing
  `8B4513` (6 digits) is rejected by the input-mask validation and
  the field falls back to the default `FF338833` (dark green) —
  which then draws as dark green. Type `FFRRGGBB`.
- Default value is `0xFF338833` (the upstream's example green).
  v1.1 changes this to neutral white.

## Findings from getting here (Proven, don't re-verify)

1. `SHADER` (tool 23) and `HIGHLIGHTER_2` (tool 18) honour arbitrary
   `color_rgba` at the rasterizer. Empirically demonstrated by
   mutating .rm files and re-rendering on device.
2. **Solid pens (BALLPOINT etc.) ignored `color_rgba` in our
   substitution test, BUT** ingatellent#12 reports "any pen can be
   a shader" once routed through the new picker's ARGB tagging.
   This contradicts our finding and is **untested in v1.0** —
   v1.2 should re-verify on a ballpoint stroke now that the picker
   is in place.
3. `.rm` v6 stroke records carry `color_rgba` only on tools that
   use ARGB(9). Pen tools leave it None unless ARGB-routed.
4. **Enum 9 = `ARGB`**, not "HIGHLIGHT" as `rmscene` mislabels it.
   It's the wildcard "use the per-stroke RGBA channel" enum.
5. The qmldiff hashtab format: 8-byte BE zero, 4-byte BE magic
   length + magic, then repeated `(8-byte BE hash, 4-byte BE name
   length, name bytes)`. Decoder at `reference/decode_hashes.py`.
   Toolchain (asivery/qmldiff binary at `~/src/qmldiff/target/release/qmldiff`,
   commit 533d2b9) + `bin/compile-qmd.sh` wrapper available.
6. Highlighter palette RGBs (for reference / future floating
   toolbar work):
   - Yellow `0xFFFFED75` `(255, 237, 117, 255)`
   - Green `0xFFACFF85` `(172, 255, 133, 255)`
   - Pink `0xFFF29EFF` `(242, 158, 255, 255)`
7. **Why FouzR/changeGreenColor's substitution alone is a no-op on
   3.26**: `colorComponent` is a `Repeater` delegate whose properties
   are `required property` bindings driven by `colorModel`. The
   upstream's Timer writes to those properties; the model's next
   refresh (which fires on every pen-tool selection) clobbers them.
   Fix is to edit binding **expressions** (REBUILD), not write
   properties — which is exactly what addColorSelector.qmd does via
   `onPressed: root.penColorSelected(rgbValue, Line.ArgbCode)` on
   a freshly-instantiated component.

## Why-the-broken-pattern-was-broken — extracted live QML

`WritingTool.qml` was extracted by zstd-decoding the 1030 zstd frames
embedded in `xochitl-3.26.0.68` (the live binary on device, ~23 MB).
479 lines, at `../ferrari/scratch/qml-dump/files/WritingTool.qml`.
`PrimaryPenMenu.qml`, `SecondaryPenMenu.qml`, and an all-decompressed
blob (`all-decompressed.bin`, 8.1 MB) sit alongside.

Decompression recipe:

```python
import zstandard as zstd
data = open("xochitl-3.26.0.68", "rb").read()
dctx = zstd.ZstdDecompressor()
# scan for b"\x28\xb5\x2f\xfd" frame magic, dctx.decompress each.
```

1030 frames decompress cleanly; ~60% are QML fragments, the rest are
compiled-QML bytecode and resource data.

## Repo layout

```
freeColour.plugin/
├── MASTER.md                # this file
├── README.md                # user-facing
├── Makefile                 # install / restore against device
├── src/
│   ├── changeGreenColor.qmd # vendored from ingatellent (MIT)
│   ├── addColorSelector.qmd # original v1.0 picker (vendored, kept for reference)
│   └── freeColour.qml-diff  # v2.3 plain-name source (ours, compiles to build/)
├── build/                   # gitignored; compiled qmds land here
├── build-porsche/           # gitignored; reserved for the future Porsche fork
├── bin/
│   ├── compile-qmd.sh       # plain-name → hashed .qmd via qmldiff
│   └── patch-floating.py    # experiment — quickTool.json grid swap (not shipped)
└── reference/
    ├── changeGreenColor.qmd            # FouzR's, verified identical to ingatellent's 3.26
    ├── changeGreenColor-3.26-ingatellent.qmd
    ├── addColorSelector-3.26-ingatellent.qmd
    ├── changeGreenColor.qml-diff       # decompiled plain-name reference
    ├── floating.qmd                    # for v1.2 quickTool.json work
    ├── gestureColourSettings.qmd       # for understanding gesture colour cycle
    ├── toolbar_icon.qmd
    ├── decode_hashes.py                # Python parser for hashtab
    ├── hashtab                         # 666 KB — 20017 entries, locked to 3.26.0.68
    └── qmldiff-workflow.md             # full author/compile/install loop
```

## Roadmap

- **v1.0** ✓ — vendor + ship ingatellent's working pair.
- **v1.1** (in progress, this session) — neutral default colour
  (currently `0xFF338833` dark green; users typing only 6 hex digits
  silently fall through to that default and get green strokes).
  Optional: row of 6–8 preset colour swatches (brown, tan, salmon,
  coral, sky, indigo, olive, teal) above the hex field — one-tap
  common colours, no typing.
- **v1.2** (next session) — pre-seed `quickTool.json` with a brown
  highlighter slot so brown is one tap from the floating toolbar
  without re-opening the picker. Schema (validated as accepted by
  floating's load+save cycle):
  ```jsonc
  // one-tap: tool + colour + thickness
  {"type":"secondary","tool":18,"rgb":4287317267,"paletteEnum":9,"thickness":2}
  // colour-only override on currently-selected tool
  {"type":"Colour","rgb":4287317267,"paletteEnum":9}
  ```
  `4287317267` = `0xFF8B4513` saddle brown. Ship as a small qmd that
  XHR-PUTs an additional slot on first run, or just document the
  manual edit in README.
- **v1.3** — re-test "any pen can be a shader" claim on ballpoint
  using the picker. If true, invalidates Finding #2 above and
  unlocks free-form RGB on every pen, not just highlighter/shader.
  Also opens a documentation update.
- **v2.0** ✓ — HSV colour wheel picker. Canvas-painted hue ring +
  inscribed S/V square, finger-drag hit-testing, replaces the hex
  TextInput. `Canvas`, `onPaint`, `requestPaint`, `MouseArea` +
  gesture handlers all confirmed present in the 3.26 hashtab.
  `Qt.hsva`, `createLinearGradient`, `strokeStyle`, `clearRect` are
  not hashed but are standard Canvas-2D API — qmldiff emits them
  plain in INSERT blocks, Qt parses them at runtime.
- **v2.3** ✓ — favourites palette. 15×2 named-favourites grid right
  of the recents block, with a star button beside the hex field for
  add, press-and-hold for view + remove (with confirmation), and
  persistence at `/home/root/.freeColour-favourites.json`. Star and
  trash icons painted on `Canvas` because the rMPP system font lacks
  ★/☆/🗑. Total picker width ~800 px; Ferrari only.
- **v2.4** — Porsche layout fork. Either a smaller-swatch variant or
  fewer favourite columns; needs a separate compile target driven by
  the Makefile (e.g. `src/freeColour-porsche.qml-diff` →
  `build-porsche/freeColour.qmd`).
- **v2.5** — 3 R/G/B sliders + live preview as a simpler alternative
  to the wheel if it ever regresses. `ArkControls.Slider`
  (16889273475487444716) is in the hashtab.
- **v2.6** — pre-seed `quickTool.json` with a brown highlighter slot
  so brown is one tap from the floating toolbar without re-opening
  the picker.

## Decision log

- **2026-04-24** — v0.1 cloned FouzR's `changeGreenColor.qmd`
  substitution pattern. Loaded but a no-op (Finding #7 above).
  Pivoted to slave-driven investigation.
- **2026-04-24** — Slaves returned. Community had already shipped
  the answer (`ingatellent/addColorSelector.qmd`). Vendored it +
  Makefile + README. v1.0 confirmed working with `FF8B4513` →
  brown highlighter stroke.
- **2026-04-24** — User requested wheel/picker UX over hex typing
  + floating-toolbar integration. Sliders/wheel deferred to v2;
  v1.1 ships preset palette + neutral default as the immediate
  improvement. Floating integration deferred to v1.2 (well-understood
  but needs another session).
- **2026-04-24** — v2.0 shipped via SLAVE-WHEEL. Added a Canvas-painted
  HSV wheel (hue ring + inscribed S/V square) in a modal Popup,
  triggered by a rainbow-gradient swatch appended to the recents Row.
  v1.2 recents + hex TextInput + `Layout.preferredHeight: 140` all
  preserved — the wheel *supplements* rather than replaces. Popup
  is parented to `Overlay.overlay` so it escapes the picker's cramped
  height. Release commits `recordPick` + `penColorSelected` + close.
  `Canvas`/`Popup`/`Overlay`/`MouseArea`/`onPaint`/`requestPaint` all
  in hashtab; compile clean; round-trip decompile matches modulo
  whitespace.
- **2026-05-05** — v2.3 favourites shipped on Ferrari. Final layout:
  side-by-side recents (4+5 staggered, rainbow at end) + favourites
  (15×2, 30 slots) at swatch size 30×30 / 4 px. Star button is a bare
  Canvas (no surrounding Rectangle), strokes always, fills black when
  the current colour is favourited. Long-press popup re-parents to
  `Overlay.overlay` and centres explicitly via x/y math —
  `anchors.centerIn: parent` did **not** propagate as expected through
  Popup; explicit `(parent.width - width)/2` is the reliable form.
  Heights bind to `contentItem`'s inner column `implicitHeight + padding * 2`.
  Three findings forced fixes mid-iteration:
    1. **Font glyph fallback** — plain Text `★` rendered as a missing-
       glyph rectangle on rMPP. Canvas-painted star polygon (10
       points, alternating outer/inner radius) renders cleanly.
    2. **`property int` truncates 32-bit unsigned ARGB** — storing
       `0xFF8B4513` (>2^31) into `property int slotRgb` clamps to
       negative; `(neg).toString(16)` → `"-74bb15"` and `slice(2)`
       gives wrong colour. Fix: never store ARGB in `property int`;
       inline `>>> 0` inside the `Qt.color("#" + ... .slice(2))`
       binding (matches the original ingatellent pattern).
    3. **Virtual keyboard taps register as press-outside** — the
       default `closePolicy: Popup.CloseOnEscape | CloseOnPressOutside`
       made `namePromptPopup` close when the user tapped the on-screen
       keyboard. Fix: `closePolicy: Popup.CloseOnEscape` for popups
       that use `Qt.inputMethod.show()`. Explicit Save/Cancel buttons
       cover the dismissal UX.
  Capacity dialled in by user feedback: 11 → 20 → 30 favourites.
  Block separation 16 → 64 → 128 px. Outer width grew to ~800 px on
  Ferrari (no Porsche test).

## Conventions inherited from `ferrari/CLAUDE.md`

- Device IP: USB `10.11.99.1`, WLAN fallback `192.168.1.112`
  (ferrari). Porsche WLAN is `192.168.1.115`.
- SSH host-key warnings on the rMPPs are a known annoyance; commands
  prefix `-o StrictHostKeyChecking=no` and pipe-grep out the warning
  spam.
- Don't commit large binaries to this repo. The 23 MB
  `xochitl-3.26.0.68` lives at `../ferrari/scratch/xochitl-3.26.0.68`
  and is referenced by path. Same for any QML resource dumps.
- Version-control as you go. Small commits with clear "what + why".
- Iteration on the device requires xochitl restarts that kick the
  user out of whatever they're reading. Batch deploys; don't restart
  more than ~3 times in a session without good cause.
