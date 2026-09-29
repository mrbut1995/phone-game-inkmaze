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

const ANCHOR_CALLOUT_SCENE := preload("res://nodes/tutorials/anchor_callout.tscn")

var _tutorial_cells_data: Dictionary = {}
var _tutorial_walls_data: Array = []
var _built_walls: Dictionary = {}
var _anchors_enabled: bool = false
var _cell_dragging_active: bool = true
## Wall Builder tutorial: đoạn "tường đứt đoạn" preview + token vô hiệu timer demo cũ
var _dashed_previews: Dictionary = {}
var _wall_demo_token: int = 0
## Vòng tròn đánh số "1"/"2" tại 2 neo của thao tác kéo mẫu (Wall Builder)
var _anchor_callouts: Array[AnchorCallout] = []
## Góc neo của từng callout (song song `_anchor_callouts`) — để dời lại khi lưới đổi cỡ
var _anchor_callout_corners: Array[Vector2i] = []


## Lưới tính lại (đổi cỡ cửa sổ / đổi chỗ bàn cờ): lớp cha vẽ lại nét mực; riêng bàn
## tutorial còn phải dời các vòng đánh số neo về tâm neo MỚI.
func _update_layout_positions() -> void:
	super._update_layout_positions()
	_reposition_anchor_callouts()


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
	# Bàn dựng lại ⇒ bỏ preview cũ + vô hiệu hoá timer demo đang chờ
	_dashed_previews.clear()
	_anchor_callouts.clear()
	_wall_demo_token += 1

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
		# Tutorial không có game_mode nên mặc định vẽ "suspected"; đổi sang "built"
		# cho khớp đoạn tường người chơi tự dựng ở chế độ thật (xanh lá, nét liền).
		var seg := _segment_for(key)
		if seg != null:
			seg.set_state("built")
			seg.set_dashed(false)
			seg.set_preview_pulse(false)
		active = true

	wall_toggled.emit(key, active)
	return active


func _segment_for(key: String) -> WallSegment:
	if _suspected_lines.has(key):
		return _suspected_lines[key]
	if _wall_segments.has(key):
		return _wall_segments[key]
	return null


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


# ============================================================================
# Wall Builder tutorial: preview "tường đứt đoạn" + trình diễn rê neo dựng tường
# ============================================================================

## Hiện "tường đứt đoạn" (nét đứt hổ phách, nhấp nháy nhẹ) ở 1 cạnh — minh hoạ
## đoạn tường mà ô cần có. Trả về đoạn để bài học có thể dùng tiếp nếu muốn.
func show_dashed_wall(is_h: bool, lattice: Vector2i) -> WallSegment:
	if not _edge_touches_board(is_h, lattice):
		return null
	var key := _lattice_key(is_h, lattice)
	if _dashed_previews.has(key):
		var existing: WallSegment = _dashed_previews[key]
		if is_instance_valid(existing):
			existing.visible = true
			return existing
	var seg := _create_wall_segment(is_h, lattice, "suspected")
	if seg == null:
		return null
	seg.set_dashed(true)
	seg.set_preview_pulse(true)
	_suspected_lines[key] = seg
	_dashed_previews[key] = seg
	seg.animate_appear()
	return seg


## Xoá hết đoạn preview nét đứt
func clear_dashed_walls() -> void:
	for key: String in _dashed_previews:
		var seg: WallSegment = _dashed_previews[key]
		if is_instance_valid(seg):
			seg.queue_free()
		_suspected_lines.erase(key)
	_dashed_previews.clear()


## Huỷ trình diễn dựng tường (timer cũ tự vô hiệu qua token) + dọn neo/đường kéo
func cancel_wall_demo() -> void:
	_wall_demo_token += 1
	hide_anchor_callouts()
	if _drag_guide_line != null:
		_drag_guide_line.visible = false
	for info in _anchor_nodes:
		var anchor: MazeAnchor = info.node
		if is_instance_valid(anchor):
			anchor.set_selected(false)
	stop_cursor_animation()


