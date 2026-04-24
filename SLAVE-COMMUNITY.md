# SLAVE-COMMUNITY — prior-art and community status on 3.26 colour hacks

You are a delegated Claude instance. The parent ("MASTER") session at
`~/Documents/remarkable/freeColour.plugin/MASTER.md` handed you this
task. No sibling coordination. Read MASTER.md end-to-end first.

## Your task

Pure research. Find any community work that would either:

- **Save us time**: a working alternative to `changeGreenColor.qmd` on
  3.26.0.68 — different fork, different mechanism, anything.
- **Save us effort**: a documented diagnosis of why `changeGreenColor`
  doesn't apply on 3.26 (someone else hit the same wall and figured
  out what changed in xochitl).
- **Open a new path**: any colour-related rmpp extension on
  GitHub / forums / Discord / Reddit / Hacker News that touches the
  highlighter or shader colour palette in a way the FouzR repo doesn't.

## Working directory

```
~/Documents/remarkable/freeColour.plugin/
```

You don't need to write any code. Output goes in this file's
`## Status` section as a written report.

Launch:

```bash
cd ~/Documents/remarkable/freeColour.plugin && claude \
  --permission-mode acceptEdits --name community
```

## Where to look

**GitHub repos to scan:**

- [`asivery/rm-xovi-extensions`](https://github.com/asivery/rm-xovi-extensions) —
  upstream of qt-resource-rebuilder. Check Issues, PRs, Discussions.
- [`asivery/qmldiff`](https://github.com/asivery/qmldiff) — same.
- [`FouzR/xovi-extensions`](https://github.com/FouzR/xovi-extensions) —
  publisher of `changeGreenColor.qmd`. Check Issues for "doesn't work",
  "3.26", "no effect", "color".
- [`ingatellent/xovi-qmd-extensions`](https://github.com/ingatellent/xovi-qmd-extensions) —
  fork of FouzR. Check for divergent changes.
- [`Samarkin/rm-hacks-xovi-qmd`](https://github.com/Samarkin/rm-hacks-xovi-qmd) — another
  qmd-extensions collection.
- [`PepikVaio/reMarkable_Xovi_Extensions`](https://github.com/PepikVaio/reMarkable_Xovi_Extensions).
- [`reHackable/awesome-reMarkable`](https://github.com/rehackable/awesome-remarkable) —
  curated index, scan for anything we missed.

**Search queries to run:**

- "changeGreenColor doesn't work" / "3.26" / "rmpp"
- "xochitl colorComponent" / "WritingTool.qml" / "penColorSelected"
- "remarkable paper pro custom color" / "highlighter color"
- "xovi color extension"

**Other surfaces:**

- The reMarkable subreddit and Discord — but be conservative,
  signal-to-noise can be low. Only flag if you find something
  load-bearing.
- The Nilorea Studio post linked from `ferrari/CLAUDE.md`'s research
  trail (rmhacks 2025-08).

## What we already know (don't re-derive)

- Upstream `changeGreenColor.qmd` exists and claims to work but is a
  no-op on 3.26.0.68 ferrari + porsche.
- `floating.qmd`, `gestureColourSettings.qmd`, `toolbar_icon.qmd`
  exist and live on the user's device today; if you read them, focus
  on the parts touching colour state — gestureColourSettings cycles
  between predefined colours, doesn't expose RGB picking.
- The user (aayush) has personally written
  `koreader-plugins/colorpicker.koplugin/main.lua` — a custom
  highlight colour wheel for KOReader. That's the KOReader side of
  this same problem; we want the equivalent for native xochitl.
  Don't redocument it; just note that the goal is parity.

## What to produce

A report in this file's `## Status` section, with three sections:

1. **Working alternatives found** (if any) — links + 1-line summary
   each. If there's a working extension, this collapses the rest of
   the project to "install + adapt".
2. **Why-changeGreenColor-broke leads** — any commit, issue, or
   discussion that diagnoses the regression.
3. **Adjacent work worth knowing** — anything that doesn't directly
   solve the problem but might help (e.g. someone documented xochitl's
   QML structure, someone built a different colour mechanism for
   stylus pressure curves, etc.).

If a section has nothing, write "Nothing found." rather than padding.

## Constraints

- Don't make any device or repo changes. Pure research.
- Time-box yourself: ~1 hour of research is enough. Diminishing
  returns after that — better to surface the partial findings than
  to keep grinding.
- Cite sources with URLs. Master will follow them.

## Status

DONE — 2026-04-24. Bottom line: **a working free-RGB colour-picker
extension for 3.26 on rMPP + rMPP Move already exists** in
`ingatellent/xovi-qmd-extensions`. This collapses v1 from "reverse-
engineer the QML and build from scratch" to "install/adapt ingatellent's
files, reconcile with our brown-colour goal, and ship." MASTER should
re-brief SLAVE-WRITINGTOOL to study ingatellent's qmd rather than dump
xochitl from zero.

### 1. Working alternatives found

**`ingatellent/xovi-qmd-extensions` — the 3.26 rewrite of changeGreenColor + a new colour-picker UI.**

- [3.26/addColorSelector.qmd](https://github.com/ingatellent/xovi-qmd-extensions/blob/main/3.26/addColorSelector.qmd)
  — adds a "Pick custom color" menu item with a text field that takes
  a hex ARGB value (e.g. `FF338833`) and a colour-swatch preview. On
  accept, calls the xochitl internal `penColorSelected(rgbValue, ARGB)`
  signal — the same injection point MASTER.md flagged as unknown. First
  committed 2026-04-04, "Change any pen to any color (using hex ARGB
  value)".
- [3.26/changeGreenColor.qmd](https://github.com/ingatellent/xovi-qmd-extensions/blob/main/3.26/changeGreenColor.qmd)
  — **prerequisite** for the picker (per the author's comment in
  issue #12: "Must be installed with changeGreenColor.qmd for the
  color assignment not to be overruled"). First committed 2026-03-18,
  corrected 2026-03-19 with "Using correct hashtab for 3.26".
- Structurally different from FouzR's v1 — uses a `SLOT` /
  `TEMPLATE` macro (the `changeColorDefinitionsSlot` /
  `changeColorDefinitionsTemplate` pair), a `REPLACE`
  on function `[[4129553690040935969]]` (the colour-select handler),
  and two `REBUILD` inserts on `[[254524038664609014]]` and
  `[[475535838851480711]]`. Our v0.1 clone of FouzR's file uses the
  pre-3.26 Timer-substitution pattern which no longer matches the
  current QML.
- Confirmed working by author + one other tester ("knox-dawson") on
  both rMPP and rMPP Move, with screenshots, in
  [issue #12 "Any color, any pen"](https://github.com/ingatellent/xovi-qmd-extensions/issues/12).
  Quote: "It work as expected. I'm amazed. […] So any pen can be a
  shader" (on passing a non-opaque alpha through ARGB).

**`ingatellent/xovi-qmd-extensions/3.26/enableAllColors.qmd`** is NOT
what we want — it's a 4-line patch that unhides the rMPP palette on
greyscale rM1/rM2, not a new-colour mechanism on rMPP.

### 2. Why-changeGreenColor-broke leads

No single bug ticket nails it, but the *diff* between the top-level
`changeGreenColor.qmd` (what FouzR ships, what we cloned) and
`3.26/changeGreenColor.qmd` is the diagnosis:

- In 3.26 the colour-select logic was refactored into function hash
  `[[4129553690040935969]]`. The old Timer-based approach writes to
  properties that colorModel rebinds on the next tick; the 3.26
  rewrite instead **replaces the function itself** and adds a one-shot
  init `Timer` on hash `[[7060683329257607547]]` that seeds the
  swatch with the ARGB override.
- The 3.26 file also rebuilds two expression hashes
  (`[[254524038664609014]]`, `[[475535838851480711]]`) so that when
  `PenColor === 9` (ARGB) the swatch renders the hex colour instead
  of falling through to the default enum-indexed colour.
- FouzR's upstream ships only the pre-3.26 file; no update. FouzR
  acknowledged the ask in [FouzR/xovi-extensions#47 "Any color"](https://github.com/FouzR/xovi-extensions/issues/47)
  (closed 2026-04-09) and said: *"Cool, but I'm not so sure if I want
  to go for a colour wheel any time soon"* — pointing users instead
  to ingatellent's fork. So FouzR's version isn't broken on purpose,
  it's just unmaintained for the 3.26 QML shape.
- `asivery/rm-xovi-extensions` [release v17-14012026](https://github.com/asivery/rm-xovi-extensions/releases/tag/v17-14012026)
  is the qt-resource-rebuilder build referenced by multiple 3.26
  troubleshooting threads (e.g. FouzR #43) — worth confirming the
  device has ≥ v17 before blaming the .qmd.

### 3. Adjacent work worth knowing

- **[FouzR/rm-hacks-qmd](https://github.com/FouzR/rm-hacks-qmd)** — a
  separate extension collection (continuation of
  [mb1986/rm-hacks](https://github.com/mb1986/rm-hacks) in qmldiff
  form). Currently at 0.0.11-pre4. Does NOT ship a colour picker.
  Relevant only as a second worked example of the SLOT/TEMPLATE
  pattern if we need reference code.
- **`vellum-dev/vellum`** has a `packages/change-green-color`
  VELBUILD — it's just a packaging recipe wrapping FouzR's file, not
  a different mechanism.
- **`rehackable/awesome-reMarkable`** index lists ingatellent's repo
  but only enumerates `delayStrokeRefresh` / `enableAllColors` —
  `addColorSelector` hasn't been added to the index yet (it's only
  3 weeks old). Confirms no other fork is doing colour work.
- **`Samarkin/rm-hacks-xovi-qmd`** stops at 3.25, no colour files.
- **`PepikVaio/reMarkable_Xovi_Extensions`** has no colour extensions.
- **Nilorea Studio 2025-08-11 post** ([link](https://www.nilorea.net/2025/08/11/latest-rmhacks-with-xovi-for-remarkable-1-2-paper-pro/))
  is an install walkthrough for rmHacks + xovi, no colour content.
- ingatellent's author in issue #12 notes the long-press-grey UI idea
  ("Long press the gray color, to reveal four sliders") as a future
  direction — we could borrow this if we want in-tool colour editing
  rather than the hex-typing UX they shipped.
- One side-effect worth knowing per knox-dawson's test: "any pen can
  be a shader" — passing non-opaque alpha via ARGB (enum 9) makes
  solid-pen tools honour transparency, which conflicts with
  MASTER.md's proven #2 ("solid pens ignore color_rgba"). Possible
  reconciliation: once the pen is re-tagged as ARGB via the new
  function path, the rasterizer reads RGBA even on ballpoint. Worth
  re-testing on device after we install ingatellent's files.

### Recommended next step for MASTER

1. Re-brief SLAVE-WRITINGTOOL to read ingatellent's two 3.26 .qmds
   line-by-line (hashes + structure) rather than dumping xochitl from
   scratch. The injection points are handed to us.
2. `make reinstall` swapping our `src/freeColour.qmd` for
   `ingatellent/3.26/changeGreenColor.qmd` + `3.26/addColorSelector.qmd`
   (MIT licensed per their LICENSE.md — attribution carries over).
   Verify the picker UI shows up, pick `0xFF8B4513` (brown), draw a
   stroke, sync, decode with rmscene, confirm `color_rgba` is set and
   renders brown.
3. If step 2 works, v1 of freeColour.qmd = ingatellent's files
   possibly stripped to a single-preset brown-only variant (no UI)
   for the coloring-in use case, with full-picker kept as a bonus.
4. Close SLAVE-QMLDIFF as no-longer-blocking (we still benefit from
   the toolchain for future patches, but not load-bearing for v1).
