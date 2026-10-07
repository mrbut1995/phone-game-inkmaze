class_name HowToPlaySumPathTutorial
extends BaseInteractivePathTutorial

## ============================================================================
## HowToPlaySumPathTutorial: Chế độ Tính Tổng (Planning.md §3.7)
## Dùng BoardTutorial: bàn 3×3, mỗi ô có điểm 1..4, mini HUD hiện Tổng / Mục tiêu (= 8).
## Kế thừa BaseInteractivePathTutorial (SOLID - OCP/SRP).
## ============================================================================

@export var lbl_hud_sum: Label = null

var _current_sum: int = 2
var _displayed_sum: int = 2
var _demo_tween: Tween = null

const CELL_VALUES: Dictionary = {
	Vector2i(0, 0): 2, Vector2i(1, 0): 1, Vector2i(2, 0): 3,
	Vector2i(0, 1): 4, Vector2i(1, 1): 2, Vector2i(2, 1): 1,
	Vector2i(0, 2): 1, Vector2i(1, 2): 3, Vector2i(2, 2): 2,
}
@export var START_POS := Vector2i(0, 0)
@export var FINISH_POS := Vector2i(2, 2)
@export var TARGET_SUM := 8


func _init_tutorial() -> void:
	tutorial_id = "how_to_play_sum_path"
	_start_cell = START_POS
	_goal_cell = FINISH_POS
	if board_tutorial != null:
		board_tutorial.setup_tutorial(
			3, 3,
			{
				START_POS: "S",
				Vector2i(1, 0): "1",
				Vector2i(2, 0): "3",
				Vector2i(0, 1): "4",
				Vector2i(1, 1): "2",
				Vector2i(2, 1): "1",
				Vector2i(0, 2): "1",
				Vector2i(1, 2): "3",
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
			"message_key": "STR_TUT_SUM_01",
			"fallback_text": "Chế độ Tính Tổng: đường đi của bạn phải có tổng bằng mục tiêu!",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_SUM_02",
			"fallback_text": "Mỗi ô bạn đi qua được cộng vào tổng. Số ở ô S được tính là điểm khởi đầu.",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_SUM_03",
			"fallback_text": "Nếu đến F mà tổng chưa bằng mục tiêu: cần chọn đường khác.",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_SUM_04",
			"fallback_text": "Giờ hãy tìm đường có tổng đúng bằng 8 nhé!",
			"advance_mode": "AUTO",
			"required_action": "DRAG_PATH"
		},
		{
			"message_key": "STR_TUT_SUM_05",
			"fallback_text": "Chuẩn không cần chỉnh!",
			"advance_mode": "MANUAL",
		}
	]


func reset_path(start_pos: Vector2i = _start_cell, update_board: bool = true) -> void:
	_current_sum = int(CELL_VALUES.get(start_pos, 2))
	_displayed_sum = _current_sum
	_update_hud(false)
	if board_tutorial != null:
		board_tutorial.show_no_moves_overlay(false)
	super.reset_path(start_pos, update_board)


func _on_step_entered(index: int, _data: Dictionary) -> void:
	_stop_demo()
	match index:
		2:
			_show_sum_path_demo()
		3:
			reset_path()


func _stop_demo() -> void:
	if _demo_tween != null and _demo_tween.is_valid():
		_demo_tween.kill()
		_demo_tween = null
	if board_tutorial != null:
		board_tutorial.stop_cursor_animation()


## Demo step 2: cursor đi theo đường S→(1,0)→(1,1)→(2,1)→F có tổng = 8, lặp bằng Tween
func _show_sum_path_demo() -> void:
	if board_tutorial == null:
		return
	var demo_path: Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 2),
	]
	board_tutorial.set_path(demo_path)
	board_tutorial.animate_cursor_path(demo_path, 0.42)
	_run_sum_hud_cycle()


