"""Controller: quản lý trạng thái chỉnh sửa 1 màn chơi.

Bao gồm: công cụ đang chọn, thao tác sửa (đặt/xoá tường, đặt S/F, đổi thuộc tính),
undo/redo theo "nét vẽ" (stroke) và cờ dirty.
View KHÔNG sửa model trực tiếp - mọi thay đổi đi qua controller này.
"""

from __future__ import annotations

import random
from typing import Any, Callable

from ..config import (
    MAX_SIZE,
    MIN_SIZE,
    PATH_WALL_EXTRA_STEPS,
    TOOL_CELL,
    TOOL_END,
    TOOL_ERASE,
    TOOL_PATH,
    TOOL_START,
    TOOL_VALUE,
    TOOL_WALL_HIDDEN,
    TOOL_WALL_VISIBLE,
    mode_edit_spec,
)
from ..models import missions as chal
from ..models.level import Cell, LevelModel, WallRef
from ..services import path_values, solver
from .events import (
    EV_DIRTY_CHANGED,
    EV_EDIT_VALUE_CHANGED,
    EV_LEVEL_CHANGED,
    EV_MODEL_UPDATED,
    EV_PATH_CHANGED,
    EV_STATUS,
    EV_TOOL_CHANGED,
    EV_VIEW_OPTIONS_CHANGED,
    EventEmitter,
)

UNDO_LIMIT = 80
## 4 hướng đi kề (dùng chung cho vẽ đường đi + sinh tường quanh đường)
PATH_DIRECTIONS: tuple[tuple[int, int], ...] = ((1, 0), (-1, 0), (0, 1), (0, -1))


def path_edge_ref(cell: Cell, dx: int, dy: int) -> WallRef:
    """Cạnh tường nằm giữa ô `cell` và ô kề theo hướng (dx, dy).

    Cùng quy ước với `solver.neighbors`: sang phải chặn bởi tường dọc (x+1, y)...
    """
    x, y = cell
    if dx > 0:
        return ("v", x + 1, y)
    if dx < 0:
        return ("v", x, y)
    if dy > 0:
        return ("h", x, y + 1)
    return ("h", x, y)


