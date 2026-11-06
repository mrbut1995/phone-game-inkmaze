#!/usr/bin/env python3
"""Compact view of a check log: deduplicated errors with the offending source lines (instead of reading raw logs).

  python tools/logs.py tests              # tools/.logs/tests.log
  python tools/logs.py load --context 3 --max 8
Understands Godot `SCRIPT ERROR` / `Parse Error` / `ERROR:` blocks that mention `res://path.gd:LINE`, and `[FAIL]` test blocks.
"""
from __future__ import annotations

import argparse
import re
import sys

from _common import ROOT, norm, read_text, setup_stdout

LOCATION = re.compile(r"(res://[^\s:()]+\.(?:gd|tscn|tres)):(\d+)")
ERRLINE = re.compile(r"^(SCRIPT ERROR|ERROR|WARNING):|Parse Error|Invalid|Cannot|Identifier|not declared|Node not found", re.I)


def snippet(path: str, line: int, ctx: int):
    f = ROOT / norm(path)
    if not f.exists():
        return []
    lines = read_text(f).splitlines()
    lo, hi = max(1, line - ctx), min(len(lines), line + ctx)
    return [f"    {'>' if n == line else ' '} {n:4d} | {lines[n - 1].rstrip()[:110]}" for n in range(lo, hi + 1)]


def main() -> int:
    setup_stdout()
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("step", help="lint | scenes | exports | plan | import | load | tests")
    ap.add_argument("--context", type=int, default=2)
    ap.add_argument("--max", type=int, default=10)
    a = ap.parse_args()
    log = ROOT / "tools" / ".logs" / f"{a.step}.log"
    if not log.exists():
        print(f"no log for '{a.step}' (run python tools/run_checks.py first)")
        return 1
    lines = read_text(log).splitlines()
    out, seen, i = [], set(), 0
    while i < len(lines):
        line = lines[i]
        if line.startswith("[FAIL]"):
            block = [line]
            j = i + 1
            while j < len(lines) and lines[j].startswith("       "):
                block.append(lines[j])
                j += 1
            key = "\n".join(block)
            if key not in seen:
                seen.add(key)
                out.append("\n".join(block))
            i = j
            continue
        if ERRLINE.search(line):
            block = [line]
            j = i + 1
            while j < len(lines) and (lines[j].startswith(("   ", "\t")) or lines[j].strip().startswith("at:")):
                block.append(lines[j])
                j += 1
            key = re.sub(r"\d+", "#", block[0])
            if key not in seen:
                seen.add(key)
                text = "\n".join(l[:200] for l in block[:4])
                m = LOCATION.search("\n".join(block))
                if m:
                    text += "\n" + "\n".join(snippet(m.group(1), int(m.group(2)), a.context))
                out.append(text)
            i = j
            continue
        i += 1
    for block in out[: a.max]:
        print(block)
        print("-" * 40)
    more = len(out) - a.max
    print(f"logs[{a.step}]: {len(out)} distinct problems" + (f" ({more} more: --max)" if more > 0 else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main())
