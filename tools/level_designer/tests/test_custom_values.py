"""Test: KIỂU EDIT THEO CHẾ ĐỘ (custom_cell_values) + 'dungeon' bị loại khỏi màn.

Ba nhóm: dữ liệu (parse/ghi .tres/model) · controller (tô/xoá/undo/đổi chế độ) · luật (config/validator).
"""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from app.config import (  # noqa: E402
    MODE_IDS,
    RETIRED_MODE_IDS,
    TOOL_VALUE,
    TOOL_WALL_VISIBLE,
    mode_edit_spec,
)
from app.controllers.editor_controller import EditorController  # noqa: E402
from app.controllers.events import EventEmitter  # noqa: E402
from app.models.repository import LevelRepository  # noqa: E402
from app.services import solver, tres_io, validator  # noqa: E402


class TestCustomValuesData(unittest.TestCase):
    def make(self, mode: str = "sum_path", size: int = 4):
        level = LevelRepository().create_level(101, size, size)
        level.mode_id = mode
        return level

    # -- parse / ghi -----------------------------------------------------
    def test_parse_and_dump_roundtrip(self) -> None:
        values, unknown = tres_io.parse_custom_values('{"0,1": 5, "2,3": 7}')
        self.assertEqual(values, {(0, 1): 5, (2, 3): 7})
        self.assertFalse(unknown)

        level = self.make()
        level.custom_cell_values = values
        text = tres_io.dumps(level)
        self.assertIn('custom_cell_values = {"0,1": 5, "2,3": 7}', text)

        back = tres_io.loads(text)
        self.assertEqual(back.custom_cell_values, values)
        self.assertFalse(back.custom_raw_unknown)

    def test_empty_values_write_braces(self) -> None:
        text = tres_io.dumps(self.make())
        self.assertIn("custom_cell_values = {}", text)

    def test_unknown_content_is_kept_verbatim(self) -> None:
        raw = '{"mine": "x", "0,1": 4}'
        values, unknown = tres_io.parse_custom_values(raw)
        self.assertTrue(unknown, "khoá không phải số nguyên -> còn phần lạ")
        self.assertEqual(values, {(0, 1): 4})

        level = self.make()
        level.custom_cell_values = values
        level.custom_raw_unknown = True
        level.custom_cell_values_raw = raw
        self.assertIn('custom_cell_values = %s' % raw, tres_io.dumps(level))

    # -- model -----------------------------------------------------------
    def test_model_set_get_clear(self) -> None:
        level = self.make(size=3)
        self.assertEqual(level.custom_value((1, 1)), 0)
        self.assertTrue(level.set_custom_value((1, 1), 7))
        self.assertFalse(level.set_custom_value((1, 1), 7), "gán lại cùng giá trị = không đổi")
        self.assertEqual(level.custom_value((1, 1)), 7)
        self.assertTrue(level.set_custom_value((1, 1), 0), "gán 0 = xoá")
        self.assertEqual(level.custom_value_count(), 0)

    def test_snapshot_keeps_values(self) -> None:
        level = self.make(size=3)
        level.set_custom_value((2, 1), 6)
        snap = level.snapshot()
        level.clear_custom_values()
        self.assertEqual(level.custom_value_count(), 0)
        level.restore(snap)
        self.assertEqual(level.custom_value((2, 1)), 6)

    def test_prune_after_resize_and_mask_change(self) -> None:
        level = self.make(size=4)
        level.set_custom_value((3, 3), 5)
        level.set_custom_value((1, 1), 2)
        level.resize(2, 2)
        self.assertEqual(level.custom_cell_values, {(1, 1): 2}, "ô ngoài lưới mới phải bị bỏ")

        level.set_cell_active((1, 1), False)
        level.prune_custom_values()
        self.assertEqual(level.custom_cell_values, {}, "ô TRỐNG không giữ giá trị")


