class_name WallBuilderGameMode
extends BaseGameMode
## ============================================================================
## Mode: Wall Builder (Xây Tường) — Daily Challenge đặc biệt (GDD §5.13).
##
## LUẬT:
## - Bàn có mê cung sinh sẵn nhưng **tường bị ẩn HOÀN TOÀN**; KHÔNG có S/F,
##   KHÔNG có nhân vật và KHÔNG di chuyển (evaluate_move luôn từ chối).
## - Số trên MỌI ô (0..4) = số cạnh có TƯỜNG GIỮA 2 Ô THUỘC BOARD (đúng quy ước §2):
##   người chơi đọc số để suy ra các đoạn tường rồi **kéo nối 2 Anchor** để dựng.
## - Số đoạn cần dựng luôn xác định ngay từ đầu: `y = Σ(số trên mọi ô) / 2`
##   (mỗi đoạn tường bên trong được ĐÚNG 2 ô kề nó đếm chung).
## - Bấm **GỬI**: khớp TOÀN BỘ con số ⇒ THẮNG (không bắt buộc trùng mê cung gốc —
##   mọi cấu hình thoả số đều là nghiệm). Sai ⇒ mất **1 LƯỢT GỬI** (3 lượt) +
##   báo **số đoạn còn lệch** (chỉ số lượng) + rung bàn cờ. Hết lượt gửi ⇒ THUA.
## - Hồi sinh (xem quảng cáo): **+1 LƯỢT GỬI** (dùng chung cơ chế LƯỢT THỬ §13.16).
## - GỢI Ý: mở + **KHOÁ** 1 đoạn tường THẬT (luôn là một nghiệm hợp lệ, không xoá được).
## - UNDO: xoá đoạn tường vừa nối (bỏ qua các đoạn đã bị khoá).
## ============================================================================

## Số LƯỢT GỬI mỗi màn (hết lượt là thua)
const SUBMIT_LIVES := 3
## Ngân sách nút khi đếm nghiệm (bàn ≤ 5×5 nên đủ nhanh; vượt ngân sách = coi như "nhiều nghiệm")
const SOLVER_NODE_BUDGET := 80000

## Các đoạn tường người chơi đã dựng: key "h,x,y" / "v,x,y" -> true
var built: Dictionary = {}
## Đoạn do GỢI Ý mở — khoá vĩnh viễn, không xoá được
var locked: Dictionary = {}
## Tổng số đoạn cần dựng = Σ(số trên mọi ô) / 2
var required_segments: int = 0
## Số lần gửi sai trong ván (thống kê/HUD)
var submit_misses: int = 0

var _size: int = 0
var _maze: MazeData = null
var _draw_order: Array[String] = []
var _solved: bool = false
## Số nghiệm của bàn đang chơi (-1 = solver vượt ngân sách -> coi như "nhiều nghiệm")
var solution_count: int = 0

## Trạng thái tạm của solver đếm nghiệm
var _sol_nodes: int = 0
var _sol_found: int = 0
var _sol_cap: int = 2
var _sol_edges: Array = []
var _sol_counts: PackedInt32Array = PackedInt32Array()
var _sol_decided: PackedInt32Array = PackedInt32Array()
var _sol_total: PackedInt32Array = PackedInt32Array()


func _init(p_difficulty := "medium") -> void:
	mode_id = "wall_builder"
	mode_name = "Wall Builder"
	mode_description = "Đọc số trên ô để tự nối các đoạn tường rồi bấm GỬI BÀI."
	is_endless = false
	instant_game_over_on_hazard = false
	respawn_on_hazard = false
	# Dùng chung cơ chế LƯỢT THỬ: ở đây là LƯỢT GỬI (§5.13)
	max_retries = SUBMIT_LIVES
	difficulty = p_difficulty
	initial_steps = 999


func setup_floor(_floor_number: int) -> MazeData:
	built.clear()
	locked.clear()
	_draw_order.clear()
	_solved = false
	submit_misses = 0
	reset_retries()

	_size = _size_for_difficulty()
	_maze = _pick_maze(_size)
	required_segments = count_true_segments(_maze)
	# Không có di chuyển -> số bước không có ý nghĩa (không bao giờ hết bước)
	initial_steps = 999
	return _maze


func _size_for_difficulty() -> int:
	match difficulty:
		"easy":
			return 3
		"hard":
			return 5
		_:
			return 4


