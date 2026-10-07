class_name HowToPlayCountdownCostTutorial
extends BaseInteractivePathTutorial

## ============================================================================
## HowToPlayCountdownCostTutorial: Chế độ Countdown Cost (Planning.md §3.x)
## Bàn 3×3, mỗi ô có chi phí bước 1–3. Ngân sách cố định 10, phải tới F.
## Kế thừa BaseInteractivePathTutorial (SOLID - OCP/SRP).
## ============================================================================

@export var lbl_hud_budget: Label = null

var _budget: int = 10
var _displayed_budget: int = 10
var _demo_tween: Tween = null

const CELL_COSTS: Dictionary = {
	Vector2i(1, 0): 1, Vector2i(2, 0): 3,
	Vector2i(0, 1): 2, Vector2i(1, 1): 1, Vector2i(2, 1): 2,
	Vector2i(0, 2): 3, Vector2i(1, 2): 1, Vector2i(2, 2): 2,
}
@export var START_POS := Vector2i(0, 0)
@export var FINISH_POS := Vector2i(2, 0)
@export var INITIAL_BUDGET := 10


func _init_tutorial() -> void:
	tutorial_id = "how_to_play_countdown_cost"
	_start_cell = START_POS
	_goal_cell = FINISH_POS
	if board_tutorial != null:
		board_tutorial.setup_tutorial(
			3, 3,
			{
				START_POS: "S",
				Vector2i(1, 0): "1",
				FINISH_POS: "F",
				Vector2i(0, 1): "2",
				Vector2i(1, 1): "1",
				Vector2i(2, 1): "2",
				Vector2i(0, 2): "3",
				Vector2i(1, 2): "1",
				Vector2i(2, 2): "2",
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
			"message_key": "STR_TUT_CC_01",
			"fallback_text": "Chế độ Chi Phí: con số trên mỗi ô là số BƯỚC bị trừ khi bước vào ô đó.",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_CC_02",
			"fallback_text": "Ngân sách bước của bạn có hạn — ô nào có số nhỏ thì ít tốn hơn!",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_CC_03",
			"fallback_text": "Chọn đường RẺ NHẤT để đến F mà ngân sách không cạn trước.",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_CC_04",
			"fallback_text": "Giờ hãy thử — đi từ S tới F tiết kiệm nhất nhé!",
			"advance_mode": "AUTO",
			"required_action": "DRAG_PATH",
		},
		{
			"message_key": "STR_TUT_CC_05",
			"fallback_text": "Xuất sắc! Bạn đã chọn đường khôn ngoan rồi đó.",
			"advance_mode": "MANUAL",
		},
	]


func reset_path(start_pos: Vector2i = _start_cell, update_board: bool = true) -> void:
	_budget = INITIAL_BUDGET
	_displayed_budget = _budget
	_update_hud(false)
	if board_tutorial != null:
		board_tutorial.show_no_moves_overlay(false)
	super.reset_path(start_pos, update_board)


func _on_step_entered(index: int, _data: Dictionary) -> void:
	_stop_demo()
	match index:
		1:
			_start_cost_demo()
		2:
			_start_cheap_path_demo()
		3:
			reset_path()


func _stop_demo() -> void:
	if _demo_tween != null and _demo_tween.is_valid():
		_demo_tween.kill()
		_demo_tween = null
	if board_tutorial != null:
		board_tutorial.stop_cursor_animation()


## Bước 2: so sánh ô rẻ (1) với ô đắt (2) — cursor thăm từng ô, HUD ngân sách giảm theo bằng Tween
func _start_cost_demo() -> void:
	if board_tutorial == null:
		return
	_run_cost_demo_cycle()


func _run_cost_demo_cycle() -> void:
	if current_step_index != 1 or not is_inside_tree() or board_tutorial == null:
		return
	_displayed_budget = INITIAL_BUDGET
	_update_hud(false)

	# Ô rẻ: S → (1,0)[chi phí = 1]
	board_tutorial.animate_cursor_drag(Vector2i(0, 0), Vector2i(1, 0), 0.5)

	_demo_tween = create_tween()
	_demo_tween.tween_interval(0.72)
	_demo_tween.tween_callback(func() -> void:
		if current_step_index != 1 or board_tutorial == null: return
		_displayed_budget = INITIAL_BUDGET - 1
		_update_hud(true)
		spawn_board_text("-1", board_tutorial.get_cell_center(Vector2i(1, 0)), Color(0.8, 0.18, 0.18))
	)
	_demo_tween.tween_interval(1.13)
	_demo_tween.tween_callback(func() -> void:
		if current_step_index != 1 or board_tutorial == null: return
		_displayed_budget = INITIAL_BUDGET
		_update_hud(false)
		board_tutorial.stop_cursor_animation()
	)
	# Ô đắt hơn: S → (0,1)[chi phí = 2]
	_demo_tween.tween_interval(0.5)
	_demo_tween.tween_callback(func() -> void:
		if current_step_index != 1 or board_tutorial == null: return
		board_tutorial.animate_cursor_drag(Vector2i(0, 0), Vector2i(0, 1), 0.5)
	)
	_demo_tween.tween_interval(0.73)
	_demo_tween.tween_callback(func() -> void:
		if current_step_index != 1 or board_tutorial == null: return
		_displayed_budget = INITIAL_BUDGET - 2
		_update_hud(true)
		spawn_board_text("-2", board_tutorial.get_cell_center(Vector2i(0, 1)), Color(0.8, 0.18, 0.18))
	)
	_demo_tween.tween_interval(1.12)
	_demo_tween.tween_callback(func() -> void:
		if current_step_index != 1 or board_tutorial == null: return
		_displayed_budget = INITIAL_BUDGET
		_update_hud(false)
		board_tutorial.stop_cursor_animation()
	)
	_demo_tween.tween_interval(0.6)
	_demo_tween.tween_callback(_run_cost_demo_cycle)


