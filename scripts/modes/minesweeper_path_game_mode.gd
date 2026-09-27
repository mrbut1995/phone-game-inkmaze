class_name MinesweeperPathGameMode
extends BaseGameMode
## ============================================================================
## Mode: Minesweeper Maze (Mê cung Dò Mìn).
## - Số trên ô là số mìn nằm trong 8 ô lân cận (0..8).
## - S và F luôn an toàn, bảo đảm luôn có ít nhất 1 đường BFS không mìn.
## - Đạp mìn: NỔ = THUA NGAY (không quay về S, không chơi tiếp) — ô vừa nổ giữ nguyên
##   con số và hiện thêm biểu tượng Bomb (xem nodes/game/cell.tscn).
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
	## Đạp mìn = thua ngay (giống Play Mode đâm tường): grid_controller giữ nguyên vị trí,
	## GameController._on_step_consumed() gọi _game_over() -> mở popup thua.
	instant_game_over_on_hazard = true
	## Đạp mìn KHÔNG bị đưa về S — nổ tại chỗ (dù đã thua-ngay, cờ này giữ hành vi rõ ràng).
	respawn_on_hazard = false
	initial_steps = 25


func setup_floor(floor_number: int) -> MazeData:
	_mines.clear()
	_revealed_mines.clear()
	_neighbor_counts.clear()

	# MÀN DO NHÀ THIẾT KẾ VẼ (màn Chọn màn chạy chế độ này): dùng ĐÚNG bàn của màn rồi rải mìn lên đó.
	var designed := designed_maze()
	if designed != null:
		return _setup_designed(designed, floor_number)

	var size := clampi(2 + floor_number, 3, 5)
	var maze := MazeData.new()
	maze.create_empty(size, size)

	var safe_path := _generate_safe_path(size, maze.get_start(), maze.get_end())
	_scatter_mines(maze, safe_path, minf(0.18 + float(floor_number) * 0.03, 0.32))
	return maze


## Bàn thiết kế: tường của màn là "bản đồ" (cho HIỆN RÕ để chọn đường), mìn là phần ẩn.
## Mìn của nhà thiết kế TÔ trong tool (mìn GHIM) luôn được giữ; phần còn lại rải trên ô ĐI TỚI ĐƯỢC
## từ S và KHÔNG thuộc đường S→F (tránh cả mìn ghim) ⇒ màn luôn có đường an toàn.
func _setup_designed(maze: MazeData, floor_number: int) -> MazeData:
	maze.set_all_walls_visible(true)
	var reachable := _reachable_cells(maze)
	var pinned := _pinned_mines(maze, reachable)
	var safe_path := _safe_path_avoiding(maze, pinned)
	if safe_path.is_empty() and not pinned.is_empty():
		push_warning("Minesweeper: mìn ghim chặn hết đường S→F — tạm bỏ mìn ghim để màn vẫn thắng được")
		pinned.clear()
		safe_path = maze.get_shortest_path(maze.get_start(), maze.get_end())
	var density := minf(0.16 + float(maxi(floor_number, 1)) * 0.02, 0.30)
	_scatter_mines(maze, safe_path, density, true, pinned)
	initial_steps = designed_steps(initial_steps)
	return maze


## MÌN GHIM của màn: ô nhà thiết kế tô trong tool (`custom_cell_values` khoá "x,y" > 0),
## chỉ nhận ô THUỘC board + ĐI TỚI ĐƯỢC từ S và không phải S/F (2 ô này luôn an toàn).
func _pinned_mines(maze: MazeData, reachable: Dictionary) -> Dictionary:
	var lvl := designed_level()
	if lvl == null or lvl.custom_cell_values.is_empty():
		return {}
	var start := maze.get_start()
	var end := maze.get_end()
	var out := {}
	for y in maze.height:
		for x in maze.width:
			var pos := Vector2i(x, y)
			if pos == start or pos == end or not maze.is_cell_active(pos) or not reachable.has(pos):
				continue
			var key := "%d,%d" % [x, y]
			if lvl.custom_cell_values.has(key) and int(lvl.custom_cell_values[key]) > 0:
				out[pos] = true
	return out


