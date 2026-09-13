"""Test: board dạng POLYOMINO (cell_mask) - dữ liệu, solver, validator, ghi/đọc .tres."""

from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from app.models.repository import LevelRepository  # noqa: E402
from app.services import solver, tres_io, validator  # noqa: E402

H_SHAPE = [
    "####",
    ".##.",
    "####",
]


def make_shape(level_id: int, rows: list[str], start: tuple[int, int], end: tuple[int, int]):
    height = len(rows)
    width = max(len(row) for row in rows)
    level = LevelRepository().create_level(level_id, width, height)
    for y, row in enumerate(rows):
        for x in range(width):
            level.set_cell_active((x, y), x < len(row) and row[x] == "#")
    level.start = level.nearest_active_cell(start)
    level.end = level.nearest_active_cell(end)
    return level


class PolyominoModelTest(unittest.TestCase):
    def setUp(self) -> None:
        self.level = make_shape(1, H_SHAPE, (0, 2), (3, 0))

    def test_mask_from_shape(self) -> None:
        active = set(self.level.active_cells())
        expected = {(0, 0), (1, 0), (2, 0), (3, 0), (1, 1), (2, 1), (0, 2), (1, 2), (2, 2), (3, 2)}
        self.assertEqual(active, expected)
        self.assertEqual(self.level.active_count(), 10)
        self.assertFalse(self.level.is_full_rect())
        self.assertFalse(self.level.is_cell_active((0, 1)))
        self.assertTrue(self.level.is_cell_active((1, 1)))

    def test_outline_is_forced_wall(self) -> None:
        # Mọi cạnh giáp ô trống đều là tường hiển thị và không sửa được
        self.assertTrue(self.level.is_outline(("v", 1, 1)))     # (0,1) trống | (1,1) board
        self.assertTrue(self.level.has_wall(("v", 1, 1)))
        self.assertTrue(self.level.is_visible(("v", 1, 1)))
        self.assertFalse(self.level.is_outline(("v", 2, 1)))    # giữa (1,1) và (2,1) đều thuộc board
        self.assertFalse(self.level.set_wall(("v", 1, 1), False))

    def test_wall_count_ignores_outline(self) -> None:
        # Ô (0,0): cạnh trái/trên là outline -> 0 tường; (1,0) giáp (1,1) nhưng đang mở
        self.assertEqual(self.level.wall_count((0, 0)), 0)
        self.assertEqual(self.level.wall_count((1, 0)), 0)
        self.level.set_wall(("h", 1, 1), True, True)     # chắn giữa (1,0) và (1,1)
        self.assertEqual(self.level.wall_count((1, 0)), 1)
        self.assertEqual(self.level.wall_count((1, 1)), 1)
        # Ô trống không có số
        self.assertEqual(self.level.wall_count((0, 1)), 0)

    def test_toggle_cell_opens_edges(self) -> None:
        level = self.level
        # Thêm ô (0,1) vào board -> các cạnh với ô board bên cạnh phải MỞ
        self.assertTrue(level.set_cell_active((0, 1), True))
        self.assertTrue(level.is_cell_active((0, 1)))
        self.assertFalse(level.has_wall(("h", 0, 1)))    # nối (0,0)-(0,1)
        self.assertFalse(level.has_wall(("h", 0, 2)))    # nối (0,1)-(0,2)
        self.assertFalse(level.has_wall(("v", 1, 1)))    # nối (0,1)-(1,1)
        # Bỏ ô đó ra -> các cạnh bao quanh lại thành tường
        self.assertTrue(level.set_cell_active((0, 1), False))
        self.assertTrue(level.is_outline(("v", 1, 1)))
        self.assertTrue(level.has_wall(("v", 1, 1)))

    def test_fill_board_returns_rectangle(self) -> None:
        self.level.fill_board()
        self.assertTrue(self.level.is_full_rect())
        self.assertEqual(self.level.active_count(), self.level.width * self.level.height)

    def test_resize_keeps_mask(self) -> None:
        level = make_shape(2, H_SHAPE, (0, 2), (3, 0))
        level.resize(6, 4)
        self.assertEqual(level.width, 6)
        self.assertEqual(level.height, 4)
        # Vùng cũ giữ nguyên hình dạng, vùng mới thêm vào là ô board
        self.assertFalse(level.is_cell_active((0, 1)))
        self.assertTrue(level.is_cell_active((5, 3)))
        self.assertEqual(len(level.cell_mask), 24)

    def test_snapshot_roundtrip_mask(self) -> None:
        snap = self.level.snapshot()
        self.level.fill_board()
        self.assertNotEqual(snap, self.level.snapshot())
        self.level.restore(snap)
        self.assertEqual(snap, self.level.snapshot())


