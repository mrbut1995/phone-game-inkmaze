"""Phương án A: tách thanh nút của màn chơi thành `nodes/hud/action_bar.tscn` (2 bố cục dọc/ngang)
rồi GẮN nó vào MỌI HUD chế độ (nodes/hud/*_hud.tscn, level_mode, dungeon_mode…).

- Nguồn nút: `scenes/orientation/portrait/game.tscn` (bê NGUYÊN block Tool/Wall/Undo/Hint/Replay
  + toàn bộ ext_resource chúng dùng ⇒ art/kích thước khớp y hệt hiện tại).
- `ActionBar` có sẵn: `Portrait/Row` (1 hàng — bản dọc) và `Landscape/MainRow` + `Landscape/SubRow`
  (2 hàng — bản ngang); `scripts/nodes/hud/action_bar.gd` CHUYỂN nút giữa 2 bố cục theo hướng màn hình.

Usage: python tools/ui/make_action_bar.py
"""

from __future__ import annotations

import pathlib
import re
import sys

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

ROOT = pathlib.Path(__file__).resolve().parents[2]
GAME_SCENE = ROOT / "scenes" / "orientation" / "portrait" / "game.tscn"
BAR_SCENE = ROOT / "nodes" / "hud" / "action_bar.tscn"
BAR_SCRIPT = "res://scripts/nodes/hud/action_bar.gd"
HUD_DIR = ROOT / "nodes" / "hud"
# HUD nhận thanh nút (mọi mode + base)
HUD_SCENES = [
    "level_mode.tscn", "dungeon_mode.tscn", "minesweep_hud.tscn", "sum_path_hud.tscn",
    "blind_memory_hud.tscn", "countdown_hud.tscn", "fading_ink_hud.tscn",
    "fog_of_war_hud.tscn", "one_stroke_hud.tscn", "wall_builder_hud.tscn",
]
NODE_RE = re.compile(r"(?=^\[node )", flags=re.M)


def split_blocks(text: str) -> tuple[str, list[str], str]:
    lines = text.splitlines(keepends=True)
    first = next(i for i, l in enumerate(lines) if l.startswith("[node "))
    header = "".join(lines[:first])
    body = "".join(lines[first:])
    blocks = [b for b in NODE_RE.split(body) if b.strip()]
    node_blocks = [b for b in blocks if b.startswith("[node ")]
    tail = "".join(b for b in blocks if not b.startswith("[node "))
    return header, node_blocks, tail


def block_path(block: str) -> str:
    head = block.splitlines()[0]
    name = re.search(r'name="([^"]*)"', head).group(1)
    parent = re.search(r'parent="([^"]*)"', head)
    if not parent or parent.group(1) in ("", "."):
        return name
    return f"{parent.group(1)}/{name}"


def rewrite(block: str, new_parent: str) -> str:
    lines = [l for l in block.splitlines(keepends=True) if not l.startswith("[connection ")]
    lines[0] = re.sub(r' parent="[^"]*"', f' parent="{new_parent}"', lines[0])
    lines[0] = re.sub(r' unique_id=-?\d+', "", lines[0])
    return "".join(lines)


def build_bar() -> None:
    header, blocks, _ = split_blocks(GAME_SCENE.read_text(encoding="utf-8"))
    by_path = {block_path(b): b for b in blocks}
    # THỨ TỰ PHÁT: từng nút gốc rồi tới con của nó (đảm bảo cha luôn đứng trước con)
    ordered: list[str] = []
    for name in ("Tool", "Wall", "Undo", "Hint"):
        root = f"Button/{name}"
        if root in by_path:
            ordered.append(root)
        ordered += [p for p in by_path if p.startswith(root + "/")]
    if "Replay" in by_path:
        ordered.append("Replay")
    ordered += [p for p in by_path if p.startswith("Replay/")]

    used_ext: list[str] = []
    block_text = ""
    roots = {"Button/Tool", "Button/Wall", "Button/Undo", "Button/Hint", "Replay"}
    for path in ordered:
        block = by_path[path]
        for ext in re.findall(r'ExtResource\("([^"]*)"\)', block):
            if ext not in used_ext:
                used_ext.append(ext)
        # node con giữ nguyên cha (đã đổi theo tổ tiên), node gốc nhảy vào Portrait/Row
        if path in roots:
            block = rewrite(block, "Portrait/Row")
            block = re.sub(r' index="-?\d+"', "", block.splitlines(keepends=True)[0]) \
                + "".join(block.splitlines(keepends=True)[1:])
        else:
            # Node con: CHA = đường dẫn mới BỎ đi tên của chính nó
            rel = path.split("Button/", 1)[1] if path.startswith("Button/") else path
            parts = rel.split("/")[:-1]
            new_parent = "Portrait/Row/" + "/".join(parts)
            block = rewrite(block, new_parent)
        block_text += block if block.endswith("\n\n") else block + "\n"

    ext_lines = [l for l in header.splitlines(keepends=True)
                 if l.startswith("[ext_resource") and re.search(r' id="([^"]*)"', l)
                 and re.search(r' id="([^"]*)"', l).group(1) in used_ext]
    out = "[gd_scene format=3]\n\n"
    out += f'[ext_resource type="Script" path="{BAR_SCRIPT}" id="1_bar"]\n'
    out += "".join(ext_lines) + "\n\n"
    out += '[node name="ActionBar" type="Control"]\nlayout_mode = 3\nanchors_preset = 15\n' \
           'anchor_right = 1.0\nanchor_bottom = 1.0\nscript = ExtResource("1_bar")\n\n'
    # Bản DỌC: 1 hàng ngang, NẰM NGAY DƯỚI khung HUD (như thanh nút cũ trong game.tscn)
    out += '[node name="Portrait" type="Control" parent="."]\nlayout_mode = 1\nanchors_preset = 15\n' \
           'anchor_right = 1.0\nanchor_bottom = 1.0\nmouse_filter = 2\n\n'
    out += '[node name="Row" type="HBoxContainer" parent="Portrait"]\nlayout_mode = 1\n' \
           'anchors_preset = -1\nanchor_top = 1.0\nanchor_right = 1.0\nanchor_bottom = 1.0\n' \
           'offset_top = 22.0\noffset_bottom = 186.0\n' \
           'theme_override_constants/separation = 20\nalignment = 1\n\n'
    out += block_text
    # Bản NGANG: 2 hàng (nút chính to trên · Undo/Hint dưới) — action_bar.gd chuyển nút sang đây
    out += '\n[node name="Landscape" type="Control" parent="."]\nlayout_mode = 1\nanchors_preset = 15\n' \
           'anchor_right = 1.0\nanchor_bottom = 1.0\nmouse_filter = 2\nvisible = false\n\n'
    out += '[node name="MainRow" type="HBoxContainer" parent="Landscape"]\nlayout_mode = 1\n' \
           'anchors_preset = -1\nanchor_left = 0.5\nanchor_right = 0.5\noffset_left = -490.0\n' \
           'offset_right = 490.0\noffset_top = 22.0\noffset_bottom = 186.0\n' \
           'theme_override_constants/separation = 18\nalignment = 1\n\n'
    out += '[node name="SubRow" type="HBoxContainer" parent="Landscape"]\nlayout_mode = 1\n' \
           'anchors_preset = -1\nanchor_left = 0.5\nanchor_right = 0.5\noffset_left = -490.0\n' \
           'offset_right = 490.0\noffset_top = 196.0\noffset_bottom = 360.0\n' \
           'theme_override_constants/separation = 18\nalignment = 1\n'
    BAR_SCENE.write_text(out, encoding="utf-8")
    print(f"  OK action_bar.tscn: {len(ordered)} node nút · {len(used_ext)} ext_resource")


