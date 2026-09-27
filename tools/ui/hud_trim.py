"""Cắt HUD theo yêu cầu "chỉ hiện thứ cần thiết" (2026-09-27).

Xoá cả CÂY node khỏi scene HUD + chỉnh vài thuộc tính (cỡ/anchor/visible) + dọn `@export`
trên node gốc cho khớp.  Chạy lại nhiều lần vẫn an toàn (idempotent — node không còn thì bỏ qua).

    python tools/ui/hud_trim.py            # áp dụng
    python tools/ui/hud_trim.py --dry      # chỉ in ra việc sẽ làm

Bảng CONFIG bên dưới là NGUỒN SỰ THẬT của thiết kế HUD mới:
    · Play · Minesweeper · Blind Memory · Fading Ink · One Stroke · Wall Builder  → CHỈ THỜI GIAN
    · Dungeon  → SỐ BƯỚC + TẦNG        (Time ẩn)
    · Countdown → NGÂN SÁCH CÒN        (Time ẩn)
    · Fog of War → LƯỢT THỬ LẠI        (Time ẩn)
    · Sum Path  → TỔNG · TOÁN TỬ · MỤC TIÊU (Time ẩn)
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

# Node Time của bản DỌC nằm trong `game_hud.tscn` (node KẾ THỪA — không xoá được, chỉ ẩn được)
PORTRAIT_TIME = "Content/ModeInformation/Time"

## Bản NGANG của HUD Fading Ink xoá MẤT node `Time` ở lần chạy đầu ⇒ chèn lại nguyên khối
## (chép từ git HEAD — cùng id `ExtResource("4_time")`, khôi phục kèm ext_resource).
FADING_INK_TIME = '''[node name="Time" type="TextureRect" parent="Content/ModeInformation" parent_id_path=PackedInt32Array(1591333926) index="0" unique_id=1036036466]
custom_minimum_size = Vector2(120, 115)
layout_mode = 2
mouse_filter = 2
texture = ExtResource("4_time")

[node name="Head" type="Label" parent="Content/ModeInformation/Time" index="0" unique_id=937397718]
layout_mode = 0
offset_left = 16.0
offset_top = 10.0
offset_right = 110.0
offset_bottom = 24.0
theme_type_variation = &"HudTimeHead"
text = "STR_HUD_TIME"
vertical_alignment = 1

[node name="Value" type="Label" parent="Content/ModeInformation/Time" index="1" unique_id=1374290961]
layout_mode = 0
offset_left = 10.0
offset_top = 33.0
offset_right = 110.0
offset_bottom = 75.0
theme_type_variation = &"HudTimeValue"
text = "0:00"
horizontal_alignment = 1
vertical_alignment = 1

[node name="Sub" type="Label" parent="Content/ModeInformation/Time" index="2" unique_id=861101356]
layout_mode = 0
offset_left = 10.0
offset_top = 84.0
offset_right = 110.0
offset_bottom = 99.0
theme_type_variation = &"HudTimeSub"
text = "STR_HUD_TIME_FREE"
horizontal_alignment = 1
vertical_alignment = 1'''

CONFIG: dict[str, dict] = {
    # ---------------------------------------------------------------- Play / Level
    "nodes/hud/portrait/game/level_mode.tscn": {
        "delete": ["Content/ModeInformation/Challenge"],
        "exports": ["time_value_node"],
    },
    "nodes/hud/landscape/game/level_mode.tscn": {
        "delete": ["Content/ModeInformation/Challenge"],
        "exports": ["time_value_node"],
    },
    # ---------------------------------------------------------------- Dungeon: SỐ BƯỚC + TẦNG
    "nodes/hud/portrait/game/dungeon_mode.tscn": {
        "delete_children_of": [PORTRAIT_TIME],
        "set": {PORTRAIT_TIME: {"visible": "false"}},
        "exports": ["time_value_node", "step_value_node", "floor_value_node"],
    },
    "nodes/hud/landscape/game/dungeon_mode.tscn": {
        "delete": ["Content/ModeInformation/Time"],
        "exports": ["step_value_node", "floor_value_node"],
    },
    # ---------------------------------------------------------------- Minesweeper: CHỈ THỜI GIAN
    "nodes/hud/portrait/game/minesweep_hud.tscn": {
        "delete": ["Content/ModeInformation/Bomb"],
        "exports": [],
    },
    "nodes/hud/landscape/game/minesweep_hud.tscn": {
        "delete": ["Content/ModeInformation/Bomb"],
        "exports": ["time_value_node"],
    },
    # ---------------------------------------------------------------- Blind Memory: CHỈ THỜI GIAN
    "nodes/hud/portrait/game/blind_memory_hud.tscn": {
        "delete": ["Content/ModeInformation/Note"],
        "exports": [],
    },
    "nodes/hud/landscape/game/blind_memory_hud.tscn": {
        "delete": ["Content/ModeInformation/Note"],
        "exports": ["time_value_node"],
    },
    # ---------------------------------------------------------------- Fading Ink: CHỈ THỜI GIAN
    "nodes/hud/portrait/game/fading_ink_hud.tscn": {
        "delete": ["Content/ModeInformation/Sheet", PORTRAIT_TIME],
        "exports": [],
    },
    "nodes/hud/landscape/game/fading_ink_hud.tscn": {
        "delete": ["Content/ModeInformation/Sheet"],
        "add_nodes": [FADING_INK_TIME],
        "exports": ["time_value_node"],
    },
    # ---------------------------------------------------------------- One Stroke: CHỈ THỜI GIAN
    "nodes/hud/portrait/game/one_stroke_hud.tscn": {
        "delete": ["Content/ModeInformation/Sheet"],
        "exports": [],
    },
    "nodes/hud/landscape/game/one_stroke_hud.tscn": {
        "delete": ["Content/ModeInformation/Sheet"],
        "exports": ["time_value_node"],
    },
    # ---------------------------------------------------------------- Wall Builder: CHỈ THỜI GIAN
    "nodes/hud/portrait/game/wall_builder_hud.tscn": {
        "delete": ["Content/ModeInformation/Sheet"],
        "exports": ["time_value_node"],
    },
    "nodes/hud/landscape/game/wall_builder_hud.tscn": {
        "delete": ["Content/ModeInformation/Sheet"],
        "exports": ["time_value_node"],
    },
    # ---------------------------------------------------------------- Countdown: CHỈ NGÂN SÁCH CÒN
    "nodes/hud/portrait/game/countdown_hud.tscn": {
        "delete": [
            "Content/ModeInformation/Sheet/Title",
            "Content/ModeInformation/Sheet/Spent",
            "Content/ModeInformation/Sheet/Price",
            "Content/ModeInformation/Sheet/Segments",
        ],
        "delete_children_of": [PORTRAIT_TIME],
        "set": {
            PORTRAIT_TIME: {"visible": "false"},
            "Content/ModeInformation/Sheet": {
                "anchor_left": "0.78", "anchor_right": "1.0",
                "offset_left": "0.0", "offset_right": "0.0",
            },
        },
        "exports": ["time_value_node", "budget_value_node", "budget_max_label"],
    },
    "nodes/hud/landscape/game/countdown_hud.tscn": {
        "delete": [
            "Content/ModeInformation/Time",
            "Content/ModeInformation/Sheet/Title",
            "Content/ModeInformation/Sheet/Spent",
            "Content/ModeInformation/Sheet/Price",
            "Content/ModeInformation/Sheet/Segments",
        ],
        "set": {
            "Content/ModeInformation/Sheet": {
                "custom_minimum_size": "Vector2(190, 115)",
                "size_flags_horizontal": "0",
            },
        },
        "exports": ["budget_value_node", "budget_max_label"],
    },
    # ---------------------------------------------------------------- Fog of War: CHỈ LƯỢT THỬ LẠI
    "nodes/hud/portrait/game/fog_of_war_hud.tscn": {
        "delete": [
            "Content/ModeInformation/Sheet/RowVision",
            "Content/ModeInformation/Sheet/VisionTitle",
            "Content/ModeInformation/Sheet/Chip",
            "Content/ModeInformation/Sheet/ChipLabel",
            "Content/ModeInformation/Sheet/RowWarn",
            "Content/ModeInformation/Sheet/Warn1",
            "Content/ModeInformation/Sheet/Warn2",
        ],
        "delete_children_of": [PORTRAIT_TIME],
        "set": {
            PORTRAIT_TIME: {"visible": "false"},
            "Content/ModeInformation/Sheet": {
                "anchor_left": "0.84", "anchor_right": "1.0",
                "offset_left": "0.0", "offset_right": "0.0",
            },
        },
        "exports": ["time_value_node", "retry_value_node", "retry_max_label", "retry_note_label"],
    },
    "nodes/hud/landscape/game/fog_of_war_hud.tscn": {
        "delete": [
            "Content/ModeInformation/Time",
            "Content/ModeInformation/Sheet/RowVision",
            "Content/ModeInformation/Sheet/VisionTitle",
            "Content/ModeInformation/Sheet/Chip",
            "Content/ModeInformation/Sheet/ChipLabel",
            "Content/ModeInformation/Sheet/VisionDesc",
            "Content/ModeInformation/Sheet/RowWarn",
            "Content/ModeInformation/Sheet/Warn1",
            "Content/ModeInformation/Sheet/Warn2",
            "Content/ModeInformation/Sheet/SubNote",
        ],
        "set": {
            "Content/ModeInformation/Sheet": {
                "custom_minimum_size": "Vector2(170, 115)",
                "size_flags_horizontal": "0",
            },
        },
        "exports": ["retry_value_node", "retry_max_label", "retry_note_label"],
    },
    # ---------------------------------------------------------------- Sum Path: TỔNG · TOÁN TỬ · MỤC TIÊU
    "nodes/hud/portrait/game/sum_path_hud.tscn": {
        "delete": [
            "Content/ModeInformation/Sheet/Title",
            "Content/ModeInformation/Sheet/Bar",
        ],
        "delete_children_of": [PORTRAIT_TIME],
        "set": {
            "Content/ModeInformation/Sheet": {
                "anchor_left": "0.44", "anchor_right": "1.0",
                "offset_left": "0.0", "offset_right": "0.0",
            },
        },
        "add_nodes": [
            '\n'.join([
                '[node name="Time" parent="Content/ModeInformation"'
                ' parent_id_path=PackedInt32Array(366839706) index="0" unique_id=212466531]',
                'visible = false',
            ]),
        ],
        "exports": [
            "time_value_node", "sum_value_node", "sum_note_label", "operator_value_label",
            "target_value_node", "need_label",
        ],
    },
    "nodes/hud/landscape/game/sum_path_hud.tscn": {
        "delete": [
            "Content/ModeInformation/Time",
            "Content/ModeInformation/Sheet/Title",
            "Content/ModeInformation/Sheet/SubNote",
            "Content/ModeInformation/Sheet/Bar",
        ],
        "set": {
            "Content/ModeInformation/Sheet": {
                "custom_minimum_size": "Vector2(320, 115)",
                "size_flags_horizontal": "0",
            },
        },
        "exports": [
            "sum_value_node", "sum_note_label", "operator_value_label",
            "target_value_node", "need_label",
        ],
    },
}

NODE_RE = re.compile(r'^\[node name="(?P<name>[^"]+)"')
PARENT_RE = re.compile(r'parent="(?P<parent>[^"]*)"')
EXPORT_RE = re.compile(r'(?P<key>\w+)\s*=\s*NodePath\("(?P<path>[^"]*)"\)')
NODE_PATHS_RE = re.compile(r'node_paths=PackedStringArray\((?P<list>[^)]*)\)')
## `id="..."` của `[ext_resource]` — PHẢI loại `uid="..."` (chuỗi `uid="` chứa cả `id="`)
EXT_ID_RE = re.compile(r'(?:^|\s)id="([^"]+)"')


class Block:
    def __init__(self, header: str, lines: list[str]) -> None:
        self.header = header
        self.lines = lines          # gồm cả header
        self.name = ""
        self.parent = "."
        self.path = ""
        if self.header.startswith("[node "):
            m = NODE_RE.match(self.header)
            if m:
                self.name = m.group("name")
            m = PARENT_RE.search(self.header)
            self.parent = m.group("parent") if m else "."

    @property
    def is_node(self) -> bool:
        return self.header.startswith("[node ")


def split_blocks(text: str) -> tuple[list[str], list[Block]]:
    """Tách file .tscn thành (khối đầu file, danh sách block)."""
    raw = text.split("\n")
    blocks: list[Block] = []
    head: list[str] = []
    current: Block | None = None
    for line in raw:
        if line.startswith("["):
            if current is not None:
                _trim_tail(current)
                blocks.append(current)
            header = line
            current = Block(header, [header])
        elif current is None:
            head.append(line)
        else:
            current.lines.append(line)
    if current is not None:
        _trim_tail(current)
        blocks.append(current)
    # bỏ dòng trống cuối của khối đầu file
    while head and head[-1].strip() == "":
        head.pop()
    return head, blocks


def _trim_tail(block: Block) -> None:
    while len(block.lines) > 1 and block.lines[-1].strip() == "":
        block.lines.pop()


def resolve_paths(blocks: list[Block]) -> dict[str, Block]:
    by_path: dict[str, Block] = {}
    for block in blocks:
        if not block.is_node:
            continue
        parent = block.parent
        if parent in (".", ""):
            block.path = block.name
        else:
            block.path = "%s/%s" % (parent, block.name)
        by_path[block.path] = block
    return by_path


def apply(rel: str, cfg: dict, dry: bool) -> list[str]:
    path = ROOT / rel
    text = path.read_text(encoding="utf-8")
    head, blocks = split_blocks(text)

    # chèn block node mới (override node KẾ THỪA — không xoá được thì thêm override `visible = false`)
    for raw in cfg.get("add_nodes", []):
        if (ROOT / rel).read_text(encoding="utf-8").count(raw.splitlines()[0]) > 0:
            continue                      # đã có override -> không thêm lại
        lines = [ln for ln in raw.splitlines()]
        blocks.append(Block(lines[0], lines))

    by_path = resolve_paths(blocks)

    doomed: set[str] = set()
    for target in cfg.get("delete", []):
        if target in by_path:
            doomed.add(target)
        else:
            print("    [bỏ qua] không thấy node %s" % target)
    for parent in cfg.get("delete_children_of", []):
        if parent not in by_path:
            print("    [bỏ qua] không thấy node cha %s" % parent)
            continue
        for block in blocks:
            if block.is_node and block.parent == parent:
                doomed.add(block.path)
    # xoá cả cây con của node bị xoá
    changed = True
    while changed:
        changed = False
        for block in blocks:
            if block.is_node and block.path not in doomed and block.parent in doomed:
                doomed.add(block.path)
                changed = True

    kept = [b for b in blocks if not (b.is_node and b.path in doomed)]
    notes = ["xoá %d node: %s" % (len(doomed), ", ".join(sorted(doomed))) if doomed else "không xoá node"]

    # đặt thuộc tính
    for target, props in cfg.get("set", {}).items():
        block = by_path.get(target)
        if block is None or (block.is_node and block.path in doomed):
            print("    [bỏ qua] không thấy node để set %s" % target)
            continue
        for key, value in props.items():
            line = "%s = %s" % (key, value)
            for i, old in enumerate(block.lines):
                if old.startswith(key + " ") or old.startswith(key + "="):
                    block.lines[i] = line
                    break
            else:
                block.lines.insert(1, line)
        notes.append("set %s: %s" % (target, props))

    # dọn `@export` trên node gốc
    if "exports" in cfg:
        keep = set(cfg["exports"])
        for block in kept:
            if not block.is_node or block.parent not in (".", ""):
                continue
            removals: list[str] = []
            for i, line in enumerate(block.lines):
                m = EXPORT_RE.match(line.strip())
                if m and m.group("key") not in keep:
                    removals.append(m.group("key"))
            for key in removals:
                block.lines = [ln for ln in block.lines
                               if not EXPORT_RE.match(ln.strip()) or EXPORT_RE.match(ln.strip()).group("key") in keep]
            m = NODE_PATHS_RE.search(block.lines[0])
            if m:
                names = [n.strip().strip('"') for n in m.group("list").split(",") if n.strip()]
                names = [n for n in names if n in keep]
                if names:
                    block.lines[0] = NODE_PATHS_RE.sub(
                        'node_paths=PackedStringArray(%s)' % ", ".join('"%s"' % n for n in names),
                        block.lines[0])
                else:
                    block.lines[0] = NODE_PATHS_RE.sub("", block.lines[0]).replace("  ", " ").strip()
            if removals:
                notes.append("bỏ export: %s" % ", ".join(removals))

    # GIỮ NGUYÊN khai báo `[ext_resource]` (không dọn — rủi ro xoá nhầm cái còn dùng);
    # nếu file đang THIẾU khai báo mà node vẫn tham chiếu thì khôi phục lại từ bản git HEAD.
    declared = {_ext_id(b.header) for b in kept if b.header.startswith("[ext_resource")}
    body = "\n".join("\n".join(b.lines) for b in kept if not b.header.startswith("[ext_resource"))
    missing = [i for i in re.findall(r'ExtResource\("([^"]+)"\)', body) if i not in declared]
    if missing:
        restored = _ext_blocks_from_head(rel, set(missing))
        if restored:
            first_node = next((i for i, b in enumerate(kept) if b.is_node), len(kept))
            kept = kept[:first_node] + restored + kept[first_node:]
            notes.append("khôi phục ext_resource: %s" % ", ".join(sorted(missing)))

    newline = "\r\n" if "\r\n" in text else "\n"
    heads = [b for b in kept if not b.is_node]          # [gd_scene] + [ext_resource] + [sub_resource]
    nodes = [b for b in kept if b.is_node]
    parts: list[str] = [newline.join(heads[0].lines)] if heads else []
    if len(heads) > 1:                                   # các ext/sub ghi LIỀN nhau (đúng kiểu Godot)
        parts.append(newline.join(newline.join(b.lines) for b in heads[1:]))
    parts.extend(newline.join(b.lines) for b in nodes)   # node cách nhau 1 dòng trống
    out = (newline + newline).join(parts) + newline

    if dry:
        print("  %s\n    %s" % (rel, "; ".join(notes)))
        return notes

    path.write_text(out, encoding="utf-8")
    print("  ✔ %s\n    %s" % (rel, "; ".join(notes)))
    return notes


def _ext_id(header: str) -> str:
    m = EXT_ID_RE.search(header)
    return m.group(1) if m else ""


def _ext_blocks_from_head(rel: str, ids: set[str]) -> list[Block]:
    """Lấy lại dòng `[ext_resource]` từ bản HEAD (git) cho các id đang bị thiếu."""
    import subprocess

    try:
        out = subprocess.run(["git", "show", "HEAD:%s" % rel], cwd=ROOT, capture_output=True,
                             text=True, encoding="utf-8", check=True).stdout
    except Exception as exc:                     # noqa: BLE001 — thiếu git thì bỏ qua
        print("    [cảnh báo] không đọc được HEAD:%s (%s)" % (rel, exc))
        return []
    blocks: list[Block] = []
    for line in out.splitlines():
        if line.startswith("[ext_resource") and _ext_id(line) in ids:
            blocks.append(Block(line, [line]))
            ids.discard(_ext_id(line))
    return blocks


def main() -> None:
    dry = "--dry" in sys.argv
    print("=== HUD TRIM %s" % ("(dry run)" if dry else ""))
    for rel, cfg in CONFIG.items():
        if not (ROOT / rel).exists():
            print("  !! không thấy %s" % rel)
            continue
        apply(rel, cfg, dry)
    print("=== XONG")


if __name__ == "__main__":
    main()
