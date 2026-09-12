class_name FogOfWarGameMode
extends BaseGameMode
## ============================================================================
## Mode: Fog of War Maze (Sương Mù Che Số Động).
## - Hoạt động tương tự Classic (có tường vô hình để suy luận).
## - Chỉ hiển thị số ở các ô lân cận bán kính 1 quanh vị trí hiện tại của nhân vật.
## - Không có tường (count == 0): Không hiển thị số 0.
## ============================================================================

var _player_pos: Vector2i = Vector2i.ZERO
var _explored_cells: Dictionary = {}


func _init(p_difficulty := "normal") -> void:
	mode_id = "fog_of_war"
	mode_name = "Fog of War"
	mode_description = "Số chỉ hiển thị quanh vị trí hiện tại. Di chuyển để khám phá các con số tiếp theo!"
	is_endless = false
	difficulty = p_difficulty
	instant_game_over_on_hazard = (p_difficulty == "hardcore")
	initial_steps = 25


func setup_floor(_floor_number: int) -> MazeData:
	_explored_cells.clear()
	var size := 4 if difficulty == "normal" else 5
	var maze := MazeData.new()
	maze.generate(size, size, 0.0)

	_player_pos = maze.get_start()
	_update_fog(_player_pos, maze.width, maze.height)
	return maze


func get_cell_text(pos: Vector2i, maze: MazeData) -> String:
	if maze == null:
		return ""
	if pos == maze.get_start():
		return "S"
	if pos == maze.get_end():
		return "F"

	var d := (pos - _player_pos).abs()
	if d.x <= 1 and d.y <= 1:
		var count := maze.get_wall_count(pos)
		return "" if count == 0 else str(count)

	return ""


func on_grid_setup(grid_view: Control, maze: MazeData) -> void:
	_player_pos = maze.get_start()
	_update_fog(_player_pos, maze.width, maze.height)
	if grid_view != null and grid_view.has_method("apply_fog_of_war"):
		grid_view.apply_fog_of_war(_player_pos, 1, _explored_cells)


func on_player_moved(grid_view: Control, new_pos: Vector2i, maze: MazeData) -> void:
	_player_pos = new_pos
	_update_fog(new_pos, maze.width, maze.height)
	if grid_view != null and grid_view.has_method("apply_fog_of_war"):
		grid_view.apply_fog_of_war(new_pos, 1, _explored_cells)


func evaluate_move(from_pos: Vector2i, to_pos: Vector2i, maze: MazeData) -> Dictionary:
	var base_eval := super.evaluate_move(from_pos, to_pos, maze)
	if not base_eval.get("allowed", false):
		return base_eval

	if maze.has_wall(from_pos, to_pos):
		maze.reveal_wall(from_pos, to_pos)
		return {
			"allowed": false,
			"is_hazard": true,
			"hazard_type": "wall",
			"from": from_pos,
			"to": to_pos
		}

	return {
		"allowed": true,
		"is_hazard": false,
		"hazard_type": "none"
	}


func _update_fog(center: Vector2i, width: int, height: int) -> void:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var p := center + Vector2i(dx, dy)
			if p.x >= 0 and p.x < width and p.y >= 0 and p.y < height:
				_explored_cells[p] = true


func get_hud_extra_info() -> String:
	return "SƯƠNG MÙ: %s" % difficulty.to_upper()