## Sinh bàn: mê cung tường ẩn HOÀN TOÀN (visible_wall_ratio = 0). Bàn sinh ra luôn có
## nghiệm là chính nó (§5.13) nên chỉ cần LỌC cho bàn đáng suy luận:
##   · đủ tường (loại bàn 1–2 đoạn nhìn là ra) · không quá nhiều ô 0/4,
##   · và ƯU TIÊN bàn có ≥ 2 nghiệm (đếm bằng solver cắt tỉa — xem count_solutions).
func _pick_maze(size: int) -> MazeData:
	var best: MazeData = null
	var best_score := -1
	var trivial_cap := maxi(size * size / 4, 2)
	for _attempt in 16:
		var maze := MazeData.new()
		maze.generate(size, size, 0.0)
		if count_true_segments(maze) < size:
			continue                      # quá ít tường -> bàn hiển nhiên, sinh lại
		var trivial := _count_trivial_cells(maze)
		var solutions := count_solutions(maze, 2)
		if solutions < 0:
			solutions = 2                 # solver chạm ngân sách = bàn khó -> nhận
		# Điểm "đáng suy luận": nhiều ô phải suy luận + thưởng bàn nhiều nghiệm
		var score := (size * size - trivial) * 2 + (2 if solutions >= 2 else 0)
		if score > best_score:
			best_score = score
			best = maze
			solution_count = solutions
		if trivial <= trivial_cap and solutions >= 2:
			solution_count = solutions
			return maze
	return best if best != null else _generate_any(size)


## Chốt hạ: nếu 16 lần đều bị loại vì quá dễ thì vẫn phải trả về 1 bàn dùng được
func _generate_any(size: int) -> MazeData:
	var maze := MazeData.new()
	maze.generate(size, size, 0.0)
	solution_count = maxi(count_solutions(maze, 2), 1)
	return maze


# ---------------------------------------------------------------------------
# Solver: ĐẾM NGHIỆM (chỉ dùng để chọn bàn — không ảnh hưởng luật khi chơi)
# ---------------------------------------------------------------------------
## Đếm số cấu hình tường thoả MỌI con số trên bàn, dừng khi đủ `cap` nghiệm.
## Trả về số nghiệm đếm được, hoặc -1 nếu vượt ngân sách nút (coi như "nhiều nghiệm").
func count_solutions(maze: MazeData, cap: int = 2) -> int:
	if maze == null:
		return 0
	_sol_cap = maxi(cap, 1)
	_sol_nodes = 0
	_sol_found = 0
	_sol_edges = []
	for ix in maze.width:
		for iy in range(1, maze.height):
			_sol_edges.append([true, Vector2i(ix, iy)])
	for ix in range(1, maze.width):
		for iy in maze.height:
			_sol_edges.append([false, Vector2i(ix, iy)])

	var cells := maxi(maze.width * maze.height, 1)
	_sol_counts = PackedInt32Array()
	_sol_counts.resize(cells)
	_sol_decided = PackedInt32Array()
	_sol_decided.resize(cells)
	_sol_total = PackedInt32Array()
	_sol_total.resize(cells)
	# Số cạnh trong board kề mỗi ô (tối đa 4) + chỉ số 2 ô của từng đoạn
	var ends: Array = []
	for edge: Array in _sol_edges:
		var is_h := bool(edge[0])
		var lattice: Vector2i = edge[1]
		var a := Vector2i(lattice.x, maxi(lattice.y - 1, 0)) if is_h else Vector2i(maxi(lattice.x - 1, 0), lattice.y)
		var b := Vector2i(lattice.x, lattice.y) if is_h else Vector2i(lattice.x, lattice.y)
		ends.append([a.y * maze.width + a.x, b.y * maze.width + b.x])
		_sol_total[a.y * maze.width + a.x] += 1
		_sol_total[b.y * maze.width + b.x] += 1

	_solve_recurse(0, ends, maze)
	return -1 if _sol_nodes > SOLVER_NODE_BUDGET else _sol_found


func _solve_recurse(index: int, ends: Array, maze: MazeData) -> void:
	if _sol_found >= _sol_cap:
		return
	_sol_nodes += 1
	if _sol_nodes > SOLVER_NODE_BUDGET:
		return
	if index >= _sol_edges.size():
		for y in maze.height:
			for x in maze.width:
				var cell := y * maze.width + x
				if _sol_counts[cell] != maze.get_wall_count(Vector2i(x, y)):
					return
		_sol_found += 1
		return

	var pair: Array = ends[index]
	var a := int(pair[0])
	var b := int(pair[1])
	for value in [false, true]:
		var delta := 1 if value else 0
		_sol_counts[a] += delta
		_sol_decided[a] += 1
		if not _cell_still_possible(a, maze):
			_sol_counts[a] -= delta
			_sol_decided[a] -= 1
			continue
		_sol_counts[b] += delta
		_sol_decided[b] += 1
		if not _cell_still_possible(b, maze):
			_sol_counts[b] -= delta
			_sol_decided[b] -= 1
			_sol_counts[a] -= delta
			_sol_decided[a] -= 1
			continue
		_solve_recurse(index + 1, ends, maze)
		_sol_counts[b] -= delta
		_sol_decided[b] -= 1
		_sol_counts[a] -= delta
		_sol_decided[a] -= 1
		if _sol_found >= _sol_cap or _sol_nodes > SOLVER_NODE_BUDGET:
			return


