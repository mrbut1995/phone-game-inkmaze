class_name HowToPlayMinesweeperTutorial
extends BaseTutorial

## ============================================================================
## HowToPlayMinesweeperTutorial: Chế độ Mìn (Planning.md §3.5)
## Bàn mini 3×3: Mìn cố định tại (1,0) và (0,2).
## Số trên ô = số mìn trong 8 ô lân cận (khai sẵn trong `.tscn`), S tại (0,0), F tại (2,2).
## ============================================================================

## 9 ô của bàn 3×3 (tra theo `grid_pos`) — bind trong .tscn
@export var cells: Array[TutorialCell] = []
## Nét đường đi (child của BoardHost) — bind trong .tscn
@export var path_line: Line2D = null

## Vị trí mìn của bàn mini (dùng cho luật thua khi đạp mìn)
const MINES: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 2)]

var _current_cell: Vector2i = Vector2i(0, 0)
var _is_dragging: bool = false
var _visited_cells: Array[Vector2i] = []

const CELL_SIZE := 76.0
const CELL_GAP := 8.0
const BOARD_ORIGIN := Vector2(85, 120)


func _init_tutorial() -> void:
	tutorial_id = "how_to_play_minesweeper"

	var steps: Array = [
		{
			"message_key": "STR_TUT_MINE_01",
			"fallback_text": "Ở chế độ này, con số là SỐ MÌN trong 8 ô xung quanh!",
			"advance_mode": "MANUAL",
			"spotlight_rect": Rect2(BOARD_ORIGIN + Vector2(CELL_SIZE + CELL_GAP, 0), Vector2(CELL_SIZE, CELL_SIZE))
		},
		{
			"message_key": "STR_TUT_MINE_02",
			"fallback_text": "Đạp trúng ô có mìn ẩn là THUA NGAY LẬP TỨC.",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_MINE_03",
			"fallback_text": "Giờ hãy dẫn đường từ S tới F — nhớ suy luận từ số để né mìn nhé!",
			"advance_mode": "AUTO",
			"required_action": "DRAG_PATH"
		},
		{
			"message_key": "STR_TUT_MINE_04",
			"fallback_text": "Chuẩn luôn! Bạn né được hết mìn.",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_MINE_05",
			"fallback_text": "Bàn Minesweeper thật luôn có ít nhất 1 đường an toàn — hãy suy luận từ số!",
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
	if index == 2:
		_reset_path()


func _gui_input(event: InputEvent) -> void:
	if current_step_index != 2:
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

	# Kiểm tra đạp mìn
	if MINES.has(next):
		show_fail_feedback("STR_TUT_MINE_FAIL_01", "Đây là ô có mìn rồi! Hãy nhìn lại các số lân cận.")
		var mine_cell := _cell_node(next)
		if mine_cell != null:
			mine_cell.play_fail()
		spawn_board_text("!", _cell_center(next), Color(0.85, 0.33, 0.31))
		return

	_current_cell = next
	_visited_cells.append(next)
	_refresh_path_line()
	_mark_cell(next)

	if next == Vector2i(2, 2):
		_is_dragging = false
		play_cells_win()
		spawn_board_text("✓", _cell_center(next))
		show_success_feedback("STR_TUT_MINE_04", "Chuẩn luôn! Bạn né được hết mìn.")
		show_step(3)


## Ô vừa được đi qua: nhún + tiếng chấm bút
func _mark_cell(coord: Vector2i) -> void:
	var cell := _cell_node(coord)
	if cell != null:
		cell.play_step()
	Sfx.play(Sfx.CELL_STEP)
