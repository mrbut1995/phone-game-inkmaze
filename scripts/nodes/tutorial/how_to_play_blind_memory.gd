class_name HowToPlayBlindMemoryTutorial
extends BaseTutorial

## ============================================================================
## HowToPlayBlindMemoryTutorial: Chế độ Trí Nhớ Mù (BlindMemory).
## Bàn 2×3, tường hiện lúc đầu → ẩn, người chơi đi từ trí nhớ.
## ============================================================================

@export var board_tutorial: BoardTutorial = null
@export var lbl_hud_walls: Label = null

var _current_cell: Vector2i = Vector2i(0, 0)
var _visited_cells: Array[Vector2i] = []
var _demo_running: bool = false

const START_POS := Vector2i(0, 0)
const FINISH_POS := Vector2i(1, 2)
## Tường ẩn: giữa (0,1)↔(1,1) và (1,0)↔(1,1)
const WALLS := [
	{"is_h": false, "lattice": Vector2i(1, 1), "visible": false},
	{"is_h": true,  "lattice": Vector2i(0, 1), "visible": false},
]


func _init_tutorial() -> void:
	tutorial_id = "how_to_play_blind_memory"
	if board_tutorial != null:
		board_tutorial.setup_tutorial(
			2, 3,
			{
				Vector2i(0, 0): "S",
				Vector2i(1, 0): "0",
				Vector2i(0, 1): "2",
				Vector2i(1, 1): "1",
				Vector2i(0, 2): "0",
				Vector2i(1, 2): "F",
			},
			WALLS,
			true,
			START_POS,
			FINISH_POS
		)
		if not board_tutorial.cell_step_attempted.is_connected(_on_cell_step_attempted):
			board_tutorial.cell_step_attempted.connect(_on_cell_step_attempted)
	_reset_path(false)


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


func _reset_path(walls_visible: bool = false) -> void:
	_visited_cells = [START_POS]
	_current_cell = START_POS
	if board_tutorial != null:
		for w in WALLS:
			board_tutorial.reveal_wall_segment(w["is_h"], w["lattice"], walls_visible)
		board_tutorial.set_path(_visited_cells)
		board_tutorial.set_player_cell(START_POS, false)
	_update_hud(false)


func _on_step_entered(index: int, _data: Dictionary) -> void:
	_demo_running = false
	match index:
		1:
			# Bước 2: hiện tường để ghi nhớ
			_reset_path(true)
		2:
			# Bước 3: demo ẩn tường → cursor đi nhờ trí nhớ
			_start_memory_demo()
		3:
			_reset_path(true)


## Bước 2 visualising: tường hiện sáng lên → rồi ẩn → cursor đi đúng đường
func _start_memory_demo() -> void:
	if board_tutorial == null:
		return
	_demo_running = true
	_run_memory_demo_cycle()


func _run_memory_demo_cycle() -> void:
	if not _demo_running or current_step_index != 2 or not is_inside_tree():
		return
	# Hiện tường cho thấy trước
	_reset_path(true)
	board_tutorial.stop_cursor_animation()
	get_tree().create_timer(1.8).timeout.connect(func() -> void:
		if not _demo_running or current_step_index != 2: return
		# Ẩn tường
		for w in WALLS:
			board_tutorial.reveal_wall_segment(w["is_h"], w["lattice"], false)
	)
	# Cursor đi đúng đường nhờ trí nhớ: S(0,0)→(1,0)→(1,1)→(1,2)F (tránh 2 tường ẩn)
	get_tree().create_timer(2.4).timeout.connect(func() -> void:
		if not _demo_running or current_step_index != 2: return
		var path: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2)]
		board_tutorial.animate_cursor_path(path, 0.52)
	)
	get_tree().create_timer(4.0).timeout.connect(func() -> void:
		if not _demo_running or current_step_index != 2: return
		var finish := board_tutorial.get_cell(FINISH_POS)
		if finish != null:
			finish.play_step()
		spawn_board_text("✓", board_tutorial.get_cell_center(FINISH_POS), Color(0.18, 0.49, 0.2))
	)
	# Chu kỳ reset
	get_tree().create_timer(5.8).timeout.connect(func() -> void:
		if not _demo_running or current_step_index != 2: return
		board_tutorial.stop_cursor_animation()
	)
	get_tree().create_timer(6.5).timeout.connect(_run_memory_demo_cycle)


func _on_cell_step_attempted(next: Vector2i) -> void:
	if current_step_index != 3:
		return
	_try_step_to(next)


func _try_step_to(next: Vector2i) -> void:
	var diff: Vector2i = next - _current_cell
	if absi(diff.x) + absi(diff.y) != 1:
		show_fail_feedback("STR_TUT_MOVE_FAIL_01", "Chỉ đi được sang ô NGAY BÊN CẠNH!")
		return

	# Kiểm tra tường ẩn
	var hit_wall := false
	for w in WALLS:
		var is_h: bool = w["is_h"]
		var lat: Vector2i = w["lattice"]
		if not is_h:
			if (_current_cell == Vector2i(lat.x - 1, lat.y) and next == Vector2i(lat.x, lat.y)) or \
			   (_current_cell == Vector2i(lat.x, lat.y) and next == Vector2i(lat.x - 1, lat.y)):
				hit_wall = true; break
		else:
			if (_current_cell == Vector2i(lat.x, lat.y - 1) and next == Vector2i(lat.x, lat.y)) or \
			   (_current_cell == Vector2i(lat.x, lat.y) and next == Vector2i(lat.x, lat.y - 1)):
				hit_wall = true; break

	if hit_wall:
		board_tutorial.show_wall_hit_at(_current_cell, next)
		show_fail_feedback("STR_TUT_BM_FAIL_01", "Đâm tường! Nhớ lại xem tường nằm đâu.")
		# Hiện lại toàn bộ tường cho ghi nhớ rồi ẩn đi sau ~1.2s
		for w in WALLS:
			board_tutorial.reveal_wall_segment(w["is_h"], w["lattice"], true)
		get_tree().create_timer(1.2).timeout.connect(func() -> void:
			if current_step_index == 3 and is_inside_tree():
				for w in WALLS:
					board_tutorial.reveal_wall_segment(w["is_h"], w["lattice"], false)
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

	if next == FINISH_POS:
		play_cells_win()
		spawn_board_text("✓", board_tutorial.get_cell_center(next))
		show_success_feedback("STR_TUT_BM_05", "Tuyệt! Trí nhớ của bạn thật đáng nể.")
		show_step(4)


func _update_hud(_animated: bool = true) -> void:
	if lbl_hud_walls == null:
		return
	var visible_count := 0
	for w in WALLS:
		visible_count += 1
	lbl_hud_walls.text = str(tr("STR_TUT_BM_HUD")) if str(tr("STR_TUT_BM_HUD")) != "STR_TUT_BM_HUD" \
		else "Tường ẩn: %d vị trí" % visible_count
