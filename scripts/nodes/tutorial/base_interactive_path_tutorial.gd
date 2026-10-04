class_name BaseInteractivePathTutorial
extends BaseTutorial

## ============================================================================
## BaseInteractivePathTutorial: Lớp cơ sở cho các bài Tutorial di chuyển ô (Path-based).
## Áp dụng Template Method Pattern (SOLID - OCP & SRP):
##   - Quản lý trạng thái đường đi (_current_cell, _visited_cells, _start_cell, _goal_cell).
##   - Chuẩn hoá kiểm tra kề nhau (Manhattan distance = 1).
##   - Cung cấp các hook có thể override: _can_step_to(), _on_step_succeeded(), _is_goal_reached(), _on_goal_reached().
##   - Đồng bộ hiển thị bàn cờ (board_tutorial) tự động.
## ============================================================================

@export var board_tutorial: BoardTutorial = null

var _current_cell: Vector2i = Vector2i.ZERO
var _visited_cells: Array[Vector2i] = []
var _start_cell: Vector2i = Vector2i.ZERO
var _goal_cell: Vector2i = Vector2i(-1, -1)


## Kiểm tra 2 ô có kề nhau theo 4 hướng (Manhattan distance = 1)
func is_adjacent(a: Vector2i, b: Vector2i) -> bool:
	var diff := b - a
	return absi(diff.x) + absi(diff.y) == 1


## Đặt lại đường đi về ô xuất phát và cập nhật bàn cờ
func reset_path(start_pos: Vector2i = _start_cell, update_board: bool = true) -> void:
	_start_cell = start_pos
	_current_cell = start_pos
	_visited_cells = [start_pos]
	if update_board and board_tutorial != null:
		board_tutorial.set_path(_visited_cells)
		board_tutorial.set_player_cell(start_pos, false)


## Kiểm tra bước hiện tại có cho phép người chơi tương tác vẽ đường không
func _is_input_allowed_at_step(_index: int) -> bool:
	return true


## Callback từ signal cell_step_attempted của BoardTutorial (được nối trong .tscn)
func _on_cell_step_attempted(next: Vector2i) -> void:
	if not _is_input_allowed_at_step(current_step_index):
		return
	_handle_step_attempt(next)


## Xử lý một lần thử bước sang ô tiếp theo (Template Method)
func _handle_step_attempt(next: Vector2i) -> void:
	if not is_adjacent(_current_cell, next):
		_on_non_adjacent_attempt(next)
		return

	if not _can_step_to(_current_cell, next):
		return

	var is_first_time := not _visited_cells.has(next)
	_current_cell = next
	_visited_cells.append(next)

	if board_tutorial != null:
		board_tutorial.set_path(_visited_cells)
		board_tutorial.set_player_cell(next, true)
		var c := board_tutorial.get_cell(next)
		if c != null:
			c.play_step()

	_on_step_succeeded(next, is_first_time)

	if _is_goal_reached(next):
		_on_goal_reached(next)


## Hook khi người chơi cố đi tắt sang ô không kề cạnh
func _on_non_adjacent_attempt(_next: Vector2i) -> void:
	show_fail_feedback("STR_TUT_MOVE_FAIL_01", "Chỉ đi được sang ô NGAY BÊN CẠNH!")


## Hook kiểm tra luật riêng của chế độ (tường, mìn, chi phí...). Mặc định cho phép.
func _can_step_to(_from_cell: Vector2i, _to_cell: Vector2i) -> bool:
	return true


## Hook xử lý sau khi bước đi hợp lệ được thực hiện (cập nhật điểm, sương mù, màu sắc...)
func _on_step_succeeded(_next: Vector2i, _is_first_time: bool) -> void:
	pass


## Hook kiểm tra đã tới đích và hoàn thành điều kiện chưa
func _is_goal_reached(next: Vector2i) -> bool:
	return _goal_cell != Vector2i(-1, -1) and next == _goal_cell


## Hook xử lý khi người chơi về đích thắng lợi
func _on_goal_reached(next: Vector2i) -> void:
	play_cells_win()
	if board_tutorial != null:
		spawn_board_text("✓", board_tutorial.get_cell_center(next))
