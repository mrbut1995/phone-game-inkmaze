"""View: sân vẽ lưới mê cung (tk.Canvas) - trái tim của Level Designer.

View này chỉ:
    - vẽ model ra canvas (ô, số tường, tường hiện/ẩn, S/F, đường đi gợi ý)
    - bắt sự kiện chuột/bàn phím rồi gọi lệnh trên EditorController
Mọi thay đổi dữ liệu đều do controller thực hiện.
"""

from __future__ import annotations

import tkinter as tk
from typing import Optional

from ..config import (
    CELL_SIZE_DEFAULT,
    CELL_SIZE_MAX,
    CELL_SIZE_MIN,
    COLOR_CANVAS_BG,
    COLOR_END,
    COLOR_GRID,
    COLOR_INK,
    COLOR_INK_SOFT,
    COLOR_MARGIN,
    COLOR_PAPER,
    COLOR_PATH,
    COLOR_SELECT,
    COLOR_START,
    COLOR_WALL_HIDDEN,
    COLOR_WALL_VISIBLE,
    TOOL_END,
    TOOL_START,
)
from ..controllers.editor_controller import EditorController
from ..controllers.events import (
    EV_DIRTY_CHANGED,
    EV_LEVEL_CHANGED,
    EV_MODEL_UPDATED,
    EV_STATUS,
    EV_TOOL_CHANGED,
    EV_VIEW_OPTIONS_CHANGED,
)
from ..models.level import Cell, WallRef
from ..services import solver

MARGIN = 54.0
EDGE_GRAB = 0.30      # bán kính (theo tỉ lệ ô) để bắt cạnh khi click
WALL_WIDTH = 5
HIDDEN_WALL_WIDTH = 4


