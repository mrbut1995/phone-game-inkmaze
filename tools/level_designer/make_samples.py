"""Tạo các MÀN MẪU dùng board dạng POLYOMINO (cell_mask) cho game InkMaze.

Chạy:
    cd tools/level_designer
    python make_samples.py            # ghi các màn mẫu vào resources/levels/
    python make_samples.py --dry-run  # chỉ in kết quả kiểm tra, không ghi file
    python make_samples.py --only 13  # chỉ ghi 1 (hoặc vài) màn mẫu: --only 13,14

Màn mẫu nằm ở chương 2 (level_10..level_17) nên không đụng 9 màn gốc của chương 1.
Mỗi màn đều được kiểm tra bằng validator: PHẢI có đường đi từ S tới F.

Khóa `"mode"` trong `SAMPLES` = CHẾ ĐỘ CHƠI của màn (mặc định "play"):
    · "play"          — mê cung thường.
    · id Special khác — game chạy chế độ đó TRÊN ĐÚNG BÀN NÀY (xem app/config.py + README).
      Màn 15 = blind_memory, màn 16 = wall_builder là 2 màn mẫu cho tính năng này.

Khóa `"challenge"` = LUẬT THỬ THÁCH (chỉ dùng khi "mode": "challenge"): (id_luật, tham_số).
    · id: countdown · move_limit · step_timer · no_tool · no_move_overlapped ·
          walk_number_only · walk_empty_only · backtrack_limit · fog_of_war
          (xem app/models/challenge_rules.py)
    · tham số 0 = game tự tính theo luật/bàn cờ/độ khó.
    Màn 13 = challenge "chỉ đi trên ô có số" · màn 14 = challenge "fog_of_war" — validator kiểm tra
    màn CÓ đường hợp lệ.

Khóa `"custom_values"` = KIỂU EDIT RIÊNG của chế độ: {(x, y): giá trị} (hiện không chế độ nào dùng).

Khóa `"lock_cells"` / `"key_cells"` = Ô KHOÁ + CHÌA: danh sách bộ ba (x, y, id) — xem README mục 5.
Mỗi id khoá phải có ít nhất 1 chìa; khoá/chìa không đặt trên S/F; validator kiểm có đường S→F.

Khóa `"path_values"` = TÔ GIÁ TRỊ THEO ĐƯỜNG ĐI (giống nút Ctrl+Enter của công cụ 8 trong tool):
    {"fill": "sum",  "value": N} — chia giá trị trên đường NGẮN NHẤT sao cho TỔNG = N
    {"fill": "step", "value": N} — giá trị tăng dần theo bước: ô ở bước j nhận j + N
Ô S/F không tô (game cũng không tính 2 ô này).
"""

from __future__ import annotations

import sys
from pathlib import Path

# Console Windows khi bị pipe có thể dùng cp1252 -> ép UTF-8 để in tiếng Việt
for stream in (sys.stdout, sys.stderr):
    if stream is not None and hasattr(stream, "reconfigure"):
        try:
            stream.reconfigure(encoding="utf-8", errors="replace")
        except Exception:  # noqa: BLE001
            pass

APP_DIR = Path(__file__).resolve().parent
if str(APP_DIR) not in sys.path:
    sys.path.insert(0, str(APP_DIR))

from app.models import missions as chal  # noqa: E402
from app.models.repository import LevelRepository  # noqa: E402
from app.config import mode_edit_spec  # noqa: E402
from app.services import path_values, solver, validator  # noqa: E402

