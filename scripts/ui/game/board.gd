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

## Cỡ THIẾT KẾ đọc 1 LẦN từ scene gốc (dùng cho mọi tầng/bàn , không đọc lại mỗi tầng)
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
var _panel_insets := Vector4.ZERO      # (không còn dùng — giữ để khỏi vỡ tham chiếu cũ)
var _sheet_tex_rect := Rect2()         # vùng GIẤY ĐẶC (bỏ bóng đổ), đơn vị pixel TEXTURE của Panel
var _margin_tex_x := -1.0              # x vạch lề đỏ (pixel texture, mép phải vạch); -1 = không có
var _tex_px := Vector2.ZERO            # kích thước texture của Panel

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
var _feel: Dictionary = PenSkin.feel_of(PenSkin.DEFAULT_PEN)   # cảm giác viết của bút đang dùng

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

# ============================================================================
# CẢM GIÁC VIẾT / QUẸT (Pen writing feel) — mọi số chỉnh được trong Inspector
# ============================================================================
@export_group("Pen writing feel")
## Công tắc tổng. TẮT = hành vi cũ (con trỏ nhún từng ô, nét mực nhảy cách ô).
@export var WRITING_MODE := true
## Tốc độ đầu bút đuổi theo ngón tay / trượt tới ô mới (càng lớn càng "dính" tay, 18–40).
@export_range(8.0, 60.0, 1.0) var TIP_FOLLOW_SPEED := 30.0
## Vùng chết quanh tâm ô (× bước ô): ngón tay chưa kéo quá mức này thì chưa ra đuôi mực
@export_range(0.0, 0.3, 0.01) var TAIL_DEADZONE := 0.10
## Đuôi mực dài tối đa (× bước ô) trước khi chốt sang ô kế
@export_range(0.2, 0.9, 0.01) var TAIL_MAX := 0.55
## Đuôi mực dài ra nhanh hơn ngón tay bao nhiêu lần (tạo cảm giác mực "chảy" theo)
@export_range(0.6, 2.0, 0.05) var TAIL_GAIN := 1.15
## Chống chạm nhầm ô chéo: ngón tay phải vào ô kế quá mép này (× bước ô) mới tính là chốt
@export_range(0.0, 0.3, 0.01) var CORNER_GUARD := 0.08
## Khoảng cách lấy mẫu dọc đường ngón tay (× bước ô) — quẹt nhanh không còn mất ô
@export_range(0.1, 0.5, 0.01) var SAMPLE_SPACING := 0.25
## Độ nghiêng bút theo tốc độ quẹt (rad mỗi px/giây) và nghiêng tối đa
@export var LEAN_PER_SPEED := 0.00035
@export var LEAN_MAX := 0.22
## Nảy (pulse) ô mỗi khi chốt bước. Tắt khi viết để lưới không "nhấp nhô"
@export var PULSE_CELLS_WHILE_WRITING := false
## Vết bút (footstep) mỗi ô. Tắt vì nét mực đã liền mạch
@export var FOOTSTEP_ON_STEP := false
## Rung nhẹ mỗi bước (chỉ mobile)
@export var HAPTIC_ON_STEP := false
@export var HAPTIC_MS := 8
## Ẩn vệt mờ (history) nằm DƯỚI đường đi hiện tại — tránh viền góc vuông lộ ra sau nét đã bo tròn
@export var HIDE_HISTORY_UNDER_PATH := true
## Kéo neo (Wall Builder): nét chỉ dẫn bò theo TRỤC lưới và tự hít vào neo kề
@export var ANCHOR_AXIS_SNAP := true
## Phần bước ô cuối còn lại khi neo kề bắt đầu "hít" (0.45 ⇒ kéo ≥ 0.55 bước là bám)
@export_range(0.1, 0.8, 0.01) var ANCHOR_MAGNET := 0.45
## Nét chỉ dẫn khi kéo neo dày hơn tường thường bao nhiêu lần (nổi bật trên đường kẻ ô)
@export_range(1.0, 2.5, 0.05) var GUIDE_WIDTH_SCALE := 1.45
## Quầng giấy sáng quanh nét chỉ dẫn (× bề rộng nét) — tách nét khỏi đường kẻ ô phía sau
@export_range(1.0, 3.0, 0.05) var GUIDE_HALO_SCALE := 2.1
## Phóng to hình neo so với cỡ khai trong anchor.tscn (1.0 = giữ nguyên). Neo to hơn = dễ thấy hơn
@export_range(1.0, 2.0, 0.05) var ANCHOR_SIZE_BOOST := 1.15
## Vùng chạm tối thiểu quanh neo (px)
@export var ANCHOR_MIN_TOUCH := 16.0
## Chạm NHẸ vào khe giữa 2 ô (không kéo) = bật/tắt 1 đoạn Tường Nghi Ngờ — nhanh hơn kéo 2 neo
@export var TAP_EDGE_TO_MARK := true
## Bề rộng vùng chạm quanh đường lưới (× bước ô, mỗi bên). 0.2 ≈ dải rộng 40% ô
@export_range(0.08, 0.3, 0.01) var EDGE_TAP_BAND := 0.2
## Khi bấm giữ 1 neo: các neo kề hợp lệ phóng to lên để người chơi thấy NỐI ĐƯỢC tới đâu
@export var ANCHOR_SHOW_CANDIDATES := true
@export_group("Paper (giấy học sinh)")
## Chừa biên TRONG tờ giấy (tỉ lệ so với TỜ GIẤY đặc, đã bỏ bóng đổ): trái, trên, phải, dưới.
## Trên chừa nhiều hơn để không đè lên băng keo + kẹp giấy.
@export var PAPER_INSET := Vector4(0.03, 0.075, 0.03, 0.035)
## Đặt lưới nằm hẳn bên PHẢI vạch lề đỏ của vở. Tắt (mặc định): lưới đè lên lề đỏ như tờ bảng
## dán trên trang vở — giữ nguyên cỡ ô. Bật: lưới nằm trong vùng viết, ô nhỏ đi ~15%.
@export var PAPER_AVOID_MARGIN := false
@export var PAPER_MARGIN_GAP := 14.0
@export_group("")

