class_name OneStrokeGameMode
extends BaseGameMode
## ============================================================================
## Mode: One Stroke (Một Nét) — Daily Challenge đặc biệt (GDD §5.12).
##
## LUẬT:
## - Bàn cờ KHÔNG có số; tường hiện RÕ 100% (không có tường ẩn, không có mìn).
##   Thử thách nằm ở THỨ TỰ ĐI, không phải ở việc dò tường.
## - Phải VẼ ĐÚNG 1 NÉT LIỀN phủ kín MỌI ô của bàn cờ, mỗi ô chỉ được vào ĐÚNG 1 LẦN.
## - Ô đã đi qua bị KHOÁ VĨNH VIỄN: cố tình đi đè lên = THUA NGAY
##   (evaluate_move trả hazard "revisit" + instant_game_over_on_hazard).
## - Ô Hố Thang Finish (F) chỉ được chạm ở NƯỚC CUỐI CÙNG: khi vẫn còn ô trống thì
##   nước đi vào F bị CHẶN (không tính bước, không thua).
## - Đi sai nhánh làm các ô trống bị CẮT RỜI (không còn cách nào phủ kín) -> hết đường
##   (is_dead_end -> GameController mở popup thua "HẾT ĐƯỜNG ĐI!").
## - Undo lùi 1 bước -> ô vừa rời được MỞ LẠI (on_move_undone).
## - Hint: chỉ ra ô ĐÚNG kế tiếp của một lời giải phủ kín (hint_next_cell).
##
## SINH BÀN (bảo đảm luôn giải được):
## - Bàn N×N với N LẺ -> S = (0,0) và F = (N-1, N-1) là 2 góc chéo cùng màu "đa số"
##   (điều kiện chẵn/lẻ của đường Hamilton trên lưới).
## - Dựng đường mẫu hình CON RẮN phủ kín bàn từ S tới F TRƯỚC, rồi mới đặt tường
##   ngẫu nhiên lên các cạnh KHÔNG thuộc đường mẫu -> đường mẫu luôn còn nguyên
##   => bàn luôn có ít nhất 1 lời giải phủ kín.
## ============================================================================

## Mật độ tường đặt thêm (chỉ trên các cạnh KHÔNG thuộc đường mẫu)
const WALL_RATIO := {
	"easy": 0.18,
	"medium": 0.34,
	"hard": 0.50,
}
## Ngân sách nút khi tự giải lại bài toán phủ kín để gợi ý (tránh treo máy ở bàn lớn)
const HINT_NODE_BUDGET := 60000

const DIRS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]

## Ô ĐÃ ĐI QUA (khoá vĩnh viễn) — có cả ô xuất phát S
var _visited: Dictionary = {}
## Tổng số ô phải phủ kín + cạnh bàn cờ (bàn vuông N×N)
var _total_cells: int = 0
var _size: int = 0
## Đường mẫu phủ kín dùng lúc sinh bàn (S -> F) — cũng là gợi ý nhanh khi đi đúng nó
var _model_cells: Array[Vector2i] = []
## Bộ đếm nút + nước đi đầu tiên của lời giải tìm được khi chạy hint
var _hint_nodes: int = 0
var _hint_first: Vector2i = Vector2i(-1, -1)


func _init(p_difficulty := "medium") -> void:
	mode_id = "one_stroke"
	mode_name = "One Stroke"
	mode_description = "Vẽ 1 nét liền phủ kín mọi ô, không đi lại ô cũ — ô cuối cùng phải là F!"
	is_endless = false
	# Đi vào ô đã qua = thua NGAY (không hồi sinh về S, giữ nguyên vệt nét đang vẽ)
	instant_game_over_on_hazard = true
	respawn_on_hazard = false
	difficulty = p_difficulty
	initial_steps = 30


func setup_floor(_floor_number: int) -> MazeData:
	_visited.clear()
	_model_cells.clear()

	var size := _size_for_difficulty()
	var maze := MazeData.new()
	maze.create_empty(size, size)
	_size = size
	_total_cells = size * size

	# 1) Đường mẫu phủ kín bàn (con rắn) — luôn kết thúc ở F = (size-1, size-1)
	_model_cells = _build_model_cells(size)

	# 2) Tường ngẫu nhiên trên các cạnh KHÔNG thuộc đường mẫu + hiện rõ 100%
	_place_walls(maze, size)
	maze.visible_wall_ratio = 1.0

	# 3) Ô xuất phát S coi như đã đi (không được quay lại S)
	_visited[maze.get_start()] = true

	# Mode không giới hạn bước thực chất — cấp dư để không bao giờ thua vì "hết bước"
	initial_steps = _total_cells * 3
	return maze


