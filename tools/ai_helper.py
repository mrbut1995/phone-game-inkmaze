#!/usr/bin/env python3
"""Prepare work for an EXTERNAL AI website (Claude, AI Studio...) and apply its answer back.

  python tools/ai_helper.py new "Redesign main menu" --target claude [--plan S03]   # -> ai_helper/session_N/
  python tools/ai_helper.py add 1 scenes/screens/main_menu.tscn --deps --why "screen to change"
  python tools/ai_helper.py add 1 scripts/constants --mode outline
  python tools/ai_helper.py add 1 assets/images-placeholder/ui/logo.svg
  (edit ai_helper/session_1/task.md - remove every <TODO>)
  python tools/ai_helper.py build 1                  # tree.txt, context.txt, prompt.txt + size report
  (paste prompt.txt in the website, attach context.txt (+ binary assets), save the answer to session_1/response.md)
  python tools/ai_helper.py apply 1                  # dry-run: parse response.md, show NEW/MODIFIED
  python tools/ai_helper.py apply 1 --write          # write files into the project, then run_checks
  python tools/ai_helper.py list

Modes for `add`: auto (default: full if small, else outline) | full | outline (signatures/summary only) | asset (binary, attach separately)
"""
from __future__ import annotations

import argparse
import datetime
import difflib
import json
import re
import shutil
import sys
from pathlib import Path

import project_tree
import scene_summary
from _common import (ROOT, IGNORE_DIRS, IGNORE_SUFFIXES, class_index, estimate_tokens, format_outline, iter_files,
                     load_json, norm, parse_tscn, read_text, setup_stdout)

HELPER = ROOT / "ai_helper"
BINARY_EXTS = {".png", ".jpg", ".jpeg", ".webp", ".ogg", ".wav", ".mp3", ".ttf", ".otf", ".woff", ".woff2",
               ".exr", ".hdr", ".glb", ".gltf", ".mp4", ".webm", ".zip", ".bmp", ".tga"}
DEFAULTS = {"targets": {"generic": {"max_files": 20, "max_tokens": 100000}}, "full_file_max_tokens": 6000,
            "tree_max_lines": 400, "allowed_output_roots": ["scenes", "scripts", "data", "tests", "assets/images-placeholder", "plan", "docs"],
            "protected_files": ["project.godot"]}


def cfg() -> dict:
    return {**DEFAULTS, **load_json(HELPER / "config.json", {})}


# ------------------------------------------------------------------ sessions
def session_numbers():
    return sorted(int(m.group(1)) for p in HELPER.glob("session_*") if (m := re.match(r"session_(\d+)$", p.name)))


def session_dir(arg: str) -> Path:
    m = re.search(r"(\d+)$", str(arg))
    if not m:
        raise SystemExit(f"bad session '{arg}' (use 1 or session_1)")
    d = HELPER / f"session_{int(m.group(1))}"
    if not d.is_dir():
        raise SystemExit(f"{d.relative_to(ROOT).as_posix()} does not exist (run `new` first)")
    return d


def load_session(d: Path) -> dict:
    return load_json(d / "session.json", {"files": []})


def save_session(d: Path, s: dict):
    (d / "session.json").write_text(json.dumps(s, indent=1, ensure_ascii=False), encoding="utf-8")


def cmd_new(a):
    HELPER.mkdir(exist_ok=True)
    n = max(session_numbers(), default=0) + 1
    d = HELPER / f"session_{n}"
    (d / "files").mkdir(parents=True)
    save_session(d, {"title": a.title, "target": a.target, "plan_ref": a.plan, "created": datetime.datetime.now().isoformat(timespec="seconds"),
                     "status": "new", "files": []})
    tpl = HELPER / "templates" / "task_template.md"
    (d / "task.md").write_text(read_text(tpl) if tpl.exists() else "# Task\n<TODO>\n", encoding="utf-8", newline="\n")
    print(f"created {d.relative_to(ROOT).as_posix()}  (target={a.target})")
    print(f"next: add files ->  python tools/ai_helper.py add {n} <paths> [--deps] ; then fill {d.relative_to(ROOT).as_posix()}/task.md")
    return 0


def outline_text(rel: str) -> str:
    if rel.endswith(".gd"):
        return format_outline(rel, False)
    if rel.endswith(".tscn"):
        return scene_summary.detail(rel, False)
    lines = read_text(ROOT / rel).splitlines()
    return "\n".join(lines[:60]) + ("\n(truncated)" if len(lines) > 60 else "")


