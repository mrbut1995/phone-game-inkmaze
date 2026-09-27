"""Test CÔNG CỤ 8 — VẼ ĐƯỜNG ĐI rồi sinh tường quanh đường (xem app/config.py TOOL_PATH).

Luồng người dùng:
    1. Chọn công cụ 8, KÉO chuột vẽ 1 nét đường (chỉ nối ô kề, không nhảy ô, không đi đè).
    2. Bấm "Sinh tường quanh đường" (Ctrl+Enter) → mọi cạnh BÊN HÔNG của nét vẽ thành tường,
       S = ô đầu, F = ô cuối, max_steps tự tính ⇒ nét vẽ là ĐƯỜNG DUY NHẤT của màn.
"""

from __future__ import annotations

import unittest

from app.config import PATH_WALL_EXTRA_STEPS, TOOL_LABELS, TOOL_PATH, TOOL_PATH_KEY
from app.controllers.editor_controller import EditorController, path_edge_ref
from app.controllers.events import EV_PATH_CHANGED, EV_STATUS
from app.models.level import LevelModel
from app.services import solver, validator

# Nét vẽ hình con rắn trên lưới 5x5 (đi hết 13 ô, không cắt ngang chính mình)
ROUTE = [
    (0, 0), (1, 0), (2, 0), (2, 1), (2, 2), (1, 2), (0, 2),
    (0, 3), (0, 4), (1, 4), (2, 4), (3, 4), (3, 3),
]


def make_editor(width: int = 5, height: int = 5) -> EditorController:
    level = LevelModel(width=width, height=height)
    level.reset_walls()
    return EditorController(level)


def draw(editor: EditorController, route: list[tuple[int, int]]) -> None:
    """Giả lập thao tác chuột: bấm ô đầu rồi kéo qua từng ô của đường."""
    editor.begin_path(route[0])
    for cell in route[1:]:
        editor.extend_path(cell)


def status_log(editor: EditorController) -> list[str]:
    messages: list[str] = []
    editor.events.on(EV_STATUS, lambda message: messages.append(str(message)))
    return messages


class PathToolConfigTest(unittest.TestCase):
    """Khai báo công cụ 8 trong app/config.py."""

    def test_tool_registered_with_key_8(self) -> None:
        self.assertEqual(TOOL_PATH_KEY, "8")
        tools = [tool for tool, _ in TOOL_LABELS]
        self.assertIn(TOOL_PATH, tools)
        self.assertEqual(tools[-1], TOOL_PATH, "Nút công cụ 8 nằm cuối hàng nút")
        self.assertEqual(TOOL_LABELS[-1][1], "Vẽ đường đi (8)")

    def test_edge_ref_matches_solver_convention(self) -> None:
        # Giống solver.neighbors: sang phải chặn bởi tường dọc (x+1, y)…
        self.assertEqual(path_edge_ref((2, 3), 1, 0), ("v", 3, 3))
        self.assertEqual(path_edge_ref((2, 3), -1, 0), ("v", 2, 3))
        self.assertEqual(path_edge_ref((2, 3), 0, 1), ("h", 2, 4))
        self.assertEqual(path_edge_ref((2, 3), 0, -1), ("h", 2, 3))


