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

DONE — 2026-04-24

### What's in place

- **qmldiff binary built locally.** Source at `~/src/qmldiff`, built with stock rustup (`cargo 1.94.1`, `rustc 1.94.1`, target `aarch64-apple-darwin`). Upstream commit `533d2b9ceac41d2952d92090eed37298cd627440` (tip of `master` on 2026-04-24). Binary at `~/src/qmldiff/target/release/qmldiff`. Not committed to this repo — rebuild with `cd ~/src/qmldiff && cargo build --release --bin qmldiff`.
- **Round-trip verified against `reference/hashtab`.** Decompiled `reference/changeGreenColor.qmd` with `qmldiff hash-diffs -r` → saved as `reference/changeGreenColor.qml-diff` (plain-name source). Recompiled via the wrapper → byte-identical to the original `.qmd` (`diff` returns 0, both 62 lines).
- **`bin/compile-qmd.sh`** — wrapper that takes `src/foo.qml-diff` and emits `build/foo.qmd` against `reference/hashtab`. Resolves the qmldiff binary via `$QMLDIFF` env, then `~/src/qmldiff/target/release/qmldiff`, then `$PATH`. Input/output contract documented at the top of the script.
- **`reference/qmldiff-workflow.md`** — full author→compile→install loop, how to extend the hashtab, and a realistic survey of what it would take to dump live QML off the device (there is no built-in debug-dump mode in qt-resource-rebuilder; cheapest honest path is a ~30-line patch to `qt-resource-rebuilder/src/main.c` to fwrite each processed file before calling `qmldiff_process_file`).
- **`build/`** ignored via `.gitignore` (compiled artefacts shouldn't land in source control; they depend on local hashtab + qmldiff versions).

### Gotchas for the next slave / master to know

- `qmldiff hash-diffs` **mutates its input file in place**. The wrapper copies the plain source into `build/` before hashing, so don't bypass it and run `qmldiff hash-diffs` against something under `src/` or `reference/` directly — you will lose your plain source.
- qmldiff's `Cargo.toml` only declares `crate-type = ["staticlib"]` (no `[[bin]]`), but `src/main.rs` is a real CLI. `cargo build` builds it anyway; use `--bin qmldiff` to be explicit.
- The hashtab at `reference/hashtab` holds 20 017 total entries, only 1 353 of which reverse-resolve to plain names (see `qmldiff dump-hashtab | wc -l`). `hash-diffs` leaves identifiers not present in the hashtab unhashed — if a diff compiles but contains plain names xochitl can't resolve, the runtime match will silently fail. When writing v1, sanity-check every new identifier with `qmldiff hash-string X` + `grep` against the dump before relying on it.
- File-extension convention I've adopted: `.qml-diff` for plain-name sources, `.qmd` for hashed device-ready artefacts. Upstream uses `.qmd` for both, which is confusing. `compile-qmd.sh` tolerates either suffix on the input but always emits `.qmd` in `build/`.
- Filenames ending in `.qml` are themselves identifiers in the hashtab (e.g. `WritingTool.qml = 14050541169674265603`), so `hash-diffs` will correctly hash `AFFECT /qt/qml/.../WritingTool.qml` paths — no special handling required.

### What's NOT done (deliberately, per the brief)

- No live-device QML dump. The README of `qt-resource-rebuilder` has no debug-dump flag; the approaches for getting actual `WritingTool.qml` contents off the tablet are documented in `reference/qmldiff-workflow.md` §"Dumping live QML from the device" for SLAVE-WRITINGTOOL to pick one.
- Makefile wiring to the new flow. `Makefile`'s `EXT` still points at `src/freeColour.qmd`. When v1 is authored as `src/freeColour.qml-diff`, either update `EXT` to `build/freeColour.qmd` + add a compile rule, or keep `src/freeColour.qmd` as the canonical committed output and call the wrapper as a pre-commit step. Master decides.
