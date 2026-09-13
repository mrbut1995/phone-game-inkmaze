"""Model: dữ liệu 1 màn chơi (thuần Python, không phụ thuộc GUI).

Quy ước trục toạ độ (giống hệt game):
    - Lưới width x height ô, ô (x, y) với x thuộc [0, width), y thuộc [0, height)
    - y = 0 là hàng TRÊN cùng
    - Tường DỌC  (ngăn 2 ô cạnh nhau theo trục X): mảng (width + 1) * height
        chỉ số = ix * height + iy   (ix thuộc [0, width], iy thuộc [0, height))
        tường tại (ix, iy) nằm giữa ô (ix-1, iy) và ô (ix, iy)
    - Tường NGANG (ngăn 2 ô trên/dưới): mảng width * (height + 1)
        chỉ số = ix * (height + 1) + iy  (ix thuộc [0, width), iy thuộc [0, height])
        tường tại (ix, iy) nằm giữa ô (ix, iy-1) và ô (ix, iy)
    - Viền ngoài luôn là tường và luôn hiển thị (game tự ép khi nạp)
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Iterable

from ..config import MIN_SIZE

Cell = tuple[int, int]
WallRef = tuple[str, int, int]  # ("v" | "h", ix, iy)


@dataclass
class LevelModel:
    """Dữ liệu tương ứng 1-1 với resource LevelData của Godot."""

    level_id: int = 1
    level_title: str = "Level 1-1"
    chapter: int = 1
    mode_id: str = "play"
    difficulty: str = "medium"

    width: int = 3
    height: int = 3
    start: Cell = (0, 2)
    end: Cell = (2, 0)
    max_steps: int = 15
    par_time: float = 45.0

    v_walls: list[int] = field(default_factory=list)
    v_walls_visible: list[int] = field(default_factory=list)
    h_walls: list[int] = field(default_factory=list)
    h_walls_visible: list[int] = field(default_factory=list)

    custom_cell_values: dict = field(default_factory=dict)
    ## Chuỗi gốc của `custom_cell_values` trong .tres (giữ nguyên khi ghi lại)
    custom_cell_values_raw: str = "{}"

    ## Uid Godot của file nguồn (giữ lại khi ghi đè để không đổi định danh)
    source_uid: str = ""
    ## Đường dẫn file nguồn (nếu được nạp từ đĩa)
    source_path: str = ""

    # ------------------------------------------------------------------
    # Khởi tạo / kích thước
    # ------------------------------------------------------------------
    def __post_init__(self) -> None:
        if not self.v_walls:
            self.reset_walls()

    def reset_walls(self) -> None:
        """Xoá hết tường trong lưới và dựng lại viền ngoài."""
        w, h = self.width, self.height
        self.v_walls = [0] * ((w + 1) * h)
        self.v_walls_visible = [0] * ((w + 1) * h)
        self.h_walls = [0] * (w * (h + 1))
        self.h_walls_visible = [0] * (w * (h + 1))
        self.ensure_borders()

    def ensure_borders(self) -> None:
        """Viền ngoài luôn là tường hiển thị (giống game ép khi nạp màn)."""
        w, h = self.width, self.height
        for iy in range(h):
            self.set_v_wall(0, iy, True, True)
            self.set_v_wall(w, iy, True, True)
        for ix in range(w):
            self.set_h_wall(ix, 0, True, True)
            self.set_h_wall(ix, h, True, True)

    def resize(self, width: int, height: int) -> None:
        """Đổi kích thước lưới, cố giữ lại các tường còn nằm trong vùng mới."""
        width = max(MIN_SIZE, int(width))
        height = max(MIN_SIZE, int(height))
        old_v = self._grid_v()
        old_h = self._grid_h()
        old_v_vis = self._grid_v_visible()
        old_h_vis = self._grid_h_visible()

        self.width, self.height = width, height
        self.reset_walls()

        for ix in range(min(width + 1, len(old_v))):
            for iy in range(min(height, len(old_v[ix]))):
                if old_v[ix][iy]:
                    self.set_v_wall(ix, iy, True, bool(old_v_vis[ix][iy]))
        for ix in range(min(width, len(old_h))):
            for iy in range(min(height + 1, len(old_h[ix]))):
                if old_h[ix][iy]:
                    self.set_h_wall(ix, iy, True, bool(old_h_vis[ix][iy]))

        self.ensure_borders()
        self.start = self.clamp_cell(self.start)
        self.end = self.clamp_cell(self.end)

    # ------------------------------------------------------------------
    # Truy cập tường
    # ------------------------------------------------------------------
    def v_index(self, ix: int, iy: int) -> int:
        return ix * self.height + iy

    def h_index(self, ix: int, iy: int) -> int:
        return ix * (self.height + 1) + iy

    def in_bounds_v(self, ix: int, iy: int) -> bool:
        return 0 <= ix <= self.width and 0 <= iy < self.height

    def in_bounds_h(self, ix: int, iy: int) -> bool:
        return 0 <= ix < self.width and 0 <= iy <= self.height

    def is_border_v(self, ix: int, iy: int) -> bool:
        return ix in (0, self.width) and self.in_bounds_v(ix, iy)

    def is_border_h(self, ix: int, iy: int) -> bool:
        return iy in (0, self.height) and self.in_bounds_h(ix, iy)

    def is_border(self, ref: WallRef) -> bool:
        kind, ix, iy = ref
        return self.is_border_v(ix, iy) if kind == "v" else self.is_border_h(ix, iy)

    def has_wall(self, ref: WallRef) -> bool:
        kind, ix, iy = ref
        if kind == "v":
            return self.in_bounds_v(ix, iy) and bool(self.v_walls[self.v_index(ix, iy)])
        return self.in_bounds_h(ix, iy) and bool(self.h_walls[self.h_index(ix, iy)])

    def is_visible(self, ref: WallRef) -> bool:
        kind, ix, iy = ref
        if not self.has_wall(ref):
            return False
        if kind == "v":
            return bool(self.v_walls_visible[self.v_index(ix, iy)])
        return bool(self.h_walls_visible[self.h_index(ix, iy)])

    def set_v_wall(self, ix: int, iy: int, wall: bool, visible: bool = False) -> None:
        if not self.in_bounds_v(ix, iy):
            return
        idx = self.v_index(ix, iy)
        self.v_walls[idx] = 1 if wall else 0
        self.v_walls_visible[idx] = 1 if (wall and visible) else 0

    def set_h_wall(self, ix: int, iy: int, wall: bool, visible: bool = False) -> None:
        if not self.in_bounds_h(ix, iy):
            return
        idx = self.h_index(ix, iy)
        self.h_walls[idx] = 1 if wall else 0
        self.h_walls_visible[idx] = 1 if (wall and visible) else 0

    def set_wall(self, ref: WallRef, wall: bool, visible: bool = False) -> bool:
        """Đặt/xoá 1 tường. Trả về False nếu là viền ngoài (không cho sửa)."""
        if self.is_border(ref):
            return False
        kind, ix, iy = ref
        if kind == "v":
            self.set_v_wall(ix, iy, wall, visible)
        else:
            self.set_h_wall(ix, iy, wall, visible)
        return True

    def iter_walls(self) -> Iterable[WallRef]:
        for ix in range(self.width + 1):
            for iy in range(self.height):
                yield ("v", ix, iy)
        for ix in range(self.width):
            for iy in range(self.height + 1):
                yield ("h", ix, iy)

    # ------------------------------------------------------------------
    # Ô / S / F
    # ------------------------------------------------------------------
    def in_bounds(self, cell: Cell) -> bool:
        return 0 <= cell[0] < self.width and 0 <= cell[1] < self.height

    def clamp_cell(self, cell: Cell) -> Cell:
        x = min(max(0, int(cell[0])), max(0, self.width - 1))
        y = min(max(0, int(cell[1])), max(0, self.height - 1))
        return (x, y)

    def wall_count(self, cell: Cell) -> int:
        """Số tường bao quanh 1 ô - đúng công thức game dùng để hiện số."""
        x, y = cell
        if not self.in_bounds(cell):
            return 0
        count = 0
        count += 1 if self.has_wall(("h", x, y)) else 0
        count += 1 if self.has_wall(("h", x, y + 1)) else 0
        count += 1 if self.has_wall(("v", x, y)) else 0
        count += 1 if self.has_wall(("v", x + 1, y)) else 0
        return count

    def start_end_ok(self) -> bool:
        return self.in_bounds(self.start) and self.in_bounds(self.end) and self.start != self.end

    # ------------------------------------------------------------------
    # Thống kê / tiện ích
    # ------------------------------------------------------------------
    def stats(self) -> dict:
        visible = sum(1 for ref in self.iter_walls() if self.has_wall(ref) and self.is_visible(ref))
        hidden = sum(1 for ref in self.iter_walls() if self.has_wall(ref) and not self.is_visible(ref))
        return {"visible_walls": visible, "hidden_walls": hidden, "cells": self.width * self.height}

    def to_grid_arrays(self) -> None:
        """Chuẩn hoá lại kích thước mảng (dùng sau khi nạp từ file)."""
        self.normalize_arrays()

    def normalize_arrays(self) -> None:
        """Bảo đảm 4 mảng tường đúng kích thước theo width/height hiện tại.

        File .tres cũ/hỏng có thể thiếu byte -> thiếu chỗ nào coi như không tường.
        """
        w, h = self.width, self.height
        self.v_walls = _fit(self.v_walls, (w + 1) * h)
        self.v_walls_visible = _fit(self.v_walls_visible, (w + 1) * h)
        self.h_walls = _fit(self.h_walls, w * (h + 1))
        self.h_walls_visible = _fit(self.h_walls_visible, w * (h + 1))

    def snapshot(self) -> dict:
        """Ảnh chụp trạng thái để phục vụ undo/redo."""
        return {
            "level_id": self.level_id,
            "level_title": self.level_title,
            "chapter": self.chapter,
            "mode_id": self.mode_id,
            "difficulty": self.difficulty,
            "width": self.width,
            "height": self.height,
            "start": tuple(self.start),
            "end": tuple(self.end),
            "max_steps": self.max_steps,
            "par_time": self.par_time,
            "v_walls": list(self.v_walls),
            "v_walls_visible": list(self.v_walls_visible),
            "h_walls": list(self.h_walls),
            "h_walls_visible": list(self.h_walls_visible),
            "custom_cell_values": dict(self.custom_cell_values),
            "custom_cell_values_raw": self.custom_cell_values_raw,
        }

    def restore(self, snap: dict) -> None:
        for key, value in snap.items():
            setattr(self, key, value)

    # ------------------------------------------------------------------
    # Nội bộ: chuyển giữa mảng phẳng (file .tres) và mảng 2 chiều (thao tác)
    # ------------------------------------------------------------------
    def _grid_v(self) -> list[list[int]]:
        return [
            [self.v_walls[self.v_index(ix, iy)] for iy in range(self.height)]
            for ix in range(self.width + 1)
        ]

    def _grid_h(self) -> list[list[int]]:
        return [
            [self.h_walls[self.h_index(ix, iy)] for iy in range(self.height + 1)]
            for ix in range(self.width)
        ]

    def _grid_v_visible(self) -> list[list[int]]:
        return [
            [self.v_walls_visible[self.v_index(ix, iy)] for iy in range(self.height)]
            for ix in range(self.width + 1)
        ]

    def _grid_h_visible(self) -> list[list[int]]:
        return [
            [self.h_walls_visible[self.h_index(ix, iy)] for iy in range(self.height + 1)]
            for ix in range(self.width)
        ]


def _fit(values: list[int], size: int) -> list[int]:
    """Cắt/đệm danh sách byte cho đủ `size` phần tử (thiếu -> 0)."""
    result = [1 if int(v) else 0 for v in values[:size]]
    if len(result) < size:
        result.extend([0] * (size - len(result)))
    return result