class PathDraftTest(unittest.TestCase):
    """Vẽ nét đường: chỉ nối ô kề, không đi đè, kéo ngược thì lùi."""

    def test_begin_path_starts_draft(self) -> None:
        editor = make_editor()
        editor.begin_path((1, 1))
        self.assertEqual(editor.path_length(), 1)
        self.assertEqual(editor.path_draft, [(1, 1)])

    def test_extend_connects_adjacent_cells(self) -> None:
        editor = make_editor()
        draw(editor, ROUTE)
        self.assertEqual(editor.path_draft, ROUTE)

    def test_extend_ignores_jump(self) -> None:
        editor = make_editor()
        editor.begin_path((0, 0))
        self.assertFalse(editor.extend_path((3, 3)), "Ô không kề thì KHÔNG được nối vào nét vẽ")
        self.assertEqual(editor.path_draft, [(0, 0)])

    def test_extend_ignores_revisit_even_when_adjacent(self) -> None:
        editor = make_editor()
        draw(editor, [(0, 0), (0, 1), (1, 1), (1, 0)])
        self.assertFalse(editor.extend_path((0, 0)), "Không đi đè lên đường đã vẽ")
        self.assertEqual(editor.path_draft, [(0, 0), (0, 1), (1, 1), (1, 0)])

    def test_drag_back_removes_last_cell(self) -> None:
        editor = make_editor()
        draw(editor, [(0, 0), (1, 0), (2, 0)])
        self.assertTrue(editor.extend_path((1, 0)), "Kéo ngược về ô trước = lùi 1 ô")
        self.assertEqual(editor.path_draft, [(0, 0), (1, 0)])
        self.assertFalse(editor.extend_path((1, 0)), "Đang ở cuối nét vẽ thì không lùi thêm")

    def test_extend_ignores_inactive_cell(self) -> None:
        editor = make_editor()
        editor.level.set_cell_active((1, 0), False)
        editor.begin_path((0, 0))
        self.assertFalse(editor.extend_path((1, 0)), "Ô trống (ngoài board) không nối được")
        self.assertEqual(editor.path_length(), 1)

    def test_begin_on_inactive_cell_does_nothing(self) -> None:
        editor = make_editor()
        messages = status_log(editor)
        editor.level.set_cell_active((2, 2), False)
        editor.begin_path((2, 2))
        self.assertEqual(editor.path_length(), 0)
        self.assertTrue(messages and "THUỘC BOARD" in messages[-1], "Có báo lỗi rõ ràng")

    def test_clear_path_draft(self) -> None:
        editor = make_editor()
        draw(editor, ROUTE)
        editor.clear_path_draft()
        self.assertEqual(editor.path_length(), 0)

    def test_replace_level_clears_draft(self) -> None:
        editor = make_editor()
        draw(editor, ROUTE)
        editor.replace_level(make_editor().level)
        self.assertEqual(editor.path_length(), 0, "Nét vẽ thuộc màn đang vẽ → đổi màn thì bỏ")

    def test_path_changed_events(self) -> None:
        editor = make_editor()
        events: list[list] = []
        editor.events.on(EV_PATH_CHANGED, lambda draft: events.append(list(draft)))
        editor.begin_path((0, 0))
        editor.extend_path((1, 0))
        editor.clear_path_draft()
        self.assertEqual([len(item) for item in events], [1, 2, 0])


