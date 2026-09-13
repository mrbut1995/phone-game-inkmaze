"""Service: đọc/ghi resource .tres của Godot 4 cho LevelData.

Format tham chiếu (do Godot sinh ra):

    [gd_resource type="Resource" script_class="LevelData" format=3 uid="uid://..."]
    [ext_resource type="Script" path="res://scripts/resources/level_data.gd" id="1_hndnq"]
    [resource]
    script = ExtResource("1_hndnq")
    level_id = 3
    level_title = "Level 1-3"
    ...
    v_walls = PackedByteArray(1, 1, 0, ...)
    custom_cell_values = {}
"""

from __future__ import annotations

import re
from pathlib import Path

from ..config import LEVEL_SCRIPT_ID, LEVEL_SCRIPT_RES
from ..models.level import LevelModel

_HEADER = '[gd_resource type="Resource" script_class="LevelData" load_steps=2 format=3'
_EXT = '[ext_resource type="Script" path="%s" id="%s"]' % (LEVEL_SCRIPT_RES, LEVEL_SCRIPT_ID)


# ---------------------------------------------------------------------------
# Ghi file
# ---------------------------------------------------------------------------
def dumps(level: LevelModel) -> str:
    """Chuyển LevelModel thành nội dung file .tres (đúng định dạng Godot 4)."""
    header = _HEADER
    if level.source_uid:
        header += ' uid="%s"' % level.source_uid
    header += "]"

    lines = [
        header,
        "",
        _EXT,
        "",
        "[resource]",
        'script = ExtResource("%s")' % LEVEL_SCRIPT_ID,
        "level_id = %d" % int(level.level_id),
        "level_title = %s" % _gd_string(level.level_title),
        "chapter = %d" % int(level.chapter),
        "mode_id = %s" % _gd_string(level.mode_id),
        "difficulty = %s" % _gd_string(level.difficulty),
        "width = %d" % int(level.width),
        "height = %d" % int(level.height),
        "start_pos = Vector2i(%d, %d)" % (int(level.start[0]), int(level.start[1])),
        "end_pos = Vector2i(%d, %d)" % (int(level.end[0]), int(level.end[1])),
        "max_steps = %d" % int(level.max_steps),
        "par_time = %s" % _gd_float(level.par_time),
        "v_walls = %s" % _gd_bytes(level.v_walls),
        "v_walls_visible = %s" % _gd_bytes(level.v_walls_visible),
        "h_walls = %s" % _gd_bytes(level.h_walls),
        "h_walls_visible = %s" % _gd_bytes(level.h_walls_visible),
        "custom_cell_values = %s" % (level.custom_cell_values_raw or "{}"),
    ]
    return "\n".join(lines) + "\n"


def save_file(level: LevelModel, path: Path) -> None:
    """Ghi level xuống file .tres (tạo thư mục cha nếu cần)."""
    path.parent.mkdir(parents=True, exist_ok=True)
    # Godot đọc UTF-8; dùng newline \n để file giống hệt định dạng chuẩn
    path.write_text(dumps(level), encoding="utf-8", newline="\n")


# ---------------------------------------------------------------------------
# Đọc file
# ---------------------------------------------------------------------------
def loads(text: str) -> LevelModel:
    """Phân tích nội dung .tres thành LevelModel (bỏ qua phần không nhận biết)."""
    level = LevelModel(custom_cell_values_raw="{}")

    uid_match = re.search(r'\[gd_resource[^\]]*uid="([^"]+)"', text)
    if uid_match:
        level.source_uid = uid_match.group(1)

    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line or line.startswith("[") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        key = key.strip()
        value = value.strip()

        if key == "level_id":
            level.level_id = _to_int(value, 1)
        elif key == "level_title":
            level.level_title = _parse_gd_string(value)
        elif key == "chapter":
            level.chapter = _to_int(value, 1)
        elif key == "mode_id":
            level.mode_id = _parse_gd_string(value)
        elif key == "difficulty":
            level.difficulty = _parse_gd_string(value)
        elif key == "width":
            level.width = max(2, _to_int(value, 3))
        elif key == "height":
            level.height = max(2, _to_int(value, 3))
        elif key == "start_pos":
            level.start = _parse_vector2i(value, (0, 0))
        elif key == "end_pos":
            level.end = _parse_vector2i(value, (1, 0))
        elif key == "max_steps":
            level.max_steps = _to_int(value, 15)
        elif key == "par_time":
            level.par_time = _to_float(value, 45.0)
        elif key == "v_walls":
            level.v_walls = _parse_bytes(value)
        elif key == "v_walls_visible":
            level.v_walls_visible = _parse_bytes(value)
        elif key == "h_walls":
            level.h_walls = _parse_bytes(value)
        elif key == "h_walls_visible":
            level.h_walls_visible = _parse_bytes(value)
        elif key == "custom_cell_values":
            level.custom_cell_values_raw = value or "{}"

    level.normalize_arrays()
    level.ensure_borders()
    return level


def load_file(path: Path) -> LevelModel:
    level = loads(Path(path).read_text(encoding="utf-8"))
    level.source_path = str(path)
    return level


# ---------------------------------------------------------------------------
# Tiện ích định dạng giá trị kiểu GDScript
# ---------------------------------------------------------------------------
def _gd_string(value: str) -> str:
    escaped = str(value).replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")
    return '"%s"' % escaped


def _gd_float(value: float) -> str:
    """Godot ghi số thực luôn kèm phần thập phân: 30.0 chứ không phải 30."""
    text = ("%.4f" % float(value)).rstrip("0")
    if text.endswith("."):
        text += "0"
    return text or "0.0"


def _gd_bytes(values: list[int]) -> str:
    return "PackedByteArray(%s)" % ", ".join(str(1 if int(v) else 0) for v in values)


def _parse_gd_string(value: str) -> str:
    text = value.strip()
    if len(text) >= 2 and text[0] == '"' and text[-1] == '"':
        text = text[1:-1]
    return text.replace("\\n", "\n").replace('\\"', '"').replace("\\\\", "\\")


def _to_int(value: str, fallback: int) -> int:
    try:
        return int(float(value))
    except (TypeError, ValueError):
        return fallback


def _to_float(value: str, fallback: float) -> float:
    try:
        return float(value)
    except (TypeError, ValueError):
        return fallback


def _parse_vector2i(value: str, fallback: tuple[int, int]) -> tuple[int, int]:
    match = re.search(r"Vector2i\(\s*(-?\d+)\s*,\s*(-?\d+)\s*\)", value)
    if not match:
        return fallback
    return (int(match.group(1)), int(match.group(2)))


def _parse_bytes(value: str) -> list[int]:
    match = re.search(r"PackedByteArray\((.*)\)", value, re.DOTALL)
    if not match:
        return []
    body = match.group(1).strip()
    if not body:
        return []
    return [1 if int(part.strip()) else 0 for part in body.split(",") if part.strip()]
