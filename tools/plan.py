#!/usr/bin/env python3
"""Plan helper: keeps session plans in plan/ cheap to read and hard to get wrong.

  python tools/plan.py init                        # create plan/00_overview.md
  python tools/plan.py new <slug> "<Title>"        # create plan/session_NN_<slug>.md from the template
  python tools/plan.py status                      # compact table of all sessions
  python tools/plan.py next                        # brief for the next runnable session (read ONLY this)
  python tools/plan.py start S01 [--allow-unverified]   # status -> in_progress (log line; flag = human OK on unverified deps)
  python tools/plan.py done S01-T01 S01-T02        # tick tasks
  python tools/plan.py block S01-T03 "reason"      # mark a task blocked
  python tools/plan.py finish S01 [--handoff-file notes.md | --handoff "text"] [--unverified]
                                                   # run the FULL gate, tick Definition of Done, write Handoff, mark done
  python tools/plan.py check                       # validate plan files + gameplay coverage
  python tools/plan.py spec 5.1                    # print a section of the gameplay file
  python tools/plan.py sync                        # rewrite the table in 00_overview.md
Status values: planned | in_progress | done | unverified | blocked.   Executor: agent | web-ai
"""
from __future__ import annotations

import argparse
import datetime
import re
import subprocess
import sys
from pathlib import Path

from _common import ROOT, norm, read_text, setup_stdout

PLAN = ROOT / "plan"
SESSION_RE = re.compile(r"^session_(\d+)_([\w\-]+)\.md$")
TASK_RE = re.compile(r"^- \[([ x!])\] (S\d+-T\d+)\b\s*(.*)$")
STATUSES = ("planned", "in_progress", "done", "unverified", "blocked")
EXECUTORS = ("agent", "web-ai")
REQUIRED = ["Goal", "Context pack", "Contracts", "Tasks", "Tests", "Definition of Done", "Handoff", "Log"]
TABLE_START, TABLE_END = "<!-- plan:table:start -->", "<!-- plan:table:end -->"

OVERVIEW_TEMPLATE = """# Plan overview

> Source: `instruction/<game_name>_gameplay.md`. Rules: `instruction/instruction_planning.md`.
> Run ONE session per agent run, then stop. Refresh the table: `python tools/plan.py sync`.

## Limits (checked by `plan.py check`)
- Max tasks per session: 8
- Max context pack files: 12

## Sessions
{start}
{end}

## Order and rationale
<!-- why this order: walking skeleton first, riskiest mechanic early, dependencies -->

## Risks
<!-- unknowns, assumptions, things that may force re-planning -->

## Changes
<!-- one line per re-plan: date, what changed, why (details in plan/changes.md) -->
""".format(start=TABLE_START, end=TABLE_END)

SESSION_TEMPLATE = """# {sid} - {title}
- Status: planned
- Executor: agent
- Depends on: none
- Gameplay refs: <!-- sections and criteria ids, e.g. 4.1, 5.1, M1-1 -->
- Budget: tasks=0 files=0 steps=80

## Goal
<!-- one or two sentences: what is playable/testable when this session is done -->

## Context pack
<!-- the ONLY files to read (path - why). Mark files created by earlier sessions or this one with (new). -->
- instruction/brief.md - rules digest (use `instruction.py show R<n>` for details)

## Contracts
<!-- APIs this session PROVIDES (class, signals, public funcs) and EXPECTS from earlier sessions, so nobody re-reads code -->

## Tasks
<!-- one line each: - [ ] {sid}-T01 [M1-1] what to do (files: a, b) -->
- [ ] {sid}-T01 

## Tests
<!-- test files to write and what they assert; every criterion id above needs one -->
- 

## Definition of Done
- [ ] All tasks ticked
- [ ] Tests above written; `python tools/run_checks.py` is green (or session marked unverified)
- [ ] Handoff filled

## Handoff
<!-- what the next session must know: decisions, deviations, open issues -->

## Log
"""


