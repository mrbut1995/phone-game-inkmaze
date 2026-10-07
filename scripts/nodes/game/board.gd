class_name BoardView
extends Control
## ============================================================================
## View: Board - Thành phần View thuần túy theo chuẩn MVC:
##   - Kích thước cell/anchor/tường/đường/cursor đọc trực tiếp từ scene gốc
##     (cell.tscn, anchor.tscn, wall_segment.tscn...) nên chỉnh .tscn là ăn ngay.
##   - Căn giữa toàn bộ bàn cờ trên Board Panel nếu còn khoảng trống.
##   - Các ô liền sát nhau 100% không có khe hở.
## ============================================================================

signal drag_updated(pos: Vector2i)
signal anchor_tapped(anchor_id: int)
signal anchor_connected(corner_a: Vector2i, corner_b: Vector2i)
## Người chơi bấm nút retry trên overlay "Hết nước đi" (game_controller lắng nghe để restart)
signal no_moves_retry_pressed

const CRASH_SFX_SCENE := preload("res://nodes/sfx/crash.tscn")
const MINE_SFX_SCENE := preload("res://nodes/sfx/mine_explosion.tscn")
const FOOTSTEP_SCENE := preload("res://nodes/game/ink_footstep.tscn")

## Cỡ THIẾT KẾ đọc 1 LẦN từ scene gốc (dùng cho mọi tầng/bàn — trước đây đọc lại mỗi tầng)
static var _design_wall_width := 0.0
static var _design_history_line_width := 0.0
static var _design_moving_line_width := 0.0
static var _design_cursor_size := 0.0

## Fallback an toàn khi không đọc được scene gốc (giá trị thật nằm trong .tscn)
@export var FALLBACK_CELL_SIZE := 88
@export var FALLBACK_ANCHOR_SIZE := 20
@export var FALLBACK_WALL_WIDTH := 5.5
@export var FALLBACK_CURSOR_SIZE := 66
@export var FALLBACK_MOVING_LINE_WIDTH := 20
@export var FALLBACK_FONT_SIZE := 28

## Mép chừa thêm bên trong phần GIẤY VẼ THẬT (px) - để ô không chạm viền giấy
@export var BOARD_PADDING := 6
## Nhỏ nhất có thể co (0.24 * 176 ≈ 42px) -> board 20x20 vẫn nằm gọn
@export var MIN_FIT_SCALE := 0.24
## Kích thước tối thiểu để còn nhìn thấy rõ
@export var MIN_WALL_WIDTH := 1.5
@export var MIN_ANCHOR_SIZE := 7.0
@export var MIN_CURSOR_SIZE := 9.0
@export var MIN_FONT_SIZE := 6

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
## Lưu theo TỈ LỆ 0..1 của Panel (left, top, right, bottom) — KHÔNG lưu pixel texture:
## panel bị kéo giãn theo màn hình (màn 9:20 cao hơn thiết kế) nên insets phải scale
## theo kích thước panel, nếu không lưới bị lệch LÊN TRÊN so với tâm thẻ giấy.
var _panel_insets := Vector4.ZERO      # left, top, right, bottom (tỉ lệ 0..1)

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
var _moving_line: InkStroke = null
var _drag_guide_line: InkStroke = null
## Đường ĐANG ĐI (danh sách Ô, không phải pixel) — giữ lại để VẼ LẠI nét khi lưới tính lại
## (đổi cỡ cửa sổ / đổi chỗ bàn cờ); nếu không nét mực đứng yên ở toạ độ cũ.
var _moving_path: Array[Vector2i] = []
var _cursor: PlayerCursor = null
## Wall Builder: ẩn hẳn nhân vật trên bàn (xem set_player_visible)
var _player_hidden: bool = false
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
## Vị trí chuột cuối cùng khi kéo neo — dựng lại đường kéo nếu lưới tính lại giữa chừng
var _drag_guide_last_local := Vector2.ZERO

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
# Node MẪU khai sẵn trong `Layers` (cell.tscn · wall_segment.tscn · anchor.tscn · history_line.tscn)
# — board `duplicate()` từ đây chứ KHÔNG `instantiate()` scene lúc chạy
var _cell_template: MazeCell = null
var _wall_template: WallSegment = null
var _anchor_template: MazeAnchor = null
var _history_template: Line2D = null
## Node KHAI SẴN trong scene mà `_clear_runtime_layers()` phải GIỮ LẠI (nét mực · chỉ dẫn ·
## con trỏ · 4 node mẫu) — lấy từ `BoardLayers.fixed_nodes()`
var _keep_nodes: Array = []