## Bước 3: demo đường rẻ nhất S → (1,0)[1] → F(2,0) — chỉ tốn 1 bước ngân sách
func _start_cheap_path_demo() -> void:
	if board_tutorial == null:
		return
	var demo_path: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
	board_tutorial.animate_cursor_path(demo_path, 0.52)
	_run_cheap_path_hud_cycle()


func _run_cheap_path_hud_cycle() -> void:
	if current_step_index != 2 or not is_inside_tree() or board_tutorial == null:
		return
	_displayed_budget = INITIAL_BUDGET
	_update_hud(false)

	_demo_tween = create_tween()
	_demo_tween.tween_interval(0.83)
	_demo_tween.tween_callback(func() -> void:
		if current_step_index != 2 or board_tutorial == null: return
		_displayed_budget = INITIAL_BUDGET - 1
		_update_hud(true)
		spawn_board_text("-1", board_tutorial.get_cell_center(Vector2i(1, 0)), Color(0.8, 0.18, 0.18))
	)
	_demo_tween.tween_interval(0.72)
	_demo_tween.tween_callback(func() -> void:
		if current_step_index != 2 or board_tutorial == null: return
		var finish := board_tutorial.get_cell(FINISH_POS)
		if finish != null:
			finish.play_step()
		spawn_board_text("✓", board_tutorial.get_cell_center(FINISH_POS), Color(0.18, 0.49, 0.2))
	)
	_demo_tween.tween_interval(1.3)
	_demo_tween.tween_callback(_run_cheap_path_hud_cycle)


func _is_input_allowed_at_step(step_idx: int) -> bool:
	return step_idx == 3


func _can_step_to(_from_cell: Vector2i, to_cell: Vector2i) -> bool:
	var cost := int(CELL_COSTS.get(to_cell, 0))
	if to_cell != FINISH_POS and cost > _budget:
		show_fail_feedback("STR_TUT_CC_FAIL_01", "Hết ngân sách! Chọn ô chi phí thấp hơn.")
		flash_fail(lbl_hud_budget)
		if board_tutorial != null:
			var c := board_tutorial.get_cell(to_cell)
			if c != null:
				c.play_fail()
		return false
	return true


func _on_step_succeeded(next: Vector2i, _is_first_time: bool) -> void:
	var cost := int(CELL_COSTS.get(next, 0))
	if next != FINISH_POS and cost > 0:
		_budget -= cost
		_displayed_budget = _budget
		_update_hud(true)
		if board_tutorial != null:
			spawn_board_text("-%d" % cost, board_tutorial.get_cell_center(next), Color(0.8, 0.2, 0.2))

	if next != FINISH_POS and _is_stuck_in_tutorial():
		_show_board_no_moves()


func _on_goal_reached(next: Vector2i) -> void:
	play_cells_win()
	if board_tutorial != null:
		spawn_board_text("✓", board_tutorial.get_cell_center(next))
	show_success_feedback("STR_TUT_CC_05", "Xuất sắc! Bạn đã chọn đường khôn ngoan rồi đó.")
	show_step(4)


func _is_stuck_in_tutorial() -> bool:
	for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var nxt := _current_cell + d
		if nxt.x < 0 or nxt.x > 2 or nxt.y < 0 or nxt.y > 2:
			continue
		if nxt == FINISH_POS:
			return false
		var cost := int(CELL_COSTS.get(nxt, 0))
		if cost <= _budget:
			return false
	return true


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


func _update_hud(animated: bool = true) -> void:
	if lbl_hud_budget == null:
		return
	var fmt := str(tr("STR_TUT_CC_HUD_FORMAT"))
	if fmt == "STR_TUT_CC_HUD_FORMAT":
		fmt = "Ngân sách: {0} bước"
	lbl_hud_budget.text = fmt.format([_displayed_budget])
	if not animated:
		return
	var full := _displayed_budget <= 0
	lbl_hud_budget.add_theme_color_override("font_color",
		Color(0.78, 0.18, 0.18) if full else Color(0.18, 0.22, 0.26))
	UIAnim.play_pop_in(lbl_hud_budget, 0.0, 0.88, 0.2)


func complete_tutorial() -> void:
	_stop_demo()
	super.complete_tutorial()


func skip_tutorial() -> void:
	_stop_demo()
	super.skip_tutorial()


func skip_all_tutorials() -> void:
	_stop_demo()
	super.skip_all_tutorials()
