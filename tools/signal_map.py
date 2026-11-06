#!/usr/bin/env python3
"""Who declares / emits / connects each signal (scripts + `[connection]` entries in .tscn). Cheap way to trace signals.

  python tools/signal_map.py                  # all signals, one line each
  python tools/signal_map.py --find health    # signals whose name contains 'health'
  python tools/signal_map.py --orphans        # declared but never emitted, or emitted but never connected
Matching is by signal NAME (heuristic): two classes with the same signal name share one row.
"""
from __future__ import annotations

import argparse
import re
import sys

from _common import ROOT, iter_files, parse_tscn, read_text, setup_stdout

DECL = re.compile(r"^signal\s+(\w+)", re.M)
EMIT = re.compile(r"\b(\w+)\.emit\(")
CONN = re.compile(r"\b(\w+)\.connect\(")


def main() -> int:
    setup_stdout()
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--find", default="")
    ap.add_argument("--orphans", action="store_true")
    a = ap.parse_args()
    sig: dict = {}

    def row(name):
        return sig.setdefault(name, {"decl": set(), "emit": set(), "code": set(), "scene": set()})

    for p in iter_files(exts={".gd"}):
        if p.startswith("tests/"):
            continue
        text = read_text(ROOT / p)
        for m in DECL.finditer(text):
            row(m.group(1))["decl"].add(p)
        for m in EMIT.finditer(text):
            row(m.group(1))["emit"].add(p)
        for m in CONN.finditer(text):
            row(m.group(1))["code"].add(p)
    for p in iter_files(exts={".tscn"}):
        for c in parse_tscn(read_text(ROOT / p))["conns"]:
            row(c["signal"])["scene"].add(f"{p}: {c['from']} -> {c['to']}.{c['method']}")

    builtin = {k for k, v in sig.items() if not v["decl"]}
    names = sorted(sig)
    if a.find:
        names = [n for n in names if a.find.lower() in n.lower()]
    shown = 0
    for n in names:
        v = sig[n]
        if a.orphans:
            custom = bool(v["decl"])
            if not custom or (v["emit"] and (v["code"] or v["scene"])):
                continue
            issue = "never emitted" if not v["emit"] else "emitted but nobody connects"
            print(f"{n}: {issue} (declared in {', '.join(sorted(v['decl']))})")
            shown += 1
            continue
        if n in builtin and not a.find:
            continue
        print(f"{n}")
        if v["decl"]:
            print("  declared: " + ", ".join(sorted(v["decl"])))
        if v["emit"]:
            print("  emitted : " + ", ".join(sorted(v["emit"])))
        if v["code"]:
            print("  code-connected in: " + ", ".join(sorted(v["code"])))
        for s in sorted(v["scene"]):
            print("  scene-connected : " + s)
        shown += 1
    print(f"signal_map: {shown} signals listed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
