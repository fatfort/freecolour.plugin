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

OPEN — not started yet.
