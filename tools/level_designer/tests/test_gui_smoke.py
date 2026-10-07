"""Test: dựng cửa sổ Tkinter thật (bỏ qua nếu máy không có màn hình)."""

from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from app.controllers.app_controller import AppController  # noqa: E402
from app.models.repository import LevelRepository  # noqa: E402


class GuiSmokeTest(unittest.TestCase):
    def setUp(self) -> None:
        try:
            import tkinter  # noqa: F401

            root = tkinter.Tk()
        except Exception as error:  # noqa: BLE001
            self.skipTest("Không có màn hình/Tk: %s" % error)
        root.destroy()

        self.tmp = tempfile.TemporaryDirectory()
        # Tạo sẵn 1 màn trong thư mục tạm để cửa sổ mở nó
        repo = LevelRepository(Path(self.tmp.name))
        level = repo.create_level(1, 4, 4)
        level.set_wall(("v", 1, 1), True, False)
        repo.save(level)
        self.app = AppController(repository=LevelRepository(Path(self.tmp.name)))

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def test_window_builds_and_updates(self) -> None:
        from app.views.main_window import MainWindow

        window = MainWindow(app=self.app, open_level_id=1)
        try:
            window.update()
            self.assertIn("level_1.tres", window.title())
            self.assertEqual(self.app.editor.level.level_id, 1)

            # Vẽ thử 1 tường qua controller rồi xem canvas có thêm phần tử
            before = len(window.grid.canvas.find_all())
            window.editor.begin_stroke()
            window.editor.apply_wall_tool(("h", 2, 2), toggle=True)
            window.editor.end_stroke()
            window.update()
            self.assertGreater(len(window.grid.canvas.find_all()), before)

            # Bật/tắt các tuỳ chọn xem + zoom không được lỗi
            window._toggle_view("show_path")
            window._toggle_view("show_numbers")
            window._toggle_view("show_hidden")
            window.grid.zoom(16)
            window.grid.reset_zoom()
            window.update()

            # Toạ độ -> cạnh/ô phải tính đúng
            cell, ref, _ = window.grid._locate(54 + 10, 54 + 10)
            self.assertEqual(cell, (0, 0))
            self.assertEqual(ref, ("v", 0, 0))

            # Inspector hiển thị thông tin hợp lệ
            self.assertEqual(window.inspector.var_width.get(), 4)
            window.inspector.var_width.set(5)
            window.inspector._on_int("width")()
            window.update()
            self.assertEqual(self.app.editor.level.width, 5)

            # Công cụ sửa ô board: bấm vào ô (0,0) để bỏ khỏi board
            from app.config import TOOL_CELL

            window.editor.set_tool(TOOL_CELL)
            self.assertTrue(self.app.editor.level.is_cell_active((0, 0)))
            origin = window.grid._origin()
            window.grid._apply_at(origin[0] + 10, origin[1] + 10, toggle=True)
            window.update()
            self.assertFalse(self.app.editor.level.is_cell_active((0, 0)))
            self.assertEqual(self.app.editor.level.wall_count((0, 0)), 0)
            # Bật lại
            window.grid._apply_at(origin[0] + 10, origin[1] + 10, toggle=True)
            self.assertTrue(self.app.editor.level.is_cell_active((0, 0)))

            # Nút "Toàn bộ ô = board" trả về hình chữ nhật
            self.app.editor.fill_board()
            window.update()
            self.assertTrue(self.app.editor.level.is_full_rect())

            # CÔNG CỤ 8: vẽ đường đi trên lưới rồi sinh tường quanh đường
            from app.config import TOOL_PATH

            def cell_xy(cell: tuple[int, int]) -> tuple[float, float]:
                box = window.grid._cell_box(cell)
                return ((box[0] + box[2]) / 2, (box[1] + box[3]) / 2)

            window.editor.set_tool(TOOL_PATH)
            window.grid._apply_at(*cell_xy((0, 0)), toggle=True)
            window.update()
            self.assertEqual(window.editor.path_length(), 1)
            self.assertTrue(window._path_box.winfo_manager(),
                            "Khối 'Đường đi' phải tự hiện khi có nét vẽ")

            window.grid._apply_at(*cell_xy((1, 0)), toggle=False)
            window.grid._apply_at(*cell_xy((2, 0)), toggle=False)
            window.update()
            self.assertEqual(window.editor.path_length(), 3)

            window.action_apply_path()
            window.update()
            self.assertEqual(self.app.editor.level.start, (0, 0), "S = ô đầu nét vẽ")
            self.assertEqual(self.app.editor.level.end, (2, 0), "F = ô cuối nét vẽ")
            self.assertTrue(self.app.editor.level.has_wall(("h", 0, 1)),
                            "Cạnh bên hông của nét vẽ phải thành tường")

            window.action_clear_path_draft()
            window.update()
            self.assertEqual(window.editor.path_length(), 0)
            self.assertFalse(window._path_box.winfo_manager(),
                             "Xoá nét vẽ → khối 'Đường đi' tự ẩn")

            # Chế độ CÓ "path" (Countdown Cost): ô "Tổng chi phí đường đi" nằm ở BẢNG PHẢI (Lưới & luật chơi),
            # KHÔNG nằm trên thanh công cụ (trước đây để trên toolbar làm tràn ngang cửa sổ hẹp).
            window.editor.set_property("mode_id", "countdown_cost")
            window.update()
            self.assertFalse(hasattr(window, "_sum_spin"), "Thanh công cụ KHÔNG còn ô 'Tổng …'")
            self.assertTrue(window.inspector._path_sum_box.winfo_manager(),
                            "Ô 'Tổng …' phải hiện trong mục Lưới & luật chơi")
            self.assertIn("Tổng chi phí", window.inspector.lbl_path_sum.cget("text"))
            self.assertIn("Sinh giá trị", window._path_apply_button.cget("text"))

            window.editor.begin_path((2, 1))
            window.editor.extend_path((3, 1))
            window.editor.extend_path((4, 1))
            window.editor.extend_path((4, 2))
            window.update()
            self.assertTrue(window._path_box.winfo_manager(), "Đang vẽ → hiện khối ĐƯỜNG ĐI")
            self.assertFalse(window._value_box.winfo_manager(),
                             "Đang vẽ → ẨN khối GIÁ TRỊ (2 khối không bao giờ cùng lúc)")
            for index, row in enumerate(window._toolbar_rows, start=1):
                self.assertLessEqual(
                    row.winfo_reqwidth(), window.winfo_width(),
                    "Thanh công cụ dòng %d bị TRÀN khi đang vẽ đường (cần %d px > %d px)"
                    % (index, row.winfo_reqwidth(), window.winfo_width()))
            window.inspector.var_path_sum.set(6)
            window.inspector._on_path_sum()
            window.update()
            window.action_apply_path()
            window.update()
            painted = sum(self.app.editor.level.custom_value(cell) for cell in [(3, 1), (4, 1)])
            self.assertEqual(painted, 6, "Tổng chi phí tô trên đường = đúng ô 'Tổng …'")
            self.assertEqual(window.editor.path_value_sum(), 6)
            self.assertEqual(window.editor.level.start, (2, 1))
            self.assertEqual(window.editor.level.end, (4, 2))

            # THANH CÔNG CỤ KHÔNG ĐƯỢC TRÀN: dựng ở cỡ cửa sổ NHỎ NHẤT (1080) rồi đo từng dòng
            window.geometry("1080x700")
            window.update()
            for index, row in enumerate(window._toolbar_rows, start=1):
                self.assertLessEqual(
                    row.winfo_reqwidth(), window.winfo_width(),
                    "Thanh công cụ dòng %d bị TRÀN ngang (cần %d px > cửa sổ %d px)"
                    % (index, row.winfo_reqwidth(), window.winfo_width()))

            # Nút "Tô theo đường đi" trong bảng phải tô đúng theo đường NGẮN NHẤT khi chưa vẽ nét
            # (dọn tường để chắc chắn màn có đường S→F; đường 3 bước ⇒ 2 ô giữa 2 đầu ⇒ tổng phải trong 2..8)
            window.action_clear_path_draft()
            window.editor.clear_walls()
            window.inspector.var_path_sum.set(5)
            window.inspector._on_paint_path_sum()
            window.update()
            route = window.editor.resolve_path_for_values()[0]
            self.assertEqual(sum(self.app.editor.level.custom_value(cell) for cell in route[1:-1]), 5)

            # CHALLENGE: gắn luật thử thách qua khối "Thử thách (Challenge)" trong bảng phải
            from app.models import challenge_rules as chrules

            window.inspector.var_mode.set("challenge")
            window.inspector._commit("mode_id", "challenge")
            window.update()
            self.assertEqual(str(window.inspector.combo_challenge.cget("state")), "readonly",
                             "mode_id = challenge -> ô chọn luật phải bật")
            window.inspector.var_challenge_rule.set(chrules.to_combo(chrules.MOVE_LIMIT))
            window.inspector._on_challenge_rule()
            window.update()
            self.assertEqual(self.app.editor.level.challenge, chrules.MOVE_LIMIT)
            self.assertEqual(str(window.inspector.spin_challenge_param.cget("state")), "normal",
                             "luật có tham số -> ô tham số phải bật")
            window.inspector.var_challenge_param.set(12)
            window.inspector._on_challenge_param()
            self.assertEqual(self.app.editor.level.challenge_param, 12)
            # Chọn lại "— Không gắn luật —" -> bỏ luật
            window.inspector.var_challenge_rule.set(chrules.NONE_LABEL)
            window.inspector._on_challenge_rule()
            window.update()
            self.assertEqual(self.app.editor.level.challenge, "")
            # Về mode play -> ô chọn luật bị khoá
            window.inspector.var_mode.set("play")
            window.inspector._commit("mode_id", "play")
            window.update()
            self.assertEqual(str(window.inspector.combo_challenge.cget("state")), "disabled",
                             "mode play -> ô chọn luật khoá (luật không được áp dụng)")
        finally:
            window.destroy()

    def test_unsaved_guard_can_be_skipped(self) -> None:
        from app.views.main_window import MainWindow

        window = MainWindow(app=self.app, open_level_id=1)
        try:
            self.assertFalse(window.editor.dirty)
            self.assertTrue(window._confirm_discard())  # không hỏi khi chưa đổi gì
        finally:
            window.destroy()


if __name__ == "__main__":
    unittest.main()
