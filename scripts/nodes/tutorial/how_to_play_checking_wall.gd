class_name HowToPlayCheckingWallTutorial
extends BaseInteractivePathTutorial

## ============================================================================
## HowToPlayCheckingWallTutorial: Đọc số & suy luận tường vô hình (Planning.md §3.3)
## Dùng BoardTutorial kế thừa BoardView thật: bàn 2×2, tường ẩn giữa (0,0) và (1,0).
## Kế thừa BaseInteractivePathTutorial (SOLID - OCP/SRP).
## ============================================================================

const START_POS := Vector2i(0, 0)
const FINISH_POS := Vector2i(1, 1)
const WALL_LATTICE := Vector2i(1, 0)


func _init_tutorial() -> void:
	tutorial_id = "how_to_play_checking_wall"
	_start_cell = START_POS
	_goal_cell = FINISH_POS
	if board_tutorial != null:
		board_tutorial.setup_tutorial(
			2, 2,
			{
				START_POS: "S",
				Vector2i(1, 0): "1",
				Vector2i(0, 1): "0",
				FINISH_POS: "F"
			},
			[{"is_h": false, "lattice": WALL_LATTICE, "visible": false}],
			true,
			START_POS,
			FINISH_POS
		)
	reset_path()


func _get_default_steps() -> Array:
	return [
		{
			"message_key": "STR_TUT_WALL_01",
			"fallback_text": "Con số trên mỗi ô cho biết có BAO NHIÊU cạnh quanh ô đó là tường vô hình.",
			"advance_mode": "MANUAL",
			"spotlight_cell": START_POS
		},
		{
			"message_key": "STR_TUT_WALL_02",
			"fallback_text": "Tường vô hình sẽ CHẶN đường đi — kéo ngang qua đó, đường sẽ không vẽ được.",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_WALL_03",
			"fallback_text": "Giờ bạn hãy tự đi từ S tới F — nhớ dùng con số để đoán tường nhé!",
			"advance_mode": "AUTO",
			"required_action": "DRAG_PATH"
		},
		{
			"message_key": "STR_TUT_WALL_04",
			"fallback_text": "Chính xác! Bạn đã dùng con số để đoán đúng tường.",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_WALL_05",
			"fallback_text": "Lưu ý: không phải chế độ nào cũng dùng số kiểu này. Cùng khám phá tiếp nhé!",
			"advance_mode": "MANUAL",
		}
	]


func _on_step_entered(index: int, _data: Dictionary) -> void:
	match index:
		0:
			reset_path()
			if board_tutorial != null:
				board_tutorial.reveal_wall_segment(false, WALL_LATTICE, false)
		1:
			if board_tutorial != null:
				board_tutorial.reveal_wall_segment(false, WALL_LATTICE, true)
		2:
			reset_path()
			if board_tutorial != null:
				board_tutorial.reveal_wall_segment(false, WALL_LATTICE, false)


func _is_input_allowed_at_step(step_idx: int) -> bool:
	return step_idx == 2


func _can_step_to(from_cell: Vector2i, to_cell: Vector2i) -> bool:
	# Kiểm tra đâm vào tường ẩn giữa (0,0) và (1,0)
	if (from_cell == Vector2i(0, 0) and to_cell == Vector2i(1, 0)) or \
	   (from_cell == Vector2i(1, 0) and to_cell == Vector2i(0, 0)):
		if board_tutorial != null:
			board_tutorial.show_wall_hit_at(from_cell, to_cell)
		show_fail_feedback("STR_TUT_WALL_FAIL_01", "Ối, đó là tường rồi! Thử hướng khác xem.")
		return false
	return true


func _on_goal_reached(next: Vector2i) -> void:
	play_cells_win()
	if board_tutorial != null:
		spawn_board_text("✓", board_tutorial.get_cell_center(next))
	show_success_feedback("STR_TUT_WALL_04", "Chính xác!")
	show_step(3)
