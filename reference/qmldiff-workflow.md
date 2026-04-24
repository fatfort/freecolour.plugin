# qmldiff workflow

How to author, compile, and install `.qmd` files for this project without
hashing integers by hand.

## Toolchain

- **qmldiff binary** (`asivery/qmldiff` Rust CLI):
    - Source: `~/src/qmldiff` (clone of https://github.com/asivery/qmldiff.git)
    - Build commit: `533d2b9ceac41d2952d92090eed37298cd627440` (tip of `master`, fetched 2026-04-24)
    - Release binary: `~/src/qmldiff/target/release/qmldiff`
    - Rebuild with: `cd ~/src/qmldiff && cargo build --release --bin qmldiff`
- **Host toolchain:** rustup default toolchain (`stable-aarch64-apple-darwin`, cargo 1.94.1). No new deps; everything comes from crates.io.
- **Device runtime:** `qt-resource-rebuilder` extension (source: `~/src/rm-xovi-extensions/qt-resource-rebuilder`) is what consumes the `.qmd` on the tablet. We don't build or modify it here.

Nothing above is committed to this repo. The binary is a build artefact; rebuild when qmldiff's upstream changes.

## Hashtab

- `reference/hashtab` — pulled from `/home/root/xovi/exthome/qt-resource-rebuilder/hashtab` on the device on 2026-04-24, firmware 3.26.0.68. 20 017 hashes total, 1 353 of them reverse-resolvable to plain names.
- Binary format: 8-byte BE zero, 4-byte BE magic length + magic string, then repeated `(8-byte BE hash, 4-byte BE name length, UTF-8 name bytes)`. Cross-checked against `reference/decode_hashes.py`.
- Inspect with: `qmldiff dump-hashtab reference/hashtab`
- Hash a single identifier without touching the hashtab: `qmldiff hash-string someIdentifier` (useful for sanity-checking that a name you're about to use is actually in the hashtab — grep the dump for it).

## Author → compile → install loop

1. **Write plain-name source** in `src/foo.qml-diff`. Use real QML identifiers: `WritingTool.qml`, `root.pen.toolColor`, `colorComponent`, etc. See `reference/changeGreenColor.qml-diff` for a complete, working example that decompiles the upstream `changeGreenColor.qmd`.

2. **Compile** to a hashed `.qmd`:

    ```
    bin/compile-qmd.sh src/foo.qml-diff      # writes build/foo.qmd
    ```

    The wrapper copies the source into `build/` and runs `qmldiff hash-diffs reference/hashtab build/foo.qmd`. Every unhashed identifier is rewritten in place to `[[u64]]` / `~&u64&~`. Anything not present in the hashtab is left unhashed — look out for that; qt-resource-rebuilder won't match it on the device.

3. **Install** on the device:

    ```
    make reinstall EXT=build/foo.qmd    # or set EXT to the new file path
    ```

    The current `Makefile` has `EXT = src/freeColour.qmd` hard-coded. When switching to the new workflow, either point `src/freeColour.qmd` at the compiled output, or update `Makefile`'s `EXT` to `build/freeColour.qmd` and have the Makefile depend on `bin/compile-qmd.sh`.

### Round-trip sanity check

Decompilation is the inverse: `qmldiff hash-diffs -r reference/hashtab <file>`. This is how `reference/changeGreenColor.qml-diff` was produced — then recompiled and confirmed byte-identical to the original `reference/changeGreenColor.qmd`. If you're ever unsure whether an edit survived hashing, decompile and diff.

## Adding identifiers that aren't in the current hashtab

The existing hashtab already covers the 1 353 named identifiers visible from xochitl's shipped QML at hashtab-build time. Three cases for new names:

1. **The name is a plain string or numeric literal** — qmldiff's hasher skips string literals and numbers. Leave it as-is; no hashing needed.

2. **The name is a new QML identifier we invent ourselves** (new property, new id, new function name we're about to INSERT): it will go into xochitl's parsed QML *after* our diff is applied, so it doesn't need to be pre-hashed. Leave it plain. qmldiff emits it unchanged when it doesn't find a match in the hashtab, which is what we want.

3. **The name is an xochitl identifier that `dump-hashtab` doesn't show** — either the hashtab rules didn't cover it, or xochitl's QML actually doesn't contain that name on this firmware. Check both:
   - `qmldiff hash-string theName` gives you the hash. Grep the hashtab binary for those 8 bytes (BE u64) to confirm it genuinely isn't there.
   - If it's missing, you need to rebuild the hashtab *on the device* against the live xochitl. Use `/home/root/xovi/rebuild_hashtable` (from asivery's xovi-setup). It stops xochitl, re-runs it under `LD_PRELOAD=xovi.so` with `QMLDIFF_HASHTAB_CREATE=/home/root/xovi/exthome/qt-resource-rebuilder/hashtab`, waits for the `Hashtab saved to ...` log line, and kills xochitl. Copy the new hashtab back into `reference/hashtab` and commit.
   - Locally, `qmldiff create-hashtab <QML root>` does the same thing from QML source on disk — but we don't have xochitl's QML on disk (it's baked into the xochitl binary via `qRegisterResourceData`), so this path only helps if you've already extracted the QML (see below).

## Dumping live QML from the device

Prerequisite for SLAVE-WRITINGTOOL: we want to read the *actual* `WritingTool.qml` shipped in xochitl 3.26.0.68 so we can figure out where to inject. Options, cheapest first:

1. **Enumerate filenames, not contents.** qt-resource-rebuilder's `qmldiff_process_file` path already logs `[qmldiff]: Processing file <name>...` to stderr for every QML file it touches. Running xochitl under `journalctl -u xochitl -f` (or `LD_PRELOAD=xovi.so xochitl 2>&1` interactively) lists every QML path xochitl loads. Good for finding the right AFFECT target; doesn't give you file contents.

2. **Hash derivations.** `rebuild_hashtable` prints `[qmldiff] [Hashtab Rule Processor]: Hashed derived '<identifier>'` for every identifier it encounters while parsing each QML file. Capture that stream and you've got a list of every identifier that exists in the live QML, grouped by the file being parsed at the time. Often enough to plan an injection without a full dump.

3. **Full content dump.** qt-resource-rebuilder has *no* built-in debug-dump mode (checked README + source — `main.c`'s `processNode` passes buffers through and frees them; nothing writes them to disk). Real options:
   - Patch `qt-resource-rebuilder/src/main.c` locally so that right before calling `qmldiff_process_file`, it `fwrite()`s `temporary` to `$XOVI_EXTHOME/exthome/qt-resource-rebuilder/qml-dump/<filename>`. Rebuild the `.so`, deploy to the device, restart xochitl, read the dump, revert. ~30 lines of C.
   - Write a standalone XOVI extension that only hooks `qRegisterResourceData` and walks the resource tree to disk. Bigger lift; only worth it if we want this as a permanent tool.
   - The `xochitl-3.26.0.68` binary at `../ferrari/scratch/xochitl-3.26.0.68` contains the QRC data inline. In principle you can extract it offline by finding the `qRegisterResourceData` call sites and reading the embedded trees, but that's a reverse-engineering project on its own.

   Recommended for SLAVE-WRITINGTOOL: option (a), the one-off patch. Keep the patched binary out of the repo; document the diff in that slave's own `## Status`.

## Gotchas hit while setting this up

- `qmldiff hash-diffs` **rewrites its input in place.** `bin/compile-qmd.sh` copies the source to `build/` first so the plain-name file survives. Don't point it at the source directly.
- `Cargo.toml` declares `crate-type = ["staticlib"]` and no `[[bin]]` stanza, but `src/main.rs` is a real CLI entry point. Plain `cargo build` builds the CLI anyway as the default bin for a package with `src/main.rs`; `cargo build --release --bin qmldiff` is explicit and safer.
- Naming: upstream calls their sources `.qmd` (hashed) and also `.qmd` (plain). This repo uses `.qml-diff` for the plain-name source and `.qmd` only for the hashed, device-ready artefact. Less ambiguous.