# ------------------------------------------------------------------ parsing
def load_sessions():
    sessions = []
    if not PLAN.is_dir():
        return sessions
    for p in sorted(PLAN.iterdir()):
        m = SESSION_RE.match(p.name)
        if not m:
            continue
        text = re.sub(r"<!--.*?-->", lambda m: "\n" * m.group(0).count("\n"), read_text(p), flags=re.S)
        meta, sections, cur = {}, {}, None
        title = ""
        for line in text.splitlines():
            if line.startswith("# ") and not title:
                title = line[2:].strip()
            elif line.startswith("## "):
                cur = line[3:].strip()
                sections[cur] = []
            elif cur is None:
                mm = re.match(r"^- ([\w ]+):\s*(.*)$", line)
                if mm:
                    meta[mm.group(1).strip()] = mm.group(2).strip()
            else:
                sections[cur].append(line)
        tasks = []
        for i, line in enumerate(text.splitlines()):
            tm = TASK_RE.match(line)
            if tm:
                tasks.append({"id": tm.group(2), "state": tm.group(1), "text": tm.group(3), "line": i})
        sessions.append({"id": f"S{int(m.group(1)):02d}", "num": int(m.group(1)), "slug": m.group(2), "path": p,
                         "title": title, "meta": meta, "sections": {k: "\n".join(v).strip() for k, v in sections.items()},
                         "tasks": tasks})
    return sessions


def deps_of(s):
    raw = s["meta"].get("Depends on", "none")
    return [] if raw.lower().startswith("none") or not raw else re.findall(r"S\d+", raw)


def status_of(s):
    return s["meta"].get("Status", "planned").split()[0]


def limits():
    text = read_text(PLAN / "00_overview.md") if (PLAN / "00_overview.md").exists() else ""
    mt = re.search(r"Max tasks per session:\s*(\d+)", text)
    mc = re.search(r"Max context pack files:\s*(\d+)", text)
    return int(mt.group(1)) if mt else 8, int(mc.group(1)) if mc else 12


def gameplay_files():
    return [p for p in (ROOT / "instruction").glob("*_gameplay.md") if not p.name.startswith("_")]


def gameplay_criteria():
    ids = set()
    for p in gameplay_files():
        ids |= set(re.findall(r"^\|\s*(M\d+-\d+)\s*\|", read_text(p), re.M))
    return ids


def set_meta(path: Path, key: str, value: str):
    text = read_text(path)
    new, n = re.subn(rf"^- {re.escape(key)}:.*$", f"- {key}: {value}", text, count=1, flags=re.M)
    path.write_text(new if n else text, encoding="utf-8", newline="\n")


def replace_section(path: Path, name: str, body: str):
    text = read_text(path)
    m = re.search(rf"(^## {re.escape(name)}\n)(.*?)(?=^## |\Z)", text, re.S | re.M)
    if not m:
        return False
    new = text[:m.start(2)] + body.strip("\n") + "\n\n" + text[m.end(2):]
    path.write_text(new, encoding="utf-8", newline="\n")
    return True


def tick_checkboxes(path: Path, section: str, skip_words=()):
    text = read_text(path)
    m = re.search(rf"(^## {re.escape(section)}\n)(.*?)(?=^## |\Z)", text, re.S | re.M)
    if not m:
        return
    lines = []
    for l in m.group(2).split("\n"):
        if l.startswith("- [ ]") and not any(w in l for w in skip_words):
            l = l.replace("- [ ]", "- [x]", 1)
        lines.append(l)
    path.write_text(text[:m.start(2)] + "\n".join(lines) + text[m.end(2):], encoding="utf-8", newline="\n")


def append_log(path: Path, line: str):
    text = read_text(path).rstrip("\n") + f"\n- {datetime.date.today().isoformat()} {line}\n"
    path.write_text(text, encoding="utf-8", newline="\n")


# ------------------------------------------------------------------ commands
def cmd_init(_):
    PLAN.mkdir(exist_ok=True)
    (PLAN / ".gdignore").touch()
    f = PLAN / "00_overview.md"
    if f.exists():
        print("plan/00_overview.md already exists")
        return 0
    f.write_text(OVERVIEW_TEMPLATE, encoding="utf-8", newline="\n")
    print("created plan/00_overview.md")
    return 0


def cmd_new(a):
    PLAN.mkdir(exist_ok=True)
    sessions = load_sessions()
    num = max([s["num"] for s in sessions], default=0) + 1
    slug = re.sub(r"[^\w\-]+", "-", a.slug.lower()).strip("-")
    sid = f"S{num:02d}"
    path = PLAN / f"session_{num:02d}_{slug}.md"
    path.write_text(SESSION_TEMPLATE.format(sid=sid, title=a.title), encoding="utf-8", newline="\n")
    print(f"created {path.relative_to(ROOT).as_posix()}")
    return 0


