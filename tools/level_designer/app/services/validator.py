"""Service: kiểm tra tính hợp lệ của màn chơi trước khi lưu."""

from __future__ import annotations

from dataclasses import dataclass

from ..config import MAX_ID, MAX_SIZE, MIN_ID, MIN_SIZE
from ..models import challenges as chal
from ..models.level import LevelModel
from . import solver

LEVEL_ERROR = "error"
LEVEL_WARNING = "warning"
LEVEL_INFO = "info"


@dataclass(frozen=True)
class Issue:
    severity: str
    message: str

    @property
    def is_error(self) -> bool:
        return self.severity == LEVEL_ERROR

    def format(self) -> str:
        icon = {"error": "✕", "warning": "!", "info": "·"}.get(self.severity, "·")
        return "%s %s" % (icon, self.message)


def validate(level: LevelModel) -> list[Issue]:
    """Trả về danh sách vấn đề (rỗng = hợp lệ hoàn toàn)."""
    issues: list[Issue] = []

    if not MIN_ID <= level.level_id <= MAX_ID:
        issues.append(Issue(LEVEL_ERROR, "level_id phải trong khoảng %d..%d" % (MIN_ID, MAX_ID)))
    if not level.level_title.strip():
        issues.append(Issue(LEVEL_WARNING, "Chưa đặt tên màn (level_title đang trống)"))
    if not (MIN_SIZE <= level.width <= MAX_SIZE and MIN_SIZE <= level.height <= MAX_SIZE):
        issues.append(Issue(LEVEL_ERROR, "Kích thước lưới phải trong khoảng %d..%d" % (MIN_SIZE, MAX_SIZE)))
    if level.active_count() < 2:
        issues.append(Issue(LEVEL_ERROR, "Board phải có ít nhất 2 ô (hiện có %d ô)" % level.active_count()))
    if not level.start_end_ok():
        if not level.is_cell_active(level.start) and level.in_bounds(level.start):
            issues.append(Issue(LEVEL_ERROR, "Điểm S đang nằm ở Ô TRỐNG (ngoài board) - bấm vào ô đó để thêm vào board"))
        if not level.is_cell_active(level.end) and level.in_bounds(level.end):
            issues.append(Issue(LEVEL_ERROR, "Đích F đang nằm ở Ô TRỐNG (ngoài board) - bấm vào ô đó để thêm vào board"))
    if level.max_steps <= 0:
        issues.append(Issue(LEVEL_ERROR, "max_steps phải lớn hơn 0"))
    if level.par_time <= 0:
        issues.append(Issue(LEVEL_ERROR, "par_time phải lớn hơn 0"))

    if not level.in_bounds(level.start):
        issues.append(Issue(LEVEL_ERROR, "Điểm S nằm ngoài lưới"))
    if not level.in_bounds(level.end):
        issues.append(Issue(LEVEL_ERROR, "Điểm F nằm ngoài lưới"))
    if level.start == level.end:
        issues.append(Issue(LEVEL_ERROR, "Điểm S và F đang trùng nhau"))
    if issues and any(issue.is_error for issue in issues):
        return issues

    info = solver.analyze(level)
    if not info["solved"]:
        issues.append(Issue(LEVEL_ERROR, "Không có đường đi từ S tới F (bị tường chặn kín)"))
        return issues

    path_length = int(info["path_length"])
    if level.max_steps < path_length:
        issues.append(Issue(
            LEVEL_ERROR,
            "max_steps (%d) nhỏ hơn đường đi ngắn nhất (%d) -> không thể thắng"
            % (level.max_steps, path_length),
        ))
    elif level.max_steps == path_length:
        issues.append(Issue(LEVEL_WARNING, "max_steps bằng đúng đường đi ngắn nhất (không có dự phòng)"))

    blocked = int(info["blocked_cells"])
    if blocked:
        issues.append(Issue(
            LEVEL_WARNING,
            "%d ô thuộc board KHÔNG tới được từ S (bị tường chặn kín)" % blocked,
        ))

    stats = level.stats()
    if stats["hidden_walls"] == 0:
        issues.append(Issue(LEVEL_INFO, "Màn chưa có tường ẩn nào (toàn bộ tường đều nhìn thấy)"))
    if level.mode_id != "play":
        issues.append(Issue(LEVEL_INFO, "mode_id = '%s' (không phải chế độ Play)" % level.mode_id))
    if int(info["empty_cells"]) > 0:
        issues.append(Issue(
            LEVEL_INFO,
            "Board dạng polyomino: %d/%d ô thuộc board (còn %d ô trống)"
            % (int(info["board_cells"]), level.width * level.height, int(info["empty_cells"])),
        ))

    issues.append(Issue(
        LEVEL_INFO,
        "Đường ngắn nhất %d bước · dư %d bước · %d tường hiện / %d tường ẩn"
        % (path_length, max(0, level.max_steps - path_length), stats["visible_walls"], stats["hidden_walls"]),
    ))
    issues.extend(validate_challenges(level, path_length=int(path_length), info=info))
    return issues


