class_name HowToPlayOneStrokeTutorial
extends BaseInteractivePathTutorial

## ============================================================================
## HowToPlayOneStrokeTutorial: Chế độ Một Nét (Planning.md §3.6)
## Bàn mini 3×3, không hiện số. Đi qua TẤT CẢ 9 ô, mỗi ô ĐÚNG 1 lần, kết thúc ở F (2,0).
## Kế thừa BaseInteractivePathTutorial (SOLID - OCP/SRP).
## ============================================================================

@export var START_POS := Vector2i(0, 0)
@export var FINISH_POS := Vector2i(2, 0)
@export var TOTAL_CELLS := 9

var _demo_tween: Tween = null


func _init_tutorial() -> void:
	tutorial_id = "how_to_play_one_stroke"
	_start_cell = START_POS
	_goal_cell = FINISH_POS
	if board_tutorial != null:
		var cells_map: Dictionary = {}
		for y in 3:
			for x in 3:
				cells_map[Vector2i(x, y)] = ""
		cells_map[START_POS] = "S"
		cells_map[FINISH_POS] = "F"
		board_tutorial.setup_tutorial(
			3, 3,
			cells_map,
			[],
			true,
			START_POS,
			FINISH_POS
		)
	reset_path()


func _get_default_steps() -> Array:
	return [
		{
			"message_key": "STR_TUT_ONE_01",
			"fallback_text": "Chế độ Một Nét: bạn phải đi qua TẤT CẢ các ô — mỗi ô đúng 1 lần!",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_ONE_02",
			"fallback_text": "Chỉ kết thúc ở ô F sau khi đã đi qua hết mọi ô.",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_ONE_03",
			"fallback_text": "Nếu đặt chân lên ô đã đi: đường bị phá, phải kéo lại từ đầu.",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_ONE_04",
			"fallback_text": "Giờ bạn hãy thử — đi qua toàn bộ 9 ô rồi về F!",
			"advance_mode": "AUTO",
			"required_action": "DRAG_PATH"
		},
		{
			"message_key": "STR_TUT_ONE_05",
			"fallback_text": "Tuyệt vời! Bạn vừa hoàn thành một nét.",
			"advance_mode": "MANUAL",
		}
	]


func reset_path(start_pos: Vector2i = _start_cell, update_board: bool = true) -> void:
	super.reset_path(start_pos, update_board)
	_update_cell_colors()


func _update_cell_colors() -> void:
	if board_tutorial == null:
		return
	for y in 3:
		for x in 3:
			var pos := Vector2i(x, y)
			var cell := board_tutorial.get_cell(pos)
			if cell != null:
				cell.set_visited_own(_visited_cells.has(pos))


func _on_step_entered(index: int, _data: Dictionary) -> void:
	_stop_demo()
	match index:
		1:
			_show_full_path_demo()
		2:
			_show_fail_demo()
		3:
			reset_path()


func _stop_demo() -> void:
	if _demo_tween != null and _demo_tween.is_valid():
		_demo_tween.kill()
		_demo_tween = null
	if board_tutorial != null:
		board_tutorial.stop_cursor_animation()


## Demo step 1: cursor đi qua toàn bộ 9 ô theo đường Hamiltonian S→F, lặp
func _show_full_path_demo() -> void:
	if board_tutorial == null:
		return
	var full_path: Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2),
		Vector2i(1, 2), Vector2i(2, 2), Vector2i(2, 1),
		Vector2i(1, 1), Vector2i(1, 0), Vector2i(2, 0),
	]
	board_tutorial.set_path(full_path)
	for y in 3:
		for x in 3:
			var cell := board_tutorial.get_cell(Vector2i(x, y))
			if cell != null:
				cell.set_visited_own(true)
	board_tutorial.animate_cursor_path(full_path, 0.42)


## Demo step 2: cursor thử đi đè lên ô đã đi rồi bị bật ngược
func _show_fail_demo() -> void:
	if board_tutorial == null:
		return
	var partial_path: Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1),
	]
	board_tutorial.set_path(partial_path)
	for y in 3:
		for x in 3:
			var pos := Vector2i(x, y)
			var cell := board_tutorial.get_cell(pos)
			if cell != null:
				cell.set_visited_own(partial_path.has(pos))
	board_tutorial.set_player_cell(Vector2i(0, 1), false)
	_run_fail_demo_cycle()


func _run_fail_demo_cycle() -> void:
	if current_step_index != 2 or not is_inside_tree() or board_tutorial == null:
		return
	board_tutorial.animate_cursor_fail_attempt(Vector2i(0, 1), Vector2i(0, 0))

	_demo_tween = create_tween()
	_demo_tween.tween_interval(0.26)
	_demo_tween.tween_callback(func() -> void:
		if current_step_index != 2 or board_tutorial == null:
			return
		var cell := board_tutorial.get_cell(Vector2i(0, 0))
		if cell != null:
			cell.play_fail()
		show_fail_feedback("STR_TUT_ONE_FAIL_01", "Ô này đi qua rồi! Chọn ô khác thử xem.")
	)
	_demo_tween.tween_interval(2.24)
	_demo_tween.tween_callback(_run_fail_demo_cycle)


func _is_input_allowed_at_step(step_idx: int) -> bool:
	return step_idx == 3


func _can_step_to(_from_cell: Vector2i, to_cell: Vector2i) -> bool:
	# Không được đi đè lên ô đã đi
	if _visited_cells.has(to_cell):
		show_fail_feedback("STR_TUT_ONE_FAIL_01", "Ô này đi qua rồi! Chọn ô khác thử xem.")
		if board_tutorial != null:
			var visited_cell := board_tutorial.get_cell(to_cell)
			if visited_cell != null:
				visited_cell.play_fail()
		return false

	# Chạm F nhưng chưa đi hết mọi ô
	if to_cell == FINISH_POS and _visited_cells.size() < TOTAL_CELLS - 1:
		show_fail_feedback("STR_TUT_ONE_FAIL_02", "Còn ô chưa đi kìa — F chỉ mở khi bạn đã đi hết cả bàn!")
		if board_tutorial != null:
			var finish_cell := board_tutorial.get_cell(to_cell)
			if finish_cell != null:
				finish_cell.play_fail()
			spawn_board_text("…", board_tutorial.get_cell_center(to_cell), Color(0.2, 0.33, 0.47))
		return false

	return true


func _on_step_succeeded(_next: Vector2i, _is_first_time: bool) -> void:
	_update_cell_colors()


func _is_goal_reached(next: Vector2i) -> bool:
	return next == FINISH_POS and _visited_cells.size() == TOTAL_CELLS


func _on_goal_reached(_next: Vector2i) -> void:
	play_cells_win()
	show_success_feedback("STR_TUT_ONE_05", "Tuyệt vời! Bạn vừa hoàn thành một nét.")
	show_step(4)


func complete_tutorial() -> void:
	_stop_demo()
	super.complete_tutorial()


func skip_tutorial() -> void:
	_stop_demo()
	super.skip_tutorial()


func skip_all_tutorials() -> void:
	_stop_demo()
	super.skip_all_tutorials()
