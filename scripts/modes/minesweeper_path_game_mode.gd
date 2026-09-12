class_name MinesweeperPathGameMode
extends BaseGameMode
## ============================================================================
## Mode: Minesweeper Maze (Mê cung Dò Mìn).
## - Số trên ô là số mìn nằm trong 8 ô lân cận (0..8).
## - S và F luôn an toàn, bảo đảm luôn có ít nhất 1 đường BFS không mìn.
## - Đạp mìn: Nổ, lật ô, trừ bước, về S.
## ============================================================================

var _mines: Dictionary = {}            # Vector2i -> bool
var _revealed_mines: Dictionary = {}   # Vector2i -> bool
var _neighbor_counts: Dictionary = {}  # Vector2i -> int
var _total_mines := 0


func _init() -> void:
	mode_id = "minesweeper"
	mode_name = "Minesweeper Maze"
	mode_description = "Dò mìn theo số lân cận, tìm đường an toàn từ S đến F."
	is_endless = false
	instant_game_over_on_hazard = false
	initial_steps = 25


func setup_floor(floor_number: int) -> MazeData:
	_mines.clear()
	_revealed_mines.clear()
	_neighbor_counts.clear()

	var size := clampi(2 + floor_number, 3, 5)
	var maze := MazeData.new()
	maze.create_empty(size, size)

	var start_pos := maze.get_start()
	var end_pos := maze.get_end()

	var safe_path := _generate_safe_path(size, start_pos, end_pos)
	var safe_cells := {}
	for p: Vector2i in safe_path:
		safe_cells[p] = true

	var mine_density := minf(0.18 + float(floor_number) * 0.03, 0.32)
	_total_mines = 0
	for y in size:
		for x in size:
			var pos := Vector2i(x, y)
			if safe_cells.has(pos):
				continue
			if randf() < mine_density:
				_mines[pos] = true
				_total_mines += 1

	if _total_mines == 0:
		for y in size:
			for x in size:
				var pos := Vector2i(x, y)
				if not safe_cells.has(pos):
					_mines[pos] = true
					_total_mines += 1
					break

	for y in size:
		for x in size:
			var pos := Vector2i(x, y)
			var count := 0
			for dy in [-1, 0, 1]:
				for dx in [-1, 0, 1]:
					if dx == 0 and dy == 0:
						continue
					var nxt := pos + Vector2i(dx, dy)
					if _mines.get(nxt, false):
						count += 1
			_neighbor_counts[pos] = count

	return maze


func get_cell_text(pos: Vector2i, maze: MazeData) -> String:
	if maze == null:
		return ""
	if pos == maze.get_start():
		return "S"
	if pos == maze.get_end():
		return "F"
	if _revealed_mines.has(pos):
		return "X"
	var count: int = _neighbor_counts.get(pos, 0)
	return "" if count == 0 else str(count)


func evaluate_move(from_pos: Vector2i, to_pos: Vector2i, maze: MazeData) -> Dictionary:
	var base_eval := super.evaluate_move(from_pos, to_pos, maze)
	if not base_eval.get("allowed", false):
		return base_eval

	if _mines.get(to_pos, false):
		_revealed_mines[to_pos] = true
		return {
			"allowed": false,
			"is_hazard": true,
			"hazard_type": "mine",
			"pos": to_pos,
			"from": from_pos,
			"to": to_pos
		}

	return {
		"allowed": true,
		"is_hazard": false,
		"hazard_type": "none"
	}


func is_mine(pos: Vector2i) -> bool:
	return _mines.get(pos, false)


func is_mine_revealed(pos: Vector2i) -> bool:
	return _revealed_mines.get(pos, false)


func get_total_mines() -> int:
	return _total_mines


func get_hud_extra_info() -> String:
	return "MÌN: %d" % _total_mines


func _generate_safe_path(size: int, start_pos: Vector2i, end_pos: Vector2i) -> Array[Vector2i]:
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
			var next_step: Vector2i = neighbors[0] if randf() < 0.7 else neighbors[randi() % neighbors.size()]
			current = next_step
			path.append(current)
			visited[current] = true

	return path
