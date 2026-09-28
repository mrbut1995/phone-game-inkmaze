class_name HowToPlayMoveTutorial
extends BaseTutorial

## ============================================================================
## HowToPlayMoveTutorial: Dạy kéo đường đi từ S đến F (Planning.md §3.2)
## Bàn mini 1×3: S (0,0) — Giữa (1,0) — F (2,0). Bàn khai trong `.tscn`.
## ============================================================================

## 3 ô theo thứ tự trái → phải (grid_pos 0,0 / 1,0 / 2,0) — bind trong .tscn
@export var cells: Array[TutorialCell] = []
## Nét đường đi (child của BoardHost) — bind trong .tscn
@export var path_line: Line2D = null

var _current_cell: Vector2i = Vector2i(0, 0)
var _is_dragging: bool = false
var _visited_cells: Array[Vector2i] = []

const CELL_SIZE := 96.0
const CELL_GAP := 14.0
const START_POS := Vector2(70, 160)


func _init_tutorial() -> void:
	tutorial_id = "how_to_play_move"
	_reset_path()

	var steps: Array = [
		{
			"message_key": "STR_TUT_MOVE_01",
			"fallback_text": "Đây là điểm BẮT ĐẦU (S). Hãy giữ và kéo sang ô bên cạnh.",
			"advance_mode": "MANUAL",
			"spotlight_rect": Rect2(START_POS - Vector2(6, 6), Vector2(CELL_SIZE + 12, CELL_SIZE + 12)),
			"pointer_drag": {
				"from": START_POS + Vector2(CELL_SIZE * 0.5, CELL_SIZE * 0.5),
				"to": START_POS + Vector2(CELL_SIZE * 1.5 + CELL_GAP, CELL_SIZE * 0.5),
				"duration": 0.6
			}
		},
		{
			"message_key": "STR_TUT_MOVE_01",
			"fallback_text": "Hãy chạm và kéo từ S sang ô ngay bên cạnh.",
			"advance_mode": "AUTO",
			"required_action": "DRAG_TO_MIDDLE",
			"pointer_drag": {
				"from": START_POS + Vector2(CELL_SIZE * 0.5, CELL_SIZE * 0.5),
				"to": START_POS + Vector2(CELL_SIZE * 1.5 + CELL_GAP, CELL_SIZE * 0.5),
				"duration": 0.6
			}
		},
		{
			"message_key": "STR_TUT_MOVE_02",
			"fallback_text": "Giờ kéo tiếp tới F để hoàn thành đường đi.",
			"advance_mode": "AUTO",
			"required_action": "DRAG_TO_FINISH",
			"pointer_drag": {
				"from": START_POS + Vector2(CELL_SIZE * 1.5 + CELL_GAP, CELL_SIZE * 0.5),
				"to": START_POS + Vector2(CELL_SIZE * 2.5 + CELL_GAP * 2, CELL_SIZE * 0.5),
				"duration": 0.6
			}
		},
		{
			"message_key": "STR_TUT_MOVE_03",
			"fallback_text": "Tuyệt vời! Bạn vừa vẽ xong đường đi đầu tiên.",
			"advance_mode": "MANUAL",
		}
	]
	setup_steps(steps)


func _reset_path() -> void:
	_visited_cells = [Vector2i(0, 0)]
	_current_cell = Vector2i(0, 0)
	_refresh_path_line()


func _refresh_path_line() -> void:
	if path_line == null:
		return
	path_line.clear_points()
	for cell_pos in _visited_cells:
		var center := START_POS + Vector2(cell_pos.x * (CELL_SIZE + CELL_GAP) + CELL_SIZE * 0.5, CELL_SIZE * 0.5)
		path_line.add_point(center)


func _on_step_entered(index: int, _data: Dictionary) -> void:
	if index == 0:
		_reset_path()
	elif index == 3:
		_stop_pointer()
		play_cells_win()
		spawn_board_text("✓", _cell_center(2))
		show_success_feedback("STR_TUT_MOVE_03", "Tuyệt vời!")


## Tâm 1 ô theo CHỈ SỐ (toạ độ trong BoardHost)
func _cell_center(idx: int) -> Vector2:
	if idx < 0 or idx >= cells.size():
		return Vector2.ZERO
	return cells[idx].position + cells[idx].size * 0.5


## Ô vừa được đi qua: nhún + tiếng chấm bút
func _mark_cell(idx: int) -> void:
	if idx < 0 or idx >= cells.size():
		return
	cells[idx].play_step()
	Sfx.play(Sfx.CELL_STEP)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_handle_touch_start(mb.global_position)
			else:
				_handle_touch_end()
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _is_dragging:
			_handle_touch_drag(mm.global_position)


## Trả về chỉ số ô theo toạ độ TOÀN CỤC (chuẩn cho mọi scene, BoardHost nằm ở đâu cũng đúng)
func _cell_index_at(global_pos: Vector2) -> int:
	for i in cells.size():
		if cells[i].get_global_rect().has_point(global_pos):
			return i
	return -1


func _handle_touch_start(global_pos: Vector2) -> void:
	var idx := _cell_index_at(global_pos)
	if idx == _current_cell.x:
		_is_dragging = true


func _handle_touch_drag(global_pos: Vector2) -> void:
	var idx := _cell_index_at(global_pos)
	if idx == -1:
		return

	if idx == _current_cell.x + 1:
		# Bước sang ô liền kề bên phải
		if current_step_index == 1 and idx == 1:
			# Kéo sang ô giữa thành công
			_current_cell = Vector2i(1, 0)
			_visited_cells.append(_current_cell)
			_refresh_path_line()
			_mark_cell(idx)
			show_success_feedback()
			show_step(2)
		elif current_step_index == 2 and idx == 2:
			# Kéo sang F thành công
			_current_cell = Vector2i(2, 0)
			_visited_cells.append(_current_cell)
			_refresh_path_line()
			_mark_cell(idx)
			show_step(3)
	elif idx > _current_cell.x + 1:
		# Nhảy cóc ô — nháy đỏ ô vừa chạm
		if idx < cells.size():
			cells[idx].play_fail()
		show_fail_feedback("STR_TUT_MOVE_FAIL_01", "Chỉ đi được sang ô NGAY BÊN CẠNH!")


func _handle_touch_end() -> void:
	_is_dragging = false