func _ready() -> void:
	_init_layers()
	_connect_skin_signal()


## Tính lại toàn bộ vị trí theo khung hiện tại. GameScene gọi sau khi ĐỔI CHỖ bàn cờ
## (lúc vừa reparent, khung giấy chưa cập nhật xong nên phải gọi ở frame kế tiếp).
func relayout() -> void:
	if _cell_nodes.is_empty():
		return
	_update_layout_positions()


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


## Lớp vẽ + nét mực + con trỏ + node MẪU đều KHAI SẴN trong scene (`Layers` = board_layers.tscn)
## ⇒ không instantiate lúc chạy: mỗi tầng mới chỉ RESET trạng thái và nhân bản từ node mẫu.
func _init_layers() -> void:
	if _cells_layer != null:
		return

	var layers := get_node_or_null("Layers") as BoardLayers
	if layers == null:
		push_warning("board: thiếu node Layers — khai trong nodes/game/board.tscn")
		return
	_cells_layer = layers.cells()
	_lines_layer = layers.lines()
	_walls_layer = layers.walls()
	_anchors_layer = layers.anchors()
	_markers_layer = layers.markers()
	_moving_line = layers.moving_line()
	_drag_guide_line = layers.drag_guide_line()
	_cursor = layers.cursor()
	_cell_template = layers.cell_template()
	_wall_template = layers.wall_template()
	_anchor_template = layers.anchor_template()
	_history_template = layers.history_template()
	_keep_nodes = layers.fixed_nodes()
	if _cell_template == null or _wall_template == null or _anchor_template == null or _history_template == null:
		push_warning("board: thiếu node MẪU trong Layers (CellTemplate · WallTemplate · AnchorTemplate · HistoryTemplate) — xem nodes/game/board_layers.tscn")
	# Cỡ THIẾT KẾ của nét mực · con trỏ · tường · vệt mực cũ: đọc ngay lúc này (còn nguyên số
	# trong scene, chưa bị co giãn/đổi chất liệu) rồi giữ lại cho mọi tầng sau.
	if _design_moving_line_width <= 0.0 and _moving_line != null and _moving_line.width > 0.0:
		_design_moving_line_width = _moving_line.width
	if _design_cursor_size <= 0.0 and _cursor != null and _cursor.size.x > 0.0:
		_design_cursor_size = _cursor.size.x
	if _design_wall_width <= 0.0 and _wall_template != null and _wall_template.width > 0.0:
		_design_wall_width = _wall_template.width
	if _design_history_line_width <= 0.0 and _history_template != null and _history_template.width > 0.0:
		_design_history_line_width = _history_template.width


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
	if _cursor != null:
		_cursor.apply_pen(_pen_id)
	if _moving_line != null:
		_moving_line.apply_pen(_pen_id)
	_apply_wall_width()


func _animate_board_entrance() -> void:
	if DisplayServer.get_name() == "headless":
		return
	for y in _height:
		for x in _width:
			var cell: MazeCell = _cell_node(Vector2i(x, y))
			if cell == null:
				continue
			cell.play_entrance(float(x + y) * 0.015)

	for info in _anchor_nodes:
		var anchor: MazeAnchor = info.node
		if anchor == null:
			continue
		var corner: Vector2i = info.corner
		anchor.play_entrance(float(corner.x + corner.y) * 0.015 + 0.04)



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
		var font_size := (node as MazeCell).text_font_size()
		if font_size > 0:
			_base_font_size = float(font_size)
		break

	if not _anchor_nodes.is_empty():
		var anchor_sz: Vector2 = _anchor_nodes[0].node.size
		if anchor_sz.x > 0.0:
			_anchor_size = anchor_sz.x

	_wall_width = _design_wall_width if _design_wall_width > 0.0 else FALLBACK_WALL_WIDTH
	_design_wall_width = _wall_width
	_history_line_width = _design_history_line_width if _design_history_line_width > 0.0 \
		else FALLBACK_MOVING_LINE_WIDTH
	_design_history_line_width = _history_line_width
	_moving_line_width = _design_moving_line_width if _design_moving_line_width > 0.0 \
		else FALLBACK_MOVING_LINE_WIDTH
	_cursor_size = _design_cursor_size if _design_cursor_size > 0.0 else FALLBACK_CURSOR_SIZE

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

	# Lưu TỈ LỆ 0..1 (không phải pixel texture) — xem chú thích `_panel_insets`.
	_panel_insets = Vector4(
		float(min_x) / float(PROBE),
		float(min_y) / float(PROBE),
		float(max_x + 1) / float(PROBE),
		float(max_y + 1) / float(PROBE))