def table(sessions):
    rows = ["| Id | Title | Status | Executor | Depends | Tasks | Gameplay refs |", "|---|---|---|---|---|---|---|"]
    for s in sessions:
        done = sum(1 for t in s["tasks"] if t["state"] == "x")
        title = re.sub(r"^S\d+\s*-\s*", "", s["title"])
        rows.append(f"| {s['id']} | {title} | {status_of(s)} | {s['meta'].get('Executor', 'agent')} | "
                    f"{', '.join(deps_of(s)) or '-'} | {done}/{len(s['tasks'])} | {s['meta'].get('Gameplay refs', '')[:40]} |")
    return "\n".join(rows)


def cmd_status(_):
    sessions = load_sessions()
    if not sessions:
        print("no sessions (python tools/plan.py init / new)")
        return 0
    print(table(sessions))
    nxt = pick_next(sessions)
    print(f"next: {nxt['title']}" if nxt else "next: none (all done or blocked by dependencies)")
    return 0


def cmd_sync(_):
    f = PLAN / "00_overview.md"
    if not f.exists():
        print("run `plan.py init` first")
        return 1
    text = read_text(f)
    if TABLE_START not in text or TABLE_END not in text:
        print("markers missing in 00_overview.md")
        return 1
    head, rest = text.split(TABLE_START, 1)
    _, tail = rest.split(TABLE_END, 1)
    f.write_text(head + TABLE_START + "\n" + table(load_sessions()) + "\n" + TABLE_END + tail, encoding="utf-8", newline="\n")
    print("synced plan/00_overview.md")
    return 0


def pick_next(sessions):
    by_id = {s["id"]: s for s in sessions}
    for want in ("in_progress", "planned"):
        for s in sessions:
            if status_of(s) == want and all(d in by_id and status_of(by_id[d]) == "done" for d in deps_of(s)):
                return s
    return None


def cmd_next(_):
    s = pick_next(load_sessions())
    if not s:
        print("No runnable session. Run `python tools/plan.py status`.")
        return 0
    sec = s["sections"]
    open_tasks = [t for t in s["tasks"] if t["state"] != "x"]
    print(f"NEXT: {s['title']}   (status={status_of(s)}, executor={s['meta'].get('Executor', 'agent')}, "
          f"depends={','.join(deps_of(s)) or 'none'})")
    print(f"FILE: {s['path'].relative_to(ROOT).as_posix()}   BUDGET: {s['meta'].get('Budget', '?')}")
    print(f"GAMEPLAY REFS: {s['meta'].get('Gameplay refs', '')}   (print a section: python tools/plan.py spec <n>)")
    for name in ("Goal", "Context pack", "Contracts"):
        print(f"\n## {name}\n{sec.get(name, '').strip()}")
    print("\n## Open tasks")
    for t in open_tasks:
        print(f"- [{t['state']}] {t['id']} {t['text']}")
    print(f"\n## Tests\n{sec.get('Tests', '').strip()}")
    by_id = {x["id"]: x for x in load_sessions()}
    for dep in deps_of(s):
        h = by_id.get(dep, {}).get("sections", {}).get("Handoff", "").strip()
        if h:
            lines = [l for l in h.splitlines() if l.strip()]
            print(f"\n## Handoff from {dep} (read this instead of re-exploring its code)")
            print("\n".join(l[:240] for l in lines[:30]) + (f"\n... ({len(lines) - 30} more lines in {by_id[dep]['path'].name})" if len(lines) > 30 else ""))
    steps = re.search(r"steps=(\d+)", s["meta"].get("Budget", ""))
    if steps:
        print(f"\nSTEP BUDGET: ~{steps.group(1)} tool calls. If you pass it, write the Handoff and stop with a partial report instead of continuing.")
    print("\nCOMMANDS (do not read tools/plan.py to learn them):")
    print(f"  python tools/plan.py start {s['id']}")
    print("  python tools/plan.py done <task ids>")
    print(f"  python tools/run_checks.py [--only tests --filter <name> --repeat N]   |   python tools/logs.py <step>")
    print(f"  python tools/plan.py finish {s['id']} --handoff-file <notes.md>   (runs the full gate, ticks Definition of Done, writes Handoff)")
    print("WORKFLOW: read ONLY the context pack -> do the open tasks -> gate -> finish -> STOP. A new session = a NEW chat.")
    return 0


def cmd_start(a):
    s = next((x for x in load_sessions() if x["id"] == a.session.upper()), None)
    if not s:
        print(f"ERROR: unknown session {a.session}")
        return 1
    by_id = {x["id"]: x for x in load_sessions()}
    ok_states = ("done", "unverified") if a.allow_unverified else ("done",)
    blocked = [d for d in deps_of(s) if status_of(by_id[d]) not in ok_states]
    if blocked:
        print(f"ERROR: dependencies not done: {', '.join(blocked)}")
        return 1
    set_meta(s["path"], "Status", "in_progress")
    append_log(s["path"], "started" + (" (human approved continuing on unverified dependencies)" if a.allow_unverified else ""))
    print(f"{s['id']} -> in_progress")
    return 0


