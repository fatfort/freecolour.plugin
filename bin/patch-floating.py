#!/usr/bin/env python3
# Read reference/floating.qmd, swap the QuickToolsToggle's contentItem
# ColumnLayout for a RowLayout (so the four quick-action buttons sit in
# one row of 4 instead of stacked 4 deep), and write build/floating.qmd.
#
# Single-token swap only: no new properties. An earlier attempt used
# GridLayout columns: 2 and inserted a `columns: 2` property line; that
# evidently broke something Foldout / PenTool relies on and made the pen
# selectors disappear from the toolbar sidebar on Ferrari. Keeping this
# patch to one token (the type itself) minimises the risk of a parse
# cascade.
#
# Trade-off: at the existing width: 420 a 4-wide row gives ~105 px per
# FoldoutItem, which may clip labels like "Reset FloatBar". If labels
# clip, fall back to the (currently broken) GridLayout approach with
# wrapping inside an extra RowLayout child of the ColumnLayout.
#
# Hashes (from reference/hashtab, locked to firmware 3.26.0.68):
#   contentItem  = 477062473974076915
#   ColumnLayout = 14125623155555875541
#   RowLayout    = 254501558939456351

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "reference" / "floating.qmd"
OUT = ROOT / "build" / "floating.qmd"

OLD_LINE = "\t\t~&477062473974076915&~: ~&14125623155555875541&~ {"
NEW_LINE = "\t\t~&477062473974076915&~: ~&254501558939456351&~ {"

text = SRC.read_text()
if OLD_LINE not in text:
    sys.exit(f"error: anchor line not found in {SRC}; vendored copy may have drifted")
if text.count(OLD_LINE) != 1:
    sys.exit(f"error: anchor line matches {text.count(OLD_LINE)} times; expected exactly 1")

patched = text.replace(OLD_LINE, NEW_LINE, 1)
OUT.parent.mkdir(parents=True, exist_ok=True)
OUT.write_text(patched)
print(f"patched: {SRC} -> {OUT}")
