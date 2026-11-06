#!/usr/bin/env python3
"""FIRST command of every agent run: project facts + what to do next in ~40 lines (replaces several exploratory reads).

  python tools/start.py
"""
from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

from _common import ROOT, class_index, iter_files, read_text, setup_stdout

TOOLS = [
    ("what is where", "script_index.py --class X | --find word | --classes   scene_summary.py <scene> | --all   project_tree.py <dir> --depth 2"),
    ("who uses X", "find_refs.py X --count      signal_map.py --find word"),
    ("create", "new_scene.py <kind> <dom>/<name> [--animated]   new_svg.py   spritesheet.py   gen_animation.py   data_import.py   placeholder_audio.py   new_test.py"),
    ("edit safely", "move_file.py old new --apply     (never move/rename by hand)"),
    ("check", "run_checks.py [--fast|--only step] [--only tests --filter name --repeat N]   logs.py <step> (compact errors)   NEVER call godot by hand"),
    ("plan / report", "plan.py next|start|done|finish --handoff-file f|spec N     gameplay_to_plan.py     diff_summary.py --save docs/reports/<date>_<task>.md"),
    ("rules", "instruction.py brief | show R3 | search word     (full docs only when the brief is not enough)"),
]


def main() -> int:
    setup_stdout()
    gd = read_text(ROOT / "project.godot") if (ROOT / "project.godot").exists() else ""
    name = (re.search(r'config/name="([^"]*)"', gd) or [None, "?"])[1]
    feats = ", ".join(re.findall(r'"([^"]+)"', (re.search(r"config/features=PackedStringArray\(([^)]*)\)", gd) or [None, ""])[1]))
    files = list(iter_files())
    scenes = [f for f in files if f.endswith(".tscn")]
    kinds: dict = {}
    for s in scenes:
        parts = s.split("/")
        k = parts[1] if len(parts) > 2 and parts[0] == "scenes" else "other"
        kinds[k] = kinds.get(k, 0) + 1
    scripts = [f for f in files if f.endswith(".gd") and f.startswith("scripts/")]
    tests = [f for f in files if f.startswith("tests/") and Path(f).name.startswith("test_")]
    print(f"PROJECT {name}  ({feats})")
    print(f"  scenes {len(scenes)}: " + ", ".join(f"{k} {v}" for k, v in sorted(kinds.items())) + f" | scripts {len(scripts)} ({len(class_index())} classes) | test files {len(tests)}")
    gameplay = [p.name for p in (ROOT / "instruction").glob("*_gameplay.md") if not p.name.startswith("_")]
    print(f"  gameplay: {', '.join(gameplay) or 'none'}")
    if (ROOT / "plan").is_dir():
        r = subprocess.run([sys.executable, "tools/plan.py", "status"], cwd=str(ROOT), capture_output=True, text=True, encoding="utf-8", errors="replace")
        tail = [l for l in r.stdout.strip().splitlines() if l.startswith("next:") or l.startswith("| S")]
        print("PLAN")
        for l in tail[-6:]:
            print("  " + l[:130])
    elif gameplay:
        print("PLAN  missing -> a whole-game request must start with: python tools/gameplay_to_plan.py (then STOP for review)")
    logs = ROOT / "tools" / ".logs"
    if logs.is_dir():
        print("LAST CHECK LOGS (details: python tools/logs.py <step>)")
        for lg in sorted(logs.glob("*.log")):
            last = [l for l in read_text(lg).splitlines() if l.strip()][-1:] or [""]
            print(f"  {lg.stem}: {last[0][:100]}")
    try:
        g = subprocess.run(["git", "status", "--porcelain"], cwd=str(ROOT), capture_output=True, text=True, timeout=10)
        if g.returncode == 0:
            print(f"GIT  {len(g.stdout.splitlines())} changed files (baseline commit needed for diff_summary)")
    except (OSError, subprocess.TimeoutExpired):
        pass
    print("TOOLS (cheapest first)")
    for k, v in TOOLS:
        print(f"  {k:14s} {v}")
    print("READ ORDER: instruction/brief.md (~1.5k tok) -> `plan.py next` -> only the files in its Context pack. Do not open files to learn what they contain.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