## Vùng giấy vẽ thật (toạ độ cục bộ của Board) - dùng để canh lưới + cho test
func panel_inner_rect() -> Rect2:
	var panel: Control = get_node_or_null("Panel") as Control
	if panel == null:
		return Rect2(Vector2.ZERO, size)
	# Insets là TỈ LỆ -> nhân với kích thước panel THẬT (panel giãn theo màn hình)
	var inner_pos := panel.position + Vector2(
		_panel_insets.x * panel.size.x, _panel_insets.y * panel.size.y)
	var inner_size := Vector2(
		(_panel_insets.z - _panel_insets.x) * panel.size.x,
		(_panel_insets.w - _panel_insets.y) * panel.size.y)
	if inner_size.x <= 0.0 or inner_size.y <= 0.0:
		return Rect2(panel.position, panel.size)
	return Rect2(inner_pos, inner_size)


## Nhân bản node MẪU khai sẵn trong scene (thay cho `PackedScene.instantiate()` lúc chạy):
## bật lại hiển thị + đưa về gốc toạ độ (node mẫu trong scene luôn ẩn).
func _spawn_template(template: Node) -> Node:
	if template == null:
		return null
	var node := template.duplicate()
	var item := node as CanvasItem
	if item != null:
		item.visible = true
	var control := node as Control
	if control != null:
		control.position = Vector2.ZERO
	else:
		var node2d := node as Node2D
		if node2d != null:
			node2d.position = Vector2.ZERO
	return node


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
		cell.set_cell_size(cell_side)          # cỡ ô + tâm xoay (ô tự lo)
		cell.set_font_size(_scaled_font_size())

	var anchor_side := maxf(_anchor_size * _fit_scale, MIN_ANCHOR_SIZE)
	for info in _anchor_nodes:
		var anchor: MazeAnchor = info.node
		anchor.set_anchor_size(anchor_side)    # cỡ neo + tâm xoay (neo tự lo)
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
		_moving_line.set_base_width(line_width)


func _update_layout_positions() -> void:
	# Chưa có maze (bàn cờ vừa mở, `Panel.resized` bắn trước `setup_maze`) ⇒ chưa có lưới để tính:
	# bỏ qua, nếu không `_cell_center` sẽ truy cập mảng rỗng (Out of bounds).
	if maze == null or _width <= 0 or _height <= 0:
		return
	_compute_layout()

	# Cập nhật toạ độ và kích cỡ từng cell (ô ngoài board không có node)
	for y in _height:
		for x in _width:
			var idx := _cell_index(x, y)
			var cell := _cell_node(Vector2i(x, y))
			if cell == null or idx < 0 or idx >= _cell_rects.size():
				continue
			cell.position = Vector2(_col_edge_x[x], _row_edge_y[y])
			_cell_rects[idx] = Rect2(cell.position, cell.size)

	# Cập nhật vị trí các anchor
	for info in _anchor_nodes:
		var a: MazeAnchor = info.node
		var corner: Vector2i = info.corner
		var pos := Vector2(_col_edge_x[corner.x], _row_edge_y[corner.y])
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

	# Cập nhật toạ độ player cursor (giữ ĐẦU BÚT trên tâm ô — xem `cursor_pos_at`)
	if _cursor != null:
		_cursor.position = cursor_pos_at(_cell_center(_player_current_cell))

	# Nét ĐÃ VẼ (đường đang đi · vệt mực cũ · đường kéo neo) nhớ danh sách Ô, nhưng pixel
	# đã dựng từ lưới CŨ ⇒ vẽ lại theo lưới mới, nếu không đường đi nằm lệch khỏi các ô.
	_refresh_drawn_strokes()


## Vẽ lại mọi nét mực ĐÃ VẼ theo lưới hiện tại — gọi khi cửa sổ đổi cỡ / bàn cờ đổi chỗ.
## Nét chỉ nhớ Ô (nguồn sự thật) nên chỉ cần suy lại tâm ô mới.
func _refresh_drawn_strokes() -> void:
	if _moving_line != null and not _moving_path.is_empty():
		var pts := PackedVector2Array()
		for p in _moving_path:
			pts.append(_cell_center(p))
		_moving_line.set_stroke(pts)

	for key: String in _history_lines:
		var line: Line2D = _history_lines[key]
		if not is_instance_valid(line) or not line.has_meta("cell_a"):
			continue
		var a: Vector2i = line.get_meta("cell_a")
		var b: Vector2i = line.get_meta("cell_b")
		line.points = PackedVector2Array([_cell_center(a), _cell_center(b)])

	# Đường kéo neo (nếu đang kéo dở): bám lại 2 đầu theo lưới mới
	if _drag_guide_line != null and _is_dragging_anchor and _drag_source_anchor_id != -1:
		_drag_guide_line.points = PackedVector2Array(
			[_anchor_center_pos(_drag_source_anchor_corner), _drag_guide_other_end()])


