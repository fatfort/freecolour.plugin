#!/usr/bin/env python3
"""
Parse the qt-resource-rebuilder hashtab and translate the hashes that appear
in changeGreenColor.qmd back into their original QML identifier names.

Hashtab format (asivery/qmldiff/src/hashtab.rs):
    [u64 = 0]                # leading zero
    [u32 = magic_len][magic] # "Hashtab file for QMLDIFF. Do not edit."
    repeated:
        [u64 hash][u32 name_len][name bytes]
"""
import re
import struct
import sys
from pathlib import Path

HERE = Path(__file__).parent
TAB = HERE / "hashtab"
QMD = HERE / "changeGreenColor.qmd"

def parse_hashtab(data: bytes) -> dict[int, str]:
    table = {}
    # leading zero hash + magic
    assert struct.unpack(">Q", data[:8])[0] == 0
    magic_len = struct.unpack(">I", data[8:12])[0]
    pos = 12 + magic_len
    while pos < len(data):
        if pos + 12 > len(data):
            break
        h = struct.unpack(">Q", data[pos:pos+8])[0]
        n = struct.unpack(">I", data[pos+8:pos+12])[0]
        pos += 12
        name = data[pos:pos+n].decode("utf-8", errors="replace")
        pos += n
        table[h] = name
    return table


def main():
    table = parse_hashtab(TAB.read_bytes())
    print(f"Parsed {len(table)} entries", file=sys.stderr)

    qmd = QMD.read_text()
    # Extract every [[N]] and ~&N&~ token; print the lookup
    seen = set()
    for tok in re.finditer(r"(?:\[\[|~&)(\d+)(?:\]\]|&~)", qmd):
        h = int(tok.group(1))
        if h in seen:
            continue
        seen.add(h)
        name = table.get(h, "<UNKNOWN>")
        print(f"  {h:>22}  {name}")

if __name__ == "__main__":
    main()
