"""Test: LUẬT THỬ THÁCH (challenge) — registry, model, .tres, validator, undo.

Game đọc dữ liệu này ở `scripts/resources/level_data.gd` + `scripts/modes/challenge_game_mode.gd`:
    mode_id = "challenge"
    challenge = "walk_number_only"        (rỗng = không gắn luật)
    challenge_param = 0                   (0 = game tự tính theo luật/bàn cờ/độ khó)
"""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from app.controllers.editor_controller import EditorController  # noqa: E402
from app.models import challenge_rules as chrules  # noqa: E402
from app.models.repository import LevelRepository  # noqa: E402
from app.services import solver, tres_io, validator  # noqa: E402


def make_level(width: int = 3, height: int = 3):
    return LevelRepository().create_level(98, width, height)


def make_walk_number_level():
    """Màn 4x4 có ĐƯỜNG S→F chỉ qua ô CÓ số (giống thiết kế của màn mẫu level_21)."""
    level = make_level(4, 4)
    level.start = (0, 3)
    level.end = (3, 0)
    for ref in (("h", 1, 3), ("v", 3, 3), ("v", 2, 2), ("v", 2, 1), ("v", 2, 0)):
        level.set_wall(ref, True, True)
    level.max_steps = solver.auto_max_steps(level, extra=2)
    return level


class ChallengeRegistryTest(unittest.TestCase):
    def test_registry_matches_game_ids(self) -> None:
        # 8 luật, id không trùng, mọi id trong ORDER đều hợp lệ + có nhãn
        self.assertEqual(len(chrules.ORDER), 8)
        self.assertEqual(len(chrules.ORDER), len(set(chrules.ORDER)))
        for rule_id in chrules.ORDER:
            self.assertTrue(chrules.is_valid(rule_id), rule_id)
            self.assertTrue(chrules.label(rule_id), rule_id)

    def test_only_four_rules_take_param(self) -> None:
        paramed = sorted(r for r in chrules.ORDER if chrules.has_param(r))
        self.assertEqual(paramed, [chrules.BACKTRACK_LIMIT, chrules.COUNTDOWN,
                                   chrules.MOVE_LIMIT, chrules.STEP_TIMER])
        self.assertFalse(chrules.is_valid("khong_ton_tai"))

    def test_suggested_param_matches_game_defaults(self) -> None:
        # Countdown: 60 + 4 giây mỗi ô, tối thiểu 75 (giống _default_param bên GDScript)
        self.assertEqual(chrules.suggested_param(chrules.COUNTDOWN, 3, 3), 96)
        self.assertEqual(chrules.suggested_param(chrules.COUNTDOWN, 1, 1), 75)
        # Move Limit: đúng bằng max_steps của màn; Backtrack: 3; Step Timer: theo độ khó
        self.assertEqual(chrules.suggested_param(chrules.MOVE_LIMIT, max_steps=13), 13)
        self.assertEqual(chrules.suggested_param(chrules.BACKTRACK_LIMIT), 3)
        self.assertEqual(chrules.suggested_param(chrules.STEP_TIMER, difficulty="easy"), 30)
        self.assertEqual(chrules.suggested_param(chrules.STEP_TIMER, difficulty="medium"), 20)
        self.assertEqual(chrules.suggested_param(chrules.STEP_TIMER, difficulty="hard"), 15)
        self.assertEqual(chrules.suggested_param(chrules.NO_TOOL), 0)

    def test_combo_helpers(self) -> None:
        self.assertEqual(chrules.from_combo(chrules.NONE_LABEL), "")
        self.assertEqual(chrules.from_combo(""), "")
        self.assertEqual(chrules.from_combo(chrules.to_combo(chrules.NO_TOOL)), chrules.NO_TOOL)
        self.assertEqual(chrules.to_combo("khong_ton_tai"), chrules.NONE_LABEL)


