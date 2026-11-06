#!/usr/bin/env python3
"""CSV -> Definition .tres files (data-driven types: ActorDefinition, ItemDefinition, ...). Reads the @export list of the script.

  python tools/data_import.py scripts/models/definitions/ActorDefinition.gd data/import/actors.csv --out data/actors
  python tools/data_import.py ... --dry-run
CSV header = export names (id is required). Cell conventions:
  int/float/bool/String/StringName: plain text      enum (e.g. Enums.Faction): member name (PLAYER) or index
  PackedScene/Texture2D/SpriteFrames/Resource: project path (scenes/...tscn or res://...)      empty cell = keep script default
"""
from __future__ import annotations

import argparse
import csv
import re
import sys

from _common import ROOT, norm, parse_gd, read_text, setup_stdout

RESOURCE_TYPES = {"PackedScene", "Texture2D", "SpriteFrames", "Resource", "AudioStream", "Script", "Material", "Theme", "Font"}


def enum_members(type_name: str) -> list:
    if "." not in type_name:
        return []
    cls, enum = type_name.split(".", 1)
    for p in (ROOT / "scripts").rglob("*.gd"):
        text = read_text(p)
        if re.search(rf"^class_name {cls}\b", text, re.M):
            m = re.search(rf"^enum\s+{enum}\s*\{{([^}}]*)\}}", text, re.M)
            if m:
                return [x.strip().split("=")[0].strip() for x in m.group(1).split(",") if x.strip()]
    return []


def convert(value: str, type_name: str, ext: dict, errors: list, ctx: str) -> str:
    v = value.strip()
    if type_name in ("int",):
        return str(int(float(v)))
    if type_name in ("float",):
        return repr(float(v))
    if type_name == "bool":
        return "true" if v.lower() in ("1", "true", "yes") else "false"
    if type_name == "String":
        return '"' + v.replace('"', '\\"') + '"'
    if type_name == "StringName":
        return f'&"{v}"'
    members = enum_members(type_name)
    if members:
        if v.isdigit():
            return v
        if v.upper() in members:
            return str(members.index(v.upper()))
        errors.append(f"{ctx}: '{v}' is not a member of {type_name} {members}")
        return "0"
    if type_name in RESOURCE_TYPES:
        path = norm(v)
        if not (ROOT / path).exists():
            errors.append(f"{ctx}: resource not found: {path}")
        key = (path, type_name)
        if key not in ext:
            ext[key] = f"{len(ext) + 2}_{re.sub(r'[^a-z0-9]', '', path.lower())[-8:]}"
        return f'ExtResource("{ext[key]}")'
    errors.append(f"{ctx}: unsupported export type '{type_name}'")
    return "null"


def main() -> int:
    setup_stdout()
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("definition")
    ap.add_argument("csv")
    ap.add_argument("--out", required=True)
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()

    script_path = norm(a.definition)
    g = parse_gd(read_text(ROOT / script_path))
    if not g["class_name"]:
        print("ERROR: definition script needs a class_name")
        return 1
    types = {n: t for n, t, _ in g["exports"]}
    rows = list(csv.DictReader(open(ROOT / norm(a.csv), encoding="utf-8-sig", newline="")))
    errors, written = [], 0
    for i, row in enumerate(rows, 2):
        rid = (row.get("id") or "").strip()
        if not rid:
            errors.append(f"csv line {i}: empty id")
            continue
        ext: dict = {}
        props = []
        for col, val in row.items():
            if col is None or val is None or not val.strip():
                continue
            if col not in types:
                errors.append(f"csv line {i}: unknown export '{col}' for {g['class_name']}")
                continue
            props.append(f"{col} = {convert(val, types[col], ext, errors, f'{rid}.{col}')}")
        steps = 2 + len(ext)
        lines = [f'[gd_resource type="Resource" script_class="{g["class_name"]}" load_steps={steps} format=3]', "",
                 f'[ext_resource type="Script" path="res://{script_path}" id="1_def"]']
        for (path, rtype), eid in ext.items():
            lines.append(f'[ext_resource type="{rtype}" path="res://{path}" id="{eid}"]')
        lines += ["", "[resource]", 'script = ExtResource("1_def")'] + props
        out = ROOT / norm(a.out) / f"{rid}.tres"
        if not a.dry_run:
            out.parent.mkdir(parents=True, exist_ok=True)
            out.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")
        written += 1
        print(f"{'would write' if a.dry_run else 'wrote'} {out.relative_to(ROOT).as_posix()}")
    for e in errors:
        print("ERROR " + e)
    print(f"data_import: {written} files, {len(errors)} errors")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