def attach_to_huds() -> None:
    for name in HUD_SCENES:
        path = HUD_DIR / name
        if not path.exists():
            print(f"  !! thiếu {name}")
            continue
        text = path.read_text(encoding="utf-8")
        if 'name="ActionBar"' in text:
            print(f"  (đã có ActionBar) {name}")
            continue
        ext = ('[ext_resource type="PackedScene" path="res://nodes/hud/action_bar.tscn" '
               'id="L_action_bar"]\n')
        lines = text.splitlines(keepends=True)
        first = next((i for i, l in enumerate(lines) if l.startswith("[node ")), len(lines))
        text = "".join(lines[:first]) + ext + "\n" + "".join(lines[first:])
        text = text.rstrip("\n") + '\n\n[node name="ActionBar" parent="." instance=ExtResource("L_action_bar")]\n'
        path.write_text(text, encoding="utf-8")
        print(f"  OK gắn ActionBar vào {name}")


def strip_from_game_layouts() -> None:
    """Bỏ hẳn node Button/* + Replay khỏi 2 bố cục màn chơi (đã chuyển vào HUD)."""
    for rel, prefixes in (("scenes/orientation/portrait/game.tscn", ("Button", "Replay")),
                          ("scenes/orientation/landscape/game.tscn", ("Side/Button", "Side/Replay"))):
        path = ROOT / rel
        text = path.read_text(encoding="utf-8")
        header, blocks, tail = split_blocks(text)
        keep, dropped = [], 0
        for b in blocks:
            p = block_path(b)
            if any(p == pre or p.startswith(pre + "/") for pre in prefixes):
                dropped += 1
                continue
            keep.append(b)
        # dọn [connection] trỏ vào node đã xóa
        tail = "".join(l for l in tail.splitlines(keepends=True)
                       if not any(f'from="{pre}' in l for pre in prefixes))
        out = header + "".join(keep) + tail
        # bỏ ext_resource không còn ai dùng (art của các nút đã chuyển sang action_bar.tscn)
        used = set(re.findall(r'ExtResource\("([^"]*)"\)', "".join(keep) + tail))
        out = "".join(l for l in out.splitlines(keepends=True)
                      if not (l.startswith("[ext_resource") and
                              (re.search(r' id="([^"]*)"', l) or re.match(r'$', l)) and
                              re.search(r' id="([^"]*)"', l).group(1) not in used))
        # renumber index= theo từng cha cho liền mạch
        counters: dict[str, int] = {}
        rows = []
        for line in out.splitlines(keepends=True):
            m = re.match(r'\[node name="([^"]*)"(?: type="[^"]*")?(?: parent="([^"]*)")?', line)
            if m:
                key = m.group(2) or ""
                idx = counters.get(key, 0)
                counters[key] = idx + 1
                if re.search(r'index="\d+"', line):
                    line = re.sub(r'index="\d+"', f'index="{idx}"', line)
            rows.append(line)
        path.write_text("".join(rows), encoding="utf-8")
        print(f"  OK dọn {rel}: bỏ {dropped} node")


if __name__ == "__main__":
    build_bar()
    attach_to_huds()
    strip_from_game_layouts()
