class_name HowToUseToolTutorial
extends BaseInteractivePathTutorial

## ============================================================================
## HowToUseToolTutorial: Dạy dùng 2 nút CÔNG CỤ (thanh hành động) —
## DỊCH CHUYỂN (teleport) và GỢI Ý (hint) — mỗi nút 3 lượt mỗi màn.
## Bàn 3×3 không tường. Bước 1 giới thiệu · bước 2 demo teleport · bước 3 demo hint
## · bước 4 luyện tập (tự đi + tự bấm 2 nút) · bước 5 chúc mừng.
## Kế thừa BaseInteractivePathTutorial (SOLID - OCP/SRP).
## ============================================================================

@export var lbl_hud_tools: Label = null
@export var btn_teleport: BaseButton = null
@export var btn_hint: BaseButton = null
@export var lbl_teleport_count: Label = null
@export var lbl_hint_count: Label = null

@export var START_POS := Vector2i(0, 0)
@export var FINISH_POS := Vector2i(2, 2)
@export var TOOL_USES := 3

var _teleport_left: int = TOOL_USES
var _hint_left: int = TOOL_USES
var _demo_tween: Tween = null


func _init_tutorial() -> void:
	tutorial_id = "how_to_use_tool"
	_start_cell = START_POS
	_goal_cell = FINISH_POS
	if board_tutorial != null:
		board_tutorial.setup_tutorial(
			3, 3,
			{
				START_POS: "S",
				Vector2i(1, 0): "", Vector2i(2, 0): "",
				Vector2i(0, 1): "", Vector2i(1, 1): "", Vector2i(2, 1): "",
				Vector2i(0, 2): "", Vector2i(1, 2): "",
				FINISH_POS: "F",
			},
			[],
			true,
			START_POS,
			FINISH_POS
		)
	reset_path()
	_update_tools(false)


func _get_default_steps() -> Array:
	return [
		{
			"message_key": "STR_TUT_TOOL_01",
			"fallback_text": "Thanh công cụ có 2 nút: DỊCH CHUYỂN và GỢI Ý — mỗi nút dùng được 3 lượt mỗi màn. Cùng xem cách dùng nhé!",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_TOOL_02",
			"fallback_text": "Ví dụ: nhấn DỊCH CHUYỂN — các ô trong tầm 2 ô sáng lên, chạm 1 ô để nhảy thẳng tới đó, kể cả có tường chắn.",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_TOOL_03",
			"fallback_text": "Ví dụ: nhấn GỢI Ý — ô nên đi tiếp sẽ sáng lên.",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_TOOL_04",
			"fallback_text": "Giờ tự thử — đi tới F, dùng DỊCH CHUYỂN và GỢI Ý khi cần nhé!",
			"advance_mode": "AUTO",
			"required_action": "DRAG_PATH",
		},
		{
			"message_key": "STR_TUT_TOOL_05",
			"fallback_text": "Tuyệt! Bạn đã nắm được 2 công cụ rồi.",
			"advance_mode": "MANUAL",
		},
	]


func _on_step_entered(index: int, _data: Dictionary) -> void:
	_stop_demo()
	match index:
		1:
			_start_teleport_demo()
		2:
			_start_hint_demo()
		3:
			_start_practice()


func _stop_demo() -> void:
	if _demo_tween != null and _demo_tween.is_valid():
		_demo_tween.kill()
		_demo_tween = null
	if board_tutorial != null:
		board_tutorial.stop_cursor_animation()


func _update_tools(animated: bool = true) -> void:
	if lbl_teleport_count != null:
		lbl_teleport_count.text = str(_teleport_left)
	if lbl_hint_count != null:
		lbl_hint_count.text = str(_hint_left)
	if btn_teleport != null:
		btn_teleport.disabled = _teleport_left <= 0
	if btn_hint != null:
		btn_hint.disabled = _hint_left <= 0
	if lbl_hud_tools == null:
		return
	var fmt := str(tr("STR_TUT_TOOL_HUD"))
	if fmt == "STR_TUT_TOOL_HUD":
		fmt = "Dịch chuyển: {0} lượt · Gợi ý: {1} lượt"
	lbl_hud_tools.text = fmt.format([_teleport_left, _hint_left])
	if not animated:
		return
	UIAnim.play_pop_in(lbl_hud_tools, 0.0, 0.88, 0.2)


