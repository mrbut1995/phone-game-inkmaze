class_name AreaGameMode
extends BaseGameMode
## ============================================================================
## Mode: Area Maze (Phân vùng Khu Vực).
## - Số trên ô là điểm số (1..9).
## - Người chơi kéo nối các Anchor để phân chia bàn cờ thành các Area có tổng
##   điểm đạt Target, đồng thời có 1 Area chứa cả ô S và ô F.
## ============================================================================

var _cell_values: Dictionary = {}      # Vector2i -> int (1..9)
var target_area_count: int = 2
var target_area_score: int = 10
var _last_detected_areas: Array = []


func _init() -> void:
	mode_id = "area"
	mode_name = "Area Maze"
	mode_description = "Nối Anchor phân chia khu vực đạt đúng tổng điểm và nối S với F."
	is_endless = false
	instant_game_over_on_hazard = false
	initial_steps = 40


func setup_floor(floor_number: int) -> MazeData:
	_cell_values.clear()
	_last_detected_areas.clear()

	var size := clampi(2 + floor_number, 3, 5)
	var maze := MazeData.new()
	maze.create_empty(size, size)

	target_area_count = 2 if size <= 3 else 3
	target_area_score = (size * size * 4) / target_area_count

	var regions: Array = []
	for k in target_area_count:
		regions.append([])

	var seeds: Array[Vector2i] = []
	if target_area_count == 2:
		seeds = [Vector2i(0, 0), Vector2i(size - 1, size - 1)]
	else:
		seeds = [Vector2i(0, 0), Vector2i(size - 1, 0), Vector2i(0, size - 1)]

	var cell_region := {}
	var queues: Array = []
	for k in target_area_count:
		var s: Vector2i = seeds[k]
		cell_region[s] = k
		regions[k].append(s)
		queues.append([s])

	var unassigned := size * size - target_area_count
	while unassigned > 0:
		for k in target_area_count:
			var q: Array = queues[k]
			if q.is_empty():
				continue
			var cur: Vector2i = q.pop_front()
			for d: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]:
				var nxt: Vector2i = cur + d
				if nxt.x >= 0 and nxt.x < size and nxt.y >= 0 and nxt.y < size:
					if not cell_region.has(nxt):
						cell_region[nxt] = k
						regions[k].append(nxt)
						queues[k].append(nxt)
						unassigned -= 1
						if unassigned == 0:
							break

	for k in target_area_count:
		var region_cells: Array = regions[k]
		var count := region_cells.size()
		if count == 0:
			continue
		
		var remaining := target_area_score
		for i in count:
			var cell: Vector2i = region_cells[i]
			if i == count - 1:
				_cell_values[cell] = maxi(1, remaining)
			else:
				var max_val := maxi(1, remaining - (count - 1 - i))
				var val := clampi(randi_range(1, mini(6, max_val)), 1, 9)
				_cell_values[cell] = val
				remaining -= val

	if regions[0].size() >= 2:
		maze.start = regions[0][0]
		maze.end = regions[0][regions[0].size() - 1]

	return maze


func get_cell_text(pos: Vector2i, _maze: MazeData) -> String:
	return str(_cell_values.get(pos, 1))


func evaluate_move(from_pos: Vector2i, to_pos: Vector2i, maze: MazeData) -> Dictionary:
	var base_eval := super.evaluate_move(from_pos, to_pos, maze)
	if not base_eval.get("allowed", false):
		return base_eval

	return {
		"allowed": true,
		"is_hazard": false,
		"hazard_type": "none"
	}


func check_completion(current_pos: Vector2i, maze: MazeData, anchor_controller: Node) -> bool:
	if maze == null or anchor_controller == null:
		return false

	if current_pos != maze.get_end():
		return false

	var areas := detect_areas(maze, anchor_controller)
	_last_detected_areas = areas

	if areas.size() != target_area_count:
		return false

	var has_sf_area := false
	for area in areas:
		var score := 0
		var has_s := false
		var has_f := false
		for cell: Vector2i in area:
			score += _cell_values.get(cell, 0)
			if cell == maze.get_start():
				has_s = true
			if cell == maze.get_end():
				has_f = true

		if score != target_area_score:
			return false

		if has_s and has_f:
			has_sf_area = true

	return has_sf_area


func detect_areas(maze: MazeData, anchor_controller: Node) -> Array:
	var areas: Array = []
	var visited := {}
	var size := maze.width

	for y in size:
		for x in size:
			var start_cell := Vector2i(x, y)
			if visited.has(start_cell):
				continue

			var area: Array[Vector2i] = []
			var queue: Array[Vector2i] = [start_cell]
			visited[start_cell] = true

			while not queue.is_empty():
				var cur: Vector2i = queue.pop_front()
				area.append(cur)

				for d: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]:
					var nxt: Vector2i = cur + d
					if nxt.x >= 0 and nxt.x < size and nxt.y >= 0 and nxt.y < size and not visited.has(nxt):
						var has_barrier := false
						if anchor_controller != null and anchor_controller.has_method("is_suspected"):
							if d == Vector2i.RIGHT:
								has_barrier = anchor_controller.is_suspected(false, Vector2i(nxt.x, cur.y))
							elif d == Vector2i.LEFT:
								has_barrier = anchor_controller.is_suspected(false, Vector2i(cur.x, cur.y))
							elif d == Vector2i.DOWN:
								has_barrier = anchor_controller.is_suspected(true, Vector2i(cur.x, nxt.y))
							elif d == Vector2i.UP:
								has_barrier = anchor_controller.is_suspected(true, Vector2i(cur.x, cur.y))

						if not has_barrier:
							visited[nxt] = true
							queue.append(nxt)

			areas.append(area)

	return areas


func get_cell_value(pos: Vector2i) -> int:
	return _cell_values.get(pos, 1)


func get_hud_extra_info() -> String:
	return "KHU VỰC: %d | TARGET: %d" % [target_area_count, target_area_score]
