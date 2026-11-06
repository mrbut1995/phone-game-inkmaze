extends TestCase
## Tests for DailyChallengeGameMode (scripts/systems/modes/DailyChallengeGameMode.gd)


func test_mode_identity() -> void:
	var mode := DailyChallengeGameMode.new()
	assert_eq(mode.mode_id, "daily_challenge")
	assert_eq(mode.mode_name, "Daily Challenge")


func test_setup_floor_generates_a_maze_with_distinct_endpoints() -> void:
	var mode := DailyChallengeGameMode.new()
	var maze := mode.setup_floor(1)
	assert_not_null(maze)
	assert_true(maze.width > 0 and maze.height > 0)
	assert_ne(maze.get_start(), maze.get_end(), "ô xuất phát và ô đích phải khác nhau")
	assert_eq(mode.initial_steps, DailyChallengeGameMode.DESIGN_STEPS)


func test_move_limit_is_relaxed_to_the_design_solution() -> void:
	var mode := DailyChallengeGameMode.new()
	var maze := mode.setup_floor(1)
	if mode.challenge_id != ChallengeGameMode.MOVE_LIMIT:
		return  # luật của ngày hôm nay không phải MOVE_LIMIT — không có gì để kiểm
	var shortest := maze.get_shortest_path(maze.get_start(), maze.get_end()).size()
	assert_true(mode.challenge_param >= shortest, "hạn mức phải đủ cho đường ngắn nhất")
