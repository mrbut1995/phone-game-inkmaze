class_name HowToPlayFogOfWarTutorial
extends BaseInteractivePathTutorial

## ============================================================================
## HowToPlayFogOfWarTutorial: Chế độ Sương Mù (FogOfWar).
## Bàn 3×3 có tường vô hình. Sương mù che số — chỉ hé lộ xung quanh ô hiện tại.
## Kế thừa BaseInteractivePathTutorial (SOLID - OCP/SRP).
## ============================================================================

@export var lbl_hud_retries: Label = null

var _retries: int = 3
var _demo_tween: Tween = null

const START_POS := Vector2i(0, 0)
const FINISH_POS := Vector2i(2, 2)
## Tường vô hình giữa (0,0)↔(1,0) và (1,1)↔(1,2)
const WALLS := [
	{"is_h": false, "lattice": Vector2i(1, 0), "visible": false},
	{"is_h": true,  "lattice": Vector2i(1, 2), "visible": false},
]


func _init_tutorial() -> void:
	tutorial_id = "how_to_play_fog_of_war"
	_start_cell = START_POS
	_goal_cell = FINISH_POS
	if board_tutorial != null:
		board_tutorial.setup_tutorial(
			3, 3,
			{
				START_POS: "S",
				Vector2i(1, 0): "?",
				Vector2i(2, 0): "?",
				Vector2i(0, 1): "?",
				Vector2i(1, 1): "?",
				Vector2i(2, 1): "?",
				Vector2i(0, 2): "?",
				Vector2i(1, 2): "?",
				FINISH_POS: "F",
			},
			WALLS,
			true,
			START_POS,
			FINISH_POS
		)
	reset_path()


func _get_default_steps() -> Array:
	return [
		{
			"message_key": "STR_TUT_FOG_01",
			"fallback_text": "Chế độ Sương Mù: số trên ô chỉ hiện ra quanh VỊ TRÍ HIỆN TẠI của bạn.",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_FOG_02",
			"fallback_text": "Di chuyển để khám phá — mỗi bước hé lộ thêm số xung quanh!",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_FOG_03",
			"fallback_text": "Đâm tường vô hình sẽ bị đẩy về S và mất 1 LƯỢT THỬ LẠI (3 lượt).",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_FOG_04",
			"fallback_text": "Dùng các con số để suy luận tường, rồi đi thận trọng từ S tới F!",
			"advance_mode": "AUTO",
			"required_action": "DRAG_PATH",
		},
		{
			"message_key": "STR_TUT_FOG_05",
			"fallback_text": "Xuất sắc! Bạn đã vượt qua sương mù rồi đó.",
			"advance_mode": "MANUAL",
		},
	]


func reset_path(start_pos: Vector2i = _start_cell, update_board: bool = true) -> void:
	_retries = 3
	_update_hud(false)
	_reset_fog_display()
	_apply_fog(start_pos)
	super.reset_path(start_pos, update_board)


func _on_step_entered(index: int, _data: Dictionary) -> void:
	_stop_demo()
	match index:
		1:
			_start_reveal_demo()
		2:
			_start_wall_hit_demo()
		3:
			reset_path()


func _stop_demo() -> void:
	if _demo_tween != null and _demo_tween.is_valid():
		_demo_tween.kill()
		_demo_tween = null
	if board_tutorial != null:
		board_tutorial.stop_cursor_animation()


## Bước 2: cursor di chuyển — hé lộ dần số xung quanh từng ô bằng Tween
func _start_reveal_demo() -> void:
	if board_tutorial == null:
		return
	_run_reveal_demo_cycle()


func _run_reveal_demo_cycle() -> void:
	if current_step_index != 1 or not is_inside_tree() or board_tutorial == null:
		return
	_reset_fog_display()
	_apply_fog(START_POS)

	board_tutorial.animate_cursor_drag(Vector2i(0, 0), Vector2i(0, 1), 0.5)

	_demo_tween = create_tween()
	_demo_tween.tween_interval(0.72)
	_demo_tween.tween_callback(func() -> void:
		if current_step_index != 1: return
		_apply_fog(Vector2i(0, 1))
	)
	_demo_tween.tween_interval(0.78)
	_demo_tween.tween_callback(func() -> void:
		if current_step_index != 1 or board_tutorial == null: return
		board_tutorial.animate_cursor_drag(Vector2i(0, 1), Vector2i(1, 1), 0.5)
	)
	_demo_tween.tween_interval(0.75)
	_demo_tween.tween_callback(func() -> void:
		if current_step_index != 1: return
		_apply_fog(Vector2i(1, 1))
	)
	_demo_tween.tween_interval(1.25)
	_demo_tween.tween_callback(func() -> void:
		if current_step_index != 1 or board_tutorial == null: return
		board_tutorial.stop_cursor_animation()
	)
	_demo_tween.tween_interval(0.7)
	_demo_tween.tween_callback(_run_reveal_demo_cycle)


## Bước 3: demo đâm tường → bị đẩy về S, mất 1 lượt thử lại
func _start_wall_hit_demo() -> void:
	if board_tutorial == null:
		return
	_run_wall_hit_demo_cycle()