func _size_for_difficulty() -> int:
	match difficulty:
		"easy":
			return 3
		"hard":
			return 7
		_:
			return 5


## Đường mẫu hình con rắn phủ kín bàn, LUÔN kết thúc đúng ở F (size lẻ)
func _build_model_cells(size: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if randi() % 2 == 0:
		for y in size:
			if y % 2 == 0:
				for x in size:
					cells.append(Vector2i(x, y))
			else:
				for x in range(size - 1, -1, -1):
					cells.append(Vector2i(x, y))
	else:
		for x in size:
			if x % 2 == 0:
				for y in size:
					cells.append(Vector2i(x, y))
			else:
				for y in range(size - 1, -1, -1):
					cells.append(Vector2i(x, y))
	return cells


## Đặt tường lên các cạnh không thuộc đường mẫu (xác suất theo độ khó) rồi cho HIỆN RÕ.
func _place_walls(maze: MazeData, size: int) -> void:
	var path_edges := {}
	for i in _model_cells.size() - 1:
		path_edges[_edge_key(_model_cells[i], _model_cells[i + 1])] = true
	var ratio: float = float(WALL_RATIO.get(difficulty, WALL_RATIO["medium"]))

	for y in size:
		for x in size:
			var a := Vector2i(x, y)
			if x + 1 < size:
				_try_place_wall(maze, a, Vector2i(x + 1, y), ratio, path_edges)
			if y + 1 < size:
				_try_place_wall(maze, a, Vector2i(x, y + 1), ratio, path_edges)


func _try_place_wall(
	maze: MazeData, a: Vector2i, b: Vector2i, ratio: float, path_edges: Dictionary
) -> void:
	if path_edges.has(_edge_key(a, b)) or randf() > ratio:
		return
	if a.x == b.x:
		maze.set_h_wall(a.x, maxi(a.y, b.y), true)
	else:
		maze.set_v_wall(maxi(a.x, b.x), a.y, true)
	# One Stroke: mọi vách ngăn đều HIỆN RÕ ngay từ đầu (không có tường ẩn)
	maze.reveal_wall(a, b)


# ---------------------------------------------------------------------------
# Trạng thái phủ kín (HUD + board dùng để vẽ lớp "ĐÃ ĐI")
# ---------------------------------------------------------------------------
func visited_count() -> int:
	return _visited.size()


func total_cells() -> int:
	return _total_cells


func coverage_ratio() -> float:
	if _total_cells <= 0:
		return 0.0
	return clampf(float(_visited.size()) / float(_total_cells), 0.0, 1.0)


func is_cell_visited(pos: Vector2i) -> bool:
	return _visited.has(pos)


# ---------------------------------------------------------------------------
# Luật đi
# ---------------------------------------------------------------------------
func get_cell_text(pos: Vector2i, maze: MazeData) -> String:
	if maze == null:
		return ""
	if pos == maze.get_start():
		return "S"
	if pos == maze.get_end():
		return "F"
	return ""      # KHÔNG có số trên ô — luật nằm ở thứ tự đi


func evaluate_move(from_pos: Vector2i, to_pos: Vector2i, maze: MazeData) -> Dictionary:
	var base_eval := super.evaluate_move(from_pos, to_pos, maze)
	if not base_eval.get("allowed", false):
		return base_eval

	# 1) Ô đã đi qua = TỬ HUYỆT: đi lại là thua ngay (GameController kết thúc ván)
	if _visited.has(to_pos):
		return {
			"allowed": true,
			"is_hazard": true,
			"hazard_type": "revisit"
		}

	# 2) F chỉ được chạm ở nước CUỐI CÙNG: chừng nào còn ô KHÁC F chưa đi thì F bị
	#    CHẶN lại (không phải hazard). Khi F là ô trống cuối cùng thì đi vào là đúng luật.
	if to_pos == maze.get_end() and _visited.size() < _total_cells - 1:
		return {
			"allowed": false,
			"is_hazard": false,
			"hazard_type": "none",
			"reason": "finish_locked"
		}

	return {
		"allowed": true,
		"is_hazard": false,
		"hazard_type": "none"
	}


func on_player_moved(grid_view: Control, new_pos: Vector2i, _maze: MazeData) -> void:
	_visited[new_pos] = true
	_refresh_cells(grid_view)


## Nước đi bị chặn: riêng One Stroke phải NÓI RÕ lý do (F chỉ được chạm ở nước cuối cùng)
func on_move_blocked(grid_view: Control, _from_pos: Vector2i, to_pos: Vector2i, reason: String) -> void:
	if reason != "finish_locked" or grid_view == null or _total_cells <= 0:
		return
	if grid_view.has_method("spawn_floating_popup"):
		var left := maxi(_total_cells - _visited.size(), 0)
		grid_view.call("spawn_floating_popup", tr("STR_OS_FINISH_LOCKED").format([left]),
				to_pos, Color(0.847, 0.267, 0.267, 1.0))


## Undo lùi 1 bước: ô vừa rời (from_pos) được MỞ LẠI để đi lại
func on_move_undone(grid_view: Control, from_pos: Vector2i, _to_pos: Vector2i, _maze: MazeData) -> void:
	_visited.erase(from_pos)
	_refresh_cells(grid_view)


func check_completion(current_pos: Vector2i, maze: MazeData, _anchor_controller: Node) -> bool:
	if maze == null or current_pos != maze.get_end():
		return false
	return _visited.size() >= _total_cells


## Hết đường khi phần ô TRỐNG còn lại không thể phủ kín bằng 1 nét nữa.
## F bị coi như TƯỜNG khi xét vùng ô trống (vì F chỉ được là ô CUỐI CÙNG, không được
## đi xuyên qua) — nếu bỏ F ra mà các ô trống còn lại bị CẮT RỜI thì đã hết đường.
func is_dead_end(current_pos: Vector2i, maze: MazeData) -> bool:
	if maze == null or current_pos == maze.get_end():
		return false
	var unvisited := _unvisited_cells()
	if unvisited.is_empty():
		return false
	return not _region_ok(maze, current_pos, unvisited)


# ---------------------------------------------------------------------------
# Hint: soi ô ĐÚNG kế tiếp của một lời giải phủ kín
# ---------------------------------------------------------------------------
## Ô kế tiếp nên đi (Vector2i(-1,-1) = mode không có ý kiến -> GridController dùng hint mặc định)
func hint_next_cell(maze: MazeData, current_pos: Vector2i) -> Vector2i:
	if maze == null:
		return Vector2i(-1, -1)
	# Đang bám đúng đường mẫu lúc sinh bàn -> chỉ luôn ô kế tiếp (nhanh, khỏi dò)
	var idx := _model_cells.find(current_pos)
	if idx >= 0 and idx + 1 < _model_cells.size():
		var following: Vector2i = _model_cells[idx + 1]
		if not _visited.has(following):
			return following
	# Đi lệch khỏi đường mẫu -> tự giải lại bài toán phủ kín (DFS cắt tỉa, có ngân sách)
	return _solve_next_cell(maze, current_pos)


func _solve_next_cell(maze: MazeData, current_pos: Vector2i) -> Vector2i:
	var unvisited := _unvisited_cells()
	if unvisited.is_empty():
		return current_pos
	if not _region_ok(maze, current_pos, unvisited):
		return current_pos
	_hint_nodes = 0
	_hint_first = Vector2i(-1, -1)
	if _dfs_cover(maze, current_pos, unvisited, true):
		return _hint_first if _hint_first != Vector2i(-1, -1) else current_pos
	return current_pos


func _dfs_cover(maze: MazeData, cur: Vector2i, unvisited: Dictionary, is_root: bool) -> bool:
	if _hint_nodes > HINT_NODE_BUDGET:
		return false
	_hint_nodes += 1
	var end_pos := maze.get_end()
	if unvisited.is_empty():
		return cur == end_pos
	# F chỉ được là ô cuối cùng
	if unvisited.has(end_pos) and unvisited.size() == 1:
		if not _can_step(maze, cur, end_pos):
			return false
	var options: Array[Vector2i] = []
	for d: Vector2i in DIRS:
		var nxt: Vector2i = cur + d
		if unvisited.has(nxt) and _can_step(maze, cur, nxt):
			options.append(nxt)
	if options.is_empty():
		return false
	# Ưu tiên ô ít lối thoát (kiểu Warnsdorff) để ít nhánh chết
	options.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return _open_neighbour_count(maze, a, unvisited) < _open_neighbour_count(maze, b, unvisited)
	)
	for nxt: Vector2i in options:
		var rest := unvisited.duplicate()
		rest.erase(nxt)
		if not _region_ok(maze, nxt, rest):
			continue
		if _dfs_cover(maze, nxt, rest, false):
			if is_root:
				_hint_first = nxt
			return true
	return false


