class_name HowToPlayBlindMemoryTutorial
extends BaseInteractivePathTutorial

## ============================================================================
## HowToPlayBlindMemoryTutorial: Chế độ Trí Nhớ Mù (BlindMemory).
## Bàn 2×3, tường hiện lúc đầu → ẩn, người chơi đi từ trí nhớ.
## Kế thừa BaseInteractivePathTutorial (SOLID - OCP/SRP).
## ============================================================================

@export var lbl_hud_walls: Label = null

var _demo_tween: Tween = null

@export var START_POS := Vector2i(0, 0)
@export var FINISH_POS := Vector2i(1, 2)
## Tường ẩn: giữa (0,1)↔(1,1) và (1,0)↔(1,1)
const WALLS := [
	{"is_h": false, "lattice": Vector2i(1, 1), "visible": false},
	{"is_h": true,  "lattice": Vector2i(0, 1), "visible": false},
]


func _init_tutorial() -> void:
	tutorial_id = "how_to_play_blind_memory"
	_start_cell = START_POS
	_goal_cell = FINISH_POS
	if board_tutorial != null:
		board_tutorial.setup_tutorial(
			2, 3,
			{
				Vector2i(0, 0): "S",
				Vector2i(1, 0): "0",
				Vector2i(0, 1): "2",
				Vector2i(1, 1): "1",
				Vector2i(0, 2): "0",
				FINISH_POS: "F",
			},
			WALLS,
			true,
			START_POS,
			FINISH_POS
		)
	# GIỮ trạng thái nội bộ (không đẩy lên bàn ở bước init) — API mới có thêm `start_pos`
	reset_path(_start_cell, false)


func _get_default_steps() -> Array:
	return [
		{
			"message_key": "STR_TUT_BM_01",
			"fallback_text": "Chế độ Trí Nhớ: bàn GHI NHỚ — tường hiện trước rồi ẩn hẳn!",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_BM_02",
			"fallback_text": "Nhìn thật kỹ các tường đang hiện — bạn cần nhớ vị trí chúng.",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_BM_03",
			"fallback_text": "Sau khi tường ẩn, bạn phải đi đúng đường nhờ trí nhớ vừa ghi.",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_BM_04",
			"fallback_text": "Ghi nhớ tường, rồi đi từ S tới F!",
			"advance_mode": "AUTO",
			"required_action": "DRAG_PATH",
		},
		{
			"message_key": "STR_TUT_BM_05",
			"fallback_text": "Tuyệt! Trí nhớ của bạn thật đáng nể.",
			"advance_mode": "MANUAL",
		},
	]


func reset_path_with_walls(walls_visible: bool = false) -> void:
	if board_tutorial != null:
		for w in WALLS:
			board_tutorial.reveal_wall_segment(w["is_h"], w["lattice"], walls_visible)
	reset_path()
	_update_hud(false)


func reset_path(start_pos: Vector2i = _start_cell, update_board: bool = true) -> void:
	super.reset_path(start_pos, update_board)


func _on_step_entered(index: int, _data: Dictionary) -> void:
	_stop_demo()
	match index:
		1:
			reset_path_with_walls(true)
		2:
			_start_memory_demo()
		3:
			reset_path_with_walls(true)


func _stop_demo() -> void:
	if _demo_tween != null and _demo_tween.is_valid():
		_demo_tween.kill()
		_demo_tween = null
	if board_tutorial != null:
		board_tutorial.stop_cursor_animation()


## Bước 2 visualising: tường hiện sáng lên → rồi ẩn → cursor đi đúng đường bằng Tween
func _start_memory_demo() -> void:
	if board_tutorial == null:
		return
	_run_memory_demo_cycle()


func _run_memory_demo_cycle() -> void:
	if current_step_index != 2 or not is_inside_tree() or board_tutorial == null:
		return
	# Hiện tường cho thấy trước
	reset_path_with_walls(true)
	board_tutorial.stop_cursor_animation()

	_demo_tween = create_tween()
	# Chờ 1.8s rồi ẩn tường
	_demo_tween.tween_interval(1.8)
	_demo_tween.tween_callback(func() -> void:
		if current_step_index != 2 or board_tutorial == null: return
		for w in WALLS:
			board_tutorial.reveal_wall_segment(w["is_h"], w["lattice"], false)
	)
	# Chờ thêm 0.6s rồi chạy cursor
	_demo_tween.tween_interval(0.6)
	_demo_tween.tween_callback(func() -> void:
		if current_step_index != 2 or board_tutorial == null: return
		var path: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), FINISH_POS]
		board_tutorial.animate_cursor_path(path, 0.52)
	)
	# Chờ 1.6s sau khi cursor chạy xong
	_demo_tween.tween_interval(1.6)
	_demo_tween.tween_callback(func() -> void:
		if current_step_index != 2 or board_tutorial == null: return
		var finish := board_tutorial.get_cell(FINISH_POS)
		if finish != null:
			finish.play_step()
		spawn_board_text("✓", board_tutorial.get_cell_center(FINISH_POS), Color(0.18, 0.49, 0.2))
	)
	# Dừng cursor rồi lặp lại
	_demo_tween.tween_interval(1.8)
	_demo_tween.tween_callback(func() -> void:
		if current_step_index != 2 or board_tutorial == null: return
		board_tutorial.stop_cursor_animation()
	)
	_demo_tween.tween_interval(0.7)
	_demo_tween.tween_callback(_run_memory_demo_cycle)


func _is_input_allowed_at_step(step_idx: int) -> bool:
	return step_idx == 3


func _can_step_to(from_cell: Vector2i, to_cell: Vector2i) -> bool:
	# Kiểm tra va vào tường ẩn
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
		show_fail_feedback("STR_TUT_BM_FAIL_01", "Đâm tường! Nhớ lại xem tường nằm đâu.")
		# Hiện lại toàn bộ tường cho ghi nhớ rồi ẩn đi sau ~1.2s
		if board_tutorial != null:
			for w in WALLS:
				board_tutorial.reveal_wall_segment(w["is_h"], w["lattice"], true)
		get_tree().create_timer(1.2).timeout.connect(func() -> void:
			if current_step_index == 3 and is_inside_tree() and board_tutorial != null:
				for w in WALLS:
					board_tutorial.reveal_wall_segment(w["is_h"], w["lattice"], false)
		)
		return false

	return true


func _on_goal_reached(next: Vector2i) -> void:
	play_cells_win()
	if board_tutorial != null:
		spawn_board_text("✓", board_tutorial.get_cell_center(next))
	show_success_feedback("STR_TUT_BM_05", "Tuyệt! Trí nhớ của bạn thật đáng nể.")
	show_step(4)


func _update_hud(animated: bool = true) -> void:
	if lbl_hud_walls == null:
		return
	var fmt := str(tr("STR_TUT_BM_HUD"))
	if fmt == "STR_TUT_BM_HUD":
		fmt = "Tường ẩn: {0} vị trí"
	lbl_hud_walls.text = fmt.format([WALLS.size()])
	if not animated:
		return
	UIAnim.play_pop_in(lbl_hud_walls, 0.0, 0.88, 0.2)


func complete_tutorial() -> void:
	_stop_demo()
	super.complete_tutorial()


func skip_tutorial() -> void:
	_stop_demo()
	super.skip_tutorial()


func skip_all_tutorials() -> void:
	_stop_demo()
	super.skip_all_tutorials()
