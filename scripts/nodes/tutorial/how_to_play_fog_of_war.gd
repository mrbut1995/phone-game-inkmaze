class_name HowToPlayFogOfWarTutorial
extends BaseTutorial

## ============================================================================
## HowToPlayFogOfWarTutorial: Chế độ Sương Mù (FogOfWar).
## Bàn 3×3 có tường vô hình. Sương mù che số — chỉ hé lộ xung quanh ô hiện tại.
## ============================================================================

@export var board_tutorial: BoardTutorial = null
@export var lbl_hud_retries: Label = null

var _current_cell: Vector2i = Vector2i(0, 0)
var _visited_cells: Array[Vector2i] = []
var _retries: int = 3
var _demo_running: bool = false

const START_POS := Vector2i(0, 0)
const FINISH_POS := Vector2i(2, 2)
## Tường vô hình giữa (0,0)↔(1,0) và (1,1)↔(1,2)
const WALLS := [
	{"is_h": false, "lattice": Vector2i(1, 0), "visible": false},
	{"is_h": true,  "lattice": Vector2i(1, 2), "visible": false},
]


func _init_tutorial() -> void:
	tutorial_id = "how_to_play_fog_of_war"
	if board_tutorial != null:
		board_tutorial.setup_tutorial(
			3, 3,
			{
				Vector2i(0, 0): "S",
				Vector2i(1, 0): "?",
				Vector2i(2, 0): "?",
				Vector2i(0, 1): "?",
				Vector2i(1, 1): "?",
				Vector2i(2, 1): "?",
				Vector2i(0, 2): "?",
				Vector2i(1, 2): "?",
				Vector2i(2, 2): "F",
			},
			WALLS,
			true,
			START_POS,
			FINISH_POS
		)
		# Dây `cell_step_attempted → _on_cell_step_attempted` khai trong `.tscn` (cùng scene)
	_reset_path()


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


func _reset_path() -> void:
	_visited_cells = [START_POS]
	_current_cell = START_POS
	_retries = 3
	_update_hud(false)
	if board_tutorial != null:
		board_tutorial.set_path(_visited_cells)
		board_tutorial.set_player_cell(START_POS, false)
	_apply_fog(START_POS)


func _on_step_entered(index: int, _data: Dictionary) -> void:
	_demo_running = false
	match index:
		1:
			_start_reveal_demo()
		2:
			_start_wall_hit_demo()
		3:
			_reset_path()


## Bước 2: cursor di chuyển — hé lộ dần số xung quanh từng ô
func _start_reveal_demo() -> void:
	if board_tutorial == null:
		return
	_demo_running = true
	_run_reveal_demo_cycle()


func _run_reveal_demo_cycle() -> void:
	if not _demo_running or current_step_index != 1 or not is_inside_tree():
		return
	# Reset bàn về sương mù
	_reset_fog_display()
	_apply_fog(START_POS)
	# Cursor đi S → (0,1) → (1,1) — hé lộ số từng bước
	var reveal_path := [Vector2i(0, 1), Vector2i(1, 1)]
	board_tutorial.animate_cursor_drag(Vector2i(0, 0), Vector2i(0, 1), 0.5)
	get_tree().create_timer(0.72).timeout.connect(func() -> void:
		if not _demo_running or current_step_index != 1: return
		_apply_fog(Vector2i(0, 1))
	)
	get_tree().create_timer(1.5).timeout.connect(func() -> void:
		if not _demo_running or current_step_index != 1: return
		board_tutorial.animate_cursor_drag(Vector2i(0, 1), Vector2i(1, 1), 0.5)
	)
	get_tree().create_timer(2.25).timeout.connect(func() -> void:
		if not _demo_running or current_step_index != 1: return
		_apply_fog(Vector2i(1, 1))
	)
	get_tree().create_timer(3.5).timeout.connect(func() -> void:
		if not _demo_running or current_step_index != 1: return
		board_tutorial.stop_cursor_animation()
	)
	get_tree().create_timer(4.2).timeout.connect(_run_reveal_demo_cycle)


## Bước 3: demo đâm tường → bị đẩy về S, mất 1 lượt thử lại
func _start_wall_hit_demo() -> void:
	if board_tutorial == null:
		return
	_demo_running = true
	_reset_fog_display()
	_apply_fog(START_POS)
	_retries = 3
	_update_hud(false)
	_run_wall_hit_demo_cycle()


func _run_wall_hit_demo_cycle() -> void:
	if not _demo_running or current_step_index != 2 or not is_inside_tree():
		return
	_retries = 3
	_update_hud(false)
	_reset_fog_display()
	_apply_fog(START_POS)
	# Cursor thử đi sang (1,0) — có tường vô hình → bị đẩy lại
	board_tutorial.animate_cursor_drag(Vector2i(0, 0), Vector2i(1, 0), 0.5)
	get_tree().create_timer(0.72).timeout.connect(func() -> void:
		if not _demo_running or current_step_index != 2: return
		# Hiện tường va chạm
		board_tutorial.reveal_wall_segment(false, Vector2i(1, 0), true)
		show_fail_feedback("STR_TUT_FOG_FAIL_01", "Đâm tường! Mất 1 lượt thử lại.")
		_retries = 2; _update_hud(true)
	)
	get_tree().create_timer(2.2).timeout.connect(func() -> void:
		if not _demo_running or current_step_index != 2: return
		board_tutorial.stop_cursor_animation()
		board_tutorial.reveal_wall_segment(false, Vector2i(1, 0), false)
	)
	get_tree().create_timer(3.0).timeout.connect(_run_wall_hit_demo_cycle)


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


func _on_cell_step_attempted(next: Vector2i) -> void:
	if current_step_index != 3:
		return
	_try_step_to(next)


func _try_step_to(next: Vector2i) -> void:
	var diff: Vector2i = next - _current_cell
	if absi(diff.x) + absi(diff.y) != 1:
		show_fail_feedback("STR_TUT_MOVE_FAIL_01", "Chỉ đi được sang ô NGAY BÊN CẠNH!")
		return

	# Kiểm tra tường vô hình
	var hit_wall := false
	for w in WALLS:
		var is_h: bool = w["is_h"]
		var lat: Vector2i = w["lattice"]
		if not is_h:
			if (_current_cell == Vector2i(lat.x - 1, lat.y) and next == Vector2i(lat.x, lat.y)) or \
			   (_current_cell == Vector2i(lat.x, lat.y) and next == Vector2i(lat.x - 1, lat.y)):
				hit_wall = true
				break
		else:
			if (_current_cell == Vector2i(lat.x, lat.y - 1) and next == Vector2i(lat.x, lat.y)) or \
			   (_current_cell == Vector2i(lat.x, lat.y) and next == Vector2i(lat.x, lat.y - 1)):
				hit_wall = true
				break

	if hit_wall:
		board_tutorial.show_wall_hit_at(_current_cell, next)
		show_fail_feedback("STR_TUT_FOG_FAIL_01", "Đâm tường vô hình! Thử đường khác.")
		_retries -= 1
		_update_hud(true)
		if _retries <= 0:
			get_tree().create_timer(0.6).timeout.connect(func() -> void:
				if current_step_index == 3 and is_inside_tree():
					_reset_path()
			)
		return

	_current_cell = next
	_visited_cells.append(next)
	if board_tutorial != null:
		board_tutorial.set_path(_visited_cells)
		board_tutorial.set_player_cell(next, true)
		var c := board_tutorial.get_cell(next)
		if c != null:
			c.play_step()
	_apply_fog(next)

	if next == FINISH_POS:
		play_cells_win()
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