class GridView(tk.Frame):
    """Widget lưới mê cung + thanh cuộn."""

    def __init__(self, master: tk.Misc, editor: EditorController) -> None:
        super().__init__(master)
        self.editor = editor
        self.cell_size = CELL_SIZE_DEFAULT
        self.hover_ref: Optional[WallRef] = None
        self.hover_cell: Optional[Cell] = None
        self._painting = False
        self._last_painted: Optional[WallRef] = None

        self.canvas = tk.Canvas(self, background=COLOR_CANVAS_BG, highlightthickness=0)
        self.hbar = tk.Scrollbar(self, orient="horizontal", command=self.canvas.xview)
        self.vbar = tk.Scrollbar(self, orient="vertical", command=self.canvas.yview)
        self.canvas.configure(xscrollcommand=self.hbar.set, yscrollcommand=self.vbar.set)

        self.canvas.grid(row=0, column=0, sticky="nsew")
        self.vbar.grid(row=0, column=1, sticky="ns")
        self.hbar.grid(row=1, column=0, sticky="ew")
        self.rowconfigure(0, weight=1)
        self.columnconfigure(0, weight=1)

        self._bind_events()
        self._subscribe()
        self.redraw()

    # ------------------------------------------------------------------
    # Đăng ký sự kiện controller -> vẽ lại
    # ------------------------------------------------------------------
    def _subscribe(self) -> None:
        for event in (EV_MODEL_UPDATED, EV_LEVEL_CHANGED, EV_VIEW_OPTIONS_CHANGED, EV_TOOL_CHANGED):
            self.editor.events.on(event, lambda *_: self.redraw())
        self.editor.events.on(EV_DIRTY_CHANGED, lambda *_: self.redraw())

    def _bind_events(self) -> None:
        self.canvas.bind("<Motion>", self._on_motion)
        self.canvas.bind("<Leave>", self._on_leave)
        self.canvas.bind("<ButtonPress-1>", self._on_press_left)
        self.canvas.bind("<B1-Motion>", self._on_drag_left)
        self.canvas.bind("<ButtonRelease-1>", self._on_release)
        self.canvas.bind("<ButtonPress-3>", self._on_press_right)
        self.canvas.bind("<B3-Motion>", self._on_drag_right)
        self.canvas.bind("<ButtonRelease-3>", self._on_release)
        self.canvas.bind("<Control-MouseWheel>", self._on_zoom_wheel)
        self.canvas.bind("<MouseWheel>", self._on_scroll_wheel)

    # ------------------------------------------------------------------
    # Zoom
    # ------------------------------------------------------------------
    def zoom(self, delta: int) -> None:
        self.cell_size = max(CELL_SIZE_MIN, min(CELL_SIZE_MAX, self.cell_size + delta))
        self.redraw()

    def reset_zoom(self) -> None:
        self.cell_size = CELL_SIZE_DEFAULT
        self.redraw()

    def _on_zoom_wheel(self, event: tk.Event) -> str:
        self.zoom(12 if event.delta > 0 else -12)
        return "break"

    def _on_scroll_wheel(self, event: tk.Event) -> str:
        self.canvas.yview_scroll(-1 if event.delta > 0 else 1, "units")
        return "break"

    # ------------------------------------------------------------------
    # Hình học
    # ------------------------------------------------------------------
    def _origin(self) -> tuple[float, float]:
        return (MARGIN, MARGIN)

    def _cell_box(self, cell: Cell) -> tuple[float, float, float, float]:
        ox, oy = self._origin()
        x, y = cell
        return (
            ox + x * self.cell_size,
            oy + y * self.cell_size,
            ox + (x + 1) * self.cell_size,
            oy + (y + 1) * self.cell_size,
        )

    def _cell_center(self, cell: Cell) -> tuple[float, float]:
        left, top, right, bottom = self._cell_box(cell)
        return ((left + right) / 2, (top + bottom) / 2)

    def _wall_segment(self, ref: WallRef) -> tuple[float, float, float, float]:
        kind, ix, iy = ref
        ox, oy = self._origin()
        size = self.cell_size
        if kind == "v":
            x = ox + ix * size
            return (x, oy + iy * size, x, oy + (iy + 1) * size)
        y = oy + iy * size
        return (ox + ix * size, y, ox + (ix + 1) * size, y)

    def _canvas_pos(self, event: tk.Event) -> tuple[float, float]:
        return (self.canvas.canvasx(event.x), self.canvas.canvasy(event.y))

    def _locate(self, px: float, py: float) -> tuple[Optional[Cell], Optional[WallRef], float]:
        """Từ toạ độ canvas -> (ô, cạnh gần nhất, khoảng cách tỉ lệ tới cạnh)."""
        level = self.editor.level
        ox, oy = self._origin()
        fx = (px - ox) / self.cell_size
        fy = (py - oy) / self.cell_size
        if fx < 0 or fy < 0 or fx > level.width or fy > level.height:
            return (None, None, 1.0)

        cx = min(int(fx), level.width - 1)
        cy = min(int(fy), level.height - 1)
        cell = (cx, cy)

        local_x = fx - cx
        local_y = fy - cy
        candidates = [
            (local_x, ("v", cx, cy)),          # cạnh trái
            (1 - local_x, ("v", cx + 1, cy)),  # cạnh phải
            (local_y, ("h", cx, cy)),          # cạnh trên
            (1 - local_y, ("h", cx, cy + 1)),  # cạnh dưới
        ]
        distance, ref = min(candidates, key=lambda item: item[0])
        if distance > EDGE_GRAB:
            return (cell, None, distance)
        return (cell, ref, distance)

    # ------------------------------------------------------------------
    # Sự kiện chuột
    # ------------------------------------------------------------------
    def _on_motion(self, event: tk.Event) -> None:
        cell, ref, _ = self._locate(*self._canvas_pos(event))
        if cell == self.hover_cell and ref == self.hover_ref:
            return
        self.hover_cell, self.hover_ref = cell, ref
        self._report_hover()
        self.redraw()

    def _on_leave(self, _event: tk.Event) -> None:
        self.hover_cell = None
        self.hover_ref = None
        self.redraw()

    def _on_press_left(self, event: tk.Event) -> None:
        self.editor.begin_stroke()
        self._painting = True
        self._last_painted = None
        self._apply_at(*self._canvas_pos(event), toggle=True)

    def _on_drag_left(self, event: tk.Event) -> None:
        if not self._painting:
            return
        self._apply_at(*self._canvas_pos(event), toggle=False)

    def _on_press_right(self, event: tk.Event) -> None:
        self.editor.begin_stroke()
        self._painting = True
        self._last_painted = None
        self._erase_at(*self._canvas_pos(event))

    def _on_drag_right(self, event: tk.Event) -> None:
        if self._painting:
            self._erase_at(*self._canvas_pos(event))

    def _on_release(self, _event: tk.Event) -> None:
        if not self._painting:
            return
        self._painting = False
        self._last_painted = None
        self.editor.end_stroke()

    def _apply_at(self, px: float, py: float, toggle: bool) -> None:
        cell, ref, _ = self._locate(px, py)
        if self.editor.tool in (TOOL_START, TOOL_END):
            if cell is not None:
                self.editor.apply_marker_tool(cell)
            return
        if ref is None:
            return
        if not toggle and ref == self._last_painted:
            return
        self._last_painted = ref
        self.editor.apply_wall_tool(ref, toggle=toggle)

    def _erase_at(self, px: float, py: float) -> None:
        _, ref, _ = self._locate(px, py)
        if ref is None or ref == self._last_painted:
            return
        self._last_painted = ref
        self.editor.erase_wall(ref)

    def _report_hover(self) -> None:
        level = self.editor.level
        parts: list[str] = []
        if self.hover_cell is not None:
            cell = self.hover_cell
            parts.append("Ô (%d, %d) · %d tường" % (cell[0], cell[1], level.wall_count(cell)))
        if self.hover_ref is not None and not level.is_border(self.hover_ref):
            kind, ix, iy = self.hover_ref
            name = "dọc" if kind == "v" else "ngang"
            state = "trống"
            if level.has_wall(self.hover_ref):
                state = "tường hiện" if level.is_visible(self.hover_ref) else "tường ẩn"
            parts.append("cạnh %s (%d, %d): %s" % (name, ix, iy, state))
        if parts:
            self.editor.events.emit(EV_STATUS, "  |  ".join(parts))

    # ------------------------------------------------------------------
    # Vẽ
    # ------------------------------------------------------------------
    def redraw(self) -> None:
        level = self.editor.level
        canvas = self.canvas
        canvas.delete("all")

        width_px = MARGIN * 2 + level.width * self.cell_size
        height_px = MARGIN * 2 + level.height * self.cell_size

        # Nền giấy + lề đỏ cho giống vở ô ly
        canvas.create_rectangle(0, 0, width_px, height_px, fill=COLOR_CANVAS_BG, outline="")
        paper = (MARGIN - 18, MARGIN - 18, width_px - MARGIN + 18, height_px - MARGIN + 18)
        canvas.create_rectangle(*paper, fill=COLOR_PAPER, outline=COLOR_INK_SOFT, width=2)
        canvas.create_line(MARGIN - 6, paper[1], MARGIN - 6, paper[3], fill=COLOR_MARGIN, width=2)

        self._draw_cells()
        if self.editor.show_path:
            self._draw_path()
        self._draw_walls()
        self._draw_hover()
        self._draw_coords()

        canvas.configure(scrollregion=(0, 0, width_px, height_px))

    def _draw_cells(self) -> None:
        level = self.editor.level
        canvas = self.canvas
        for y in range(level.height):
            for x in range(level.width):
                left, top, right, bottom = self._cell_box((x, y))
                canvas.create_rectangle(left, top, right, bottom, outline=COLOR_GRID, width=1)

                if self.editor.show_numbers:
                    count = level.wall_count((x, y))
                    if count > 0:
                        canvas.create_text(
                            (left + right) / 2, (top + bottom) / 2,
                            text=str(count), fill=COLOR_INK_SOFT,
                            font=(None, max(9, int(self.cell_size * 0.28)), "bold"),
                        )

        if level.in_bounds(level.start):
            self._draw_marker(level.start, "S", COLOR_START)
        if level.in_bounds(level.end):
            self._draw_marker(level.end, "F", COLOR_END)

    def _draw_marker(self, cell: Cell, text: str, color: str) -> None:
        cx, cy = self._cell_center(cell)
        radius = self.cell_size * 0.30
        self.canvas.create_oval(cx - radius, cy - radius, cx + radius, cy + radius,
                                fill=color, outline=COLOR_PAPER, width=2)
        self.canvas.create_text(cx, cy, text=text, fill="white",
                                font=(None, max(10, int(self.cell_size * 0.30)), "bold"))

    def _draw_path(self) -> None:
        level = self.editor.level
        path = solver.shortest_path(level)
        if not path or len(path) < 2:
            return
        points: list[float] = []
        for cell in path:
            cx, cy = self._cell_center(cell)
            points.extend((cx, cy))
        self.canvas.create_line(*points, fill=COLOR_PATH, width=max(3, int(self.cell_size * 0.08)),
                                capstyle="round", joinstyle="round")

    def _draw_walls(self) -> None:
        level = self.editor.level
        canvas = self.canvas
        for ref in level.iter_walls():
            if not level.has_wall(ref):
                continue
            x1, y1, x2, y2 = self._wall_segment(ref)
            if level.is_border(ref):
                canvas.create_line(x1, y1, x2, y2, fill=COLOR_INK, width=WALL_WIDTH + 1, capstyle="round")
                continue
            if not self.editor.show_hidden and not level.is_visible(ref):
                continue
            if level.is_visible(ref):
                canvas.create_line(x1, y1, x2, y2, fill=COLOR_WALL_VISIBLE, width=WALL_WIDTH, capstyle="round")
            else:
                canvas.create_line(x1, y1, x2, y2, fill=COLOR_WALL_HIDDEN, width=HIDDEN_WALL_WIDTH,
                                   dash=(7, 5), capstyle="round")

    def _draw_hover(self) -> None:
        level = self.editor.level
        if self.hover_ref is not None and not level.is_border(self.hover_ref):
            x1, y1, x2, y2 = self._wall_segment(self.hover_ref)
            self.canvas.create_line(x1, y1, x2, y2, fill=COLOR_SELECT, width=WALL_WIDTH + 2,
                                    capstyle="round", dash=(3, 3))
        elif self.hover_cell is not None:
            left, top, right, bottom = self._cell_box(self.hover_cell)
            self.canvas.create_rectangle(left, top, right, bottom, outline=COLOR_SELECT, width=2)

    def _draw_coords(self) -> None:
        level = self.editor.level
        ox, oy = self._origin()
        size = self.cell_size
        for x in range(level.width):
            self.canvas.create_text(ox + (x + 0.5) * size, MARGIN * 0.55,
                                    text="x%d" % x, fill=COLOR_INK_SOFT, font=(None, 9))
        for y in range(level.height):
            self.canvas.create_text(MARGIN * 0.55, oy + (y + 0.5) * size,
                                    text="y%d" % y, fill=COLOR_INK_SOFT, font=(None, 9))
