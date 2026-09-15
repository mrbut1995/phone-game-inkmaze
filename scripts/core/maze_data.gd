class_name MazeData
extends RefCounted
## ============================================================================
## Model: Dữ liệu và cấu trúc Mê Cung (thuần túy, KHÔNG phụ thuộc Scene Tree).
## - Sinh mê cung bảo đảm luôn có ít nhất 1 đường đi hợp lệ từ S đến F.
## - Mỗi ô có 4 cạnh: biên lưới luôn là tường, cạnh trong có thể mở/đóng.
## - Số hiển thị trên ô = tổng số cạnh là tường GIỮA 2 Ô THUỘC BOARD (0..4);
##   cạnh bao quanh board (viền ngoài hoặc giáp ô trống) KHÔNG được tính vào ô.
## - BOARD CÓ THỂ KHÔNG PHẢI HÌNH CHỮ NHẬT: `_cells` (cell_mask) đánh dấu ô nào
##   thuộc board (polyomino). Ô không thuộc board coi như "ngoài board":
##   mọi cạnh giáp nó tự động thành tường hiện, và không đi vào được.
## - Tường có thể được đánh dấu hiển thị trước (is_visible) theo visible_wall_ratio.
## ============================================================================

enum WallState { UNKNOWN, WALL, OPEN }

var width: int = 0
var height: int = 0
var start: Vector2i = Vector2i.ZERO
var end: Vector2i = Vector2i.ZERO
var visible_wall_ratio: float = 0.0

## Ô thuộc board: width*height bytes, index = y*width + x (1 = thuộc board)
var _cells: PackedByteArray = PackedByteArray()

## Lưới tường dọc: _v_walls[ix] (ix: 0..width) là PackedByteArray[height]
var _v_walls: Array = []
## Lưới tường ngang: _h_walls[ix] (ix: 0..width-1) là PackedByteArray[height+1]
var _h_walls: Array = []
var _v_visible: Array = []
var _h_visible: Array = []
var _wall_count: Array = []      # _wall_count[y][x]
var _tree_edges: Dictionary = {} # key cạnh thuộc cây khung (bắt buộc mở)


func generate(p_width: int, p_height: int, p_visible_ratio: float) -> void:
	width = maxi(2, p_width)
	height = maxi(2, p_height)
	visible_wall_ratio = clampf(p_visible_ratio, 0.0, 1.0)

	_init_walls()
	_pick_start_end()
	_carve_tree()
	_add_random_walls()
	_compute_wall_counts()
	_assign_visibility()

	var guard := 0
	while not is_solvable() and guard < 5:
		guard += 1
		_init_walls()
		_tree_edges.clear()
		_carve_tree()
		_add_random_walls()
		_compute_wall_counts()
		_assign_visibility()


## Khởi tạo lưới trống (chỉ có tường biên ngoài) cho Minesweeper / Sum Path / Fading Ink.
func create_empty(p_width: int, p_height: int) -> void:
	width = maxi(2, p_width)
	height = maxi(2, p_height)
	visible_wall_ratio = 0.0
	_init_walls()
	start = Vector2i(0, 0)
	end = Vector2i(width - 1, height - 1)
	_compute_wall_counts()


func set_h_wall(ix: int, iy: int, is_wall: bool) -> void:
	if ix >= 0 and ix < width and iy >= 0 and iy <= height:
		_h_walls[ix][iy] = 1 if is_wall else 0
		_compute_wall_counts()


func set_v_wall(ix: int, iy: int, is_wall: bool) -> void:
	if ix >= 0 and ix <= width and iy >= 0 and iy < height:
		_v_walls[ix][iy] = 1 if is_wall else 0
		_compute_wall_counts()


# ---------------------------------------------------------------------------
# HÌNH DẠNG BOARD (polyomino)
# ---------------------------------------------------------------------------
## Nạp mask ô thuộc board. `mask` rỗng/sai kích thước = chữ nhật đầy đủ.
func set_cell_mask(mask: PackedByteArray) -> void:
	if mask.size() == width * height:
		_cells = mask.duplicate()
	else:
		reset_cell_mask()
	_apply_mask_walls()
	_compute_wall_counts()


## Toàn bộ ô vuông đều thuộc board (màn chữ nhật)
func reset_cell_mask() -> void:
	_cells = PackedByteArray()
	_cells.resize(width * height)
	_cells.fill(1)


func get_cell_mask() -> PackedByteArray:
	if _cells.size() != width * height:
		reset_cell_mask()
	return _cells.duplicate()


func is_full_rect() -> bool:
	if _cells.size() != width * height:
		return true
	for value in _cells:
		if value == 0:
			return false
	return true