# "#" = ô thuộc board, "." = ô trống (ngoài board)
SAMPLES: dict[int, dict] = {
    10: {
        "title": "Level 2-1 · Chữ H (polyomino)",
        "difficulty": "easy",
        "chapter": 2,
        "shape": [
            "####",
            ".##.",
            "####",
        ],
        "start": (0, 2),
        "end": (3, 0),
        "walls": [
            ("h", 2, 1, False),    # tường ẩn: chặn lối lên của ô (2,0)
            ("h", 2, 2, True),     # tường hiện: chặn lối xuống của ô (2,1)
        ],
        # Nhiệm vụ: param 0 = tự lấy theo max_steps/par_time của màn
        "missions": [
            (chal.NO_WALL, 0),
            (chal.STEPS_MAX, 0),
            (chal.NO_HINT, 0),
        ],
    },
    11: {
        "title": "Level 2-2 · Thập tự (polyomino)",
        "difficulty": "easy",
        "chapter": 2,
        "shape": [
            ".##.",
            "####",
            "####",
            ".##.",
        ],
        "start": (1, 3),
        "end": (2, 0),
        "walls": [
            ("v", 2, 2, False),    # tường ẩn giữa (1,2) và (2,2)
            ("h", 0, 1, True),     # tường hiện dưới ô (0,0)
            ("h", 0, 2, True),     # tường hiện dưới ô (0,1)
            ("v", 3, 1, False),    # tường ẩn giữa (2,1) và (3,1)
        ],
        "missions": [
            (chal.NO_WALL, 0),
            (chal.STEPS_MAX, 0),
            (chal.TIME_MAX, 0),
        ],
    },
    12: {
        "title": "Level 2-3 · Vòng 2 ô (có lỗ giữa)",
        "difficulty": "medium",
        "chapter": 2,
        "shape": [
            "######",
            "######",
            "##..##",
            "##..##",
            "######",
            "######",
        ],
        "start": (0, 0),
        "end": (5, 5),
        "walls": [
            ("h", 0, 2, True),     # tường hiện ở hành lang trái
            ("h", 1, 3, False),    # tường ẩn ở hành lang trái (lệch nhịp)
            ("v", 3, 4, True),     # tường hiện ở hành lang dưới
            ("v", 4, 5, False),    # tường ẩn ở hành lang dưới
            ("h", 4, 2, True),     # tường hiện ở hành lang phải
            ("h", 5, 3, False),    # tường ẩn ở hành lang phải
            ("v", 1, 0, False),    # tường ẩn ở hành lang trên
            ("v", 2, 1, True),     # tường hiện ở hành lang trên
        ],
        "missions": [
            (chal.NO_WALL, 0),
            (chal.NO_REVISIT, 0),
            (chal.LEN_MAX_PERCENT, 80),
        ],
    },
    13: {
        # M?N M?U CHALLENGE MODE: 1 lu?t th? th?ch ? vi ph?m l? thua ngay.
        # Lu?t "ch? ?i tr?n ? C? s?": c?c ? tr?n ???ng S?F ??u c? ?1 t??ng quanh n?
        # (? hi?n s?), c?n l?i ???ng n?o qua ? KH?NG s? c?ng kh?ng b? ch?n k?n.
        "title": "Level 2-4 ? Challenge ? ch? ?i tr?n ? c? s?",
        "difficulty": "medium",
        "chapter": 2,
        "mode": "challenge",
        # id lu?t + tham s? (0 = game t? t?nh; lu?t n?y kh?ng c?n tham s?)
        "challenge": ("walk_number_only", 0),
        "shape": ["######"] * 5,
        "start": (0, 4),
        "end": (5, 0),
        "walls": [
            # Cho c?c ? h?ng d??i (1,4)..(3,4) m?i ? 1 t??ng ph?a tr?n ? c? s?
            ("h", 1, 4, True),
            ("h", 2, 4, True),
            ("h", 3, 4, True),
            # Ch?n l?i r? ph?i ? (4,4) + cho (4,4) c? s?
            ("v", 5, 4, True),
            # C?t x=4 ?i l?n: m?i ? 1 t??ng b?n tr?i ? c? s?; (4,0) r? ph?i t?i F
            ("v", 4, 3, True),
            ("v", 4, 2, True),
            ("v", 4, 1, True),
            ("v", 4, 0, True),
        ],
    },
    14: {
        # CHALLENGE "fog_of_war": tr??c ??y l? ch? ?? ri?ng, nay ch? l? LU?T th? th?ch
        # (ch? th?y ? quanh nh?n v?t) ? b?n ch?i y nh? Play Mode.
        "title": "Level 2-5 ? Challenge ? s??ng m? quanh nh?n v?t",
        "difficulty": "medium",
        "chapter": 2,
        "mode": "challenge",
        "challenge": ("fog_of_war", 0),
        "shape": ["######"] * 6,
        "start": (0, 5),
        "end": (5, 0),
        "walls": [
            ("v", 2, 5, True),
            ("v", 2, 4, True),
            ("h", 3, 4, True),
            ("h", 1, 3, True),
            ("v", 4, 3, True),
            ("h", 4, 2, True),
            ("v", 3, 1, True),
            ("h", 2, 1, True),
            ("h", 5, 5, True),
        ],
    },
    15: {
        "title": "Level 2-6 ? Blind Memory ? nh? m?n r?i ?i",
        "difficulty": "hard",
        "chapter": 2,
        "mode": "blind_memory",
        "shape": ["######"] * 6,
        "start": (0, 5),
        "end": (5, 0),
        "walls": [
            ("v", 2, 5, True),
            ("v", 2, 4, True),
            ("h", 3, 4, True),
            ("h", 1, 3, True),
            ("v", 4, 3, True),
            ("h", 4, 2, True),
            ("v", 3, 1, True),
            ("h", 2, 1, True),
            ("h", 5, 5, True),
        ],
        "missions": [
            (chal.NO_WALL, 0),
            (chal.NO_HINT, 0),
        ],
    },
    16: {
        "title": "Level 2-7 ? Wall Builder ? suy lu?n l?i t??ng",
        "difficulty": "hard",
        "chapter": 2,
        "mode": "wall_builder",
        "shape": ["######"] * 5,
        "start": (0, 4),
        "end": (5, 0),
        "walls": [
            ("v", 1, 4, False),
            ("v", 2, 3, False),
            ("h", 2, 4, False),
            ("h", 3, 3, False),
            ("v", 4, 4, False),
            ("h", 5, 4, False),
            ("v", 3, 2, False),
            ("h", 1, 3, False),
            ("h", 4, 2, False),
            ("v", 5, 2, False),
            ("v", 2, 1, False),
            ("h", 2, 1, False),
        ],
    },
    17: {
        # Ô KHOÁ + CHÌA: tường dọc chia bàn làm 2 nửa, chỉ chừa 1 cửa ở hàng y=2 và
        # đặt Ô KHOÁ id 1 ngay cửa đó → buộc phải vòng về (0,0) nhặt chÌa rồi mới qua được.
        "title": "Level 2-8 · Ô khoá & chìa khoá",
        "difficulty": "medium",
        "chapter": 2,
        "mode": "play",
        "shape": ["#####"] * 4,
        "start": (0, 3),
        "end": (4, 0),
        "walls": [
            ("v", 2, 0, True),
            ("v", 2, 1, True),
            ("v", 2, 3, True),
        ],
        "lock_cells": [
            (2, 2, 1),
        ],
        "key_cells": [
            (0, 0, 1),
        ],
        "missions": [
            (chal.NO_WALL, 0),
            (chal.NO_TELEPORT, 0),
        ],
    },
}


