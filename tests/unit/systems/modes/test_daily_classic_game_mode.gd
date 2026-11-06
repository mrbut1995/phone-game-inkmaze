extends TestCase
## Tests for DailyClassicGameMode (scripts/systems/modes/DailyClassicGameMode.gd)


func test_mode_identity() -> void:
	var mode := DailyClassicGameMode.new()
	assert_eq(mode.mode_id, "daily_classic")
	assert_false(mode.is_endless, "ván Daily chỉ 1 màn")
	assert_true(mode.instant_game_over_on_hazard, "đâm tường ẩn là thua ngay")


func test_setup_floor_generates_a_playable_maze() -> void:
	var mode := DailyClassicGameMode.new()
	var maze := mode.setup_floor(1)
	assert_not_null(maze)
	assert_true(maze.width > 0 and maze.height > 0)
	assert_ne(maze.get_start(), maze.get_end(), "ô xuất phát và ô đích phải khác nhau")
	assert_eq(mode.initial_steps, DailyClassicGameMode.DESIGN_STEPS)
	assert_null(mode.current_level_data, "bàn tự sinh không dùng LevelData")


func test_hud_texts_are_not_empty() -> void:
	var mode := DailyClassicGameMode.new()
	assert_true(not mode.get_hud_floor_title(1).is_empty())
	assert_true(not mode.get_hud_subtitle(1).is_empty())
