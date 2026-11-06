#!/usr/bin/env python3
"""Compact index of GDScript classes so you do NOT have to open every script.

  python tools/script_index.py                      # outline of every script
  python tools/script_index.py --classes            # class_name -> path (one line each)
  python tools/script_index.py --find health        # scripts whose class/signal/export/func matches
  python tools/script_index.py --file scripts/objects/world/Actor.gd
  python tools/script_index.py --class Actor --private
"""
from __future__ import annotations

import argparse
import sys

from _common import ROOT, class_index, format_outline, iter_files, norm, parse_gd, read_text, setup_stdout


def main() -> int:
    setup_stdout()
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--classes", action="store_true")
    ap.add_argument("--find", default="")
    ap.add_argument("--file", default="")
    ap.add_argument("--class", dest="cls", default="")
    ap.add_argument("--private", action="store_true", help="include _private funcs")
    ap.add_argument("--folder", default="", help="limit to a sub folder")
    a = ap.parse_args()

    if a.classes:
        for name, path in sorted(class_index().items()):
            print(f"{name} -> {path}")
        return 0
    if a.file:
        print(format_outline(norm(a.file), a.private))
        return 0
    if a.cls:
        idx = class_index()
        if a.cls not in idx:
            print(f"class '{a.cls}' not found")
            return 1
        print(format_outline(idx[a.cls], a.private))
        return 0
    needle = a.find.lower()
    for p in iter_files(norm(a.folder).rstrip("/"), exts={".gd"}):
        if needle:
            g = parse_gd(read_text(ROOT / p))
            hay = " ".join([g["class_name"], g["extends"], *g["signals"], *(e[0] for e in g["exports"]),
                            *(f["name"] for f in g["funcs"]), p]).lower()
            if needle not in hay:
                continue
        print(format_outline(p, a.private))
    return 0


if __name__ == "__main__":
    sys.exit(main())
