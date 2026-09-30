class_name HowToPlaySumPathTutorial
extends BaseTutorial

## ============================================================================
## HowToPlaySumPathTutorial: Chế độ Tính Tổng (Planning.md §3.7)
## Dùng BoardTutorial: bàn 3×3, mỗi ô có điểm 1..4, mini HUD hiện Tổng / Mục tiêu (= 8).
## ============================================================================

@export var board_tutorial: BoardTutorial = null
@export var lbl_hud_sum: Label = null

var _current_cell: Vector2i = Vector2i(0, 0)
var _visited_cells: Array[Vector2i] = []
var _current_sum: int = 2
var _displayed_sum: int = 2
var _sum_demo_running: bool = false

const CELL_VALUES: Dictionary = {
	Vector2i(0, 0): 2, Vector2i(1, 0): 1, Vector2i(2, 0): 3,
	Vector2i(0, 1): 4, Vector2i(1, 1): 2, Vector2i(2, 1): 1,
	Vector2i(0, 2): 1, Vector2i(1, 2): 3, Vector2i(2, 2): 2,
}
const START_POS := Vector2i(0, 0)
const FINISH_POS := Vector2i(2, 2)
const TARGET_SUM := 8


func _init_tutorial() -> void:
	tutorial_id = "how_to_play_sum_path"
	if board_tutorial != null:
		board_tutorial.setup_tutorial(
			3, 3,
			{
				Vector2i(0, 0): "S",
				Vector2i(1, 0): "1",
				Vector2i(2, 0): "3",
				Vector2i(0, 1): "4",
				Vector2i(1, 1): "2",
				Vector2i(2, 1): "1",
				Vector2i(0, 2): "1",
				Vector2i(1, 2): "3",
				Vector2i(2, 2): "F"
			},
			[],
			true,
			START_POS,
			FINISH_POS
		)
		# Dây `cell_step_attempted → _on_cell_step_attempted` khai trong `.tscn` (cùng scene)
	_reset_path()

	var hud_panel := get_node_or_null("BoardHost/HudPanel") as Control


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


func _reset_path() -> void:
	_visited_cells = [START_POS]
	_current_cell = START_POS
	_current_sum = int(CELL_VALUES[START_POS])
	_displayed_sum = _current_sum
	_update_hud(false)
	if board_tutorial != null:
		board_tutorial.show_no_moves_overlay(false)
		board_tutorial.set_path(_visited_cells)
		board_tutorial.set_player_cell(START_POS, false)


func _on_step_entered(index: int, _data: Dictionary) -> void:
	_sum_demo_running = false
	match index:
		2:
			_show_sum_path_demo()
		3:
			_reset_path()


## Demo step 2: cursor đi theo đường S→(1,0)→(1,1)→(2,1)→F có tổng = 8, lặp
func _show_sum_path_demo() -> void:
	if board_tutorial == null:
		return
	_sum_demo_running = true
	var demo_path: Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 2),
	]
	board_tutorial.set_path(demo_path)
	board_tutorial.animate_cursor_path(demo_path, 0.42)
	_run_sum_hud_cycle()


func _run_sum_hud_cycle() -> void:
	if not _sum_demo_running or current_step_index != 2 or not is_inside_tree():
		return
	# Reset HUD đầu chu kỳ
	_displayed_sum = 2
	_update_hud(false)
	# S(2)→(1,0)+1 ≈ 0.83s
	get_tree().create_timer(0.83).timeout.connect(func() -> void:
		if not _sum_demo_running or current_step_index != 2: return
		_displayed_sum = 3; _update_hud(true)
		spawn_board_text("+1", board_tutorial.get_cell_center(Vector2i(1, 0)))
	)
	# (1,0)→(1,1)+2 ≈ 1.52s
	get_tree().create_timer(1.52).timeout.connect(func() -> void:
		if not _sum_demo_running or current_step_index != 2: return
		_displayed_sum = 5; _update_hud(true)
		spawn_board_text("+2", board_tutorial.get_cell_center(Vector2i(1, 1)))
	)
	# (1,1)→(2,1)+1 ≈ 2.21s
	get_tree().create_timer(2.21).timeout.connect(func() -> void:
		if not _sum_demo_running or current_step_index != 2: return
		_displayed_sum = 6; _update_hud(true)
		spawn_board_text("+1", board_tutorial.get_cell_center(Vector2i(2, 1)))
	)
	# (2,1)→F(2,2)+2 = 8 ≈ 2.90s
	get_tree().create_timer(2.90).timeout.connect(func() -> void:
		if not _sum_demo_running or current_step_index != 2: return
		_displayed_sum = 8; _update_hud(true)
		spawn_board_text("+2", board_tutorial.get_cell_center(Vector2i(2, 2)))
		var finish := board_tutorial.get_cell(FINISH_POS)
		if finish != null:
			finish.play_step()
	)
	# Lặp lại sau ~4s để đồng bộ với chu kỳ cursor
	get_tree().create_timer(4.0).timeout.connect(_run_sum_hud_cycle)


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


func _on_cell_step_attempted(next: Vector2i) -> void:
	if current_step_index != 3:
		return
	_try_step_to(next)


func _try_step_to(next: Vector2i) -> void:
	var diff: Vector2i = next - _current_cell
	if absi(diff.x) + absi(diff.y) != 1:
		show_fail_feedback("STR_TUT_MOVE_FAIL_01", "Chỉ đi được sang ô NGAY BÊN CẠNH!")
		return

	_current_cell = next
	var is_first_time := not _visited_cells.has(next)
	_visited_cells.append(next)
	if board_tutorial != null:
		board_tutorial.set_path(_visited_cells)
		board_tutorial.set_player_cell(next, true)
		var c := board_tutorial.get_cell(next)
		if c != null:
			c.play_step()

	if is_first_time and CELL_VALUES.has(next):
		var gain := int(CELL_VALUES[next])
		_current_sum += gain
		_displayed_sum = _current_sum
		_update_hud(true)
		if board_tutorial != null:
			spawn_board_text("+%d" % gain, board_tutorial.get_cell_center(next))

	# Kiểm tra điều kiện khi tới F
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
					_reset_path()
			)
		return

	# Tổng đã vượt TARGET_SUM với điều kiện "=" → không còn đường nào dẫn tới F hợp lệ
	if _current_sum > TARGET_SUM:
		_show_board_no_moves()


## Hiện overlay "Hết nước đi" trên bàn mini — BoardTutorial kế thừa board.gd nên có API này.
func _show_board_no_moves() -> void:
	if board_tutorial == null:
		return
	if not board_tutorial.is_connected("no_moves_retry_pressed", _on_board_retry):
		board_tutorial.connect("no_moves_retry_pressed", _on_board_retry)
	board_tutorial.show_no_moves_overlay(true)


func _on_board_retry() -> void:
	if board_tutorial != null:
		board_tutorial.show_no_moves_overlay(false)
	_reset_path()