## Đầu thứ 2 của đường kéo neo: tâm neo đang rê trúng, hoặc vị trí chuột cuối cùng
func _drag_guide_other_end() -> Vector2:
	if _hover_target_anchor_id != -1:
		var corner := _anchor_corner(_hover_target_anchor_id)
		if corner.x != -1:
			return _anchor_center_pos(corner)
	return _drag_guide_last_local


func _build_cells() -> void:
	# Board có thể là polyomino: ô ngoài board KHÔNG có node -> mảng giữ null
	_cell_nodes.resize(_width * _height)
	_cell_rects.resize(_width * _height)
	if _cell_template == null:
		return
	for y in _height:
		for x in _width:
			var pos := Vector2i(x, y)
			if maze != null and not maze.is_cell_active(pos):
				continue
			var c := _spawn_template(_cell_template) as MazeCell
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


## Đồng bộ biểu tượng Bomb cho ô (mode nào có mìn đã nổ — xem MinesweeperPathGameMode).
func _sync_bomb_marker(cell_node: MazeCell, pos: Vector2i) -> void:
	if cell_node == null:
		return
	var marked := game_mode != null and game_mode.has_bomb_marker(pos)
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
				if seg != null:
					_wall_segments[_lattice_key(true, Vector2i(ix, iy))] = seg
	for ix in _width + 1:
		for iy in _height:
			if not _edge_touches_board(false, Vector2i(ix, iy)):
				continue
			if maze.has_v_wall(ix, iy):
				var seg := _create_wall_segment(false, Vector2i(ix, iy),
					"visible" if maze.is_v_wall_visible(ix, iy) else "invisible")
				if seg != null:
					_wall_segments[_lattice_key(false, Vector2i(ix, iy))] = seg


func _create_wall_segment(is_h: bool, lattice: Vector2i, state: String) -> WallSegment:
	var seg := _spawn_template(_wall_template) as WallSegment
	if seg == null:
		return null
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
	if _anchor_template == null:
		return
	var id := 0
	for iy in _height + 1:
		for ix in _width + 1:
			# Chỉ tạo anchor ở góc có dính ít nhất 1 ô thuộc board
			if not _corner_touches_board(ix, iy):
				continue
			var a := _spawn_template(_anchor_template) as MazeAnchor
			a.set_anchors_preset(Control.PRESET_TOP_LEFT)
			# Không set size/position: kích thước lấy từ anchor.tscn,
			# vị trí do _update_layout_positions() căn theo lưới
			a.anchor_id = id
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


## Nét mực đang vẽ (InkStroke khai sẵn trong `Layers/Lines`) — mỗi tầng chỉ xoá điểm cũ
func _build_moving_line() -> void:
	if _moving_line == null:
		return
	_moving_line.position = Vector2.ZERO
	_moving_path.clear()
	# width/default_color lấy nguyên từ moving_line.tscn
	_set_line_points(_moving_line, PackedVector2Array())


## Đường kẻ chỉ dẫn khi KÉO NEO (cùng loại nét với moving_line, ẩn đến khi cần)
func _build_drag_guide_line() -> void:
	if _drag_guide_line == null:
		return
	_drag_guide_line.position = Vector2.ZERO
	_drag_guide_line.width = _wall_width
	_drag_guide_line.default_color = Color(0.77, 0.52, 0.23, 0.75)
	_drag_guide_line.visible = false
	_set_line_points(_drag_guide_line, PackedVector2Array())


## Ghi điểm cho nét — dùng `set_stroke()` của InkStroke (đồng bộ luôn quầng sáng)
func _set_line_points(line: InkStroke, points_now: PackedVector2Array) -> void:
	if line == null:
		return
	line.set_stroke(points_now)