def deps_of(rel: str) -> list:
    found = []
    text = read_text(ROOT / rel) if Path(rel).suffix not in BINARY_EXTS else ""
    if rel.endswith((".tscn", ".tres")):
        found = [e["path"] for e in parse_tscn(text)["ext"].values()]
    elif rel.endswith(".gd"):
        found = [norm(m) for m in re.findall(r'res://[^"\s\)]+', text)]
        ext = re.search(r"^extends\s+(\w+)", text, re.M)
        if ext and ext.group(1) in class_index():
            found.append(class_index()[ext.group(1)])
    return [p for p in dict.fromkeys(found) if (ROOT / p).is_file() and p != rel]


def refused(rel: str) -> str:
    parts = rel.split("/")
    if parts[0] == "ai_helper":
        return "ai_helper/ is not a source folder"
    if any(p in IGNORE_DIRS for p in parts[:-1]) or rel.endswith(IGNORE_SUFFIXES):
        return "ignored (.godot / .uid / .import / .git ...)"
    return ""


def add_one(d: Path, s: dict, rel: str, mode: str, why: str) -> str:
    bad = refused(rel)
    if bad:
        return f"skip {rel}: {bad}"
    p = ROOT / rel
    ext = Path(rel).suffix.lower()
    binary = ext in BINARY_EXTS
    if binary:
        mode = "asset"
    elif mode == "asset":
        mode = "full"
    text = "" if binary else read_text(p)
    if mode == "auto":
        mode = "full" if estimate_tokens(text) <= cfg()["full_file_max_tokens"] else "outline"
    entry = next((f for f in s["files"] if f["path"] == rel), None)
    if entry and entry["mode"] == "full" and mode == "outline":
        return f"keep {rel} (already full)"
    out = d / "files" / rel
    out.parent.mkdir(parents=True, exist_ok=True)
    for stale in (out, Path(str(out) + ".outline.txt")):
        if stale.exists():
            stale.unlink()
    if mode == "outline":
        body = outline_text(rel)
        Path(str(out) + ".outline.txt").write_text(body + "\n", encoding="utf-8", newline="\n")
        tokens, size = estimate_tokens(body), len(body.encode("utf-8"))
    else:
        shutil.copy2(p, out)
        tokens, size = (0 if binary else estimate_tokens(text)), p.stat().st_size
    new = {"path": rel, "mode": mode, "why": why or "", "bytes": size, "tokens": tokens}
    if entry:
        entry.update(new)
    else:
        s["files"].append(new)
    return f"{'upd' if entry else 'add'} {rel} [{mode}] ~{tokens} tok"


def cmd_add(a):
    d = session_dir(a.session)
    s = load_session(d)
    targets = []
    for raw in a.paths:
        rel = norm(raw).rstrip("/")
        if not (ROOT / rel).exists():
            print(f"ERROR: {rel} does not exist")
            return 1
        targets += list(iter_files(rel)) if (ROOT / rel).is_dir() else [rel]
    for rel in targets:
        print(add_one(d, s, rel, a.mode, a.why))
    if a.deps:
        for rel in targets:
            if Path(rel).suffix.lower() in BINARY_EXTS:
                continue
            for dep in deps_of(rel):
                if not any(f["path"] == dep for f in s["files"]):
                    print(add_one(d, s, dep, "outline", f"dependency of {rel}"))
    save_session(d, s)
    total = sum(f["tokens"] for f in s["files"])
    print(f"session has {len(s['files'])} files, ~{total} tokens of context")
    return 0


# ------------------------------------------------------------------ build
def project_facts() -> tuple:
    text = read_text(ROOT / "project.godot") if (ROOT / "project.godot").exists() else ""
    name = (re.search(r'config/name="([^"]*)"', text) or [None, "?"])[1]
    feats = re.search(r"config/features=PackedStringArray\(([^)]*)\)", text)
    features = re.findall(r'"([^"]+)"', feats.group(1)) if feats else []
    engine = next((f for f in features if re.match(r"^\d+\.\d+", f)), "4.x")
    main = (re.search(r'run/main_scene="([^"]*)"', text) or [None, "?"])[1]
    autos = re.findall(r'^(\w+)="\*', text, re.M)
    facts = f"name: {name}\nengine: Godot {engine} ({', '.join(f for f in features if f != engine) or 'n/a'})\nmain scene: {main}\nautoloads: {', '.join(autos) or 'none'}"
    return engine, facts


