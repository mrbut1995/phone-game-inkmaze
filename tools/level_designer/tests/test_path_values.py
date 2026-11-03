"""Test phần "TÔ GIÁ TRỊ THEO ĐƯỜNG ĐI" sau khi bỏ 6 chế độ cũ.

Bối cảnh: Minesweeper · Sum Path · Countdown Cost · Fading Ink · One Stroke · Fog of War (chế độ riêng)
đã bị xoá khỏi game. Nay CHỈ CÒN 4 chế độ: play · blind_memory · wall_builder · challenge — không chế
độ nào dùng giá trị ô, nên nét vẽ của công cụ 8 chỉ còn 1 tác dụng: SINH TƯỜNG quanh đường + đặt S/F.

Vì vậy:
    · `mode_edit_spec()` của MỌI chế độ phải có `paints_values = False`, không có ô "Tổng …".
    · `EditorController.apply_path_values()` phải TỪ CHỐI ở mọi chế độ (giữ code + test để sau này
      thêm chế độ mới thì chỉ cần bật `path` trong app/config.py là dùng lại được).
    · Phần toán chia tổng (`app/services/path_values.py`) vẫn test riêng vì nó độc lập với chế độ.
"""

from __future__ import annotations

import unittest

from app.config import MODE_IDS, mode_edit_spec
from app.controllers.editor_controller import EditorController
from app.controllers.events import EV_STATUS
from app.models.level import LevelModel
from app.services import path_values

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

    def test_no_mode_paints_cell_values(self) -> None:
        # 4 chế độ còn lại đều KHÔNG dùng giá trị ô ⇒ ô "Tổng …" và công cụ 7 luôn ẩn
        self.assertEqual(MODE_IDS, ("play", "blind_memory", "wall_builder", "challenge"))
        for mode_id in MODE_IDS:
            spec = mode_edit_spec(mode_id)
            self.assertFalse(spec["paints_values"], "%s không tô giá trị theo đường" % mode_id)
            self.assertFalse(spec["is_cell_value"], "%s không có công cụ tô giá trị ô" % mode_id)
            self.assertFalse(spec["has_sum_field"], "%s không có ô 'Tổng …'" % mode_id)

    def test_every_mode_builds_walls_around_path(self) -> None:
        for mode_id in MODE_IDS:
            spec = mode_edit_spec(mode_id)
            self.assertEqual(spec["path_action"], "walls",
                             "%s vẫn sinh tường quanh đường khi Ctrl+Enter" % mode_id)

    def test_removed_modes_fall_back_to_play(self) -> None:
        # Chế độ đã xoá ⇒ rơi về khai báo mặc định (như "play"), không còn tô giá trị
        for mode_id in ("minesweeper", "sum_path", "countdown_cost",
                        "fading_ink", "one_stroke", "fog_of_war"):
            spec = mode_edit_spec(mode_id)
            self.assertFalse(spec["paints_values"], mode_id)
            self.assertEqual(spec["path_action"], "walls", mode_id)


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
    """Ctrl+Enter: chế độ không dùng giá trị ô thì TỪ CHỐI tô, chỉ sinh tường quanh đường."""

    def test_every_mode_rejects_value_fill(self) -> None:
        for mode_id in MODE_IDS:
            editor = make_editor(mode_id)
            messages = logger(editor)
            draw(editor, ROUTE)
            self.assertFalse(editor.apply_path_values(20), mode_id)
            self.assertTrue(any("không tô giá trị theo đường" in message for message in messages),
                            messages[-1:])
            self.assertEqual([editor.level.custom_value(cell) for cell in ROUTE[1:-1]],
                             [0] * (len(ROUTE) - 2), "%s không được tô giá trị ô" % mode_id)
            self.assertFalse(editor.dirty, "%s: từ chối thì không đánh dấu dirty" % mode_id)

    def test_value_helpers_stay_empty(self) -> None:
        editor = make_editor("play")
        draw(editor, ROUTE)
        self.assertEqual(editor.path_value_sum(), 0)
        self.assertEqual(editor.path_value_count(), 0)

    def test_set_custom_value_still_serialises(self) -> None:
        # Model vẫn giữ custom_cell_values (LevelData.custom_cell_values) để đọc lại màn cũ;
        # chỉ là không chế độ nào dùng tới nữa.
        level = LevelModel(width=5, height=5)
        level.reset_walls()
        self.assertTrue(level.set_custom_value((1, 1), 4))
        self.assertEqual(level.custom_value((1, 1)), 4)
        self.assertEqual(level.custom_value_count(), 1)
        self.assertEqual(level.clear_custom_values(), 1)
        self.assertEqual(level.custom_value_count(), 0)


if __name__ == "__main__":
    unittest.main()
