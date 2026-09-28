class_name BoardTutorial
extends BoardView

## ============================================================================
## BoardTutorial: Bàn cờ dành riêng cho màn hình Tutorial (Hướng dẫn)
## Kế thừa toàn bộ View & logic của Board thật (board.gd / board.tscn):
##   - Dùng panel NinePatchRect với card_board.svg chuẩn như ván game thật
##   - Dùng MazeCell thật (cell.tscn) liền sát nhau không khe hở
##   - Dùng PlayerCursor thật (player_cursor.tscn) nhún nhảy tự nhiên
##   - Dùng hệ thống tường, neo và nét mực của game
## ============================================================================

signal cell_drag_stepped(from_cell: Vector2i, to_cell: Vector2i)
signal cell_step_attempted(next_cell: Vector2i)
signal wall_toggled(wall_key: String, active: bool)

var _tutorial_cells_data: Dictionary = {}
var _tutorial_walls_data: Array = []
var _built_walls: Dictionary = {}
var _anchors_enabled: bool = false
var _cell_dragging_active: bool = true


func _on_drag(local_pos: Vector2) -> void:
	if not _interaction_enabled:
		return
	if _anchors_enabled and _is_dragging_anchor:
		super._on_drag(local_pos)
		return

	if _dragging_player:
		var cell := _hit_cell(local_pos)
		if cell != Vector2i(-1, -1) and cell != _player_current_cell:
			stop_cursor_animation()
			cell_step_attempted.emit(cell)
			if _is_adjacent(_player_current_cell, cell):
				drag_updated.emit(cell)


func _on_release(local_pos: Vector2) -> void:
	if _anchors_enabled and _is_dragging_anchor:
		super._on_release(local_pos)
		return

	if not _has_dragged and _pressed_cell != Vector2i(-1, -1):
		var cell := _hit_cell(local_pos)
		if cell != Vector2i(-1, -1) and cell != _player_current_cell:
			stop_cursor_animation()
			cell_step_attempted.emit(cell)
			if _is_adjacent(_player_current_cell, cell):
				drag_updated.emit(cell)

	super._on_release(local_pos)


func _ready() -> void:
	super._ready()
	if not anchor_connected.is_connected(_on_tutorial_anchor_connected):
		anchor_connected.connect(_on_tutorial_anchor_connected)


## Thiết lập bàn cờ tutorial với kích thước và dữ liệu ô tuỳ chỉnh
func setup_tutorial(
	p_width: int,
	p_height: int,
	cells_text: Dictionary,       # Vector2i -> String ("S", "F", "0", "1", "")
	walls_spec: Array = [],        # Array of Dictionary: {"is_h": bool, "lattice": Vector2i, "visible": bool}
	show_cursor: bool = true,
	start_cell: Vector2i = Vector2i.ZERO,
	end_cell: Vector2i = Vector2i(-1, -1),
	with_anchors: bool = false
) -> void:
	_init_layers()
	_width = p_width
	_height = p_height
	_tutorial_cells_data = cells_text
	_tutorial_walls_data = walls_spec
	_anchors_enabled = with_anchors
	_built_walls.clear()

	# Tự động tìm S và F nếu chưa chỉ định rõ
	for pos in cells_text:
		if cells_text[pos] == "S":
			start_cell = pos
		elif cells_text[pos] == "F":
			end_cell = pos

	if end_cell == Vector2i(-1, -1):
		end_cell = Vector2i(p_width - 1, p_height - 1)

	_player_current_cell = start_cell

	# Dựng MazeData tương thích với BoardView
	var md := MazeData.new()
	md.width = _width
	md.height = _height
	md.start = start_cell
	md.end = end_cell
	md.reset_cell_mask()

	md._v_walls.clear()
	md._v_visible.clear()
	for ix in _width + 1:
		var col := PackedByteArray()
		col.resize(_height)
		col.fill(1 if (ix == 0 or ix == _width) else 0)
		md._v_walls.append(col)
		var col_vis := PackedByteArray()
		col_vis.resize(_height)
		col_vis.fill(0)
		md._v_visible.append(col_vis)

	md._h_walls.clear()
	md._h_visible.clear()
	for ix in _width:
		var col := PackedByteArray()
		col.resize(_height + 1)
		col.fill(0)
		col[0] = 1
		col[_height] = 1
		md._h_walls.append(col)
		var col_vis := PackedByteArray()
		col_vis.resize(_height + 1)
		col_vis.fill(0)
		md._h_visible.append(col_vis)

	# Gán tường theo đặc tả
	for w in walls_spec:
		var is_h: bool = w.get("is_h", false)
		var lat: Vector2i = w.get("lattice", Vector2i.ZERO)
		var vis: bool = w.get("visible", false)
		if is_h:
			if lat.x >= 0 and lat.x < _width and lat.y >= 0 and lat.y <= _height:
				md._h_walls[lat.x][lat.y] = 1
				md._h_visible[lat.x][lat.y] = 1 if vis else 0
		else:
			if lat.x >= 0 and lat.x <= _width and lat.y >= 0 and lat.y < _height:
				md._v_walls[lat.x][lat.y] = 1
				md._v_visible[lat.x][lat.y] = 1 if vis else 0

	# Tính SỐ TƯỜNG quanh từng ô — BoardView._build_cells() đọc `maze.get_wall_count()`;
	# dựng MazeData thủ công mà quên bước này ⇒ `_wall_count` rỗng ⇒ lỗi Out of bounds.
	md._compute_wall_counts()

	maze = md
	_interaction_enabled = true

	_clear_runtime_layers()
	_build_cells()

	if _anchors_enabled:
		_build_anchors()
		if _anchors_layer != null:
			_anchors_layer.visible = true
	else:
		if _anchors_layer != null:
			_anchors_layer.visible = false

	_read_metrics_from_scenes()
	_update_layout_positions()

	_build_walls()
	_build_moving_line()
	_build_drag_guide_line()

	if show_cursor:
		_player_hidden = false
		_place_cursor_at_start()
	else:
		_player_hidden = true
		if _cursor != null:
			_cursor.visible = false

	apply_pen_skin()
	_apply_metrics_scale()
	_apply_wall_width()
	_animate_board_entrance()


