"""Test: đọc/ghi .tres - phải khớp định dạng Godot 4 sinh ra."""

from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from app import config  # noqa: E402
from app.models.repository import LevelRepository  # noqa: E402
from app.services import tres_io  # noqa: E402

REAL_LEVELS = sorted((config.LEVELS_DIR).glob("level_*.tres")) if config.LEVELS_DIR.exists() else []


class TestTresFormat(unittest.TestCase):
    def test_emit_header_and_fields(self) -> None:
        level = LevelRepository().create_level(7, 3, 3)
        level.set_wall(("v", 1, 1), True, False)
        text = tres_io.dumps(level)

        self.assertIn('[gd_resource type="Resource" script_class="LevelData" load_steps=2 format=3', text)
        self.assertIn('[ext_resource type="Script" path="%s" id="%s"]' % (
            config.LEVEL_SCRIPT_RES, config.LEVEL_SCRIPT_ID), text)
        self.assertIn("script = ExtResource(", text)
        self.assertIn("start_pos = Vector2i(0, 2)", text)
        self.assertIn("end_pos = Vector2i(2, 0)", text)
        self.assertIn("par_time = 30.0", text)
        self.assertIn("custom_cell_values = {}", text)
        self.assertTrue(text.rstrip().endswith("}"), "dòng cuối phải là custom_cell_values = {}")
        for key in ("v_walls = PackedByteArray(", "v_walls_visible = PackedByteArray(",
                    "h_walls = PackedByteArray(", "h_walls_visible = PackedByteArray("):
            self.assertIn(key, text)

    def test_arrays_are_0_or_1_and_right_size(self) -> None:
        level = LevelRepository().create_level(8, 4, 3)
        text = tres_io.dumps(level)
        for line in text.splitlines():
            if line.startswith(("v_walls = ", "v_walls_visible = ", "h_walls = ", "h_walls_visible = ")):
                values = line.split("(", 1)[1].rstrip(")")
                parts = [int(v) for v in values.split(",") if v.strip()]
                self.assertTrue(all(v in (0, 1) for v in parts), line)
        self.assertEqual(len(level.v_walls), (4 + 1) * 3)
        self.assertEqual(len(level.h_walls), 4 * (3 + 1))

    def test_roundtrip_real_levels(self) -> None:
        if not REAL_LEVELS:
            self.skipTest("Không có file .tres thật trong resources/levels")
        repo = LevelRepository()
        for path in REAL_LEVELS:
            with self.subTest(level=path.name):
                level = repo.load_path(path)
                again = tres_io.loads(tres_io.dumps(level))
                self.assertEqual(level.snapshot(), again.snapshot())
                self.assertTrue(level.start_end_ok())

    def test_uid_is_preserved(self) -> None:
        text = (
            '[gd_resource type="Resource" script_class="LevelData" load_steps=2 format=3 '
            'uid="uid://abc123"]\n'
            '[ext_resource type="Script" path="res://scripts/resources/level_data.gd" id="1_level"]\n'
            "\n"
            "[resource]\n"
            'script = ExtResource("1_level")\n'
            "level_id = 5\n"
            'level_title = "Test"\n'
            "chapter = 1\n"
            'mode_id = "play"\n'
            'difficulty = "easy"\n'
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
        self.assertEqual(level.source_uid, "uid://abc123")
        self.assertEqual(level.level_id, 5)
        self.assertEqual(level.max_steps, 4)
        emitted = tres_io.dumps(level)
        self.assertIn('uid="uid://abc123"', emitted)

    def test_missing_arrays_do_not_crash(self) -> None:
        text = (
            '[gd_resource type="Resource" script_class="LevelData" load_steps=2 format=3]\n'
            '[ext_resource type="Script" path="res://scripts/resources/level_data.gd" id="1_level"]\n'
            "[resource]\n"
            'script = ExtResource("1_level")\n'
            "level_id = 3\n"
            "width = 3\n"
            "height = 3\n"
            "start_pos = Vector2i(0, 2)\n"
            "end_pos = Vector2i(2, 0)\n"
        )
        level = tres_io.loads(text)
        level.normalize_arrays()
        self.assertEqual(len(level.v_walls), 12)
        self.assertEqual(len(level.h_walls), 12)

    def test_save_and_load_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = LevelRepository(Path(tmp))
            level = repo.create_level(12, 3, 3)
            level.level_title = 'Tiêu đề "đặc biệt" \\ test'
            path = repo.save(level)
            self.assertTrue(path.exists())
            again = repo.load(12)
            self.assertEqual(level.level_title, again.level_title)
            self.assertEqual(level.snapshot(), again.snapshot())


if __name__ == "__main__":
    unittest.main()