func _flash_tool_button(btn: BaseButton) -> void:
	var tb := btn as TextureButton
	if tb == null or tb.disabled:
		return
	var normal_tex := tb.texture_normal
	var pressed_tex := tb.texture_pressed
	if pressed_tex == null:
		return
	tb.texture_normal = pressed_tex
	UIAnim.play_pop_in(tb, 0.0, 0.92, 0.14)
	get_tree().create_timer(0.18).timeout.connect(func() -> void:
		if is_instance_valid(tb):
			tb.texture_normal = normal_tex
	)


func _button_center(btn: Control) -> Vector2:
	if btn == null or board_host == null:
		return Vector2.ZERO
	return btn.global_position + btn.size * 0.5 - board_host.global_position


## Bước 2: demo DỊCH CHUYỂN — nhấn nút, các ô trong tầm 2 sáng lên, con trỏ nhảy tới 1 ô
func _start_teleport_demo() -> void:
	if board_tutorial == null:
		return
	_run_teleport_demo_cycle()


func _teleport_range_cells(from: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			var d := absi(dx) + absi(dy)
			if d == 0 or d > 2:
				continue
			var p := from + Vector2i(dx, dy)
			if p.x < 0 or p.y < 0 or p.x > 2 or p.y > 2:
				continue
			out.append(p)
	return out


func _set_teleport_glow(cells: Array[Vector2i], on: bool) -> void:
	if board_tutorial == null:
		return
	for p in cells:
		var c := board_tutorial.get_cell(p)
		if c != null and c.has_method("set_teleport_target"):
			c.set_teleport_target(on)


func _run_teleport_demo_cycle() -> void:
	if current_step_index != 1 or not is_inside_tree() or board_tutorial == null:
		return
	reset_path()
	_teleport_left = TOOL_USES
	_hint_left = TOOL_USES
	_update_tools(false)
	var glow := _teleport_range_cells(START_POS)
	var target := Vector2i(1, 1)

	_demo_tween = create_tween()
	# Nhấn DỊCH CHUYỂN -> các ô trong tầm sáng lên
	_demo_tween.tween_interval(0.5)
	_demo_tween.tween_callback(func() -> void:
		if current_step_index != 1: return
		_flash_tool_button(btn_teleport)
		_set_teleport_glow(glow, true)
	)
	# Chọn ô (1,1): con trỏ nhảy tới, huy hiệu 3 -> 2
	_demo_tween.tween_interval(1.3)
	_demo_tween.tween_callback(func() -> void:
		if current_step_index != 1 or board_tutorial == null: return
		_set_teleport_glow(glow, false)
		_visited_cells = [target]
		_current_cell = target
		board_tutorial.set_path(_visited_cells)
		board_tutorial.set_player_cell(_current_cell, true)
		var c := board_tutorial.get_cell(_current_cell)
		if c != null:
			c.play_step()
		_teleport_left = TOOL_USES - 1
		_update_tools(true)
		spawn_board_text("-1", _button_center(btn_teleport) + Vector2(0, -30), Color(0.78, 0.22, 0.22))
	)
	# Về lại ô xuất phát cho vòng lặp sau
	_demo_tween.tween_interval(1.6)
	_demo_tween.tween_callback(func() -> void:
		if current_step_index != 1: return
		reset_path()
		_teleport_left = TOOL_USES
		_update_tools(true)
	)
	_demo_tween.tween_interval(0.7)
	_demo_tween.tween_callback(_run_teleport_demo_cycle)


## Bước 3: demo GỢI Ý — nhấn nút, ô kế tiếp sáng nhịp 3 lần bằng Tween
func _start_hint_demo() -> void:
	if board_tutorial == null:
		return
	_run_hint_demo_cycle()


func _run_hint_demo_cycle() -> void:
	if current_step_index != 2 or not is_inside_tree() or board_tutorial == null:
		return
	reset_path()
	_teleport_left = TOOL_USES
	_hint_left = TOOL_USES
	_update_tools(false)

	_demo_tween = create_tween()
	# Nhấn GỢI Ý (huy hiệu 3 → 2)
	_demo_tween.tween_interval(0.5)
	_demo_tween.tween_callback(func() -> void:
		if current_step_index != 2: return
		_flash_tool_button(btn_hint)
		_hint_left = TOOL_USES - 1
		_update_tools(true)
		spawn_board_text("-1", _button_center(btn_hint) + Vector2(0, -30), Color(0.78, 0.22, 0.22))
	)
	# Ô kế tiếp sáng lên 3 nhịp
	for i in 3:
		_demo_tween.tween_interval(0.6)
		_demo_tween.tween_callback(func() -> void:
			if current_step_index != 2: return
			_pulse_hint_cell(Vector2i(1, 0))
		)
	# Trả huy hiệu về 3 cho vòng lặp sau
	_demo_tween.tween_interval(1.5)
	_demo_tween.tween_callback(func() -> void:
		if current_step_index != 2: return
		_hint_left = TOOL_USES
		_update_tools(true)
	)
	_demo_tween.tween_interval(0.8)
	_demo_tween.tween_callback(_run_hint_demo_cycle)


func _pulse_hint_cell(pos: Vector2i) -> void:
	if board_tutorial == null:
		return
	board_tutorial.pulse_cell(pos)
	spawn_board_text("?", board_tutorial.get_cell_center(pos), Color(0.13, 0.3, 0.43))


func _start_practice() -> void:
	reset_path()
	_teleport_left = TOOL_USES
	_hint_left = TOOL_USES
	_update_tools(true)


func _is_input_allowed_at_step(step_idx: int) -> bool:
	return step_idx == 3


func _on_goal_reached(next: Vector2i) -> void:
	play_cells_win()
	if board_tutorial != null:
		spawn_board_text("✓", board_tutorial.get_cell_center(next))
	show_success_feedback("STR_TUT_TOOL_05", "Tuyệt! Bạn đã nắm được 2 công cụ rồi.")
	show_step(4)


## Luyện tập: nhảy tới ô trong tầm 2 gần ô F nhất (tutorial không cần bước chọn ô)
func _on_teleport_pressed() -> void:
	if current_step_index != 3 or _teleport_left <= 0:
		return
	var best := Vector2i(-1, -1)
	var best_d := 1 << 20
	for p in _teleport_range_cells(_current_cell):
		var d := absi(p.x - FINISH_POS.x) + absi(p.y - FINISH_POS.y)
		if d < best_d:
			best_d = d
			best = p
	if best == Vector2i(-1, -1):
		show_fail_feedback("STR_TUT_TOOL_FAIL_TELEPORT", "Không có ô nào để dịch chuyển tới!")
		return
	_teleport_left -= 1
	_visited_cells = [best]
	_current_cell = best
	if board_tutorial != null:
		board_tutorial.set_path(_visited_cells)
		board_tutorial.set_player_cell(_current_cell, true)
	_update_tools(true)
	if best == FINISH_POS:
		_on_goal_reached(best)


func _on_hint_pressed() -> void:
	if current_step_index != 3 or _hint_left <= 0:
		return
	var next := _next_hint_cell()
	if next == Vector2i(-1, -1):
		return
	_hint_left -= 1
	_pulse_hint_cell(next)
	_update_tools(true)


func _next_hint_cell() -> Vector2i:
	if _current_cell == FINISH_POS:
		return Vector2i(-1, -1)
	var diff := FINISH_POS - _current_cell
	if diff.x != 0:
		return _current_cell + Vector2i(signi(diff.x), 0)
	return _current_cell + Vector2i(0, signi(diff.y))


func complete_tutorial() -> void:
	_stop_demo()
	super.complete_tutorial()


func skip_tutorial() -> void:
	_stop_demo()
	super.skip_tutorial()


func skip_all_tutorials() -> void:
	_stop_demo()
	super.skip_all_tutorials()