# ---------------------------------------------------------------------------
# THỬ THÁCH (tối đa 3 / màn) — xem app/models/challenges.py
# ---------------------------------------------------------------------------
def validate_challenges(
    level: LevelModel,
    path_length: int = 0,
    info: dict | None = None,
) -> list[Issue]:
    """Kiểm tra danh sách thử thách của màn (rỗng = dùng mặc định của game)."""
    issues: list[Issue] = []
    items = list(level.challenges)

    if len(items) > chal.MAX_PER_LEVEL:
        issues.append(Issue(
            LEVEL_ERROR,
            "Mỗi màn chỉ được TỐI ĐA %d thử thách (đang có %d)" % (chal.MAX_PER_LEVEL, len(items)),
        ))
    if not items:
        issues.append(Issue(
            LEVEL_INFO,
            "Chưa chọn thử thách -> game dùng 3 thử thách mặc định (không đâm tường · %d bước · %d giây)"
            % (max(1, int(level.max_steps)), max(5, int(round(level.par_time)))),
        ))
        return issues

    types = [str(item[0]) for item in items]
    for type_id in types:
        if not chal.is_valid(type_id):
            issues.append(Issue(LEVEL_ERROR, "Loại thử thách không tồn tại: '%s'" % type_id))
    for type_id in sorted(set(types)):
        if list(types).count(type_id) > 1:
            issues.append(Issue(LEVEL_WARNING, "Thử thách '%s' bị lặp lại" % chal.label(type_id)))

    if chal.ONLY_NUMBERED in types and chal.AVOID_NUMBERED in types:
        issues.append(Issue(
            LEVEL_ERROR,
            "Hai thử thách 'chỉ đi vào ô CÓ số' và 'không đi vào ô CÓ số' mâu thuẫn nhau",
        ))

    numbers = _numbered_cells(level)
    total_number = sum(numbers.values())
    board_cells = max(1, level.active_count())
    max_percent = 100
    min_percent = int((100.0 * max(path_length, 1) + board_cells - 1) // board_cells)

    if (chal.ONLY_NUMBERED in types or chal.AVOID_NUMBERED in types or _uses_sum(types)) and not numbers:
        issues.append(Issue(
            LEVEL_WARNING,
            "Màn không có ô nào hiện số -> thử thách liên quan tới số rất khó đạt",
        ))

    if (chal.VISIT_ALL in types or chal.VISIT_ALL_NUMBERED in types) and info is not None:
        blocked = int(info.get("blocked_cells", 0))
        if chal.VISIT_ALL in types and blocked:
            issues.append(Issue(
                LEVEL_ERROR,
                "Thử thách 'đi qua hết mọi ô' không thể đạt: %d ô thuộc board không tới được" % blocked,
            ))
    if chal.VISIT_ALL in types and chal.NO_REVISIT in types:
        issues.append(Issue(
            LEVEL_WARNING,
            "'đi hết mọi ô' + 'không đi đè' cần đường đi Hamilton — hãy chơi thử để chắc chắn có lời giải",
        ))

    for index, (type_id, param) in enumerate(items):
        if not chal.is_valid(type_id):
            continue
        label = chal.label(type_id)
        if not chal.has_param(type_id):
            continue
        low, high = chal.param_bounds(type_id)
        if param < low or param > high:
            issues.append(Issue(
                LEVEL_ERROR,
                "Thử thách %d (%s): tham số %d ngoài khoảng %d..%d" % (index + 1, label, param, low, high),
            ))
            continue

        kind = chal.param_kind(type_id)
        if type_id == chal.STEPS_MAX and path_length and param < path_length:
            issues.append(Issue(
                LEVEL_ERROR,
                "Thử thách %d (%s): %d bước < đường đi ngắn nhất (%d) -> không thể đạt"
                % (index + 1, label, param, path_length),
            ))
        elif type_id == chal.LEN_MAX_PERCENT and param < min_percent:
            issues.append(Issue(
                LEVEL_ERROR,
                "Thử thách %d (%s): tối đa %d%% nhưng đường ngắn nhất đã cần %d%% số ô"
                % (index + 1, label, param, min_percent),
            ))
        elif type_id == chal.LEN_MIN_PERCENT and param > max_percent:
            issues.append(Issue(
                LEVEL_ERROR,
                "Thử thách %d (%s): tối thiểu %d%% > 100%%" % (index + 1, label, param),
            ))
        elif type_id == chal.SUM_LT and param <= 0:
            issues.append(Issue(
                LEVEL_ERROR,
                "Thử thách %d (%s): tổng luôn >= 0 nên N phải > 0" % (index + 1, label),
            ))
        elif type_id == chal.SUM_GT and param > 0 and param >= total_number:
            issues.append(Issue(
                LEVEL_ERROR,
                "Thử thách %d (%s): N = %d >= tổng số lớn nhất có thể (%d) -> không thể đạt"
                % (index + 1, label, param, total_number),
            ))
        elif type_id == chal.SUM_GE and param > 0 and param > total_number:
            issues.append(Issue(
                LEVEL_ERROR,
                "Thử thách %d (%s): N = %d > tổng số lớn nhất có thể (%d) -> không thể đạt"
                % (index + 1, label, param, total_number),
            ))
        elif kind == chal.PARAM_PERCENT:
            issues.append(Issue(
                LEVEL_INFO,
                "Thử thách %d (%s): đường ngắn nhất chiếm %d%% số ô" % (index + 1, label, min_percent),
            ))

    if len(items) < chal.MAX_PER_LEVEL:
        issues.append(Issue(
            LEVEL_INFO,
            "Màn có %d thử thách -> tối đa %d Sao cho màn này" % (len(items), len(items)),
        ))
    else:
        issues.append(Issue(
            LEVEL_INFO,
            "3 thử thách: %s" % " · ".join(chal.label(str(item[0])) for item in items),
        ))
    return issues


# ---------------------------------------------------------------------------
def _uses_sum(types: list[str]) -> bool:
    return any(t in (chal.SUM_LT, chal.SUM_LE, chal.SUM_GT, chal.SUM_GE) for t in types)


## Ô có số trên board -> {cell: số} (số = số tường quanh ô, giống số hiển thị trong game)
## S/F không tính (trong game 2 ô này hiện chữ S/F).
def _numbered_cells(level: LevelModel) -> dict:
    out: dict = {}
    for y in range(level.height):
        for x in range(level.width):
            cell = (x, y)
            if not level.is_cell_active(cell) or cell == level.start or cell == level.end:
                continue
            count = level.wall_count(cell)
            if count > 0:
                out[cell] = count
    return out


def has_errors(issues: list[Issue]) -> bool:
    return any(issue.is_error for issue in issues)


def summary_line(issues: list[Issue]) -> str:
    errors = sum(1 for i in issues if i.severity == LEVEL_ERROR)
    warnings = sum(1 for i in issues if i.severity == LEVEL_WARNING)
    if errors:
        return "%d lỗi · %d cảnh báo" % (errors, warnings)
    if warnings:
        return "Hợp lệ · %d cảnh báo" % warnings
    return "Hợp lệ"