## Trình diễn thao tác "rê neo để dựng tường": chọn neo A → trượt con trỏ + đường kéo
## sang neo B → đoạn tường hiện ra. Con trỏ trượt thẳng cùng nhịp với đường kéo.
func play_wall_demo_drag(is_h: bool, lattice: Vector2i, duration := 0.55) -> void:
	if _cursor == null or _drag_guide_line == null:
		return
	var corner_a := lattice
	var corner_b: Vector2i
	if is_h:
		corner_b = Vector2i(lattice.x + 1, lattice.y)
	else:
		corner_b = Vector2i(lattice.x, lattice.y + 1)
	var a_center := _anchor_center_pos(corner_a)
	var b_center := _anchor_center_pos(corner_b)
	var token := _wall_demo_token

	_cursor.stop_demo()
	_cursor.visible = true
	_cursor.position = a_center - _cursor.size * 0.5
	_set_demo_anchor_selected(corner_a, true)
	_pulse_demo_anchor(corner_a)
	Sfx.play(Sfx.ANCHOR_SNAP)
	_drag_guide_line.visible = true
	_drag_guide_line.points = PackedVector2Array([a_center, a_center])

	get_tree().create_timer(0.15).timeout.connect(func() -> void:
		if _wall_demo_token != token or not is_inside_tree():
			return
		_cursor.play_demo_slide(a_center, b_center, duration)
		var line_tw := create_tween()
		line_tw.tween_method(func(prog: float) -> void:
			_drag_guide_line.points = PackedVector2Array([a_center, a_center.lerp(b_center, prog)])
		, 0.0, 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	)

	get_tree().create_timer(0.15 + duration + 0.06).timeout.connect(func() -> void:
		if _wall_demo_token != token or not is_inside_tree():
			return
		_pulse_demo_anchor(corner_b)
		Sfx.play(Sfx.WALL_MARK)
		toggle_wall(is_h, lattice)
		_drag_guide_line.visible = false
		_set_demo_anchor_selected(corner_a, false)
	)


func _set_demo_anchor_selected(corner: Vector2i, on: bool) -> void:
	for info in _anchor_nodes:
		if info.corner == corner:
			var anchor: MazeAnchor = info.node
			anchor.set_selected(on)
			return


func _pulse_demo_anchor(corner: Vector2i) -> void:
	for info in _anchor_nodes:
		if info.corner == corner:
			(info.node as MazeAnchor).pulse()
			return


# --- Callout số "1"/"2" đánh dấu ĐIỂM CHẠM (Wall Builder tutorial) --------------

## Hiện vòng đánh số tại 2 neo: (1) neo bắt đầu kéo, (2) neo kéo tới.
func show_anchor_callouts(corner_a: Vector2i, corner_b: Vector2i) -> void:
	_ensure_anchor_callouts()
	_place_anchor_callout(0, corner_a, 1)
	_place_anchor_callout(1, corner_b, 2)


func hide_anchor_callouts() -> void:
	for callout in _anchor_callouts:
		if is_instance_valid(callout):
			callout.hide_callout()


func _ensure_anchor_callouts() -> void:
	if _anchors_layer == null:
		return
	while _anchor_callouts.size() < 2:
		var callout := ANCHOR_CALLOUT_SCENE.instantiate() as AnchorCallout
		if callout == null:
			return
		_anchors_layer.add_child(callout)
		_anchor_callouts.append(callout)
		_anchor_callout_corners.append(Vector2i(-1, -1))


func _place_anchor_callout(index: int, corner: Vector2i, number: int) -> void:
	if index >= _anchor_callouts.size():
		return
	var callout := _anchor_callouts[index]
	if not is_instance_valid(callout):
		return
	_anchor_callout_corners[index] = corner
	callout.set_number(number)
	callout.show_at(_anchor_center_pos(corner))


## Dời mọi callout đang hiện về tâm neo mới (không phát lại hiệu ứng nở)
func _reposition_anchor_callouts() -> void:
	for i in _anchor_callouts.size():
		if i >= _anchor_callout_corners.size():
			return
		var corner := _anchor_callout_corners[i]
		if corner.x == -1:
			continue
		var callout := _anchor_callouts[i]
		if is_instance_valid(callout):
			callout.move_to(_anchor_center_pos(corner))
