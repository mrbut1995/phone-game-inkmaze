class_name HowToPlayFadingInkTutorial
extends BaseInteractivePathTutorial

## ============================================================================
## HowToPlayFadingInkTutorial: Chế độ Mực Phai (Planning.md §3.x)
## Bàn 3×3, không tường trong. Mỗi ô có số = mực. MỌI ô nhạt 1 sau mỗi bước.
## Kế thừa BaseInteractivePathTutorial (SOLID - OCP/SRP).
## ============================================================================

@export var lbl_hud_ink: Label = null

var _moves_made: int = 0
var _demo_tween: Tween = null

const CELL_INK: Dictionary = {
	Vector2i(1, 0): 4, Vector2i(2, 0): 2,
	Vector2i(0, 1): 3, Vector2i(1, 1): 5, Vector2i(2, 1): 3,
	Vector2i(0, 2): 2, Vector2i(1, 2): 4,
}
@export var START_POS := Vector2i(0, 0)
@export var FINISH_POS := Vector2i(2, 2)


func _init_tutorial() -> void:
	tutorial_id = "how_to_play_fading_ink"
	_start_cell = START_POS
	_goal_cell = FINISH_POS
	if board_tutorial != null:
		var cells_map: Dictionary = {}
		cells_map[START_POS] = "S"
		cells_map[FINISH_POS] = "F"
		for pos: Vector2i in CELL_INK:
			cells_map[pos] = str(CELL_INK[pos])
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
			"message_key": "STR_TUT_FI_01",
			"fallback_text": "Chế độ Mực Phai: số trên ô là LượNG MỰC còn lại — bước vào ô hết mực là bị chặn.",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_FI_02",
			"fallback_text": "MỖI BƯỚC ĐI làm TẤT CẢ ô nhạt đi 1 — hãy về đích trước khi mực cạn!",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_FI_03",
			"fallback_text": "Tìm đường ngắn nhất đến F trước khi lối đi biến mất.",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_FI_04",
			"fallback_text": "Giờ thử đi từ S tới F nhanh nhất có thể nhé!",
			"advance_mode": "AUTO",
			"required_action": "DRAG_PATH",
		},
		{
			"message_key": "STR_TUT_FI_05",
			"fallback_text": "Tuyệt! Bạn đã tìm đường kịp trước khi mực cạn.",
			"advance_mode": "MANUAL",
		},
	]


func reset_path(start_pos: Vector2i = _start_cell, update_board: bool = true) -> void:
	_moves_made = 0
	if board_tutorial != null:
		board_tutorial.show_no_moves_overlay(false)
		for pos: Vector2i in CELL_INK:
			var cell := board_tutorial.get_cell(pos)
			if cell != null:
				cell.set_text(str(CELL_INK[pos]))
	_update_hud(false)
	super.reset_path(start_pos, update_board)


func _on_step_entered(index: int, _data: Dictionary) -> void:
	_stop_demo()
	match index:
		1:
			_start_fade_demo()
		2:
			_start_shortest_path_demo()
		3:
			reset_path()


func _stop_demo() -> void:
	if _demo_tween != null and _demo_tween.is_valid():
		_demo_tween.kill()
		_demo_tween = null
	if board_tutorial != null:
		board_tutorial.stop_cursor_animation()


## Bước 2: cursor đi 1 bước — tất cả số mực giảm 1, lặp bằng Tween
func _start_fade_demo() -> void:
	if board_tutorial == null:
		return
	_run_fade_demo_cycle()


func _run_fade_demo_cycle() -> void:
	if current_step_index != 1 or not is_inside_tree() or board_tutorial == null:
		return
	for pos: Vector2i in CELL_INK:
		var cell := board_tutorial.get_cell(pos)
		if cell != null:
			cell.set_text(str(CELL_INK[pos]))

	board_tutorial.animate_cursor_drag(Vector2i(0, 0), Vector2i(0, 1), 0.5)

	_demo_tween = create_tween()
	_demo_tween.tween_interval(0.7)
	_demo_tween.tween_callback(func() -> void:
		if current_step_index != 1 or board_tutorial == null: return
		for pos: Vector2i in CELL_INK:
			var new_ink: int = int(CELL_INK[pos]) - 1
			var cell := board_tutorial.get_cell(pos)
			if cell != null:
				cell.set_text(str(new_ink) if new_ink > 0 else "")
				if new_ink == 0:
					cell.play_fail()
		spawn_board_text("-1", board_tutorial.get_cell_center(Vector2i(1, 0)), Color(0.78, 0.22, 0.22))
	)
	_demo_tween.tween_interval(1.7)
	_demo_tween.tween_callback(func() -> void:
		if current_step_index != 1 or board_tutorial == null: return
		for pos: Vector2i in CELL_INK:
			var cell := board_tutorial.get_cell(pos)
			if cell != null:
				cell.set_text(str(CELL_INK[pos]))
		board_tutorial.stop_cursor_animation()
	)
	_demo_tween.tween_interval(0.8)
	_demo_tween.tween_callback(_run_fade_demo_cycle)


