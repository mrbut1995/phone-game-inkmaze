class_name HowToPlayCheckingWallTutorial
extends BaseTutorial

## ============================================================================
## HowToPlayCheckingWallTutorial: Đọc số & suy luận tường vô hình (Planning.md §3.3)
## Bàn mini 2×2: (0,0) [S, số 2] | (1,0)
##                (0,1)          | (1,1) [F]
## Tường chặn giữa (0,0) và (1,0). Đường đi đúng: (0,0) -> (0,1) -> (1,1).
## Bàn cờ + đoạn tường khai trong `.tscn`.
## ============================================================================

## 4 ô của bàn 2×2 (tra theo `grid_pos`) — bind trong .tscn
@export var cells: Array[TutorialCell] = []
## Đoạn tường giữa (0,0) và (1,0) — bind trong .tscn
@export var wall_top: Control = null
## Nét đường đi (child của BoardHost) — bind trong .tscn
@export var path_line: Line2D = null

var _current_cell: Vector2i = Vector2i(0, 0)
var _is_dragging: bool = false
var _visited_cells: Array[Vector2i] = []

const CELL_SIZE := 92.0
const CELL_GAP := 10.0
const BOARD_ORIGIN := Vector2(120, 130)


func _init_tutorial() -> void:
	tutorial_id = "how_to_play_checking_wall"

	var steps: Array = [
		{
			"message_key": "STR_TUT_WALL_01",
			"fallback_text": "Con số trên mỗi ô cho biết có BAO NHIÊU cạnh quanh ô đó là tường vô hình.",
			"advance_mode": "MANUAL",
			"spotlight_rect": Rect2(BOARD_ORIGIN - Vector2(4, 4), Vector2(CELL_SIZE + 8, CELL_SIZE + 8))
		},
		{
			"message_key": "STR_TUT_WALL_02",
			"fallback_text": "Tường vô hình sẽ CHẶN đường đi — kéo ngang qua đó, đường sẽ không vẽ được.",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_WALL_03",
			"fallback_text": "Giờ bạn hãy tự đi từ S tới F — nhớ dùng con số để đoán tường nhé!",
			"advance_mode": "AUTO",
			"required_action": "DRAG_PATH"
		},
		{
			"message_key": "STR_TUT_WALL_04",
			"fallback_text": "Chính xác! Bạn đã dùng con số để đoán đúng tường.",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_WALL_05",
			"fallback_text": "Lưu ý: không phải chế độ nào cũng dùng số kiểu này. Cùng khám phá tiếp nhé!",
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


func _on_step_entered(index: int, _data: Dictionary) -> void:
	if index == 0:
		_reset_path()
		_set_wall_visible(false)
	elif index == 1:
		# Hoạt cảnh tường hiện ra để giải thích
		_reveal_wall()
	elif index == 2:
		# Bắt đầu cho người chơi tự đi
		_reset_path()
		_set_wall_visible(false)


## Tường hiện ra: nở nhẹ + mờ dần hiện + tiếng vẽ tường
func _reveal_wall() -> void:
	_set_wall_visible(true)
	if wall_top == null:
		return
	Sfx.play(Sfx.WALL_MARK)
	wall_top.pivot_offset = wall_top.size * 0.5
	wall_top.scale = Vector2(0.6, 0.2)
	wall_top.modulate.a = 0.0
	var tw := wall_top.create_tween()
	tw.set_parallel(true)
	tw.tween_property(wall_top, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(wall_top, "modulate:a", 1.0, 0.24)


## Ô vừa được đi qua: nhún + tiếng chấm bút
func _mark_cell(coord: Vector2i) -> void:
	var cell := _cell_node(coord)
	if cell != null:
		cell.play_step()
	Sfx.play(Sfx.CELL_STEP)


func _cell_node(coord: Vector2i) -> TutorialCell:
	for c in cells:
		if c.grid_pos == coord:
			return c
	return null


func _set_wall_visible(on: bool) -> void:
	if wall_top != null:
		wall_top.visible = on


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

	# Kiểm tra đâm vào tường giữa (0,0) và (1,0)
	if (_current_cell == Vector2i(0, 0) and next == Vector2i(1, 0)) or \
		(_current_cell == Vector2i(1, 0) and next == Vector2i(0, 0)):
		_set_wall_visible(true)
		wall_top.modulate.a = 1.0
		wall_top.scale = Vector2.ONE
		show_fail_feedback("STR_TUT_WALL_FAIL_01", "Ối, đó là tường rồi! Thử hướng khác xem.")
		shake_node(wall_top, 0.25, 6.0)
		flash_fail(wall_top)
		return

	_current_cell = next
	_visited_cells.append(next)
	_refresh_path_line()
	_mark_cell(next)

	if next == Vector2i(1, 1):
		# Đến F thành công!
		_is_dragging = false
		play_cells_win()
		spawn_board_text("✓", _cell_center(next))
		show_success_feedback("STR_TUT_WALL_04", "Chính xác!")
		show_step(3)
