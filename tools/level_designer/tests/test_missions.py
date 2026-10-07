"""Test: NHIỆM VỤ (mission) — model, ghi/đọc .tres, validator, undo trong controller.

Game đọc dữ liệu này ở `scripts/resources/level_data.gd`:
    mission_types = PackedStringArray("no_wall", "steps_max", ...)
    mission_params = PackedInt32Array(0, 15, ...)
"""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from app.controllers.editor_controller import EditorController  # noqa: E402
from app.models import missions as chal  # noqa: E402
from app.models.repository import LevelRepository  # noqa: E402
from app.services import tres_io, validator  # noqa: E402


def make_level(width: int = 3, height: int = 3):
    return LevelRepository().create_level(99, width, height)


class MissionModelTest(unittest.TestCase):
    def test_new_level_has_no_explicit_missions(self) -> None:
        level = make_level()
        self.assertEqual(level.missions, [])
        # Không khai báo -> game dùng 3 nhiệm vụ mặc định
        self.assertEqual([c[0] for c in level.default_missions()],
                         [chal.NO_WALL, chal.STEPS_MAX, chal.TIME_MAX])

    def test_set_and_clear(self) -> None:
        level = make_level()
        level.max_steps = 12
        level.par_time = 40.0
        self.assertTrue(level.set_mission(0, chal.STEPS_MAX))
        self.assertEqual(level.missions[0][0], chal.STEPS_MAX)
        # Tham số <= 0 -> tự lấy mặc định theo màn
        self.assertEqual(level.missions[0][1], 12)

        self.assertTrue(level.set_mission(1, chal.TIME_MAX, 30))
        self.assertEqual(level.missions[1], (chal.TIME_MAX, 30))

        self.assertTrue(level.clear_mission(0))
        self.assertEqual(len(level.missions), 1)
        self.assertEqual(level.missions[0][0], chal.TIME_MAX)

    def test_max_three_missions(self) -> None:
        level = make_level()
        for slot, type_id in enumerate([chal.NO_WALL, chal.NO_REVISIT, chal.NO_HINT]):
            level.set_mission(slot, type_id)
        self.assertEqual(len(level.missions), chal.MAX_PER_LEVEL)
        # slot ngoài 0..2 bị từ chối
        self.assertFalse(level.set_mission(3, chal.VISIT_ALL))
        self.assertEqual(len(level.missions), chal.MAX_PER_LEVEL)

    def test_invalid_type_is_rejected(self) -> None:
        level = make_level()
        self.assertFalse(level.set_mission(0, "khong_ton_tai"))
        self.assertEqual(level.missions, [])

    def test_clear_all(self) -> None:
        level = make_level()
        level.missions = level.default_missions()
        self.assertTrue(level.clear_all_missions())
        self.assertEqual(level.missions, [])
        self.assertFalse(level.clear_all_missions())

    def test_snapshot_keeps_missions(self) -> None:
        level = make_level()
        level.set_mission(0, chal.LEN_MAX_PERCENT, 60)
        snap = level.snapshot()
        level.missions = []
        level.restore(snap)
        self.assertEqual(level.missions, [(chal.LEN_MAX_PERCENT, 60)])


