#!/usr/bin/env python3
"""Offline validation of .tscn/.tres files (no Godot needed). Exit 1 on errors.

Checks: ext_resource paths exist, ids unique/defined, parents exist, [connection] nodes exist and
`_on_*` handler methods exist in the target script chain, $Path / %UniqueName used by scene scripts exist.

  python tools/validate_scenes.py            # all scenes/resources
  python tools/validate_scenes.py scenes/screens/game.tscn
"""
from __future__ import annotations

import argparse
import re
import sys

from _common import ROOT, class_index, iter_files, norm, parse_gd, parse_tscn, read_text, resolve_scene, setup_stdout


def strip_comments_and_strings(text: str) -> str:
    out = []
    for line in text.splitlines():
        line = re.sub(r"#.*$", "", line) if '"' not in line.split("#")[0] or line.strip().startswith("#") else line
        out.append(re.sub(r'"[^"\n]*"', '""', line))
    return "\n".join(out)


def script_methods(path: str, classes: dict, seen=None) -> set:
    seen = seen or set()
    if not path or path in seen or not (ROOT / path).exists():
        return set()
    seen.add(path)
    text = read_text(ROOT / path)
    g = parse_gd(text)
    names = {f["name"] for f in g["funcs"]}
    ext = g["extends"]
    if ext.startswith("res://"):
        names |= script_methods(norm(ext), classes, seen)
    elif ext in classes:
        names |= script_methods(classes[ext], classes, seen)
    return names


def norm_rel(rel: str) -> str:
    parts = []
    for seg in rel.split("/"):
        if seg in ("", "."):
            continue
        if seg == "..":
            if parts:
                parts.pop()
            continue
        parts.append(seg)
    return "/".join(parts)


def validate(path: str, classes: dict) -> list:
    errors = []
    data = parse_tscn(read_text(ROOT / path))
    is_scene = path.endswith(".tscn")

    seen_ids = set()
    for rid, e in data["ext"].items():
        if rid in seen_ids:
            errors.append(f"duplicate ext_resource id '{rid}'")
        seen_ids.add(rid)
        if e["path"] and not (ROOT / e["path"]).exists():
            errors.append(f"missing resource: res://{e['path']} (ext_resource {rid})")
    text = read_text(ROOT / path)
    for m in re.finditer(r'ExtResource\("([^"]+)"\)', text):
        if m.group(1) not in data["ext"]:
            errors.append(f"ExtResource id '{m.group(1)}' is not declared")
    for m in re.finditer(r'SubResource\("([^"]+)"\)', text):
        if m.group(1) not in data["subs"]:
            errors.append(f"SubResource id '{m.group(1)}' is not declared")
    if not is_scene:
        return errors

    try:
        nodes = resolve_scene(path)
    except Exception as exc:  # broken inheritance
        return errors + [f"cannot resolve scene: {exc}"]

    siblings = set()
    for n in data["nodes"]:
        key = (n["parent"], n["name"])
        if key in siblings:
            errors.append(f"duplicate node '{n['name']}' under '{n['parent']}' (line {n['line']})")
        siblings.add(key)
        if n["parent"] not in (None, ".") and norm_rel(n["parent"]) not in nodes:
            errors.append(f"node '{n['name']}' has unknown parent '{n['parent']}' (line {n['line']})")

    for c in data["conns"]:
        frm, to = norm_rel(c["from"]), norm_rel(c["to"])
        # Dây nối vào node BÊN TRONG một scene instance (VD `Portrait/TopBar/Back` khi `Portrait` là
        # instance của layout) là hợp lệ lúc chạy nhưng KHÔNG đọc được offline ⇒ chấp nhận khi tiền tố
        # của đường dẫn là một node instance (cùng luật với `$Node` trong `_check_path`).
        if frm not in nodes and not _enters_instance(nodes, frm):
            errors.append(f"connection {c['signal']}: unknown 'from' node '{c['from']}' (line {c['line']})")
        if to not in nodes:
            if _enters_instance(nodes, to):
                continue
            errors.append(f"connection {c['signal']}: unknown 'to' node '{c['to']}' (line {c['line']})")
            continue
        script = nodes[to].get("script")
        if script and c["method"].startswith("_") and c["method"] not in script_methods(script, classes):
            errors.append(f"connection {c['from']}.{c['signal']}: method '{c['method']}' not found in {script} (line {c['line']})")

    unique_names = {n["name"] for n in nodes.values() if n["unique"]}
    for rel, n in nodes.items():
        script = n.get("script")
        if not script or n.get("script_scene") != path or not (ROOT / script).exists():
            continue
        code = read_text(ROOT / script)
        for m in re.finditer(r'\$"([^"\n]+)"', code):
            _check_path(errors, nodes, rel, m.group(1), script)
        clean = strip_comments_and_strings(code)
        for m in re.finditer(r"\$([A-Za-z_][\w/]*)", clean):
            _check_path(errors, nodes, rel, m.group(1), script)
        for m in re.finditer(r"(?:^|[=(,\s])%([A-Z]\w*)", clean, re.M):
            if m.group(1) not in unique_names:
                errors.append(f"{script}: %{m.group(1)} is not a unique-name node in {path}")
    return errors


def _enters_instance(nodes: dict, rel: str) -> bool:
    """`rel` có đi vào bên trong một scene INSTANCE không (offline không đọc được scene con)."""
    parts = rel.split("/")
    for i in range(1, len(parts)):
        prefix = "/".join(parts[:i])
        if prefix in nodes and nodes[prefix].get("instance_path"):
            return True
    return False


def _check_path(errors, nodes, rel, target, script):
    full = norm_rel(f"{rel}/{target}") if rel else norm_rel(target)
    if full in nodes:
        return
    # path may enter an instanced (opaque) sub-scene: accept if any prefix is an instance
    if _enters_instance(nodes, full):
        return
    errors.append(f"{script}: ${target} not found from node '{rel or '(root)'}'")


def main() -> int:
    setup_stdout()
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("files", nargs="*")
    a = ap.parse_args()
    classes = class_index()
    files = [norm(f) for f in a.files] or list(iter_files(exts={".tscn", ".tres"}))
    total = 0
    for f in files:
        for e in validate(f, classes):
            print(f"ERROR {f}: {e}")
            total += 1
    print(f"validate_scenes: {len(files)} files, {total} errors")
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())