func get_hud_extra_info() -> String:
	return "PHỦ KÍN: %d/%d" % [_visited.size(), _total_cells]


## Thử thách mặc định của One Stroke (§5.12): không đâm tường là vô nghĩa ở đây nên dùng
## time_max · no_hint · no_undo (KHÔNG dùng visit_all/no_revisit vì đó là luật cứng của chế độ).
func default_challenges() -> Array[String]:
	return [ChallengeTypes.TIME_MAX, ChallengeTypes.NO_HINT, ChallengeTypes.NO_UNDO]


# ---------------------------------------------------------------------------
# Tiện ích lưới
# ---------------------------------------------------------------------------
func _unvisited_cells() -> Dictionary:
	var out := {}
	for y in _size:
		for x in _size:
			var pos := Vector2i(x, y)
			if not _visited.has(pos):
				out[pos] = true
	return out


## F còn trống thì nó phải là ĐIỂM DỪNG CUỐI: khi xét vùng ô trống còn phủ được hay không,
## BỎ F RA khỏi vùng đó (không được đi xuyên qua F). Chỉ còn đúng F thì phải bước vào được ngay.
func _region_ok(maze: MazeData, cur: Vector2i, unvisited: Dictionary) -> bool:
	var end_pos := maze.get_end()
	var rest := unvisited.duplicate()
	rest.erase(end_pos)
	if rest.is_empty():
		return unvisited.has(end_pos) and _can_step(maze, cur, end_pos)
	return _region_connected(maze, cur, rest)


