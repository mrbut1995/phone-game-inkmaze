class_name BoardView
extends Control
## ============================================================================
## View: Board - Thành phần View thuần túy theo chuẩn MVC:
##   - Kích thước cell/anchor/tường/đường/cursor đọc trực tiếp từ scene gốc
##     (cell.tscn, anchor.tscn, wall_segment.tscn...) nên chỉnh .tscn là ăn ngay.
##   - Căn giữa toàn bộ bàn cờ trên Board Panel nếu còn khoảng trống.
##   - Các ô liền sát nhau 100% không có khe hở.
## ============================================================================

signal cell_pressed(pos: Vector2i)
signal drag_updated(pos: Vector2i)
signal anchor_tapped(anchor_id: int)
signal anchor_connected(corner_a: Vector2i, corner_b: Vector2i)

const CELL_SCENE := preload("res://nodes/game/cell.tscn")
const ANCHOR_SCENE := preload("res://nodes/game/anchor.tscn")
const WALL_SEGMENT_SCENE := preload("res://nodes/game/wall_segment.tscn")
const MOVING_LINE_SCENE := preload("res://nodes/game/moving_line.tscn")
const HISTORY_LINE_SCENE := preload("res://nodes/game/history_line.tscn")
const PLAYER_CURSOR_SCENE := preload("res://nodes/game/player_cursor.tscn")
const CRASH_SFX_SCENE := preload("res://nodes/sfx/crash.tscn")
const MINE_SFX_SCENE := preload("res://nodes/sfx/mine_explosion.tscn")

const GLOW_LINE_SHADER := preload("res://shaders/line_glowing_shader.gdshader")

## Fallback an toàn khi không đọc được scene gốc (giá trị thật nằm trong .tscn)
const FALLBACK_CELL_SIZE := 176.0
const FALLBACK_ANCHOR_SIZE := 40.0
const FALLBACK_WALL_WIDTH := 11.0
const FALLBACK_CURSOR_SIZE := 132.0
const FALLBACK_MOVING_LINE_WIDTH := 40.0
const FALLBACK_FONT_SIZE := 56.0

## Mép chừa thêm bên trong phần GIẤY VẼ THẬT (px) - để ô không chạm viền giấy
const BOARD_PADDING := 12.0
## Nhỏ nhất có thể co (0.24 * 176 ≈ 42px) -> board 20x20 vẫn nằm gọn
const MIN_FIT_SCALE := 0.24
## Kích thước tối thiểu để còn nhìn thấy rõ
const MIN_WALL_WIDTH := 3.0
const MIN_ANCHOR_SIZE := 14.0
const MIN_CURSOR_SIZE := 18.0
const MIN_FONT_SIZE := 12

var maze: MazeData = null
var game_mode: BaseGameMode = null

var _width := 0
var _height := 0
var _step := FALLBACK_CELL_SIZE
var _cell_size := FALLBACK_CELL_SIZE
var _anchor_size := FALLBACK_ANCHOR_SIZE
var _wall_width := FALLBACK_WALL_WIDTH
var _cursor_size := FALLBACK_CURSOR_SIZE
var _moving_line_width := FALLBACK_MOVING_LINE_WIDTH
var _history_line_width := FALLBACK_MOVING_LINE_WIDTH
var _base_font_size := FALLBACK_FONT_SIZE
var _anchor_hit_radius := FALLBACK_ANCHOR_SIZE * 0.75
## Tỉ lệ co board cho vừa panel (1.0 = board nhỏ, giữ nguyên cỡ gốc)
var _fit_scale := 1.0
## Vùng GIẤY VẼ THẬT bên trong node Panel (art card_board.svg có lề đổ bóng)
var _panel_insets := Vector4.ZERO      # left, top, right, bottom (px trong node Panel)

var _cell_nodes: Array = []        # MazeCell
var _cell_rects: Array[Rect2] = []
var _col_edge_x: Array = []
var _row_edge_y: Array = []
var _col_center_x: Array = []
var _row_center_y: Array = []

var _anchor_nodes: Array = []
var _wall_segments: Dictionary = {}     # lattice key -> wall_segment
var _suspected_lines: Dictionary = {}   # lattice key -> wall_segment
var _history_lines: Dictionary = {}     # cell-edge key -> history Line2D
var _moving_line: Line2D = null
var _drag_guide_line: Line2D = null
var _cursor: Control = null
## Ngòi bút đang dùng (PenSkin) — quyết định icon con trỏ + màu/chất liệu nét mực
var _pen_id := PenSkin.DEFAULT_PEN

var _interaction_enabled := true

# Player drag movement
var _dragging_player := false
var _player_current_cell := Vector2i.ZERO
var _drag_draw_sfx_on := false    # Đã phát tiếng miết bút trong lượt kéo này chưa

# Cell tap tracking
var _pressed_cell := Vector2i(-1, -1)
var _press_start_pos := Vector2.ZERO
var _has_dragged := false

# Anchor dragging
var _is_dragging_anchor := false
var _drag_source_anchor_id := -1
var _drag_source_anchor_corner := Vector2i(-1, -1)
var _hover_target_anchor_id := -1

# Shake tracking
var _shake_tween: Tween = null
var _original_position := Vector2.ZERO
var _is_shaking := false

# Container Layers
var _cells_layer: Control = null
var _walls_layer: Control = null
var _anchors_layer: Control = null
var _lines_layer: Control = null
var _markers_layer: Control = null


func _ready() -> void:
	_init_layers()
	_connect_skin_signal()


## Người chơi đổi bút ở Cửa hàng -> đổi luôn con trỏ + nét mực đang hiển thị
func _connect_skin_signal() -> void:
	var themes := get_node_or_null("/root/ThemeManager")
	if themes == null or not themes.has_signal("skin_changed"):
		return
	if not themes.is_connected("skin_changed", _on_skin_changed):
		themes.connect("skin_changed", _on_skin_changed)


func _on_skin_changed(_theme_id: String, _pen_id: String) -> void:
	apply_pen_skin()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		if maze != null and _cell_nodes.size() > 0:
			_update_layout_positions()


func _init_layers() -> void:
	if _cells_layer != null:
		return

	_cells_layer = Control.new()
	_cells_layer.name = "Cells"
	_cells_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_cells_layer)

	_lines_layer = Control.new()
	_lines_layer.name = "Lines"
	_lines_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_lines_layer)

	_walls_layer = Control.new()
	_walls_layer.name = "Walls"
	_walls_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_walls_layer)

	_anchors_layer = Control.new()
	_anchors_layer.name = "Anchors"
	_anchors_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_anchors_layer)

	_markers_layer = Control.new()
	_markers_layer.name = "Markers"
	_markers_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_markers_layer)


