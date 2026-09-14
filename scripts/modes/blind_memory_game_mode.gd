class_name BlindMemoryGameMode
extends BaseGameMode
## ============================================================================
## Mode: Blind Memory Maze (Thử thách Trí nhớ Không gian).
## - Không hiển thị số trên các ô.
## - Khi bắt đầu, toàn bộ tường hiển thị kèm Countdown đếm ngược (3..2..1..GO!).
## - Sau khi Countdown kết thúc, tường ẩn hoàn toàn và bắt đầu tính giờ/bước.
## - Tùy chọn: Normal (về S khi đâm tường) hoặc Hardcore (thua ngay).
## ============================================================================

var countdown_seconds: int = 3


func _init(p_difficulty := "normal") -> void:
	mode_id = "blind_memory"
	mode_name = "Blind Memory"
	mode_description = "Không có số: Ghi nhớ vị trí toàn bộ bức tường trong lúc Countdown trước khi chúng biến mất!"
	is_endless = false
	difficulty = p_difficulty
	instant_game_over_on_hazard = (p_difficulty == "hardcore")
	initial_steps = 25
	countdown_seconds = 3 if difficulty == "normal" else 2
	# Pha GHI NHỚ: GameController hiện tường + mở popup đếm ngược rồi mới chạy đồng hồ
	memorize_countdown_seconds = countdown_seconds


func setup_floor(_floor_number: int) -> MazeData:
	var size := 4 if difficulty == "normal" else 5
	var maze := MazeData.new()
	maze.generate(size, size, 0.0)
	return maze


func get_cell_text(pos: Vector2i, maze: MazeData) -> String:
	if maze == null:
		return ""
	if pos == maze.get_start():
		return "S"
	if pos == maze.get_end():
		return "F"
	return ""


## Hiện toàn bộ tường cho pha ghi nhớ. Phần đếm ngược do popup lo
## (GameController._start_memorize_phase / UIController.show_memorize_countdown).
func on_grid_setup(grid_view: Control, _maze: MazeData) -> void:
	if grid_view != null and grid_view.has_method("reveal_all_walls"):
		grid_view.reveal_all_walls()


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
	return "CHẾ ĐỘ: %s" % difficulty.to_upper()