class TestCustomValuesController(unittest.TestCase):
    def make(self, mode: str = "sum_path", size: int = 4):
        level = LevelRepository().create_level(102, size, size)
        level.mode_id = mode
        return level

    def editor(self, mode: str = "sum_path", size: int = 4) -> EditorController:
        return EditorController(level=self.make(mode, size), events=EventEmitter())

    def test_paint_erase_and_undo(self) -> None:
        editor = self.editor()
        level = editor.level
        editor.set_tool(TOOL_VALUE)
        editor.set_edit_value(9)

        editor.apply_value_tool((1, 1))
        self.assertEqual(level.custom_value((1, 1)), 9)
        editor.apply_value_tool((1, 1))
        self.assertEqual(level.custom_value((1, 1)), 0, "click lại đúng giá trị = xoá")

        editor.undo()
        self.assertEqual(level.custom_value((1, 1)), 9, "hoàn tác phải trả lại giá trị")
        editor.redo()
        self.assertEqual(level.custom_value((1, 1)), 0)

    def test_drag_paints_without_toggle(self) -> None:
        editor = self.editor()
        editor.set_tool(TOOL_VALUE)
        editor.set_edit_value(3)
        editor.apply_value_tool((0, 0), toggle=False)
        editor.apply_value_tool((0, 0), toggle=False)
        self.assertEqual(editor.level.custom_value((0, 0)), 3, "kéo rê không xoá")

    def test_edit_value_clamped_per_mode(self) -> None:
        editor = self.editor("countdown_cost")
        editor.set_edit_value(9)
        self.assertEqual(editor.edit_value, 4)
        editor.set_edit_value(0)
        self.assertEqual(editor.edit_value, 1)

        plain = self.editor("play")
        plain.set_edit_value(5)
        self.assertEqual(plain.edit_value, 0, "chế độ 'play' không có kiểu edit giá trị")

    def test_skips_start_finish_and_empty_cells(self) -> None:
        editor = self.editor(size=3)
        level = editor.level
        editor.set_tool(TOOL_VALUE)
        editor.set_edit_value(5)
        editor.apply_value_tool(level.start)
        editor.apply_value_tool(level.end)
        self.assertEqual(level.custom_value_count(), 0, "S/F không cần tô (game bỏ qua 2 ô này)")

        level.set_cell_active((1, 1), False)
        editor.apply_value_tool((1, 1))
        self.assertEqual(level.custom_value((1, 1)), 0, "ô TRỐNG ngoài board thì không tô")

    def test_erase_value_reports_and_undoes(self) -> None:
        editor = self.editor()
        level = editor.level
        self.assertFalse(editor.erase_value((2, 2)), "ô chưa tô -> không có gì để xoá")
        editor.set_edit_value(4)
        editor.apply_value_tool((2, 2))
        self.assertTrue(editor.erase_value((2, 2)))
        self.assertEqual(level.custom_value_count(), 0)
        editor.undo()
        self.assertEqual(level.custom_value((2, 2)), 4)

    def test_clear_custom_values_undoable(self) -> None:
        editor = self.editor()
        editor.set_edit_value(7)
        for cell in ((0, 0), (1, 0), (2, 0)):
            editor.apply_value_tool(cell)
        editor.clear_custom_values()
        self.assertEqual(editor.level.custom_value_count(), 0)
        editor.undo()
        self.assertEqual(editor.level.custom_value_count(), 3)

    def test_mode_switch_resets_tool_and_value(self) -> None:
        editor = self.editor("sum_path")
        editor.set_tool(TOOL_VALUE)
        editor.set_edit_value(7)
        editor.set_property("mode_id", "play")
        self.assertEqual(editor.tool, TOOL_WALL_VISIBLE, "chế độ mới không dùng công cụ giá trị")
        self.assertEqual(editor.edit_value, 0)

        editor.set_property("mode_id", "countdown_cost")
        self.assertEqual(editor.edit_value, mode_edit_spec("countdown_cost")["default"])


class TestCustomValuesRules(unittest.TestCase):
    def make(self, mode: str = "sum_path", size: int = 3):
        level = LevelRepository().create_level(103, size, size)
        level.mode_id = mode
        return level

    # -- config ----------------------------------------------------------
    def test_dungeon_removed_from_level_modes(self) -> None:
        self.assertNotIn("dungeon", MODE_IDS, "dungeon không được dùng cho màn")
        self.assertIn("dungeon", RETIRED_MODE_IDS)

    def test_every_mode_has_edit_spec(self) -> None:
        for mode in MODE_IDS:
            spec = mode_edit_spec(mode)
            self.assertIn(spec["kind"], ("none", "cell_value"), mode)
            self.assertTrue(spec["note"], "mỗi chế độ phải có ghi chú kiểu edit: %s" % mode)
            if spec["is_cell_value"]:
                self.assertTrue(spec["tool"], mode)
                self.assertLessEqual(spec["min"], spec["default"], mode)
                self.assertLessEqual(spec["default"], spec["max"], mode)

    def test_cell_value_modes_are_the_four_expected(self) -> None:
        cell_modes = sorted(m for m in MODE_IDS if mode_edit_spec(m)["is_cell_value"])
        # Fading Ink thêm 2026-09-27: nhà thiết kế tô MỰC cho từng ô (trước đây game tự cấp)
        self.assertEqual(cell_modes, ["countdown_cost", "fading_ink", "minesweeper", "sum_path"])

    def test_unknown_mode_falls_back_to_play_spec(self) -> None:
        self.assertEqual(mode_edit_spec("khong_ton_tai")["kind"], "none")

    # -- validator -------------------------------------------------------
    def test_dungeon_is_an_error(self) -> None:
        issues = validator.validate(self.make("dungeon"))
        self.assertTrue(any(i.is_error and "BẤT TẬN" in i.message for i in issues),
                        "dungeon phải là LỖI khi ở trong màn")

    def test_out_of_range_value_warns(self) -> None:
        level = self.make("countdown_cost")
        level.set_custom_value((1, 1), 9)
        issues = validator.validate(level)
        self.assertTrue(any(i.severity == "warning" and "NGOÀI khoảng" in i.message for i in issues))

    def test_values_with_play_mode_are_reported(self) -> None:
        level = self.make("play")
        level.set_custom_value((1, 1), 5)
        issues = validator.validate(level)
        self.assertTrue(any("không dùng" in i.message for i in issues))

    def test_pinned_mine_on_shortest_path_warns(self) -> None:
        level = self.make("minesweeper", size=3)
        path = solver.shortest_path(level) or []
        self.assertTrue(path, "bàn 3x3 mặc định phải có đường S→F")
        level.set_custom_value(path[len(path) // 2], 1)
        issues = validator.validate(level)
        self.assertTrue(any("mìn GHIM" in i.message for i in issues))

    def test_painted_values_are_reported_as_info(self) -> None:
        level = self.make("sum_path")
        level.set_custom_value((1, 1), 8)
        issues = validator.validate(level)
        self.assertTrue(any("Đã tô điểm ô cho 1 ô" in i.message for i in issues))


if __name__ == "__main__":
    unittest.main()
