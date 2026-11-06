#!/usr/bin/env python3
"""Pre-fill the final-report skeleton (instruction_writing_project.md section 9) from git, so the agent only writes the narrative.

  python tools/diff_summary.py                       # vs HEAD (staged + unstaged + untracked)
  python tools/diff_summary.py --base main --save docs/reports/2026-10-24_room_entry_fix.md
Needs a git repository (`git init && git add -A && git commit -m base` before the task).
Lists: files by status, new @export vars, new signals, new [connection]s, EXCEPTION / code-connect tags, new tests,
changed animations / placeholders. Sections that need judgement are left as TODO.
"""
from __future__ import annotations

import argparse
import re
import subprocess
import sys

from _common import ROOT, read_text, setup_stdout


def git(*args) -> str:
    p = subprocess.run(["git", *args], cwd=str(ROOT), capture_output=True, text=True, encoding="utf-8", errors="replace")
    if p.returncode != 0:
        raise RuntimeError(p.stderr.strip() or "git failed")
    return p.stdout


def main() -> int:
    setup_stdout()
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--base", default="HEAD")
    ap.add_argument("--save", default="")
    a = ap.parse_args()
    try:
        status = git("status", "--porcelain=v1", "-uall")
    except (RuntimeError, OSError) as exc:
        print(f"ERROR: {exc}. Run `git init` and commit a baseline first.")
        return 1
    files = []
    for line in status.splitlines():
        code, path = line[:2], line[3:].strip().strip('"')
        if " -> " in path:
            path = path.split(" -> ")[1]
        if path.startswith(("ai_helper/", "tools/.logs/", ".godot/")) or path.endswith((".uid", ".import")):
            continue
        kind = "created" if code.strip() in ("??", "A") else "deleted" if "D" in code else "modified"
        files.append((kind, path))
    added: dict = {}
    for kind, path in files:
        if kind == "deleted":
            continue
        if kind == "created":
            lines = read_text(ROOT / path).splitlines() if (ROOT / path).is_file() else []
        else:
            diff = git("diff", a.base, "--unified=0", "--", path)
            lines = [l[1:] for l in diff.splitlines() if l.startswith("+") and not l.startswith("+++")]
        added[path] = lines

    def collect(pattern, only=None):
        out = []
        rx = re.compile(pattern)
        for path, lines in added.items():
            if only and not path.endswith(only):
                continue
            for l in lines:
                if rx.search(l):
                    out.append((path, l.strip()))
        return out

    exports = collect(r"^@export", ".gd")
    signals = collect(r"^signal\s", ".gd")
    conns = collect(r"^\[connection", ".tscn")
    tags = collect(r"EXCEPTION\(|code-connect:", ".gd")
    tests = [(p, l.strip()) for p, ls in added.items() if p.startswith("tests/") for l in ls if re.match(r"^func test_", l)]
    anims = [p for _, p in files if p.startswith("data/animations/")]
    manifest = [(p, l) for p, l in collect(r"^\|", "MANIFEST.md")]

    def bullets(items, fmt):
        return "\n".join("- " + fmt(i) for i in items) if items else "- (none)"

    out = ["# Report (draft - fill the TODOs)", "", "## 1. Summary", "TODO (3-5 lines)", "", "## 2. Files",
           bullets(files, lambda f: f"{f[0]}: `{f[1]}`"), "", "## 3. Exports added",
           bullets(exports, lambda e: f"`{e[0]}`: {e[1][:110]}"), "", "## 4. Signals",
           "Declared:", bullets(signals, lambda e: f"`{e[0]}`: {e[1][:90]}"), "`.tscn` connections added:",
           bullets(conns, lambda e: f"`{e[0]}`: {e[1][:110]}"), "", "## 5. Animations",
           bullets(anims, lambda p: f"`{p}`") + "\nTweens/justification: TODO", "", "## 6. Placeholders",
           bullets(manifest, lambda e: e[1][:110]), "", f"## 7. Tests ({len(tests)} new test functions)",
           bullets(tests, lambda e: f"`{e[0]}`: {e[1][:80]}"), "Result line (`Tests: N passed, M failed`): TODO", "",
           "## 8. Exceptions / code-connect markers added", bullets(tags, lambda e: f"`{e[0]}`: {e[1][:110]}"), "",
           "## 9. Assumptions / deviations / open questions", "TODO", "", "## 10. Verification",
           "`python tools/run_checks.py` -> TODO (paste the summary lines and RESULT)"]
    text = "\n".join(out) + "\n"
    if a.save:
        dest = ROOT / a.save
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(text, encoding="utf-8", newline="\n")
        print(f"wrote {a.save} ({len(files)} files, {len(exports)} exports, {len(signals)} signals, {len(tests)} tests)")
    else:
        print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
