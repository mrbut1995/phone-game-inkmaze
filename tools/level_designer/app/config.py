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
LEVEL_SCRIPT_RES = "res://scripts/data/level_data.gd"
# Id ext_resource trong file .tres (Godot dùng id nội bộ, giá trị nào cũng hợp lệ)
LEVEL_SCRIPT_ID = "1_level"

# CHƯƠNG (màn "CHỌN CHƯƠNG" của game) - xem scripts/resources/chapter_data.gd
CHAPTER_SCRIPT_RES = "res://scripts/data/chapter_data.gd"
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
    "Nhiệm vụ trí nhớ và khả năng vẽ không chạm tường",
    "Mê cung khổng lồ dành cho cao thủ suy luận",
    "Nhiệm vụ giới hạn dành cho người chơi kỳ cựu",
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
## Chế độ CHỌN ĐƯỢC cho 1 MÀN. KHÔNG có "dungeon": đó là chế độ BẤT TẬN, chỉ chơi từ Main Screen
## (file cũ lỡ khai `dungeon` sẽ bị game coi như "play" — xem RETIRED_MODE_IDS).
MODE_IDS = (
    "play",
    "blind_memory",
    "wall_builder",
    "challenge",
)
## 6 chế độ đã bị XOÁ khỏi game (đợt tái cấu trúc: bỏ gần hết mode). Màn cũ còn khai các id này thì
## validator báo LỖI — phải đổi sang "play"/"challenge" (Fog of War nay là LUẬT thử thách `fog_of_war`).
REMOVED_MODE_IDS = (
    "minesweeper",
    "sum_path",
    "countdown_cost",
    "fading_ink",
    "one_stroke",
    "fog_of_war",
)
## Chế độ KHÔNG dùng được cho màn nhưng vẫn có thể gặp trong file cũ → validator báo LỖI rõ ràng
RETIRED_MODE_IDS = ("dungeon",) + REMOVED_MODE_IDS

# --- CHẾ ĐỘ SPECIAL chạy TRÊN MÀN (khớp scripts/modes/*.gd bên game) ----------
# Màn khai `mode_id` khác "play" sẽ được game chạy bằng chế độ đó TRÊN ĐÚNG BÀN NÀY:
#   · Dùng nguyên tường + hình dạng board (cell_mask) do tool vẽ.
#   · Chỉ còn 2 chế độ Special: Blind Memory · Wall Builder (Fog of War nay là LUẬT thử thách).
PLAY_MODE_ID = "play"
MODE_LABELS = {
    "play": "Play — mê cung thường (mặc định)",
    "blind_memory": "Blind Memory — nhớ màn rồi đi (tường tự ẩn lại)",
    "wall_builder": "Wall Builder — suy luận lại toàn bộ tường từ các con số",
    "challenge": "Challenge — 1 luật thử thách, vi phạm là thua ngay",
}
# Mode mà game ÉP trạng thái hiện/ẩn của tường khi chơi trên màn (xem MazeData.set_all_walls_visible)
MODE_WALL_VISIBILITY_OVERRIDE = {
    "blind_memory": "hidden",
    "wall_builder": "hidden",
}
# Mode mà người chơi BUỘC PHẢI thấy tường để tính đường (validator sẽ cảnh báo nếu màn còn tường ẩn)
MODES_NEEDING_VISIBLE_WALLS: tuple[str, ...] = ()

# --- KIỂU EDIT RIÊNG THEO CHẾ ĐỘ -------------------------------------------
# Mỗi chế độ có 1 "kiểu edit" — nhà thiết kế dùng công cụ 7 để tô dữ liệu riêng của chế độ đó
# (lưu vào `custom_cell_values` của file .tres, khoá "x,y"). Ô nào KHÔNG tô = chế độ tự sinh.
TOOL_VALUE = "value"
TOOL_VALUE_KEY = "7"
# kind = "none"       : chỉ vẽ tường/ô board/S/F — dữ liệu còn lại do game tự sinh
# kind = "cell_value" : tô 1 giá trị số cho từng ô (min..max) — game đọc đúng giá trị đã tô
MODE_EDITS = {
    "play": {
        "kind": "none",
        "note": "Mê cung thường: tường (hiện/ẩn) + ô board + S/F + nhiệm vụ là đủ.",
    },
    "blind_memory": {
        "kind": "none",
        "note": "Tường của màn dùng cho pha GHI NHỚ; game tự ẩn lại khi hết đếm ngược.",
    },
    "wall_builder": {
        "kind": "none",
        "note": "Số trên ô suy từ CHÍNH tường của màn — vẽ tường đủ nhiều để bàn đáng suy luận.",
    },
    "challenge": {
        "kind": "none",
        "note": "Chơi như Play Mode nhưng phải theo 1 LUẬT — chọn luật + tham số ở khối "
                "\"Thử thách (Challenge)\" bên dưới. Vi phạm luật là thua ngay; "
                "2 luật \"chỉ đi trên ô có số/không số\" cần màn CÓ đường hợp lệ (validator kiểm tra).",
    },
}