# ============================================================================
# Thiết lập maze & mode (gọi từ Controller)
# ============================================================================
func setup_maze(p_maze: MazeData, p_mode: BaseGameMode = null) -> void:
	_init_layers()
	maze = p_maze
	game_mode = p_mode if p_mode != null else DungeonGameMode.new()
	_width = maze.width
	_height = maze.height
	_interaction_enabled = true
	_dragging_player = false
	_pressed_cell = Vector2i(-1, -1)
	_press_start_pos = Vector2.ZERO
	_has_dragged = false
	_is_dragging_anchor = false
	_drag_source_anchor_id = -1
	_hover_target_anchor_id = -1
	_player_current_cell = maze.get_start()

	if _is_shaking and _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()
		position = _original_position
		_is_shaking = false

	_clear_runtime_layers()

	# Dựng node trước để lấy đúng kích thước từ scene gốc, rồi mới tính layout
	_build_cells()
	_build_anchors()
	_read_metrics_from_scenes()
	_update_layout_positions()

	_build_walls()
	_build_moving_line()
	_build_drag_guide_line()
	_place_cursor_at_start()
	apply_pen_skin()
	# Sau khi đã có đủ node: áp lại tỉ lệ vừa khít (tường/cursor/line...)
	_apply_metrics_scale()
	_apply_wall_width()
	_animate_board_entrance()


## Áp skin NGÒI BÚT đang dùng (ShopManager.equipped_pen):
##   · con trỏ người chơi -> icon player_cursor_*.svg tương ứng
##   · moving_line -> màu mực + chất liệu (bề rộng/đầu nét/nét đứt/quầng sáng)
##   · vệt bước chân mực -> đúng icon + màu mực của bút
func apply_pen_skin() -> void:
	_pen_id = PenSkin.equipped_id()
	if _cursor != null and _cursor.has_method("apply_pen"):
		_cursor.call("apply_pen", _pen_id)
	if _moving_line != null and _moving_line.has_method("apply_pen"):
		_moving_line.call("apply_pen", _pen_id)
	_apply_wall_width()