## Cắt tỉa: ô đã chọn xong thì phải ĐÚNG số; chưa xong thì số hiện tại + số khe còn lại
## vẫn phải phủ được con số gợi ý (counts <= clue <= counts + undecided).
func _cell_still_possible(cell: int, maze: MazeData) -> bool:
	var clue := maze.get_wall_count(Vector2i(cell % maze.width, cell / maze.width))
	var now := _sol_counts[cell]
	if now > clue:
		return false
	return now + (_sol_total[cell] - _sol_decided[cell]) >= clue


func _count_trivial_cells(maze: MazeData) -> int:
	var trivial := 0
	for y in maze.height:
		for x in maze.width:
			var count := maze.get_wall_count(Vector2i(x, y))
			if count == 0 or count == 4:
				trivial += 1
	return trivial


## Tổng số đoạn tường bên trong mê cung = Σ(số trên mọi ô) / 2
func count_true_segments(maze: MazeData) -> int:
	if maze == null:
		return 0
	var total := 0
	for ix in maze.width:
		for iy in range(1, maze.height):
			if maze.has_h_wall(ix, iy):
				total += 1
	for ix in range(1, maze.width):
		for iy in maze.height:
			if maze.has_v_wall(ix, iy):
				total += 1
	return total


# ---------------------------------------------------------------------------
# Trạng thái dựng tường (HUD + board dùng)
# ---------------------------------------------------------------------------
func built_count() -> int:
	return built.size()


func missing_count() -> int:
	return maxi(required_segments - built.size(), 0)


func is_solved() -> bool:
	return _solved


## Chip trạng thái trên HUD: "building" (ĐANG NỐI TƯỜNG) · "enough" (ĐỦ TƯỜNG) ·
## "ready" (SẴN SÀNG GỬI — cấu hình đã khớp MỌI con số)
func build_state() -> String:
	if is_configuration_valid():
		return "ready"
	if built.size() < required_segments:
		return "building"
	return "enough"


func get_hud_extra_info() -> String:
	return "TƯỜNG: %d/%d" % [built.size(), required_segments]


## Ô đã KHỚP SỐ: số tường quanh ô theo bản dựng bằng đúng con số gợi ý trên ô
## (board tô nền xanh lá nhạt — chỉ là gợi ý trực quan, xem mockup matchup_wall_builder.svg).
func is_cell_satisfied(pos: Vector2i) -> bool:
	if _maze == null:
		return false
	return _drawn_count(pos) == _maze.get_wall_count(pos)


## Thử thách mặc định của Wall Builder (§5.13): gửi đúng ngay lần đầu · trong thời gian · không gợi ý.
func default_challenges() -> Array[String]:
	return [ChallengeTypes.NO_WRONG_SUBMIT, ChallengeTypes.TIME_MAX, ChallengeTypes.NO_HINT]


# ---------------------------------------------------------------------------
# Luật bàn cờ
# ---------------------------------------------------------------------------
## Hiện SỐ TƯỜNG trên MỌI ô (kể cả số 0) — bàn này không có S/F
func get_cell_text(pos: Vector2i, maze: MazeData) -> String:
	if maze == null:
		return ""
	return str(maze.get_wall_count(pos))


## Không có nhân vật: mọi nước "di chuyển" đều bị từ chối (không mất bước, không thua)
func evaluate_move(_from_pos: Vector2i, _to_pos: Vector2i, _maze: MazeData) -> Dictionary:
	return {
		"allowed": false,
		"is_hazard": false,
		"hazard_type": "none",
		"reason": "no_movement"
	}


func shows_player() -> bool:
	return false


func wall_draw_state() -> String:
	return "built"


func revive_desc_key() -> String:
	return "STR_REVIVE_DESC_SUBMIT"


func is_wall_locked(is_h: bool, lattice: Vector2i) -> bool:
	return locked.has(_key(is_h, lattice))


## Chỉ vẽ được ở khe GIỮA 2 Ô THUỘC BOARD — viền ngoài là tường cố định (§5.13)
func can_draw_wall(is_h: bool, lattice: Vector2i, maze: MazeData) -> bool:
	if maze == null:
		return false
	if is_h:
		return lattice.y > 0 and lattice.y < maze.height
	return lattice.x > 0 and lattice.x < maze.width


func on_wall_toggled(is_h: bool, lattice: Vector2i, active: bool) -> void:
	var key := _key(is_h, lattice)
	if active:
		built[key] = true
		if not _draw_order.has(key):
			_draw_order.append(key)
	else:
		built.erase(key)
		_draw_order.erase(key)