class EditorController:
    """Điều khiển việc chỉnh sửa màn chơi hiện tại."""

    def __init__(self, level: LevelModel | None = None, events: EventEmitter | None = None) -> None:
        self.events = events or EventEmitter()
        self.level: LevelModel = level or LevelModel()
        self.tool: str = TOOL_WALL_VISIBLE
        ## Giá trị đang cầm để TÔ bằng công cụ giá trị (kiểu edit của chế độ đang chọn)
        self.edit_value: int = self.mode_edit_spec()["default"]
        self.show_numbers = True
        self.show_path = False
        self.show_hidden = True
        self.show_coords = False
        self.dirty = False
        ## NÉT ĐƯỜNG ĐI đang vẽ bằng công cụ 8 (danh sách ô liền kề, KHÔNG lưu vào .tres)
        self.path_draft: list[Cell] = []

        self._undo: list[dict] = []
        self._redo: list[dict] = []
        self._stroke_snapshot: dict | None = None

    # ------------------------------------------------------------------
    # Trạng thái chung
    # ------------------------------------------------------------------
    def set_tool(self, tool: str) -> None:
        if tool == self.tool:
            return
        self.tool = tool
        self.events.emit(EV_TOOL_CHANGED, tool)

    def set_view_option(self, name: str, value: bool) -> None:
        if not hasattr(self, name):
            return
        setattr(self, name, bool(value))
        self.events.emit(EV_VIEW_OPTIONS_CHANGED, name, value)
        self.events.emit(EV_MODEL_UPDATED)

    def toggle_view_option(self, name: str) -> None:
        self.set_view_option(name, not bool(getattr(self, name, False)))

    def can_undo(self) -> bool:
        return bool(self._undo)

    def can_redo(self) -> bool:
        return bool(self._redo)

    # ------------------------------------------------------------------
    # Nạp màn khác
    # ------------------------------------------------------------------
    def replace_level(self, level: LevelModel, *, reset_history: bool = True) -> None:
        self.level = level
        if reset_history:
            self._undo.clear()
            self._redo.clear()
        self._stroke_snapshot = None
        # Nét đường đi chỉ thuộc về màn đang vẽ → bỏ khi nạp màn khác
        self.path_draft = []
        self.events.emit(EV_PATH_CHANGED, self.path_draft)
        # Chế độ mới có thể có kiểu edit khác → đặt lại giá trị đang cầm + bỏ công cụ giá trị nếu không dùng
        self._sync_mode_edit()
        self._set_dirty(False)
        self.events.emit(EV_LEVEL_CHANGED, level)

    # ------------------------------------------------------------------
    # Thao tác trên lưới (view gọi khi người dùng click/kéo)
    # ------------------------------------------------------------------
    def begin_stroke(self) -> None:
        """Bắt đầu 1 nét vẽ (mouse down) - dùng để gộp undo."""
        if self._stroke_snapshot is None:
            self._stroke_snapshot = self.level.snapshot()

    def end_stroke(self) -> None:
        """Kết thúc nét vẽ (mouse up): chỉ ghi undo nếu model thực sự đổi."""
        if self._stroke_snapshot is None:
            return
        if self._stroke_snapshot != self.level.snapshot():
            self._push_undo(self._stroke_snapshot)
            self._set_dirty(True)
        self._stroke_snapshot = None
        self.events.emit(EV_MODEL_UPDATED)

    def apply_wall_tool(self, ref: WallRef, toggle: bool = True) -> None:
        """Áp công cụ tường hiện tại lên 1 cạnh (bỏ qua cạnh bao quanh board).

        toggle=True  : click đơn - click lại đúng loại tường đang có thì xoá
        toggle=False : đang kéo rê - luôn đặt theo công cụ (không lật qua lại)
        """
        if self.level.is_outline(ref):
            self.events.emit(EV_STATUS, "Cạnh bao quanh board luôn là tường, không sửa được")
            return

        if self.tool == TOOL_ERASE:
            if not self.level.has_wall(ref):
                return
            self.level.set_wall(ref, False)
            self.events.emit(EV_MODEL_UPDATED)
            return

        if self.tool not in (TOOL_WALL_VISIBLE, TOOL_WALL_HIDDEN):
            return

        visible = self.tool == TOOL_WALL_VISIBLE
        already = self.level.has_wall(ref) and self.level.is_visible(ref) == visible
        if toggle and already:
            self.level.set_wall(ref, False)
        else:
            self.level.set_wall(ref, True, visible)
        self.events.emit(EV_MODEL_UPDATED)

    def erase_wall(self, ref: WallRef) -> None:
        """Xoá tường (chuột phải) - không phụ thuộc công cụ đang chọn."""
        if self.level.is_outline(ref) or not self.level.has_wall(ref):
            return
        self.level.set_wall(ref, False)
        self.events.emit(EV_MODEL_UPDATED)

    def apply_cell_tool(self, cell: Cell) -> None:
        """Bật/tắt 1 ô khỏi board (công cụ sửa ô - polyomino)."""
        before = self.level.snapshot()
        if not self.level.toggle_cell_active(cell):
            return
        if not self.level.is_cell_active(self.level.start):
            self.level.start = self.level.nearest_active_cell(self.level.start)
        if not self.level.is_cell_active(self.level.end):
            self.level.end = self.level.nearest_active_cell(self.level.end)
        self._push_undo(before)
        self._set_dirty(True)
        self.events.emit(EV_MODEL_UPDATED)
        state = "thêm vào" if self.level.is_cell_active(cell) else "bỏ khỏi"
        self.events.emit(EV_STATUS, "Ô (%d, %d) %s board" % (cell[0], cell[1], state))

    def apply_marker_tool(self, cell: Cell) -> None:
        """Áp công cụ S/F; các công cụ tường thì bỏ qua ô trống."""
        if self.tool == TOOL_START:
            if cell == self.level.end:
                self.events.emit(EV_STATUS, "Ô này đang là đích F")
                return
            if self.level.start != cell:
                self.level.start = cell
                self._commit("Đặt điểm xuất phát S")
        elif self.tool == TOOL_END:
            if cell == self.level.start:
                self.events.emit(EV_STATUS, "Ô này đang là điểm xuất phát S")
                return
            if self.level.end != cell:
                self.level.end = cell
                self._commit("Đặt đích F")

    # ------------------------------------------------------------------
    # KIỂU EDIT THEO CHẾ ĐỘ (công cụ giá trị — xem app/config.py MODE_EDITS)
    # ------------------------------------------------------------------
    def mode_edit_spec(self) -> dict:
        """Kiểu edit của chế độ đang chọn (kind · min/max · nhãn công cụ · ghi chú)."""
        return mode_edit_spec(str(self.level.mode_id))

    def _sync_mode_edit(self) -> None:
        """Đồng bộ giá trị đang cầm + công cụ mỗi khi chế độ của màn đổi."""
        spec = self.mode_edit_spec()
        self.edit_value = int(spec["default"])
        self.events.emit(EV_EDIT_VALUE_CHANGED, self.edit_value)
        if not spec["is_cell_value"] and self.tool == TOOL_VALUE:
            self.set_tool(TOOL_WALL_VISIBLE)

    def set_edit_value(self, value: int) -> None:
        """Đổi giá trị đang cầm để tô (kẹp theo khoảng của chế độ đang chọn)."""
        spec = self.mode_edit_spec()
        if not spec["is_cell_value"]:
            return
        try:
            value = int(value)
        except (TypeError, ValueError):
            return
        value = max(int(spec["min"]), min(int(spec["max"]), value))
        if value == self.edit_value:
            return
        self.edit_value = value
        self.events.emit(EV_EDIT_VALUE_CHANGED, value)

    def apply_value_tool(self, cell: Cell, toggle: bool = True) -> None:
        """Tô dữ liệu riêng của chế độ lên 1 ô (click lại đúng giá trị đó = xoá)."""
        spec = self.mode_edit_spec()
        if not spec["is_cell_value"]:
            return
        if not self.level.is_cell_active(cell):
            self.events.emit(EV_STATUS, "Ô (%d, %d) là ô TRỐNG (ngoài board) — bật bằng công cụ 6 trước" % cell)
            return
        if cell == self.level.start or cell == self.level.end:
            self.events.emit(EV_STATUS, "Ô S/F không cần tô giá trị (%s tự bỏ qua 2 ô này)" % spec["mode_id"])
            return

        current = self.level.custom_value(cell)
        value = 0 if (toggle and current == self.edit_value) else self.edit_value
        before = self.level.snapshot()
        if not self.level.set_custom_value(cell, value):
            return
        self._push_undo(before)
        self._set_dirty(True)
        self.events.emit(EV_MODEL_UPDATED)
        if value <= 0:
            self.events.emit(EV_STATUS, "Ô (%d, %d): đã xoá %s" % (cell[0], cell[1], spec["tool"].lower()))
        else:
            self.events.emit(EV_STATUS, "Ô (%d, %d): %s = %d %s" % (
                cell[0], cell[1], spec["tool"], value, spec["unit"]))

    def erase_value(self, cell: Cell) -> bool:
        """Xoá giá trị riêng của 1 ô (chuột phải). Trả về True nếu CÓ xoá được."""
        if self.level.custom_value(cell) <= 0:
            return False
        before = self.level.snapshot()
        if not self.level.set_custom_value(cell, 0):
            return False
        self._push_undo(before)
        self._set_dirty(True)
        self.events.emit(EV_MODEL_UPDATED)
        self.events.emit(EV_STATUS, "Ô (%d, %d): đã xoá %s" % (
            cell[0], cell[1], self.mode_edit_spec()["tool"].lower()))
        return True

    def clear_custom_values(self) -> None:
        """Xoá HẾT dữ liệu riêng của chế độ trong màn (có undo)."""
        if not self.level.custom_value_count():
            self.events.emit(EV_STATUS, "Màn chưa có giá trị riêng nào để xoá")
            return
        before = self.level.snapshot()
        removed = self.level.clear_custom_values()
        self._push_undo(before)
        self._set_dirty(True)
        self.events.emit(EV_MODEL_UPDATED)
        self.events.emit(EV_STATUS, "Đã xoá %d giá trị riêng của chế độ" % removed)

    # ------------------------------------------------------------------
    # VẼ ĐƯỜNG ĐI (công cụ 8) — xem app/config.py TOOL_PATH
    # Nét vẽ là dữ liệu TẠM của phiên làm việc (không ghi vào .tres): vẽ xong bấm Ctrl+Enter để
    # biến nét vẽ thành màn chơi — SINH TƯỜNG quanh đường, hoặc TÔ GIÁ TRỊ lên đường (tuỳ chế độ).
    # ------------------------------------------------------------------
    def path_length(self) -> int:
        """Số ô của nét đường đang vẽ."""
        return len(self.path_draft)

    def path_paint_cells(self) -> list[Cell]:
        """Các ô của nét đường sẽ được TÔ GIÁ TRỊ: bỏ 2 ĐẦU (game không tính giá trị ở S/F)."""
        return list(self.path_draft[1:-1]) if len(self.path_draft) >= 2 else []

    def path_value_sum(self) -> int:
        """Tổng giá trị đã tô trên nét đường đang vẽ (0 nếu chưa tô gì)."""
        return sum(self.level.custom_value(cell) for cell in self.path_paint_cells())

    def path_value_count(self) -> int:
        """Số ô ĐÃ TÔ giá trị trên nét đường đang vẽ."""
        return sum(1 for cell in self.path_paint_cells() if self.level.custom_value(cell) > 0)

    def resolve_path_for_values(self) -> tuple[list[Cell], str]:
        """Đường dùng để tô giá trị: NÉT VẼ đang vẽ, hoặc ĐƯỜNG NGẮN NHẤT nếu chưa vẽ gì."""
        if len(self.path_draft) >= 2:
            return list(self.path_draft), "nét vẽ"
        return list(solver.shortest_path(self.level) or []), "đường ngắn nhất của màn"

    def apply_path_values(self, target: int | None = None) -> bool:
        """TÔ GIÁ TRỊ của chế độ lên ĐƯỜNG ĐI (công cụ 8 — Ctrl+Enter).

        · `fill = "sum"` (Countdown Cost · Sum Path): chia giá trị các ô sao cho TỔNG = `target`.
        · `fill = "step"` (Fading Ink): cấp MỰC tăng dần theo bước đi = bước j + `target` (mực dư).
        Ô S/F không tô (game cũng không tính 2 ô này) — xem app/config.py MODE_EDITS[*]["path"].
        """
        spec = self.mode_edit_spec()
        if not spec["paints_values"]:
            self.events.emit(EV_STATUS,
                             "Chế độ %s không tô giá trị theo đường — dùng \"Sinh tường quanh đường\""
                             % spec["mode_id"])
            return False

        route, source = self.resolve_path_for_values()
        if not route:
            self.events.emit(EV_STATUS,
                             "Màn CHƯA CÓ đường S→F để tô — vẽ nét bằng công cụ 8 hoặc sửa tường trước")
            return False
        cells = route[1:-1]
        if len(cells) < 1:
            self.events.emit(EV_STATUS,
                             "Cần đường đi có ÍT NHẤT 3 ô (S … F) — đường hiện tại chỉ có %d ô" % len(route))
            return False

        lo, hi = int(spec["min"]), int(spec["max"])
        fill = spec["path_fill"]
        field = int(target if target is not None else spec["sum_default"])
        if fill == "sum":
            min_total, max_total = path_values.feasible_range(len(cells), lo, hi)
            if field < min_total or field > max_total:
                self.events.emit(EV_STATUS,
                                 "Tổng %d ngoài khoảng hợp lệ của %d ô: %d..%d (mỗi ô %d..%d)"
                                 % (field, len(cells), min_total, max_total, lo, hi))
                return False
            numbers = path_values.distribute_sum(field, len(cells), lo, hi) or []
        else:                                  # "step" — mực tăng dần theo bước đi
            numbers = path_values.step_values(list(range(1, len(cells) + 1)), field, lo, hi)

        before = self.level.snapshot()
        for cell, value in zip(cells, numbers):
            self.level.set_custom_value(cell, int(value))
        self.level.start, self.level.end = route[0], route[-1]
        auto_steps = solver.auto_max_steps(self.level, extra=2)
        if spec.get("budget_from_sum") and fill == "sum":
            # Chi phí ô chính là SỐ BƯỚC phải bỏ ra ⇒ max_steps phải đủ cho đường vừa chia
            self.level.max_steps = max(auto_steps, sum(numbers) + 3)
        else:
            self.level.max_steps = auto_steps

        if before == self.level.snapshot():
            self.events.emit(EV_STATUS, "Đường đi đã đúng các giá trị đó rồi (không có gì đổi)")
            return False

        self._push_undo(before)
        self._set_dirty(True)
        self.events.emit(EV_MODEL_UPDATED)
        self.events.emit(EV_PATH_CHANGED, self.path_draft)
        self.events.emit(EV_STATUS,
                         "Đã tô %s cho %d ô theo %s (tổng = %d%s) · S=(%d, %d) · F=(%d, %d) · max_steps=%d"
                         % (spec["tool"].lower(), len(cells), source, sum(numbers),
                            (" · mực dư %d/bước" % field) if fill == "step" else "",
                            route[0][0], route[0][1], route[-1][0], route[-1][1], self.level.max_steps))
        return True

    def begin_path(self, cell: Cell) -> None:
        """Bắt đầu 1 nét đường mới tại `cell` (mouse down của công cụ 8)."""
        if cell is None or not self.level.is_cell_active(cell):
            self.events.emit(EV_STATUS, "Ô vẽ đường đi phải là ô THUỘC BOARD")
            return
        self.path_draft = [cell]
        self.events.emit(EV_PATH_CHANGED, self.path_draft)
        self.events.emit(EV_MODEL_UPDATED)
        self.events.emit(EV_STATUS,
                         "Vẽ đường đi từ ô (%d, %d) — kéo chuột tới F; Ctrl+Enter để áp dụng cho đường" % cell)

    def extend_path(self, cell: Cell) -> bool:
        """Nối thêm ô khi KÉO chuột (chỉ ô kề, không đi đè; kéo ngược về ô trước = lùi 1 ô)."""
        if not self.path_draft or cell is None:
            return False
        if not self.level.is_cell_active(cell):
            return False
        last = self.path_draft[-1]
        if cell == last:
            return False

        if len(self.path_draft) >= 2 and cell == self.path_draft[-2]:
            self.path_draft.pop()                      # kéo ngược lại = lùi 1 ô
        else:
            if cell in self.path_draft:
                return False                           # không đi đè lên đường đã vẽ
            if abs(cell[0] - last[0]) + abs(cell[1] - last[1]) != 1:
                return False                           # chỉ nối ô KỀ (không nhảy ô)
            self.path_draft.append(cell)

        self.events.emit(EV_PATH_CHANGED, self.path_draft)
        self.events.emit(EV_MODEL_UPDATED)
        if cell == self.level.end:
            self.events.emit(EV_STATUS, "Đường đã tới đích F (%d ô) — bấm Sinh tường quanh đường (Ctrl+Enter)"
                             % len(self.path_draft))
        return True

    def clear_path_draft(self) -> None:
        """Bỏ nét đường đang vẽ (chuột phải khi đang ở công cụ 8, hoặc Esc)."""
        if not self.path_draft:
            self.events.emit(EV_STATUS, "Chưa có nét đường nào để xoá")
            return
        count = len(self.path_draft)
        self.path_draft = []
        self.events.emit(EV_PATH_CHANGED, self.path_draft)
        self.events.emit(EV_MODEL_UPDATED)
        self.events.emit(EV_STATUS, "Đã xoá nét đường đang vẽ (%d ô)" % count)

    def apply_path_walls(self, visible: bool = True, extra: int = PATH_WALL_EXTRA_STEPS) -> bool:
        """SINH MÀN từ nét đường đang vẽ.

        Mọi cạnh BÊN HÔNG của đường (cạnh không nối 2 ô LIỀN NHAU trên nét vẽ) thành tường,
        cạnh nối 2 ô liền nhau được mở ⇒ nét vẽ trở thành ĐƯỜNG DUY NHẤT từ S tới F.
        Đồng thời: S = ô đầu · F = ô cuối · max_steps = số bước + dự phòng.
        """
        route = list(self.path_draft)
        if len(route) < 2:
            self.events.emit(EV_STATUS, "Hãy KÉO chuột vẽ ít nhất 2 ô rồi mới sinh tường (nét vẽ: %d ô)"
                             % len(route))
            return False
        if not all(self.level.is_cell_active(cell) for cell in route):
            self.events.emit(EV_STATUS, "Nét vẽ có ô NGOÀI BOARD — bật ô đó bằng công cụ 6 rồi vẽ lại")
            return False

        before = self.level.snapshot()
        for index, cell in enumerate(route):
            for dx, dy in PATH_DIRECTIONS:
                neighbour = (cell[0] + dx, cell[1] + dy)
                ref = path_edge_ref(cell, dx, dy)
                connected = (index > 0 and route[index - 1] == neighbour) \
                    or (index + 1 < len(route) and route[index + 1] == neighbour)
                if connected:
                    if self.level.has_wall(ref):       # mở lối đi của nét vẽ
                        self.level.set_wall(ref, False)
                elif self.level.is_cell_active(neighbour):
                    self.level.set_wall(ref, True, bool(visible))

        self.level.start = route[0]
        self.level.end = route[-1]
        self.level.max_steps = solver.auto_max_steps(self.level, extra=max(0, int(extra)))

        self._push_undo(before)
        self._set_dirty(True)
        self.events.emit(EV_MODEL_UPDATED)
        self.events.emit(EV_PATH_CHANGED, self.path_draft)
        self.events.emit(EV_STATUS,
                         "Đã sinh tường quanh đường đi (%d ô): đường đã vẽ giờ là ĐƯỜNG DUY NHẤT · "
                         "S=(%d, %d) · F=(%d, %d) · max_steps=%d"
                         % (len(route), route[0][0], route[0][1], route[-1][0], route[-1][1],
                            self.level.max_steps))
        return True

    # ------------------------------------------------------------------
    # Thuộc tính màn chơi (inspector gọi)
    # ------------------------------------------------------------------
    def set_property(self, name: str, value: Any) -> bool:
        """Cập nhật 1 thuộc tính; trả về True nếu có thay đổi."""
        if name in ("width", "height"):
            return self._resize(name, value)
        if not hasattr(self.level, name):
            return False
        if getattr(self.level, name) == value:
            return False
        setattr(self.level, name, value)
        if name == "mode_id":
            self._sync_mode_edit()
        self._commit("Cập nhật %s" % name)
        return True

    def _resize(self, name: str, value: Any) -> bool:
        try:
            size = int(value)
        except (TypeError, ValueError):
            self.events.emit(EV_STATUS, "Kích thước không hợp lệ")
            return False
        size = max(MIN_SIZE, min(MAX_SIZE, size))
        if size == getattr(self.level, name):
            return False
        width = size if name == "width" else self.level.width
        height = size if name == "height" else self.level.height
        before = self.level.snapshot()
        self.level.resize(width, height)
        self._push_undo(before)
        self._set_dirty(True)
        self.events.emit(EV_MODEL_UPDATED)
        self.events.emit(EV_STATUS, "Đổi kích thước lưới thành %dx%d" % (width, height))
        return True

    # ------------------------------------------------------------------
    # Hành động nhanh
    # ------------------------------------------------------------------
    def clear_walls(self) -> None:
        before = self.level.snapshot()
        for ref in list(self.level.iter_walls()):
            if not self.level.is_outline(ref):
                self.level.set_wall(ref, False)
        self._push_undo(before)
        self._set_dirty(True)
        self.events.emit(EV_MODEL_UPDATED)
        self.events.emit(EV_STATUS, "Đã xoá toàn bộ tường bên trong board")

    def fill_board(self) -> None:
        """Trả board về hình chữ nhật đầy đủ (bỏ polyomino)."""
        if self.level.is_full_rect():
            self.events.emit(EV_STATUS, "Board đang là hình chữ nhật đầy đủ")
            return
        before = self.level.snapshot()
        self.level.fill_mask()
        self._push_undo(before)
        self._set_dirty(True)
        self.events.emit(EV_MODEL_UPDATED)
        self.events.emit(EV_STATUS, "Đã chuyển board về hình chữ nhật đầy đủ")

    # ------------------------------------------------------------------
    # NHIỆM VỤ (tối đa 3 / màn) — xem app/models/missions.py
    # ------------------------------------------------------------------
    def set_mission(self, slot: int, type_id: str, param: int = 0) -> None:
        """Đặt nhiệm vụ ở vị trí `slot` (0..2)."""
        if not chal.is_valid(type_id):
            self.events.emit(EV_STATUS, "Loại nhiệm vụ không hợp lệ: %s" % type_id)
            return
        before = self.level.snapshot()
        if not self.level.set_mission(slot, type_id, int(param)):
            return
        self._push_undo(before)
        self._set_dirty(True)
        self.events.emit(EV_MODEL_UPDATED)
        self.events.emit(EV_STATUS, "Nhiệm vụ %d: %s" % (slot + 1, chal.label(type_id)))

    def set_mission_param(self, slot: int, param: int) -> None:
        """Đổi tham số của nhiệm vụ đang có ở `slot`."""
        if slot < 0 or slot >= len(self.level.missions):
            return
        type_id = self.level.missions[slot][0]
        if not chal.has_param(type_id):
            return
        self.set_mission(slot, type_id, int(param))

    def clear_mission(self, slot: int) -> None:
        """Bỏ nhiệm vụ ở vị trí `slot`."""
        before = self.level.snapshot()
        if not self.level.clear_mission(slot):
            return
        self._push_undo(before)
        self._set_dirty(True)
        self.events.emit(EV_MODEL_UPDATED)
        self.events.emit(EV_STATUS, "Đã bỏ nhiệm vụ %d" % (slot + 1))

    def reset_missions(self) -> None:
        """Về chế độ mặc định: game tự dùng 3 nhiệm vụ chuẩn."""
        before = self.level.snapshot()
        if not self.level.clear_all_missions():
            self.events.emit(EV_STATUS, "Màn đang dùng nhiệm vụ mặc định")
            return
        self._push_undo(before)
        self._set_dirty(True)
        self.events.emit(EV_MODEL_UPDATED)
        self.events.emit(EV_STATUS, "Đã về 3 nhiệm vụ mặc định (không đâm tường · đủ bước · đủ thời gian)")

    def fill_default_missions(self) -> None:
        """Ghi rõ 3 nhiệm vụ mặc định vào màn (theo max_steps/par_time hiện tại)."""
        before = self.level.snapshot()
        self.level.missions = self.level.default_missions()
        self._push_undo(before)
        self._set_dirty(True)
        self.events.emit(EV_MODEL_UPDATED)
        self.events.emit(EV_STATUS, "Đã ghi 3 nhiệm vụ mặc định vào màn")

    def invert_row_cells(self, row: int) -> None:
        """Đảo trạng thái ô của cả 1 hàng (tiện vẽ polyomino nhanh)."""
        if row < 0 or row >= self.level.height:
            return
        before = self.level.snapshot()
        for x in range(self.level.width):
            self.level.set_cell_active((x, row), not self.level.is_cell_active((x, row)))
        self.level.ensure_borders()
        self._push_undo(before)
        self._set_dirty(True)
        self.events.emit(EV_MODEL_UPDATED)
        self.events.emit(EV_STATUS, "Đảo các ô của hàng y=%d" % row)

    def fill_hidden_random(self, ratio: float = 0.35, seed: int | None = None) -> None:
        """Sinh tường ẩn ngẫu nhiên (chừa đường đi) để làm mẫu rồi tinh chỉnh."""
        rng = random.Random(seed)
        before = self.level.snapshot()
        for ref in list(self.level.iter_walls()):
            if self.level.is_outline(ref):
                continue
            kind, ix, iy = ref
            # chỉ dùng tường ẩn (đặc trưng lối chơi), tránh tường hiện ngẫu nhiên
            if kind == "v" and rng.random() < ratio:
                self.level.set_wall(ref, True, False)
            elif kind == "h" and rng.random() < ratio:
                self.level.set_wall(ref, True, False)
        self._push_undo(before)
        self._set_dirty(True)
        self.events.emit(EV_MODEL_UPDATED)
        self.events.emit(EV_STATUS, "Sinh tường ẩn ngẫu nhiên (tỉ lệ %.0f%%)" % (ratio * 100))

    def auto_steps(self, extra: int = 2) -> None:
        """Đặt max_steps theo đường đi ngắn nhất + `extra`."""
        info = solver.analyze(self.level)
        if not info["solved"]:
            self.events.emit(EV_STATUS, "Chưa có đường đi S -> F để tính số bước")
            return
        self.set_property("max_steps", max(1, int(info["path_length"]) + extra))

    # ------------------------------------------------------------------
    # Undo / Redo
    # ------------------------------------------------------------------
    def undo(self) -> None:
        if not self._undo:
            self.events.emit(EV_STATUS, "Không còn gì để hoàn tác")
            return
        self._redo.append(self.level.snapshot())
        self.level.restore(self._undo.pop())
        self._set_dirty(True)
        self.events.emit(EV_MODEL_UPDATED)
        self.events.emit(EV_STATUS, "Hoàn tác")

    def redo(self) -> None:
        if not self._redo:
            self.events.emit(EV_STATUS, "Không còn gì để làm lại")
            return
        self._undo.append(self.level.snapshot())
        self.level.restore(self._redo.pop())
        self._set_dirty(True)
        self.events.emit(EV_MODEL_UPDATED)
        self.events.emit(EV_STATUS, "Làm lại")

    # ------------------------------------------------------------------
    # Nội bộ
    # ------------------------------------------------------------------
    def _commit(self, message: str) -> None:
        """Gói 1 thay đổi đơn lẻ: đã có snapshot trước đó ở nơi gọi hay chưa."""
        self._set_dirty(True)
        self.events.emit(EV_MODEL_UPDATED)
        if message:
            self.events.emit(EV_STATUS, message)

    def run_with_undo(self, action: Callable[[], None], message: str = "") -> None:
        """Chạy 1 hành động có ghi undo (dùng cho các lệnh rời rạc)."""
        before = self.level.snapshot()
        action()
        if before != self.level.snapshot():
            self._push_undo(before)
            self._commit(message)

    def _push_undo(self, snapshot: dict) -> None:
        self._undo.append(snapshot)
        if len(self._undo) > UNDO_LIMIT:
            self._undo.pop(0)
        self._redo.clear()

    def _set_dirty(self, value: bool) -> None:
        if self.dirty == value:
            return
        self.dirty = value
        self.events.emit(EV_DIRTY_CHANGED, value)
