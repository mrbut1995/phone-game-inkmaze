"""Cấu hình chung của Level Designer (đường dẫn, hằng số, màu sắc giao diện)."""

from __future__ import annotations

import os
from pathlib import Path

APP_NAME = "InkMaze Level Designer"
APP_VERSION = "1.0.0"

# --- Đường dẫn dự án -------------------------------------------------------
def _find_project_root() -> Path:
    """Tìm thư mục gốc game (nơi có project.godot).

    Ưu tiên: biến môi trường INKMAZE_PROJECT_ROOT -> đi ngược từ file hiện tại
    -> đi ngược từ file .exe (khi chạy bản đã build).
    """
    env = os.environ.get("INKMAZE_PROJECT_ROOT")
    if env and (Path(env) / "project.godot").exists():
        return Path(env)

    starts: list[Path] = []
    if getattr(__import__("sys"), "frozen", False):  # chạy từ .exe PyInstaller
        starts.append(Path(__import__("sys").executable).resolve().parent)
    starts.append(Path(__file__).resolve().parent)

    for start in starts:
        for candidate in [start, *start.parents]:
            if (candidate / "project.godot").exists():
                return candidate
    return Path(__file__).resolve().parents[3]


PROJECT_ROOT = _find_project_root()
LEVELS_DIR = PROJECT_ROOT / "resources" / "levels"

# Đường dẫn script Godot mà file .tres trỏ tới (giữ nguyên như Godot sinh ra)
LEVEL_SCRIPT_RES = "res://scripts/resources/level_data.gd"
# Id ext_resource trong file .tres (Godot dùng id nội bộ, giá trị nào cũng hợp lệ)
LEVEL_SCRIPT_ID = "1_level"

# --- Giới hạn thiết kế -----------------------------------------------------
MIN_SIZE = 2
MAX_SIZE = 20
MIN_ID = 1
MAX_ID = 999
DIFFICULTIES = ("easy", "medium", "hard")
MODE_IDS = (
    "play",
    "dungeon",
    "time_attack",
    "minesweeper",
    "sum_path",
    "countdown_cost",
    "blind_memory",
    "fog_of_war",
    "area",
)

# --- Màu sắc (đồng bộ với theme sổ ô ly của game) --------------------------
COLOR_PAPER = "#FEFDFA"
COLOR_PAPER_ALT = "#FAF5EB"
COLOR_GRID = "#DCE9F2"
COLOR_MARGIN = "#D84444"
COLOR_INK = "#224C6D"
COLOR_INK_SOFT = "#6EA0C8"
COLOR_WALL_VISIBLE = "#224C6D"
COLOR_WALL_HIDDEN = "#D84444"
COLOR_START = "#2E7D32"
COLOR_END = "#D8243C"
COLOR_PATH = "#3D83AE"
COLOR_SELECT = "#F59E0B"
COLOR_CANVAS_BG = "#F3EFE6"

CELL_SIZE_DEFAULT = 120
CELL_SIZE_MIN = 48
CELL_SIZE_MAX = 260

# --- Tên công cụ -----------------------------------------------------------
TOOL_WALL_VISIBLE = "wall_visible"
TOOL_WALL_HIDDEN = "wall_hidden"
TOOL_ERASE = "erase"
TOOL_START = "start"
TOOL_END = "end"

TOOL_LABELS = (
    (TOOL_WALL_VISIBLE, "Tường hiện (1)"),
    (TOOL_WALL_HIDDEN, "Tường ẩn (2)"),
    (TOOL_ERASE, "Xoá tường (3)"),
    (TOOL_START, "Điểm S (4)"),
    (TOOL_END, "Đích F (5)"),
)

# --- Hàm tiện ích ----------------------------------------------------------
def ensure_levels_dir() -> Path:
    """Tạo thư mục resources/levels nếu chưa có và trả về đường dẫn."""
    LEVELS_DIR.mkdir(parents=True, exist_ok=True)
    return LEVELS_DIR


def is_frozen() -> bool:
    """True khi đang chạy từ file .exe đã build bằng PyInstaller."""
    return bool(getattr(__import__("sys"), "frozen", False))


def tool_dir() -> Path:
    """Thư mục của tool: chứa main.py (khi chạy source) hoặc LevelDesigner.exe (khi đã build)."""
    if is_frozen():
        exe_dir = Path(__import__("sys").executable).resolve().parent
        # Bản build nằm trong dist/ -> dùng thư mục cha cho gọn
        if exe_dir.name.lower() in ("dist", "release", "release_win"):
            return exe_dir.parent
        return exe_dir
    return Path(__file__).resolve().parents[1]


def default_output_dir() -> Path:
    """Thư mục mặc định cho các file xuất ra (không đụng vào resources/levels)."""
    return tool_dir() / "out"


def project_root_hint() -> str:
    """Chuỗi gợi ý đường dẫn dự án (dùng cho giao diện/thông báo)."""
    return str(PROJECT_ROOT)