def cmd_done(a):
    sessions = load_sessions()
    for tid in a.tasks:
        sid = tid.split("-")[0]
        s = next((x for x in sessions if x["id"] == sid), None)
        t = next((x for x in s["tasks"] if x["id"] == tid), None) if s else None
        if not t:
            print(f"ERROR: unknown task {tid}")
            return 1
        lines = read_text(s["path"]).splitlines()
        lines[t["line"]] = re.sub(r"^- \[[ x!]\]", "- [x]", lines[t["line"]])
        s["path"].write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")
        if status_of(s) == "planned":
            set_meta(s["path"], "Status", "in_progress")
        print(f"ticked {tid}")
    return 0


def cmd_block(a):
    sid = a.task.split("-")[0]
    s = next((x for x in load_sessions() if x["id"] == sid), None)
    t = next((x for x in s["tasks"] if x["id"] == a.task), None) if s else None
    if not t:
        print(f"ERROR: unknown task {a.task}")
        return 1
    lines = read_text(s["path"]).splitlines()
    lines[t["line"]] = re.sub(r"^- \[[ x!]\]", "- [!]", lines[t["line"]]) + f" (BLOCKED: {a.reason})"
    s["path"].write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")
    set_meta(s["path"], "Status", "blocked")
    append_log(s["path"], f"blocked {a.task}: {a.reason}")
    print(f"blocked {a.task}")
    return 0


def cmd_finish(a):
    s = next((x for x in load_sessions() if x["id"] == a.session.upper()), None)
    if not s:
        print(f"ERROR: unknown session {a.session}")
        return 1
    pending = [t["id"] for t in s["tasks"] if t["state"] != "x"]
    if pending:
        print(f"ERROR: tasks not done: {', '.join(pending)}")
        return 1
    rc = subprocess.run([sys.executable, "tools/run_checks.py"], cwd=str(ROOT)).returncode
    handoff = a.handoff
    if a.handoff_file:
        handoff = read_text(ROOT / norm(a.handoff_file))
    if rc in (0, 2) and (rc == 0 or a.unverified):
        if handoff:
            replace_section(s["path"], "Handoff", handoff)
        tick_checkboxes(s["path"], "Definition of Done", skip_words=("run_checks",) if rc == 2 else ())
    if rc == 0:
        set_meta(s["path"], "Status", "done")
        append_log(s["path"], "finished (verified)")
        print(f"{s['id']} -> done")
        return 0
    if rc == 2 and a.unverified:
        set_meta(s["path"], "Status", "unverified")
        append_log(s["path"], "finished NOT VERIFIED (Godot steps skipped)")
        print(f"{s['id']} -> unverified (dependents stay blocked until verified)")
        return 0
    print("checks did not pass; session NOT finished" + (" (use --unverified if Godot is unavailable)" if rc == 2 else ""))
    return 1


def cmd_spec(a):
    files = gameplay_files()
    if not files:
        print("no instruction/*_gameplay.md found")
        return 1
    want = a.section.rstrip(".")
    lines = read_text(files[0]).splitlines()
    out, level = [], None
    for line in lines:
        m = re.match(r"^(#{2,4})\s+(\d+(?:\.\d+)*)[.\s]", line)
        if level is None:
            if m and m.group(2) == want:
                level, out = len(m.group(1)), [line]
        else:
            if re.match(r"^#{1,%d}\s" % level, line):
                break
            out.append(line)
    print("\n".join(out) if out else f"section {want} not found in {files[0].name}")
    return 0 if out else 1


