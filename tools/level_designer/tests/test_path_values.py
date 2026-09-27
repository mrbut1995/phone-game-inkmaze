"""Test TÔ GIÁ TRỊ THEO ĐƯỜNG ĐI (công cụ 8) — Countdown Cost · Sum Path · Fading Ink.

Luồng người dùng:
    1. Chọn chế độ (ô `mode_id`) — thanh công cụ hiện ô "Tổng chi phí" / "Tổng điểm" / "Mực dư".
    2. Công cụ 8: kéo chuột vẽ đường (hoặc bỏ qua — tool tự lấy ĐƯỜNG NGẮN NHẤT của màn).
    3. Ctrl+Enter → tô giá trị lên các ô của đường sao cho TỔNG đúng bằng ô "Tổng …"
       (Fading Ink: cấp MỰC tăng dần theo bước đi).
"""

from __future__ import annotations

import unittest

from app.config import mode_edit_spec
from app.controllers.editor_controller import EditorController
from app.controllers.events import EV_STATUS
from app.models.level import LevelModel
from app.services import path_values, solver

ROUTE = [(0, 0), (1, 0), (2, 0), (2, 1), (2, 2), (1, 2), (0, 2), (0, 3), (0, 4)]


def make_editor(mode_id: str, width: int = 5, height: int = 5) -> EditorController:
    level = LevelModel(width=width, height=height)
    level.reset_walls()
    level.mode_id = mode_id
    return EditorController(level)


def draw(editor: EditorController, route: list[tuple[int, int]]) -> None:
    editor.begin_path(route[0])
    for cell in route[1:]:
        editor.extend_path(cell)


def logger(editor: EditorController) -> list[str]:
    messages: list[str] = []
    editor.events.on(EV_STATUS, lambda message: messages.append(str(message)))
    return messages


class ModeSpecTest(unittest.TestCase):
    """Khai báo 'path' của từng chế độ trong app/config.py."""

    def test_fading_ink_paints_ink_values(self) -> None:
        spec = mode_edit_spec("fading_ink")
        self.assertTrue(spec["is_cell_value"], "Fading Ink có công cụ 7 để tô MỰC từng ô")
        self.assertEqual(spec["tool"], "Mực ô")
        self.assertEqual((spec["min"], spec["max"]), (1, 9))
        self.assertTrue(spec["has_sum_field"])
        self.assertEqual(spec["path_fill"], "step", "Mực cấp theo BƯỚC ĐI")
        self.assertEqual(spec["sum_label"], "Mực dư mỗi bước")

    def test_countdown_and_sum_path_use_sum(self) -> None:
        for mode_id, label in (("countdown_cost", "Tổng chi phí đường đi"),
                               ("sum_path", "Tổng điểm đường đi")):
            spec = mode_edit_spec(mode_id)
            self.assertTrue(spec["paints_values"], "%s tô giá trị theo đường" % mode_id)
            self.assertEqual(spec["path_fill"], "sum")
            self.assertEqual(spec["sum_label"], label)
        self.assertTrue(mode_edit_spec("countdown_cost")["budget_from_sum"],
                        "Countdown Cost: tổng chi phí = số bước ⇒ tự nâng max_steps")
        self.assertFalse(mode_edit_spec("sum_path")["budget_from_sum"])

    def test_other_modes_still_build_walls(self) -> None:
        for mode_id in ("play", "minesweeper", "blind_memory", "fog_of_war", "one_stroke", "wall_builder"):
            spec = mode_edit_spec(mode_id)
            self.assertEqual(spec["path_action"], "walls", "%s vẫn sinh tường quanh đường" % mode_id)
            self.assertFalse(spec["has_sum_field"])


class DistributeTest(unittest.TestCase):
    """Chia tổng cho N ô (app/services/path_values.py)."""

    def test_sum_is_exact_and_in_range(self) -> None:
        for total, count, lo, hi in ((30, 8, 1, 4), (60, 19, 1, 9), (7, 3, 1, 4), (12, 3, 4, 4)):
            values = path_values.distribute_sum(total, count, lo, hi)
            self.assertIsNotNone(values)
            self.assertEqual(len(values), count)
            self.assertEqual(sum(values), total)
            self.assertTrue(all(lo <= value <= hi for value in values), values)

    def test_out_of_range_returns_none(self) -> None:
        self.assertIsNone(path_values.distribute_sum(7, 3, 1, 2))    # cần 3..6
        self.assertIsNone(path_values.distribute_sum(40, 3, 1, 4))   # tối đa 12
        self.assertIsNone(path_values.distribute_sum(5, 0, 1, 4))

    def test_feasible_range(self) -> None:
        self.assertEqual(path_values.feasible_range(8, 1, 4), (8, 32))

    def test_step_values_grow_with_steps(self) -> None:
        values = path_values.step_values([1, 2, 3, 4], 3, 1, 9)
        self.assertEqual(values, [4, 5, 6, 7])
        # Chặn trên: bước dài thì kẹp ở max (mực tối đa 9)
        self.assertEqual(path_values.step_values([7, 8, 9], 3, 1, 9), [9, 9, 9])


