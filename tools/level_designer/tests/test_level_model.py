"""Test: LevelModel - tường, viền, kích thước, undo snapshot."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from app.models.level import LevelModel  # noqa: E402
from app.models.repository import LevelRepository  # noqa: E402


class TestLevelModel(unittest.TestCase):
    def make(self, width: int = 3, height: int = 3) -> LevelModel:
        return LevelRepository().create_level(99, width, height)

    def test_borders_are_solid(self) -> None:
        level = self.make()
        for ref in level.iter_walls():
            if level.is_border(ref):
                self.assertTrue(level.has_wall(ref), "viền %s phải là tường" % (ref,))
                self.assertTrue(level.is_visible(ref), "viền %s phải nhìn thấy" % (ref,))
            else:
                self.assertFalse(level.has_wall(ref), "bên trong %s phải trống" % (ref,))

    def test_set_wall_on_border_is_ignored(self) -> None:
        level = self.make()
        self.assertFalse(level.set_wall(("v", 0, 0), False))
        self.assertTrue(level.has_wall(("v", 0, 0)))

    def test_wall_count_and_visibility(self) -> None:
        level = self.make(3, 3)
        # Tường ẩn ngăn cách (1,1) với (0,1)
        level.set_wall(("v", 1, 1), True, False)
        self.assertFalse(level.is_visible(("v", 1, 1)))
        # (0,1): chỉ tính tường ẩn bên phải (viền trái bị bỏ qua)
        self.assertEqual(level.wall_count((0, 1)), 1)
        # (1,1): chỉ có tường ẩn bên trái
        self.assertEqual(level.wall_count((1, 1)), 1)
        level.set_wall(("v", 1, 1), False)
        self.assertEqual(level.wall_count((0, 1)), 0)
        self.assertEqual(level.wall_count((1, 1)), 0)

    def test_border_walls_are_not_counted(self) -> None:
        """Tường VIỀN NGOÀI board không tính vào số của ô (update 2026-09)."""
        level = self.make(4, 4)
        # Màn trống: viền là tường nhưng mọi ô đều phải là 0
        for y in range(level.height):
            for x in range(level.width):
                self.assertEqual(level.wall_count((x, y)), 0, "ô (%d,%d)" % (x, y))
        self.assertTrue(level.has_wall(("v", 0, 0)), "viền vẫn phải là tường để chặn đường")
        self.assertTrue(level.has_wall(("h", 3, 4)))

        # Tường bên trong vẫn được tính (cả tường ẩn)
        level.set_wall(("v", 2, 2), True, False)
        self.assertEqual(level.wall_count((1, 2)), 1)   # kề bên phải
        self.assertEqual(level.wall_count((2, 2)), 1)   # kề bên trái
        self.assertEqual(level.wall_count((1, 1)), 0)   # không kề tường nào

        # Ô sát biên tối đa 3 tường, ô giữa tối đa 4
        level.set_wall(("h", 0, 1), True)
        level.set_wall(("h", 0, 2), True)
        self.assertEqual(level.wall_count((0, 1)), 2)

    def test_wall_count_uses_godot_layout(self) -> None:
        """wall_count = h[x][y] + h[x][y+1] + v[x][y] + v[x+1][y], bỏ viền (maze_data.gd)."""
        level = self.make(4, 4)
        level.set_wall(("v", 2, 2), True, True)
        level.set_wall(("h", 1, 2), True, True)
        # Ô (1,2): phải v(2,2) + trên h(1,2)
        self.assertEqual(level.wall_count((1, 2)), 2)
        self.assertEqual(level.v_walls[level.v_index(2, 2)], 1)
        self.assertEqual(level.h_walls[level.h_index(1, 2)], 1)
        # Ô (1,1) nằm ngay TRÊN ô (1,2) nên có tường dưới = h(1,2)
        self.assertEqual(level.wall_count((1, 1)), 1)
        # Ô trong không kề tường nào
        self.assertEqual(level.wall_count((2, 1)), 0)
        # Ô góc dưới-phải chỉ có viền -> không tính
        self.assertEqual(level.wall_count((3, 3)), 0)

    def test_array_index_convention(self) -> None:
        """v_index = ix*h + iy ; h_index = ix*(h+1) + iy (khớp level_manager.gd)."""
        level = self.make(4, 5)
        self.assertEqual(level.v_index(3, 2), 3 * 5 + 2)
        self.assertEqual(level.h_index(3, 2), 3 * 6 + 2)
        level.set_wall(("v", 2, 3), True, True)
        self.assertEqual(level.v_walls[2 * 5 + 3], 1)
        self.assertEqual(level.v_walls_visible[2 * 5 + 3], 1)

    def test_resize_keeps_borders(self) -> None:
        level = self.make(3, 3)
        level.set_wall(("v", 1, 1), True, False)
        level.resize(5, 2)
        self.assertEqual(level.width, 5)
        self.assertEqual(level.height, 2)
        self.assertEqual(len(level.v_walls), (5 + 1) * 2)
        self.assertEqual(len(level.h_walls), 5 * (2 + 1))
        for ref in level.iter_walls():
            if level.is_border(ref):
                self.assertTrue(level.has_wall(ref))
        self.assertTrue(level.in_bounds(level.start))
        self.assertTrue(level.in_bounds(level.end))

    def test_snapshot_restore(self) -> None:
        level = self.make()
        snapshot = level.snapshot()
        level.set_wall(("h", 1, 1), True, True)
        level.max_steps = 99
        self.assertNotEqual(snapshot, level.snapshot())
        level.restore(snapshot)
        self.assertEqual(snapshot, level.snapshot())


if __name__ == "__main__":
    unittest.main()
