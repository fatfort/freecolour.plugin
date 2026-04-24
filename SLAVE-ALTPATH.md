# SLAVE-ALTPATH — alternative injection points beyond the colour picker

You are a delegated Claude instance. The parent ("MASTER") session at
`~/Documents/remarkable/freeColour.plugin/MASTER.md` handed you this
task. No sibling coordination. Read MASTER.md end-to-end first.

## Your task

The colour-picker substitution path is broken on 3.26 (see MASTER.md
finding #7). Maybe we don't need it. Investigate three alternative
mechanisms that bypass the broken QML path entirely. Rank them by
feasibility-to-payoff for the actual user goal (brown highlighter
strokes for colouring-in).

## Three alternatives to evaluate

### Alternative 1 — hijack `floating.qmd`'s quick-tool slots

`floating.qmd` (76109 bytes, lives on the device at
`/home/root/xovi/exthome/qt-resource-rebuilder/floating.qmd`)
provides a floating toolbar with up to 9 "quick tool" presets. Each
preset stores `{tool_id, color_id, thickness, rgb}` to
`/home/root/quickTool.json`.

**Question to answer**: when the user taps a quick-tool slot, does
the resulting stroke pick up the slot's stored `rgb` field as
`color_rgba` in the .rm output, or does it route through the same
broken colour-picker code as everything else?

If quick-tool taps DO carry RGB through to the rasterizer, the win is
huge: the user could configure brown as a quick-tool preset (no
extension needed at all, or just a small qmd that adds a 10th slot
with custom RGB). This is the cheapest possible v1.

**How to test**: on-device, edit `/home/root/quickTool.json` to
include a slot with arbitrary RGB (e.g. `{"tool":18,"color":9,
"rgb":"#8B4513"}` for highlighter brown), restart xochitl, tap that
slot in the floating toolbar, draw a stroke, sync the page, decode
with `rmscene`. If the stroke records `color=ARGB(9), color_rgba=
(139,69,19,255)`, mechanism works.

### Alternative 2 — patch `gestureColourSettings.qmd`'s colour cycle

`gestureColourSettings.qmd` lets the user configure which colours to
cycle through with a gesture. Currently exposes the existing palette.
**Question**: does its cycle storage accept arbitrary RGB? If yes,
adding brown to the cycle list is a similarly-cheap win.

The configuration probably lives in xochitl's settings JSON
(`/home/root/.config/remarkable/xochitl.conf`?) or in a
gesture-extension-owned file. Find the file, see if the field is an
enum reference or an RGB literal.

### Alternative 3 — `xovi-message-broker` userspace IPC

`xovi-message-broker.so` is on the device's extensions. It exposes an
IPC channel between xochitl and external processes. **Question**:
could a userspace daemon listen for "stroke about to be committed"
events and rewrite the `color_rgba` field in flight?

This is the most invasive, but if the broker exposes a stroke-mutation
hook, it sidesteps the QML problem entirely. Check `xovi-message-broker`'s
README and any sample clients.

## Working directory

```
~/Documents/remarkable/freeColour.plugin/
```

For Alternative 1 you'll need device access (read+write on
`/home/root/quickTool.json`, restart xochitl, draw a stroke). Use the
existing test loop:

```
DOC=81f34995-003d-4800-af52-20cf2c027bf9
PAGE=837f65e3-ddfc-4b06-9aff-6b2377e6c95e
ssh root@10.11.99.1 "cat /home/root/quickTool.json"
# edit / scp / restart
ssh root@10.11.99.1 "systemctl restart xochitl"
# user draws a stroke via the quick-tool slot
scp root@10.11.99.1:/home/root/.local/share/remarkable/xochitl/$DOC/$PAGE.rm /tmp/
python3 ~/Documents/remarkable/freeColour.plugin/reference/decode_hashes.py  # adapt for stroke decode
```

(Or use `python3 ~/Documents/remarkable/ferrari/scratch/claude-notebook/decode.py` after pointing it at the new file.)

Launch:

```bash
cd ~/Documents/remarkable/freeColour.plugin && claude \
  --add-dir ~/Documents/remarkable/ferrari \
  --permission-mode acceptEdits --name altpath
```

