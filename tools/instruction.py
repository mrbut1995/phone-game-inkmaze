#!/usr/bin/env python3
"""Read ONE rule/section of the instructions instead of a whole document (saves thousands of tokens).

  python tools/instruction.py list                    # section ids + sizes of the main instruction
  python tools/instruction.py show R3                 # rule R3
  python tools/instruction.py show 7.3                # section 7.3 (testing: what must be tested)
  python tools/instruction.py show T9 --doc tools     # a row/rule of another doc: writing | tools | planning | types | ai_helper | brief | cheatsheet
  python tools/instruction.py search "baseline"       # lines matching, with their section id
  python tools/instruction.py brief                    # the ~1.5k-token agent brief (read this first)
"""
from __future__ import annotations

import argparse
import re
import sys

from _common import ROOT, estimate_tokens, read_text, setup_stdout

DOCS = {
    "writing": "instruction/instruction_writing_project.md",
    "tools": "instruction/instruction_tools.md",
    "planning": "instruction/instruction_planning.md",
    "types": "instruction/instruction_project_types.md",
    "brief": "instruction/brief.md",
    "cheatsheet": "instruction/godot4_cheatsheet.md",
    "ai_helper": "ai_helper/instruction_ai_helper.md",
}
HEAD = re.compile(r"^(#{2,4})\s+((?:R\d+|\d+(?:\.\d+)*|[A-Z]\d*)[.\s:)-]?)\s*(.*)$")


def sections(text: str):
    """-> list of (id, title, level, start, end)"""
    lines = text.splitlines()
    heads = []
    for i, line in enumerate(lines):
        m = HEAD.match(line)
        if m:
            sid = re.match(r"^(R\d+|\d+(?:\.\d+)*|[A-Z]\d*)", m.group(2)).group(1)
            heads.append((sid, m.group(3).strip(), len(m.group(1)), i))
    out = []
    for n, (sid, title, level, start) in enumerate(heads):
        end = len(lines)
        for sid2, _, level2, start2 in heads[n + 1:]:
            if level2 <= level:
                end = start2
                break
        out.append((sid, title, level, start, end))
    return lines, out


def main() -> int:
    setup_stdout()
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    for name in ("list", "show", "search", "brief"):
        p = sub.add_parser(name)
        p.add_argument("--doc", default="writing")
        if name in ("show", "search"):
            p.add_argument("query")
    a = ap.parse_args()
    if a.cmd == "brief":
        a.doc = "brief"
    path = ROOT / DOCS.get(a.doc, a.doc)
    if not path.exists():
        print(f"ERROR: {path.name} not found (docs: {', '.join(DOCS)})")
        return 1
    text = read_text(path)
    if a.cmd == "brief":
        print(text)
        return 0
    lines, secs = sections(text)
    if a.cmd == "list":
        for sid, title, level, start, end in secs:
            print(f"{'  ' * (level - 2)}{sid:6s} {title[:70]}  (~{estimate_tokens(chr(10).join(lines[start:end]))} tok)")
        return 0
    if a.cmd == "show":
        want = a.query.rstrip(".")
        for sid, title, level, start, end in secs:
            if sid == want:
                print("\n".join(lines[start:end]).rstrip())
                return 0
        # table row / bullet with that id (e.g. T9 in a table)
        for line in lines:
            if re.match(r"^\|\s*" + re.escape(want) + r"\s*\|", line) or line.startswith(f"- {want}") or line.startswith(f"{want}."):
                print(line)
                return 0
        print(f"section '{want}' not found; try `list`")
        return 1
    needle = a.query.lower()
    shown = 0
    for sid, title, level, start, end in secs:
        for line in lines[start + 1:end]:
            if needle in line.lower():
                print(f"[{sid}] {line.strip()[:150]}")
                shown += 1
                if shown >= 12:
                    return 0
    print(f"{shown} matches")
    return 0


if __name__ == "__main__":
    sys.exit(main())