## Thắng chỉ khi đã GỬI đúng (được set bởi GameController.submit_build)
func check_completion(_current_pos: Vector2i, _maze: MazeData, _anchor_controller: Node) -> bool:
	return _solved


func on_grid_setup(grid_view: Control, _maze: MazeData) -> void:
	# Wall Builder không có nhân vật trên bàn
	if grid_view != null and grid_view.has_method("set_player_visible"):
		grid_view.call("set_player_visible", false)


# ---------------------------------------------------------------------------
# GỬI BÀI
# ---------------------------------------------------------------------------
## Đối chiếu bản dựng với MỌI con số trên bàn.
## Trả { "solved": bool, "wrong": int } — `wrong` = số ĐOẠN còn lệch
## (tổng chênh lệch của mọi ô chia 2, vì mỗi đoạn được 2 ô kề nó đếm chung).
func evaluate_submit() -> Dictionary:
	if _maze == null:
		return { "solved": false, "wrong": 0 }
	var total_diff := 0
	for y in _maze.height:
		for x in _maze.width:
			var pos := Vector2i(x, y)
			total_diff += absi(_drawn_count(pos) - _maze.get_wall_count(pos))
	return {
		"solved": total_diff == 0,
		"wrong": int(total_diff / 2)
	}


## Cấu hình hiện tại đã khớp mọi con số chưa (dùng cho chip trạng thái HUD)
func is_configuration_valid() -> bool:
	return bool(evaluate_submit().get("solved", false))


## GameController gọi khi người chơi bấm GỬI thành công
func mark_solved() -> void:
	_solved = true


## Số cạnh CÓ TƯỜNG quanh ô theo bản dựng của người chơi (chỉ tính cạnh giữa 2 ô thuộc board)
func _drawn_count(pos: Vector2i) -> int:
	var count := 0
	if built.has(_key(true, Vector2i(pos.x, pos.y))):            # cạnh TRÊN
		count += 1
	if built.has(_key(true, Vector2i(pos.x, pos.y + 1))):        # cạnh DƯỚI
		count += 1
	if built.has(_key(false, Vector2i(pos.x, pos.y))):           # cạnh TRÁI
		count += 1
	if built.has(_key(false, Vector2i(pos.x + 1, pos.y))):       # cạnh PHẢI
		count += 1
	return count


# ---------------------------------------------------------------------------
# Undo / Hint riêng của chế độ
# ---------------------------------------------------------------------------
## Xoá đoạn tường vừa nối (bỏ qua đoạn đã bị Gợi ý khoá)
func undo_drawn_wall(anchor_controller: AnchorController) -> bool:
	if anchor_controller == null:
		return false
	var index := -1
	for i in range(_draw_order.size() - 1, -1, -1):
		if not locked.has(_draw_order[i]):
			index = i
			break
	if index < 0:
		return false
	var key: String = _draw_order[index]
	_draw_order.remove_at(index)
	built.erase(key)
	_apply_to_anchor(anchor_controller, key, false)
	return true


## Gợi ý: mở + KHOÁ 1 đoạn tường THẬT chưa dựng (đoạn này không xoá được nữa)
func hint_wall(anchor_controller: AnchorController, maze: MazeData) -> bool:
	if anchor_controller == null or maze == null:
		return false
	var candidates: Array[String] = []
	for ix in maze.width:
		for iy in range(1, maze.height):
			if maze.has_h_wall(ix, iy) and not built.has(_key(true, Vector2i(ix, iy))):
				candidates.append(_key(true, Vector2i(ix, iy)))
	for ix in range(1, maze.width):
		for iy in maze.height:
			if maze.has_v_wall(ix, iy) and not built.has(_key(false, Vector2i(ix, iy))):
				candidates.append(_key(false, Vector2i(ix, iy)))
	if candidates.is_empty():
		return false
	var chosen: String = candidates[randi() % candidates.size()]
	locked[chosen] = true
	built[chosen] = true
	_draw_order.append(chosen)
	_apply_to_anchor(anchor_controller, chosen, true)
	return true


## Ghi trạng thái 1 khe vào AnchorController (nó phát signal để board vẽ/xoá đoạn tường)
func _apply_to_anchor(anchor_controller: AnchorController, key: String, active: bool) -> void:
	var parts := key.split(",")
	if parts.size() != 3:
		return
	var is_h := parts[0] == "h"
	anchor_controller.set_suspected(is_h, Vector2i(int(parts[1]), int(parts[2])), active)


func _key(is_h: bool, lattice: Vector2i) -> String:
	return ("h,%d,%d" if is_h else "v,%d,%d") % [lattice.x, lattice.y]