## Ô này có thuộc board không (ngoài biên hoặc ô trống đều là false)
func is_cell_active(pos: Vector2i) -> bool:
	if pos.x < 0 or pos.y < 0 or pos.x >= width or pos.y >= height:
		return false
	if _cells.size() != width * height:
		return true
	return _cells[pos.y * width + pos.x] == 1


## Mọi cạnh giáp ô NGOÀI board trở thành tường hiện (giống viền ngoài board)
func _apply_mask_walls() -> void:
	for ix in width:
		for iy in height + 1:
			if not (is_cell_active(Vector2i(ix, iy - 1)) and is_cell_active(Vector2i(ix, iy))):
				_h_walls[ix][iy] = 1
				_h_visible[ix][iy] = 1
	for ix in width + 1:
		for iy in height:
			if not (is_cell_active(Vector2i(ix - 1, iy)) and is_cell_active(Vector2i(ix, iy))):
				_v_walls[ix][iy] = 1
				_v_visible[ix][iy] = 1


# --- Khởi tạo: biên là tường, cạnh trong mở ---
func _init_walls() -> void:
	reset_cell_mask()
	_v_walls.clear()
	_h_walls.clear()
	_v_visible.clear()
	_h_visible.clear()

	for ix in width + 1:
		var col := PackedByteArray()
		col.resize(height)
		col.fill(0)
		_v_walls.append(col)
		var vis := PackedByteArray()
		vis.resize(height)
		vis.fill(0)
		_v_visible.append(vis)

	for ix in width:
		var row := PackedByteArray()
		row.resize(height + 1)
		row.fill(0)
		_h_walls.append(row)
		var vis := PackedByteArray()
		vis.resize(height + 1)
		vis.fill(0)
		_h_visible.append(vis)

	# Biên lưới luôn là tường
	for iy in height:
		_v_walls[0][iy] = 1
		_v_walls[width][iy] = 1
	for ix in width:
		_h_walls[ix][0] = 1
		_h_walls[ix][height] = 1


# --- Chọn S/F: ưu tiên 2 góc đối xứng ---
func _pick_start_end() -> void:
	var tl := Vector2i(0, 0)
	var tr := Vector2i(width - 1, 0)
	var bl := Vector2i(0, height - 1)
	var br := Vector2i(width - 1, height - 1)
	if randf() < 0.5:
		start = tl
		end = br
	else:
		start = tr
		end = bl


# --- Cây khung (recursive backtracker) bảo đảm mọi ô liên thông, có đường S->F ---
func _carve_tree() -> void:
	_tree_edges.clear()
	var visited: Dictionary = {}
	var stack: Array[Vector2i] = [start]
	visited[start] = true

	while not stack.is_empty():
		var cur: Vector2i = stack.back()
		var neighbors: Array[Vector2i] = []
		for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var nxt := cur + d
			if _in_bounds(nxt) and not visited.has(nxt):
				neighbors.append(nxt)
		neighbors.shuffle()
		if not neighbors.is_empty():
			var nxt: Vector2i = neighbors.pop_back()
			_open_edge(cur, nxt)
			_tree_edges[_edge_key(cur, nxt)] = true
			visited[nxt] = true
			stack.append(nxt)
		else:
			stack.pop_back()


func _open_edge(a: Vector2i, b: Vector2i) -> void:
	if a.x == b.x:
		var iy := maxi(a.y, b.y)
		_h_walls[a.x][iy] = 0
	else:
		var ix := maxi(a.x, b.x)
		_v_walls[ix][a.y] = 0


# --- Thêm tường ngẫu nhiên trên các cạnh KHÔNG thuộc cây khung ---
func _add_random_walls() -> void:
	const WALL_PROB := 0.5
	for ix in width:
		for iy in range(1, height):
			if not _tree_edges.has(_h_key(ix, iy)) and randf() < WALL_PROB:
				_h_walls[ix][iy] = 1
	for ix in range(1, width):
		for iy in height:
			if not _tree_edges.has(_v_key(ix, iy)) and randf() < WALL_PROB:
				_v_walls[ix][iy] = 1


# --- Tính số tường quanh từng ô (0..4) ---
# LƯU Ý: chỉ tính cạnh GIỮA 2 Ô THUỘC BOARD. Cạnh viền ngoài hoặc giáp ô trống
# (ngoài board) KHÔNG tính vào ô - xem thêm set_cell_mask().
func _compute_wall_counts() -> void:
	_wall_count.clear()
	for y in height:
		var row: Array = []
		for x in width:
			var c := 0
			if is_cell_active(Vector2i(x, y)):
				if is_cell_active(Vector2i(x, y - 1)):
					c += _h_walls[x][y]          # cạnh trên
				if is_cell_active(Vector2i(x, y + 1)):
					c += _h_walls[x][y + 1]      # cạnh dưới
				if is_cell_active(Vector2i(x - 1, y)):
					c += _v_walls[x][y]          # cạnh trái
				if is_cell_active(Vector2i(x + 1, y)):
					c += _v_walls[x + 1][y]      # cạnh phải
			row.append(c)
		_wall_count.append(row)