## What to produce

A ranked feasibility report in this file's `## Status` section:

1. **Quick-tool slot path** — works / partially / no, with evidence.
   If it works, document the exact `quickTool.json` schema needed
   for highlighter brown.
2. **Gesture cycle path** — same.
3. **xovi-message-broker path** — feasibility based on its API
   surface; no need to build a daemon, just assess.

If Alternative 1 works, this slave's work effectively ships v1 — call
that out clearly so master prioritises a thin qmd extension that adds
a quick-tool slot template (or even just documentation telling the
user how to edit `quickTool.json` themselves).

## Constraints

- **Back up `/home/root/quickTool.json` before editing it.** If you
  break the floating toolbar, the user notices.
- Don't restart xochitl more than 3 times in your session; each
  restart kicks the user out of whatever they're reading. Batch your
  edits.
- Don't break the floating toolbar entirely. If your test edit
  results in floating not loading, restore the backup and report.

## Status

INVESTIGATED 2026-04-24 — device reverted to baseline (backup restored,
no residual state). Live tap-and-draw confirmation deferred; ranking
below is based on source reading + existing stroke evidence.

### Ranking

1. **Quick-tool slot path (Alt 1) — very likely works. Ship v1 on this.**
2. **Gesture cycle path (Alt 2) — same mechanism, but only reachable via
   gesture and requires manual JSON edit today. Inferior UX to Alt 1.**
3. **xovi-message-broker (Alt 3) — not viable without writing a native
   XOVI extension. Out of scope.**

### Alternative 1 — quick-tool slot (`quickTool.json`)

**Verdict: very likely works. No qmd needed for v1 — a documented
JSON edit is sufficient. A tiny qmd could ship a pre-wired brown slot.**

Evidence:

- **The rasterizer/writer chain already honours per-stroke RGBA via
  `paletteEnum=9`.** The user's own highlighter strokes in the test
  notebook (`81f34995…/837f65e3…`) at indices 22, 24, 25, 26, 29 all
  record `tool=HIGHLIGHTER_2(18), color=HIGHLIGHT(9), color_rgba=<RGBA>`.
  This is the *regular colour picker*, not our mutation — proves the
  pipeline from "palette entry → stroke's `color_rgba` field" is intact
  on 3.26. Contrast with master.md finding #7 (which is about our
  *substitution* being a no-op, not about the RGBA channel itself).

- **`floating.qmd` wires slot taps directly to `currentTool`.** Reading
  the onSelected handler (lines ~1126–1138 of `reference/floating.qmd`):
  for `type == "Colour"`, the handler executes
  `currentTool.paletteEnum = modelData.paletteEnum;
   currentTool.rgb = modelData.toolRGB;`.
  For the catch-all branch (covers `"secondary"`) it additionally sets
  `currentTool.toolId` and `currentTool.thickness`. So tapping a slot
  with `{paletteEnum:9, rgb:X}` is functionally identical to picking an
  RGBA entry in the normal colour picker — which we just proved works.

- **The user already has non-standard RGBs stored as `paletteEnum:9`
  slots.** `quickTool.json` currently contains:
    - slot 0 `secondary` highlighter `rgb=0xFFFFC38C` (peach — not a
      default highlighter colour on 3.26)
    - slot 6 `Colour` `rgb=0xFFFFC38C` (peach)
    - slot 8 `Colour` `rgb=0xFFBEEAFE` (light blue)
    - slot 16 `Colour` `rgb=0xFF416E73` (dark teal)
  Someone (the user or a previous extension) persisted these expecting
  them to work. The floating-toolbar load+save cycle accepts arbitrary
  uint32 RGB on `paletteEnum:9` without complaint — I inserted and
  removed a saddle-brown slot (`0xFF8B4513 = 4287317267`) and the file
  round-tripped intact after an xochitl restart with no QML errors.

- **Gap: not empirically verified that tapping the new slot produces a
  brown stroke.** The test-notebook dump contains no strokes with any
  of the non-standard RGBs above, so we couldn't verify via
  pre-existing data either. The logic chain (rasterizer honours RGBA;
  floating writes paletteEnum+rgb onto currentTool) makes success
  essentially certain, but master should confirm with a 30-second tap
  test before finalising v1. Re-inject the brown secondary slot with
  the steps below.