class PolyominoSolverTest(unittest.TestCase):
    def test_path_exists_through_shape(self) -> None:
        level = make_shape(3, H_SHAPE, (0, 2), (3, 0))
        path = solver.shortest_path(level)
        self.assertIsNotNone(path)
        assert path is not None
        self.assertEqual(path[0], (0, 2))
        self.assertEqual(path[-1], (3, 0))
        self.assertEqual(len(path) - 1, 5)
        # Mọi ô trên đường đi đều thuộc board
        self.assertTrue(all(level.is_cell_active(cell) for cell in path))

    def test_cannot_leave_board(self) -> None:
        level = make_shape(4, H_SHAPE, (0, 2), (3, 0))
        moves = solver.neighbors(level, (1, 1))
        self.assertNotIn((0, 1), moves)          # ô trống
        self.assertNotIn((1, 2), moves) if level.has_wall(("h", 1, 2)) else None
        self.assertIn((1, 0), moves)

    def test_analysis_counts_only_board_cells(self) -> None:
        level = make_shape(5, H_SHAPE, (0, 2), (3, 0))
        info = solver.analyze(level)
        self.assertTrue(info["solved"])
        self.assertEqual(info["board_cells"], 10)
        self.assertEqual(info["total_cells"], 10)
        self.assertEqual(info["empty_cells"], 2)
        self.assertEqual(info["blocked_cells"], 0)
        self.assertTrue(info["all_reachable"])

    def test_blocked_goal_is_detected(self) -> None:
        level = make_shape(6, H_SHAPE, (0, 2), (3, 0))
        # Bịt kín đích F (3,0) bằng tường giữa (2,0) và (3,0)
        level.set_wall(("v", 3, 0), True, True)
        self.assertIsNone(solver.shortest_path(level))
        issues = validator.validate(level)
        self.assertTrue(any("Không có đường đi" in issue.message for issue in issues))
        self.assertTrue(validator.has_errors(issues))

    def test_validator_flags_start_on_empty_cell(self) -> None:
        level = make_shape(7, H_SHAPE, (0, 2), (3, 0))
        level.start = (0, 1)          # ô trống (ngoài board)
        issues = validator.validate(level)
        self.assertTrue(any("Ô TRỐNG" in issue.message for issue in issues))
        self.assertTrue(validator.has_errors(issues))

    def test_validator_warns_unreachable_board_cell(self) -> None:
        level = make_shape(8, H_SHAPE, (0, 2), (3, 0))
        # Chặn ô (3,2): bịt cả 2 lối vào
        level.set_wall(("h", 3, 2), True, True)
        level.set_wall(("v", 3, 2), True, True)
        issues = validator.validate(level)
        self.assertTrue(any("KHÔNG tới được" in issue.message for issue in issues))
        self.assertFalse(validator.has_errors(issues))     # chỉ là cảnh báo
        self.assertTrue(solver.shortest_path(level), "vẫn phải tới được đích F")

    def test_validator_info_about_polyomino(self) -> None:
        level = make_shape(9, H_SHAPE, (0, 2), (3, 0))
        issues = validator.validate(level)
        self.assertTrue(any("polyomino" in issue.message for issue in issues))


