class_name StandardGameMode
extends BaseGameMode
## ============================================================================
## Mode: Play Mode (Standard / Classic - 1 Màn: Đâm tường = Thua ngay).
## - Số trên ô là số tường vô hình (0..4). Không hiện số 0.
## - Đâm vào tường vô hình = Game Over ngay lập tức.
## - Xếp hạng theo thời gian hoàn thành nhanh nhất.
## ============================================================================

func _init(p_difficulty := "medium") -> void:
	mode_id = "play"
	mode_name = "Play Mode"
	mode_description = "1 Màn duy nhất: Đâm vào tường vô hình = Thua ngay lập tức!"
	is_endless = false
	instant_game_over_on_hazard = true
	difficulty = p_difficulty
	_apply_difficulty()


func _apply_difficulty() -> void:
	match difficulty:
		"easy":
			initial_steps = 15
		"hard":
			initial_steps = 25
		_:
			difficulty = "medium"
			initial_steps = 20


func setup_floor(floor_number: int) -> MazeData:
	# Nạp màn chơi từ LevelManager Resource thay vì ngẫu nhiên
	var main_loop := Engine.get_main_loop()
	if main_loop is SceneTree:
		var tree := main_loop as SceneTree
		var lm: Node = tree.root.get_node_or_null("LevelManager")
		if lm != null and lm.has_method("load_level"):
			var lvl: LevelData = lm.call("load_level", floor_number)
			if lvl != null:
				initial_steps = lvl.max_steps
				current_level_data = lvl      # nguồn Thử thách của màn (tối đa 3)
				return lvl.to_maze_data()

	# Fallback tạo maze nếu không có LevelManager
	current_level_data = null
	var size := 3
	var ratio := 0.5
	var maze := MazeData.new()
	maze.generate(size, size, ratio)
	return maze


func get_cell_text(pos: Vector2i, maze: MazeData) -> String:
	if maze == null:
		return ""
	if pos == maze.get_start():
		return "S"
	if pos == maze.get_end():
		return "F"
	var count := maze.get_wall_count(pos)
	return "" if count == 0 else str(count)


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


func get_hud_extra_info() -> String:
	return "ĐỘ KHÓ: %s" % difficulty.to_upper()