func _run_wall_hit_demo_cycle() -> void:
	if current_step_index != 2 or not is_inside_tree() or board_tutorial == null:
		return
	_retries = 3
	_update_hud(false)
	_reset_fog_display()
	_apply_fog(START_POS)

	board_tutorial.animate_cursor_drag(Vector2i(0, 0), Vector2i(1, 0), 0.5)

	_demo_tween = create_tween()
	_demo_tween.tween_interval(0.72)
	_demo_tween.tween_callback(func() -> void:
		if current_step_index != 2 or board_tutorial == null: return
		board_tutorial.reveal_wall_segment(false, Vector2i(1, 0), true)
		show_fail_feedback("STR_TUT_FOG_FAIL_01", "Đâm tường! Mất 1 lượt thử lại.")
		_retries = 2
		_update_hud(true)
	)
	_demo_tween.tween_interval(1.48)
	_demo_tween.tween_callback(func() -> void:
		if current_step_index != 2 or board_tutorial == null: return
		board_tutorial.stop_cursor_animation()
		board_tutorial.reveal_wall_segment(false, Vector2i(1, 0), false)
	)
	_demo_tween.tween_interval(0.8)
	_demo_tween.tween_callback(_run_wall_hit_demo_cycle)


## Ẩn số sương mù: đặt "?" cho mọi ô không phải S/F
func _reset_fog_display() -> void:
	if board_tutorial == null:
		return
	for y in 3:
		for x in 3:
			var pos := Vector2i(x, y)
			if pos == START_POS or pos == FINISH_POS:
				continue
			var cell := board_tutorial.get_cell(pos)
			if cell != null:
				cell.set_text("?")


## Hé lộ số quanh ô center (bán kính 1)
func _apply_fog(center: Vector2i) -> void:
	if board_tutorial == null:
		return
	const WALLS_AROUND: Dictionary = {
		Vector2i(0, 0): 1, Vector2i(1, 0): 1, Vector2i(2, 0): 0,
		Vector2i(0, 1): 0, Vector2i(1, 1): 1, Vector2i(2, 1): 0,
		Vector2i(0, 2): 0, Vector2i(1, 2): 1, Vector2i(2, 2): 0,
	}
	for d: Vector2i in [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var pos := center + d
		if pos.x < 0 or pos.x > 2 or pos.y < 0 or pos.y > 2:
			continue
		if pos == START_POS or pos == FINISH_POS:
			continue
		var cell := board_tutorial.get_cell(pos)
		if cell != null:
			cell.set_text(str(WALLS_AROUND.get(pos, 0)))


func _is_input_allowed_at_step(step_idx: int) -> bool:
	return step_idx == 3


func _can_step_to(from_cell: Vector2i, to_cell: Vector2i) -> bool:
	var hit_wall := false
	for w in WALLS:
		var is_h: bool = w["is_h"]
		var lat: Vector2i = w["lattice"]
		if not is_h:
			if (from_cell == Vector2i(lat.x - 1, lat.y) and to_cell == Vector2i(lat.x, lat.y)) or \
			   (from_cell == Vector2i(lat.x, lat.y) and to_cell == Vector2i(lat.x - 1, lat.y)):
				hit_wall = true
				break
		else:
			if (from_cell == Vector2i(lat.x, lat.y - 1) and to_cell == Vector2i(lat.x, lat.y)) or \
			   (from_cell == Vector2i(lat.x, lat.y) and to_cell == Vector2i(lat.x, lat.y - 1)):
				hit_wall = true
				break

	if hit_wall:
		if board_tutorial != null:
			board_tutorial.show_wall_hit_at(from_cell, to_cell)
		show_fail_feedback("STR_TUT_FOG_FAIL_01", "Đâm tường vô hình! Thử đường khác.")
		_retries -= 1
		_update_hud(true)
		if _retries <= 0:
			get_tree().create_timer(0.6).timeout.connect(func() -> void:
				if current_step_index == 3 and is_inside_tree():
					reset_path()
			)
		return false

	return true


func _on_step_succeeded(next: Vector2i, _is_first_time: bool) -> void:
	_apply_fog(next)


func _on_goal_reached(next: Vector2i) -> void:
	play_cells_win()
	if board_tutorial != null:
		spawn_board_text("✓", board_tutorial.get_cell_center(next))
	show_success_feedback("STR_TUT_FOG_05", "Xuất sắc! Bạn đã vượt qua sương mù rồi đó.")
	show_step(4)


func _update_hud(animated: bool = true) -> void:
	if lbl_hud_retries == null:
		return
	var fmt := str(tr("STR_TUT_FOG_HUD_FORMAT"))
	if fmt == "STR_TUT_FOG_HUD_FORMAT":
		fmt = "Lượt thử: {0} / 3"
	lbl_hud_retries.text = fmt.format([_retries])
	if not animated:
		return
	UIAnim.play_pop_in(lbl_hud_retries, 0.0, 0.88, 0.2)
	lbl_hud_retries.add_theme_color_override("font_color",
		Color(0.78, 0.18, 0.18) if _retries <= 1 else Color(0.18, 0.22, 0.26))


func complete_tutorial() -> void:
	_stop_demo()
	super.complete_tutorial()


func skip_tutorial() -> void:
	_stop_demo()
	super.skip_tutorial()


func skip_all_tutorials() -> void:
	_stop_demo()
	super.skip_all_tutorials()
