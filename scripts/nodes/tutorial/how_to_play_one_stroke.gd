class_name HowToPlayOneStrokeTutorial
extends BaseTutorial

## ============================================================================
## HowToPlayOneStrokeTutorial: Chế độ Một Nét (Planning.md §3.6)
## Bàn mini 3×3, không hiện số. Đi qua TẤT CẢ 9 ô, mỗi ô ĐÚNG 1 lần, kết thúc ở F (2,0).
## Ô "đã đi qua" tô nền bằng `TutorialCell.set_visited()` (StyleBox khai trong `.tscn`).
## ============================================================================

## 9 ô của bàn 3×3 (tra theo `grid_pos`) — bind trong .tscn
@export var cells: Array[TutorialCell] = []
## Nét đường đi (child của BoardHost) — bind trong .tscn
@export var path_line: Line2D = null

var _current_cell: Vector2i = Vector2i(0, 0)
var _is_dragging: bool = false
var _visited_cells: Array[Vector2i] = []

const CELL_SIZE := 76.0
const CELL_GAP := 8.0
const BOARD_ORIGIN := Vector2(85, 120)
const TOTAL_CELLS := 9
const FINISH_POS := Vector2i(2, 0)


func _init_tutorial() -> void:
	tutorial_id = "how_to_play_one_stroke"

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
	_update_cell_colors()
	_refresh_path_line()


## Ô nào đã đi qua thì đổi nền (StyleBox `style_visited` khai trong scene của ô)
func _update_cell_colors() -> void:
	for c in cells:
		c.set_visited(_visited_cells.has(c.grid_pos))


func _refresh_path_line() -> void:
	if path_line == null:
		return
	path_line.clear_points()
	for cell_pos in _visited_cells:
		path_line.add_point(_cell_center(cell_pos))


func _cell_center(coord: Vector2i) -> Vector2:
	for c in cells:
		if c.grid_pos == coord:
			return c.position + c.size * 0.5
	return Vector2.ZERO


func _cell_node(coord: Vector2i) -> TutorialCell:
	for c in cells:
		if c.grid_pos == coord:
			return c
	return null


func _on_step_entered(index: int, _data: Dictionary) -> void:
	if index == 3:
		_reset_board_state()


func _gui_input(event: InputEvent) -> void:
	if current_step_index != 3:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if _cell_at(mb.global_position) == _current_cell:
					_is_dragging = true
			else:
				_is_dragging = false
	elif event is InputEventMouseMotion and _is_dragging:
		var mm := event as InputEventMouseMotion
		var next := _cell_at(mm.global_position)
		if next != Vector2i(-1, -1) and next != _current_cell:
			_try_step_to(next)


## Tra ô theo toạ độ TOÀN CỤC (BoardHost nằm ở đâu cũng đúng)
func _cell_at(global_pos: Vector2) -> Vector2i:
	for c in cells:
		if c.get_global_rect().has_point(global_pos):
			return c.grid_pos
	return Vector2i(-1, -1)


func _try_step_to(next: Vector2i) -> void:
	var diff: Vector2i = next - _current_cell
	if absi(diff.x) + absi(diff.y) != 1:
		show_fail_feedback("STR_TUT_MOVE_FAIL_01", "Chỉ đi được sang ô NGAY BÊN CẠNH!")
		return

	# Không được đi đè lên ô đã đi
	if _visited_cells.has(next):
		show_fail_feedback("STR_TUT_ONE_FAIL_01", "Ô này đi qua rồi! Chọn ô khác thử xem.")
		var visited_cell := _cell_node(next)
		if visited_cell != null:
			visited_cell.play_fail()
		return

	# Chạm F nhưng chưa đi hết mọi ô
	if next == FINISH_POS and _visited_cells.size() < TOTAL_CELLS - 1:
		show_fail_feedback("STR_TUT_ONE_FAIL_02", "Còn ô chưa đi kìa — F chỉ mở khi bạn đã đi hết cả bàn!")
		var finish_cell := _cell_node(next)
		if finish_cell != null:
			finish_cell.play_fail()
		spawn_board_text("…", _cell_center(next), Color(0.2, 0.333333, 0.466667))
		return

	_current_cell = next
	_visited_cells.append(next)
	_update_cell_colors()
	_refresh_path_line()
	_mark_cell(next)

	if next == FINISH_POS and _visited_cells.size() == TOTAL_CELLS:
		_is_dragging = false
		play_cells_win()
		show_success_feedback("STR_TUT_ONE_05", "Tuyệt vời! Bạn vừa hoàn thành một nét.")
		show_step(4)


## Ô vừa được đi qua: nhún + tiếng chấm bút
func _mark_cell(coord: Vector2i) -> void:
	var cell := _cell_node(coord)
	if cell != null:
		cell.play_step()
	Sfx.play(Sfx.CELL_STEP)