class ApplyPathWallsTest(unittest.TestCase):
    """Ctrl+Enter: biến nét vẽ thành màn chơi (S/F + tường bên hông + max_steps)."""

    def test_apply_needs_at_least_two_cells(self) -> None:
        editor = make_editor()
        messages = status_log(editor)
        self.assertFalse(editor.apply_path_walls(), "1 ô thì chưa sinh được màn")
        editor.begin_path((0, 0))
        self.assertFalse(editor.apply_path_walls())
        self.assertTrue(any("2 ô" in message for message in messages))

    def test_apply_sets_start_end_and_lateral_walls(self) -> None:
        editor = make_editor()
        draw(editor, ROUTE)
        self.assertTrue(editor.apply_path_walls())
        level = editor.level
        self.assertEqual(level.start, ROUTE[0], "S = ô ĐẦU của nét vẽ")
        self.assertEqual(level.end, ROUTE[-1], "F = ô CUỐI của nét vẽ")
        for index, cell in enumerate(ROUTE):
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                neighbour = (cell[0] + dx, cell[1] + dy)
                ref = path_edge_ref(cell, dx, dy)
                connected = (index > 0 and ROUTE[index - 1] == neighbour) \
                    or (index + 1 < len(ROUTE) and ROUTE[index + 1] == neighbour)
                if connected:
                    self.assertFalse(level.has_wall(ref),
                                     "Lối đi của nét vẽ phải MỞ (%s)" % (ref,))
                elif level.is_cell_active(neighbour) and not level.is_outline(ref):
                    self.assertTrue(level.has_wall(ref),
                                    "Cạnh bên hông phải là tường (%s)" % (ref,))

    def test_apply_makes_route_the_only_way(self) -> None:
        editor = make_editor()
        draw(editor, ROUTE)
        editor.apply_path_walls()
        info = solver.analyze(editor.level)
        self.assertTrue(info["solved"])
        self.assertEqual(info["path"], ROUTE, "Đường ngắn nhất = ĐÚNG nét vẽ (đường duy nhất)")
        self.assertEqual(info["path_length"], len(ROUTE) - 1)
        self.assertEqual(info["reachable_cells"], len(ROUTE),
                         "Chỉ các ô của nét vẽ đi tới được (bàn còn lại bị khoá kín)")

    def test_apply_sets_max_steps(self) -> None:
        editor = make_editor()
        draw(editor, ROUTE)
        editor.apply_path_walls()
        self.assertEqual(editor.level.max_steps, len(ROUTE) - 1 + PATH_WALL_EXTRA_STEPS)
        self.assertEqual(editor.level.max_steps, solver.auto_max_steps(editor.level))

    def test_apply_opens_walls_that_blocked_the_route(self) -> None:
        editor = make_editor()
        # 3 cạnh NẰM TRÊN nét vẽ (nối 2 ô liền nhau) — nếu đang là tường thì phải được MỞ
        blockers = [("v", 1, 0), ("v", 2, 0), ("h", 2, 1)]
        for ref in blockers:
            editor.level.set_wall(ref, True, True)
        draw(editor, ROUTE[:4])
        editor.apply_path_walls()
        for ref in blockers:
            self.assertFalse(editor.level.has_wall(ref), "Cạnh của nét vẽ phải được MỞ (%s)" % (ref,))
        self.assertTrue(editor.level.has_wall(("v", 3, 0)),
                        "Cạnh BÊN HÔNG vẫn được dựng tường (v,3,0)")
        self.assertTrue(solver.analyze(editor.level)["solved"], "Nét vẽ luôn đi được sau khi sinh")

    def test_apply_hidden_walls_option(self) -> None:
        editor = make_editor()
        draw(editor, ROUTE)
        editor.apply_path_walls(visible=False)
        ref = ("h", 1, 1)   # cạnh dưới ô (1,0) — cạnh BÊN HÔNG của nét vẽ
        self.assertTrue(editor.level.has_wall(ref))
        self.assertFalse(editor.level.is_visible(ref), "Được phép sinh tường ẨN")

    def test_apply_is_undoable(self) -> None:
        editor = make_editor()
        before = editor.level.snapshot()
        draw(editor, ROUTE)
        editor.apply_path_walls()
        self.assertNotEqual(editor.level.snapshot(), before)
        editor.undo()
        self.assertEqual(editor.level.snapshot(), before, "Ctrl+Z trả màn về trước khi sinh tường")

    def test_apply_marks_level_dirty(self) -> None:
        editor = make_editor()
        draw(editor, ROUTE)
        editor.apply_path_walls()
        self.assertTrue(editor.dirty)

    def test_apply_status_says_unique(self) -> None:
        editor = make_editor()
        messages = status_log(editor)
        draw(editor, ROUTE)
        editor.apply_path_walls()
        self.assertTrue(any("DUY NHẤT" in message for message in messages), messages[-1:])

    def test_apply_keeps_draft_for_reuse(self) -> None:
        editor = make_editor()
        draw(editor, ROUTE)
        editor.apply_path_walls()
        self.assertEqual(editor.path_draft, ROUTE, "Nét vẽ vẫn còn để vẽ tiếp / sửa lại")

    def test_apply_rejects_route_outside_board(self) -> None:
        editor = make_editor()
        draw(editor, ROUTE)
        editor.level.set_cell_active(ROUTE[3], False)
        messages = status_log(editor)
        self.assertFalse(editor.apply_path_walls(), "Ô của nét vẽ bị bỏ khỏi board → không sinh")
        self.assertTrue(any("NGOÀI BOARD" in message for message in messages))

    def test_validator_has_no_error_after_apply(self) -> None:
        editor = make_editor()
        draw(editor, ROUTE)
        editor.apply_path_walls()
        errors = [issue.format() for issue in validator.validate(editor.level) if issue.is_error]
        self.assertEqual(errors, [])

    def test_apply_with_mode_edit_value_still_works(self) -> None:
        """Màn có kiểu edit riêng (vd minesweeper ghim mìn) vẫn sinh tường bình thường."""
        editor = make_editor()
        editor.level.mode_id = "minesweeper"
        editor.level.set_custom_value((4, 0), 1)
        draw(editor, ROUTE)
        editor.apply_path_walls()
        self.assertEqual(editor.level.custom_value((4, 0)), 1, "Không đụng dữ liệu riêng của chế độ")
        self.assertEqual(solver.analyze(editor.level)["path"], ROUTE)


if __name__ == "__main__":
    unittest.main()
