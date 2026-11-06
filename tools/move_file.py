#!/usr/bin/env python3
"""Move/rename a file or folder and rewrite every res:// reference (scripts, scenes, resources, project.godot, docs).
Also moves the .uid / .import sidecar files. Dry-run by default.

  python tools/move_file.py scripts/entities/Actor.gd scripts/objects/world/Actor.gd           # preview
  python tools/move_file.py scenes/popups scenes/objects/ui/popups --apply                      # whole folder
Does NOT rename class_name or code identifiers: do that separately and run the tests.
"""
from __future__ import annotations

import argparse
import re
import shutil
import sys

from _common import ROOT, TEXT_EXTS, iter_files, norm, read_text, setup_stdout

SIDECARS = (".uid", ".import")


def main() -> int:
    setup_stdout()
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("old")
    ap.add_argument("new")
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--no-docs", action="store_true", help="do not touch .md files")
    a = ap.parse_args()

    old, new = norm(a.old).rstrip("/"), norm(a.new).rstrip("/")
    src, dst = ROOT / old, ROOT / new
    if not src.exists():
        print(f"ERROR: {old} does not exist")
        return 1
    if dst.exists():
        print(f"ERROR: {new} already exists")
        return 1

    moves = []
    if src.is_dir():
        moves.append((old, new))
    else:
        moves.append((old, new))
        for suffix in SIDECARS:
            if (ROOT / (old + suffix)).exists():
                moves.append((old + suffix, new + suffix))

    pattern = re.compile(r"res://" + re.escape(old) + r"(?=[/\"'\s\)\],]|$)")
    changes = []
    for p in iter_files(exts=TEXT_EXTS):
        if a.no_docs and p.endswith(".md"):
            continue
        text = read_text(ROOT / p)
        new_text, n = pattern.subn("res://" + new, text)
        if n:
            changes.append((p, n, new_text))

    print(("APPLY" if a.apply else "DRY-RUN") + f": {old} -> {new}")
    for m_old, m_new in moves:
        print(f"  move {m_old} -> {m_new}")
    for p, n, _ in changes:
        print(f"  rewrite {p} ({n} refs)")
    if not changes:
        print("  (no references to rewrite)")
    if not a.apply:
        print("re-run with --apply to perform it")
        return 0

    for p, _, new_text in changes:
        (ROOT / p).write_text(new_text, encoding="utf-8", newline="\n")
    for m_old, m_new in moves:
        (ROOT / m_new).parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(ROOT / m_old), str(ROOT / m_new))
    # remove empty parent dirs left behind
    parent = (ROOT / old).parent
    while parent != ROOT and parent.exists() and not any(parent.iterdir()):
        parent.rmdir()
        parent = parent.parent
    print("done. Next: python tools/run_checks.py")
    return 0


if __name__ == "__main__":
    sys.exit(main())
