"""Tạo các MÀN MẪU dùng board dạng POLYOMINO (cell_mask) cho game InkMaze.

Chạy:
    cd tools/level_designer
    python make_samples.py            # ghi các màn mẫu vào resources/levels/
    python make_samples.py --dry-run  # chỉ in kết quả kiểm tra, không ghi file

Màn mẫu nằm ở chương 2 (level_10..level_13) nên không đụng 9 màn gốc của chương 1.
Mỗi màn đều được kiểm tra bằng validator: PHẢI có đường đi từ S tới F.
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

from app.models import challenges as chal  # noqa: E402
from app.models.repository import LevelRepository  # noqa: E402
from app.services import solver, validator  # noqa: E402

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
        # Thử thách: param 0 = tự lấy theo max_steps/par_time của màn
        "challenges": [
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
        "challenges": [
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
        "challenges": [
            (chal.NO_WALL, 0),
            (chal.NO_REVISIT, 0),
            (chal.LEN_MAX_PERCENT, 80),
        ],
    },
    13: {
        "title": "Level 2-4 · Chữ U 2 ô dày",
        "difficulty": "medium",
        "chapter": 2,
        "shape": [
            "######",
            "##..##",
            "##..##",
            "######",
        ],
        "start": (0, 0),
        "end": (5, 3),
        "walls": [
            ("v", 1, 0, True),     # tường hiện: chặn (0,0) - (1,0)
            ("v", 1, 2, False),    # tường ẩn: chặn (0,2) - (1,2)
            ("v", 4, 3, True),     # tường hiện: chặn (3,3) - (4,3)
        ],
        "challenges": [
            (chal.NO_WALL, 0),
            (chal.LEN_MIN_PERCENT, 60),
            (chal.NO_UNDO, 0),
        ],
    },
    14: {
        "title": "Level 2-5 · Bàn cờ lớn 11×11",
        "difficulty": "hard",
        "chapter": 2,
        # Lưới chữ nhật đầy đủ 11x11: để thử board nhiều ô (ô tự co cho vừa khung giấy)
        "shape": ["###########"] * 11,
        "start": (0, 10),
        "end": (10, 0),
        "walls": [
            ("v", 2, 9, True),
            ("h", 3, 6, True),
            ("v", 6, 3, False),
            ("h", 7, 7, True),
            ("v", 4, 4, False),
            ("h", 5, 2, True),
            ("v", 8, 5, True),
            ("h", 1, 8, False),
        ],
        "challenges": [
            (chal.NO_WALL, 0),
            (chal.STEPS_MAX, 0),
            (chal.LEN_MAX_PERCENT, 45),
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
    level.mode_id = "play"

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

    # 4. Số bước = đường ngắn nhất + dự phòng, rồi kiểm tra lại toàn bộ
    level.max_steps = solver.auto_max_steps(level, extra=4)
    level.par_time = float(max(20, level.max_steps * 3))

    # 5. THỬ THÁCH (tối đa 3): param 0 -> tự lấy theo max_steps/par_time vừa tính
    level.challenges = []
    for slot, entry in enumerate(sample.get("challenges", [])[:chal.MAX_PER_LEVEL]):
        type_id, param = entry
        level.set_challenge(slot, str(type_id), int(param))
    return level


def main() -> int:
    dry_run = "--dry-run" in sys.argv
    repo = LevelRepository()
    print("Ghi màn mẫu vào: %s" % repo.levels_dir)
    failures = 0
    used_ids: set[int] = set()

    for level_id in sorted(SAMPLES):
        sample = dict(SAMPLES[level_id])
        sample["_id"] = level_id
        # Đặt lại id để create_level dùng đúng số (vd 10 -> "Level 1-10")
        level = build_sample(sample)

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
    print("\nXong: %d màn mẫu hợp lệ%s." % (len(SAMPLES), " (dry-run, chưa ghi file)" if dry_run else ""))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