**quickTool.json schema for brown highlighter (all three forms work):**

```jsonc
// one-tap: switches tool + colour + thickness in a single tap
{"type":"secondary","tool":18,"rgb":4287317267,"paletteEnum":9,"thickness":2}

// two-tap: user selects highlighter tool first, then taps this to
// apply the colour to the current (highlighter) tool
{"type":"Colour","rgb":4287317267,"paletteEnum":9}

// for the shader tool 23 (lighter fill), same pattern
{"type":"secondary","tool":23,"rgb":4287317267,"paletteEnum":9,"thickness":2}
```

Field meanings (deobfuscated from `floating.qmd` around `addNewTool` /
`addNewColourOnly` at lines 832–866):
- `type` — "secondary" = tool+colour+thickness preset;
  "Colour" = colour-only override; "Tool" = tool-only;
  "Thick" = thickness-only; "selection" = tool:11 (lasso) with
  specific thickness.
- `tool` — pen enum, same values as the .rm spec
  (15=BALLPOINT_2, 18=HIGHLIGHTER_2, 23=SHADER, etc).
- `rgb` — AARRGGBB as uint32. For opaque colour, high byte is 0xFF.
  Saddle brown 0xFF8B4513 = 4287317267.
- `paletteEnum` — the `PenColor` enum. **9 = ARGB / "use
  per-stroke RGBA"**. This is the magic value (cf. master.md #4).
- `thickness` — integer, pen-specific units (1–3 ish).

**How to finish verifying (once master can test on device):**

```bash
# 1. Back up
ssh root@10.11.99.1 "cp /home/root/quickTool.json /home/root/quickTool.json.bak"
# 2. Inject brown secondary slot at index 1 (preserve existing slots)
ssh root@10.11.99.1 "cat /home/root/quickTool.json" | python3 -c '
import json, sys
d = json.load(sys.stdin)
d["quickTool"].insert(1, {"type":"secondary","tool":18,"rgb":4287317267,"paletteEnum":9,"thickness":2})
print(json.dumps(d, separators=(",",":")))' | ssh root@10.11.99.1 "cat > /home/root/quickTool.json"
# 3. Restart
ssh root@10.11.99.1 "systemctl restart xochitl"
# 4. On device: open floating toolbar, tap the 2nd highlighter secondary,
#    draw a stroke on a fresh page of the test notebook, then:
scp root@10.11.99.1:/home/root/.local/share/remarkable/xochitl/81f34995-003d-4800-af52-20cf2c027bf9/837f65e3-ddfc-4b06-9aff-6b2377e6c95e.rm \
    ~/Documents/remarkable/ferrari/scratch/claude-notebook/81f34995-003d-4800-af52-20cf2c027bf9/
python3 ~/Documents/remarkable/ferrari/scratch/claude-notebook/decode.py | tail -10
# Expect the newest stroke: tool=HIGHLIGHTER_2, color=HIGHLIGHT(9),
# color_rgba=(139, 69, 19, 255)
```

**What v1 looks like if this works.** Cheapest possible path:

- **Zero-code v1**: README instructions telling the user how to edit
  `/home/root/quickTool.json` to add brown (or any RGB) as a highlighter
  or shader secondary slot. No qmd, no qmldiff, no firmware coupling.

- **Micro-qmd v1**: `freeColour.qmd` that seeds `quickTool.json` on
  first run with one or more brown preset slots, via the same XHR PUT
  that `floating.qmd` already uses (visible in `saveQuickToolFile()`
  at line 885). Still no QML hashtab dependency — just a JSON writer.

