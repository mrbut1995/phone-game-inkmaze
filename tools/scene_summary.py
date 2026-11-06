#!/usr/bin/env python3
"""Summarise scenes without reading the raw .tscn.

  python tools/scene_summary.py --all                       # one line per scene
  python tools/scene_summary.py scenes/screens/game.tscn    # node tree, scripts, connections
  python tools/scene_summary.py scenes/screens/game.tscn --flat   # include nodes inherited from base scenes
"""
from __future__ import annotations

import argparse
import sys

from _common import ROOT, iter_files, norm, parse_tscn, read_text, resolve_scene, setup_stdout


def kind_of(path: str) -> str:
    parts = path.split("/")
    return parts[1] if len(parts) > 2 and parts[0] == "scenes" else "-"


def one_line(path: str) -> str:
    nodes = resolve_scene(path)
    data = parse_tscn(read_text(ROOT / path))
    root = nodes.get("", {})
    base = data["nodes"][0]["instance_path"] if data["nodes"] else ""
    return (f"{path} | {kind_of(path)} | root={root.get('type', '?')} | script={root.get('script') or '-'}"
            f" | nodes={len(nodes)} | conn={len(data['conns'])}" + (f" | inherits={base}" if base else ""))


def detail(path: str, flat: bool) -> str:
    data = parse_tscn(read_text(ROOT / path))
    merged = resolve_scene(path)
    own = {n["name"] if n["parent"] is None else (n["name"] if n["parent"] == "." else f"{n['parent']}/{n['name']}")
           for n in data["nodes"]}
    out = [f"{path}  ({kind_of(path)})"]
    if data["nodes"] and data["nodes"][0]["instance_path"]:
        out.append(f"inherits: {data['nodes'][0]['instance_path']}")
    out.append("nodes (* = unique name, [script], -> instanced scene):")

    def label_of(rel, n):
        label = n["name"] if rel == "" else rel
        if n["unique"]:
            label += "*"
        extra = f" : {n['type']}" if n["type"] else ""
        if n["script"]:
            extra += f" [{n['script']}]"
        if n["instance_path"] and rel != "":
            extra += f" -> {n['instance_path']}"
        return label, extra

    ignore_props = {"script", "unique_name_in_owner", "layout_mode", "anchors_preset", "anchor_right", "anchor_bottom",
                    "grow_horizontal", "grow_vertical", "offset_left", "offset_top", "offset_right", "offset_bottom",
                    "anchor_left", "anchor_top"}
    if flat:
        children: dict = {}
        for rel in merged:
            if rel != "":
                parent = rel.rsplit("/", 1)[0] if "/" in rel else ""
                children.setdefault(parent, []).append(rel)

        def walk(rel, depth):
            n = merged[rel]
            label, extra = label_of(rel, n)
            if rel != "":
                label = rel.split("/")[-1] + ("*" if n["unique"] else "")
            out.append("  " * (depth + 1) + label + extra)
            for child in children.get(rel, []):
                walk(child, depth + 1)

        walk("", 0)
    else:
        for rel, n in merged.items():
            if not ((rel == "") or rel in own):
                continue
            label, extra = label_of(rel, n)
            exported = [k for k in n["props"] if k not in ignore_props]
            if exported:
                extra += "  props: " + ",".join(exported[:8]) + ("..." if len(exported) > 8 else "")
            out.append("  " + label + extra)
    if data["conns"]:
        out.append("connections:")
        for c in data["conns"]:
            out.append(f"  {c['from']}.{c['signal']} -> {c['to']}.{c['method']}")
    subs = sorted(set(data["subs"].values()))
    if subs:
        out.append("sub_resources: " + ", ".join(subs))
    return "\n".join(out)


def main() -> int:
    setup_stdout()
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("scene", nargs="?", default="")
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--flat", action="store_true", help="include nodes inherited from base scenes")
    a = ap.parse_args()
    if a.all or not a.scene:
        for p in iter_files(exts={".tscn"}):
            print(one_line(p))
        return 0
    print(detail(norm(a.scene), a.flat))
    return 0


if __name__ == "__main__":
    sys.exit(main())
