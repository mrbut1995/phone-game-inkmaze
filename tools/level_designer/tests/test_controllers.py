"""Test: services (solver/validator) + controllers (undo, save, delete, dirty)."""

from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from app.controllers.app_controller import AppController  # noqa: E402
from app.controllers.editor_controller import EditorController  # noqa: E402
from app.models.repository import LevelRepository  # noqa: E402
from app.services import solver, validator  # noqa: E402


class SolverValidatorTest(unittest.TestCase):
    def setUp(self) -> None:
        self.editor = EditorController(LevelRepository().create_level(1, 3, 3))

    def test_shortest_path_is_rectilinear(self) -> None:
        path = solver.shortest_path(self.editor.level)
        self.assertIsNotNone(path)
        assert path is not None
        self.assertEqual(path[0], self.editor.level.start)
        self.assertEqual(path[-1], self.editor.level.end)
        # Mê cung 3x3 trống: đi hết 4 bước
        self.assertEqual(len(path) - 1, 4)

    def test_wall_blocks_path(self) -> None:
        # Chặn hết các cạnh quanh ô xuất phát (0,2)
        level = self.editor.level
        level.set_wall(("v", 0, 2), True)
        level.set_wall(("v", 1, 2), True)
        level.set_wall(("h", 0, 3), True)
        level.set_wall(("h", 0, 2), True)
        self.assertFalse(solver.analyze(level)["solved"])
        issues = validator.validate(level)
        self.assertTrue(validator.has_errors(issues))

    def test_validator_flags_low_max_steps(self) -> None:
        self.editor.level.max_steps = 2
        issues = validator.validate(self.editor.level)
        self.assertTrue(any("không thể thắng" in i.message for i in issues))

    def test_auto_max_steps(self) -> None:
        self.editor.auto_steps(extra=3)
        self.assertEqual(self.editor.level.max_steps, 4 + 3)


class EditorControllerTest(unittest.TestCase):
    def setUp(self) -> None:
        self.editor = EditorController(LevelRepository().create_level(2, 4, 4))

    def test_undo_redo_wall(self) -> None:
        self.editor.begin_stroke()
        self.editor.apply_wall_tool(("v", 1, 1), toggle=True)
        self.editor.end_stroke()
        self.assertEqual(self.editor.level.v_walls[self.editor.level.v_index(1, 1)], 1)
        self.assertTrue(self.editor.dirty)

        self.editor.undo()
        self.assertEqual(self.editor.level.v_walls[self.editor.level.v_index(1, 1)], 0)
        self.editor.redo()
        self.assertEqual(self.editor.level.v_walls[self.editor.level.v_index(1, 1)], 1)

    def test_click_same_tool_removes_wall(self) -> None:
        self.editor.set_tool("wall_hidden")
        self.editor.begin_stroke()
        self.editor.apply_wall_tool(("h", 2, 2), toggle=True)
        self.editor.end_stroke()
        ref = ("h", 2, 2)
        self.assertTrue(self.editor.level.has_wall(ref))
        self.assertFalse(self.editor.level.is_visible(ref))

        self.editor.begin_stroke()
        self.editor.apply_wall_tool(ref, toggle=True)
        self.editor.end_stroke()
        self.assertFalse(self.editor.level.has_wall(ref))

    def test_drag_does_not_toggle_back(self) -> None:
        self.editor.set_tool("wall_visible")
        ref = ("h", 1, 1)
        self.editor.begin_stroke()
        self.editor.apply_wall_tool(ref, toggle=True)   # click đầu
        self.editor.apply_wall_tool(ref, toggle=False)  # rê qua lại
        self.editor.apply_wall_tool(ref, toggle=False)
        self.editor.end_stroke()
        self.assertTrue(self.editor.level.has_wall(ref))

    def test_resize_and_properties(self) -> None:
        self.assertTrue(self.editor.set_property("width", 6))
        self.assertEqual(self.editor.level.width, 6)
        self.assertFalse(self.editor.set_property("width", 6))  # không đổi -> False
        self.assertTrue(self.editor.set_property("level_title", "Đổi tên"))
        self.editor.undo()
        self.assertNotEqual(self.editor.level.level_title, "Đổi tên")

    def test_marker_tools(self) -> None:
        self.editor.set_tool("start")
        self.editor.begin_stroke()
        self.editor.apply_marker_tool((1, 1))
        self.editor.end_stroke()
        self.assertEqual(self.editor.level.start, (1, 1))

        # Không cho S trùng F
        self.editor.set_tool("start")
        self.editor.begin_stroke()
        self.editor.apply_marker_tool(self.editor.level.end)
        self.editor.end_stroke()
        self.assertNotEqual(self.editor.level.start, self.editor.level.end)

    def test_clear_walls_keeps_border(self) -> None:
        self.editor.level.set_wall(("v", 1, 1), True, True)
        self.editor.clear_walls()
        for ref in self.editor.level.iter_walls():
            if not self.editor.level.is_border(ref):
                self.assertFalse(self.editor.level.has_wall(ref))


class AppControllerTest(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.app = AppController(repository=LevelRepository(Path(self.tmp.name)))

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def test_create_save_load_delete(self) -> None:
        self.app.create_level(10, 3, 3)
        self.assertTrue(self.app.save_current())
        self.assertFalse(self.app.editor.dirty)

        self.assertEqual(len(self.app.level_summaries()), 1)
        self.app.create_level(11, 4, 4)
        self.assertTrue(self.app.save_current())
        self.assertEqual([s.level_id for s in self.app.level_summaries()], [10, 11])

        self.assertTrue(self.app.load_level(10))
        self.assertEqual(self.app.editor.level.width, 3)
        self.assertTrue(self.app.delete_level(11))
        self.assertEqual([s.level_id for s in self.app.level_summaries()], [10])

    def test_save_blocked_when_level_is_broken(self) -> None:
        self.app.create_level(12, 2, 2)
        # Chặn kín ô xuất phát
        level = self.app.editor.level
        level.set_wall(("v", 0, 1), True)
        level.set_wall(("v", 1, 1), True)
        level.set_wall(("h", 0, 1), True)
        level.set_wall(("h", 0, 2), True)
        self.assertFalse(self.app.save_current())
        self.assertFalse((self.app.levels_dir() / "level_12.tres").exists())

    def test_next_free_id_and_duplicate(self) -> None:
        self.app.create_level(1, 3, 3)
        self.app.save_current()
        self.assertEqual(self.app.repository.next_free_id(), 2)
        clone = self.app.duplicate_current()
        self.assertEqual(clone.level_id, 2)
        self.assertIn("copy", clone.level_title)

    def test_export_json(self) -> None:
        self.app.create_level(13, 3, 3)
        out = Path(self.tmp.name) / "level.json"
        self.assertTrue(self.app.export_json(out))
        self.assertIn('"analysis"', out.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