func _can_step(maze: MazeData, a: Vector2i, b: Vector2i) -> bool:
	if not maze.is_in_bounds(b) or not maze.is_cell_active(b):
		return false
	return not maze.has_wall(a, b)


## Mọi ô trong `cells` có nối liền nhau từ `from_pos` qua các ô trống không
## (ô F vẫn được tính là ô trống — chỉ khác là nó phải là ĐIỂM DỪNG CUỐI).
func _region_connected(maze: MazeData, from_pos: Vector2i, cells: Dictionary) -> bool:
	if cells.is_empty():
		return true
	var seen := {}
	var stack: Array[Vector2i] = []
	for d: Vector2i in DIRS:
		var nxt: Vector2i = from_pos + d
		if cells.has(nxt) and _can_step(maze, from_pos, nxt):
			seen[nxt] = true
			stack.append(nxt)
	while not stack.is_empty():
		var cur: Vector2i = stack.pop_back()
		for d: Vector2i in DIRS:
			var nxt: Vector2i = cur + d
			if cells.has(nxt) and not seen.has(nxt) and _can_step(maze, cur, nxt):
				seen[nxt] = true
				stack.append(nxt)
	return seen.size() == cells.size()


func _open_neighbour_count(maze: MazeData, pos: Vector2i, cells: Dictionary) -> int:
	var count := 0
	for d: Vector2i in DIRS:
		var nxt: Vector2i = pos + d
		if cells.has(nxt) and _can_step(maze, pos, nxt):
			count += 1
	return count


func _refresh_cells(grid_view: Control) -> void:
	if grid_view != null and grid_view.has_method("refresh_cell_texts"):
		grid_view.call("refresh_cell_texts")


func _edge_key(a: Vector2i, b: Vector2i) -> String:
	var lo := a
	var hi := b
	if a.x > b.x or (a.x == b.x and a.y > b.y):
		lo = b
		hi = a
	return "%d,%d|%d,%d" % [lo.x, lo.y, hi.x, hi.y]
