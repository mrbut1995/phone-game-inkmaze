extends TestCase
## Tests for TutorialStore (scripts/models/TutorialStore.gd)


func test_starts_with_nothing_completed() -> void:
	var store := TutorialStore.new()
	assert_false(store.is_completed("first_time"))
	assert_eq(store.flow_step, 0)
	assert_false(store.flow_done)


func test_set_completed_marks_core_when_three_first_lessons_done() -> void:
	var store := TutorialStore.new()
	store.set_completed("first_time")
	store.set_completed("how_to_play_move")
	assert_false(store.is_completed("core_completed"), "còn thiếu bài checking_wall")
	store.set_completed("how_to_play_checking_wall")
	assert_true(store.is_completed("core_completed"), "đủ 3 bài đầu thì core_completed tự bật")


func test_set_completed_can_reset_a_lesson() -> void:
	var store := TutorialStore.new()
	store.set_completed("how_to_play_writting_hint")
	assert_true(store.is_completed("how_to_play_writting_hint"))
	store.set_completed("how_to_play_writting_hint", false)
	assert_false(store.is_completed("how_to_play_writting_hint"))


func test_mark_core_completed_marks_all_core_lessons() -> void:
	var store := TutorialStore.new()
	store.mark_core_completed()
	assert_true(store.is_completed("core_completed"))
	assert_true(store.is_completed("first_time"))
	assert_true(store.is_completed("how_to_play_checking_wall"))


func test_set_flow_clamps_step() -> void:
	var store := TutorialStore.new()
	store.set_flow(999, true)
	assert_eq(store.flow_step, 64)
	assert_true(store.flow_done)
	store.set_flow(-3, false)
	assert_eq(store.flow_step, 0)
	assert_false(store.flow_done)


func test_request_and_take_request_is_one_shot() -> void:
	var store := TutorialStore.new()
	store.request("  how_to_play_move  ", true)
	assert_eq(store.pending_tutorial, "how_to_play_move", "id được cắt khoảng trắng")
	assert_true(store.pending_return_to_list)
	assert_eq(store.take_request(), "how_to_play_move")
	assert_eq(store.take_request(), "", "yêu cầu chỉ dùng 1 lần")