def build_sample(sample: dict) -> object:
    """Tạo LevelModel cho 1 màn mẫu (chưa lưu)."""
    shape = sample["shape"]
    height = len(shape)
    width = max(len(row) for row in shape)

    repo = LevelRepository()
    level = repo.create_level(int(sample["_id"]), width, height)
    level.level_title = str(sample["title"])
    level.difficulty = str(sample["difficulty"])
    level.chapter = int(sample["chapter"])
    # "mode" = chế độ chơi của màn ("play" = mê cung thường; id khác = chế độ Special trên bàn này)
    level.mode_id = str(sample.get("mode", "play"))

    # 1. Hình dạng board: ô nào thuộc board
    for y, row in enumerate(shape):
        for x in range(width):
            inside = x < len(row) and row[x] == "#"
            level.set_cell_active((x, y), inside)

    # 2. S / F (ép về ô thuộc board gần nhất nếu lỡ nằm ngoài)
    level.start = level.nearest_active_cell(tuple(sample["start"]))
    level.end = level.nearest_active_cell(tuple(sample["end"]))

    # 3. Tường trong board
    for kind, ix, iy, visible in sample["walls"]:
        level.set_wall((kind, int(ix), int(iy)), True, bool(visible))

    # 3b. Ô KHOÁ + CHÌA KHOÁ (bộ ba x,y,id) — khớp LevelData.lock_cells / key_cells
    for x, y, lock_id in sample.get("lock_cells", []):
        if not level.add_lock((int(x), int(y)), int(lock_id)):
            raise ValueError("ô khoá không hợp lệ: %s" % ((x, y, lock_id),))
    for x, y, key_id in sample.get("key_cells", []):
        if not level.add_key((int(x), int(y)), int(key_id)):
            raise ValueError("ô chìa không hợp lệ: %s" % ((x, y, key_id),))
    level.sort_lock_keys()

    # 4. Số bước = đường ngắn nhất + dự phòng, rồi kiểm tra lại toàn bộ
    level.max_steps = solver.auto_max_steps(level, extra=4)
    # Ô khoá có thể buộc đi vòng ⇒ đường thật dài hơn đường BFS thường: nới ngân sách bước
    min_with_keys = validator.min_steps_with_keys(level)
    if min_with_keys:
        level.max_steps = max(level.max_steps, int(min_with_keys) + 4)
    level.par_time = float(max(20, level.max_steps * 3))

    # 5. NHIỆM VỤ (tối đa 3): param 0 -> tự lấy theo max_steps/par_time vừa tính
    level.missions = []
    for slot, entry in enumerate(sample.get("missions", [])[:chal.MAX_PER_LEVEL]):
        type_id, param = entry
        level.set_mission(slot, str(type_id), int(param))

    # 5b. LUẬT THỬ THÁCH (Challenge Mode): ("walk_number_only", 0) — chỉ dùng với "mode": "challenge"
    challenge = sample.get("challenge")
    if challenge:
        rule_id, param = challenge
        if not level.set_challenge(str(rule_id), int(param)):
            raise ValueError("luật thử thách không hợp lệ: %s" % rule_id)

    # 6. TÔ GIÁ TRỊ THEO ĐƯỜNG ĐI ("path_values") — cùng luật với nút Ctrl+Enter của tool:
    #    dùng đường NGẮN NHẤT của màn, bỏ 2 đầu S/F, chia theo TỔNG hoặc cấp mực theo bước.
    path_values_cfg = sample.get("path_values")
    if path_values_cfg:
        paint_path_values(level, path_values_cfg)

    # 7. DỮ LIỆU RIÊNG CỦA CHẾ ĐỘ (kiểu edit theo `mode`): {(x, y): giá trị} — xem app/config.py MODE_EDITS
    level.custom_cell_values.update({tuple(cell): int(value)
                                     for cell, value in sample.get("custom_values", {}).items()})

    return level


