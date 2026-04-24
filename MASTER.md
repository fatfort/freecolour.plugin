# MASTER — freeColour project state

You are the **parent** Claude session for the freeColour xovi extension.
Per-task children live in `SLAVE-*.md` briefs in this directory. Your job
is synthesis, decision-making, and ownership of `src/freeColour.qmd`. When
re-invoked, read this file end-to-end first, then check each slave's
`## Status` section for new findings.

## What this project is trying to do

Add free-form RGB colours to xochitl's pen tools on reMarkable Paper Pro
(11.8" ferrari and 7.3" porsche Move, both on firmware 3.26.0.68).
Specifically: brown for coloring-in. The mechanism is a qt-resource-rebuilder
qmd extension that patches xochitl's QML at runtime — no binary patching.

## What we've proven (don't re-test)

1. **`SHADER` (tool 23) and `HIGHLIGHTER_2` (tool 18) honour arbitrary
   `color_rgba`** at the rasterizer. Demonstrated by mutating
   `81f34995-…/837f65e3-….rm` in `ferrari/scratch/claude-notebook/`,
   pushing back, restarting xochitl, and confirming visually that strokes
   4 (shader red→green) and 10 (shader blue→brown) rendered as their new
   RGBA. Decoded via `rmscene`.
2. **Solid pens (BALLPOINT_2, FINELINER, etc.) IGNORE `color_rgba`** and
   read only the `PenColor` enum. Strokes 0 and 1 in the same notebook
   were ballpoint with `color=RED, color_rgba=(green/brown override)` and
   they rendered as red. The rasterizer doesn't even consult RGBA on
   pen tools.
3. **`.rm` v6 stroke records carry `color_rgba` only on tools that use
   ARGB(9)**. Pen tools leave it None. Highlighter and shader use it.
4. **Enum 9 = `ARGB`**, not "HIGHLIGHT" as `rmscene` mislabels it. Per
   the upstream README of `changeGreenColor.qmd`. It's the wildcard
   "use the per-stroke RGBA channel" enum.
5. **The qmldiff hashtab** at
   `/home/root/xovi/exthome/qt-resource-rebuilder/hashtab` (1353 entries
   visible by name, 20017 hashes total) is locked to firmware 3.26.0.68.
   Format: 8-byte BE zero, then 4-byte BE magic length + magic, then
   repeated `(8-byte BE hash, 4-byte BE name length, name bytes)`.
   Decoder at `reference/decode_hashes.py`.
6. **Highlighter palette RGBs captured**:
   - Yellow `0xFFFFED75` = `(255, 237, 117, 255)`
   - Green `0xFFACFF85` = `(172, 255, 133, 255)`
   - Pink `0xFFF29EFF` = `(242, 158, 255, 255)`
7. **The `changeGreenColor.qmd` pattern (which we cloned for v0.1) doesn't
   work on 3.26.0.68.** The .qmd loads (`qmldiff: Processing file …
   WritingTool.qml` appears in xochitl logs) but the Timer's substitution
   is a no-op. Conclusive proof: porsche-without-the-plugin shows the
   same default green as ferrari-with-the-plugin. The upstream README
   claim "Works in exports both on device and through reMarkable's apps"
   is either aspirational or refers to an older firmware. Either the
   hashes target identifiers that no longer exist in 3.26 QML, or the
   colorComponent's properties are immediately rebound by colorModel
   after the Timer writes.

## What we don't know yet

- The actual current shape of `WritingTool.qml` and `colorComponent` in
  3.26 (need to dump from the live xochitl QRC resources).
- Where the colour-swatch tap actually flows to `penColorSelected(rgb,
  enum)` — that's the real injection point we need.
- Whether `floating.qmd`'s quick-tool slots or `gestureColourSettings`'s
  cycle expose a writable RGB field we could hijack from a different
  angle.
- Whether anyone else in the rmpp community has shipped a working colour
  extension on 3.26 we missed.

## Repo layout

```
freeColour.plugin/
├── MASTER.md                    # this file
├── SLAVE-QMLDIFF.md             # build asivery/qmldiff toolchain
├── SLAVE-WRITINGTOOL.md         # dump + read the live QML, find injection points
├── SLAVE-COMMUNITY.md           # search for prior art on 3.26
├── SLAVE-ALTPATH.md             # alternative injection points (floating, gestures, …)
├── README.md                    # user-facing overview
├── Makefile                     # install / restore against the device
├── src/freeColour.qmd           # current (broken) v0.1
├── reference/                   # upstream qmds, hashtab, hash decoder
└── (scratch experiments live in ../ferrari/scratch/, NOT in this repo)
```

