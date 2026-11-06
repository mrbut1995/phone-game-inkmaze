extends TestCase
## Tests for Life (scripts/utils/Life.gd)
## Chỉ test phần THUẦN (định dạng chuỗi) + đọc trạng thái thật qua autoload GameManager.


func test_clock_text_formats_minutes_and_seconds() -> void:
	assert_eq(Life.clock_text(754), "12:34")
	assert_eq(Life.clock_text(0), "00:00")
	assert_eq(Life.clock_text(-9), "00:00", "số âm coi như 0")
	assert_eq(Life.clock_text(59), "00:59")


func test_clock_text_keeps_hours_as_minutes() -> void:
	assert_eq(Life.clock_text(3600), "60:00")


func test_constants_match_design() -> void:
	assert_eq(Life.MAX, 5)
	assert_eq(Life.RECHARGE_SECONDS, 30 * 60)


func test_chip_text_matches_count_over_max() -> void:
	assert_eq(Life.chip_text(), "%d/%d" % [Life.count(), Life.max_count()])


func test_available_when_game_manager_is_loaded() -> void:
	assert_true(Life.available(), "autoload GameManager phải có lives_left()")
	assert_true(Life.count() >= 0)
	assert_true(Life.max_count() >= Life.count())
