class_name HowToPlayCheckingWallTutorial
extends BaseTutorial

## ============================================================================
## HowToPlayCheckingWallTutorial: Đọc số & suy luận tường vô hình (Planning.md §3.3)
## Dùng BoardTutorial kế thừa BoardView thật: bàn 2×2, tường ẩn giữa (0,0) và (1,0).
## ============================================================================

@export var board_tutorial: BoardTutorial = null

var _current_cell: Vector2i = Vector2i(0, 0)
var _visited_cells: Array[Vector2i] = []

const WALL_LATTICE := Vector2i(1, 0)


func _init_tutorial() -> void:
	tutorial_id = "how_to_play_checking_wall"
	if board_tutorial != null:
		board_tutorial.setup_tutorial(
			2, 2,
			{
				Vector2i(0, 0): "S",
				Vector2i(1, 0): "1",
				Vector2i(0, 1): "1",
				Vector2i(1, 1): "F"
			},
			[{"is_h": false, "lattice": WALL_LATTICE, "visible": false}],
			true,
			Vector2i(0, 0),
			Vector2i(1, 1)
		)
		if not board_tutorial.cell_step_attempted.is_connected(_on_cell_step_attempted):
			board_tutorial.cell_step_attempted.connect(_on_cell_step_attempted)
	_reset_path()

	var steps: Array = [
		{
			"message_key": "STR_TUT_WALL_01",
			"fallback_text": "Con số trên mỗi ô cho biết có BAO NHIÊU cạnh quanh ô đó là tường vô hình.",
			"advance_mode": "MANUAL",
			"spotlight_cell": Vector2i(0, 0)
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
		if board_tutorial != null:
			board_tutorial.reveal_wall_segment(false, WALL_LATTICE, false)
	elif index == 1:
		if board_tutorial != null:
			board_tutorial.reveal_wall_segment(false, WALL_LATTICE, true)
	elif index == 2:
		_reset_path()
		if board_tutorial != null:
			board_tutorial.reveal_wall_segment(false, WALL_LATTICE, false)


func _on_cell_step_attempted(next: Vector2i) -> void:
	if current_step_index != 2:
		return
	_try_step_to(next)


func _try_step_to(next: Vector2i) -> void:
	var diff: Vector2i = next - _current_cell
	if absi(diff.x) + absi(diff.y) != 1:
		show_fail_feedback("STR_TUT_MOVE_FAIL_01", "Chỉ đi được sang ô NGAY BÊN CẠNH!")
		return

	# Kiểm tra đâm vào tường giữa (0,0) và (1,0)
	if (_current_cell == Vector2i(0, 0) and next == Vector2i(1, 0)) or \
		(_current_cell == Vector2i(1, 0) and next == Vector2i(0, 0)):
		if board_tutorial != null:
			board_tutorial.show_wall_hit_at(_current_cell, next)
		show_fail_feedback("STR_TUT_WALL_FAIL_01", "Ối, đó là tường rồi! Thử hướng khác xem.")
		return

	_current_cell = next
	_visited_cells.append(next)
	if board_tutorial != null:
		board_tutorial.set_path(_visited_cells)
		board_tutorial.set_player_cell(next, true)
		var c := board_tutorial.get_cell(next)
		if c != null:
			c.play_step()

	if next == Vector2i(1, 1):
		play_cells_win()
		if board_tutorial != null:
			spawn_board_text("✓", board_tutorial.get_cell_center(next))
		show_success_feedback("STR_TUT_WALL_04", "Chính xác!")
		show_step(3)