## Bước 3: demo đường ngắn nhất S→(1,0)→(1,1)→(1,2)→F(2,2)
func _start_shortest_path_demo() -> void:
	if board_tutorial == null:
		return
	var demo_path: Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), FINISH_POS
	]
	board_tutorial.animate_cursor_path(demo_path, 0.48)
	_run_shortest_path_hud_cycle()


func _run_shortest_path_hud_cycle() -> void:
	if current_step_index != 2 or not is_inside_tree() or board_tutorial == null:
		return
	for pos: Vector2i in CELL_INK:
		var cell := board_tutorial.get_cell(pos)
		if cell != null:
			cell.set_text(str(CELL_INK[pos]))
	_update_hud(false)

	var path := [Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), FINISH_POS]
	var step_delay := 0.82

	_demo_tween = create_tween()
	for i in path.size():
		var moved := i + 1
		var cell_pos: Vector2i = path[i]
		_demo_tween.tween_interval(step_delay)
		_demo_tween.tween_callback(func() -> void:
			if current_step_index != 2 or board_tutorial == null: return
			for pos: Vector2i in CELL_INK:
				var new_ink: int = int(CELL_INK[pos]) - moved
				var cell := board_tutorial.get_cell(pos)
				if cell != null:
					cell.set_text(str(new_ink) if new_ink > 0 else "")
			_update_hud(true)
			if cell_pos == FINISH_POS:
				spawn_board_text("✓", board_tutorial.get_cell_center(FINISH_POS), Color(0.18, 0.49, 0.2))
		)
	_demo_tween.tween_interval(0.62)
	_demo_tween.tween_callback(_run_shortest_path_hud_cycle)


func _is_input_allowed_at_step(step_idx: int) -> bool:
	return step_idx == 3


func _can_step_to(_from_cell: Vector2i, to_cell: Vector2i) -> bool:
	if to_cell != FINISH_POS and CELL_INK.has(to_cell):
		var remaining := maxi(int(CELL_INK[to_cell]) - _moves_made, 0)
		if remaining <= 0:
			show_fail_feedback("STR_TUT_FI_FAIL_01", "Ô này đã cạn mực — hãy chọn ô khác!")
			if board_tutorial != null:
				var c := board_tutorial.get_cell(to_cell)
				if c != null:
					c.play_fail()
			return false
	return true


func _on_step_succeeded(_next: Vector2i, _is_first_time: bool) -> void:
	_moves_made += 1
	_update_ink_display()
	_update_hud(true)
	if _next != FINISH_POS and _is_stuck_in_tutorial():
		_show_board_no_moves()


func _on_goal_reached(next: Vector2i) -> void:
	play_cells_win()
	if board_tutorial != null:
		spawn_board_text("✓", board_tutorial.get_cell_center(next))
	show_success_feedback("STR_TUT_FI_05", "Tuyệt! Bạn đã tìm đường kịp trước khi mực cạn.")
	show_step(4)


func _update_ink_display() -> void:
	if board_tutorial == null:
		return
	for pos: Vector2i in CELL_INK:
		var remaining := maxi(int(CELL_INK[pos]) - _moves_made, 0)
		var cell := board_tutorial.get_cell(pos)
		if cell != null:
			cell.set_text(str(remaining) if remaining > 0 else "")


func _is_stuck_in_tutorial() -> bool:
	for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var nxt := _current_cell + d
		if nxt.x < 0 or nxt.x > 2 or nxt.y < 0 or nxt.y > 2:
			continue
		if nxt == FINISH_POS:
			return false
		if CELL_INK.has(nxt):
			var remaining := maxi(int(CELL_INK[nxt]) - _moves_made, 0)
			if remaining > 0:
				return false
	return true


func _show_board_no_moves() -> void:
	if board_tutorial == null:
		return
	# Dây `no_moves_retry_pressed → _on_board_retry` khai trong `how_to_play_fading_ink.tscn`
	board_tutorial.show_no_moves_overlay(true)


func _on_board_retry() -> void:
	if board_tutorial != null:
		board_tutorial.show_no_moves_overlay(false)
	reset_path()


func _update_hud(animated: bool = true) -> void:
	if lbl_hud_ink == null:
		return
	var moves_left := maxi(int(CELL_INK.values().min()) - _moves_made, 0)
	var fmt := str(tr("STR_TUT_FI_HUD_FORMAT"))
	if fmt == "STR_TUT_FI_HUD_FORMAT":
		fmt = "Bước đã đi: {0}"
	lbl_hud_ink.text = fmt.format([_moves_made])
	if not animated:
		return
	UIAnim.play_pop_in(lbl_hud_ink, 0.0, 0.88, 0.2)
	if moves_left <= 1:
		lbl_hud_ink.add_theme_color_override("font_color", Color(0.78, 0.18, 0.18))
	else:
		lbl_hud_ink.remove_theme_color_override("font_color")


func complete_tutorial() -> void:
	_stop_demo()
	super.complete_tutorial()


func skip_tutorial() -> void:
	_stop_demo()
	super.skip_tutorial()


func skip_all_tutorials() -> void:
	_stop_demo()
	super.skip_all_tutorials()
