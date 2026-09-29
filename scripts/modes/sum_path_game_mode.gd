class_name SumPathGameMode
extends BaseGameMode
## ============================================================================
## Mode: Sum Path (Đường đi đạt Điều Kiện Tổng Điểm: <, >, =).
## - Không có tường ngăn cách.
## - Số trên ô là điểm số (1..9), S và F hiển thị "S" và "F".
## - Thắng khi tới F với tổng điểm thỏa: SUM < / > / = Target.
## - Mỗi ô trên đường đi chỉ tính điểm 1 lần.
## ============================================================================

var target_val: int = 0
var operator: String = "="          # "<", ">", "="
var current_sum: int = 0
var _cell_scores: Dictionary = {}   # Vector2i -> int
var _current_path: Array[Vector2i] = []
var _start_pos := Vector2i.ZERO
var _end_pos := Vector2i.ZERO


func _init(p_difficulty := "medium", p_operator := "") -> void:
	mode_id = "sum_path"
	mode_name = "Sum Path"
	mode_description = "Không có tường: Tìm đường đi từ S đến F có tổng điểm thỏa mãn điều kiện."
	is_endless = false
	instant_game_over_on_hazard = false
	difficulty = p_difficulty
	operator = p_operator
	initial_steps = 30


func setup_floor(_floor_number: int) -> MazeData:
	_cell_scores.clear()
	_current_path.clear()
	current_sum = 0

	# MÀN DO NHÀ THIẾT KẾ VẼ: dùng ĐÚNG bàn của màn (tường + hình dạng board) rồi mới gán điểm ô.
	var maze := designed_maze()
	if maze != null:
		return _setup_on_maze(maze)

	var size := 4
	match difficulty:
		"easy":
			size = 3
		"hard":
			size = 5
		_:
			size = 4

	maze = MazeData.new()
	maze.create_empty(size, size)
	return _setup_on_maze(maze)


## Gán điểm cho từng ô của `maze` rồi chọn điều kiện tổng (</>/=) theo TỔNG của đường S→F.
## - Bàn tự sinh (Daily): đường mẫu là 1 đường đi hợp lệ ngẫu nhiên như trước.
## - Bàn thiết kế: đường mẫu = đường NGẮN NHẤT S→F của màn (tôn trọng tường của nhà thiết kế).
func _setup_on_maze(maze: MazeData) -> MazeData:
	var start_pos := maze.get_start()
	var end_pos := maze.get_end()
	_start_pos = start_pos
	_end_pos = end_pos

	# Ô nào nhà thiết kế khai điểm riêng (custom_cell_values["x,y"]) thì dùng, còn lại random 1..9.
	# S/F KHÔNG có điểm (trên ô chỉ hiện chữ S/F) — nhờ vậy tổng đường đi khớp ĐÚNG số nhà thiết kế muốn.
	for y in maze.height:
		for x in maze.width:
			var pos := Vector2i(x, y)
			if pos == start_pos or pos == end_pos:
				continue
			if not maze.is_cell_active(pos):
				continue
			_cell_scores[pos] = _designed_score(pos)

	var sample_path := maze.get_shortest_path(start_pos, end_pos)
	var path_sum := 0
	for p: Vector2i in sample_path:
		path_sum += _cell_score(p)

	if operator.is_empty() or not (operator in ["<", ">", "="]):
		var ops := ["=", "<", ">"]
		operator = ops[randi() % ops.size()]

	match operator:
		"=":
			target_val = path_sum
		"<":
			target_val = path_sum + randi_range(3, 8)
		">":
			target_val = maxi(1, path_sum - randi_range(2, 6))

	_current_path = [start_pos]
	current_sum = 0
	initial_steps = designed_steps(initial_steps)
	return maze


## Điểm của 1 ô KHI TÍNH TỔNG: S/F = 0 (không có số trên ô) — khớp với cách tool tô giá trị.
func _cell_score(pos: Vector2i) -> int:
	if pos == _start_pos or pos == _end_pos:
		return 0
	return int(_cell_scores.get(pos, 1))