class MissionTresIoTest(unittest.TestCase):
    def test_emitted_syntax(self) -> None:
        level = make_level()
        level.set_mission(0, chal.NO_WALL)
        level.set_mission(1, chal.STEPS_MAX, 15)
        text = tres_io.dumps(level)
        self.assertIn('mission_types = PackedStringArray("no_wall", "steps_max")', text)
        self.assertIn("mission_params = PackedInt32Array(0, 15)", text)

    def test_empty_arrays_like_godot(self) -> None:
        level = make_level()
        text = tres_io.dumps(level)
        self.assertIn("mission_types = PackedStringArray()", text)
        self.assertIn("mission_params = PackedInt32Array()", text)

    def test_roundtrip(self) -> None:
        level = make_level(4, 4)
        level.set_mission(0, chal.ONLY_NUMBERED)
        level.set_mission(1, chal.SUM_GE, 12)
        level.set_mission(2, chal.VISIT_ALL_NUMBERED)
        again = tres_io.loads(tres_io.dumps(level))
        self.assertEqual(again.missions, level.missions)

    def test_legacy_file_without_mission_keys(self) -> None:
        # File .tres cũ (chưa có 2 dòng mission) phải đọc được, danh sách rỗng
        level = make_level()
        text = "\n".join(
            line for line in tres_io.dumps(level).splitlines()
            if not line.startswith("mission_")
        ) + "\n"
        again = tres_io.loads(text)
        self.assertEqual(again.missions, [])

    def test_reading_more_than_three_is_capped(self) -> None:
        level = make_level()
        text = tres_io.dumps(level).replace(
            "mission_types = PackedStringArray()",
            'mission_types = PackedStringArray("no_wall", "steps_max", "time_max", "no_hint")',
        ).replace(
            "mission_params = PackedInt32Array()",
            "mission_params = PackedInt32Array(0, 10, 30, 0)",
        )
        again = tres_io.loads(text)
        self.assertEqual(len(again.missions), chal.MAX_PER_LEVEL)


class MissionValidatorTest(unittest.TestCase):
    def messages(self, level) -> list[str]:
        return [issue.message for issue in validator.validate(level)]

    def test_default_hint_when_empty(self) -> None:
        msgs = " | ".join(self.messages(make_level()))
        self.assertIn("3 nhiệm vụ mặc định", msgs)

    def test_too_many_is_error(self) -> None:
        level = make_level()
        level.missions = [
            (chal.NO_WALL, 0), (chal.NO_REVISIT, 0), (chal.NO_HINT, 0), (chal.VISIT_ALL, 0),
        ]
        issues = validator.validate(level)
        self.assertTrue(any(i.is_error and "TỐI ĐA" in i.message for i in issues))

    def test_duplicate_is_warning(self) -> None:
        level = make_level()
        level.missions = [(chal.NO_HINT, 0), (chal.NO_HINT, 0)]
        issues = validator.validate(level)
        self.assertTrue(any(i.severity == validator.LEVEL_WARNING and "lặp lại" in i.message
                            for i in issues))

    def test_numbered_contradiction_is_error(self) -> None:
        level = make_level()
        level.missions = [(chal.ONLY_NUMBERED, 0), (chal.AVOID_NUMBERED, 0)]
        issues = validator.validate(level)
        self.assertTrue(any(i.is_error and "mâu thuẫn" in i.message for i in issues))

    def test_steps_below_shortest_path_is_error(self) -> None:
        level = make_level()          # 3x3 trống: đường ngắn nhất 4 bước
        level.missions = [(chal.STEPS_MAX, 2)]
        issues = validator.validate(level)
        self.assertTrue(any(i.is_error and "ngắn nhất" in i.message for i in issues))

    def test_len_max_percent_below_minimum_is_error(self) -> None:
        level = make_level()          # 9 ô, đường ngắn nhất 5 ô -> cần ~56%
        level.missions = [(chal.LEN_MAX_PERCENT, 20)]
        issues = validator.validate(level)
        self.assertTrue(any(i.is_error and "đường ngắn nhất" in i.message for i in issues))

    def test_visit_all_with_blocked_cells_is_error(self) -> None:
        level = make_level()
        # Bịt kín ô (2, 2): 2 tường dọc + 2 tường ngang quanh nó
        level.set_wall(("v", 2, 2), True)
        level.set_wall(("v", 3, 2), True)
        level.set_wall(("h", 2, 2), True)
        level.set_wall(("h", 2, 3), True)
        level.missions = [(chal.VISIT_ALL, 0)]
        issues = validator.validate(level)
        self.assertTrue(any(i.is_error and "không tới được" in i.message for i in issues))

    def test_sum_gt_impossible_is_error(self) -> None:
        level = make_level()
        level.missions = [(chal.SUM_GT, 9999)]
        issues = validator.validate(level)
        self.assertTrue(any(i.is_error and "không thể đạt" in i.message for i in issues))

    def test_param_out_of_range_is_error(self) -> None:
        level = make_level()
        level.missions = [(chal.LEN_MIN_PERCENT, 500)]
        issues = validator.validate(level)
        self.assertTrue(any(i.is_error and "ngoài khoảng" in i.message for i in issues))

    def test_full_valid_set_has_no_errors(self) -> None:
        level = make_level(5, 5)
        level.set_mission(0, chal.NO_WALL)
        level.set_mission(1, chal.STEPS_MAX, 12)
        level.set_mission(2, chal.LEN_MAX_PERCENT, 90)
        issues = validator.validate(level)
        self.assertFalse([i for i in issues if i.is_error], "không được có lỗi: %s"
                         % [i.message for i in issues])