# --- Gán cờ hiển thị (visible) theo tỉ lệ ---
func _assign_visibility() -> void:
	for ix in width + 1:
		for iy in height:
			_v_visible[ix][iy] = 1 if (_v_walls[ix][iy] == 1 and randf() < visible_wall_ratio) else 0
	for ix in width:
		for iy in height + 1:
			_h_visible[ix][iy] = 1 if (_h_walls[ix][iy] == 1 and randf() < visible_wall_ratio) else 0


# --- API truy vấn ---
func is_in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < width and pos.y >= 0 and pos.y < height


func get_wall_count(pos: Vector2i) -> int:
	if not is_in_bounds(pos):
		return 0
	return _wall_count[pos.y][pos.x]


func has_wall(from_pos: Vector2i, to_pos: Vector2i) -> bool:
	if not is_cell_active(from_pos) or not is_cell_active(to_pos):
		return true
	if from_pos.x == to_pos.x:
		return _h_walls[from_pos.x][maxi(from_pos.y, to_pos.y)] == 1
	if from_pos.y == to_pos.y:
		return _v_walls[maxi(from_pos.x, to_pos.x)][from_pos.y] == 1
	return true


func has_h_wall(ix: int, iy: int) -> bool:
	if ix < 0 or ix >= width or iy < 0 or iy > height:
		return false
	return _h_walls[ix][iy] == 1


func has_v_wall(ix: int, iy: int) -> bool:
	if ix < 0 or ix > width or iy < 0 or iy >= height:
		return false
	return _v_walls[ix][iy] == 1


func is_h_wall_visible(ix: int, iy: int) -> bool:
	return has_h_wall(ix, iy) and _h_visible[ix][iy] == 1


func is_v_wall_visible(ix: int, iy: int) -> bool:
	return has_v_wall(ix, iy) and _v_visible[ix][iy] == 1


func reveal_wall(from_pos: Vector2i, to_pos: Vector2i) -> void:
	if from_pos.x == to_pos.x:
		var iy := maxi(from_pos.y, to_pos.y)
		if from_pos.x >= 0 and from_pos.x < width and iy >= 0 and iy <= height:
			_h_visible[from_pos.x][iy] = 1
	elif from_pos.y == to_pos.y:
		var ix := maxi(from_pos.x, to_pos.x)
		if ix >= 0 and ix <= width and from_pos.y >= 0 and from_pos.y < height:
			_v_visible[ix][from_pos.y] = 1


func get_start() -> Vector2i:
	return start


func get_end() -> Vector2i:
	return end


## Kiểm tra tồn tại đường đi từ S đến F bằng BFS
func is_solvable() -> bool:
	return not get_shortest_path(start, end).is_empty()


## Thuật toán BFS tìm đường đi ngắn nhất từ from_pos đến to_pos
func get_shortest_path(from_pos: Vector2i, to_pos: Vector2i) -> Array[Vector2i]:
	if width <= 0 or height <= 0:
		return []
	if not is_cell_active(from_pos) or not is_cell_active(to_pos):
		return []      # S/F nằm ngoài board (ô trống) => không có đường
	if from_pos == to_pos:
		return [from_pos]

	var visited: Dictionary = {}
	var parent: Dictionary = {}
	var queue: Array[Vector2i] = [from_pos]
	visited[from_pos] = true

	while not queue.is_empty():
		var cur: Vector2i = queue.pop_front()
		if cur == to_pos:
			var path: Array[Vector2i] = []
			var curr: Vector2i = to_pos
			while curr != from_pos:
				path.append(curr)
				curr = parent[curr]
			path.append(from_pos)
			path.reverse()
			return path

		for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var nxt := cur + d
			if is_in_bounds(nxt) and not visited.has(nxt) and not has_wall(cur, nxt):
				visited[nxt] = true
				parent[nxt] = cur
				queue.append(nxt)

	return []


# --- Key helpers ---
func _h_key(ix: int, iy: int) -> String:
	return "h,%d,%d" % [ix, iy]


func _v_key(ix: int, iy: int) -> String:
	return "v,%d,%d" % [ix, iy]


func _edge_key(a: Vector2i, b: Vector2i) -> String:
	if a.x == b.x:
		return _h_key(a.x, maxi(a.y, b.y))
	return _v_key(maxi(a.x, b.x), a.y)


func _in_bounds(pos: Vector2i) -> bool:
	return is_in_bounds(pos)
