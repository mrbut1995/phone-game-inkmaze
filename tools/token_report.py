#!/usr/bin/env python3
"""Which files cost the most tokens, and how much an outline would save. Use before building prompts / reading files.

  python tools/token_report.py                # top 15 text files
  python tools/token_report.py --top 30 --folder scripts
"""
from __future__ import annotations

import argparse
import sys

from _common import ROOT, TEXT_EXTS, estimate_tokens, format_outline, iter_files, norm, read_text, setup_stdout


def main() -> int:
    setup_stdout()
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--top", type=int, default=15)
    ap.add_argument("--folder", default="")
    a = ap.parse_args()
    rows, total = [], 0
    for p in iter_files(norm(a.folder).rstrip("/"), exts=TEXT_EXTS - {".md", ".py"}):
        t = estimate_tokens(read_text(ROOT / p))
        total += t
        out = format_outline(p) if p.endswith(".gd") else ""
        rows.append((t, estimate_tokens(out) if out else 0, p))
    rows.sort(reverse=True)
    print("tokens  outline  file")
    for t, o, p in rows[: a.top]:
        print(f"{t:6d}  {('~' + str(o)) if o else '-':>7}  {p}")
    print(f"token_report: {len(rows)} files, ~{total} tokens total (outline column = tokens if you send only the outline)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
