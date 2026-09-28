class_name HowToPlayOneStrokeTutorial
extends BaseTutorial

## ============================================================================
## HowToPlayOneStrokeTutorial: Chế độ Một Nét (Planning.md §3.6)
## Bàn mini 3×3, không hiện số. Đi qua TẤT CẢ 9 ô, mỗi ô ĐÚNG 1 lần, kết thúc ở F (2,0).
## ============================================================================

@export var board_tutorial: BoardTutorial = null

var _current_cell: Vector2i = Vector2i(0, 0)
var _visited_cells: Array[Vector2i] = []

const TOTAL_CELLS := 9
const FINISH_POS := Vector2i(2, 0)


func _init_tutorial() -> void:
	tutorial_id = "how_to_play_one_stroke"
	if board_tutorial != null:
		var cells_map: Dictionary = {}
		for y in 3:
			for x in 3:
				cells_map[Vector2i(x, y)] = ""
		cells_map[Vector2i(0, 0)] = "S"
		cells_map[FINISH_POS] = "F"
		board_tutorial.setup_tutorial(
			3, 3,
			cells_map,
			[],
			true,
			Vector2i(0, 0),
			FINISH_POS
		)
		if not board_tutorial.cell_step_attempted.is_connected(_on_cell_step_attempted):
			board_tutorial.cell_step_attempted.connect(_on_cell_step_attempted)
	_reset_board_state()

	var steps: Array = [
		{
			"message_key": "STR_TUT_ONE_01",
			"fallback_text": "Chế độ này KHÔNG có số — tường đã hiện rõ sẵn trên bàn.",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_ONE_02",
			"fallback_text": "Luật đặc biệt: bạn phải đi qua TẤT CẢ các ô, mỗi ô ĐÚNG 1 LẦN, rồi mới được dừng ở F.",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_ONE_03",
			"fallback_text": "Đi đè lên ô đã đi qua là THUA NGAY, nên đi tới đâu chắc tới đó nhé.",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_ONE_04",
			"fallback_text": "Giờ đến lượt bạn — đi hết cả 9 ô rồi kết thúc ở F nhé!",
			"advance_mode": "AUTO",
			"required_action": "DRAG_PATH"
		},
		{
			"message_key": "STR_TUT_ONE_05",
			"fallback_text": "Bạn vừa hoàn thành một nét đầu tiên rồi đó!",
			"advance_mode": "MANUAL",
		}
	]
	setup_steps(steps)


func _reset_board_state() -> void:
	_visited_cells = [Vector2i(0, 0)]
	_current_cell = Vector2i(0, 0)
	if board_tutorial != null:
		board_tutorial.set_path(_visited_cells)
		board_tutorial.set_player_cell(Vector2i(0, 0), false)
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
	if index == 3:
		_reset_board_state()


func _on_cell_step_attempted(next: Vector2i) -> void:
	if current_step_index != 3:
		return
	_try_step_to(next)


func _try_step_to(next: Vector2i) -> void:
	var diff: Vector2i = next - _current_cell
	if absi(diff.x) + absi(diff.y) != 1:
		show_fail_feedback("STR_TUT_MOVE_FAIL_01", "Chỉ đi được sang ô NGAY BÊN CẠNH!")
		return

	# Không được đi đè lên ô đã đi
	if _visited_cells.has(next):
		show_fail_feedback("STR_TUT_ONE_FAIL_01", "Ô này đi qua rồi! Chọn ô khác thử xem.")
		if board_tutorial != null:
			var visited_cell := board_tutorial.get_cell(next)
			if visited_cell != null:
				visited_cell.play_fail()
		return

	# Chạm F nhưng chưa đi hết mọi ô
	if next == FINISH_POS and _visited_cells.size() < TOTAL_CELLS - 1:
		show_fail_feedback("STR_TUT_ONE_FAIL_02", "Còn ô chưa đi kìa — F chỉ mở khi bạn đã đi hết cả bàn!")
		if board_tutorial != null:
			var finish_cell := board_tutorial.get_cell(next)
			if finish_cell != null:
				finish_cell.play_fail()
			spawn_board_text("…", board_tutorial.get_cell_center(next), Color(0.2, 0.33, 0.47))
		return

	_current_cell = next
	_visited_cells.append(next)
	if board_tutorial != null:
		board_tutorial.set_path(_visited_cells)
		board_tutorial.set_player_cell(next, true)
		var c := board_tutorial.get_cell(next)
		if c != null:
			c.play_step()
	_update_cell_colors()

	if next == FINISH_POS and _visited_cells.size() == TOTAL_CELLS:
		play_cells_win()
		show_success_feedback("STR_TUT_ONE_05", "Tuyệt vời! Bạn vừa hoàn thành một nét.")
		show_step(4)
