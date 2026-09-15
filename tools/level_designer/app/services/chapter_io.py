"""Service: đọc/ghi resource .tres của Godot 4 cho ChapterData.

Format giống hệt file do game sinh ra (resources/chapters/chapter_N.tres):

    [gd_resource type="Resource" script_class="ChapterData" load_steps=2 format=3 uid="uid://..."]
    [ext_resource type="Script" path="res://scripts/resources/chapter_data.gd" id="1_chapter"]
    [resource]
    script = ExtResource("1_chapter")
    chapter_id = 1
    title = "NHẬP MÔN"
    subtitle = "..."
    size_label = "3×3 – 5×5"
    star_cost = 0
    icon = "intro"
"""

from __future__ import annotations

import re
from pathlib import Path

from ..config import CHAPTER_SCRIPT_ID, CHAPTER_SCRIPT_RES
from ..models.chapter import ChapterModel

_HEADER = '[gd_resource type="Resource" script_class="ChapterData" load_steps=2 format=3'
_EXT = '[ext_resource type="Script" path="%s" id="%s"]' % (CHAPTER_SCRIPT_RES, CHAPTER_SCRIPT_ID)


# ---------------------------------------------------------------------------
# Ghi file
# ---------------------------------------------------------------------------
def dumps(chapter: ChapterModel) -> str:
    """Chuyển ChapterModel thành nội dung file .tres (đúng định dạng Godot 4)."""
    chapter.normalized()
    header = _HEADER
    if chapter.source_uid:
        header += ' uid="%s"' % chapter.source_uid
    header += "]"

    lines = [
        header,
        "",
        _EXT,
        "",
        "[resource]",
        'script = ExtResource("%s")' % CHAPTER_SCRIPT_ID,
        "chapter_id = %d" % int(chapter.chapter_id),
        "title = %s" % _gd_string(chapter.title),
        "subtitle = %s" % _gd_string(chapter.subtitle),
        "size_label = %s" % _gd_string(chapter.size_label),
        "star_cost = %d" % int(chapter.star_cost),
        "icon = %s" % _gd_string(chapter.icon),
    ]
    return "\n".join(lines) + "\n"


def save_file(chapter: ChapterModel, path: Path) -> None:
    """Ghi chương xuống file .tres (tạo thư mục cha nếu cần)."""
    path.parent.mkdir(parents=True, exist_ok=True)
    # Godot đọc UTF-8; dùng newline \n để file giống hệt định dạng chuẩn
    path.write_text(dumps(chapter), encoding="utf-8", newline="\n")


# ---------------------------------------------------------------------------
# Đọc file
# ---------------------------------------------------------------------------
def loads(text: str) -> ChapterModel:
    """Phân tích nội dung .tres thành ChapterModel (bỏ qua phần không nhận biết)."""
    chapter = ChapterModel()

    uid_match = re.search(r'\[gd_resource[^\]]*uid="([^"]+)"', text)
    if uid_match:
        chapter.source_uid = uid_match.group(1)

    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line or line.startswith("[") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        key = key.strip()
        value = value.strip()

        if key == "chapter_id":
            chapter.chapter_id = _to_int(value, 1)
        elif key == "title":
            chapter.title = _parse_gd_string(value)
        elif key == "subtitle":
            chapter.subtitle = _parse_gd_string(value)
        elif key == "size_label":
            chapter.size_label = _parse_gd_string(value)
        elif key == "star_cost":
            chapter.star_cost = _to_int(value, 0)
        elif key == "icon":
            chapter.icon = _parse_gd_string(value)

    return chapter.normalized()


def load_file(path: Path) -> ChapterModel:
    """Đọc file .tres chương từ đĩa."""
    chapter = loads(Path(path).read_text(encoding="utf-8", errors="replace"))
    chapter.source_path = str(path)
    return chapter


# ---------------------------------------------------------------------------
# Helper chuỗi kiểu Godot
# ---------------------------------------------------------------------------
def _gd_string(value: str) -> str:
    """Chuỗi Godot: bọc nháy kép, escape \\ " và ký tự xuống dòng."""
    escaped = (
        str(value)
        .replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("\n", "\\n")
        .replace("\r", "\\r")
        .replace("\t", "\\t")
    )
    return '"%s"' % escaped


def _parse_gd_string(value: str) -> str:
    """Bỏ nháy kép + giải escape của chuỗi Godot."""
    text = value.strip()
    if len(text) >= 2 and text.startswith('"') and text.endswith('"'):
        text = text[1:-1]
    return (
        text.replace('\\"', '"')
        .replace("\\n", "\n")
        .replace("\\r", "\r")
        .replace("\\t", "\t")
        .replace("\\\\", "\\")
    )


def _to_int(value: str, fallback: int) -> int:
    try:
        return int(float(value))
    except (TypeError, ValueError):
        return fallback