class PolyominoIOTest(unittest.TestCase):
    def test_mask_written_for_polyomino(self) -> None:
        level = make_shape(10, H_SHAPE, (0, 2), (3, 0))
        text = tres_io.dumps(level)
        self.assertIn("cell_mask = PackedByteArray(1, 1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1)", text)

        again = tres_io.loads(text)
        self.assertEqual(again.cell_mask, level.cell_mask)
        self.assertEqual(again.active_count(), 10)
        self.assertFalse(again.is_cell_active((0, 1)))

    def test_full_rect_writes_empty_mask(self) -> None:
        level = LevelRepository().create_level(11, 3, 3)
        text = tres_io.dumps(level)
        self.assertIn("cell_mask = PackedByteArray()", text)
        again = tres_io.loads(text)
        self.assertTrue(again.is_full_rect())
        self.assertEqual(again.active_count(), 9)

    def test_old_file_without_mask_is_full_rect(self) -> None:
        text = (
            '[gd_resource type="Resource" script_class="LevelData" load_steps=2 format=3]\n'
            '[ext_resource type="Script" path="res://scripts/resources/level_data.gd" id="1_level"]\n'
            "[resource]\n"
            'script = ExtResource("1_level")\n'
            "level_id = 3\n"
            "width = 2\n"
            "height = 2\n"
            "start_pos = Vector2i(0, 1)\n"
            "end_pos = Vector2i(1, 0)\n"
            "max_steps = 4\n"
            "par_time = 20.0\n"
            "v_walls = PackedByteArray(1, 1, 1, 1, 1, 1)\n"
            "v_walls_visible = PackedByteArray(1, 1, 1, 1, 1, 1)\n"
            "h_walls = PackedByteArray(1, 1, 1, 1, 1, 1)\n"
            "h_walls_visible = PackedByteArray(1, 1, 1, 1, 1, 1)\n"
            "custom_cell_values = {}\n"
        )
        level = tres_io.loads(text)
        self.assertTrue(level.is_full_rect())
        self.assertEqual(level.active_count(), 4)

    def test_mask_size_mismatch_resets_to_full(self) -> None:
        level = LevelRepository().create_level(12, 3, 3)
        level.cell_mask = [1, 0, 1]      # sai kích thước
        level.normalize_arrays()
        self.assertEqual(len(level.cell_mask), 9)
        self.assertTrue(level.is_full_rect())

    def test_save_and_reload_polyomino(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = LevelRepository(Path(tmp))
            level = make_shape(13, H_SHAPE, (0, 2), (3, 0))
            repo.save(level)
            again = repo.load(13)
            self.assertEqual(again.cell_mask, level.cell_mask)
            self.assertEqual(again.snapshot(), level.snapshot())
            self.assertEqual(solver.shortest_path(again), solver.shortest_path(level))


class SampleLevelsTest(unittest.TestCase):
    """Các màn mẫu polyomino trong resources/levels phải có mask + đường tới đích."""

    def test_samples_are_solvable(self) -> None:
        repo = LevelRepository()
        ids: list[int] = []
        for summary in repo.list_summaries():
            level = repo.load(summary.level_id)
            if not level.is_full_rect():
                ids.append(summary.level_id)
        if not ids:
            self.skipTest("Chưa có màn mẫu polyomino trong resources/levels")

        for level_id in ids:
            with self.subTest(level=level_id):
                level = repo.load(level_id)
                self.assertFalse(level.is_full_rect(), "Màn mẫu phải có cell_mask")
                self.assertLess(level.active_count(), level.width * level.height)
                path = solver.shortest_path(level)
                self.assertIsNotNone(path, "Màn mẫu phải có đường tới đích")
                self.assertFalse(validator.has_errors(validator.validate(level)))

        self.assertGreaterEqual(len(ids), 2, "Phải có ít nhất 2 màn mẫu polyomino")


if __name__ == "__main__":
    unittest.main()