class ApplyPathValuesTest(unittest.TestCase):
    """Ctrl+Enter tô giá trị lên đường đi."""

    def test_countdown_cost_sum_matches_field(self) -> None:
        editor = make_editor("countdown_cost")
        draw(editor, ROUTE)
        self.assertTrue(editor.apply_path_values(24))
        painted = ROUTE[1:-1]
        values = [editor.level.custom_value(cell) for cell in painted]
        self.assertEqual(sum(values), 24, "Tổng chi phí trên đường = đúng ô \"Tổng chi phí\"")
        self.assertTrue(all(1 <= value <= 4 for value in values), values)
        self.assertEqual(editor.level.custom_value(ROUTE[0]), 0, "S không tô giá trị")
        self.assertEqual(editor.level.custom_value(ROUTE[-1]), 0, "F không tô giá trị")
        self.assertEqual(editor.level.start, ROUTE[0])
        self.assertEqual(editor.level.end, ROUTE[-1])
        self.assertEqual(editor.level.max_steps, 24 + 3, "max_steps đủ cho tổng chi phí vừa chia")

    def test_sum_path_sum_matches_field(self) -> None:
        editor = make_editor("sum_path")
        draw(editor, ROUTE)
        self.assertTrue(editor.apply_path_values(50))
        values = [editor.level.custom_value(cell) for cell in ROUTE[1:-1]]
        self.assertEqual(sum(values), 50)
        self.assertTrue(all(1 <= value <= 9 for value in values), values)
        self.assertEqual(editor.level.max_steps, solver.auto_max_steps(editor.level),
                         "Sum Path: bước đi không phụ thuộc tổng điểm")

    def test_out_of_range_sum_is_rejected(self) -> None:
        editor = make_editor("countdown_cost")
        messages = logger(editor)
        draw(editor, ROUTE)
        self.assertFalse(editor.apply_path_values(999), "Tổng quá lớn thì không tô")
        self.assertTrue(any("khoảng hợp lệ" in message for message in messages), messages[-1:])
        self.assertEqual(editor.level.custom_value(ROUTE[1]), 0)

    def test_fading_ink_steps_keep_route_walkable(self) -> None:
        editor = make_editor("fading_ink")
        draw(editor, ROUTE)
        self.assertTrue(editor.apply_path_values(3))       # mực dư 3 mỗi bước
        painted = ROUTE[1:-1]
        for step, cell in enumerate(painted, start=1):
            value = editor.level.custom_value(cell)
            self.assertEqual(value, min(9, step + 3), "Ô ở bước %d có mực = bước + dư" % step)
            self.assertGreaterEqual(value, step, "Mực phải ≥ số bước phải đi để tới ô đó")
        values = [editor.level.custom_value(cell) for cell in painted]
        self.assertTrue(all(values[index] <= values[index + 1] for index in range(len(values) - 1)),
                        "Mực tăng dần theo bước đi: %s" % values)

    def test_uses_shortest_path_when_no_draft(self) -> None:
        editor = make_editor("countdown_cost")
        self.assertEqual(editor.path_length(), 0)
        self.assertTrue(editor.apply_path_values(12), "Chưa vẽ gì thì tô theo đường NGẮN NHẤT")
        route = solver.shortest_path(editor.level) or []
        values = [editor.level.custom_value(cell) for cell in route[1:-1]]
        self.assertEqual(sum(values), 12)
        self.assertEqual(editor.level.start, route[0])
        self.assertEqual(editor.level.end, route[-1])

    def test_draft_path_sum_is_reported(self) -> None:
        editor = make_editor("sum_path")
        draw(editor, ROUTE)
        self.assertEqual(editor.path_value_sum(), 0)
        editor.apply_path_values(40)
        self.assertEqual(editor.path_value_sum(), 40, "Ô 'Tổng …' hiện đúng tổng đang tô")
        self.assertEqual(editor.path_paint_cells(), ROUTE[1:-1], "Chỉ tô các ô GIỮA 2 đầu")

    def test_walls_mode_rejects_value_fill(self) -> None:
        editor = make_editor("play")
        messages = logger(editor)
        draw(editor, ROUTE)
        self.assertFalse(editor.apply_path_values(20))
        self.assertTrue(any("không tô giá trị theo đường" in message for message in messages))

    def test_too_short_path_is_rejected(self) -> None:
        editor = make_editor("sum_path")
        messages = logger(editor)
        draw(editor, [(0, 0), (1, 0)])
        self.assertFalse(editor.apply_path_values(5), "Đường 2 ô thì không có ô nào để tô")
        self.assertTrue(any("3 ô" in message for message in messages))

    def test_apply_is_undoable_and_marks_dirty(self) -> None:
        editor = make_editor("countdown_cost")
        draw(editor, ROUTE)
        before = editor.level.snapshot()
        editor.apply_path_values(24)
        self.assertTrue(editor.dirty)
        editor.undo()
        self.assertEqual(editor.level.snapshot(), before)

    def test_repaint_saturated_total_reports_no_change(self) -> None:
        editor = make_editor("countdown_cost")
        messages = logger(editor)
        draw(editor, ROUTE)
        count = len(ROUTE) - 2
        editor.apply_path_values(4 * count)          # mọi ô = 4 (mức tối đa)
        self.assertTrue(all(editor.level.custom_value(cell) == 4 for cell in ROUTE[1:-1]))
        self.assertFalse(editor.apply_path_values(4 * count), "Tô lại y hệt → không có gì thay đổi")
        self.assertTrue(any("không có gì đổi" in message for message in messages), messages[-1:])


if __name__ == "__main__":
    unittest.main()
