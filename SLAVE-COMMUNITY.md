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

OPEN — not started yet.
