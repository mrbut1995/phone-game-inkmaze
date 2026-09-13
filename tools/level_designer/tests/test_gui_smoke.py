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