## Điểm của 1 ô: ưu tiên giá trị nhà thiết kế đặt trong `custom_cell_values` (khóa "x,y"), không có thì 1..9
func _designed_score(pos: Vector2i) -> int:
	var lvl := designed_level()
	if lvl != null and not lvl.custom_cell_values.is_empty():
		var key := "%d,%d" % [pos.x, pos.y]
		if lvl.custom_cell_values.has(key):
			return clampi(int(lvl.custom_cell_values[key]), 1, 9)
	return randi_range(1, 9)


func get_cell_text(pos: Vector2i, maze: MazeData) -> String:
	if maze == null:
		return ""
	if pos == maze.get_start():
		return "S"
	if pos == maze.get_end():
		return "F"
	return str(_cell_scores.get(pos, 1))


func evaluate_move(from_pos: Vector2i, to_pos: Vector2i, maze: MazeData) -> Dictionary:
	var base_eval := super.evaluate_move(from_pos, to_pos, maze)
	if not base_eval.get("allowed", false):
		return base_eval

	return {
		"allowed": true,
		"is_hazard": false,
		"hazard_type": "none"
	}


func on_player_moved(grid_view: Control, new_pos: Vector2i, maze: MazeData) -> void:
	var was_visited := _current_path.has(new_pos)
	_current_path.append(new_pos)
	_recompute_sum()

	# Hiệu ứng chữ nổi bay lên khi thu thập số ô mới
	if not was_visited and grid_view != null and grid_view.has_method("spawn_floating_popup"):
		if maze != null and new_pos != maze.get_start() and new_pos != maze.get_end():
			var val: int = _cell_scores.get(new_pos, 1)
			grid_view.call("spawn_floating_popup", "+%d" % val, new_pos, Color(0.133, 0.45, 0.65, 1.0))


## Tổng hiện tại = tổng điểm các ô ĐÃ ĐI QUA (mỗi ô tính 1 lần) — tính lại từ `_current_path`
## nên Undo tự trừ điểm về đúng trạng thái trước đó.
func _recompute_sum() -> void:
	var unique_cells := {}
	current_sum = 0
	for p: Vector2i in _current_path:
		if not unique_cells.has(p):
			unique_cells[p] = true
			current_sum += _cell_score(p)


## Undo lùi bước (GridController gọi): bỏ ô vừa đi khỏi đường đi rồi tính lại tổng.
func on_move_undone(_grid_view: Control, _from_pos: Vector2i, _to_pos: Vector2i, _maze: MazeData) -> void:
	if _current_path.size() > 1:
		_current_path.pop_back()
	_recompute_sum()


## KHÔNG THỂ THẮNG NỮA: tổng hiện tại đã VƯỢT mục tiêu trong khi điều kiện cần là "<" hoặc "="
## (mỗi bước đi chỉ CỘNG thêm điểm nên không bao giờ giảm về được) — GameController dùng cờ này
## để hiện nút CHƠI LẠI dưới thanh nút (xem scripts/core/controllers/game_controller.gd).
func is_unwinnable() -> bool:
	return (operator == "<" or operator == "=") and current_sum > target_val


func is_stuck(_pos: Vector2i, _maze: MazeData, _steps: int) -> bool:
	return is_unwinnable()


func check_completion(current_pos: Vector2i, maze: MazeData, _anchor_controller: Node) -> bool:
	if maze == null:
		return false
	if current_pos != maze.get_end():
		return false

	match operator:
		"<":
			return current_sum < target_val
		">":
			return current_sum > target_val
		_:
			return current_sum == target_val


func get_hud_extra_info() -> String:
	return "TỔNG: %d %s %d" % [current_sum, operator, target_val]


## Chuỗi mục tiêu hiển thị trên HUD (VD "= 24", "> 18").
func get_target_text() -> String:
	return "%s %d" % [operator, target_val]
