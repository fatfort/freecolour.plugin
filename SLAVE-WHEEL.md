# SLAVE-WHEEL — replace the hex field with an HSV colour wheel popup

You are a delegated Claude instance. The parent ("MASTER") session at
`~/Documents/remarkable/freeColour.plugin/MASTER.md` handed you this
task. No sibling coordination; all updates surface here under
`## Status`. Read MASTER.md end-to-end first.

## Your task

Replace (or supplement) the hex AARRGGBB text-input field in
`src/freeColour.qml-diff` with a real **HSV colour wheel** picker —
a circular hue ring with a saturation/value triangle (or square)
inside, finger-draggable on the rMPP touchscreen. End state: user
taps "Pick custom color", sees the wheel, drags to the colour they
want, and the current pen draws strokes in that colour. Hex typing
becomes optional / hidden.

## Why this is non-trivial

xochitl's QML stack has **no off-the-shelf colour-wheel component**.
Confirmed by SLAVE-QMLDIFF dumping the hashtab and grepping for
`wheel`, `hue`, `hsv`, `colorpick` — only `Slider`, `SlimSlider`,
and various ArkControls primitives exist. The wheel must be
**hand-built** as either:

- A `Canvas` element painting the hue ring + S/V triangle with
  JavaScript drawing primitives (arc, rect, gradient), with a
  `MouseArea` overlaid for hit-testing → convert tap (x,y) to
  (hue, sat, val) → assign to `colorSelector.rgbValue`.