class ChallengeModelTest(unittest.TestCase):
    def test_new_level_has_no_challenge(self) -> None:
        level = make_level()
        self.assertEqual(level.challenge, "")
        self.assertEqual(level.challenge_param, 0)
        self.assertFalse(level.has_challenge())

    def test_set_and_clear(self) -> None:
        level = make_level()
        self.assertTrue(level.set_challenge(chrules.MOVE_LIMIT, 12))
        self.assertEqual((level.challenge, level.challenge_param), (chrules.MOVE_LIMIT, 12))
        self.assertTrue(level.has_challenge())
        # Đặt lại y hệt -> không phải thay đổi
        self.assertFalse(level.set_challenge(chrules.MOVE_LIMIT, 12))

        self.assertTrue(level.clear_challenge())
        self.assertEqual((level.challenge, level.challenge_param), ("", 0))
        self.assertFalse(level.clear_challenge())

    def test_set_empty_rule_clears(self) -> None:
        level = make_level()
        level.set_challenge(chrules.NO_TOOL)
        self.assertTrue(level.set_challenge(""))
        self.assertEqual(level.challenge, "")

    def test_invalid_rule_is_rejected(self) -> None:
        level = make_level()
        self.assertFalse(level.set_challenge("khong_ton_tai"))
        self.assertEqual(level.challenge, "")

    def test_param_rules(self) -> None:
        level = make_level()
        # Tham số âm -> 0 (game tự tính)
        self.assertTrue(level.set_challenge(chrules.COUNTDOWN, -5))
        self.assertEqual(level.challenge_param, 0)
        self.assertTrue(level.set_challenge(chrules.MOVE_LIMIT, 9))
        self.assertEqual(level.challenge_param, 9)
        # Luật KHÔNG cần tham số -> luôn về 0
        self.assertTrue(level.set_challenge(chrules.WALK_NUMBER_ONLY, 7))
        self.assertEqual(level.challenge_param, 0)

    def test_suggested_param_uses_level_data(self) -> None:
        level = make_level(4, 4)
        level.max_steps = 20
        level.difficulty = "easy"
        level.set_challenge(chrules.MOVE_LIMIT)
        self.assertEqual(level.suggested_challenge_param(), 20)
        level.set_challenge(chrules.STEP_TIMER)
        self.assertEqual(level.suggested_challenge_param(), 30)
        level.set_challenge(chrules.COUNTDOWN)
        self.assertEqual(level.suggested_challenge_param(), 60 + 16 * 4)

    def test_snapshot_keeps_challenge(self) -> None:
        level = make_level()
        level.set_challenge(chrules.BACKTRACK_LIMIT, 2)
        snap = level.snapshot()
        level.clear_challenge()
        level.restore(snap)
        self.assertEqual((level.challenge, level.challenge_param), (chrules.BACKTRACK_LIMIT, 2))


class ChallengeTresIoTest(unittest.TestCase):
    def test_emitted_syntax(self) -> None:
        level = make_level()
        level.mode_id = "challenge"
        level.set_challenge(chrules.MOVE_LIMIT, 12)
        text = tres_io.dumps(level)
        self.assertIn('mode_id = "challenge"', text)
        self.assertIn('challenge = "move_limit"', text)
        self.assertIn("challenge_param = 12", text)

    def test_default_lines_like_godot(self) -> None:
        level = make_level()
        text = tres_io.dumps(level)
        self.assertIn('challenge = ""', text)
        self.assertIn("challenge_param = 0", text)

    def test_roundtrip(self) -> None:
        level = make_level(4, 4)
        level.mode_id = "challenge"
        level.set_challenge(chrules.WALK_EMPTY_ONLY)
        again = tres_io.loads(tres_io.dumps(level))
        self.assertEqual(again.challenge, chrules.WALK_EMPTY_ONLY)
        self.assertEqual(again.challenge_param, 0)
        self.assertEqual(again.snapshot(), level.snapshot())

    def test_legacy_file_without_challenge_keys(self) -> None:
        # File .tres cũ (chưa có 2 dòng challenge) phải đọc được -> rỗng (game dùng mặc định)
        level = make_level()
        text = "\n".join(
            line for line in tres_io.dumps(level).splitlines()
            if not line.startswith("challenge")
        ) + "\n"
        again = tres_io.loads(text)
        self.assertEqual(again.challenge, "")
        self.assertEqual(again.challenge_param, 0)

    def test_unknown_rule_in_file_is_kept_for_validation(self) -> None:
        level = make_level()
        text = tres_io.dumps(level).replace('challenge = ""', 'challenge = "luat_la"')
        again = tres_io.loads(text)
        self.assertEqual(again.challenge, "luat_la")
        issues = validator.validate(again)
        self.assertTrue(any(i.is_error and "không tồn tại" in i.message for i in issues))


