# SLAVE-QMLDIFF — build the qmldiff Rust toolchain locally

You are a delegated Claude instance. The parent ("MASTER") session at
`~/Documents/remarkable/freeColour.plugin/MASTER.md` handed you this
task. No sibling coordination; all updates surface here under
`## Status`. Read MASTER.md end-to-end first for project context.

## Your task

Build [`asivery/qmldiff`](https://github.com/asivery/qmldiff) (Rust
CLI) locally, verify it works against the on-device hashtab, and
document a complete authoring workflow for the rest of the project.

The current freeColour.qmd is hand-edited from the obfuscated
upstream — every identifier is a `[[hash]]` or `~&hash&~` literal.
That's fine for cloning a 60-line example but unworkable for the v1
extension which needs new identifier hashes (for QML elements the
upstream extension never touched). Without `qmldiff`, we'd be
hashing 64-bit integers by hand. Don't.

## Working directory

```
~/Documents/remarkable/freeColour.plugin/
```

This is a normal git repo. Clone qmldiff somewhere outside the repo
(e.g. `~/src/qmldiff/`); commit only the resulting binary path or
build instructions to this repo.

Launch:

```bash
cd ~/Documents/remarkable/freeColour.plugin && claude \
  --add-dir ~/Documents/remarkable/ferrari \
  --permission-mode acceptEdits --name qmldiff
```

## What to produce

1. **A working `qmldiff` binary on PATH** (or an alias / wrapper
   script). Document the install path and version commit hash.
2. **A demonstration that `qmldiff` round-trips against the device's
   hashtab.** Specifically:
   - Take the hashtab at `reference/hashtab` (binary form, BE u64
     hash + BE u32 name-length + name bytes — see decoder in
     `reference/decode_hashes.py`).
   - Decompile `reference/changeGreenColor.qmd` from its hashed form
     into a plain-name `.qml-diff` source. Save it next to the
     original as `reference/changeGreenColor.qml-diff`.
   - Re-compile that plain source back into a .qmd using the
     hashtab. Confirm the output is byte-equivalent (or at least
     semantically equivalent) to the original.
3. **A wrapper script `bin/compile-qmd.sh`** that takes a
   plain-name `src/foo.qml-diff` source and emits
   `build/foo.qmd` against `reference/hashtab`. Document inputs /
   outputs at the top.
4. **A short `reference/qmldiff-workflow.md`** explaining the full
   author → compile → install loop for future slaves and master:
   - Where qmldiff lives
   - How to extend the hashtab when xochitl's QML uses a name not in
     the existing dictionary (see asivery's docs — the tool can scan
     QML source directories to compute new hashes)
   - How to dump the live WritingTool.qml from the device so we can
     read its actual structure (this is the prerequisite for
     SLAVE-WRITINGTOOL's work — but you don't need to do that
     dumping yourself; just document the command). The `qt-resource-rebuilder`
     extension may itself have a debug-dump mode; check its README.

## Reference

- [asivery/qmldiff](https://github.com/asivery/qmldiff) — the Rust source.
- [asivery/rm-xovi-extensions/qt-resource-rebuilder](https://github.com/asivery/rm-xovi-extensions/tree/master/qt-resource-rebuilder)
   — the on-device runtime that consumes .qmd files.
- `reference/hashtab` — pulled from the device on 2026-04-24, locked
  to firmware 3.26.0.68.
- `reference/changeGreenColor.qmd` — the canonical small example
  (60 lines). Decompiling this is the easiest unit test.
- `reference/decode_hashes.py` — already parses the hashtab format
  in Python; cross-check qmldiff's output against this.

## Constraints

- Don't commit the qmldiff binary itself or any build artifacts to
  this repo (size + portability). Document install paths instead.
- `cargo install` is fine; vendoring isn't necessary.
- macOS host (laptop). The qmldiff CLI runs locally; we don't
  cross-compile it for the device. Output `.qmd` files travel to the
  device unchanged.

## Status

OPEN — not started yet.

(When you're done, append a "DONE — <date>" header and a short
summary of what you produced + any gotchas under it. Master will
read this on next invocation.)