def build_tree(maxlines: int) -> str:
    """Filtered project tree. Asset folders deeper than 3 levels are collapsed to '(N files)' (saves tokens)."""
    paths, counts = [], {}
    for p in iter_files():
        parts = p.split("/")
        if parts[0] in ("assets",) and len(parts) > 3:
            key = "/".join(parts[:3]) + "/"
            counts[key] = counts.get(key, 0) + 1
        else:
            paths.append(p)
    for key, n in counts.items():
        paths.append(f"{key}({n} files)")
    tree = project_tree.build_tree(paths)
    lines = project_tree.render(tree, None)
    if len(lines) > maxlines:
        lines = project_tree.render(tree, 3) + [f"(tree truncated to depth 3: {len(paths)} entries)"]
    return "\n".join(lines)


def rules_digest() -> str:
    """Condensed rules for the website AI = the rules block of instruction/brief.md (single source of truth)."""
    brief = ROOT / "instruction" / "brief.md"
    if not brief.exists():
        raise SystemExit("ERROR: instruction/brief.md is missing (it holds the rules digest)")
    m = re.search(r"<!-- rules:start -->\n(.*?)\n<!-- rules:end -->", read_text(brief), re.S)
    if not m:
        raise SystemExit("ERROR: instruction/brief.md has no <!-- rules:start --> ... <!-- rules:end --> block")
    return m.group(1).strip()


def cmd_build(a):
    d = session_dir(a.session)
    s = load_session(d)
    c = cfg()
    target = c["targets"].get(s["target"], c["targets"].get("generic", DEFAULTS["targets"]["generic"]))
    task = read_text(d / "task.md")
    if "<TODO" in task:
        print("ERROR: task.md still contains <TODO> placeholders - fill them first")
        return 1
    if not s["files"]:
        print("ERROR: no files in the session (use `add`)")
        return 1
    tree = build_tree(c["tree_max_lines"])
    (d / "tree.txt").write_text(tree + "\n", encoding="utf-8", newline="\n")

    blocks, binaries = [], []
    for f in s["files"]:
        if f["mode"] == "asset":
            binaries.append(f)
            continue
        src = d / "files" / (f["path"] + (".outline.txt" if f["mode"] == "outline" else ""))
        blocks.append(f"===== FILE: {f['path']} [{f['mode']}] =====\n{read_text(src).rstrip()}\n")
    context = "\n".join(blocks)
    (d / "context.txt").write_text(context, encoding="utf-8", newline="\n")

    rows = ["| path | mode | why | ~tokens |", "|---|---|---|---|"]
    rows += [f"| {f['path']} | {f['mode']} | {f['why'] or '-'} | {f['tokens']} |" for f in s["files"]]
    legend = "mode full = complete file; outline = signatures/summary only (ask me if you need the body); asset = binary file attached separately."
    if a.no_bundle:
        names = [Path(f["path"]).name for f in s["files"]]
        if len(set(names)) != len(names):
            print("WARN: duplicate file names - individual attachments would be ambiguous; prefer the bundle")
        attach = ("Files are attached individually; the table below lists each one with its project path.\n")
    else:
        attach = ("One text file `context.txt` is attached. It bundles every non-binary file below; each part starts with a line "
                  "`===== FILE: <path> [<mode>] =====`.\n")
    if binaries:
        attach += "Binary assets attached separately: " + ", ".join(Path(f["path"]).name + f" ({f['path']})" for f in binaries) + ".\n"
    engine, facts = project_facts()
    tpl_dir = HELPER / "templates"
    ver = re.search(r"Version (\d+\.\d+)", read_text(ROOT / "instruction" / "instruction_writing_project.md")) if (ROOT / "instruction" / "instruction_writing_project.md").exists() else None
    digest = rules_digest()
    if ver and f"instruction v{ver.group(1)}" not in digest:
        print(f"WARN: the rules block of instruction/brief.md is not marked 'instruction v{ver.group(1)}' - update the brief to match the instruction")
    body = task.split("\n", 1)[1].strip() if task.startswith("# ") else task.strip()
    prompt = read_text(tpl_dir / "prompt_template.txt")
    for key, val in {"ENGINE": engine, "PROJECT_FACTS": facts, "RULES_DIGEST": digest,
                     "TREE": tree, "ATTACHMENTS": attach.strip(), "FILES_TABLE": "\n".join(rows) + "\n" + legend,
                     "TASK": f"{s['title']}\n\n{body}", "OUTPUT_FORMAT": read_text(tpl_dir / "output_format.md").strip()}.items():
        prompt = prompt.replace("{{" + key + "}}", val)
    (d / "prompt.txt").write_text(prompt, encoding="utf-8", newline="\n")
    (d / "request.md").write_text(f"# {s['title']}\n\n{body}\n", encoding="utf-8", newline="\n")
    s["status"] = "built"
    save_session(d, s)

    pt, ct = estimate_tokens(prompt), estimate_tokens(context)
    attach_count = (len(s["files"]) if a.no_bundle else 1 + len(binaries))
    print(f"built {d.relative_to(ROOT).as_posix()}  target={s['target']}")
    print(f"  prompt.txt   ~{pt} tokens   -> paste into the chat")
    print(f"  context.txt  ~{ct} tokens   -> attach ({sum(1 for f in s['files'] if f['mode'] == 'full')} full, "
          f"{sum(1 for f in s['files'] if f['mode'] == 'outline')} outline)")
    for f in binaries:
        print(f"  asset        {f['path']}   -> attach")
    print(f"  total ~{pt + ct} / {target['max_tokens']} tokens, {attach_count} / {target['max_files']} files")
    code = 0
    if pt + ct > target["max_tokens"]:
        print("WARN: over the token budget - switch big files to --mode outline or remove some")
        code = 0
    if attach_count > target["max_files"]:
        print("WARN: too many attachments - use the bundle (default) or fewer assets")
    print(f"then save the AI answer to {d.relative_to(ROOT).as_posix()}/response.md and run: python tools/ai_helper.py apply {a.session}")
    return code