func _run_sum_hud_cycle() -> void:
	if current_step_index != 2 or not is_inside_tree() or board_tutorial == null:
		return
	# Reset HUD đầu chu kỳ
	_displayed_sum = 2
	_update_hud(false)

	_demo_tween = create_tween()
	# S(2)→(1,0)+1 ≈ 0.83s
	_demo_tween.tween_interval(0.83)
	_demo_tween.tween_callback(func() -> void:
		if current_step_index != 2 or board_tutorial == null: return
		_displayed_sum = 3
		_update_hud(true)
		spawn_board_text("+1", board_tutorial.get_cell_center(Vector2i(1, 0)))
	)
	# (1,0)→(1,1)+2 ≈ 0.69s (1.52 - 0.83)
	_demo_tween.tween_interval(0.69)
	_demo_tween.tween_callback(func() -> void:
		if current_step_index != 2 or board_tutorial == null: return
		_displayed_sum = 5
		_update_hud(true)
		spawn_board_text("+2", board_tutorial.get_cell_center(Vector2i(1, 1)))
	)
	# (1,1)→(2,1)+1 ≈ 0.69s (2.21 - 1.52)
	_demo_tween.tween_interval(0.69)
	_demo_tween.tween_callback(func() -> void:
		if current_step_index != 2 or board_tutorial == null: return
		_displayed_sum = 6
		_update_hud(true)
		spawn_board_text("+1", board_tutorial.get_cell_center(Vector2i(2, 1)))
	)
	# (2,1)→F(2,2)+2 = 8 ≈ 0.69s (2.90 - 2.21)
	_demo_tween.tween_interval(0.69)
	_demo_tween.tween_callback(func() -> void:
		if current_step_index != 2 or board_tutorial == null: return
		_displayed_sum = 8
		_update_hud(true)
		spawn_board_text("+2", board_tutorial.get_cell_center(Vector2i(2, 2)))
		var finish := board_tutorial.get_cell(FINISH_POS)
		if finish != null:
			finish.play_step()
	)
	# Lặp lại sau ~1.1s
	_demo_tween.tween_interval(1.1)
	_demo_tween.tween_callback(_run_sum_hud_cycle)


func _update_hud(animated: bool = true) -> void:
	if lbl_hud_sum == null:
		return
	var fmt := str(tr("STR_TUT_SUM_HUD_FORMAT"))
	if fmt == "STR_TUT_SUM_HUD_FORMAT":
		fmt = "Tổng: {0}  |  Mục tiêu: = {1}"
	lbl_hud_sum.text = fmt.format([_displayed_sum, TARGET_SUM])

	if not animated:
		return

	if _displayed_sum == TARGET_SUM:
		lbl_hud_sum.add_theme_color_override("font_color", Color("#2E7D32"))
	elif _displayed_sum > TARGET_SUM:
		lbl_hud_sum.add_theme_color_override("font_color", Color("#C62828"))
	else:
		lbl_hud_sum.add_theme_color_override("font_color", Color("#2C3E50"))
	UIAnim.play_pop_in(lbl_hud_sum, 0.0, 0.88, 0.2)


func _is_input_allowed_at_step(step_idx: int) -> bool:
	return step_idx == 3


func _on_step_succeeded(next: Vector2i, is_first_time: bool) -> void:
	if is_first_time and CELL_VALUES.has(next):
		var gain := int(CELL_VALUES[next])
		_current_sum += gain
		_displayed_sum = _current_sum
		_update_hud(true)
		if board_tutorial != null:
			spawn_board_text("+%d" % gain, board_tutorial.get_cell_center(next))

	if next == FINISH_POS:
		if _current_sum == TARGET_SUM:
			play_cells_win()
			if board_tutorial != null:
				spawn_board_text("✓", board_tutorial.get_cell_center(next))
			show_success_feedback("STR_TUT_SUM_05", "Chuẩn không cần chỉnh!")
			show_step(4)
		else:
			show_fail_feedback("STR_TUT_SUM_FAIL_01", "Tổng chưa bằng 8 rồi! Thử đi đường khác xem.")
			shake_node(lbl_hud_sum, 0.25, 6.0)
			flash_fail(lbl_hud_sum)
			if board_tutorial != null:
				var c := board_tutorial.get_cell(next)
				if c != null:
					c.play_fail()
			get_tree().create_timer(0.8).timeout.connect(func() -> void:
				if current_step_index == 3 and is_inside_tree():
					reset_path()
			)
		return

	if _current_sum > TARGET_SUM:
		_show_board_no_moves()


func _show_board_no_moves() -> void:
	if board_tutorial == null:
		return
	if not board_tutorial.is_connected("no_moves_retry_pressed", _on_board_retry):
		board_tutorial.connect("no_moves_retry_pressed", _on_board_retry)
	board_tutorial.show_no_moves_overlay(true)


func _on_board_retry() -> void:
	if board_tutorial != null:
		board_tutorial.show_no_moves_overlay(false)
	reset_path()


func complete_tutorial() -> void:
	_stop_demo()
	super.complete_tutorial()


func skip_tutorial() -> void:
	_stop_demo()
	super.skip_tutorial()


func skip_all_tutorials() -> void:
	_stop_demo()
	super.skip_all_tutorials()
