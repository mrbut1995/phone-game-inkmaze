"""Phương án B (mỗi hướng 1 scene HUD riêng):

1. Các HUD chế độ bản DỌC (`nodes/hud/<mode>.tscn`) đổi PackedScene gốc từ `base.tscn`
   sang `res://nodes/hud/portrait/portrait.tscn` (đã có action bar dọc).
2. Sinh HUD bản NGANG cho từng chế độ: `nodes/hud/landscape/<mode>.tscn`
   — kế thừa `res://nodes/hud/landscape/landscape.tscn` (đã có action bar ngang 2 hàng),
     giữ NGUYÊN tên node + script của bản dọc (controller/script tìm node theo tên),
     chỉ chuyển toạ độ dọc (anchor_y) thành toạ độ tuyệt đối trong khung thẻ 980×249
     để thẻ nằm ở phần trên, chừa chỗ cho 2 hàng nút của action bar ngang.

Usage: python tools/ui/make_hud_landscape.py
"""

from __future__ import annotations

import pathlib
import re
import sys

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

ROOT = pathlib.Path(__file__).resolve().parents[2]
HUD_DIR = ROOT / "nodes" / "hud"
LAND_DIR = HUD_DIR / "landscape"
BASE_UID = "uid://bnohqoayq3dt2"
PORTRAIT_UID = "uid://bl4r7bsfws086"
LANDSCAPE_UID = "uid://cchuuwsep7gyy"
BASE_SCENE = "res://nodes/hud/base.tscn"
PORTRAIT_SCENE = "res://nodes/hud/portrait/portrait.tscn"
LANDSCAPE_SCENE = "res://nodes/hud/landscape/landscape.tscn"

## Khung thẻ của HUD dọc (base.tscn: anchor 0.072 → 0.072*1920 + 37 .. + 286)
REF_H = 249.0

HUD_SCENES = [
    "level_mode.tscn", "dungeon_mode.tscn", "minesweep_hud.tscn", "sum_path_hud.tscn",
    "blind_memory_hud.tscn", "countdown_hud.tscn", "fading_ink_hud.tscn",
    "fog_of_war_hud.tscn", "one_stroke_hud.tscn", "wall_builder_hud.tscn",
]

CONTAINERS = {
    "HBoxContainer", "VBoxContainer", "HFlowContainer", "VFlowContainer", "GridContainer",
    "MarginContainer", "CenterContainer", "PanelContainer", "ScrollContainer", "BoxContainer",
    "FlowContainer", "TabContainer", "SplitContainer", "AspectRatioContainer",
}
NODE_RE = re.compile(r'^\[node name="([^"]*)"(?: type="([^"]*)")?(?: parent="([^"]*)")?')
PROP_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_/]*) = (.*)$")


def split_scene(text: str) -> tuple[list[str], list[dict], str]:
    header: list[str] = []
    blocks: list[dict] = []
    tail: list[str] = []
    cur: dict | None = None
    for line in text.splitlines(keepends=True):
        if line.startswith("[node "):
            m = NODE_RE.match(line)
            cur = {"head": line, "body": [], "name": m.group(1), "type": m.group(2),
                   "parent": m.group(3)}
            blocks.append(cur)
        elif line.startswith("[connection ") or line.startswith("[editable"):
            cur = None
            tail.append(line)
        elif cur is None:
            header.append(line)
        else:
            cur["body"].append(line)
    return header, blocks, tail


def prop(block: dict, name: str) -> str | None:
    for line in block["body"]:
        m = PROP_RE.match(line.rstrip("\n"))
        if m and m.group(1) == name:
            return m.group(2).strip()
    return None


def path_of(block: dict) -> str:
    p = block["parent"]
    return block["name"] if p in (None, ".", "") else f"{p}/{block['name']}"


