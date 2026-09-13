"""Service: kiểm tra tính hợp lệ của màn chơi trước khi lưu."""

from __future__ import annotations

from dataclasses import dataclass

from ..config import MAX_ID, MAX_SIZE, MIN_ID, MIN_SIZE
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
    return issues


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