var _pen_down := false                       # ngón tay đang đặt xuống & kéo vẽ đường đi
var _pointer_last := Vector2.ZERO            # vị trí con trỏ ở sự kiện kéo trước (LOCAL)
var _finger := Vector2.ZERO                  # vị trí ngón tay mới nhất (LOCAL)
var _tip := Vector2.ZERO                     # ĐẦU BÚT hiển thị (đã làm mượt)
var _tip_prev := Vector2.ZERO
var _tip_dir := Vector2i.ZERO                # trục đuôi mực đang dùng (chống nhảy trục)
var _blocked_cell := Vector2i(-1, -1)        # ô vừa bị từ chối (đâm tường...) — khoá tới khi ngón tay rời ô
var _path_edge_keys: Dictionary = {}         # cạnh nằm trên đường đi hiện tại
var _cursor_block_t := 0.0                   # >0: đang chạy bonk/mìn, đừng ghi đè vị trí con trỏ
var _pending_run_finished := false
var _candidate_nodes: Array = []             # neo kề đang được phóng to khi kéo từ 1 neo


func _ready() -> void:
	set_process(false)
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
	var themes := Svc.theme()
	if themes == null or not themes.has_signal("skin_changed"):
		return
	if not themes.is_connected("skin_changed", _on_skin_changed):  # keep-code: nối/ngắt AUTOLOAD GameManager (không phải node tĩnh)
		themes.connect("skin_changed", _on_skin_changed)  # keep-code: signal của node sinh lúc chạy / biến thể (nối 1 chỗ khi tạo)


func _on_skin_changed(_theme_id: String, _pen_id: String) -> void:
	apply_pen_skin()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		if maze != null and _cell_nodes.size() > 0:
			_update_layout_positions()


## Lớp vẽ + nét mực + con trỏ + node MẪU đều KHAI SẴN trong scene (`Layers` = board_layers.tscn)
## ⇒ không instantiate lúc chạy: mỗi tầng mới chỉ RESET trạng thái và nhân bản từ node mẫu.
## Node binding: khai `node_paths` + NodePath trong `nodes/game/board.tscn`
@export var layers: BoardLayers = null


func _init_layers() -> void:
	if _cells_layer != null:
		return

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
	_feel = PenSkin.feel_of(_pen_id)
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
	_sheet_tex_rect = Rect2()
	_margin_tex_x = -1.0
	_tex_px = Vector2.ZERO
	# Panel là NinePatchRect (không phải TextureRect) — ép sai kiểu sẽ không đọc được gì
	var panel := get_node_or_null("Panel") as NinePatchRect
	if panel == null or panel.texture == null:
		return
	var img := panel.texture.get_image()
	if img == null or img.get_width() <= 0 or img.get_height() <= 0:
		return
	if img.is_compressed():
		img.decompress()
	_tex_px = Vector2(img.get_width(), img.get_height())

	# 1) Vùng GIẤY ĐẶC: lấy các pixel gần như đặc (alpha > 0.7) — bỏ bóng đổ mờ quanh tờ giấy
	const PROBE := 128
	var probe := img.duplicate() as Image
	probe.resize(PROBE, PROBE, Image.INTERPOLATE_BILINEAR)
	var min_x := PROBE
	var min_y := PROBE
	var max_x := -1
	var max_y := -1
	for y in PROBE:
		for x in PROBE:
			if probe.get_pixel(x, y).a > 0.7:
				min_x = mini(min_x, x)
				max_x = maxi(max_x, x)
				min_y = mini(min_y, y)
				max_y = maxi(max_y, y)
	if max_x >= min_x and max_y >= min_y:
		_sheet_tex_rect = Rect2(
			float(min_x) / PROBE * _tex_px.x, float(min_y) / PROBE * _tex_px.y,
			float(max_x + 1 - min_x) / PROBE * _tex_px.x, float(max_y + 1 - min_y) / PROBE * _tex_px.y)

	# 2) Vạch LỀ ĐỎ: quét 1 hàng ngang giữa ảnh (nửa trái), lấy mép phải của vạch đỏ đầu tiên
	var row := int(_tex_px.y * 0.5)
	var in_line := false
	for x in range(0, int(_tex_px.x * 0.4)):
		var c := img.get_pixel(x, row)
		var is_red := c.a > 0.5 and c.r > 0.7 and c.r - c.g > 0.3 and c.r - c.b > 0.3
		if is_red:
			in_line = true
			_margin_tex_x = float(x + 1)
		elif in_line:
			break


