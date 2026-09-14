"""Test: THỬ THÁCH (challenge) — model, ghi/đọc .tres, validator, undo trong controller.

Game đọc dữ liệu này ở `scripts/resources/level_data.gd`:
    challenge_types = PackedStringArray("no_wall", "steps_max", ...)
    challenge_params = PackedInt32Array(0, 15, ...)
"""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from app.controllers.editor_controller import EditorController  # noqa: E402
from app.models import challenges as chal  # noqa: E402
from app.models.repository import LevelRepository  # noqa: E402
from app.services import tres_io, validator  # noqa: E402


def make_level(width: int = 3, height: int = 3):
    return LevelRepository().create_level(99, width, height)


class ChallengeModelTest(unittest.TestCase):
    def test_new_level_has_no_explicit_challenges(self) -> None:
        level = make_level()
        self.assertEqual(level.challenges, [])
        # Không khai báo -> game dùng 3 thử thách mặc định
        self.assertEqual([c[0] for c in level.default_challenges()],
                         [chal.NO_WALL, chal.STEPS_MAX, chal.TIME_MAX])

    def test_set_and_clear(self) -> None:
        level = make_level()
        level.max_steps = 12
        level.par_time = 40.0
        self.assertTrue(level.set_challenge(0, chal.STEPS_MAX))
        self.assertEqual(level.challenges[0][0], chal.STEPS_MAX)
        # Tham số <= 0 -> tự lấy mặc định theo màn
        self.assertEqual(level.challenges[0][1], 12)

        self.assertTrue(level.set_challenge(1, chal.TIME_MAX, 30))
        self.assertEqual(level.challenges[1], (chal.TIME_MAX, 30))

        self.assertTrue(level.clear_challenge(0))
        self.assertEqual(len(level.challenges), 1)
        self.assertEqual(level.challenges[0][0], chal.TIME_MAX)

    def test_max_three_challenges(self) -> None:
        level = make_level()
        for slot, type_id in enumerate([chal.NO_WALL, chal.NO_REVISIT, chal.NO_HINT]):
            level.set_challenge(slot, type_id)
        self.assertEqual(len(level.challenges), chal.MAX_PER_LEVEL)
        # slot ngoài 0..2 bị từ chối
        self.assertFalse(level.set_challenge(3, chal.VISIT_ALL))
        self.assertEqual(len(level.challenges), chal.MAX_PER_LEVEL)

    def test_invalid_type_is_rejected(self) -> None:
        level = make_level()
        self.assertFalse(level.set_challenge(0, "khong_ton_tai"))
        self.assertEqual(level.challenges, [])

    def test_clear_all(self) -> None:
        level = make_level()
        level.challenges = level.default_challenges()
        self.assertTrue(level.clear_all_challenges())
        self.assertEqual(level.challenges, [])
        self.assertFalse(level.clear_all_challenges())

    def test_snapshot_keeps_challenges(self) -> None:
        level = make_level()
        level.set_challenge(0, chal.LEN_MAX_PERCENT, 60)
        snap = level.snapshot()
        level.challenges = []
        level.restore(snap)
        self.assertEqual(level.challenges, [(chal.LEN_MAX_PERCENT, 60)])


class ChallengeTresIoTest(unittest.TestCase):
    def test_emitted_syntax(self) -> None:
        level = make_level()
        level.set_challenge(0, chal.NO_WALL)
        level.set_challenge(1, chal.STEPS_MAX, 15)
        text = tres_io.dumps(level)
        self.assertIn('challenge_types = PackedStringArray("no_wall", "steps_max")', text)
        self.assertIn("challenge_params = PackedInt32Array(0, 15)", text)

    def test_empty_arrays_like_godot(self) -> None:
        level = make_level()
        text = tres_io.dumps(level)
        self.assertIn("challenge_types = PackedStringArray()", text)
        self.assertIn("challenge_params = PackedInt32Array()", text)

    def test_roundtrip(self) -> None:
        level = make_level(4, 4)
        level.set_challenge(0, chal.ONLY_NUMBERED)
        level.set_challenge(1, chal.SUM_GE, 12)
        level.set_challenge(2, chal.VISIT_ALL_NUMBERED)
        again = tres_io.loads(tres_io.dumps(level))
        self.assertEqual(again.challenges, level.challenges)

    def test_legacy_file_without_challenge_keys(self) -> None:
        # File .tres cũ (chưa có 2 dòng challenge) phải đọc được, danh sách rỗng
        level = make_level()
        text = "\n".join(
            line for line in tres_io.dumps(level).splitlines()
            if not line.startswith("challenge_")
        ) + "\n"
        again = tres_io.loads(text)
        self.assertEqual(again.challenges, [])

    def test_reading_more_than_three_is_capped(self) -> None:
        level = make_level()
        text = tres_io.dumps(level).replace(
            "challenge_types = PackedStringArray()",
            'challenge_types = PackedStringArray("no_wall", "steps_max", "time_max", "no_hint")',
        ).replace(
            "challenge_params = PackedInt32Array()",
            "challenge_params = PackedInt32Array(0, 10, 30, 0)",
        )
        again = tres_io.loads(text)
        self.assertEqual(len(again.challenges), chal.MAX_PER_LEVEL)


