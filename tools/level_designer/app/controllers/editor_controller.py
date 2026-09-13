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
    TOOL_END,
    TOOL_ERASE,
    TOOL_START,
    TOOL_WALL_HIDDEN,
    TOOL_WALL_VISIBLE,
)
from ..models.level import Cell, LevelModel, WallRef
from ..services import solver
from .events import (
    EV_DIRTY_CHANGED,
    EV_LEVEL_CHANGED,
    EV_MODEL_UPDATED,
    EV_STATUS,
    EV_TOOL_CHANGED,
    EV_VIEW_OPTIONS_CHANGED,
    EventEmitter,
)

UNDO_LIMIT = 80


class EditorController:
    """Điều khiển việc chỉnh sửa màn chơi hiện tại."""

    def __init__(self, level: LevelModel | None = None, events: EventEmitter | None = None) -> None:
        self.events = events or EventEmitter()
        self.level: LevelModel = level or LevelModel()
        self.tool: str = TOOL_WALL_VISIBLE
        self.show_numbers = True
        self.show_path = False
        self.show_hidden = True
        self.show_coords = False
        self.dirty = False

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
        """Áp công cụ tường hiện tại lên 1 cạnh (bỏ qua viền ngoài).

        toggle=True  : click đơn - click lại đúng loại tường đang có thì xoá
        toggle=False : đang kéo rê - luôn đặt theo công cụ (không lật qua lại)
        """
        if self.level.is_border(ref):
            self.events.emit(EV_STATUS, "Viền ngoài luôn là tường, không sửa được")
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
        if self.level.is_border(ref) or not self.level.has_wall(ref):
            return
        self.level.set_wall(ref, False)
        self.events.emit(EV_MODEL_UPDATED)

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
            if not self.level.is_border(ref):
                self.level.set_wall(ref, False)
        self._push_undo(before)
        self._set_dirty(True)
        self.events.emit(EV_MODEL_UPDATED)
        self.events.emit(EV_STATUS, "Đã xoá toàn bộ tường bên trong")

    def fill_hidden_random(self, ratio: float = 0.35, seed: int | None = None) -> None:
        """Sinh tường ẩn ngẫu nhiên (chừa đường đi) để làm mẫu rồi tinh chỉnh."""
        rng = random.Random(seed)
        before = self.level.snapshot()
        for ref in list(self.level.iter_walls()):
            if self.level.is_border(ref):
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