## Đổi toạ độ pixel TEXTURE → toạ độ điều khiển (control) của Panel theo luật NinePatch:
## góc không co giãn, phần giữa co theo kích thước Panel.
func _nine_map(tex_v: float, horizontal: bool) -> float:
	var panel := get_node_or_null("Panel") as NinePatchRect
	if panel == null:
		return tex_v
	var tex_len := _tex_px.x if horizontal else _tex_px.y
	var ctrl_len := panel.size.x if horizontal else panel.size.y
	var m_a := float(panel.patch_margin_left if horizontal else panel.patch_margin_top)
	var m_b := float(panel.patch_margin_right if horizontal else panel.patch_margin_bottom)
	if tex_len <= 0.0:
		return tex_v
	if tex_len <= m_a + m_b or ctrl_len <= m_a + m_b:
		return tex_v / tex_len * ctrl_len
	if tex_v <= m_a:
		return tex_v
	if tex_v >= tex_len - m_b:
		return ctrl_len - (tex_len - tex_v)
	return m_a + (tex_v - m_a) * (ctrl_len - m_a - m_b) / (tex_len - m_a - m_b)


## Vùng giấy vẽ thật (toạ độ cục bộ của Board) - dùng để canh lưới + cho test:
## TỜ GIẤY đặc (bỏ bóng đổ) trừ biên PAPER_INSET, và (tuỳ chọn) nằm bên phải lề đỏ.
func panel_inner_rect() -> Rect2:
	var panel: Control = get_node_or_null("Panel") as Control
	if panel == null:
		return Rect2(Vector2.ZERO, size)
	var full := Rect2(panel.position, panel.size)
	if _sheet_tex_rect.size.x <= 0.0 or _sheet_tex_rect.size.y <= 0.0 or _tex_px.x <= 0.0:
		return full
	var l := _nine_map(_sheet_tex_rect.position.x, true)
	var t := _nine_map(_sheet_tex_rect.position.y, false)
	var r := _nine_map(_sheet_tex_rect.end.x, true)
	var b := _nine_map(_sheet_tex_rect.end.y, false)
	var sheet_w := r - l
	var sheet_h := b - t
	l += PAPER_INSET.x * sheet_w
	t += PAPER_INSET.y * sheet_h
	r -= PAPER_INSET.z * sheet_w
	b -= PAPER_INSET.w * sheet_h
	if PAPER_AVOID_MARGIN and _margin_tex_x >= 0.0:
		l = maxf(l, _nine_map(_margin_tex_x, true) + PAPER_MARGIN_GAP)
	if r - l <= 1.0 or b - t <= 1.0:
		return full
	return Rect2(panel.position + Vector2(l, t), Vector2(r - l, b - t))


## Nhân bản node MẪU khai sẵn trong scene (thay cho `PackedScene.instantiate()` lúc chạy):
## bật lại hiển thị + đưa về gốc toạ độ (node mẫu trong scene luôn ẩn).
func _spawn_template(template: Node) -> Node:
	if template == null:
		return null
	var node := template.duplicate()
	var item := node as CanvasItem
	if item != null:
		item.visible = true  # keep-code: trạng thái theo dữ liệu (runtime)
	var control := node as Control
	if control != null:
		control.position = Vector2.ZERO  # keep-code: pose hoạt cảnh runtime (tween)
	else:
		var node2d := node as Node2D
		if node2d != null:
			node2d.position = Vector2.ZERO  # keep-code: pose hoạt cảnh runtime (tween)
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

	var anchor_side := maxf(_anchor_size * _fit_scale * ANCHOR_SIZE_BOOST, MIN_ANCHOR_SIZE)
	for info in _anchor_nodes:
		var anchor: MazeAnchor = info.node
		anchor.set_anchor_size(anchor_side)    # cỡ neo + tâm xoay (neo tự lo)
	_anchor_hit_radius = maxf(maxf(_anchor_size * 0.75 * _fit_scale, anchor_side * 0.5), ANCHOR_MIN_TOUCH)
	# Không để vùng chạm của 2 neo kề nhau chồng lên nhau
	_anchor_hit_radius = minf(_anchor_hit_radius, maxf(_step * 0.42, anchor_side * 0.5))

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
	# set_line_width: tường người chơi tự đánh dấu tự dày hơn + quầng sáng theo kịp (xem wall_segment.gd)
	for key in _wall_segments:
		(_wall_segments[key] as WallSegment).set_line_width(width)
	for key in _suspected_lines:
		(_suspected_lines[key] as WallSegment).set_line_width(width)
	for key in _history_lines:
		(_history_lines[key] as Line2D).width = width
	if _drag_guide_line != null:
		_drag_guide_line.width = width * GUIDE_WIDTH_SCALE
		_set_guide_points(_drag_guide_line.points)
	if _moving_line != null:
		var line_width := maxf(_moving_line_width * _fit_scale, MIN_WALL_WIDTH)
		_moving_line.set_base_width(line_width)
		_moving_line.set_metrics(_step, _fit_scale)


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
	_snap_tip_to_center()

	# Nét ĐÃ VẼ (đường đang đi · vệt mực cũ · đường kéo neo) nhớ danh sách Ô, nhưng pixel
	# đã dựng từ lưới CŨ ⇒ vẽ lại theo lưới mới, nếu không đường đi nằm lệch khỏi các ô.
	_refresh_drawn_strokes()