## Đè lại _build_cells để gán text và hình ảnh từ tutorial_cells_data
func _build_cells() -> void:
	super._build_cells()
	for y in _height:
		for x in _width:
			var pos := Vector2i(x, y)
			var cell := _cell_node(pos)
			if cell == null:
				continue
			if _tutorial_cells_data.has(pos):
				var txt: String = _tutorial_cells_data[pos]
				cell.set_text(txt)
			cell.set_focused(false)


# --- API Truy vấn Ô & Toạ độ ---

func get_cell(pos: Vector2i) -> MazeCell:
	return _cell_node(pos)


func get_all_cells() -> Array[MazeCell]:
	var out: Array[MazeCell] = []
	for node in _cell_nodes:
		if node is MazeCell:
			out.append(node as MazeCell)
	return out


func get_cell_center(pos: Vector2i) -> Vector2:
	return _cell_center(pos)


func get_cell_rect(pos: Vector2i) -> Rect2:
	var c := _cell_node(pos)
	if c != null:
		return Rect2(c.position, c.size)
	return Rect2()


func get_cell_global_rect(pos: Vector2i) -> Rect2:
	var c := _cell_node(pos)
	if c != null:
		return c.get_global_rect()
	return Rect2()


func get_cell_at_global_pos(gpos: Vector2) -> Vector2i:
	for y in _height:
		for x in _width:
			var pos := Vector2i(x, y)
			var c := _cell_node(pos)
			if c != null and c.get_global_rect().has_point(gpos):
				return pos
	return Vector2i(-1, -1)


# --- API Di chuyển & Nét vẽ đường ---

func set_path(path: Array[Vector2i]) -> void:
	set_moving_path(path)


func set_player_cell(pos: Vector2i, animate: bool = true) -> void:
	if _cursor == null:
		return
	var target_pos := _cell_center(pos) - _cursor.size * 0.5
	if animate:
		var dir := Vector2(pos - _player_current_cell)
		_cursor.run_to(target_pos, dir, 0.16)
		_spawn_ink_footstep(_cell_center(_player_current_cell))
		Sfx.play(Sfx.CELL_STEP)
	else:
		_cursor.position = target_pos
	_player_current_cell = pos


func show_wall_hit_at(from_pos: Vector2i, to_pos: Vector2i) -> void:
	show_wall_hit(from_pos, to_pos)
	if _cursor != null:
		var recoil_dir := Vector2(from_pos - to_pos)
		_cursor.play_bonk_recoil(recoil_dir)


func reveal_wall_segment(is_h: bool, lattice: Vector2i, visible: bool = true) -> void:
	var key := _lattice_key(is_h, lattice)
	var seg: WallSegment = null
	if _wall_segments.has(key):
		seg = _wall_segments[key]
	else:
		seg = _create_wall_segment(is_h, lattice, "visible" if visible else "invisible")
		if seg != null:
			_wall_segments[key] = seg

	if seg != null:
		seg.set_state("visible" if visible else "invisible")
		if visible:
			seg.animate_appear()
			Sfx.play(Sfx.WALL_MARK)


func toggle_wall(is_h: bool, lattice: Vector2i) -> bool:
	var key := _lattice_key(is_h, lattice)
	var active := false
	if _built_walls.has(key) and _built_walls[key]:
		_built_walls.erase(key)
		set_suspected_wall(is_h, lattice, false)
		active = false
	else:
		_built_walls[key] = true
		set_suspected_wall(is_h, lattice, true)
		active = true

	wall_toggled.emit(key, active)
	return active


func has_built_wall(is_h: bool, lattice: Vector2i) -> bool:
	var key := _lattice_key(is_h, lattice)
	return _built_walls.has(key) and _built_walls[key]


func get_built_wall_keys() -> Array[String]:
	var out: Array[String] = []
	for k: String in _built_walls:
		if _built_walls[k]:
			out.append(k)
	return out


func _on_tutorial_anchor_connected(corner_a: Vector2i, corner_b: Vector2i) -> void:
	if not _anchors_enabled:
		return
	var diff := corner_b - corner_a
	if absi(diff.x) + absi(diff.y) != 1:
		return

	var is_h := (corner_a.y == corner_b.y)
	var lattice: Vector2i
	if is_h:
		lattice = Vector2i(mini(corner_a.x, corner_b.x), corner_a.y)
	else:
		lattice = Vector2i(corner_a.x, mini(corner_a.y, corner_b.y))

	toggle_wall(is_h, lattice)
