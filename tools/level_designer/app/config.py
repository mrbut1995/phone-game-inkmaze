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
CHAPTERS_DIR = PROJECT_ROOT / "resources" / "chapters"

# Đường dẫn script Godot mà file .tres trỏ tới (giữ nguyên như Godot sinh ra)
LEVEL_SCRIPT_RES = "res://scripts/resources/level_data.gd"
# Id ext_resource trong file .tres (Godot dùng id nội bộ, giá trị nào cũng hợp lệ)
LEVEL_SCRIPT_ID = "1_level"

# CHƯƠNG (màn "CHỌN CHƯƠNG" của game) - xem scripts/resources/chapter_data.gd
CHAPTER_SCRIPT_RES = "res://scripts/resources/chapter_data.gd"
CHAPTER_SCRIPT_ID = "1_chapter"
MIN_CHAPTER_ID = 1
MAX_CHAPTER_ID = 99

# Tên chương gợi ý khi tạo tự động theo dữ liệu màn
DEFAULT_CHAPTER_TITLES = (
    "NHẬP MÔN",
    "SUY LUẬN",
    "BẪY ẨN",
    "BẬC THẦY",
    "CỰC HẠN",
)
DEFAULT_CHAPTER_SUBTITLES = (
    "Làm quen với các quy luật bước & tường",
    "Mê cung rộng hơn với mật độ tường tăng cao",
    "Thử thách trí nhớ và khả năng vẽ không chạm tường",
    "Mê cung khổng lồ dành cho cao thủ suy luận",
    "Thử thách giới hạn dành cho người chơi kỳ cựu",
)
# Phí sao mặc định để mở chương (theo thứ tự chương 1..4)
DEFAULT_CHAPTER_COSTS = (0, 25, 45, 70)
# Icon riêng của từng chương (khớp assets/images/chapters/icon_<tên>.svg bên game)
CHAPTER_ICONS = ("intro", "logic", "trap", "master")
# Icon gợi ý cho chương N (ngoài danh sách -> lặp lại theo chu kỳ)
def chapter_icon_for(chapter_id: int) -> str:
    if not CHAPTER_ICONS:
        return ""
    return CHAPTER_ICONS[(max(1, int(chapter_id)) - 1) % len(CHAPTER_ICONS)]

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
    "fading_ink",
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
TOOL_CELL = "cell"

TOOL_LABELS = (
    (TOOL_WALL_VISIBLE, "Tường hiện (1)"),
    (TOOL_WALL_HIDDEN, "Tường ẩn (2)"),
    (TOOL_ERASE, "Xoá tường (3)"),
    (TOOL_START, "Điểm S (4)"),
    (TOOL_END, "Đích F (5)"),
    (TOOL_CELL, "Sửa ô board (6)"),
)

# --- Hàm tiện ích ----------------------------------------------------------
def ensure_levels_dir() -> Path:
    """Tạo thư mục resources/levels nếu chưa có và trả về đường dẫn."""
    LEVELS_DIR.mkdir(parents=True, exist_ok=True)
    return LEVELS_DIR


def ensure_chapters_dir() -> Path:
    """Tạo thư mục resources/chapters nếu chưa có và trả về đường dẫn."""
    CHAPTERS_DIR.mkdir(parents=True, exist_ok=True)
    return CHAPTERS_DIR


def default_chapter_meta(chapter_id: int) -> tuple[str, str, int]:
    """(tiêu đề, mô tả, phí sao) gợi ý cho chương N khi tạo mới."""
    index = max(0, int(chapter_id) - 1)
    title = DEFAULT_CHAPTER_TITLES[index] if index < len(DEFAULT_CHAPTER_TITLES) \
        else "CHƯƠNG %d" % chapter_id
    subtitle = DEFAULT_CHAPTER_SUBTITLES[index] if index < len(DEFAULT_CHAPTER_SUBTITLES) \
        else ""
    cost = DEFAULT_CHAPTER_COSTS[index] if index < len(DEFAULT_CHAPTER_COSTS) \
        else 25 + 15 * index
    return title, subtitle, cost


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
