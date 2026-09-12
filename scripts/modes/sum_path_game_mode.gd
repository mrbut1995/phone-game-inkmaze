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

	var size := 4
	match difficulty:
		"easy":
			size = 3
		"hard":
			size = 5
		_:
			size = 4

	var maze := MazeData.new()
	maze.create_empty(size, size)

	var start_pos := maze.get_start()
	var end_pos := maze.get_end()

	for y in size:
		for x in size:
			_cell_scores[Vector2i(x, y)] = randi_range(1, 9)

	var sample_path := _generate_valid_path(size, start_pos, end_pos)
	var path_sum := 0
	for p: Vector2i in sample_path:
		path_sum += _cell_scores.get(p, 1)

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
	current_sum = _cell_scores.get(start_pos, 1)

	return maze


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


func on_player_moved(_grid_view: Control, new_pos: Vector2i, _maze: MazeData) -> void:
	_current_path.append(new_pos)
	var unique_cells := {}
	current_sum = 0
	for p: Vector2i in _current_path:
		if not unique_cells.has(p):
			unique_cells[p] = true
			current_sum += _cell_scores.get(p, 1)


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


func _generate_valid_path(size: int, start_pos: Vector2i, end_pos: Vector2i) -> Array[Vector2i]:
	var current := start_pos
	var path: Array[Vector2i] = [current]
	var visited := { current: true }

	while current != end_pos:
		var neighbors: Array[Vector2i] = []
		for d: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT]:
			var nxt: Vector2i = current + d
			if nxt.x >= 0 and nxt.x < size and nxt.y >= 0 and nxt.y < size and not visited.has(nxt):
				neighbors.append(nxt)

		if neighbors.is_empty():
			var step := Vector2i.ZERO
			if current.x < end_pos.x:
				step = Vector2i.RIGHT
			elif current.y < end_pos.y:
				step = Vector2i.DOWN
			elif current.x > end_pos.x:
				step = Vector2i.LEFT
			else:
				step = Vector2i.UP
			current += step
			path.append(current)
			visited[current] = true
		else:
			neighbors.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
				return (a - end_pos).length_squared() < (b - end_pos).length_squared()
			)
			var next_step: Vector2i = neighbors[0] if randf() < 0.65 else neighbors[randi() % neighbors.size()]
			current = next_step
			path.append(current)
			visited[current] = true

	return path