## Đường S→F NGẮN NHẤT tránh mọi ô mìn ghim (rỗng = mìn ghim chặn hết đường đi)
func _safe_path_avoiding(maze: MazeData, mines: Dictionary) -> Array[Vector2i]:
	if mines.is_empty():
		return maze.get_shortest_path(maze.get_start(), maze.get_end())

	var start := maze.get_start()
	var end := maze.get_end()
	var dist := {start: 0}
	var prev := {start: start}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var cur: Vector2i = queue.pop_front()
		if cur == end:
			break
		for d: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT]:
			var nxt: Vector2i = cur + d
			if dist.has(nxt) or mines.has(nxt):
				continue
			if not maze.is_in_bounds(nxt) or not maze.is_cell_active(nxt) or maze.has_wall(cur, nxt):
				continue
			dist[nxt] = int(dist[cur]) + 1
			prev[nxt] = cur
			queue.append(nxt)

	var path: Array[Vector2i] = []
	if not dist.has(end):
		return path
	var cursor := end
	while cursor != start:
		path.push_front(cursor)
		cursor = prev[cursor]
	path.push_front(start)
	return path


## Rải mìn lên các ô không thuộc `safe_path` (xác suất `density`), rồi tính số mìn lân cận từng ô.
## `only_reachable = true` (bàn thiết kế): bỏ qua ô bị tường bao kín — rải ở đó cũng vô ích.
## `pinned` = mìn nhà thiết kế ghim sẵn (luôn giữ, không rải random đè lên).
func _scatter_mines(maze: MazeData, safe_path: Array[Vector2i], density: float,
		only_reachable := false, pinned: Dictionary = {}) -> void:
	var safe_cells := {}
	for p: Vector2i in safe_path:
		safe_cells[p] = true
	var reachable := _reachable_cells(maze) if only_reachable else {}

	var candidates: Array[Vector2i] = []
	_total_mines = 0
	for pos: Vector2i in pinned:
		if safe_cells.has(pos) or _mines.has(pos):
			continue
		_mines[pos] = true
		_total_mines += 1
	for y in maze.height:
		for x in maze.width:
			var pos := Vector2i(x, y)
			if not maze.is_cell_active(pos) or safe_cells.has(pos) or _mines.has(pos):
				continue
			if only_reachable and not reachable.has(pos):
				continue
			candidates.append(pos)
			if randf() < density:
				_mines[pos] = true
				_total_mines += 1

	# Bàn không có mìn nào thì luật "dò mìn" thành vô nghĩa ⇒ ép 1 ô (nếu còn ô trống để rải)
	if _total_mines == 0 and not candidates.is_empty():
		var picked: Vector2i = candidates[randi() % candidates.size()]
		_mines[picked] = true
		_total_mines += 1

	_compute_neighbor_counts(maze)


## Các ô ĐI TỚI ĐƯỢC từ S (BFS qua các cạnh không có tường)
func _reachable_cells(maze: MazeData) -> Dictionary:
	var seen := {}
	var queue: Array[Vector2i] = [maze.get_start()]
	seen[maze.get_start()] = true
	while not queue.is_empty():
		var cur: Vector2i = queue.pop_front()
		for d: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT]:
			var nxt: Vector2i = cur + d
			if seen.has(nxt) or not maze.is_in_bounds(nxt) or not maze.is_cell_active(nxt):
				continue
			if maze.has_wall(cur, nxt):
				continue
			seen[nxt] = true
			queue.append(nxt)
	return seen


## Số mìn trong 8 ô lân cận của MỌI ô (số hiện trên bàn cờ)
func _compute_neighbor_counts(maze: MazeData) -> void:
	for y in maze.height:
		for x in maze.width:
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


func get_cell_text(pos: Vector2i, maze: MazeData) -> String:
	if maze == null:
		return ""
	if pos == maze.get_start():
		return "S"
	if pos == maze.get_end():
		return "F"
	# Ô đã nổ mìn vẫn giữ nguyên con số (không ghi đè bằng X) — xem nodes/game/cell.tscn (Bomb)
	var count: int = _neighbor_counts.get(pos, 0)
	return "" if count == 0 else str(count)


func evaluate_move(from_pos: Vector2i, to_pos: Vector2i, maze: MazeData) -> Dictionary:
	var base_eval := super.evaluate_move(from_pos, to_pos, maze)
	if not base_eval.get("allowed", false):
		return base_eval

	# Mìn luôn là hazard (đạp là thua ngay) — chỉ ghi nhận để HUD đếm "BOMB CÒN LẠI" + đánh dấu ô.
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


## Số mìn CHƯA nổ (đã trừ những ô đã lộ diện) — HUD hiện "BOMB: còn/tổng".
func get_mines_left() -> int:
	return maxi(_total_mines - _revealed_mines.size(), 0)


## Ô này đã nổ mìn chưa (Board vẽ biểu tượng Bomb lên ô đó).
func has_bomb_marker(pos: Vector2i) -> bool:
	return _revealed_mines.has(pos)


func get_hud_extra_info() -> String:
	return "BOMB: %d/%d" % [get_mines_left(), _total_mines]


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