def cmd_check(_):
    errors, warns = [], []
    if not PLAN.is_dir() or not (PLAN / "00_overview.md").exists():
        print("plan_check: plan/00_overview.md missing")
        return 1
    sessions = load_sessions()
    max_tasks, max_ctx = limits()
    ids = {s["id"] for s in sessions}
    referenced, all_task_ids = set(), set()
    for s in sessions:
        n = s["path"].name
        if not s["title"].startswith(s["id"] + " "):
            errors.append(f"{n}: title must start with '# {s['id']} - '")
        for sec in REQUIRED:
            if sec not in s["sections"]:
                errors.append(f"{n}: missing section '## {sec}'")
        if status_of(s) not in STATUSES:
            errors.append(f"{n}: bad Status '{status_of(s)}'")
        if s["meta"].get("Executor", "agent") not in EXECUTORS:
            errors.append(f"{n}: Executor must be agent|web-ai")
        for d in deps_of(s):
            if d not in ids:
                errors.append(f"{n}: depends on unknown {d}")
            elif d == s["id"]:
                errors.append(f"{n}: depends on itself")
        if not s["tasks"]:
            errors.append(f"{n}: no tasks")
        if len(s["tasks"]) > max_tasks:
            errors.append(f"{n}: {len(s['tasks'])} tasks > limit {max_tasks} (split the session)")
        for t in s["tasks"]:
            if t["id"] in all_task_ids:
                errors.append(f"{n}: duplicate task id {t['id']}")
            all_task_ids.add(t["id"])
            if not t["id"].startswith(s["id"] + "-"):
                errors.append(f"{n}: task {t['id']} does not belong to {s['id']}")
            if not t["text"].strip():
                errors.append(f"{n}: task {t['id']} has no description")
            for grp in re.findall(r"\[(M\d+-\d+(?:\s*,\s*M\d+-\d+)*)\]", t["text"]):
                referenced |= set(re.findall(r"M\d+-\d+", grp))
        ctx = [l for l in s["sections"].get("Context pack", "").splitlines() if l.startswith("- ")]
        if len(ctx) > max_ctx:
            errors.append(f"{n}: context pack has {len(ctx)} files > limit {max_ctx}")
        for l in ctx:
            m = re.match(r"^- `?([\w./\-]+)`?", l)
            if m and "(new)" not in l and "/" in m.group(1) and not (ROOT / m.group(1)).exists():
                warns.append(f"{n}: context pack path not found: {m.group(1)}")
        tests = [l for l in s["sections"].get("Tests", "").splitlines() if l.startswith("- ") and l.strip() != "-"]
        if s["meta"].get("Executor", "agent") == "agent" and not tests:
            errors.append(f"{n}: Tests section is empty")
        if status_of(s) == "done" and any(t["state"] != "x" for t in s["tasks"]):
            errors.append(f"{n}: Status done but tasks are open")
    # cycles
    by_id = {s["id"]: s for s in sessions}

    def visit(sid, stack):
        if sid in stack:
            errors.append("dependency cycle: " + " -> ".join(stack + [sid]))
            return
        for d in deps_of(by_id.get(sid, {"meta": {}})):
            if d in by_id:
                visit(d, stack + [sid])

    for s in sessions:
        visit(s["id"], [])
    # coverage
    criteria = gameplay_criteria()
    for cid in sorted(criteria - referenced):
        errors.append(f"gameplay criterion {cid} is not covered by any task")
    for cid in sorted(referenced - criteria):
        if criteria:
            errors.append(f"task references unknown criterion {cid}")
    if not criteria:
        warns.append("no acceptance criteria (| M1-1 | ...) found in instruction/*_gameplay.md")
    for w in warns:
        print("WARN " + w)
    for e in errors:
        print("ERROR " + e)
    print(f"plan_check: {len(sessions)} sessions, {len(criteria)} criteria, {len(errors)} errors, {len(warns)} warnings")
    return 1 if errors else 0


def main() -> int:
    setup_stdout()
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("init")
    p = sub.add_parser("new"); p.add_argument("slug"); p.add_argument("title")
    sub.add_parser("status")
    sub.add_parser("next")
    sub.add_parser("sync")
    sub.add_parser("check")
    p = sub.add_parser("done"); p.add_argument("tasks", nargs="+")
    p = sub.add_parser("block"); p.add_argument("task"); p.add_argument("reason")
    p = sub.add_parser("finish"); p.add_argument("session"); p.add_argument("--unverified", action="store_true"); p.add_argument("--handoff", default=""); p.add_argument("--handoff-file", default="")
    p = sub.add_parser("start"); p.add_argument("session"); p.add_argument("--allow-unverified", action="store_true", help="human decision: continue although a dependency is only `unverified`")
    p = sub.add_parser("spec"); p.add_argument("section")
    a = ap.parse_args()
    return {"init": cmd_init, "new": cmd_new, "status": cmd_status, "next": cmd_next, "sync": cmd_sync,
            "check": cmd_check, "start": cmd_start, "done": cmd_done, "block": cmd_block, "finish": cmd_finish, "spec": cmd_spec}[a.cmd](a)


if __name__ == "__main__":
    sys.exit(main())