- An `Image` with a precomputed wheel PNG (not preferred — needs
  asset shipping + doesn't react to gesture drag).

**`Canvas` is the right primitive.** Its `onPaint` handler runs
once per repaint; you draw arcs and gradients with `ctx.arc`,
`ctx.fillStyle`, etc. Verify `Canvas` is in the hashtab before
relying on it (`grep "^Canvas = " /tmp/hashtab.txt`). If it's not,
you'll need a fallback (3 sliders + preview swatch).

## Working directory

```
~/Documents/remarkable/freeColour.plugin/
```

You'll need:

- `src/freeColour.qml-diff` — the current v1.2 picker source. You're
  modifying this. Keep recent-colours tracking; replace only the
  hex `TextInput` block (or supplement it with the wheel above).
- `bin/compile-qmd.sh` — the qmldiff wrapper. Same author/compile/
  install loop as before.
- `reference/qmldiff-workflow.md` — full workflow doc.
- `reference/hashtab` — verify any new identifiers you use.
- `../ferrari/scratch/qml-dump/files/WritingTool.qml` — the live
  xochitl QML you're patching, for reference.

Launch:

```bash
cd ~/Documents/remarkable/freeColour.plugin && claude \
  --add-dir ~/Documents/remarkable/ferrari \
  --permission-mode acceptEdits --name wheel
```

## Design constraints

- **Touch-only**, no stylus needed. The wheel must work with finger
  drag on the rMPP touchscreen.
- **Fits within the existing picker rectangle**. Don't grow the
  parent FoldoutGridItem unless you have to — preserve the recents
  row at the top, fit the wheel below it. If space is tight,
  consider making the wheel pop OUT of the picker (overlay) on tap.
- **Saturation + value control matters.** A pure hue ring without
  S/V means user can only pick saturated colours. Combine the ring
  with an inner triangle (the "Photoshop" style) or a square
  (simpler, easier hit-testing).
- **Persist last-picked colour**. Continue writing to
  `/home/root/.freeColour-recent.json` per v1.2's `recordPick(rgb)`
  function. Each finger-up after a wheel drag should call
  `recordPick(currentRGB)` and `root.penColorSelected(currentRGB, Line.ArgbCode)`.
- **e-ink limitations**: the rMPP renders ~10 distinct CYMK
  pigments via dithering. Colours close to those pigments work
  best; pastels can look washed out. Don't compensate in the
  wheel — let the user pick what they pick. But maybe widen the
  wheel's outer ring for grip on a screen that doesn't refresh
  fast.

## Deliverables

1. **`src/freeColour.qml-diff` updated** with the wheel widget.
   Plain-name source. The Repeater for recents stays at top; the
   wheel takes the lower portion.
2. **`build/freeColour.qmd` compiled cleanly** via
   `bin/compile-qmd.sh src/freeColour.qml-diff`. Verify no
   identifier-not-in-hashtab warnings on critical names. (Comment
   text and JS locals are fine unhashed.)
3. **One on-device test**: install via `make reinstall`, ask the
   user to draw on the wheel, sync the page, decode the stroke
   with `python3 ../ferrari/scratch/claude-notebook/decode.py`,
   confirm `color_rgba` matches the wheel position (within
   reasonable tolerance — dither + finger imprecision).
4. **README updated** with the new UX (single sentence is fine).
5. **MASTER.md decision log entry** noting the v2 ship.

## Constraints

- **Don't break the recents row.** v1.2 ships it; the wheel is
  additive.
- **Don't restart xochitl more than 3 times** in your session;
  each restart kicks the user out of whatever they're reading.
  Iterate on the qmd locally, only deploy when you have a
  candidate worth testing.
- **Test the finger-drag math carefully** before deploy.
  Misinterpreting tap coordinates will produce nonsensical
  colours and burn one of your restart budget slots.
- **If `Canvas` isn't in the hashtab**, fall back to 3 RGB
  sliders (`ArkControls.Slider` IS in the hashtab —
  `16889273475487444716`). Document the fallback decision in
  this file's Status before going down that path.
- **Don't commit the qmldiff binary or build artifacts**; the
  Makefile recompiles `build/` on every `install`/`reinstall`.

## Reference recipe — Canvas hue wheel sketch (untested)

```qml
import QtQuick

Canvas {
    id: wheel
    width: 280; height: 280
    property real centerX: width / 2
    property real centerY: height / 2
    property real outerR: Math.min(width, height) / 2 - 4
    property real innerR: outerR - 30      // ring thickness 30
    property real currentH: 0
    property real currentS: 1
    property real currentV: 1

    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        // Hue ring: many thin arcs around the centre
        for (var deg = 0; deg < 360; deg += 1) {
            ctx.beginPath();
            ctx.arc(centerX, centerY, (outerR + innerR) / 2,
                    (deg - 0.5) * Math.PI / 180,
                    (deg + 0.5) * Math.PI / 180);
            ctx.lineWidth = outerR - innerR;
            ctx.strokeStyle = Qt.hsva(deg / 360, 1, 1, 1);
            ctx.stroke();
        }
        // S/V triangle inside (omitted — see e.g. SwatchInputPicker
        // patterns; or use a square: 0..innerR-something).
    }

    MouseArea {
        anchors.fill: parent
        onPressed: handleDrag(mouseX, mouseY)
        onPositionChanged: handleDrag(mouseX, mouseY)
        onReleased: {
            colorSelector.rgbValue = hsvToARGB(wheel.currentH, wheel.currentS, wheel.currentV);
            colorSelector.recordPick(colorSelector.rgbValue);
            root.penColorSelected(colorSelector.rgbValue, Line.ArgbCode);
        }
    }

    function handleDrag(x, y) {
        var dx = x - centerX, dy = y - centerY;
        var r = Math.sqrt(dx*dx + dy*dy);
        if (r >= innerR && r <= outerR) {
            // In the hue ring — set hue
            wheel.currentH = (Math.atan2(dy, dx) + Math.PI) / (2 * Math.PI);
        } else if (r < innerR) {
            // Inside — set S/V (e.g. linear scale by distance from centre)
            wheel.currentS = Math.min(1, r / innerR);
            wheel.currentV = 1;  // or compute differently
        }
        wheel.requestPaint();
    }

    function hsvToARGB(h, s, v) {
        var c = Qt.hsva(h, s, v, 1);
        // c is a Qt.color object; extract RGB via toString and parse,
        // or use bit-shifts on c.r/c.g/c.b * 255.
        var r = Math.round(c.r * 255);
        var g = Math.round(c.g * 255);
        var b = Math.round(c.b * 255);
        return (0xFF << 24) | (r << 16) | (g << 8) | b;
    }
}
```

This is a sketch, not working code. Test it before assuming the
math is right. The hue formula in particular needs verification —
`atan2` returns -π..π, normalisation and offset depend on which
angle you treat as "0° red".

## Status

OPEN — not started yet.

(When you're done, append a "DONE — <date>" header and a short
summary. Master will then commit and update README.)
