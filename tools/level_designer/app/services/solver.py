"""Service: giải mê cung trên LevelModel (BFS) để kiểm tra màn có lời giải.

Quy tắc di chuyển giống hệt game (MazeData.has_wall):
    - sang phải (x, y) -> (x+1, y): chặn bởi tường dọc tại (x + 1, y)
    - sang trái  (x, y) -> (x-1, y): chặn bởi tường dọc tại (x, y)
    - xuống      (x, y) -> (x, y+1): chặn bởi tường ngang tại (x, y + 1)
    - lên        (x, y) -> (x, y-1): chặn bởi tường ngang tại (x, y)
"""

from __future__ import annotations

from collections import deque
from typing import Optional

from ..models.level import Cell, LevelModel


def neighbors(level: LevelModel, cell: Cell) -> list[Cell]:
    """Các ô đi được từ `cell` (đã tính tường chặn)."""
    x, y = cell
    result: list[Cell] = []
    if not level.has_wall(("v", x + 1, y)):
        result.append((x + 1, y))
    if not level.has_wall(("v", x, y)):
        result.append((x - 1, y))
    if not level.has_wall(("h", x, y + 1)):
        result.append((x, y + 1))
    if not level.has_wall(("h", x, y)):
        result.append((x, y - 1))
    return [c for c in result if level.in_bounds(c)]


def bfs(level: LevelModel, start: Cell) -> tuple[dict[Cell, int], dict[Cell, Optional[Cell]]]:
    """Duyệt BFS từ `start`, trả về (khoảng cách, ô trước đó)."""
    dist: dict[Cell, int] = {start: 0}
    prev: dict[Cell, Optional[Cell]] = {start: None}
    queue: deque[Cell] = deque([start])
    while queue:
        cell = queue.popleft()
        for nxt in neighbors(level, cell):
            if nxt in dist:
                continue
            dist[nxt] = dist[cell] + 1
            prev[nxt] = cell
            queue.append(nxt)
    return dist, prev


def shortest_path(level: LevelModel) -> Optional[list[Cell]]:
    """Đường đi ngắn nhất từ S tới F (None nếu không tới được)."""
    if not level.start_end_ok():
        return None
    dist, prev = bfs(level, level.start)
    if level.end not in dist:
        return None
    path: list[Cell] = []
    cursor: Optional[Cell] = level.end
    while cursor is not None:
        path.append(cursor)
        cursor = prev.get(cursor)
    path.reverse()
    return path


def analyze(level: LevelModel) -> dict:
    """Thông tin phân tích màn chơi dùng cho inspector/validator."""
    total_cells = level.width * level.height
    if not level.start_end_ok():
        return {
            "solved": False,
            "path": None,
            "path_length": 0,
            "reachable_cells": 0,
            "total_cells": total_cells,
            "blocked_cells": total_cells,
            "slack": 0,
        }

    dist, _ = bfs(level, level.start)
    path = shortest_path(level)
    path_length = len(path) - 1 if path else 0
    return {
        "solved": path is not None,
        "path": path,
        "path_length": path_length,
        "reachable_cells": len(dist),
        "total_cells": total_cells,
        "blocked_cells": total_cells - len(dist),
        "slack": level.max_steps - path_length,
    }


def auto_max_steps(level: LevelModel, extra: int = 2) -> int:
    """Gợi ý số bước tối đa = đường đi ngắn nhất + `extra` nhịp thở."""
    info = analyze(level)
    if not info["solved"]:
        return max(1, level.width * level.height)
    return max(1, int(info["path_length"]) + extra)