def paint_path_values(level, cfg: dict) -> int:
    """TÔ GIÁ TRỊ theo ĐƯỜNG NGẮN NHẤT của màn (giống nút "Sinh giá trị trên đường" của tool).

    cfg = {"fill": "sum"|"step", "value": N}. Trả về TỔNG đã tô (0 nếu không có gì để tô).
    Ném `ValueError` khi tổng không chia được cho số ô (ngoài khoảng hợp lệ).
    """
    spec = mode_edit_spec(str(level.mode_id))
    if not spec["has_sum_field"]:
        raise ValueError("chế độ %s không tô giá trị theo đường" % level.mode_id)

    route = solver.shortest_path(level) or []
    cells = route[1:-1]
    if not cells:
        raise ValueError("đường ngắn nhất chưa đủ dài để tô giá trị")

    lo, hi = int(spec["min"]), int(spec["max"])
    fill = str(cfg.get("fill", "sum"))
    value = int(cfg.get("value", 0))
    if fill == "sum":
        numbers = path_values.distribute_sum(value, len(cells), lo, hi)
        if numbers is None:
            low_total, high_total = path_values.feasible_range(len(cells), lo, hi)
            raise ValueError("tổng %d ngoài khoảng %d..%d của %d ô"
                             % (value, low_total, high_total, len(cells)))
    else:
        numbers = path_values.step_values(list(range(1, len(cells) + 1)), value, lo, hi)

    for cell, number in zip(cells, numbers):
        level.set_custom_value(cell, int(number))
    if spec.get("budget_from_sum") and fill == "sum":
        # Chi phí ô = số bước phải bỏ ra ⇒ max_steps phải đủ cho đường vừa chia
        level.max_steps = max(level.max_steps, sum(numbers) + 3)
    return sum(numbers)