# ------------------------------------------------------------------ apply
FENCE = re.compile(r"^(`{3,})[^\n]*\n(.*?)\n\1[ \t]*$", re.M | re.S)
FILE_LINE = re.compile(r"(?:^|[\s#/*;<!\-])FILE:\s*[`*\"]*([^\s`*\"]+)")
DELETE_LINE = re.compile(r"^[\s*`]*DELETE:\s*[`*]*([^\s`*]+)", re.M)
ELISION = re.compile(r"^\s*(?:#|//|;|<!--)?\s*\.\.\.\s*(?:-->)?\s*$|(?:#|//)\s*.*(?:rest of (?:the )?(?:file|code|script)|existing code|unchanged|same as (?:before|above)|omitted|remains the same)", re.I)


def parse_response(text: str):
    files, problems = {}, []
    prev_end = 0
    for m in FENCE.finditer(text):
        before = [l for l in text[prev_end:m.start()].splitlines() if l.strip()]
        prev_end = m.end()
        content = m.group(2)
        path = None
        if before:
            fm = FILE_LINE.search(before[-1])
            if fm:
                path = fm.group(1)
        if path is None:
            first = content.split("\n", 1)[0]
            fm = FILE_LINE.search(first)
            if fm:
                path = fm.group(1)
                content = content.split("\n", 1)[1] if "\n" in content else ""
        if path:
            files[norm(path.strip("`*"))] = content
    deletes = [norm(x) for x in DELETE_LINE.findall(text)]
    if not files and not deletes:
        problems.append("no `FILE: <path>` + fenced block found in response.md")
    return files, deletes, problems