## Đặt con trỏ về ô xuất phát (con trỏ KHAI SẴN trong `Layers/Markers`)
func _place_cursor_at_start() -> void:
	if _cursor == null:
		return
	# Kích thước cursor lấy nguyên từ player_cursor.tscn
	_cursor.pivot_offset = _cursor.size * 0.5
	var target_pos := cursor_pos_at(_cell_center(maze.get_start()))
	_cursor.position = target_pos
	_cursor.visible = not _player_hidden
	_player_current_cell = maze.get_start()
	# SFX: bước vào ô xuất phát S khi bắt đầu mỗi floor
	Sfx.play(Sfx.STAIRS_ENTER)
	if DisplayServer.get_name() != "headless":
		_cursor.play_spawn_drop(target_pos)


## Dọn node ĐỘNG của tầng trước (ô · tường · neo · vệt mực · hiệu ứng...).
## GIỮ LẠI mọi node KHAI SẴN trong scene (nét mực · đường kẻ chỉ dẫn · con trỏ · 4 node MẪU —
## xem `BoardLayers.fixed_nodes()`).
func _clear_runtime_layers() -> void:
	for layer in [_cells_layer, _walls_layer, _anchors_layer, _lines_layer, _markers_layer]:
		if layer == null:
			continue
		for child in layer.get_children():
			if _keep_nodes.has(child):
				continue
			child.queue_free()
	_cell_nodes.clear()
	_cell_rects.clear()
	_anchor_nodes.clear()
	_wall_segments.clear()
	_suspected_lines.clear()
	_history_lines.clear()


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
	var target_pos := cursor_pos_at(target_center)
	var move_dir := (Vector2(pos) - Vector2(prev_cell)).normalized()

	# Hiệu ứng vệt chân mực lan nhẹ khi cất bước
	_spawn_ink_footstep(from_center)

	# SFX: chấm bút chì khi vào tâm ô mới; thêm tiếng "vào cầu thang" khi tới ô F
	Sfx.play(Sfx.CELL_STEP)
	if pos == maze.get_end():
		Sfx.play(Sfx.STAIRS_ENTER)
		if _cursor != null:
			_cursor.play_celebration()

	# Chạy animation bước nhảy (Hop / Squash & Stretch / Tilt)
	_cursor.run_to(target_pos, move_dir, 0.16)

	var c_idx := _cell_index(pos.x, pos.y)
	if c_idx >= 0 and c_idx < _cell_nodes.size():
		var cell_node: MazeCell = _cell_nodes[c_idx]
		cell_node.pulse()


func _spawn_ink_footstep(pos: Vector2) -> void:
	if _markers_layer == null:
		return
	var ripple := FOOTSTEP_SCENE.instantiate() as InkFootstep
	_markers_layer.add_child(ripple)
	ripple.setup(pos, PenSkin.cursor_texture(_pen_id), PenSkin.ink_color(_pen_id))
	# Hiệu ứng lan to + mờ dần (và tự xoá) khai trong `ink_footstep.tscn` (AnimationPlayer autoplay)


func set_moving_path(path: Array[Vector2i]) -> void:
	if _moving_line == null:
		return
	# Nhớ đường đi theo Ô để còn vẽ LẠI khi lưới đổi cỡ (xem `_refresh_drawn_strokes`)
	_moving_path = path.duplicate()
	var pts := PackedVector2Array()
	for p in path:
		pts.append(_cell_center(p))
	_moving_line.set_stroke(pts)
	_set_path_focus(path)