class ChallengeValidatorTest(unittest.TestCase):
    def messages(self, level) -> list[str]:
        return [issue.message for issue in validator.validate(level)]

    def test_rule_outside_challenge_mode_is_warning(self) -> None:
        level = make_level()
        level.set_challenge(chrules.NO_TOOL)          # mode_id vẫn là "play"
        issues = validator.validate(level)
        self.assertTrue(any(i.severity == validator.LEVEL_WARNING and "BỎ QUA" in i.message
                            for i in issues))

    def test_challenge_mode_without_rule_is_warning(self) -> None:
        level = make_level()
        level.mode_id = "challenge"
        issues = validator.validate(level)
        self.assertTrue(any(i.severity == validator.LEVEL_WARNING and "CHƯA chọn luật" in i.message
                            for i in issues))

    def test_mode_play_without_rule_has_no_challenge_issues(self) -> None:
        self.assertFalse([m for m in self.messages(make_level()) if "Thử thách" in m])

    def test_move_limit_below_shortest_path_is_error(self) -> None:
        level = make_level()                          # 3x3 trống: đường ngắn nhất 4 bước
        level.mode_id = "challenge"
        level.set_challenge(chrules.MOVE_LIMIT, 2)
        issues = validator.validate(level)
        self.assertTrue(any(i.is_error and "không thể thắng" in i.message for i in issues))

    def test_move_limit_equal_to_path_is_warning(self) -> None:
        level = make_level()
        level.mode_id = "challenge"
        level.set_challenge(chrules.MOVE_LIMIT, 4)
        issues = validator.validate(level)
        self.assertTrue(any(i.severity == validator.LEVEL_WARNING and "ĐÚNG BẰNG" in i.message
                            for i in issues))

    def test_move_limit_zero_uses_max_steps(self) -> None:
        level = make_level()
        level.mode_id = "challenge"
        level.set_challenge(chrules.MOVE_LIMIT, 0)
        issues = validator.validate(level)
        self.assertFalse([i for i in issues if i.is_error], [i.message for i in issues])
        self.assertTrue(any("tự tính" in i.message for i in issues))

    def test_param_out_of_range_is_error(self) -> None:
        level = make_level()
        level.mode_id = "challenge"
        level.set_challenge(chrules.COUNTDOWN, 2)     # dưới mức tối thiểu 5 giây
        issues = validator.validate(level)
        self.assertTrue(any(i.is_error and "ngoài khoảng" in i.message for i in issues))

    def test_countdown_too_fast_warning(self) -> None:
        level = make_level(5, 5)                      # đường ngắn nhất 8 bước
        level.mode_id = "challenge"
        level.set_challenge(chrules.COUNTDOWN, 5)
        issues = validator.validate(level)
        self.assertTrue(any(i.severity == validator.LEVEL_WARNING and "không thể" in i.message
                            for i in issues))

    def test_walk_number_only_on_open_maze_is_error(self) -> None:
        # Màn trống hoàn toàn: không ô nào có số -> không thể có đường "chỉ ô có số"
        level = make_level()
        level.mode_id = "challenge"
        level.set_challenge(chrules.WALK_NUMBER_ONLY)
        issues = validator.validate(level)
        self.assertTrue(any(i.is_error and "KHÔNG có đường" in i.message for i in issues))

    def test_walk_empty_only_on_open_maze_is_ok(self) -> None:
        level = make_level()
        level.mode_id = "challenge"
        level.set_challenge(chrules.WALK_EMPTY_ONLY)
        issues = validator.validate(level)
        self.assertFalse([i for i in issues if i.is_error], [i.message for i in issues])
        self.assertTrue(any("có đường hợp lệ" in i.message for i in issues))

    def test_walk_number_only_with_designed_walls_is_ok(self) -> None:
        level = make_walk_number_level()
        level.mode_id = "challenge"
        level.set_challenge(chrules.WALK_NUMBER_ONLY)
        issues = validator.validate(level)
        self.assertFalse([i for i in issues if i.is_error], [i.message for i in issues])
        self.assertTrue(any("có đường hợp lệ" in i.message for i in issues))

    def test_no_tool_and_overlap_need_no_path_check(self) -> None:
        for rule_id in (chrules.NO_TOOL, chrules.NO_MOVE_OVERLAPPED, chrules.BACKTRACK_LIMIT):
            with self.subTest(rule=rule_id):
                level = make_level()
                level.mode_id = "challenge"
                level.set_challenge(rule_id)
                issues = validator.validate(level)
                self.assertFalse([i for i in issues if i.is_error], [i.message for i in issues])

    def test_full_valid_challenge_has_no_errors(self) -> None:
        level = make_walk_number_level()
        level.mode_id = "challenge"
        level.set_challenge(chrules.WALK_NUMBER_ONLY)
        issues = validator.validate(level)
        self.assertFalse([i for i in issues if i.is_error],
                         [i.message for i in issues])