func _animate_board_entrance() -> void:
	if DisplayServer.get_name() == "headless":
		return
	for y in _height:
		for x in _width:
			var cell: MazeCell = _cell_node(Vector2i(x, y))
			if cell == null:
				continue
			cell.pivot_offset = cell.size * 0.5
			cell.scale = Vector2(0.65, 0.65)
			cell.modulate.a = 0.0
			var delay := float(x + y) * 0.015
			var tw := cell.create_tween().set_parallel(true)
			if delay > 0.0:
				tw.tween_interval(delay)
			tw.tween_property(cell, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(cell, "modulate:a", 1.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	for info in _anchor_nodes:
		var anchor: Control = info.node
		if anchor == null:
			continue
		anchor.pivot_offset = anchor.size * 0.5
		anchor.scale = Vector2.ZERO
		var corner: Vector2i = info.corner
		var delay := float(corner.x + corner.y) * 0.015 + 0.04
		var tw_a := anchor.create_tween()
		if delay > 0.0:
			tw_a.tween_interval(delay)
		tw_a.tween_property(anchor, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)



func _cell_index(x: int, y: int) -> int:
	return x + y * _width


# ============================================================================
# Metrics: đọc trực tiếp từ scene gốc => .tscn luôn là source of truth
# ============================================================================
func _read_metrics_from_scenes() -> void:
	for node in _cell_nodes:
		if node == null:
			continue
		var cell_sz: Vector2 = (node as MazeCell).size
		if cell_sz.x > 0.0 and cell_sz.y > 0.0:
			_cell_size = cell_sz.x
		# Cỡ chữ số trên ô (LabelSettings của cell) để scale theo từng cỡ board
		var label: Label = (node as MazeCell).get_node_or_null("Sprite/Label")
		if label != null and label.label_settings != null and label.label_settings.font_size > 0:
			_base_font_size = float(label.label_settings.font_size)
		break

	if not _anchor_nodes.is_empty():
		var anchor_sz: Vector2 = _anchor_nodes[0].node.size
		if anchor_sz.x > 0.0:
			_anchor_size = anchor_sz.x

	_wall_width = _read_scene_line_width(WALL_SEGMENT_SCENE, FALLBACK_WALL_WIDTH)
	_moving_line_width = _read_scene_line_width(MOVING_LINE_SCENE, FALLBACK_MOVING_LINE_WIDTH)
	_history_line_width = _read_scene_line_width(HISTORY_LINE_SCENE, FALLBACK_MOVING_LINE_WIDTH)
	_cursor_size = _read_scene_size(PLAYER_CURSOR_SCENE, FALLBACK_CURSOR_SIZE)

	_step = _cell_size
	# Bán kính bắt dính anchor suy ra từ kích thước anchor (không hard-code riêng)
	_anchor_hit_radius = _anchor_size * 0.75
	_read_panel_insets()


## Đo vùng GIẤY VẼ THẬT của art Panel (card_board.svg có lề đổ bóng quanh mép)
## bằng alpha bbox trên ảnh thu nhỏ -> canh lưới vào đúng phần giấy, không chạm viền.
func _read_panel_insets() -> void:
	_panel_insets = Vector4.ZERO
	var panel: TextureRect = get_node_or_null("Panel") as TextureRect
	if panel == null or panel.texture == null:
		return
	var img := panel.texture.get_image()
	if img == null or img.get_width() <= 0 or img.get_height() <= 0:
		return

	const PROBE := 64
	var probe := img.duplicate() as Image
	probe.resize(PROBE, PROBE, Image.INTERPOLATE_BILINEAR)
	var min_x := PROBE
	var min_y := PROBE
	var max_x := -1
	var max_y := -1
	for y in PROBE:
		for x in PROBE:
			if probe.get_pixel(x, y).a > 0.05:
				min_x = mini(min_x, x)
				max_x = maxi(max_x, x)
				min_y = mini(min_y, y)
				max_y = maxi(max_y, y)
	if max_x < min_x or max_y < min_y:
		return

	var sx := float(img.get_width()) / float(PROBE)
	var sy := float(img.get_height()) / float(PROBE)
	_panel_insets = Vector4(min_x * sx, min_y * sy, max_x * sx, max_y * sy)


## Vùng giấy vẽ thật (toạ độ cục bộ của Board) - dùng để canh lưới + cho test
func panel_inner_rect() -> Rect2:
	var panel: Control = get_node_or_null("Panel") as Control
	if panel == null:
		return Rect2(Vector2.ZERO, size)
	var inner_pos := panel.position + Vector2(_panel_insets.x, _panel_insets.y)
	var inner_size := Vector2(_panel_insets.z - _panel_insets.x, _panel_insets.w - _panel_insets.y)
	if inner_size.x <= 0.0 or inner_size.y <= 0.0:
		return Rect2(panel.position, panel.size)
	return Rect2(inner_pos, inner_size)


func _read_scene_size(scene: PackedScene, fallback: float) -> float:
	var probe := scene.instantiate() as Control
	if probe == null:
		return fallback
	var side := probe.size.x
	probe.free()
	return side if side > 0.0 else fallback


func _read_scene_line_width(scene: PackedScene, fallback: float) -> float:
	var probe := scene.instantiate() as Line2D
	if probe == null:
		return fallback
	var w := probe.width
	probe.free()
	return w if w > 0.0 else fallback


# ============================================================================
# Layout: Kích cỡ cell/anchor/tường... lấy từ scene gốc (_read_metrics_from_scenes)
#         => Chỉnh sửa trực tiếp trong .tscn là Board tự cập nhật theo.
# ============================================================================
func _compute_layout() -> void:
	# Vùng giấy vẽ thật của panel (đã trừ lề đổ bóng của art)
	var inner := panel_inner_rect()

	# --- Co board cho VỪA KHÍT phần giấy, CHỪA MÉP ---
	# Board nhỏ (<= 5x5) giữ nguyên cỡ ô gốc; board lớn (11x11, 20x20...) tự thu nhỏ.
	# Trừ thêm phần "nhô ra" của tường/anchor vì chúng vẽ canh tâm ở mép lưới.
	var available_w := maxf(inner.size.x - BOARD_PADDING * 2.0, 1.0)
	var available_h := maxf(inner.size.y - BOARD_PADDING * 2.0, 1.0)
	var overhang := maxf(_anchor_size, _wall_width)
	var denom_w := _cell_size * float(maxi(_width, 1)) + overhang
	var denom_h := _cell_size * float(maxi(_height, 1)) + overhang
	var fit_scale := minf(available_w / maxf(denom_w, 1.0), available_h / maxf(denom_h, 1.0))
	_fit_scale = clampf(fit_scale, MIN_FIT_SCALE, 1.0)
	_step = _cell_size * _fit_scale
	_apply_metrics_scale()

	# Kích thước toàn bộ lưới cell
	var total_w := float(_width) * _step
	var total_h := float(_height) * _step

	# Căn giữa lưới vào vùng giấy vẽ thật
	var inner_center := inner.position + inner.size * 0.5
	var margin_x := inner_center.x - total_w * 0.5
	var margin_y := inner_center.y - total_h * 0.5

	_col_edge_x.clear()
	for ix in _width + 1:
		_col_edge_x.append(margin_x + ix * _step)

	_row_edge_y.clear()
	for iy in _height + 1:
		_row_edge_y.append(margin_y + iy * _step)

	_col_center_x.clear()
	for ix in _width:
		_col_center_x.append(margin_x + (ix + 0.5) * _step)

	_row_center_y.clear()
	for iy in _height:
		_row_center_y.append(margin_y + (iy + 0.5) * _step)


# ============================================================================
# Co giãn theo tỉ lệ vừa khít: cell / anchor / cursor / bề rộng tường / cỡ chữ
# ============================================================================
func _apply_metrics_scale() -> void:
	var cell_side := _step
	for node in _cell_nodes:
		if node == null:
			continue
		var cell: MazeCell = node
		cell.size = Vector2(cell_side, cell_side)
		cell.pivot_offset = cell.size * 0.5
		cell.set_font_size(_scaled_font_size())

	var anchor_side := maxf(_anchor_size * _fit_scale, MIN_ANCHOR_SIZE)
	for info in _anchor_nodes:
		var anchor: Control = info.node
		anchor.size = Vector2(anchor_side, anchor_side)
		anchor.pivot_offset = anchor.size * 0.5
	_anchor_hit_radius = maxf(_anchor_size * 0.75 * _fit_scale, anchor_side * 0.5)

	_apply_wall_width()

	if _cursor != null:
		var cursor_side := maxf(_cursor_size * _fit_scale, MIN_CURSOR_SIZE)
		_cursor.size = Vector2(cursor_side, cursor_side)
		_cursor.pivot_offset = _cursor.size * 0.5


func _scaled_wall_width() -> float:
	return maxf(_wall_width * _fit_scale, MIN_WALL_WIDTH)


func _scaled_font_size() -> int:
	return maxi(int(round(_base_font_size * _fit_scale)), MIN_FONT_SIZE)


func _apply_wall_width() -> void:
	var width := _scaled_wall_width()
	for key in _wall_segments:
		(_wall_segments[key] as Line2D).width = width
	for key in _suspected_lines:
		(_suspected_lines[key] as Line2D).width = width
	for key in _history_lines:
		(_history_lines[key] as Line2D).width = width
	if _drag_guide_line != null:
		_drag_guide_line.width = width
	if _moving_line != null:
		var line_width := maxf(_moving_line_width * _fit_scale, MIN_WALL_WIDTH)
		if _moving_line.has_method("set_base_width"):
			_moving_line.call("set_base_width", line_width)
		else:
			_moving_line.width = line_width


func _update_layout_positions() -> void:
	_compute_layout()

	# Cập nhật toạ độ và kích cỡ từng cell (ô ngoài board không có node)
	for y in _height:
		for x in _width:
			var idx := _cell_index(x, y)
			var cell := _cell_node(Vector2i(x, y))
			if cell == null or idx < 0 or idx >= _cell_rects.size():
				continue
			cell.position = Vector2(_col_edge_x[x], _row_edge_y[y])
			cell.pivot_offset = cell.size * 0.5
			_cell_rects[idx] = Rect2(cell.position, cell.size)

	# Cập nhật vị trí các anchor
	for info in _anchor_nodes:
		var a: Control = info.node
		var corner: Vector2i = info.corner
		var pos := Vector2(_col_edge_x[corner.x], _row_edge_y[corner.y])
		a.pivot_offset = a.size * 0.5
		a.position = pos - a.size * 0.5

	# Cập nhật toạ độ các wall segments
	for key: String in _wall_segments:
		var seg: WallSegment = _wall_segments[key]
		var parts: PackedStringArray = key.split(",")
		var is_h: bool = parts[0] == "h"
		var lattice := Vector2i(int(parts[1]), int(parts[2]))
		var pts := _edge_points(is_h, lattice)
		seg.set_wall_points(pts[0], pts[1])

	# Cập nhật toạ độ các suspected lines
	for key: String in _suspected_lines:
		var seg: WallSegment = _suspected_lines[key]
		var parts: PackedStringArray = key.split(",")
		var is_h: bool = parts[0] == "h"
		var lattice := Vector2i(int(parts[1]), int(parts[2]))
		var pts := _edge_points(is_h, lattice)
		seg.set_wall_points(pts[0], pts[1])

	# Cập nhật toạ độ player cursor
	if _cursor != null:
		_cursor.position = _cell_center(_player_current_cell) - _cursor.size * 0.5


func _build_cells() -> void:
	# Board có thể là polyomino: ô ngoài board KHÔNG có node -> mảng giữ null
	_cell_nodes.resize(_width * _height)
	_cell_rects.resize(_width * _height)
	for y in _height:
		for x in _width:
			var pos := Vector2i(x, y)
			if maze != null and not maze.is_cell_active(pos):
				continue
			var c: MazeCell = CELL_SCENE.instantiate()
			c.set_anchors_preset(Control.PRESET_TOP_LEFT)
			# Không set size: kích thước lấy nguyên từ cell.tscn
			c.grid_pos = pos
			_cells_layer.add_child(c)
			_cell_nodes[_cell_index(x, y)] = c
			_cell_rects[_cell_index(x, y)] = Rect2(c.position, c.size)

			var text := ""
			if game_mode != null:
				text = game_mode.get_cell_text(pos, maze)
			else:
				if pos == maze.get_start():
					text = "S"
				elif pos == maze.get_end():
					text = "F"
				else:
					text = str(maze.get_wall_count(pos))

			c.set_text(text)
			_sync_bomb_marker(c, pos)
			c.set_focused(false)


## Đồng bộ biểu tượng Bomb cho ô (mode nào có API has_bomb_marker — xem MinesweeperPathGameMode).
func _sync_bomb_marker(cell_node: MazeCell, pos: Vector2i) -> void:
	if cell_node == null:
		return
	var marked := game_mode != null \
		and game_mode.has_method("has_bomb_marker") \
		and bool(game_mode.call("has_bomb_marker", pos))
	cell_node.set_bomb(marked)


func _build_walls() -> void:
	_wall_segments.clear()
	for ix in _width:
		for iy in _height + 1:
			if not _edge_touches_board(true, Vector2i(ix, iy)):
				continue      # cạnh giữa 2 ô ngoài board -> không vẽ
			if maze.has_h_wall(ix, iy):
				var seg := _create_wall_segment(true, Vector2i(ix, iy),
					"visible" if maze.is_h_wall_visible(ix, iy) else "invisible")
				_wall_segments[_lattice_key(true, Vector2i(ix, iy))] = seg
	for ix in _width + 1:
		for iy in _height:
			if not _edge_touches_board(false, Vector2i(ix, iy)):
				continue
			if maze.has_v_wall(ix, iy):
				var seg := _create_wall_segment(false, Vector2i(ix, iy),
					"visible" if maze.is_v_wall_visible(ix, iy) else "invisible")
				_wall_segments[_lattice_key(false, Vector2i(ix, iy))] = seg


func _create_wall_segment(is_h: bool, lattice: Vector2i, state: String) -> WallSegment:
	var seg: WallSegment = WALL_SEGMENT_SCENE.instantiate()
	var pts := _edge_points(is_h, lattice)
	_walls_layer.add_child(seg)
	seg.set_wall_points(pts[0], pts[1])
	# Bề rộng tường co theo cỡ board (board càng nhiều ô thì nét càng mảnh)
	seg.width = _scaled_wall_width()
	seg.set_meta("base_state", state)
	seg.set_state(state)
	return seg


func _edge_points(is_h: bool, lattice: Vector2i) -> PackedVector2Array:
	if is_h:
		var p1 := Vector2(_col_edge_x[lattice.x], _row_edge_y[lattice.y])
		var p2 := Vector2(_col_edge_x[lattice.x + 1], _row_edge_y[lattice.y])
		return PackedVector2Array([p1, p2])
	var p1 := Vector2(_col_edge_x[lattice.x], _row_edge_y[lattice.y])
	var p2 := Vector2(_col_edge_x[lattice.x], _row_edge_y[lattice.y + 1])
	return PackedVector2Array([p1, p2])


func _build_anchors() -> void:
	_anchor_nodes.clear()
	var id := 0
	for iy in _height + 1:
		for ix in _width + 1:
			# Chỉ tạo anchor ở góc có dính ít nhất 1 ô thuộc board
			if not _corner_touches_board(ix, iy):
				continue
			var a: Control = ANCHOR_SCENE.instantiate()
			a.set_anchors_preset(Control.PRESET_TOP_LEFT)
			# Không set size/position: kích thước lấy từ anchor.tscn,
			# vị trí do _update_layout_positions() căn theo lưới
			a.set("anchor_id", id)
			_anchors_layer.add_child(a)
			_anchor_nodes.append({ "node": a, "corner": Vector2i(ix, iy) })
			id += 1


# ============================================================================
# Hình dạng board (polyomino): vài tiện ích dùng lại nhiều lần
# ============================================================================
## Node của 1 ô (null nếu ô đó ngoài board)
func _cell_node(pos: Vector2i) -> MazeCell:
	if maze != null and not maze.is_cell_active(pos):
		return null
	var idx := _cell_index(pos.x, pos.y)
	if idx < 0 or idx >= _cell_nodes.size():
		return null
	return _cell_nodes[idx]


## Cạnh này có dính ít nhất 1 ô thuộc board không
func _edge_touches_board(is_h: bool, lattice: Vector2i) -> bool:
	if maze == null:
		return true
	if is_h:
		var above := maze.is_cell_active(Vector2i(lattice.x, lattice.y - 1))
		var below := maze.is_cell_active(Vector2i(lattice.x, lattice.y))
		return above or below
	var left := maze.is_cell_active(Vector2i(lattice.x - 1, lattice.y))
	var right := maze.is_cell_active(Vector2i(lattice.x, lattice.y))
	return left or right


## Góc lưới này có dính ít nhất 1 ô thuộc board không
func _corner_touches_board(ix: int, iy: int) -> bool:
	if maze == null:
		return true
	for dy in [-1, 0]:
		for dx in [-1, 0]:
			if maze.is_cell_active(Vector2i(ix + dx, iy + dy)):
				return true
	return false


func _build_moving_line() -> void:
	_moving_line = MOVING_LINE_SCENE.instantiate()
	_lines_layer.add_child(_moving_line)
	_moving_line.position = Vector2.ZERO
	# width/default_color lấy nguyên từ moving_line.tscn
	_moving_line.points = PackedVector2Array()


func _build_drag_guide_line() -> void:
	_drag_guide_line = MOVING_LINE_SCENE.instantiate()
	_lines_layer.add_child(_drag_guide_line)
	_drag_guide_line.position = Vector2.ZERO
	_drag_guide_line.width = _wall_width
	_drag_guide_line.default_color = Color(0.77, 0.52, 0.23, 0.75)
	_drag_guide_line.visible = false


func _place_cursor_at_start() -> void:
	if _cursor == null:
		_cursor = PLAYER_CURSOR_SCENE.instantiate()
		_markers_layer.add_child(_cursor)
		_cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Kích thước cursor lấy nguyên từ player_cursor.tscn
	_cursor.pivot_offset = _cursor.size * 0.5
	var target_pos := _cell_center(maze.get_start()) - _cursor.size * 0.5
	_cursor.position = target_pos
	_cursor.visible = true
	_player_current_cell = maze.get_start()
	# SFX: bước vào ô xuất phát S khi bắt đầu mỗi floor
	Sfx.play(Sfx.STAIRS_ENTER)
	if DisplayServer.get_name() != "headless" and _cursor.has_method("play_spawn_drop"):
		_cursor.call("play_spawn_drop", target_pos)


func _clear_runtime_layers() -> void:
	for layer in [_cells_layer, _walls_layer, _anchors_layer, _lines_layer, _markers_layer]:
		if layer == null:
			continue
		for child in layer.get_children():
			child.queue_free()
	_cell_nodes.clear()
	_cell_rects.clear()
	_anchor_nodes.clear()
	_wall_segments.clear()
	_suspected_lines.clear()
	_history_lines.clear()
	_moving_line = null
	_drag_guide_line = null
	_cursor = null


# ============================================================================
# API cho Controller gọi (Render & Animation)
# ============================================================================
func move_cursor_to(pos: Vector2i) -> void:
	if _cursor == null or maze == null:
		return
	var prev_cell := _player_current_cell
	_player_current_cell = pos
	var from_center := _cell_center(prev_cell)
	var target_center := _cell_center(pos)
	var target_pos := target_center - _cursor.size * 0.5
	var move_dir := (Vector2(pos) - Vector2(prev_cell)).normalized()

	# Hiệu ứng vệt chân mực lan nhẹ khi cất bước
	_spawn_ink_footstep(from_center)

	# SFX: chấm bút chì khi vào tâm ô mới; thêm tiếng "vào cầu thang" khi tới ô F
	Sfx.play(Sfx.CELL_STEP)
	if pos == maze.get_end():
		Sfx.play(Sfx.STAIRS_ENTER)
		if _cursor != null and _cursor.has_method("play_celebration"):
			_cursor.call("play_celebration")

	# Chạy animation bước nhảy (Hop / Squash & Stretch / Tilt)
	if _cursor.has_method("run_to"):
		_cursor.call("run_to", target_pos, move_dir, 0.16)
	else:
		var tw := create_tween().set_parallel(true)
		tw.tween_property(_cursor, "position", target_pos, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var c_idx := _cell_index(pos.x, pos.y)
	if c_idx >= 0 and c_idx < _cell_nodes.size():
		var cell_node: MazeCell = _cell_nodes[c_idx]
		cell_node.pulse()


func _spawn_ink_footstep(pos: Vector2) -> void:
	if _markers_layer == null:
		return
	var ripple := Control.new()
	ripple.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ripple.position = pos - Vector2(18, 18)
	ripple.size = Vector2(36, 36)
	ripple.pivot_offset = Vector2(18, 18)

	var tex_rect := TextureRect.new()
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	var cursor_tex := PenSkin.cursor_texture(_pen_id)
	tex_rect.texture = cursor_tex if cursor_tex != null \
		else preload("res://assets/images/game/player_cursor.svg")
	var ink := PenSkin.ink_color(_pen_id)
	tex_rect.modulate = Color(ink.r, ink.g, ink.b, 0.45)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ripple.add_child(tex_rect)
	_markers_layer.add_child(ripple)

	var tw := create_tween().set_parallel(true)
	tw.tween_property(ripple, "scale", Vector2(1.9, 1.9), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(ripple, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(ripple.queue_free)


func set_moving_path(path: Array[Vector2i]) -> void:
	if _moving_line == null:
		return
	var pts := PackedVector2Array()
	for p in path:
		pts.append(_cell_center(p))
	if _moving_line.has_method("set_stroke"):
		_moving_line.call("set_stroke", pts)
	else:
		_moving_line.points = pts
	_set_path_focus(path)


func reset_to_start() -> void:
	if maze == null or _cursor == null:
		return
	_player_current_cell = maze.get_start()
	var target_pos := _cell_center(maze.get_start()) - _cursor.size * 0.5

	var tw := create_tween()
	tw.tween_property(_cursor, "position", target_pos, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	set_moving_path([maze.get_start()])


func show_history_edge(a: Vector2i, b: Vector2i) -> void:
	var key := _cell_edge_key(a, b)
	if _history_lines.has(key):
		return
	var line: Line2D = HISTORY_LINE_SCENE.instantiate()
	_lines_layer.add_child(line)
	line.position = Vector2.ZERO
	line.points = PackedVector2Array([_cell_center(a), _cell_center(b)])
	# Vệt bút mờ cũ: cùng MÀU + chất liệu ngòi bút (mờ hơn nét đang đi)
	InkStroke.style_plain(line, _pen_id, _scaled_wall_width(), 0.55)
	_history_lines[key] = line


func show_wall_hit(from_pos: Vector2i, to_pos: Vector2i) -> void:
	# SFX: gãy ngòi bút chì khi đâm trúng tường vô hình
	Sfx.play(Sfx.WALL_HIT)
	var is_h := (from_pos.x == to_pos.x)
	var lattice: Vector2i
	if is_h:
		lattice = Vector2i(from_pos.x, maxi(from_pos.y, to_pos.y))
	else:
		lattice = Vector2i(maxi(from_pos.x, to_pos.x), from_pos.y)

	var key := _lattice_key(is_h, lattice)

	var seg: WallSegment = null
	if _wall_segments.has(key):
		seg = _wall_segments[key]
		seg.flash_hit_then_stay_visible()
	else:
		seg = _create_wall_segment(is_h, lattice, "hit")
		_wall_segments[key] = seg
		seg.flash_hit_then_stay_visible()

	var pts := _edge_points(is_h, lattice)
	var wall_center: Vector2 = (pts[0] + pts[1]) * 0.5

	var crash: Control = CRASH_SFX_SCENE.instantiate()
	_markers_layer.add_child(crash)
	crash.position = wall_center - crash.size * 0.5
	crash.scale = Vector2.ZERO

	var tw_crash := create_tween()
	tw_crash.tween_property(crash, "scale", Vector2(1.3, 1.3), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw_crash.tween_property(crash, "scale", Vector2.ONE, 0.06)
	tw_crash.tween_interval(0.45)
	tw_crash.tween_property(crash, "modulate:a", 0.0, 0.22)
	tw_crash.tween_callback(crash.queue_free)

	# Tác động lực giật nảy lên con trỏ người chơi (Bonk recoil)
	if _cursor != null and _cursor.has_method("play_bonk_recoil"):
		var recoil_dir := (Vector2(from_pos) - Vector2(to_pos)).normalized()
		_cursor.call("play_bonk_recoil", recoil_dir)

	_play_grid_shake()


func show_mine_hit(pos: Vector2i) -> void:
	var c_idx := _cell_index(pos.x, pos.y)
	if c_idx >= 0 and c_idx < _cell_nodes.size():
		var cell_node: MazeCell = _cell_nodes[c_idx]
		if cell_node != null:
			# Giữ nguyên con số trên ô, chỉ đánh dấu quả mìn đã nổ
			cell_node.set_bomb(true)
			if cell_node.has_method("play_shudder"):
				cell_node.call("play_shudder")

	if _cursor != null and _cursor.has_method("play_bonk_recoil"):
		_cursor.call("play_bonk_recoil", Vector2(0, -1))

	var center := _cell_center(pos)
	var mine_sfx: Control = MINE_SFX_SCENE.instantiate()
	_markers_layer.add_child(mine_sfx)
	mine_sfx.position = center - mine_sfx.size * 0.5
	mine_sfx.scale = Vector2.ZERO

	var tw := create_tween()
	tw.tween_property(mine_sfx, "scale", Vector2(1.4, 1.4), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(mine_sfx, "scale", Vector2.ONE, 0.08)
	tw.tween_interval(0.5)
	tw.tween_property(mine_sfx, "modulate:a", 0.0, 0.2)
	tw.tween_callback(mine_sfx.queue_free)

	_play_grid_shake()


func pulse_cell(pos: Vector2i) -> void:
	var node := _cell_node(pos)
	if node != null:
		node.pulse()


## Tạo chữ nổi bay lên và tan dần trên một ô (dùng cho +điểm, cảnh báo...)
func spawn_floating_popup(text: String, cell_pos: Vector2i, color := Color(0.133, 0.298, 0.427, 1.0)) -> void:
	var center := _cell_center(cell_pos)
	if _markers_layer != null:
		UIAnim.spawn_floating_text(_markers_layer, text, center, color)



func reveal_wall_segment(is_h: bool, lattice: Vector2i) -> void:
	var key := _lattice_key(is_h, lattice)
	if _wall_segments.has(key):
		var seg: WallSegment = _wall_segments[key]
		seg.set_state("visible")
		seg.animate_appear()


## Pha GHI NHỚ (Blind Memory): hiện toàn bộ tường + khoá tương tác.
## Đếm ngược nằm ở popup riêng (xem scripts/nodes/popups/memory_countdown.gd) — KHÔNG vẽ label
## trong board nữa vì board bị dựng lại mỗi màn sẽ xoá mất label đó.
func reveal_all_walls() -> void:
	set_interaction_enabled(false)
	for key in _wall_segments:
		var seg: WallSegment = _wall_segments[key]
		seg.set_state("visible")


## Hết pha ghi nhớ: trả tường về trạng thái gốc (ẩn) + mở lại tương tác.
func hide_all_walls() -> void:
	for key in _wall_segments:
		var seg: WallSegment = _wall_segments[key]
		var base: String = seg.get_meta("base_state", "invisible")
		seg.set_state(base)
	set_interaction_enabled(true)


## Cập nhật lại SỐ trên mọi ô theo GameMode (mode có giá trị đổi theo thời gian — Fading Ink).
## `dim_unwalkable` = ô không còn đi vào được thì mờ đi (hết mực thì coi như trống).
## Mode có `ink_left()` (Fading Ink): thay vì mờ cả ô, ô hiện LỚP cảnh báo riêng
## (1 mực = nền hổ phách "SẮP PHAI" · 0 mực = lớp gạch + huy hiệu "CẠN") để phần
## huy hiệu không bị mờ theo ô.
func refresh_cell_texts(dim_unwalkable: bool = false) -> void:
	if maze == null or game_mode == null:
		return
	var has_ink := game_mode.has_method("ink_left")
	for y in _height:
		for x in _width:
			var pos := Vector2i(x, y)
			var cell_node := _cell_node(pos)
			if cell_node == null:
				continue
			cell_node.set_text(game_mode.get_cell_text(pos, maze))
			_sync_bomb_marker(cell_node, pos)
			if has_ink:
				# Ô S/F không bao giờ cạn mực -> tắt lớp cảnh báo
				var ink := -1
				if pos != maze.get_start() and pos != maze.get_end():
					ink = int(game_mode.call("ink_left", pos))
				cell_node.set_ink_left(ink)
				cell_node.modulate = Color(1, 1, 1, 1)
			elif dim_unwalkable:
				var walkable := not game_mode.has_method("is_walkable") \
					or bool(game_mode.call("is_walkable", pos))
				cell_node.modulate = Color(1, 1, 1, 1) if walkable else Color(1, 1, 1, 0.4)


func apply_fog_of_war(_center: Vector2i, _radius: int, explored: Dictionary) -> void:
	if maze == null or game_mode == null:
		return
	for y in _height:
		for x in _width:
			var p := Vector2i(x, y)
			var cell_node := _cell_node(p)
			if cell_node == null:
				continue      # ô ngoài board: không có số để làm mờ
			var text: String = game_mode.get_cell_text(p, maze)
			cell_node.set_text(text)
			_sync_bomb_marker(cell_node, p)
			if explored.has(p):
				cell_node.modulate = Color(1, 1, 1, 1.0)
			else:
				cell_node.modulate = Color(0.6, 0.6, 0.6, 0.4)


func _play_grid_shake() -> void:
	if not _is_shaking:
		_original_position = position
		_is_shaking = true
	elif _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()
		position = _original_position

	_shake_tween = create_tween()
	_shake_tween.tween_property(self, "position", _original_position + Vector2(-6, 4), 0.035)
	_shake_tween.tween_property(self, "position", _original_position + Vector2(6, -4), 0.035)
	_shake_tween.tween_property(self, "position", _original_position + Vector2(-3, 3), 0.035)
	_shake_tween.tween_property(self, "position", _original_position, 0.04)
	_shake_tween.tween_callback(func() -> void:
		position = _original_position
		_is_shaking = false
	)


func set_suspected_wall(is_h: bool, lattice: Vector2i, active: bool) -> void:
	# Cạnh ngoài board (giữa 2 ô trống) thì không có gì để đánh dấu
	if not _edge_touches_board(is_h, lattice):
		return
	var key := _lattice_key(is_h, lattice)
	var seg: WallSegment = null
	if _wall_segments.has(key):
		seg = _wall_segments[key]
	elif _suspected_lines.has(key):
		seg = _suspected_lines[key]
	else:
		seg = _create_wall_segment(is_h, lattice, "suspected")
		_suspected_lines[key] = seg

	if active:
		seg.set_state("suspected")
		seg.animate_appear()
	else:
		if _wall_segments.has(key):
			seg.set_state(seg.get_meta("base_state", "invisible"))
		else:
			seg.visible = false


func set_interaction_enabled(enabled: bool) -> void:
	_interaction_enabled = enabled
	if not enabled:
		_dragging_player = false
		_pressed_cell = Vector2i(-1, -1)
		_has_dragged = false
		_cancel_anchor_drag()


var tool_mode: String = "path"

func set_tool_mode(p_tool: String) -> void:
	tool_mode = p_tool


func _set_path_focus(path: Array[Vector2i]) -> void:
	for y in _height:
		for x in _width:
			var cell := _cell_node(Vector2i(x, y))
			if cell != null:
				cell.set_focused(false)
	for p in path:
		var cell := _cell_node(p)
		if cell != null:
			cell.set_focused(true)


# ============================================================================
# Input: Xử lý Kéo di chuyển Player & Kéo nối Anchor
#
# LƯU Ý TOẠ ĐỘ (bug 2026-09 — "không kéo được anchor để vẽ hint line"):
#   - Godot đưa sự kiện vào `_gui_input` ở toạ độ **LOCAL** của node này (đã trừ vị trí
#     của Board) => dùng `event.position` TRỰC TIẾP, KHÔNG chuyển đổi thêm (nếu chuyển
#     nữa thì hint line bị lệch đúng bằng vị trí Board).
#   - `_unhandled_input` (đường dự phòng, hiếm khi chạy vì GUI đã nhận sự kiện) lại ở
#     toạ độ MÀN HÌNH => phải chuyển qua `_to_local(_screen_to_canvas(...))`.
# ============================================================================
func _gui_input(event: InputEvent) -> void:
	if not _interaction_enabled or maze == null:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		_handle_press_release(touch.pressed, touch.position)
	elif event is InputEventScreenDrag:
		_handle_drag((event as InputEventScreenDrag).position)
	elif event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_LEFT:
			_handle_press_release(button.pressed, button.position)
	elif event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			_handle_drag(motion.position)


func _unhandled_input(event: InputEvent) -> void:
	if not _interaction_enabled or maze == null:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		_handle_press_release(touch.pressed, _to_local(_screen_to_canvas(touch.position)))
	elif event is InputEventScreenDrag:
		_handle_drag(_to_local(_screen_to_canvas((event as InputEventScreenDrag).position)))
	elif event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_LEFT:
			_handle_press_release(button.pressed, _to_local(_screen_to_canvas(button.position)))
	elif event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			_handle_drag(_to_local(_screen_to_canvas(motion.position)))


## Nhấn / thả chuột-cảm ứng tại 1 điểm đã ở toạ độ LOCAL của Board
func _handle_press_release(pressed: bool, local_pos: Vector2) -> void:
	if pressed:
		_on_press(local_pos)
	else:
		_on_release(local_pos)


## Kéo: chỉ xử lý khi đang kéo vẽ đường đi hoặc đang kéo nối anchor (hint line)
func _handle_drag(local_pos: Vector2) -> void:
	if _dragging_player or _is_dragging_anchor:
		_on_drag(local_pos)


func _screen_to_canvas(pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * pos


func _to_local(canvas_pos: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * canvas_pos


func _on_press(local_pos: Vector2) -> void:
	_press_start_pos = local_pos
	_has_dragged = false
	_pressed_cell = Vector2i(-1, -1)
	_drag_draw_sfx_on = false

	var anchor_info := _hit_anchor_info(local_pos)
	if not anchor_info.is_empty() and anchor_info.has("node"):
		_start_anchor_drag(anchor_info)
		return

	var cell := _hit_cell(local_pos)
	if cell != Vector2i(-1, -1):
		_pressed_cell = cell
		_dragging_player = true


func _on_drag(local_pos: Vector2) -> void:
	if not _has_dragged and local_pos.distance_to(_press_start_pos) > 8.0:
		_has_dragged = true

	if _is_dragging_anchor:
		_update_anchor_drag(local_pos)
		return

	if _dragging_player:
		# SFX: tiếng ngòi chì miết trên giấy khi bắt đầu kéo vẽ đường đi
		if not _drag_draw_sfx_on:
			_drag_draw_sfx_on = true
			Sfx.play(Sfx.PATH_DRAW)
		var cell := _hit_cell(local_pos)
		if cell != Vector2i(-1, -1) and cell != _player_current_cell:
			if _is_adjacent(_player_current_cell, cell):
				drag_updated.emit(cell)


func _on_release(local_pos: Vector2) -> void:
	if _is_dragging_anchor:
		_finish_anchor_drag(local_pos)
		_dragging_player = false
		_pressed_cell = Vector2i(-1, -1)
		_has_dragged = false
		return

	if _dragging_player:
		_dragging_player = false

	if not _has_dragged and _pressed_cell != Vector2i(-1, -1):
		var release_cell := _hit_cell(local_pos)
		if release_cell == _pressed_cell:
			cell_pressed.emit(_pressed_cell)

	_pressed_cell = Vector2i(-1, -1)
	_has_dragged = false


# ============================================================================
# Anchor Dragging Visual Helpers
# ============================================================================
func _start_anchor_drag(anchor_info: Dictionary) -> void:
	if anchor_info.is_empty() or not anchor_info.has("node"):
		return

	_is_dragging_anchor = true
	var node: Control = anchor_info.node
	_drag_source_anchor_id = node.get("anchor_id")
	_drag_source_anchor_corner = anchor_info.corner
	_hover_target_anchor_id = -1

	if node.has_method("set_selected"):
		node.call("set_selected", true)

	# SFX: "tách" cơ học khi rê trúng điểm neo
	Sfx.play(Sfx.ANCHOR_SNAP)

	var anchor_center := _anchor_center_pos(_drag_source_anchor_corner)
	_drag_guide_line.visible = true
	_drag_guide_line.points = PackedVector2Array([anchor_center, anchor_center])


func _update_anchor_drag(local_pos: Vector2) -> void:
	if not _is_dragging_anchor or _drag_source_anchor_id == -1:
		return

	var anchor_a_pos := _anchor_center_pos(_drag_source_anchor_corner)
	var hovered_anchor := _hit_anchor_info(local_pos)

	if not hovered_anchor.is_empty() and hovered_anchor.has("node"):
		var node: Control = hovered_anchor.node
		if node.get("anchor_id") != _drag_source_anchor_id:
			var edge := _corner_edge(_drag_source_anchor_corner, hovered_anchor.corner)
			if not edge.is_empty():
				var target_id: int = node.get("anchor_id")
				if _hover_target_anchor_id != target_id:
					_clear_hover_target_highlight()
					_hover_target_anchor_id = target_id
					if node.has_method("set_selected"):
						node.call("set_selected", true)

				var target_pos := _anchor_center_pos(hovered_anchor.corner)
				_drag_guide_line.points = PackedVector2Array([anchor_a_pos, target_pos])
				return

	_clear_hover_target_highlight()
	_hover_target_anchor_id = -1
	_drag_guide_line.points = PackedVector2Array([anchor_a_pos, local_pos])


func _finish_anchor_drag(local_pos: Vector2) -> void:
	if not _is_dragging_anchor:
		return

	var target_anchor := _hit_anchor_info(local_pos)
	var target_id := -1
	if not target_anchor.is_empty() and target_anchor.has("node"):
		var node: Control = target_anchor.node
		if node.get("anchor_id") != _drag_source_anchor_id:
			target_id = node.get("anchor_id")
	elif _hover_target_anchor_id != -1:
		target_id = _hover_target_anchor_id

	if target_id != -1 and _drag_source_anchor_id != -1:
		var target_corner := _anchor_corner(target_id)
		anchor_connected.emit(_drag_source_anchor_corner, target_corner)
		# SFX: nét chì dứt khoát khi hoàn tất một đường "Tường nghi ngờ"
		Sfx.play(Sfx.WALL_MARK)

		var src_node := _get_anchor_node(_drag_source_anchor_id)
		if src_node != null and src_node.has_method("pulse"):
			src_node.call("pulse")
		var dst_node := _get_anchor_node(target_id)
		if dst_node != null and dst_node.has_method("pulse"):
			dst_node.call("pulse")

	_cancel_anchor_drag()


func _cancel_anchor_drag() -> void:
	_clear_hover_target_highlight()
	if _drag_source_anchor_id != -1:
		var src_node := _get_anchor_node(_drag_source_anchor_id)
		if src_node != null and src_node.has_method("set_selected"):
			src_node.call("set_selected", false)

	if _drag_guide_line != null:
		_drag_guide_line.visible = false

	_is_dragging_anchor = false
	_drag_source_anchor_id = -1
	_drag_source_anchor_corner = Vector2i(-1, -1)
	_hover_target_anchor_id = -1


func _clear_hover_target_highlight() -> void:
	if _hover_target_anchor_id != -1:
		var target_node := _get_anchor_node(_hover_target_anchor_id)
		if target_node != null and target_node.has_method("set_selected"):
			target_node.call("set_selected", false)


func _get_anchor_node(anchor_id: int) -> Control:
	for info in _anchor_nodes:
		var node: Control = info.node
		if node.get("anchor_id") == anchor_id:
			return node
	return null


func _anchor_center_pos(corner: Vector2i) -> Vector2:
	return Vector2(_col_edge_x[corner.x], _row_edge_y[corner.y])


func _hit_anchor_info(local_pos: Vector2) -> Dictionary:
	for info in _anchor_nodes:
		var node: Control = info.node
		var center: Vector2 = node.position + node.size * 0.5
		if center.distance_to(local_pos) <= _anchor_hit_radius:
			return info
	return {}


func _hit_cell(local_pos: Vector2) -> Vector2i:
	for y in _height:
		for x in _width:
			var pos := Vector2i(x, y)
			if maze != null and not maze.is_cell_active(pos):
				continue      # ô ngoài board: không bấm được
			if _cell_rects[_cell_index(x, y)].has_point(local_pos):
				return pos
	return Vector2i(-1, -1)


func _is_adjacent(a: Vector2i, b: Vector2i) -> bool:
	var d := (a - b).abs()
	return d.x + d.y == 1


func _anchor_corner(anchor_id: int) -> Vector2i:
	for info in _anchor_nodes:
		var node: Control = info.node
		if node.get("anchor_id") == anchor_id:
			return info.corner
	return Vector2i(-1, -1)


func _corner_edge(a: Vector2i, b: Vector2i) -> Array:
	if a == b:
		return []
	if a.x == b.x and absi(a.y - b.y) == 1:
		return [false, Vector2i(a.x, mini(a.y, b.y))]
	if a.y == b.y and absi(a.x - b.x) == 1:
		return [true, Vector2i(mini(a.x, b.x), a.y)]
	return []


# ============================================================================
# Helpers
# ============================================================================
func _cell_center(pos: Vector2i) -> Vector2:
	return Vector2(_col_center_x[pos.x], _row_center_y[pos.y])


func _lattice_key(is_h: bool, lattice: Vector2i) -> String:
	return ("h,%d,%d" if is_h else "v,%d,%d") % [lattice.x, lattice.y]


func _cell_edge_key(a: Vector2i, b: Vector2i) -> String:
	var lo: Vector2i
	var hi: Vector2i
	if a.x < b.x or (a.x == b.x and a.y < b.y):
		lo = a
		hi = b
	else:
		lo = b
		hi = a
	return "%d,%d->%d,%d" % [lo.x, lo.y, hi.x, hi.y]
