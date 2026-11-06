#!/usr/bin/env python3
"""Generate a plan skeleton (plan/) from the gameplay file: S01 walking skeleton + one session per milestone.
Saves the planning tokens; the agent then refines Context packs, file lists and contracts, runs `plan.py check`, and STOPS.

  python tools/gameplay_to_plan.py                              # auto-detects instruction/*_gameplay.md
  python tools/gameplay_to_plan.py instruction/my_game_gameplay.md --force
Reads: `### M1 - Title` milestone headings, the paragraph under them (goal), rows `| M1-1 | criterion | test path::method |`.
A milestone with more than --max-tasks criteria is split into parts.
"""
from __future__ import annotations

import argparse
import re
import sys

import plan as planlib
from _common import ROOT, norm, read_text, setup_stdout


def slug(text: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")[:32] or "milestone"


def parse(text: str):
    milestones, cur = [], None
    for line in text.splitlines():
        h = re.match(r"^###\s+(M\d+)\s*-\s*(.+?)\s*$", line)
        if h:
            cur = {"id": h.group(1), "title": h.group(2), "goal": "", "rows": []}
            milestones.append(cur)
            continue
        if cur is None:
            continue
        if line.startswith("## "):
            cur = None
            continue
        r = re.match(r"^\|\s*(M\d+-\d+)\s*\|\s*(.*?)\s*\|\s*(.*?)\s*\|\s*$", line)
        if r:
            cur["rows"].append((r.group(1), r.group(2), r.group(3).strip("` ")))
        elif line.strip() and not line.startswith(("|", "-", "---", "#")) and not cur["goal"]:
            cur["goal"] = line.strip()
    return milestones


def write_session(num: int, title: str, goal: str, depends: str, refs: str, tasks: list, tests: list, ctx: list, gameplay: str):
    sid = f"S{num:02d}"
    body = planlib.SESSION_TEMPLATE.format(sid=sid, title=title)
    body = re.sub(r"^- Depends on:.*$", f"- Depends on: {depends}", body, flags=re.M)
    body = re.sub(r"^- Gameplay refs:.*$", f"- Gameplay refs: {refs}", body, flags=re.M)
    body = re.sub(r"^- Budget:.*$", f"- Budget: tasks={len(tasks)} files=?? steps=80", body, flags=re.M)
    body = re.sub(r"(## Goal\n)<!--.*?-->\n", lambda m: m.group(1) + goal + "\n", body, flags=re.S)
    body = re.sub(r"(## Context pack\n)<!--.*?-->\n- instruction/instruction_writing_project.md - rules\n",
                  lambda m: m.group(1) + "\n".join(ctx) + "\n", body, flags=re.S)
    task_lines = "\n".join(f"- [ ] {sid}-T{i:02d} {t}" for i, t in enumerate(tasks, 1))
    body = re.sub(r"(## Tasks\n)<!--.*?-->\n- \[ \] .*?\n", lambda m: m.group(1) + task_lines + "\n", body, flags=re.S)
    body = re.sub(r"(## Tests\n)<!--.*?-->\n- \n", lambda m: m.group(1) + "\n".join(tests) + "\n", body, flags=re.S)
    path = planlib.PLAN / f"session_{num:02d}_{slug(title)}.md"
    path.write_text(body, encoding="utf-8", newline="\n")
    return path


def main() -> int:
    setup_stdout()
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("gameplay", nargs="?", default="")
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--max-tasks", type=int, default=7)
    a = ap.parse_args()
    files = [ROOT / norm(a.gameplay)] if a.gameplay else planlib.gameplay_files()
    if not files or not files[0].exists():
        print("ERROR: no instruction/*_gameplay.md found")
        return 1
    gp = files[0]
    gp_rel = gp.relative_to(ROOT).as_posix()
    milestones = parse(read_text(gp))
    if not milestones:
        print("ERROR: no `### M1 - Title` milestones with criteria rows found in the gameplay file")
        return 1
    if planlib.PLAN.is_dir() and any(planlib.SESSION_RE.match(p.name) for p in planlib.PLAN.iterdir()) and not a.force:
        print("ERROR: plan/ already has sessions (use --force to overwrite)")
        return 1
    planlib.PLAN.mkdir(exist_ok=True)
    (planlib.PLAN / ".gdignore").touch()
    for p in planlib.PLAN.glob("session_*.md"):
        p.unlink()
    ov = planlib.PLAN / "00_overview.md"
    ov.write_text(planlib.OVERVIEW_TEMPLATE.replace("instruction/<game_name>_gameplay.md", gp_rel), encoding="utf-8", newline="\n")

    base_ctx = ["- instruction/brief.md - rules digest (use `instruction.py show R<n>` for details)", f"- {gp_rel} - sections for this session (use `python tools/plan.py spec <n>`)"]
    num = 1
    write_session(num, "Walking skeleton", "Game boots to the main menu and into an empty game screen; test runner and run_checks are green.", "none", "1, 8",
                  ["Project settings, input actions, autoloads review (files: project.godot)",
                   "Boot -> main menu -> game screens from the template (files: scenes/screens/*.tscn)",
                   "Placeholder art + data folders for the first milestone (files: assets/images-placeholder/, data/)",
                   "Smoke test and `python tools/run_checks.py` green (files: tests/)"],
                  ["- tests/integration/test_scenes_smoke.gd: every scene instantiates"], base_ctx, gp_rel)
    prev = "S01"
    for ms in milestones:
        chunks = [ms["rows"][i:i + a.max_tasks] for i in range(0, max(len(ms["rows"]), 1), a.max_tasks)]
        for part, rows in enumerate(chunks, 1):
            num += 1
            title = f"{ms['id']} {ms['title']}" + (f" (part {part})" if len(chunks) > 1 else "")
            tasks = [f"[{rid}] {re.sub(chr(10), ' ', crit)[:120]} (files: TBD)" for rid, crit, _ in rows]
            tests = [f"- {test or 'tests/unit/TBD.gd'}: covers {rid}" for rid, _, test in rows]
            write_session(num, title, ms["goal"] or f"Milestone {ms['id']} is playable and its criteria pass.", prev,
                          f"{ms['id']}, " + ", ".join(r[0] for r in rows), tasks, tests, base_ctx, gp_rel)
            prev = f"S{num:02d}"
    import subprocess
    subprocess.run([sys.executable, "tools/plan.py", "sync"], cwd=str(ROOT))
    print(f"generated {num} sessions from {gp_rel}")
    rc = subprocess.run([sys.executable, "tools/plan.py", "check"], cwd=str(ROOT)).returncode
    print("NEXT (agent): refine each session (Context pack paths, `files:`, Contracts, Budget files=), then `python tools/plan.py check`, then STOP for human review.")
    return rc


if __name__ == "__main__":
    sys.exit(main())
