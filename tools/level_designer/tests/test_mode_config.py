"""Test CẤU HÌNH CHẾ ĐỘ sau đợt tái cấu trúc: chỉ còn play · blind_memory · wall_builder · challenge.

Bối cảnh: 6 chế độ (minesweeper · sum_path · countdown_cost · fading_ink · one_stroke · fog_of_war) đã
bị xoá khỏi game; Fog of War trở thành LUẬT thử thách `fog_of_war`. File .tres CŨ vẫn có thể còn khai
các id đó ⇒ validator phải báo LỖI rõ ràng, và `custom_cell_values` vẫn phải đọc/ghi được (tương thích
ngược với `LevelData.custom_cell_values` bên game).
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
    MODE_LABELS,
    REMOVED_MODE_IDS,
    RETIRED_MODE_IDS,
    mode_edit_spec,
)
from app.models import challenge_rules as chrules  # noqa: E402
from app.models.repository import LevelRepository  # noqa: E402
from app.services import tres_io, validator  # noqa: E402


class ModeRegistryTest(unittest.TestCase):
    def test_only_four_modes(self) -> None:
        self.assertEqual(MODE_IDS, ("play", "blind_memory", "wall_builder", "challenge"))
        self.assertEqual(sorted(MODE_LABELS), sorted(MODE_IDS), "nhãn phải khớp danh sách chế độ")

    def test_removed_modes_are_not_selectable(self) -> None:
        self.assertEqual(len(REMOVED_MODE_IDS), 6)
        for mode_id in REMOVED_MODE_IDS:
            self.assertNotIn(mode_id, MODE_IDS, mode_id)
            self.assertNotIn(mode_id, MODE_LABELS, mode_id)
            self.assertIn(mode_id, RETIRED_MODE_IDS, mode_id)

    def test_fog_of_war_is_a_challenge_rule_now(self) -> None:
        self.assertIn(chrules.FOG_OF_WAR, chrules.ORDER)
        self.assertNotIn(chrules.FOG_OF_WAR, MODE_IDS)

    def test_removed_mode_falls_back_to_play_spec(self) -> None:
        play = mode_edit_spec("play")
        for mode_id in REMOVED_MODE_IDS:
            spec = mode_edit_spec(mode_id)
            self.assertEqual(spec["kind"], play["kind"], mode_id)
            self.assertEqual(spec["path_action"], play["path_action"], mode_id)


class RemovedModeValidationTest(unittest.TestCase):
    def test_removed_mode_is_an_error(self) -> None:
        for mode_id in REMOVED_MODE_IDS:
            level = LevelRepository().create_level(101, 4, 4)
            level.mode_id = mode_id
            issues = validator.validate(level)
            errors = [issue.message for issue in issues if issue.is_error]
            self.assertTrue(errors, mode_id)
            self.assertTrue(any("ĐÃ BỊ XOÁ" in message for message in errors), errors)

    def test_dungeon_keeps_its_own_message(self) -> None:
        level = LevelRepository().create_level(101, 4, 4)
        level.mode_id = "dungeon"
        messages = [issue.message for issue in validator.validate(level) if issue.is_error]
        self.assertTrue(any("BẤT TẬN" in message for message in messages), messages)


class CustomValuesCompatTest(unittest.TestCase):
    """`custom_cell_values` không chế độ nào dùng nữa, nhưng vẫn phải đọc/ghi đúng (màn cũ)."""

    def test_parse_and_dump_roundtrip(self) -> None:
        values, unknown = tres_io.parse_custom_values('{"0,1": 5, "2,3": 7}')
        self.assertEqual(values, {(0, 1): 5, (2, 3): 7})
        self.assertFalse(unknown)

    def test_empty_and_unknown(self) -> None:
        self.assertEqual(tres_io.parse_custom_values("{}"), ({}, False))
        self.assertEqual(tres_io.parse_custom_values(""), ({}, False))
        _, unknown = tres_io.parse_custom_values('{"0,1": 5, "la": "lạ"}')
        self.assertTrue(unknown, "phần lạ phải được đánh dấu để lúc ghi giữ nguyên")

    def test_model_keeps_values_across_snapshot(self) -> None:
        level = LevelRepository().create_level(101, 4, 4)
        level.set_custom_value((1, 1), 4)
        snapshot = level.snapshot()
        level.clear_custom_values()
        self.assertEqual(level.custom_value_count(), 0)
        level.restore(snapshot)
        self.assertEqual(level.custom_value((1, 1)), 4)


if __name__ == "__main__":
    unittest.main()
