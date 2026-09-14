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
    - BOARD CÓ THỂ KHÔNG PHẢI HÌNH CHỮ NHẬT (polyomino): `cell_mask` đánh dấu ô nào
      thuộc board. Mọi cạnh bao quanh board (viền ngoài hoặc giáp ô trống) tự động
      là tường hiển thị và KHÔNG sửa được; số trên ô chỉ tính tường giữa 2 ô thuộc board.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Iterable

from ..config import MIN_SIZE
from . import challenges as chal

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

    ## Ô thuộc board (polyomino): width*height phần tử, chỉ số = y*width + x
    ## 1 = ô thuộc board, 0 = ô trống ngoài board (không có ô để chơi)
    cell_mask: list[int] = field(default_factory=list)

    custom_cell_values: dict = field(default_factory=dict)
    ## Chuỗi gốc của `custom_cell_values` trong .tres (giữ nguyên khi ghi lại)
    custom_cell_values_raw: str = "{}"

    ## THỬ THÁCH của màn (tối đa 3): danh sách (type_id, param).
    ## Rỗng = game dùng 3 thử thách mặc định (no_wall · steps_max · time_max).
    challenges: list[tuple[str, int]] = field(default_factory=list)

    ## Uid Godot của file nguồn (giữ lại khi ghi đè để không đổi định danh)
    source_uid: str = ""
    ## Đường dẫn file nguồn (nếu được nạp từ đĩa)
    source_path: str = ""

    # ------------------------------------------------------------------
    # Khởi tạo / kích thước
    # ------------------------------------------------------------------
    def __post_init__(self) -> None:
        if len(self.cell_mask) != self.width * self.height:
            self.cell_mask = default_cell_mask(self.width, self.height)
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
        """Cạnh bao quanh board (viền ngoài + giáp ô trống) luôn là tường hiển thị.

        Giống game ép khi nạp màn (level_data.gd -> MazeData.set_cell_mask).
        """
        for ref in self.iter_walls():
            if self.is_outline(ref):
                kind, ix, iy = ref
                if kind == "v":
                    self.set_v_wall(ix, iy, True, True)
                else:
                    self.set_h_wall(ix, iy, True, True)

    def resize(self, width: int, height: int) -> None:
        """Đổi kích thước lưới, cố giữ lại các tường + ô thuộc board trong vùng mới."""
        width = max(MIN_SIZE, int(width))
        height = max(MIN_SIZE, int(height))
        old_v = self._grid_v()
        old_h = self._grid_h()
        old_v_vis = self._grid_v_visible()
        old_h_vis = self._grid_h_visible()
        old_mask = self.cell_mask
        old_w, old_h_size = self.width, self.height

        self.width, self.height = width, height
        # Ô mới thêm vào mặc định THUỘC board (giữ hành vi lưới chữ nhật như trước)
        self.cell_mask = default_cell_mask(width, height)
        for y in range(min(height, old_h_size)):
            for x in range(min(width, old_w)):
                if y * old_w + x < len(old_mask):
                    self.cell_mask[y * width + x] = old_mask[y * old_w + x]

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
        """Cạnh dọc có phải viền ngoài hộp bao không."""
        return ix in (0, self.width) and self.in_bounds_v(ix, iy)

    def is_border_h(self, ix: int, iy: int) -> bool:
        """Cạnh ngang có phải viền ngoài hộp bao không."""
        return iy in (0, self.height) and self.in_bounds_h(ix, iy)

    def is_outline(self, ref: WallRef) -> bool:
        """Cạnh BAO QUANH BOARD: viền ngoài hoặc giáp ô trống (ngoài polyomino).

        Các cạnh này luôn là tường hiển thị và không sửa được (giống viền ngoài).
        """
        kind, ix, iy = ref
        if kind == "v":
            if not self.in_bounds_v(ix, iy):
                return True
            return not (self.is_cell_active((ix - 1, iy)) and self.is_cell_active((ix, iy)))
        if not self.in_bounds_h(ix, iy):
            return True
        return not (self.is_cell_active((ix, iy - 1)) and self.is_cell_active((ix, iy)))

    def is_border(self, ref: WallRef) -> bool:
        """Tên cũ của `is_outline` (giữ để tương thích)."""
        return self.is_outline(ref)

    def has_wall(self, ref: WallRef) -> bool:
        if self.is_outline(ref):
            return True      # cạnh bao quanh board luôn là tường
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
        """Đặt/xoá 1 tường. Trả về False nếu là cạnh bao quanh board (không cho sửa)."""
        if self.is_outline(ref):
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
    # Hình dạng board (polyomino)
    # ------------------------------------------------------------------
    def mask_index(self, cell: Cell) -> int:
        return cell[1] * self.width + cell[0]

    def is_cell_active(self, cell: Cell) -> bool:
        """Ô này có thuộc board không (ô trống / ngoài hộp bao đều là False)."""
        if not self.in_bounds(cell):
            return False
        index = self.mask_index(cell)
        if index < 0 or index >= len(self.cell_mask):
            return True
        return bool(self.cell_mask[index])

    def set_cell_active(self, cell: Cell, active: bool) -> bool:
        """Bật/tắt 1 ô khỏi board. Trả về True nếu có thay đổi.

        Khi BẬT: mở các cạnh nối tới các ô đang hoạt động bên cạnh để ô mới
        không bị bao kín sau khi thêm vào board.
        """
        if not self.in_bounds(cell):
            return False
        x, y = cell
        if self.is_cell_active(cell) == bool(active):
            return False
        self.cell_mask[self.mask_index(cell)] = 1 if active else 0
        if active:
            neighbours = ((x - 1, y, ("v", x, y)), (x + 1, y, ("v", x + 1, y)),
                          (x, y - 1, ("h", x, y)), (x, y + 1, ("h", x, y + 1)))
            for nx, ny, ref in neighbours:
                if self.is_cell_active((nx, ny)):
                    self.set_wall(ref, False)
        self.ensure_borders()
        return True

    def toggle_cell_active(self, cell: Cell) -> bool:
        return self.set_cell_active(cell, not self.is_cell_active(cell))

    def fill_mask(self) -> None:
        """Toàn bộ lưới là board (chữ nhật đầy đủ)."""
        self.cell_mask = default_cell_mask(self.width, self.height)
        self.ensure_borders()

    def fill_board(self) -> None:
        """Tên khác của `fill_mask` (đọc thuận hơn khi gọi từ UI)."""
        self.fill_mask()

    def full_rect_mask(self) -> None:
        self.fill_mask()

    def is_full_rect(self) -> bool:
        return all(self.cell_mask)

    def active_cells(self) -> list[Cell]:
        return [(x, y) for y in range(self.height) for x in range(self.width)
                if self.is_cell_active((x, y))]

    def active_count(self) -> int:
        return sum(1 for value in self.cell_mask if value)

    def nearest_active_cell(self, cell: Cell) -> Cell:
        """Ô hoạt động gần nhất (dùng khi ô hiện tại bị bỏ khỏi board)."""
        if self.is_cell_active(cell):
            return cell
        best = None
        best_distance = None
        for candidate in self.active_cells():
            distance = abs(candidate[0] - cell[0]) + abs(candidate[1] - cell[1])
            if best_distance is None or distance < best_distance:
                best, best_distance = candidate, distance
        return best if best is not None else self.clamp_cell(cell)

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
        """Số tường quanh 1 ô - dùng để hiện số trong ô (khớp game).

        Chỉ tính cạnh GIỮA 2 Ô THUỘC BOARD. Cạnh bao quanh board (viền ngoài hoặc
        giáp ô trống) không tính - giống maze_data.gd::_compute_wall_counts().
        """
        x, y = cell
        if not self.is_cell_active(cell):
            return 0
        edges = (
            ((x, y - 1), ("h", x, y)),        # cạnh trên
            ((x, y + 1), ("h", x, y + 1)),    # cạnh dưới
            ((x - 1, y), ("v", x, y)),        # cạnh trái
            ((x + 1, y), ("v", x + 1, y)),    # cạnh phải
        )
        return sum(1 for neighbour, ref in edges
                   if self.is_cell_active(neighbour) and self.has_wall(ref))

    def start_end_ok(self) -> bool:
        return (self.is_cell_active(self.start) and self.is_cell_active(self.end)
                and self.start != self.end)

    # ------------------------------------------------------------------
    # Thống kê / tiện ích
    # ------------------------------------------------------------------
    def stats(self) -> dict:
        visible = sum(1 for ref in self.iter_walls() if self.has_wall(ref) and self.is_visible(ref))
        hidden = sum(1 for ref in self.iter_walls() if self.has_wall(ref) and not self.is_visible(ref))
        return {
            "visible_walls": visible,
            "hidden_walls": hidden,
            "cells": self.width * self.height,
            "board_cells": self.active_count(),
        }

    def to_grid_arrays(self) -> None:
        """Chuẩn hoá lại kích thước mảng (dùng sau khi nạp từ file)."""
        self.normalize_arrays()

    def normalize_arrays(self) -> None:
        """Bảo đảm mask + 4 mảng tường đúng kích thước theo width/height hiện tại.

        File .tres cũ/hỏng có thể thiếu byte -> thiếu chỗ nào coi như không tường.
        """
        w, h = self.width, self.height
        if len(self.cell_mask) != w * h:
            self.cell_mask = default_cell_mask(w, h)
        self.v_walls = _fit(self.v_walls, (w + 1) * h)
        self.v_walls_visible = _fit(self.v_walls_visible, (w + 1) * h)
        self.h_walls = _fit(self.h_walls, w * (h + 1))
        self.h_walls_visible = _fit(self.h_walls_visible, w * (h + 1))
        self.ensure_borders()

    # ------------------------------------------------------------------
    # THỬ THÁCH (tối đa 3 / màn) — xem app/models/challenges.py
    # ------------------------------------------------------------------
    def set_challenge(self, slot: int, type_id: str, param: int = 0) -> bool:
        """Đặt thử thách ở vị trí `slot` (0..2). Trả về True nếu có thay đổi."""
        if slot < 0 or slot >= chal.MAX_PER_LEVEL:
            return False
        if not chal.is_valid(type_id):
            return False
        value = int(param) if chal.has_param(type_id) else 0
        if value <= 0 and chal.has_param(type_id):
            value = chal.default_param(type_id, self.max_steps, self.par_time)
        entry = (type_id, value)
        while len(self.challenges) <= slot:
            self.challenges.append(("", 0))
        if self.challenges[slot] == entry:
            return False
        self.challenges[slot] = entry
        self.challenges = [c for c in self.challenges if chal.is_valid(c[0])]
        return True

    def clear_challenge(self, slot: int) -> bool:
        """Bỏ thử thách ở vị trí `slot`."""
        if slot < 0 or slot >= len(self.challenges):
            return False
        self.challenges.pop(slot)
        return True

    def clear_all_challenges(self) -> bool:
        """Về chế độ "để game tự dùng 3 thử thách mặc định"."""
        if not self.challenges:
            return False
        self.challenges = []
        return True

    def default_challenges(self) -> list[tuple[str, int]]:
        """3 thử thách mặc định suy ra từ max_steps/par_time của màn."""
        return [
            (chal.NO_WALL, 0),
            (chal.STEPS_MAX, max(1, int(self.max_steps))),
            (chal.TIME_MAX, max(5, int(round(self.par_time)))),
        ]

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
            "cell_mask": list(self.cell_mask),
            "custom_cell_values": dict(self.custom_cell_values),
            "custom_cell_values_raw": self.custom_cell_values_raw,
            "challenges": [tuple(item) for item in self.challenges],
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


def default_cell_mask(width: int, height: int) -> list[int]:
    """Mask mặc định: toàn bộ ô thuộc board (lưới chữ nhật đầy đủ)."""
    return [1] * (width * height)


def _fit(values: list[int], size: int) -> list[int]:
    """Cắt/đệm danh sách byte cho đủ `size` phần tử (thiếu -> 0)."""
    result = [1 if int(v) else 0 for v in values[:size]]
    if len(result) < size:
        result.extend([0] * (size - len(result)))
    return result