def _parse_only() -> set[int]:
    """Đọc cờ `--only 21` / `--only 21,22` (rỗng = làm TẤT CẢ màn mẫu)."""
    args = sys.argv
    if "--only" not in args:
        return set()
    index = args.index("--only")
    if index + 1 >= len(args):
        return set()
    return {int(part) for part in args[index + 1].split(",") if part.strip()}


## Thư mục mặc định của màn mẫu — CỐ Ý KHÁC `resources/levels/`: id 10..17 đã là MÀN THẬT của game,
## ghi màn mẫu vào đó sẽ ĐÈ mất màn thật. Muốn ghi vào chỗ khác: `--dir resources/levels`.
DEFAULT_SAMPLES_DIR = APP_DIR.parents[1] / "resources" / "levels_samples"


def _parse_dir() -> Path:
    """Đọc cờ `--dir <thư mục>` (mặc định DEFAULT_SAMPLES_DIR)."""
    args = sys.argv
    if "--dir" not in args:
        return DEFAULT_SAMPLES_DIR
    index = args.index("--dir")
    if index + 1 >= len(args):
        return DEFAULT_SAMPLES_DIR
    return Path(args[index + 1]).resolve()


def main() -> int:
    dry_run = "--dry-run" in sys.argv
    only = _parse_only()
    repo = LevelRepository(_parse_dir())
    print("Ghi màn mẫu vào: %s" % repo.levels_dir)
    failures = 0
    used_ids: set[int] = set()

    for level_id in [i for i in sorted(SAMPLES) if not only or i in only]:
        sample = dict(SAMPLES[level_id])
        sample["_id"] = level_id
        # Đặt lại id để create_level dùng đúng số (vd 10 -> "Level 1-10")
        try:
            level = build_sample(sample)
        except ValueError as error:
            print("\n--- level_%d: %s ---" % (level_id, sample["title"]))
            print("    ! %s" % error)
            failures += 1
            continue

        info = solver.analyze(level)
        issues = validator.validate(level)
        errors = [issue for issue in issues if issue.is_error]
        print("\n--- level_%d: %s ---" % (level_id, level.level_title))
        print("    board %dx%d, %d/%d ô thuộc board (còn %d ô trống)"
              % (level.width, level.height, level.active_count(),
                 level.width * level.height, level.width * level.height - level.active_count()))
        print("    S=%s  F=%s  đường ngắn nhất=%s bước  max_steps=%d"
              % (level.start, level.end,
                 info["path_length"] if info["solved"] else "KHÔNG CÓ", level.max_steps))
        if sample.get("path_values"):
            route = solver.shortest_path(level) or []
            painted = [cell for cell in route[1:-1] if level.custom_value(cell) > 0]
            print("    tô giá trị theo đường: %d ô · tổng = %d"
                  % (len(painted), sum(level.custom_value(cell) for cell in painted)))
        if sample.get("challenge"):
            rule_id, param = sample["challenge"]
            print("    luật thử thách: %s · tham số %d (0 = game tự tính)"
                  % (rule_id, int(param)))
        for issue in issues:
            print("    %s" % issue.format())

        if errors or not info["solved"]:
            print("    => BỎ QUA (màn mẫu không hợp lệ)")
            failures += 1
            continue

        if not dry_run:
            path = repo.save(level)
            print("    => Đã ghi %s" % path.name)
            used_ids.add(level_id)

    if failures:
        print("\nCÓ %d màn mẫu KHÔNG hợp lệ - cần sửa lại thiết kế." % failures)
        return 1
    count = len(only) if only else len(SAMPLES)
    print("\nXong: %d màn mẫu hợp lệ%s." % (count, " (dry-run, chưa ghi file)" if dry_run else ""))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