class ChallengeValidatorTest(unittest.TestCase):
    def messages(self, level) -> list[str]:
        return [issue.message for issue in validator.validate(level)]

    def test_default_hint_when_empty(self) -> None:
        msgs = " | ".join(self.messages(make_level()))
        self.assertIn("3 thử thách mặc định", msgs)

    def test_too_many_is_error(self) -> None:
        level = make_level()
        level.challenges = [
            (chal.NO_WALL, 0), (chal.NO_REVISIT, 0), (chal.NO_HINT, 0), (chal.VISIT_ALL, 0),
        ]
        issues = validator.validate(level)
        self.assertTrue(any(i.is_error and "TỐI ĐA" in i.message for i in issues))

    def test_duplicate_is_warning(self) -> None:
        level = make_level()
        level.challenges = [(chal.NO_HINT, 0), (chal.NO_HINT, 0)]
        issues = validator.validate(level)
        self.assertTrue(any(i.severity == validator.LEVEL_WARNING and "lặp lại" in i.message
                            for i in issues))

    def test_numbered_contradiction_is_error(self) -> None:
        level = make_level()
        level.challenges = [(chal.ONLY_NUMBERED, 0), (chal.AVOID_NUMBERED, 0)]
        issues = validator.validate(level)
        self.assertTrue(any(i.is_error and "mâu thuẫn" in i.message for i in issues))

    def test_steps_below_shortest_path_is_error(self) -> None:
        level = make_level()          # 3x3 trống: đường ngắn nhất 4 bước
        level.challenges = [(chal.STEPS_MAX, 2)]
        issues = validator.validate(level)
        self.assertTrue(any(i.is_error and "ngắn nhất" in i.message for i in issues))

    def test_len_max_percent_below_minimum_is_error(self) -> None:
        level = make_level()          # 9 ô, đường ngắn nhất 5 ô -> cần ~56%
        level.challenges = [(chal.LEN_MAX_PERCENT, 20)]
        issues = validator.validate(level)
        self.assertTrue(any(i.is_error and "đường ngắn nhất" in i.message for i in issues))

    def test_visit_all_with_blocked_cells_is_error(self) -> None:
        level = make_level()
        # Bịt kín ô (2, 2): 2 tường dọc + 2 tường ngang quanh nó
        level.set_wall(("v", 2, 2), True)
        level.set_wall(("v", 3, 2), True)
        level.set_wall(("h", 2, 2), True)
        level.set_wall(("h", 2, 3), True)
        level.challenges = [(chal.VISIT_ALL, 0)]
        issues = validator.validate(level)
        self.assertTrue(any(i.is_error and "không tới được" in i.message for i in issues))

    def test_sum_gt_impossible_is_error(self) -> None:
        level = make_level()
        level.challenges = [(chal.SUM_GT, 9999)]
        issues = validator.validate(level)
        self.assertTrue(any(i.is_error and "không thể đạt" in i.message for i in issues))

    def test_param_out_of_range_is_error(self) -> None:
        level = make_level()
        level.challenges = [(chal.LEN_MIN_PERCENT, 500)]
        issues = validator.validate(level)
        self.assertTrue(any(i.is_error and "ngoài khoảng" in i.message for i in issues))

    def test_full_valid_set_has_no_errors(self) -> None:
        level = make_level(5, 5)
        level.set_challenge(0, chal.NO_WALL)
        level.set_challenge(1, chal.STEPS_MAX, 12)
        level.set_challenge(2, chal.LEN_MAX_PERCENT, 90)
        issues = validator.validate(level)
        self.assertFalse([i for i in issues if i.is_error], "không được có lỗi: %s"
                         % [i.message for i in issues])


class ChallengeControllerTest(unittest.TestCase):
    def test_set_and_undo(self) -> None:
        editor = EditorController(make_level())
        editor.set_challenge(0, chal.NO_REVISIT)
        self.assertEqual(editor.level.challenges, [(chal.NO_REVISIT, 0)])
        self.assertTrue(editor.can_undo())
        editor.undo()
        self.assertEqual(editor.level.challenges, [])

    def test_set_param(self) -> None:
        editor = EditorController(make_level())
        editor.set_challenge(0, chal.STEPS_MAX, 10)
        editor.set_challenge_param(0, 16)
        self.assertEqual(editor.level.challenges[0], (chal.STEPS_MAX, 16))
        # Loại không cần tham số thì đổi param bị bỏ qua
        editor.set_challenge(1, chal.NO_HINT)
        editor.set_challenge_param(1, 5)
        self.assertEqual(editor.level.challenges[1], (chal.NO_HINT, 0))

    def test_fill_default_and_reset(self) -> None:
        editor = EditorController(make_level())
        editor.level.max_steps = 18
        editor.level.par_time = 50.0
        editor.fill_default_challenges()
        self.assertEqual(editor.level.challenges[:2], [(chal.NO_WALL, 0), (chal.STEPS_MAX, 18)])
        self.assertEqual(editor.level.challenges[2], (chal.TIME_MAX, 50))
        editor.reset_challenges()
        self.assertEqual(editor.level.challenges, [])


class ChallengeRegistryTest(unittest.TestCase):
    def test_registry_matches_game_ids(self) -> None:
        # 16 loại, id không trùng, id trong ORDER đều hợp lệ
        self.assertEqual(len(chal.ORDER), len(set(chal.ORDER)))
        self.assertEqual(len(chal.ORDER), 16)
        for type_id in chal.ORDER:
            self.assertTrue(chal.is_valid(type_id), type_id)
            self.assertTrue(chal.label(type_id))
        self.assertEqual(set(chal.DEFAULT_TYPES), {chal.NO_WALL, chal.STEPS_MAX, chal.TIME_MAX})

    def test_combo_roundtrip(self) -> None:
        for type_id in chal.ORDER:
            self.assertEqual(chal.from_combo(chal.to_combo(type_id)), type_id)


if __name__ == "__main__":
    unittest.main()