class MissionControllerTest(unittest.TestCase):
    def test_set_and_undo(self) -> None:
        editor = EditorController(make_level())
        editor.set_mission(0, chal.NO_REVISIT)
        self.assertEqual(editor.level.missions, [(chal.NO_REVISIT, 0)])
        self.assertTrue(editor.can_undo())
        editor.undo()
        self.assertEqual(editor.level.missions, [])

    def test_set_param(self) -> None:
        editor = EditorController(make_level())
        editor.set_mission(0, chal.STEPS_MAX, 10)
        editor.set_mission_param(0, 16)
        self.assertEqual(editor.level.missions[0], (chal.STEPS_MAX, 16))
        # Loại không cần tham số thì đổi param bị bỏ qua
        editor.set_mission(1, chal.NO_HINT)
        editor.set_mission_param(1, 5)
        self.assertEqual(editor.level.missions[1], (chal.NO_HINT, 0))

    def test_fill_default_and_reset(self) -> None:
        editor = EditorController(make_level())
        editor.level.max_steps = 18
        editor.level.par_time = 50.0
        editor.fill_default_missions()
        self.assertEqual(editor.level.missions[:2], [(chal.NO_WALL, 0), (chal.STEPS_MAX, 18)])
        self.assertEqual(editor.level.missions[2], (chal.TIME_MAX, 50))
        editor.reset_missions()
        self.assertEqual(editor.level.missions, [])


class MissionRegistryTest(unittest.TestCase):
    def test_registry_matches_game_ids(self) -> None:
        # 17 loại, id không trùng, id trong ORDER đều hợp lệ
        self.assertEqual(len(chal.ORDER), len(set(chal.ORDER)))
        self.assertEqual(len(chal.ORDER), 17)
        for type_id in chal.ORDER:
            self.assertTrue(chal.is_valid(type_id), type_id)
            self.assertTrue(chal.label(type_id))
        self.assertEqual(set(chal.DEFAULT_TYPES), {chal.NO_WALL, chal.STEPS_MAX, chal.TIME_MAX})

    def test_no_wrong_submit_for_wall_builder(self) -> None:
        # Loại mới 2026-10 (game: MissionTypes.NO_WRONG_SUBMIT — riêng Wall Builder)
        self.assertTrue(chal.is_valid(chal.NO_WRONG_SUBMIT))
        self.assertFalse(chal.has_param(chal.NO_WRONG_SUBMIT))
        self.assertIn(chal.NO_WRONG_SUBMIT, chal.NO_PARAM_TYPES)
        self.assertIn(chal.NO_WRONG_SUBMIT, chal.combo_values()[-1])

    def test_combo_roundtrip(self) -> None:
        for type_id in chal.ORDER:
            self.assertEqual(chal.from_combo(chal.to_combo(type_id)), type_id)


if __name__ == "__main__":
    unittest.main()
