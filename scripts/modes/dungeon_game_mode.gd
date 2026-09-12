class_name DungeonGameMode
extends BaseGameMode
## ============================================================================
## Mode: Dungeon Mode (Endless Maze Tường Vô Hình).
## - Nhiều Floor liên tiếp, độ khó tăng dần qua Endless Visible Wall.
## - Đâm tường: trừ 1 bước, lộ tường thật, rung bàn cờ, đưa nhân vật về điểm S.
## - Không có tường (count == 0): Không hiển thị số 0.
## ============================================================================

func _init() -> void:
	mode_id = "dungeon"
	mode_name = "Dungeon Mode"
	mode_description = "Vượt tháp mê cung tường vô hình bất tận."
	is_endless = true
	instant_game_over_on_hazard = false
	initial_steps = 15


func setup_floor(floor_number: int) -> MazeData:
	var size := FloorConfig.get_grid_size(floor_number)
	var ratio := FloorConfig.get_visible_ratio(floor_number)
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