def mode_edit_spec(mode_id: str) -> dict:
    """Kiểu edit của 1 chế độ (đã điền giá trị mặc định của 'none' + phần 'path')."""
    spec = dict(MODE_EDITS.get(str(mode_id or PLAY_MODE_ID).strip().lower(),
                               MODE_EDITS[PLAY_MODE_ID]))
    spec.setdefault("tool", "")
    spec.setdefault("min", 0)
    spec.setdefault("max", 0)
    spec.setdefault("default", 0)
    spec.setdefault("unit", "")
    spec.setdefault("note", "")
    spec["mode_id"] = str(mode_id or PLAY_MODE_ID)
    spec["is_cell_value"] = spec.get("kind") == "cell_value"

    # HÀNH ĐỘNG CỦA CÔNG CỤ 8 (Ctrl+Enter) trên nét đường đang vẽ:
    #   · action "walls"  — sinh tường quanh đường (mọi chế độ không có 'path')
    #   · action "values" — TÔ GIÁ TRỊ cho các ô của đường:
    #         fill "sum"  : tổng các giá trị = đúng ô "Tổng …" trên thanh công cụ
    #         fill "step" : giá trị tăng dần theo bước đi (mực của Fading Ink)
    path = spec.get("path") or {}
    spec["path_action"] = str(path.get("action", "walls"))
    spec["path_fill"] = str(path.get("fill", ""))
    spec["sum_label"] = str(path.get("sum_label", ""))
    spec["sum_min"] = int(path.get("sum_min", 0))
    spec["sum_max"] = int(path.get("sum_max", 999))
    spec["sum_default"] = int(path.get("sum_default", 0))
    spec["has_sum_field"] = bool(spec["sum_label"])
    spec["paints_values"] = spec["path_action"] == "values"
    ## Chế độ mà TỔNG giá trị = SỐ BƯỚC của đường (Countdown Cost) ⇒ tự nâng `max_steps` theo tổng
    spec["budget_from_sum"] = bool(path.get("budget_from_sum", False))
    return spec

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
COLOR_PATH_DRAFT = "#8E44AD"
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

# --- VẼ ĐƯỜNG ĐI (công cụ 8) ----------------------------------------------
# Kéo chuột vẽ 1 nét đường S→F (chỉ nối ô kề, không nhảy ô, không đi đè).
# Bấm "Sinh tường quanh đường" (Ctrl+Enter) → màn chơi được sinh từ nét vẽ:
#   · S = ô đầu nét vẽ · F = ô cuối nét vẽ
#   · mọi cạnh BÊN HÔNG của đường thành tường → đường đã vẽ là ĐƯỜNG DUY NHẤT
#   · max_steps = số bước của nét vẽ + PATH_WALL_EXTRA_STEPS
TOOL_PATH = "path"
TOOL_PATH_KEY = "8"
PATH_WALL_EXTRA_STEPS = 2

TOOL_LABELS = (
    (TOOL_WALL_VISIBLE, "Tường hiện (1)"),
    (TOOL_WALL_HIDDEN, "Tường ẩn (2)"),
    (TOOL_ERASE, "Xoá tường (3)"),
    (TOOL_START, "Điểm S (4)"),
    (TOOL_END, "Đích F (5)"),
    (TOOL_CELL, "Sửa ô board (6)"),
    (TOOL_PATH, "Vẽ đường đi (%s)" % TOOL_PATH_KEY),
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