def normalize(rel: str, content: str, fix_indent: bool, notes: list) -> str:
    content = content.replace("\r\n", "\n").replace("\r", "\n")
    if not content.endswith("\n"):
        content += "\n"
    if rel.endswith(".gd") and fix_indent:
        lines = content.split("\n")
        has_tab = any(l.startswith("\t") for l in lines)
        spaced = [l for l in lines if l.startswith("    ")]
        if spaced and not has_tab:
            if any((len(l) - len(l.lstrip(" "))) % 4 for l in spaced):
                notes.append(f"{rel}: space indentation is not a multiple of 4; left unchanged")
            else:
                lines = ["\t" * ((len(l) - len(l.lstrip(" "))) // 4) + l.lstrip(" ") if l.startswith(" ") else l for l in lines]
                content = "\n".join(lines)
                notes.append(f"{rel}: converted space indentation to tabs")
    return content


def path_allowed(rel: str, c: dict, allow_protected: bool) -> str:
    if rel.startswith("/") or re.match(r"^[A-Za-z]:", rel) or ".." in rel.split("/"):
        return "unsafe path"
    if rel in c["protected_files"] and not allow_protected:
        return "protected file (use --allow-protected)"
    if rel in c["protected_files"]:
        return ""
    if not any(rel == r or rel.startswith(r + "/") for r in c["allowed_output_roots"]):
        return f"outside allowed folders {c['allowed_output_roots']}"
    return ""


def cmd_apply(a):
    d = session_dir(a.session)
    resp = d / "response.md"
    if not resp.exists() or not read_text(resp).strip():
        print(f"ERROR: paste the AI answer into {resp.relative_to(ROOT).as_posix()} first")
        return 1
    c = cfg()
    files, deletes, problems = parse_response(read_text(resp))
    notes, plan = [], []
    for rel, content in files.items():
        why = path_allowed(rel, c, a.allow_protected)
        if why:
            problems.append(f"{rel}: {why}")
            continue
        content = normalize(rel, content, not a.no_fix_indent, notes)
        if rel.endswith((".gd", ".tscn", ".tres", ".json", ".svg")):
            bad = next(((i + 1, l.strip()) for i, l in enumerate(content.split("\n")) if ELISION.search(l)), None)
            if bad and not a.force:
                problems.append(f"{rel}: looks incomplete (line {bad[0]}: {bad[1][:60]}) - ask the AI for the full file or use --force")
                continue
        dst = ROOT / rel
        old = read_text(dst) if dst.exists() else None
        status = "NEW" if old is None else ("UNCHANGED" if old == content else "MODIFIED")
        diff = list(difflib.unified_diff((old or "").splitlines(), content.splitlines(), lineterm="", n=0))
        added = sum(1 for l in diff if l.startswith("+") and not l.startswith("+++"))
        removed = sum(1 for l in diff if l.startswith("-") and not l.startswith("---"))
        plan.append((rel, content, status, added, removed, diff))
    for rel in deletes:
        why = path_allowed(rel, c, a.allow_protected)
        if why:
            problems.append(f"DELETE {rel}: {why}")
        elif not (ROOT / rel).exists():
            notes.append(f"DELETE {rel}: file does not exist (ignored)")

    print(("WRITE" if a.write else "DRY-RUN") + f" session {d.name}: {len(plan)} files, {len(deletes)} deletes")
    for rel, _, status, added, removed, diff in plan:
        print(f"  {status:9s} {rel}  (+{added} -{removed})")
        if a.diff and status == "MODIFIED":
            print("\n".join("      " + l for l in diff[:60]))
    for rel in deletes:
        print(f"  DELETE    {rel}")
    for n in notes:
        print("  note: " + n)
    for p in problems:
        print("  PROBLEM: " + p)

    out = d / "out"
    for rel, content, *_ in plan:
        (out / rel).parent.mkdir(parents=True, exist_ok=True)
        (out / rel).write_text(content, encoding="utf-8", newline="\n")
    if problems and not a.force:
        print("nothing written because of PROBLEMs (reviewed copies are in out/). Fix response.md or use --force.")
        return 1
    if not a.write:
        print("dry-run only. Add --write to apply.")
        return 0
    for rel, content, status, *_ in plan:
        if status == "UNCHANGED":
            continue
        (ROOT / rel).parent.mkdir(parents=True, exist_ok=True)
        (ROOT / rel).write_text(content, encoding="utf-8", newline="\n")
    for rel in deletes:
        p = ROOT / rel
        if p.is_file() and not path_allowed(rel, c, a.allow_protected):
            p.unlink()
            for suffix in (".uid", ".import"):
                if (ROOT / (rel + suffix)).exists():
                    (ROOT / (rel + suffix)).unlink()
    s = load_session(d)
    s["status"] = "applied"
    save_session(d, s)
    print("applied. Next: `godot --headless --path . --import` (creates .uid files), then `python tools/run_checks.py`.")
    return 0


def cmd_list(_):
    for n in session_numbers():
        d = HELPER / f"session_{n}"
        s = load_session(d)
        print(f"session_{n} | {s.get('status', '?'):8s} | {s.get('target', '?'):8s} | {len(s.get('files', []))} files | {s.get('title', '')}")
    return 0


def main() -> int:
    setup_stdout()
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("new"); p.add_argument("title"); p.add_argument("--target", default="generic"); p.add_argument("--plan", default="")
    p = sub.add_parser("add"); p.add_argument("session"); p.add_argument("paths", nargs="+")
    p.add_argument("--mode", choices=["auto", "full", "outline", "asset"], default="auto"); p.add_argument("--why", default=""); p.add_argument("--deps", action="store_true")
    p = sub.add_parser("build"); p.add_argument("session"); p.add_argument("--no-bundle", action="store_true")
    p = sub.add_parser("apply"); p.add_argument("session"); p.add_argument("--write", action="store_true"); p.add_argument("--diff", action="store_true")
    p.add_argument("--force", action="store_true"); p.add_argument("--allow-protected", action="store_true"); p.add_argument("--no-fix-indent", action="store_true")
    sub.add_parser("list")
    a = ap.parse_args()
    return {"new": cmd_new, "add": cmd_add, "build": cmd_build, "apply": cmd_apply, "list": cmd_list}[a.cmd](a)


if __name__ == "__main__":
    sys.exit(main())