## Slaves dispatched

| File | Owner role | Status |
|---|---|---|
| SLAVE-QMLDIFF.md | Toolchain build | DONE 2026-04-24 — qmldiff binary at `~/src/qmldiff/target/release/qmldiff`, `bin/compile-qmd.sh` wrapper, `reference/qmldiff-workflow.md`. Round-trip verified. |
| SLAVE-WRITINGTOOL.md | QML reverse-engineering | DONE 2026-04-24 — extracted `WritingTool.qml` (479 lines, at `../ferrari/scratch/qml-dump/files/`), diagnosed why upstream Timer no-ops (Repeater clobber), recommended REBUILD-binding-expression injection point. Findings turned out to match what ingatellent's `addColorSelector.qmd` already does. |
| SLAVE-COMMUNITY.md | Prior-art research | DONE 2026-04-24 — found ingatellent/xovi-qmd-extensions/3.26/addColorSelector.qmd: a working hex-ARGB picker UI, MIT, confirmed working on rMPP and Move per their issue #12. Their `3.26/changeGreenColor.qmd` is byte-identical to FouzR's (md5 225953e2…). |
| SLAVE-ALTPATH.md | Alternative mechanisms | DONE 2026-04-24 (with deferred verification) — `floating.qmd` quick-tool slots accept arbitrary `paletteEnum:9 + rgb` with no QML changes. Documented JSON schema; tap-and-draw confirmation deferred to v1.1. |

There is **no sibling coordination** between slaves. Each works from
its brief alone and writes results to its own `## Status` section. You
(master) synthesise across them.

## Conventions inherited from `ferrari/CLAUDE.md`

- Device IP: USB `10.11.99.1`, WLAN fallback `192.168.1.112` (ferrari).
  Porsche WLAN is `192.168.1.115`.
- SSH host-key warnings on the rMPPs are a known annoyance; commands
  prefix `-o StrictHostKeyChecking=no` and pipe-grep out the warning
  spam.
- Never run rmsync verbs that write with `--delete` against porsche
  unless `RMSYNC_DEVICE_GUARD=off` is set — wrong-device targeting nuked
  Kiyomi's library on 2026-04-22 and the hostname guard prevents
  repeats. (Not relevant to this project but inherit the discipline.)
- Don't commit large binaries to this repo. The 23 MB `xochitl-3.26.0.68`
  binary lives at `../ferrari/scratch/xochitl-3.26.0.68` and is
  referenced by path. Same for any QML resource dumps.
- Version-control as you go. Small commits with clear "what + why".

## Decision log

- **2026-04-24** — v0.1 cloned `changeGreenColor.qmd` substitution
  pattern. Confirmed cloning + install + restart + reload pipeline
  works end-to-end. Substitution itself is a no-op on this firmware
  (see Proven #7). Pivoted to slave-driven investigation.
- **2026-04-24** — Slaves returned. SLAVE-COMMUNITY's find collapses
  the problem: ingatellent's `addColorSelector.qmd` already ships a
  working hex-ARGB picker on 3.26. SLAVE-WRITINGTOOL independently
  arrived at the same injection-point shape (REBUILD on bindings, not
  property writes). v1.0 = vendor + ship ingatellent's two qmds with
  our Makefile + README + project history. Zero new qmd code.
  SLAVE-QMLDIFF's toolchain remains in tree for v1.1+ work. Awaiting
  user verification that "Pick custom color" UI appears in the pen
  menu after `make install`.

## v1.0 status (2026-04-24, after `make install`)

- `src/changeGreenColor.qmd` and `src/addColorSelector.qmd` deployed
  to device.
- Old broken `freeColour.qmd` removed from device.
- `changeGreenColor.qmd.bak` (FouzR's pre-3.26 file) preserved on
  device for `make restore`.
- Awaiting user confirmation: "Pick custom color" menu item visible
  on a pen → typing `8B4513` → drawing produces a brown stroke.

## v1.1 (planned)

- Pre-seed `quickTool.json` with a brown highlighter slot via a
  small qmd that runs an XHR PUT on first load (per SLAVE-ALTPATH's
  recommendation). One-tap brown without typing the hex.
- Re-test "any pen can be a shader" claim on solid pens; if true,
  invalidates Proven #2 and unlocks free-form RGB on every pen.
- Decide whether to switch authoring of any future qmds (e.g. a HSV
  wheel popup) to plain-name source via `bin/compile-qmd.sh`. Today
  v1.0 is vendored straight from upstream so authoring isn't yet on
  the critical path.