## Vẽ lại mọi nét mực ĐÃ VẼ theo lưới hiện tại — gọi khi cửa sổ đổi cỡ / bàn cờ đổi chỗ.
## Nét chỉ nhớ Ô (nguồn sự thật) nên chỉ cần suy lại tâm ô mới.
func _refresh_drawn_strokes() -> void:
	if _moving_line != null and not _moving_path.is_empty():
		_push_path_to_stroke()

	for key: String in _history_lines:
		var line: Line2D = _history_lines[key]
		if not is_instance_valid(line) or not line.has_meta("cell_a"):
			continue
		var a: Vector2i = line.get_meta("cell_a")
		var b: Vector2i = line.get_meta("cell_b")
		line.points = PackedVector2Array([_cell_center(a), _cell_center(b)])

	# Đường kéo neo (nếu đang kéo dở): bám lại 2 đầu theo lưới mới
	if _drag_guide_line != null and _is_dragging_anchor and _drag_source_anchor_id != -1:
		_set_guide_points(PackedVector2Array(
			[_anchor_center_pos(_drag_source_anchor_corner), _drag_guide_other_end()]))


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
			c.set_anchors_preset(Control.PRESET_TOP_LEFT)  # keep-code: ô sinh lúc chạy — đặt anchor khi dựng
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
	seg.set_line_width(_scaled_wall_width())
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
			a.set_anchors_preset(Control.PRESET_TOP_LEFT)  # keep-code: neo sinh lúc chạy — đặt anchor khi dựng
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
	_moving_line.position = Vector2.ZERO  # keep-code: pose hoạt cảnh runtime (tween)
	_moving_path.clear()
	_path_edge_keys.clear()
	_pen_down = false
	_blocked_cell = Vector2i(-1, -1)
	_cursor_block_t = 0.0
	set_process(false)
	# width/default_color lấy nguyên từ moving_line.tscn
	_set_line_points(_moving_line, PackedVector2Array())
	_snap_tip_to_center()


## Đường kẻ chỉ dẫn khi KÉO NEO (cùng loại nét với moving_line, ẩn đến khi cần)
func _build_drag_guide_line() -> void:
	if _drag_guide_line == null:
		return
	_drag_guide_line.position = Vector2.ZERO  # keep-code: pose hoạt cảnh runtime (tween)
	_drag_guide_line.width = _wall_width * GUIDE_WIDTH_SCALE
	_drag_guide_line.default_color = Color(0.77, 0.52, 0.23, 0.97)
	_drag_guide_line.visible = false  # keep-code: trạng thái theo dữ liệu (runtime)
	_ensure_guide_halo()
	_set_line_points(_drag_guide_line, PackedVector2Array())
	_set_guide_points(PackedVector2Array())


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
	_snap_tip_to_center()
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

	# Hiệu ứng vệt chân mực lan nhẹ khi cất bước (tắt khi viết: nét mực đã liền mạch)
	if FOOTSTEP_ON_STEP or not WRITING_MODE:
		_spawn_ink_footstep(from_center)

	# SFX: chấm bút chì khi vào tâm ô mới; thêm tiếng "vào cầu thang" khi tới ô F
	Sfx.play(Sfx.CELL_STEP)
	if pos == maze.get_end():
		Sfx.play(Sfx.STAIRS_ENTER)
		if _cursor != null:
			_cursor.play_celebration()

	if WRITING_MODE:
		# Đầu bút TRƯỢT mượt tới tâm ô mới (xem `_process`) — nét mực dài ra liên tục theo đầu bút,
		# không còn nhún nhảy / nhảy cóc giữa các ô.
		_tip_dir = Vector2i.ZERO
		_pending_run_finished = true
		set_process(true)
	else:
		# Chạy animation bước nhảy (Hop / Squash & Stretch / Tilt)
		_cursor.run_to(target_pos, move_dir, 0.16)

	if PULSE_CELLS_WHILE_WRITING or not WRITING_MODE or not _pen_down:
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
	# Không có đầu bút nào đang trượt (hoàn tác · khởi động lại · gợi ý...) -> nét dừng đúng cuối đường mới,
	# tránh đuôi mực cũ còn sót lại.
	if not is_processing() and not _moving_path.is_empty():
		_tip = _cell_center(_moving_path[_moving_path.size() - 1])
		_tip_prev = _tip
	_push_path_to_stroke()
	_refresh_path_edge_keys()
	_set_path_focus(path)


## Dựng lại nét mực từ danh sách Ô (tâm ô theo lưới hiện tại) + đầu bút hiện tại
func _push_path_to_stroke() -> void:
	if _moving_line == null:
		return
	var pts := PackedVector2Array()
	for p in _moving_path:
		pts.append(_cell_center(p))
	_moving_line.set_metrics(_step, _fit_scale)
	_moving_line.set_path_vertices(pts)
	_moving_line.set_tip(_tip, true)


## Ghi nhớ các CẠNH nằm trên đường đi hiện tại + ẩn vệt mờ (history) trùng dưới nét
func _refresh_path_edge_keys() -> void:
	_path_edge_keys.clear()
	for i in range(1, _moving_path.size()):
		_path_edge_keys[_cell_edge_key(_moving_path[i - 1], _moving_path[i])] = true
	for key: String in _history_lines:
		var line: Line2D = _history_lines[key]
		if is_instance_valid(line):
			line.visible = not (HIDE_HISTORY_UNDER_PATH and _path_edge_keys.has(key))


