extends TestCase
## Tests for ChallengeRules (scripts/systems/ChallengeRules.gd)
## Chỉ soi phần LUẬT (không dựng bàn cờ): truyền thẳng mode + path + số bước.


func test_reset_and_begin_step_track_clock() -> void:
	var rules := ChallengeRules.new()
	rules.begin_step(12.5)
	assert_almost_eq(rules.step_start, 12.5)
	rules.reset()
	assert_almost_eq(rules.step_start, 0.0)
	assert_eq(rules.backtracks, 0)


func test_ticks_ignore_null_mode() -> void:
	var rules := ChallengeRules.new()
	assert_eq(rules.tick(null, 999.0), "")
	assert_eq(rules.after_step(null, [], 0), "")


func test_countdown_rule_fires_at_limit() -> void:
	var rules := ChallengeRules.new()
	var ch := ChallengeGameMode.new()
	ch.challenge_id = ChallengeGameMode.COUNTDOWN
	ch.challenge_param = 30
	assert_eq(rules.tick(ch, 29.0), "", "chưa tới hạn thì chưa thua")
	assert_eq(rules.tick(ch, 30.0), ChallengeGameMode.COUNTDOWN)


func test_step_timer_counts_from_begin_step() -> void:
	var rules := ChallengeRules.new()
	var ch := ChallengeGameMode.new()
	ch.challenge_id = ChallengeGameMode.STEP_TIMER
	ch.challenge_param = 5
	rules.begin_step(10.0)
	assert_eq(rules.tick(ch, 14.0), "")
	assert_eq(rules.tick(ch, 15.0), ChallengeGameMode.STEP_TIMER)


func test_move_limit_fires_only_after_limit() -> void:
	var rules := ChallengeRules.new()
	var ch := ChallengeGameMode.new()
	ch.challenge_id = ChallengeGameMode.MOVE_LIMIT
	ch.challenge_param = 3
	var path: Array[Vector2i] = [Vector2i(0, 0)]
	assert_eq(rules.after_step(ch, path, 3), "", "đúng hạn mức thì chưa thua")
	assert_eq(rules.after_step(ch, path, 4), ChallengeGameMode.MOVE_LIMIT)


func test_no_move_overlapped_detects_revisit() -> void:
	var rules := ChallengeRules.new()
	var ch := ChallengeGameMode.new()
	ch.challenge_id = ChallengeGameMode.NO_MOVE_OVERLAPPED
	var straight: Array[Vector2i] = [Vector2i(0, 0), Vector2i(0, 1)]
	assert_eq(rules.after_step(ch, straight, 1), "")
	var revisited: Array[Vector2i] = [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 0)]
	assert_eq(rules.after_step(ch, revisited, 2), ChallengeGameMode.NO_MOVE_OVERLAPPED)


func test_backtrack_limit_counts_three_cell_bounce() -> void:
	var rules := ChallengeRules.new()
	var ch := ChallengeGameMode.new()
	ch.challenge_id = ChallengeGameMode.BACKTRACK_LIMIT
	ch.challenge_param = 2
	var bounce: Array[Vector2i] = [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 0)]
	assert_eq(rules.after_step(ch, bounce, 2), "", "lượt quay đầu thứ 1 và 2 còn được phép")
	assert_eq(rules.after_step(ch, bounce, 2), "")
	assert_eq(rules.after_step(ch, bounce, 2), ChallengeGameMode.BACKTRACK_LIMIT)
	assert_eq(rules.backtracks, 3)