def flatten_y(block: dict) -> bool:
    """Chuyển anchor dọc (theo khung 249) thành offset tuyệt đối — trả True nếu có sửa."""
    at = float(prop(block, "anchor_top") or 0.0)
    ab = float(prop(block, "anchor_bottom") or 0.0)
    if at == 0.0 and ab == 0.0:
        return False
    ot = float(prop(block, "offset_top") or 0.0)
    ob = float(prop(block, "offset_bottom") or 0.0)
    new_ot = round(at * REF_H + ot, 2)
    new_ob = round(ab * REF_H + ob, 2)
    geom = ("layout_mode", "anchors_preset", "anchor_left", "anchor_top", "anchor_right",
            "anchor_bottom", "offset_left", "offset_top", "offset_right", "offset_bottom")
    kept = [l for l in block["body"] if not (PROP_RE.match(l.rstrip("\n")) and
                                             PROP_RE.match(l.rstrip("\n")).group(1) in geom)]
    fresh = [
        "layout_mode = 1\n",
        "anchors_preset = -1\n",
        f"anchor_left = {prop(block, 'anchor_left') or '0.0'}\n",
        "anchor_top = 0.0\n",
        f"anchor_right = {prop(block, 'anchor_right') or '0.0'}\n",
        "anchor_bottom = 0.0\n",
        f"offset_left = {prop(block, 'offset_left') or '0.0'}\n",
        f"offset_top = {new_ot}\n",
        f"offset_right = {prop(block, 'offset_right') or '0.0'}\n",
        f"offset_bottom = {new_ob}\n",
    ]
    block["body"] = fresh + kept
    return True


def make_landscape_hud(name: str) -> str:
    text = (HUD_DIR / name).read_text(encoding="utf-8")
    header, blocks, tail = split_scene(text)
    types = {path_of(b): b["type"] for b in blocks}

    for i, line in enumerate(header):
        if line.startswith("[ext_resource") and ("/hud/base.tscn" in line
                or "/hud/portrait/portrait.tscn" in line or "/hud/landscape/landscape.tscn" in line):
            header[i] = re.sub(r'uid="[^"]*" path="[^"]*"',
                               f'uid="{LANDSCAPE_UID}" path="{LANDSCAPE_SCENE}"', line)
    out = "".join(header)
    changed: list[str] = []
    for block in blocks:
        if block["parent"] in (None, ".") and block["name"] == "Hud":
            block["body"] = [f"custom_minimum_size = Vector2(0, 760)\n"] + block["body"]
            out += block["head"] + "".join(block["body"])
            continue
        ptype = types.get(block["parent"] or "", "")
        mode = prop(block, "layout_mode")
        if ptype not in CONTAINERS and mode not in ("0", "2"):
            if flatten_y(block):
                changed.append(path_of(block))
        out += block["head"] + "".join(block["body"])
    out += "".join(tail)
    (LAND_DIR / name).write_text(out, encoding="utf-8")
    return ", ".join(changed) if changed else "(không có thẻ nào dùng anchor dọc)"


def repoint_portrait_huds() -> None:
    for name in HUD_SCENES:
        path = HUD_DIR / name
        text = path.read_text(encoding="utf-8")
        new = re.sub(r'\[ext_resource type="PackedScene" uid="[^"]*" path="res://nodes/hud/base\.tscn" id="([^"]+)"\]',
                     f'[ext_resource type="PackedScene" uid="{PORTRAIT_UID}" '
                     f'path="{PORTRAIT_SCENE}" id="\\1"]', text)
        if new != text:
            path.write_text(new, encoding="utf-8")
            print(f"  OK dọc → portrait.tscn: {name}")


def patch_game_layouts() -> None:
    portrait = ROOT / "scenes" / "orientation" / "portrait" / "game.tscn"
    landscape = ROOT / "scenes" / "orientation" / "landscape" / "game.tscn"
    text = portrait.read_text(encoding="utf-8")
    new = re.sub(r'\[ext_resource type="PackedScene" uid="[^"]*" path="res://nodes/hud/base\.tscn" id="14_nepv3"\]',
                 f'[ext_resource type="PackedScene" uid="{PORTRAIT_UID}" '
                 f'path="{PORTRAIT_SCENE}" id="14_nepv3"]', text)
    if new != text:
        portrait.write_text(new, encoding="utf-8")
        print("  OK game dọc: Information → portrait.tscn")

    text = landscape.read_text(encoding="utf-8")
    new = re.sub(r'\[ext_resource type="PackedScene" uid="[^"]*" path="res://nodes/hud/base\.tscn" id="14_nepv3"\]',
                 f'[ext_resource type="PackedScene" uid="{LANDSCAPE_UID}" '
                 f'path="{LANDSCAPE_SCENE}" id="14_nepv3"]', text)
    new = new.replace('custom_minimum_size = Vector2(0, 260)', 'custom_minimum_size = Vector2(0, 760)')
    if new != text:
        landscape.write_text(new, encoding="utf-8")
        print("  OK game ngang: Information → landscape.tscn (cao 760)")


if __name__ == "__main__":
    LAND_DIR.mkdir(parents=True, exist_ok=True)
    repoint_portrait_huds()
    for name in HUD_SCENES:
        print(f"  OK landscape/{name}: {make_landscape_hud(name)}")
    patch_game_layouts()