func reset_to_start() -> void:
	if maze == null or _cursor == null:
		return
	_player_current_cell = maze.get_start()
	var target_pos := cursor_pos_at(_cell_center(maze.get_start()))

	# (GIỮ tween) Vị trí đích = TÂM Ô theo lưới tính lúc chạy (phụ thuộc kích thước lưới/cỡ ô)
	var tw := create_tween()
	tw.tween_property(_cursor, "position", target_pos, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	set_moving_path([maze.get_start()])


func show_history_edge(a: Vector2i, b: Vector2i) -> void:
	var key := _cell_edge_key(a, b)
	if _history_lines.has(key) or _history_template == null:
		return
	var line := _spawn_template(_history_template) as Line2D
	_lines_layer.add_child(line)
	line.points = PackedVector2Array([_cell_center(a), _cell_center(b)])
	# Nhớ 2 Ô của cạnh (nguồn sự thật) để vẽ LẠI đúng chỗ khi lưới đổi cỡ
	line.set_meta("cell_a", a)
	line.set_meta("cell_b", b)
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
		if seg == null:
			return
		_wall_segments[key] = seg
		seg.flash_hit_then_stay_visible()

	var pts := _edge_points(is_h, lattice)
	var wall_center: Vector2 = (pts[0] + pts[1]) * 0.5

	var crash: Control = CRASH_SFX_SCENE.instantiate()
	_markers_layer.add_child(crash)
	crash.position = wall_center - crash.size * 0.5
	crash.scale = Vector2.ZERO
	# Nảy to → giữ → mờ dần (và tự xoá): khai trong `nodes/sfx/crash.tscn` (AnimationPlayer autoplay)

	# Tác động lực giật nảy lên con trỏ người chơi (Bonk recoil)
	if _cursor != null:
		var recoil_dir := (Vector2(from_pos) - Vector2(to_pos)).normalized()
		_cursor.play_bonk_recoil(recoil_dir)

	_play_grid_shake()


func show_mine_hit(pos: Vector2i) -> void:
	var c_idx := _cell_index(pos.x, pos.y)
	if c_idx >= 0 and c_idx < _cell_nodes.size():
		var cell_node: MazeCell = _cell_nodes[c_idx]
		if cell_node != null:
			# Giữ nguyên con số trên ô, chỉ đánh dấu quả mìn đã nổ
			cell_node.set_bomb(true)
			cell_node.play_shudder()

	if _cursor != null:
		_cursor.play_bonk_recoil(Vector2(0, -1))

	var center := _cell_center(pos)
	var mine_sfx: Control = MINE_SFX_SCENE.instantiate()
	_markers_layer.add_child(mine_sfx)
	mine_sfx.position = center - mine_sfx.size * 0.5
	mine_sfx.scale = Vector2.ZERO
	# Nảy to → giữ → mờ dần (và tự xoá): khai trong `nodes/sfx/mine_explosion.tscn` (AnimationPlayer autoplay)

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
	var has_ink := game_mode.shows_ink_left()
	# One Stroke: ô đã đi qua bị KHOÁ -> tô mực xanh + gạch chéo + nhãn "ĐÃ ĐI"
	var has_visited := game_mode.tracks_visited_cells()
	# Wall Builder: ô đã KHỚP SỐ (đủ tường quanh ô) -> nền xanh lá nhạt
	var has_satisfied := game_mode.tracks_satisfied_cells()
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
					ink = game_mode.ink_left(pos)
				cell_node.set_ink_left(ink)
				cell_node.modulate = Color(1, 1, 1, 1)
			elif has_visited:
				# Ô S/F giữ nguyên art xuất phát/đích (mockup không gạch chéo 2 ô này)
				var seen := false
				if pos != maze.get_start() and pos != maze.get_end():
					seen = game_mode.is_cell_visited(pos)
				cell_node.set_visited_own(seen)
				cell_node.modulate = Color(1, 1, 1, 1)
			elif has_satisfied:
				cell_node.set_satisfied(game_mode.is_cell_satisfied(pos))
				cell_node.modulate = Color(1, 1, 1, 1)
			elif dim_unwalkable:
				var walkable := game_mode.is_walkable(pos)
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

	# (GIỮ tween) Gốc rung = vị trí bàn do layout tính LÚC CHẠY (không phải số cố định
	# trong scene) nên không thể bake thành track tĩnh — hiệu ứng động duy nhất của bàn.
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
	# Chế độ có thể đổi kiểu hiển thị đoạn người chơi nối (Wall Builder: "built")
	var draw_state := "suspected"
	if game_mode != null:
		var custom := game_mode.wall_draw_state()
		if not custom.is_empty():
			draw_state = custom
	var key := _lattice_key(is_h, lattice)
	var seg: WallSegment = null
	if _wall_segments.has(key):
		seg = _wall_segments[key]
	elif _suspected_lines.has(key):
		seg = _suspected_lines[key]
	else:
		seg = _create_wall_segment(is_h, lattice, draw_state)
		_suspected_lines[key] = seg

	if active:
		seg.set_state(draw_state)
		seg.animate_appear()
	else:
		if _wall_segments.has(key):
			seg.set_state(seg.get_meta("base_state", "invisible"))
		else:
			seg.visible = false


## Wall Builder: bàn chơi KHÔNG có nhân vật -> ẩn cursor (nhớ trạng thái cho lần tạo lại)
func set_player_visible(on: bool) -> void:
	_player_hidden = not on
	if _cursor != null:
		_cursor.set_cursor_visible(on)


## Đổi hiển thị con trỏ người chơi
func set_cursor_visible(on: bool) -> void:
	set_player_visible(on)


## Lấy instance PlayerCursor trong bàn
func get_cursor() -> PlayerCursor:
	return _cursor


## Trình diễn kéo con trỏ từ ô from_cell sang to_cell (dùng cho hướng dẫn)
func animate_cursor_drag(from_cell: Vector2i, to_cell: Vector2i, duration: float = 0.6) -> void:
	if _cursor == null:
		return
	_player_hidden = false
	_cursor.visible = true
	var p1 := cursor_pos_at(_cell_center(from_cell))
	var p2 := cursor_pos_at(_cell_center(to_cell))
	_cursor.play_demo_drag(p1, p2, duration)


## Trình diễn chạm/nhấp con trỏ tại ô
func animate_cursor_tap(cell: Vector2i) -> void:
	if _cursor == null:
		return
	_player_hidden = false
	_cursor.visible = true
	var p := cursor_pos_at(_cell_center(cell))
	_cursor.play_demo_tap(p)


## Dừng hoạt ảnh trình diễn của con trỏ và đưa về tâm ô người chơi hiện tại
func stop_cursor_animation() -> void:
	if _cursor == null:
		return
	_cursor.stop_demo()
	if maze != null:
		_cursor.position = cursor_pos_at(_cell_center(_player_current_cell))
	if _player_hidden:
		_cursor.visible = false


## Trình diễn cursor di chuyển qua chuỗi ô (dùng cho demo full-path, lặp)
func animate_cursor_path(path: Array[Vector2i], dur_per_step: float = 0.45) -> void:
	if _cursor == null or path.size() < 2:
		return
	_player_hidden = false
	_cursor.visible = true
	var positions: Array[Vector2] = []
	for cell in path:
		positions.append(cursor_pos_at(_cell_center(cell)))
	_cursor.play_demo_path(positions, dur_per_step)


## Trình diễn cursor thử đi đè lên ô đã đi: di chuyển nửa đường rồi nảy lại (1 chu kỳ)
func animate_cursor_fail_attempt(from_cell: Vector2i, toward_cell: Vector2i) -> void:
	if _cursor == null:
		return
	_player_hidden = false
	_cursor.visible = true
	var from_p := cursor_pos_at(_cell_center(from_cell))
	var toward_p := cursor_pos_at(_cell_center(toward_cell))
	var midway := from_p.lerp(toward_p, 0.5)
	var recoil_dir := Vector2(from_cell - toward_cell)
	_cursor.play_demo_fail_attempt(from_p, midway, recoil_dir)


## Rung bàn cờ (Wall Builder: GỬI SAI) — bản public của hiệu ứng rung lưới
func shake_board() -> void:
	_play_grid_shake()


## Hiện/ẩn overlay "Hết nước đi" trên bàn (Sum Path / Countdown Cost / Fading Ink)
func show_no_moves_overlay(on: bool) -> void:
	var overlay := get_node_or_null("NoMovesOverlay")
	if overlay == null:
		return
	if overlay.visible == on:
		return
	overlay.visible = on
	if on:
		# Huỷ drag đang diễn ra — người dùng giữ ngón tay sẽ không tiếp tục kéo qua overlay
		_dragging_player = false
		_pressed_cell = Vector2i(-1, -1)
		_has_dragged = false
		_cancel_anchor_drag()
		var btn := overlay.get_node_or_null("RetryBtn") as Control
		if btn != null:
			UIAnim.play_pop_in(btn, 0.12, 0.65, 0.3)


func _on_no_moves_retry_btn_pressed() -> void:
	no_moves_retry_pressed.emit()



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

	_pressed_cell = Vector2i(-1, -1)
	_has_dragged = false


# ============================================================================
# Anchor Dragging Visual Helpers
# ============================================================================
func _start_anchor_drag(anchor_info: Dictionary) -> void:
	if anchor_info.is_empty() or not anchor_info.has("node"):
		return

	_is_dragging_anchor = true
	var node: MazeAnchor = anchor_info.node
	_drag_source_anchor_id = node.anchor_id
	_drag_source_anchor_corner = anchor_info.corner
	_hover_target_anchor_id = -1

	node.set_selected(true)

	# SFX: "tách" cơ học khi rê trúng điểm neo
	Sfx.play(Sfx.ANCHOR_SNAP)

	var anchor_center := _anchor_center_pos(_drag_source_anchor_corner)
	_drag_guide_last_local = anchor_center
	_drag_guide_line.visible = true
	_drag_guide_line.points = PackedVector2Array([anchor_center, anchor_center])


func _update_anchor_drag(local_pos: Vector2) -> void:
	if not _is_dragging_anchor or _drag_source_anchor_id == -1:
		return

	_drag_guide_last_local = local_pos
	var anchor_a_pos := _anchor_center_pos(_drag_source_anchor_corner)
	var hovered_anchor := _hit_anchor_info(local_pos)

	if not hovered_anchor.is_empty() and hovered_anchor.has("node"):
		var node: MazeAnchor = hovered_anchor.node
		if node.anchor_id != _drag_source_anchor_id:
			var edge := _corner_edge(_drag_source_anchor_corner, hovered_anchor.corner)
			if not edge.is_empty():
				var target_id := node.anchor_id
				if _hover_target_anchor_id != target_id:
					_clear_hover_target_highlight()
					_hover_target_anchor_id = target_id
					node.set_selected(true)

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
		var node: MazeAnchor = target_anchor.node
		if node.anchor_id != _drag_source_anchor_id:
			target_id = node.anchor_id
	elif _hover_target_anchor_id != -1:
		target_id = _hover_target_anchor_id

	if target_id != -1 and _drag_source_anchor_id != -1:
		var target_corner := _anchor_corner(target_id)
		anchor_connected.emit(_drag_source_anchor_corner, target_corner)
		# SFX: nét chì dứt khoát khi hoàn tất một đường "Tường nghi ngờ"
		Sfx.play(Sfx.WALL_MARK)

		var src_node := _get_anchor_node(_drag_source_anchor_id)
		if src_node != null:
			src_node.pulse()
		var dst_node := _get_anchor_node(target_id)
		if dst_node != null:
			dst_node.pulse()

	_cancel_anchor_drag()


func _cancel_anchor_drag() -> void:
	_clear_hover_target_highlight()
	if _drag_source_anchor_id != -1:
		var src_node := _get_anchor_node(_drag_source_anchor_id)
		if src_node != null:
			src_node.set_selected(false)

	if _drag_guide_line != null:
		_drag_guide_line.visible = false

	_is_dragging_anchor = false
	_drag_source_anchor_id = -1
	_drag_source_anchor_corner = Vector2i(-1, -1)
	_hover_target_anchor_id = -1


func _clear_hover_target_highlight() -> void:
	if _hover_target_anchor_id != -1:
		var target_node := _get_anchor_node(_hover_target_anchor_id)
		if target_node != null:
			target_node.set_selected(false)


func _get_anchor_node(anchor_id: int) -> MazeAnchor:
	for info in _anchor_nodes:
		var node: MazeAnchor = info.node
		if node.anchor_id == anchor_id:
			return node
	return null


func _anchor_center_pos(corner: Vector2i) -> Vector2:
	return Vector2(_col_edge_x[corner.x], _row_edge_y[corner.y])


func _hit_anchor_info(local_pos: Vector2) -> Dictionary:
	for info in _anchor_nodes:
		var node: MazeAnchor = info.node
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
		var node: MazeAnchor = info.node
		if node.anchor_id == anchor_id:
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
## Đầu bút (tip) trong art con trỏ — toạ độ CHUẨN HOÁ theo cỡ sprite (0..1).
## Đo từ `assets/images-png/game/player_cursor*.png` (28×28 · mực trải (3,3)-(22,22) ·
## đầu bút ở góc dưới-phải (22,22) ⇒ 22/28 ≈ 0.786 — mọi skin bút cùng vị trí).
## Bàn cờ đặt ĐẦU BÚT trùng điểm cuối nét mực (tâm ô) chứ KHÔNG đặt tâm sprite — nếu đặt
## tâm sprite thì đầu bút thò ra ngoài nét vẽ (lỗi người chơi báo 2026-10-03).
@export var CURSOR_TIP_UV := Vector2(0.786, 0.786)


## Vị trí (góc trên-trái node con trỏ) sao cho ĐẦU BÚT nằm đúng `center` (tâm ô = điểm
## cuối nét mực). Tự co theo cỡ con trỏ lúc chạy (bàn lớn ⇒ con trỏ nhỏ đi).
func cursor_pos_at(center: Vector2) -> Vector2:
	if _cursor == null:
		return center
	return center - CURSOR_TIP_UV * _cursor.size


## Tâm của 1 ô (toạ độ lưới → pixel). Chỉ số được KẸP vào trong bảng nên không bao giờ
## lỗi "Out of bounds" khi con trỏ/điểm vẽ nằm ngoài board (một số chế độ giữ toạ độ đặc biệt).
func _cell_center(pos: Vector2i) -> Vector2:
	if _col_center_x.is_empty() or _row_center_y.is_empty():
		return Vector2.ZERO
	return Vector2(
		_col_center_x[clampi(pos.x, 0, _col_center_x.size() - 1)],
		_row_center_y[clampi(pos.y, 0, _row_center_y.size() - 1)])


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