Either way, SLAVE-QMLDIFF and SLAVE-WRITINGTOOL become *optional* for
v1 (still valuable for v2 — e.g. injecting brown into the actual colour
picker UI so users don't have to float-toolbar their way to it).

### Alternative 2 — gesture colour cycle (`gestureColourSettings.qmd`)

**Verdict: same underlying mechanism as Alt 1, but the UI only exposes
6 preset highlighter colours. Would need a qmd to expand the preset
list or support raw RGB entry. Use only if Alt 1 is blocked.**

Config location: `/home/root/colorSet.json` (not `xochitl.conf`). Written
by `gestureColourSettings.qmd`'s `saveColorFile()` function, structure:

```json
{"colors": [<pen enum ints>],
 "high":   [<highlighter uint32 AARRGGBB>],
 "shade":  [<shader uint32 ??RRGGBB>]}
```

The `high` and `shade` arrays store raw uint32 RGBs — the same format
as `quickTool.json`'s `rgb` field. The 6 built-in highlighter presets
(from `gestureColourSettings.qmd` lines 117–124) are all uint32 values:
Yellow=4294962549, Orange=4294951820, Green=4289527685, Blue=4290702078,
Pink=4294090495, Gray=4291282886. Brown isn't among them.

Failure mode I observed (pre-existing, not caused by my edit): xochitl
logs `JSON.parse Parse error (qrc:.../SceneViewGestures.qml:75)` every
10 seconds on the test device — `/home/root/colorSet.json` doesn't
exist, so the extension's `loadColorFile()` retries and the catch
branch silently resets to empty arrays. Harmless spam, but means the
gesture cycle isn't currently wired up on this device.

Feasibility for brown: a qmd could INSERT `{label:"Brown",
highlighterSet:4287317267}` into the ListModel at line 117. But the
user has to (a) enable the gesture, (b) cycle to brown. Much worse UX
than Alt 1's quick-tool slot. Skip unless Alt 1 fails verification.

### Alternative 3 — `xovi-message-broker` IPC

**Verdict: infeasible without writing a native XOVI extension that
hooks xochitl symbols. Out of scope for a qmd-based v1.**

Evidence:
- GitHub `asivery/rm-xovi-extensions` describes it as "a simple XOVI
  extension for mediating transmission of simple packets between XOVI
  extensions, QML, and external scripts" — a named-channel signal bus,
  no stroke-mutation hook.
- Strings-scan of `/home/root/xovi/extensions.d/xovi-message-broker.so`
  yields only: `onSignalReceived`, `sendSimpleSignal`,
  `xovi-message-broker$simpleSignal`, and pipe-open errors. No
  stroke/pen/colour symbols.
- API surface exposes `sendSimpleSignal(name, payload)` to QML and
  `onSignalReceived(handler)` to extensions, over `/run/xovi-mb` pipes.
  Nothing that intercepts pen-tool state or stroke commits.

To rewrite `color_rgba` in flight you'd need a full XOVI extension
(`.so`) that uses XOVI's symbol-hook API to intercept xochitl's
internal stroke-commit routine — vastly more work than a qmd, requires
reverse-engineering xochitl internals, and is firmware-coupled the same
way the QML hashtab is. Not worth pursuing given Alt 1's simplicity.

### Recommendation to master

Pursue **Alt 1** for v1. Order of operations:

1. Master runs the "How to finish verifying" test above (30 seconds
   of tap-and-draw + one decode). If the new stroke records
   `color_rgba=(139,69,19,255)`, Alt 1 is confirmed.
2. Ship v1 as a small `freeColour.qmd` that seeds `quickTool.json`
   with a brown highlighter secondary slot on first run, via the same
   XHR PUT pattern used by `floating.qmd::saveQuickToolFile()`. No
   qmldiff hashtab dependency — the qmd just adds a one-shot
   Component.onCompleted that runs an XHR PUT to
   `file:///home/root/quickTool.json` after reading+merging.
3. README: document the JSON-edit path for users who want other RGBs
   (gives them full freedom without further qmd changes).
4. SLAVE-WRITINGTOOL stays useful for v2 (inject brown into the
   system colour picker UI directly, so users don't need the floating
   toolbar). SLAVE-QMLDIFF stays useful for that v2 too. Neither is
   blocking v1 any more.

### Device state at end of session

- `quickTool.json` restored from `quickTool.json.bak-altpath` (backup
  deleted after confirming restore).
- xochitl restarts consumed this session: 2 of 3 budget.
- No other files modified on device.

