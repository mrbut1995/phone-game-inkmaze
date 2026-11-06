#!/usr/bin/env python3
"""Find who uses a file path, a class_name or any text. Cross-platform, ignores .godot/*.uid.

  python tools/find_refs.py scripts/objects/world/Actor.gd     # res:// path usages + class usages
  python tools/find_refs.py ActorModel                         # class_name usages (word match)
  python tools/find_refs.py health_changed --max 20
  python tools/find_refs.py Actor --count                      # only hits per file
"""
from __future__ import annotations

import argparse
import re
import sys

from _common import ROOT, TEXT_EXTS, class_index, iter_files, norm, read_text, setup_stdout


def main() -> int:
    setup_stdout()
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("target")
    ap.add_argument("--max", type=int, default=60)
    ap.add_argument("--count", action="store_true")
    ap.add_argument("--regex", action="store_true", help="treat target as a regex")
    a = ap.parse_args()

    t = norm(a.target)
    patterns = []
    owner_file = ""
    if (ROOT / t).is_file():
        patterns.append(re.escape("res://" + t))
        owner_file = t
        m = re.search(r"^class_name\s+(\w+)", read_text(ROOT / t), re.M) if t.endswith(".gd") else None
        if m:
            patterns.append(r"\b" + m.group(1) + r"\b")
    elif a.regex:
        patterns.append(a.target)
    else:
        patterns.append(r"\b" + re.escape(a.target) + r"\b" if re.match(r"^\w+$", a.target) else re.escape(a.target))
    regex = re.compile("|".join(patterns))

    hits, per_file = [], {}
    for p in iter_files(exts={e for e in TEXT_EXTS if e != ".py"}):
        if p == owner_file:
            continue
        for i, line in enumerate(read_text(ROOT / p).splitlines(), 1):
            if regex.search(line):
                per_file[p] = per_file.get(p, 0) + 1
                hits.append((p, i, line.strip()))
    if a.count:
        for p, n in sorted(per_file.items()):
            print(f"{n:4d}  {p}")
        print(f"total: {len(hits)} hits in {len(per_file)} files")
        return 0
    for p, i, line in hits[: a.max]:
        print(f"{p}:{i}: {line[:140]}")
    if len(hits) > a.max:
        print(f"... {len(hits) - a.max} more (use --max or --count)")
    if not hits:
        print("no references found")
    return 0


if __name__ == "__main__":
    sys.exit(main())
