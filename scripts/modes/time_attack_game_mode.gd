class_name TimeAttackGameMode
extends BaseGameMode
## ============================================================================
## Mode: Time Attack Maze (Chạy Đua Với Thời Gian).
## - Giới hạn thời gian tổng (60s / 90s / 120s) đếm ngược về 0.
## - Không giới hạn số bước di chuyển (initial_steps = 999).
## - Đâm tường: về S, mất thời gian. Hết giờ = Game Over.
## ============================================================================

var time_limit: float = 60.0


func _init(p_difficulty := "medium") -> void:
	mode_id = "time_attack"
	mode_name = "Time Attack"
	mode_description = "Không giới hạn bước: Chạy đua với đồng hồ đếm ngược để tới đích F trước khi hết giờ!"
	is_endless = false
	instant_game_over_on_hazard = false
	difficulty = p_difficulty
	initial_steps = 999

	match difficulty:
		"easy":
			time_limit = 90.0
		"hard":
			time_limit = 45.0
		_:
			time_limit = 60.0


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
	return "TIME ATTACK"