func reset_to_start() -> void:
	if maze == null or _cursor == null:
		return
	_player_current_cell = maze.get_start()
	var target_pos := cursor_pos_at(_cell_center(maze.get_start()))

	# (GIỮ tween) Vị trí đích = TÂM Ô theo lưới tính lúc chạy (phụ thuộc kích thước lưới/cỡ ô)
	var tw := create_tween()
	tw.tween_property(_cursor, "position", target_pos, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	set_moving_path([maze.get_start()])
	_snap_tip_to_center()


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
	line.visible = not (HIDE_HISTORY_UNDER_PATH and _path_edge_keys.has(key))
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

	# Mực thụt về tâm ô ngay khi va chạm, rồi con trỏ mới giật nảy (Bonk recoil)
	_snap_pen_for_impact()
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

	_snap_pen_for_impact()
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
## Đếm ngược nằm ở popup riêng (xem scripts/ui/popups/memory_countdown.gd) — KHÔNG vẽ label
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


## Cập nhật HIỂN THỊ từng ô theo chế độ chơi (số · lớp mực · ô đã đi · sương mù).
## Phần duyệt ô nằm ở `BoardCellsView`; board chỉ truyền cách tra node theo toạ độ.
func refresh_cell_texts(dim_unwalkable: bool = false) -> void:
	BoardCellsView.refresh_texts(_width, _height, _cell_node, maze, game_mode,
			dim_unwalkable, _sync_bomb_marker)


func apply_fog_of_war(_center: Vector2i, _radius: int, explored: Dictionary) -> void:
	BoardCellsView.apply_fog(_width, _height, _cell_node, maze, game_mode,
			explored, _sync_bomb_marker)




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
			seg.visible = false  # keep-code: trạng thái theo dữ liệu (runtime)


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
	_cursor.visible = true  # keep-code: trạng thái theo dữ liệu (runtime)
	var p1 := cursor_pos_at(_cell_center(from_cell))
	var p2 := cursor_pos_at(_cell_center(to_cell))
	_cursor.play_demo_drag(p1, p2, duration)


## Trình diễn chạm/nhấp con trỏ tại ô
func animate_cursor_tap(cell: Vector2i) -> void:
	if _cursor == null:
		return
	_player_hidden = false
	_cursor.visible = true  # keep-code: trạng thái theo dữ liệu (runtime)
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
		_cursor.visible = false  # keep-code: trạng thái theo dữ liệu (runtime)


## Trình diễn cursor di chuyển qua chuỗi ô (dùng cho demo full-path, lặp)
func animate_cursor_path(path: Array[Vector2i], dur_per_step: float = 0.45) -> void:
	if _cursor == null or path.size() < 2:
		return
	_player_hidden = false
	_cursor.visible = true  # keep-code: trạng thái theo dữ liệu (runtime)
	var positions: Array[Vector2] = []
	for cell in path:
		positions.append(cursor_pos_at(_cell_center(cell)))
	_cursor.play_demo_path(positions, dur_per_step)


## Trình diễn cursor thử đi đè lên ô đã đi: di chuyển nửa đường rồi nảy lại (1 chu kỳ)
func animate_cursor_fail_attempt(from_cell: Vector2i, toward_cell: Vector2i) -> void:
	if _cursor == null:
		return
	_player_hidden = false
	_cursor.visible = true  # keep-code: trạng thái theo dữ liệu (runtime)
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
		_end_pen_down()
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
		_end_pen_down()
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
		_begin_pen_down(local_pos)


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
		_finger = local_pos
		# Lấy mẫu dọc đường ngón tay đã đi từ sự kiện trước tới giờ — quẹt nhanh vẫn không lọt ô
		_sample_pointer_path(_pointer_last, local_pos)
		_pointer_last = local_pos


func _on_release(local_pos: Vector2) -> void:
	if _is_dragging_anchor:
		_finish_anchor_drag(local_pos)
		_dragging_player = false
		_pressed_cell = Vector2i(-1, -1)
		_has_dragged = false
		return

	# Chạm nhẹ vào khe giữa 2 ô (không kéo) ⇒ bật/tắt đoạn Tường Nghi Ngờ ở khe đó
	if _dragging_player and TAP_EDGE_TO_MARK and not _has_dragged \
			and local_pos.distance_to(_press_start_pos) <= 12.0:
		var edge := _edge_at(_press_start_pos)
		if not edge.is_empty():
			_mark_edge_by_tap(edge[0], edge[1])

	if _dragging_player:
		_dragging_player = false
	_end_pen_down()

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
	_drag_guide_line.visible = true  # keep-code: trạng thái theo dữ liệu (runtime)
	_set_guide_points(PackedVector2Array([anchor_center, anchor_center]))
	_show_anchor_candidates(_drag_source_anchor_corner)


func _update_anchor_drag(local_pos: Vector2) -> void:
	if not _is_dragging_anchor or _drag_source_anchor_id == -1:
		return

	_drag_guide_last_local = local_pos
	var anchor_a_pos := _anchor_center_pos(_drag_source_anchor_corner)
	if ANCHOR_AXIS_SNAP:
		_update_anchor_drag_axis(local_pos, anchor_a_pos)
		return
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
				_set_guide_points(PackedVector2Array([anchor_a_pos, target_pos]))
				return

	_clear_hover_target_highlight()
	_hover_target_anchor_id = -1
	_set_guide_points(PackedVector2Array([anchor_a_pos, local_pos]))


func _finish_anchor_drag(local_pos: Vector2) -> void:
	if not _is_dragging_anchor:
		return

	var target_anchor := _hit_anchor_info(local_pos)
	var target_id := -1
	if ANCHOR_AXIS_SNAP:
		# Nét chỉ dẫn đã tự hít vào neo kề: thả tay ở đâu cũng nối đúng neo đang sáng
		target_id = _hover_target_anchor_id
	elif not target_anchor.is_empty() and target_anchor.has("node"):
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
	_clear_anchor_candidates()
	_clear_hover_target_highlight()
	if _drag_source_anchor_id != -1:
		var src_node := _get_anchor_node(_drag_source_anchor_id)
		if src_node != null:
			src_node.set_selected(false)

	if _drag_guide_line != null:
		_drag_guide_line.visible = false  # keep-code: trạng thái theo dữ liệu (runtime)

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
	# Chọn neo GẦN NHẤT trong vùng chạm (không phải neo đầu tiên tìm thấy)
	var best: Dictionary = {}
	var best_d := INF
	for info in _anchor_nodes:
		var node: MazeAnchor = info.node
		var center: Vector2 = node.position + node.size * 0.5
		var d := center.distance_to(local_pos)
		if d <= _anchor_hit_radius and d < best_d:
			best = info
			best_d = d
	return best


## Ô chứa điểm `local_pos` — tính số học O(1) (không duyệt cả bảng mỗi sự kiện kéo)
func _hit_cell(local_pos: Vector2) -> Vector2i:
	return _cell_at(local_pos)


func _cell_at(local_pos: Vector2) -> Vector2i:
	if _col_edge_x.is_empty() or _row_edge_y.is_empty() or _step <= 0.0:
		return Vector2i(-1, -1)
	var ix := int(floor((local_pos.x - float(_col_edge_x[0])) / _step))
	var iy := int(floor((local_pos.y - float(_row_edge_y[0])) / _step))
	if ix < 0 or iy < 0 or ix >= _width or iy >= _height:
		return Vector2i(-1, -1)
	var pos := Vector2i(ix, iy)
	if maze != null and not maze.is_cell_active(pos):
		return Vector2i(-1, -1)      # ô ngoài board: không bấm được
	return pos


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
	# Đầu bút của TỪNG bút nằm ở chỗ khác nhau trong icon (PenSkin.tip_uv → cursor.tip_uv)
	return center - _cursor.tip_uv * _cursor.size


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


# ============================================================================
# BÚT VIẾT: lấy mẫu ngón tay · đuôi mực · đầu bút trượt mượt
#
#   Mô hình: LOGIC vẫn rời rạc theo ô (controller chỉ nhận `drag_updated(cell)` như cũ),
#   còn HIỂN THỊ liên tục:
#     ngón tay ──▶ `_tail_target()` (đuôi mực bò theo trục, tối đa nửa ô)
#              ──▶ `_tip` (đầu bút, làm mượt) ──▶ InkStroke.set_tip() + PlayerCursor.write_at()
#   Khi ngón tay vượt mép ô kề ⇒ chốt ô (signal) ⇒ đầu bút trượt nốt tới tâm ô mới.
# ============================================================================
func _begin_pen_down(local_pos: Vector2) -> void:
	_pen_down = true
	_pointer_last = local_pos
	_finger = local_pos
	_blocked_cell = Vector2i(-1, -1)
	_tip_dir = Vector2i.ZERO
	if not WRITING_MODE:
		return
	if _cursor != null and _cursor.visible and not _player_hidden and _cursor_block_t <= 0.0:
		_cursor.begin_writing()
	set_process(true)


## Nhấc ngón tay: đầu bút tự rút về tâm ô (xem `_process`), xong thì nhả bút
func _end_pen_down() -> void:
	_pen_down = false
	_blocked_cell = Vector2i(-1, -1)


## Đặt đầu bút đúng tâm ô hiện tại, không hoạt ảnh
func _snap_tip_to_center() -> void:
	_tip = _cell_center(_player_current_cell)
	_tip_prev = _tip
	if _moving_line != null:
		_moving_line.set_tip(_tip, true)


## Trước hiệu ứng va chạm (tường · mìn): mực thụt về tâm ô, con trỏ về dáng chuẩn
func _snap_pen_for_impact() -> void:
	_snap_tip_to_center()
	_cursor_block_t = 0.3
	if _cursor != null:
		_cursor.stop_writing_immediate()
		_cursor.position = cursor_pos_at(_tip)
	if WRITING_MODE:
		set_process(true)


func _process(delta: float) -> void:
	if maze == null or _width <= 0:
		set_process(false)
		return
	if _cursor_block_t > 0.0:
		_cursor_block_t -= delta

	var center := _cell_center(_player_current_cell)
	var target := center
	if _pen_down and not _player_hidden and _cursor_block_t <= 0.0:
		target = _tail_target(center)

	_tip_prev = _tip
	_tip = _tip.lerp(target, 1.0 - exp(-delta * TIP_FOLLOW_SPEED * float(_feel.get("follow", 1.0))))
	if _tip.distance_squared_to(target) < 0.12:
		_tip = target
	_apply_tip_visual(delta)

	if not _pen_down and _tip == target and _cursor_block_t <= 0.0:
		_finish_pen_visual()


## Điểm đầu bút MUỐN tới: tâm ô, hoặc tâm ô + đuôi mực bò theo trục về phía ngón tay
func _tail_target(center: Vector2) -> Vector2:
	var d := _finger - center
	var ax := absf(d.x)
	var ay := absf(d.y)
	if ax > _step * 1.6 or ay > _step * 1.6:
		return center                      # ngón tay ở xa bút: bút đứng yên
	# Chọn trục (có "trễ" để đuôi mực không nhảy trục khi ngón tay đi chéo)
	var use_x: bool
	if _tip_dir.x != 0:
		use_x = ax * 1.25 >= ay
	elif _tip_dir.y != 0:
		use_x = ax > ay * 1.25
	else:
		use_x = ax >= ay
	var dir := Vector2i.ZERO
	var along := 0.0
	if use_x:
		dir = Vector2i(1 if d.x > 0.0 else -1, 0)
		along = ax
	else:
		dir = Vector2i(0, 1 if d.y > 0.0 else -1)
		along = ay
	var length := clampf((along - TAIL_DEADZONE * _step) * TAIL_GAIN * float(_feel.get("tail", 1.0)),
		0.0, TAIL_MAX * _step)
	if length <= 0.0:
		_tip_dir = Vector2i.ZERO
		return center
	_tip_dir = dir

	var nb := _player_current_cell + dir
	# Không kéo đuôi mực ngược về ô vừa đi qua (đó là quay lui, để bút tự lùi khi chốt)
	if _moving_path.size() >= 2 and nb == _moving_path[_moving_path.size() - 2]:
		return center
	if nb == _blocked_cell:
		return center                      # ô vừa bị từ chối: bút "cứng" lại
	var open_cell := nb.x >= 0 and nb.y >= 0 and nb.x < _width and nb.y < _height \
			and maze != null and maze.is_cell_active(nb)
	if not open_cell:
		length = minf(length, _step * 0.08)    # ngoài board: chỉ nhích nhẹ như bị cản
	return center + Vector2(dir) * length


func _apply_tip_visual(delta: float) -> void:
	if _moving_line != null:
		_moving_line.set_tip(_tip, true)
	if _cursor == null or _cursor_block_t > 0.0 or not WRITING_MODE:
		return
	if _pen_down and _cursor.visible and not _cursor.is_writing():
		_cursor.begin_writing()
	if _cursor.is_writing():
		var vx := (_tip.x - _tip_prev.x) / maxf(delta, 0.001)
		var lean_k := float(_feel.get("lean", 1.0))
		_cursor.write_at(_tip, clampf(vx * LEAN_PER_SPEED * lean_k, -LEAN_MAX * lean_k, LEAN_MAX * lean_k), delta)
	else:
		_cursor.position = cursor_pos_at(_tip)


## Đầu bút đã về tâm ô và ngón tay đã nhấc: nhả bút, dừng vòng cập nhật
func _finish_pen_visual() -> void:
	set_process(false)
	_snap_tip_to_center()
	if _cursor != null:
		_cursor.position = cursor_pos_at(_tip)
		_cursor.end_writing()
		if _pending_run_finished:
			_cursor.notify_run_finished()
	_pending_run_finished = false


## Đi dọc đoạn from→to, mỗi ~¼ ô thử chốt ô nếu ngón tay đã vào ô kề
func _sample_pointer_path(from: Vector2, to: Vector2) -> void:
	var spacing := maxf(_step * SAMPLE_SPACING, 2.0)
	var count := maxi(1, int(ceil(from.distance_to(to) / spacing)))
	for i in range(1, count + 1):
		if not _try_step_at(from.lerp(to, float(i) / float(count))):
			return


## Trả về false khi bước bị từ chối (dừng lấy mẫu tiếp trong sự kiện này)
func _try_step_at(p: Vector2) -> bool:
	var cell := _cell_at(p)
	if cell == Vector2i(-1, -1):
		return true
	if cell != _blocked_cell:
		_blocked_cell = Vector2i(-1, -1)     # ngón tay đã rời ô bị từ chối ⇒ mở khoá
	else:
		return true                          # vẫn kẹt trong ô vừa bị từ chối: không gửi lại liên tục
	if cell == _player_current_cell or not _is_adjacent(_player_current_cell, cell):
		return true
	# Chỉ lướt qua mép góc của ô kề thì chưa tính
	var c := _cell_center(cell)
	var dir := cell - _player_current_cell
	var off := absf(p.y - c.y) if dir.x != 0 else absf(p.x - c.x)
	if off > _step * (0.5 - CORNER_GUARD):
		return true

	var before := _player_current_cell
	drag_updated.emit(cell)
	if _player_current_cell == before:
		_blocked_cell = cell
		return false
	if HAPTIC_ON_STEP and OS.has_feature("mobile"):
		Input.vibrate_handheld(maxi(1, int(round(HAPTIC_MS * float(_feel.get("haptic", 8)) / 8.0))), 0.35)
	return true


# ----------------------------------------------------------------------------
# Kéo neo kiểu "viết": nét chỉ dẫn bò theo trục lưới, hít vào neo kề
# ----------------------------------------------------------------------------
func _update_anchor_drag_axis(local_pos: Vector2, anchor_a_pos: Vector2) -> void:
	var d := local_pos - anchor_a_pos
	var along_x := absf(d.x) >= absf(d.y)
	var dir := Vector2i.ZERO
	var along := 0.0
	if along_x:
		dir = Vector2i(1 if d.x > 0.0 else -1, 0)
		along = absf(d.x)
	else:
		dir = Vector2i(0, 1 if d.y > 0.0 else -1)
		along = absf(d.y)

	var target_corner := _drag_source_anchor_corner + dir
	var target_info := _anchor_info_at_corner(target_corner)
	var valid := not target_info.is_empty() \
			and not _corner_edge(_drag_source_anchor_corner, target_corner).is_empty()

	var length := minf(along, _step)
	var engage_at := _step * (1.0 - ANCHOR_MAGNET)
	if valid and along >= engage_at:
		var node: MazeAnchor = target_info.node
		if _hover_target_anchor_id != node.anchor_id:
			_clear_hover_target_highlight()
			_hover_target_anchor_id = node.anchor_id
			node.set_selected(true)
			Sfx.play(Sfx.ANCHOR_SNAP)
		# Hít dần vào tâm neo kề (mượt, không giật)
		var m := smoothstep(engage_at, _step * 0.85, along)
		length = lerpf(along, _step, m)
	else:
		_clear_hover_target_highlight()
		_hover_target_anchor_id = -1
		if not valid:
			length = minf(length, _step * 0.35)    # hướng không có neo: nét chỉ bò ngắn như bị cản
	_set_guide_points(PackedVector2Array([anchor_a_pos, anchor_a_pos + Vector2(dir) * length]))


func _anchor_info_at_corner(corner: Vector2i) -> Dictionary:
	for info in _anchor_nodes:
		if info.corner == corner:
			return info
	return {}


# ----------------------------------------------------------------------------
# Đặt hint dễ hơn: chạm vào khe · neo kề sáng lên
# ----------------------------------------------------------------------------
## Khe (cạnh giữa 2 neo kề) gần điểm `p` nhất, trong dải EDGE_TAP_BAND quanh đường lưới.
## Trả [corner_a, corner_b] hoặc [] nếu không có khe hợp lệ (ngoài board / thiếu neo).
func _edge_at(p: Vector2) -> Array:
	if _col_edge_x.is_empty() or _row_edge_y.is_empty() or _step <= 0.0:
		return []
	var fx := (p.x - float(_col_edge_x[0])) / _step      # toạ độ lưới (đơn vị ô)
	var fy := (p.y - float(_row_edge_y[0])) / _step
	var nx := roundi(fx)
	var ny := roundi(fy)
	var dx := absf(fx - float(nx))
	var dy := absf(fy - float(ny))
	var a := Vector2i.ZERO
	var b := Vector2i.ZERO
	if dx <= dy and dx <= EDGE_TAP_BAND:
		var j := int(floor(fy))
		a = Vector2i(nx, j)
		b = Vector2i(nx, j + 1)
	elif dy < dx and dy <= EDGE_TAP_BAND:
		var i := int(floor(fx))
		a = Vector2i(i, ny)
		b = Vector2i(i + 1, ny)
	else:
		return []
	var edge := _corner_edge(a, b)
	if edge.is_empty() or not _edge_touches_board(edge[0], edge[1]):
		return []
	if _anchor_info_at_corner(a).is_empty() or _anchor_info_at_corner(b).is_empty():
		return []
	return [a, b]


## Giống hệt kéo nối 2 neo: phát `anchor_connected` để controller bật/tắt Tường Nghi Ngờ
func _mark_edge_by_tap(a: Vector2i, b: Vector2i) -> void:
	anchor_connected.emit(a, b)
	Sfx.play(Sfx.WALL_MARK)
	for corner in [a, b]:
		var info := _anchor_info_at_corner(corner)
		if not info.is_empty():
			(info.node as MazeAnchor).pulse()


## Phóng to các neo kề NỐI ĐƯỢC từ `corner` (đang bấm giữ) — thấy ngay mình có thể kéo tới đâu
func _show_anchor_candidates(corner: Vector2i) -> void:
	_clear_anchor_candidates()
	if not ANCHOR_SHOW_CANDIDATES:
		return
	for dir in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var other: Vector2i = corner + dir
		var info := _anchor_info_at_corner(other)
		if info.is_empty():
			continue
		var edge := _corner_edge(corner, other)
		if edge.is_empty() or not _edge_touches_board(edge[0], edge[1]):
			continue
		var node := info.node as MazeAnchor
		_candidate_nodes.append(node)
		var tw := node.create_tween()
		tw.tween_property(node, "scale", Vector2.ONE * 1.5, 0.14) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _clear_anchor_candidates() -> void:
	for node in _candidate_nodes:
		if is_instance_valid(node):
			var tw := (node as Node).create_tween()
			tw.tween_property(node, "scale", Vector2.ONE, 0.10)
	_candidate_nodes.clear()


# ----------------------------------------------------------------------------
# Nét chỉ dẫn kéo neo: thêm QUẦNG GIẤY SÁNG phía sau để nổi trên đường kẻ ô
# ----------------------------------------------------------------------------
var _guide_halo: Line2D = null


func _ensure_guide_halo() -> void:
	if _drag_guide_line == null:
		return
	if _guide_halo != null and is_instance_valid(_guide_halo):
		return
	_guide_halo = Line2D.new()
	_guide_halo.name = "Halo"
	_guide_halo.show_behind_parent = true
	_guide_halo.joint_mode = Line2D.LINE_JOINT_ROUND
	_guide_halo.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_guide_halo.end_cap_mode = Line2D.LINE_CAP_ROUND
	_guide_halo.default_color = Color(1.0, 0.99, 0.94, 0.95)
	_drag_guide_line.add_child(_guide_halo)


func _set_guide_points(pts: PackedVector2Array) -> void:
	if _drag_guide_line == null:
		return
	_drag_guide_line.points = pts
	if _guide_halo != null and is_instance_valid(_guide_halo):
		_guide_halo.points = pts
		_guide_halo.width = _drag_guide_line.width * GUIDE_HALO_SCALE
