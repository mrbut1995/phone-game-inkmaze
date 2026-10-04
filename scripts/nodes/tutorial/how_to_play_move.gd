class_name HowToPlayMoveTutorial
extends BaseInteractivePathTutorial

## ============================================================================
## HowToPlayMoveTutorial: Dạy kéo đường đi từ S đến F (Planning.md §3.2)
## Dùng BoardTutorial kế thừa BoardView thật: khung card_board.svg, 3 ô S - giữa - F.
## Kế thừa BaseInteractivePathTutorial (SOLID - OCP/SRP).
## ============================================================================

const START_POS := Vector2i(0, 0)
const FINISH_POS := Vector2i(2, 0)


func _init_tutorial() -> void:
	tutorial_id = "how_to_play_move"
	_start_cell = START_POS
	_goal_cell = FINISH_POS
	if board_tutorial != null:
		board_tutorial.setup_tutorial(
			3, 1,
			{
				START_POS: "S",
				Vector2i(1, 0): "",
				FINISH_POS: "F"
			},
			[],
			true,
			START_POS,
			FINISH_POS
		)
	reset_path()


func _get_default_steps() -> Array:
	return [
		{
			"message_key": "STR_TUT_MOVE_01",
			"fallback_text": "Chào! Hãy kéo ngón tay qua từng ô để tạo đường đi.",
			"advance_mode": "MANUAL",
			"pointer_drag": {"from_cell": Vector2i(0, 0), "to_cell": FINISH_POS, "duration": 1.0}
		},
		{
			"message_key": "STR_TUT_MOVE_02",
			"fallback_text": "Tốt lắm! Giờ bạn hãy tự kéo từ ô S sang ô giữa.",
			"advance_mode": "AUTO",
			"required_action": "DRAG_PATH",
			"pointer_drag": {"from_cell": Vector2i(0, 0), "to_cell": Vector2i(1, 0), "duration": 0.7}
		},
		{
			"message_key": "STR_TUT_MOVE_02B",
			"fallback_text": "Tuyệt! Tiếp tục kéo sang ô cuối — ô F.",
			"advance_mode": "AUTO",
			"required_action": "DRAG_PATH",
			"pointer_drag": {"from_cell": Vector2i(1, 0), "to_cell": FINISH_POS, "duration": 0.7}
		},
		{
			"message_key": "STR_TUT_MOVE_03",
			"fallback_text": "Tuyệt vời! Bạn đã tạo được đường đi.",
			"advance_mode": "MANUAL",
		}
	]


func _on_step_entered(index: int, _data: Dictionary) -> void:
	match index:
		0, 1:
			reset_path()
		3:
			stop_cursor_animation()
			play_cells_win()
			if board_tutorial != null:
				spawn_board_text("✓", board_tutorial.get_cell_center(FINISH_POS))
			show_success_feedback("STR_TUT_MOVE_03", "Tuyệt vời!")


func _is_input_allowed_at_step(step_idx: int) -> bool:
	return step_idx == 1 or step_idx == 2


func _can_step_to(_from_cell: Vector2i, to_cell: Vector2i) -> bool:
	# Chỉ cho phép tiến từng ô sang phải
	if to_cell == _current_cell + Vector2i(1, 0):
		return true

	if board_tutorial != null:
		var c := board_tutorial.get_cell(to_cell)
		if c != null:
			c.play_fail()
	show_fail_feedback("STR_TUT_MOVE_FAIL_01", "Chỉ đi được sang ô NGAY BÊN CẠNH!")
	return false


func _on_step_succeeded(next: Vector2i, _is_first_time: bool) -> void:
	if next == Vector2i(1, 0) and current_step_index == 1:
		show_success_feedback()
		show_step(2)
	elif next == FINISH_POS and current_step_index == 2:
		show_step(3)