class ChallengeControllerTest(unittest.TestCase):
    def test_set_rule_and_undo(self) -> None:
        editor = EditorController(make_level())
        editor.set_challenge_rule(chrules.NO_TOOL)
        self.assertEqual(editor.level.challenge, chrules.NO_TOOL)
        self.assertTrue(editor.can_undo())
        editor.undo()
        self.assertEqual(editor.level.challenge, "")

    def test_switch_rule_resets_param(self) -> None:
        editor = EditorController(make_level())
        editor.set_challenge_rule(chrules.MOVE_LIMIT)
        editor.set_challenge_param(9)
        self.assertEqual(editor.level.challenge_param, 9)
        # Đổi sang luật khác (đơn vị tham số khác) -> tham số về 0 = game tự tính
        editor.set_challenge_rule(chrules.COUNTDOWN)
        self.assertEqual(editor.level.challenge_param, 0)

    def test_set_param_and_undo(self) -> None:
        editor = EditorController(make_level())
        editor.set_challenge_rule(chrules.BACKTRACK_LIMIT)
        editor.set_challenge_param(5)
        self.assertEqual(editor.level.challenge_param, 5)
        editor.undo()
        self.assertEqual(editor.level.challenge_param, 0)

    def test_param_ignored_for_no_param_rule(self) -> None:
        editor = EditorController(make_level())
        editor.set_challenge_rule(chrules.WALK_NUMBER_ONLY)
        editor.set_challenge_param(7)
        self.assertEqual(editor.level.challenge_param, 0)

    def test_clear_challenge(self) -> None:
        editor = EditorController(make_level())
        editor.set_challenge_rule(chrules.STEP_TIMER)
        editor.clear_challenge()
        self.assertEqual(editor.level.challenge, "")
        # Bỏ lần nữa -> không có gì đổi, không ghi thêm undo
        editor.clear_challenge()
        self.assertEqual(editor.level.challenge, "")

    def test_invalid_rule_is_rejected(self) -> None:
        editor = EditorController(make_level())
        editor.set_challenge_rule("khong_ton_tai")
        self.assertEqual(editor.level.challenge, "")
        self.assertFalse(editor.can_undo())

    def test_empty_rule_clears(self) -> None:
        editor = EditorController(make_level())
        editor.set_challenge_rule(chrules.NO_TOOL)
        editor.set_challenge_rule("")
        self.assertEqual(editor.level.challenge, "")


if __name__ == "__main__":
    unittest.main()
