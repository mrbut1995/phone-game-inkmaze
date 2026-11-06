#!/usr/bin/env python3
"""Compact project tree / file list. Skips .godot, *.uid, *.import, .git, ai_helper (and .gitkeep/.gdignore).

  python tools/project_tree.py                      # whole project, tree format
  python tools/project_tree.py scenes --depth 2
  python tools/project_tree.py --ext gd,tscn --format list
  python tools/project_tree.py --format json --out tree.json
"""
from __future__ import annotations

import argparse
import json
import sys

from _common import ROOT, iter_files, norm, setup_stdout


def build_tree(paths):
    tree: dict = {}
    for p in paths:
        node = tree
        parts = p.split("/")
        for part in parts[:-1]:
            node = node.setdefault(part + "/", {})
        node[parts[-1]] = None
    return tree


def render(tree, depth, indent=0, sizes=None, prefix=""):
    lines = []
    for name in sorted(tree, key=lambda n: (not n.endswith("/"), n.lower())):
        child = tree[name]
        if child is None:
            extra = f"  ({sizes[prefix + name]} B)" if sizes else ""
            lines.append("  " * indent + name + extra)
        else:
            lines.append("  " * indent + name)
            if depth is None or indent + 1 < depth:
                lines.extend(render(child, depth, indent + 1, sizes, prefix + name))
            else:
                lines.append("  " * (indent + 1) + "...")
    return lines


def main() -> int:
    setup_stdout()
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("path", nargs="?", default="", help="sub folder (default: project root)")
    ap.add_argument("--depth", type=int, default=None)
    ap.add_argument("--ext", default="", help="comma list, e.g. gd,tscn")
    ap.add_argument("--format", choices=["tree", "list", "json"], default="tree")
    ap.add_argument("--all", action="store_true", help="also show .gitkeep/.gdignore")
    ap.add_argument("--include-ai-helper", action="store_true")
    ap.add_argument("--sizes", action="store_true")
    ap.add_argument("--out", default="")
    a = ap.parse_args()

    exts = {"." + e.strip().lstrip(".").lower() for e in a.ext.split(",") if e.strip()} or None
    paths = list(iter_files(norm(a.path).rstrip("/"), a.include_ai_helper, exts, a.all))
    if a.format == "list":
        out = "\n".join(paths)
    elif a.format == "json":
        out = json.dumps(paths, indent=1)
    else:
        sizes = {p: (ROOT / p).stat().st_size for p in paths} if a.sizes else None
        out = "\n".join(render(build_tree(paths), a.depth, sizes=sizes))
    if a.out:
        (ROOT / a.out).write_text(out + "\n", encoding="utf-8")
        print(f"wrote {a.out} ({len(paths)} files)")
    else:
        print(out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
