class_name HintController
extends Node
## ============================================================================
## Controller: Cung cấp gợi ý (Hint) cho người chơi.
## - Tìm bước đi hợp lệ tiếp theo hướng tới đích F bằng thuật toán BFS.
## - Hoặc hé lộ một đoạn tường vô hình để hỗ trợ người chơi suy luận.
## ============================================================================

signal hint_provided(hint_type: String, data: Dictionary)


func get_next_step_hint(maze: MazeData, current_pos: Vector2i) -> Vector2i:
	if maze == null:
		return current_pos
	var path := maze.get_shortest_path(current_pos, maze.get_end())
	if path.size() >= 2:
		var next_step: Vector2i = path[1]
		hint_provided.emit("step", { "next_cell": next_step })
		return next_step
	return current_pos


func reveal_one_invisible_wall(maze: MazeData) -> Dictionary:
	if maze == null:
		return {}

	for ix in maze.width:
		for iy in range(1, maze.height):
			if maze.has_h_wall(ix, iy) and not maze.is_h_wall_visible(ix, iy):
				maze._h_visible[ix][iy] = 1
				var data := { "is_h": true, "lattice": Vector2i(ix, iy) }
				hint_provided.emit("wall", data)
				return data

	for ix in range(1, maze.width):
		for iy in maze.height:
			if maze.has_v_wall(ix, iy) and not maze.is_v_wall_visible(ix, iy):
				maze._v_visible[ix][iy] = 1
				var data := { "is_h": false, "lattice": Vector2i(ix, iy) }
				hint_provided.emit("wall", data)
				return data

	return {}
