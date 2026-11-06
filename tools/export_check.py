#!/usr/bin/env python3
"""Find required exports that no scene assigns (the `assert(x != null)` in _ready would fire at runtime). Exit 1 on errors.

A "required export" = an @export var that its script (or a base script) asserts `!= null` on.
  python tools/export_check.py
"""
from __future__ import annotations

import re
import sys

from _common import ROOT, class_index, iter_files, norm, parse_gd, parse_tscn, read_text, resolve_scene, setup_stdout

ASSERT = re.compile(r"assert\(\s*(\w+)\s*!=\s*null")


def required_exports(script: str, classes: dict, seen=None) -> set:
    seen = seen or set()
    if not script or script in seen or not (ROOT / script).exists():
        return set()
    seen.add(script)
    text = read_text(ROOT / script)
    g = parse_gd(text)
    exports = {n for n, _, _ in g["exports"]}
    req = {m.group(1) for m in ASSERT.finditer(text) if m.group(1) in exports}
    ext = g["extends"]
    if ext.startswith("res://"):
        req |= required_exports(norm(ext), classes, seen)
    elif ext in classes:
        req |= required_exports(classes[ext], classes, seen)
    return req


def main() -> int:
    setup_stdout()
    classes = class_index()
    scenes = list(iter_files(exts={".tscn"}))
    resolved = {s: resolve_scene(s) for s in scenes}
    # instancing nodes anywhere: scene path -> list of prop dicts that override the instanced root
    overrides: dict = {}
    for s in scenes:
        for n in parse_tscn(read_text(ROOT / s))["nodes"]:
            if n["parent"] is not None and n["instance_path"]:
                overrides.setdefault(n["instance_path"], []).append(n["props"])
    errors = warns = 0
    for s, nodes in resolved.items():
        for rel, n in nodes.items():
            script = n.get("script")
            if not script or n.get("script_scene") != s and rel != "":
                continue
            req = required_exports(script, classes)
            for name in sorted(req):
                if name in n["props"]:
                    continue
                if rel == "":
                    if any(name in props for props in overrides.get(s, [])):
                        continue
                    if s in overrides:
                        print(f"WARN  {s}: root requires export '{name}' ({script}); instancing scenes do not set it")
                        warns += 1
                    # not instanced anywhere and not set: the scene would fail when run directly
                    elif not s.startswith("scenes/base/"):
                        print(f"WARN  {s}: root requires export '{name}' ({script}) but nothing assigns it")
                        warns += 1
                else:
                    print(f"ERROR {s}: node '{rel}' ({script}) requires export '{name}' but the scene does not assign it")
                    errors += 1
    print(f"export_check: {errors} errors, {warns} warnings")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
