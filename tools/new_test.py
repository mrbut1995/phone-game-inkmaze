#!/usr/bin/env python3
"""Create a test skeleton for a class (instruction section 7). Each public function gets a FAILING stub so
the gate stays red until you replace it with a real assertion.

  python tools/new_test.py ActorModel
  python tools/new_test.py FactionRules --out tests/unit/systems/test_faction_rules.gd
"""
from __future__ import annotations

import argparse
import re
import sys

from _common import ROOT, class_index, norm, parse_gd, read_text, setup_stdout


def snake(name: str) -> str:
    s = re.sub(r"(?<=[a-z0-9])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])", "_", name)
    return s.lower()


def main() -> int:
    setup_stdout()
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("class_name")
    ap.add_argument("--out", default="")
    ap.add_argument("--force", action="store_true")
    a = ap.parse_args()
    idx = class_index()
    if a.class_name not in idx:
        print(f"ERROR: class '{a.class_name}' not found")
        return 1
    src = idx[a.class_name]
    g = parse_gd(read_text(ROOT / src))
    mirror = "/".join(src.split("/")[1:-1])
    out = ROOT / (norm(a.out) if a.out else f"tests/unit/{mirror}/test_{snake(a.class_name)}.gd")
    if out.exists() and not a.force:
        print(f"ERROR: {out.relative_to(ROOT).as_posix()} exists (use --force)")
        return 1
    static_only = bool(g["funcs"]) and all(f["static"] for f in g["funcs"] if not f["name"].startswith("_"))
    lines = ["extends TestCase", f"## Tests for {a.class_name} ({src})", ""]
    if not static_only:
        lines += [f"func _make() -> {a.class_name}:", f"\treturn {a.class_name}.new()", ""]
    public = [f for f in g["funcs"] if not f["name"].startswith("_")]
    for f in public or [{"name": "behaviour", "args": "", "ret": "", "static": False}]:
        lines += [f"func test_{f['name']}_basic_case() -> void:",
                  f"\tfail(\"TODO: test {a.class_name}.{f['name']}({f['args']})\")", ""]
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text("\n".join(lines), encoding="utf-8", newline="\n")
    print(f"created {out.relative_to(ROOT).as_posix()} ({len(public)} stubs). Replace each fail(...) with real assertions.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
