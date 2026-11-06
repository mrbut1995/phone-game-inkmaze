extends TestCase
## Tests for DebugData (scripts/utils/DebugData.gd) — Debug Console chỉ ĐỌC dữ liệu.


func test_star_helpers_are_in_range() -> void:
	assert_true(DebugData.play_stars_max() > 0)
	assert_true(DebugData.stars_max() >= DebugData.play_stars_max(), "tổng Sao ngày phải >= Sao phần chơi")
	assert_true(DebugData.play_stars_today() >= 0)
	assert_true(DebugData.stars_today() >= 0)


func test_text_helpers_never_return_empty() -> void:
	assert_true(not DebugData.next_milestone_text().is_empty())
	assert_true(not DebugData.claimed_milestones_text().is_empty())
	assert_true(not DebugData.yesterday_state_text().is_empty())
	assert_true(not DebugData.ads_state_text().is_empty())


func test_tutorial_helpers_read_progress() -> void:
	assert_true(DebugData.tutorial_ids().size() > 0, "phải có danh sách bài học")
	assert_false(DebugData.tutorial_flag("khong_ton_tai"))
	assert_true(DebugData.tutorial_done_count() >= 0)
