class_name CountdownCostGameMode
extends BaseGameMode
## ============================================================================
## Mode: Countdown Cost (Chi phí bước di chuyển theo số trên ô).
## - Số trên ô vừa là số tường vừa là chi phí bước khi bước tới ô đó (0..4).
## - Đâm tường: về S, trừ chi phí ô đích.
## - Không có tường (count == 0): Không hiển thị số 0.
## ============================================================================

func _init(p_difficulty := "medium") -> void:
	mode_id = "countdown_cost"
	mode_name = "Countdown Cost"
	mode_description = "Số bước bị trừ bằng đúng giá trị con số ghi trên ô bước tới (0-4 bước)."
	is_endless = false
	instant_game_over_on_hazard = false
	difficulty = p_difficulty
	_apply_difficulty()


func _apply_difficulty() -> void:
	match difficulty:
		"easy":
			initial_steps = 25
		"hard":
			initial_steps = 16
		_:
			difficulty = "medium"
			initial_steps = 20


func setup_floor(_floor_number: int) -> MazeData:
	var size := 4
	var ratio := 0.35
	match difficulty:
		"easy":
			size = 3
			ratio = 0.5
		"hard":
			size = 5
			ratio = 0.2
		_:
			size = 4
			ratio = 0.35

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


func get_step_cost(_from_pos: Vector2i, to_pos: Vector2i, maze: MazeData) -> int:
	if maze == null:
		return 1
	return maze.get_wall_count(to_pos)


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
	return "CHI PHÍ: %s" % difficulty.to_upper()
