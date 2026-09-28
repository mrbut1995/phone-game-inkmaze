class_name HowToPlayMoveTutorial
extends BaseTutorial

## ============================================================================
## HowToPlayMoveTutorial: Dạy kéo đường đi từ S đến F (Planning.md §3.2)
## Dùng BoardTutorial kế thừa BoardView thật: khung card_board.svg, 3 ô S - giữa - F.
## ============================================================================

@export var board_tutorial: BoardTutorial = null

var _current_cell: Vector2i = Vector2i(0, 0)
var _visited_cells: Array[Vector2i] = []


func _init_tutorial() -> void:
	tutorial_id = "how_to_play_move"
	if board_tutorial != null:
		board_tutorial.setup_tutorial(
			3, 1,
			{
				Vector2i(0, 0): "S",
				Vector2i(1, 0): "",
				Vector2i(2, 0): "F"
			},
			[],
			true,
			Vector2i(0, 0),
			Vector2i(2, 0)
		)
		if not board_tutorial.cell_step_attempted.is_connected(_on_cell_step_attempted):
			board_tutorial.cell_step_attempted.connect(_on_cell_step_attempted)
	_reset_path()

	var steps: Array = [
		{
			"message_key": "STR_TUT_MOVE_01",
			"fallback_text": "Đây là điểm BẮT ĐẦU (S). Hãy giữ và kéo sang ô bên cạnh.",
			"advance_mode": "MANUAL",
			"spotlight_cell": Vector2i(0, 0),
			"pointer_drag": {
				"from_cell": Vector2i(0, 0),
				"to_cell": Vector2i(1, 0),
				"duration": 0.6
			}
		},
		{
			"message_key": "STR_TUT_MOVE_01",
			"fallback_text": "Hãy chạm và kéo từ S sang ô ngay bên cạnh.",
			"advance_mode": "AUTO",
			"required_action": "DRAG_TO_MIDDLE",
			"pointer_drag": {
				"from_cell": Vector2i(0, 0),
				"to_cell": Vector2i(1, 0),
				"duration": 0.6
			}
		},
		{
			"message_key": "STR_TUT_MOVE_02",
			"fallback_text": "Giờ kéo tiếp tới F để hoàn thành đường đi.",
			"advance_mode": "AUTO",
			"required_action": "DRAG_TO_FINISH",
			"pointer_drag": {
				"from_cell": Vector2i(1, 0),
				"to_cell": Vector2i(2, 0),
				"duration": 0.6
			}
		},
		{
			"message_key": "STR_TUT_MOVE_03",
			"fallback_text": "Tuyệt vời! Bạn vừa vẽ xong đường đi đầu tiên.",
			"advance_mode": "MANUAL",
		}
	]
	setup_steps(steps)


func _reset_path() -> void:
	_visited_cells = [Vector2i(0, 0)]
	_current_cell = Vector2i(0, 0)
	if board_tutorial != null:
		board_tutorial.set_path(_visited_cells)
		board_tutorial.set_player_cell(Vector2i(0, 0), false)


func _on_step_entered(index: int, _data: Dictionary) -> void:
	if index == 0:
		_reset_path()
	elif index == 1:
		_reset_path()
	elif index == 3:
		stop_cursor_animation()
		play_cells_win()
		if board_tutorial != null:
			spawn_board_text("✓", board_tutorial.get_cell_center(Vector2i(2, 0)))
		show_success_feedback("STR_TUT_MOVE_03", "Tuyệt vời!")


func _on_cell_step_attempted(next: Vector2i) -> void:
	if current_step_index != 1 and current_step_index != 2:
		return
	_try_step_to(next)


func _try_step_to(next: Vector2i) -> void:
	if next == _current_cell + Vector2i(1, 0):
		_current_cell = next
		_visited_cells.append(next)
		if board_tutorial != null:
			board_tutorial.set_path(_visited_cells)
			board_tutorial.set_player_cell(next, true)
			var c := board_tutorial.get_cell(next)
			if c != null:
				c.play_step()

		if next == Vector2i(1, 0) and current_step_index == 1:
			show_success_feedback()
			show_step(2)
		elif next == Vector2i(2, 0) and current_step_index == 2:
			show_step(3)
	elif next.x > _current_cell.x + 1:
		if board_tutorial != null:
			var c := board_tutorial.get_cell(next)
			if c != null:
				c.play_fail()
		show_fail_feedback("STR_TUT_MOVE_FAIL_01", "Chỉ đi được sang ô NGAY BÊN CẠNH!")
