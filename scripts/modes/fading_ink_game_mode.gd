class_name FadingInkGameMode
extends BaseGameMode
## ============================================================================
## Mode: Fading Ink (Mực Phai) — thay cho Area Maze (đã bỏ 2026-11).
##
## - Bàn KHÔNG có tường trong (chỉ viền ngoài). Con số trên ô KHÔNG phải số tường
##   mà là MỰC của riêng ô đó.
## - Người chơi CHỈ được đi vào ô còn mực (> 0). Ô hết mực coi như trống, không đi vào.
## - MỖI BƯỚC ĐI làm MỌI ô nhạt đi đúng 1 điểm mực: ô nào về 0 thì mất số.
## - Vì mực phai toàn bàn nên phải tìm đường NGẮN NHẤT tới F trước khi lối đi biến mất.
## - Hết lối đi mà chưa tới F -> thua (is_dead_end -> GameController._on_dead_end).
##
## Trạng thái mực được TÍNH LẠI từ số bước đã đi (`moves_made`) nên Undo (lùi bước)
## tự động "hồi mực" mà không cần lưu lịch sử — xem on_move_undone().
## ============================================================================

## Mực ban đầu của các ô.
const INK_MIN := 2
const INK_MAX := 9
## Ô ngoài đường ngắn nhất: mực thấp (lối tắt dự phòng, mau phai)
const OFF_PATH_MIN := 2
const OFF_PATH_MAX := 6
## Số bước của đường ngắn nhất + khoảng dư để chốt ngưỡng thử thách "đi không quá N bước"
const STEP_SLACK := 4

## Số bước đã đi = số điểm mực đã phai (mọi ô cùng phai một nhịp)
var moves_made: int = 0

var _ink: Dictionary = {}          # Vector2i -> int : MỰC BAN ĐẦU của ô
var _start_pos := Vector2i.ZERO
var _end_pos := Vector2i.ZERO
## Số bước cần cho đường ngắn nhất (đường đi mẫu lúc sinh bàn)
var design_moves: int = 0


func _init(p_difficulty := "medium") -> void:
	mode_id = "fading_ink"
	mode_name = "Fading Ink"
	mode_description = "Chỉ đi trên ô còn số: mỗi bước đi làm MỌI con số nhạt đi 1 — số về 0 là ô biến mất!"
	is_endless = false
	instant_game_over_on_hazard = false
	difficulty = p_difficulty
	initial_steps = 25


func setup_floor(_floor_number: int) -> MazeData:
	_ink.clear()
	moves_made = 0

	var size := 4
	match difficulty:
		"easy":
			size = 3
		"hard":
			size = 5
		_:
			size = 4

	var maze := MazeData.new()
	maze.create_empty(size, size)      # luật đi nằm ở MỰC của từng ô, không phải tường
	_start_pos = maze.get_start()
	_end_pos = maze.get_end()

	var shortest := maze.get_shortest_path(_start_pos, _end_pos)
	design_moves = maxi(shortest.size() - 1, 0)
	# Ngưỡng thử thách: đi đúng đường ngắn nhất + chút dư (mode không giới hạn bước)
	initial_steps = design_moves + STEP_SLACK

	_assign_ink(maze, shortest)
	return maze


## Cấp mực ban đầu: ô trên đường ngắn nhất LUÔN đủ mực để tới F,
## các ô còn lại nhận mực ngẫu nhiên thấp hơn (lối tắt dự phòng).
func _assign_ink(maze: MazeData, shortest: Array[Vector2i]) -> void:
	var step_index := {}
	for i in shortest.size():
		step_index[shortest[i]] = i      # S = 0, ô kế tiếp của đường mẫu = 1, 2...
	for y in maze.height:
		for x in maze.width:
			var pos := Vector2i(x, y)
			if not maze.is_cell_active(pos) or pos == _start_pos or pos == _end_pos:
				continue
			if step_index.has(pos):
				# Để tới được ô ở bước thứ j thì lúc đó mực còn (j-1) điểm đã phai
				# -> mực ban đầu phải >= j, cho dư 2..3 điểm.
				var j: int = int(step_index[pos])
				_ink[pos] = clampi(j + randi_range(2, 3), INK_MIN, INK_MAX)
			else:
				_ink[pos] = randi_range(OFF_PATH_MIN, OFF_PATH_MAX)


# ---------------------------------------------------------------------------
# Mực
# ---------------------------------------------------------------------------
## Mực còn lại của ô ở thời điểm hiện tại (đã trừ số bước đã đi)
func ink_left(pos: Vector2i) -> int:
	return maxi(int(_ink.get(pos, 0)) - moves_made, 0)


## Mực BAN ĐẦU của ô (chưa phai) — dùng khi cần phân biệt ô vốn có số
func ink_initial(pos: Vector2i) -> int:
	return int(_ink.get(pos, 0))


## Ô có đi vào được không: S/F luôn đi được, các ô khác phải còn mực
func is_walkable(pos: Vector2i) -> bool:
	if pos == _start_pos or pos == _end_pos:
		return true
	return ink_left(pos) > 0


func get_cell_text(pos: Vector2i, maze: MazeData) -> String:
	if maze == null:
		return ""
	if pos == maze.get_start():
		return "S"
	if pos == maze.get_end():
		return "F"
	var left := ink_left(pos)
	return "" if left <= 0 else str(left)


func evaluate_move(from_pos: Vector2i, to_pos: Vector2i, maze: MazeData) -> Dictionary:
	var base_eval := super.evaluate_move(from_pos, to_pos, maze)
	if not base_eval.get("allowed", false):
		return base_eval

	# Ô đã phai hết mực = ô trống: KHÔNG đi vào được (không phải hazard, không mất bước)
	if not is_walkable(to_pos):
		return {
			"allowed": false,
			"is_hazard": false,
			"hazard_type": "none",
			"reason": "no_ink"
		}

	return {
		"allowed": true,
		"is_hazard": false,
		"hazard_type": "none"
	}


func on_player_moved(grid_view: Control, _new_pos: Vector2i, _maze: MazeData) -> void:
	moves_made += 1                  # mọi ô nhạt đi 1 điểm mực
	_refresh_ink(grid_view)


## Lùi bước (Undo): mực "hồi" lại đúng số bước đã lùi (không cần lưu lịch sử)
func on_move_undone(grid_view: Control, _from_pos: Vector2i, _to_pos: Vector2i, _maze: MazeData) -> void:
	moves_made = maxi(moves_made - 1, 0)
	_refresh_ink(grid_view)


## Không còn ô nào đi được nữa mà chưa tới F -> hết đường
func is_dead_end(current_pos: Vector2i, maze: MazeData) -> bool:
	if maze == null or current_pos == maze.get_end():
		return false
	for d: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT]:
		var nxt: Vector2i = current_pos + d
		if maze.is_in_bounds(nxt) and maze.is_cell_active(nxt) and is_walkable(nxt):
			return false
	return true


func get_hud_extra_info() -> String:
	return "MỰC PHAI: %d" % moves_made


func _refresh_ink(grid_view: Control) -> void:
	if grid_view != null and grid_view.has_method("refresh_cell_texts"):
		grid_view.call("refresh_cell_texts", true)
