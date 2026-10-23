class_name LevelMap
extends Node2D
## ============================================================================
## LevelMap — Bản đồ road map dọc của màn Chọn màn
##
## Bố cục: các nút màn xếp kiểu RẮN (snake) từ dưới lên (màn 1 ở dưới cùng, hàng chẵn đi
## trái→phải, hàng lẻ phải→trái), nối nhau bằng MỘT đường `LevelMapPath` có cung quay đầu ở
## mép. Bản DỌC 3 cột · bản NGANG 5 cột (số đo bản ngang tính theo khung thiết kế 960×540 rồi
## nhân `design_unit()`). Cuộn bản đồ bằng cách dịch node `Tracks` (KHÔNG dùng Camera2D).
##
## Màn BONUS (cuối chương, `bonus_ids`) vẽ bằng nút màu cam + băng "BONUS"; cờ đích cắm ở màn
## CHÍNH cuối cùng. (Kiểu zigzag cũ chỉ còn khi đặt cột = 0.)
##
## Quy ước của project (CẤU HÌNH TĨNH nằm trong `level_map.tscn`):
##   · `Tracks` — node dịch chuyển khi cuộn (bind `@export`)
##   · `Tracks/Items` — nơi sinh các nút màn + đường nối (script chỉ dọn/nhân bản ở đây)
##   · `Tracks/Goal` — cờ đích ở đầu bản đồ (animation "wave" autoplay trong scene)
##   · `Tracks/Marker` — mũi chỉ "màn tiếp theo" (animation "bob" autoplay trong scene)
## Script chỉ CANH vị trí các node có sẵn; duy nhất nút màn/đường nối được sinh theo
## dữ liệu chương (số màn thay đổi) nên phải instantiate trong `Items`.
##
## Vị trí/cỡ nút tự thích ứng khung `MapArea` (cha): màn NGANG thì nút to hơn, khoảng
## cách và zigzag rộng hơn. Cuộn xong phát `scrolled` để nền giấy parallax trượt theo.
## ============================================================================

signal level_selected(level_id: int)
## Độ dịch cuộn THẬT của bản đồ (px) so với GIỮA khoảng cuộn — `Background` dùng để trượt
## parallax: nền chạy theo đúng nhịp ngón tay (tỉ lệ cố định), không phụ thuộc chương
## dài/ngắn như khi quy về tiến độ [-1..1].
signal scrolled(delta_y: float)

## ============================================================================
## CẤU HÌNH — chỉnh trực tiếp trong Inspector (mỗi scene override riêng được)
## ============================================================================
@export_group("Scene con")
## Scene nút màn + scene đường nối (đổi art/logic không cần sửa code)
@export var node_scene: PackedScene = preload("res://nodes/level_selection/level_node.tscn")
@export var path_scene: PackedScene = preload("res://nodes/level_selection/level_path.tscn")

@export_group("Bố cục")
## Số CỘT của bản đồ kiểu RẮN (snake): hàng 0 ở ĐÁY đi trái→phải, hàng 1 đi phải→trái…
## `0` = giữ kiểu zigzag cũ (2 cột lệch nhau).
@export_range(0, 8, 1) var columns := 3
@export_range(0, 8, 1) var columns_landscape := 5
## Bản DỌC (px canvas): khoảng cách tâm 2 nút theo trục X / Y, độ phình cung quay đầu
## (tính theo "đơn vị nút" ⇒ nhân `node_scale`), dịch cả cụm cột sang PHẢI (dành lề trái cho thanh thưởng dọc)
@export_range(60.0, 260.0, 1.0) var column_spacing := 120.0
@export_range(80.0, 320.0, 1.0) var row_spacing := 170.0
@export_range(0.0, 200.0, 1.0) var turn_bulge := 76.0
@export_range(-200.0, 200.0, 1.0) var snake_center_shift := 50.0
## Cỡ nút ở bản dọc (art nút hiển thị 112px ở scale 1 ⇒ 0.68 cho mặt nút ≈ 62px như mockup)
@export_range(0.2, 2.5, 0.01) var node_scale_portrait := 0.68
## Bản NGANG — số đo theo KHUNG THIẾT KẾ 960×540, tự nhân với `design_unit()` (= độ phóng của khung)
@export_range(60.0, 260.0, 1.0) var column_spacing_landscape := 118.0
@export_range(80.0, 320.0, 1.0) var row_spacing_landscape := 140.0
@export_range(0.0, 200.0, 1.0) var turn_bulge_landscape := 106.0
@export_range(-200.0, 200.0, 1.0) var snake_center_shift_landscape := 0.0
@export_range(0.2, 2.5, 0.01) var node_scale_landscape := 0.68
## Khoảng cách tâm 2 nút theo trục Y (px) và độ lệch zigzag quanh tâm — theo hướng màn hình
@export_range(80.0, 400.0, 1.0) var spacing_portrait := 158.0
@export_range(100.0, 600.0, 1.0) var spacing_landscape := 200.0
@export_range(0.0, 300.0, 1.0) var zigzag_portrait := 74.0
@export_range(0.0, 800.0, 1.0) var zigzag_landscape := 320.0
## Độ uốn ngang của đường nối tại điểm giữa mỗi đoạn (dáng chữ S như mockup):
## lấy theo nhịp dọc SPACING × tỉ lệ này, nhưng KẸP lại để không tràn khỏi khung.
## Dùng khi 2 nút liền nhau lệch chủ yếu theo trục DỌC (bản dọc: nút xếp gần như thẳng cột
## ⇒ cần uốn NGANG mới ra dáng chữ S).
@export_range(0.0, 2.0, 0.05) var sway_spacing_ratio := 0.6
## Tỉ lệ uốn khi 2 nút liền nhau lệch chủ yếu theo trục NGANG (bản ngang: zigzag đã tạo sẵn
## dáng uốn lượn, uốn VUÔNG GÓC thêm làm tiếp tuyến Catmull-Rom quá lớn ⇒ đường TỰ CẮT
## thành vòng — đã gặp thật). Đo ở canvas 1635×920 (nút cách nhau 640×200): tỉ lệ ≤ 0,30
## (uốn ≤ 60 px) không tự cắt; ≥ 0,45 (uốn ≥ 90 px) tự cắt 3 chỗ ⇒ chọn 0,30.
@export_range(0.0, 1.0, 0.05) var sway_flat_ratio := 0.3
@export_range(0.0, 200.0, 1.0) var sway_edge_margin := 60.0
@export_range(0.0, 120.0, 1.0) var sway_min := 28.0
## Nửa bề rộng art nút màn (nút 112 px ở bản dọc) — dùng để KẸP zigzag cho nút
## không lòi ra ngoài khung bản đồ ở màn hẹp
@export_range(0.0, 200.0, 1.0) var node_half_width := 56.0
## Tâm MẶT nút lệch lên so với tâm art (nút có gờ đáy ~6px ở dưới ⇒ mặt nút nằm cao hơn ~3px).
## Đường nối đi qua tâm MẶT nút cho khớp mắt nhìn (nhân theo tỉ lệ nút ở màn ngang).
@export_range(-20.0, 20.0, 0.5) var node_face_center_y := -2.0

@export_group("Cờ đích / mũi chỉ")
## Mặt nút (khối giấy) cao 88 trên art 112 ⇒ mép trên mặt nút cách TÂM art 46 (ở scale 1)
@export_range(0.0, 120.0, 1.0) var node_face_top := 46.0
## Cờ đích `lv_flag` hiển thị ~59×77 (art 2x, scale 0.74 trong `level_map.tscn`): nửa cao 38,5;
## chồng nhẹ xuống mép nút; cột cờ nằm lệch TRÁI tâm art ~15px nên canh bù để cột trùng trục giữa nút
@export_range(0.0, 120.0, 1.0) var flag_half_height := 38.5
@export_range(0.0, 80.0, 1.0) var flag_overlap := 4.0
@export_range(0.0, 60.0, 1.0) var flag_pole_offset := 15.0
## Khoảng cách từ mép trên mặt nút tới TÂM bút chì chỉ `lv_pencil` (nửa cao ~41 + hở 6)
@export_range(0.0, 120.0, 1.0) var marker_face_gap := 48.0

@export_group("Cuộn / kéo")
## Lề trên/dưới khi tính giới hạn cuộn (px)
@export_range(0.0, 300.0, 1.0) var scroll_margin := 90.0
## Thời gian auto-scroll đến màn đang chơi (giây)
@export_range(0.05, 2.0, 0.05) var scroll_to_duration := 0.5
## Quán tính kéo: hệ số giảm tốc mỗi frame + tốc độ tối thiểu để còn trượt (px/frame)
@export_range(0.5, 0.999, 0.001) var drag_friction := 0.88
@export_range(0.0, 20.0, 0.1) var drag_min_speed := 1.5
## Bước cuộn mỗi nấc lăn chuột (px)
@export_range(10.0, 300.0, 1.0) var wheel_step := 70.0

## Node con — bind bằng `@export` trong `level_map.tscn`
@export var tracks: Node2D = null
@export var items: Node2D = null
@export var marker: Node2D = null
@export var goal: Node2D = null

## Dữ liệu từ levels.gd
var _level_ids: Array[int] = []
var _stars: Dictionary = {}       # level_id -> int(sao)
var _unlocked := 1                # level_id cao nhất đã unlock
var _current_id := 1              # màn tiếp theo cần chơi
var _bonus_ids: Array[int] = []   # các màn BONUS (cuối chương)

var _nodes: Dictionary = {}       # level_id -> LevelMapNode
var _min_scroll_y := 0.0
var _max_scroll_y := 0.0

# Kéo / cuộn
var _drag_active := false
var _drag_start_y := 0.0
var _tracks_start_y := 0.0
var _velocity_y := 0.0
var _scroll_tween: Tween = null

var _last_area_width := 0.0
var _last_unit := 1.0
var _last_area_height := 0.0
var _last_wide := false


func _ready() -> void:
	set_process(false)   # chỉ bật khi đang có quán tính kéo
	_last_area_width = _area_size().x
	_last_area_height = _area_size().y
	_last_unit = design_unit()
	_last_wide = is_wide()
	# Khung bản đồ đổi cỡ (layout) → dựng lại theo hướng mới; viewport là dự phòng cho
	# trường hợp map không nằm trong Control (test / dùng lẻ).
	var area := _map_area()
	if area != null:
		area.resized.connect(_on_viewport_size_changed)
	var viewport := get_viewport()
	if viewport != null:
		viewport.size_changed.connect(_on_viewport_size_changed)


func _on_viewport_size_changed() -> void:
	var width := _area_size().x
	var height := _area_size().y
	var unit := design_unit()
	var wide := is_wide()
	# Chỉ dựng lại khi bề rộng khung / độ phóng / hướng THẬT SỰ đổi (tránh gọi trùng lúc khởi động)
	if absf(width - _last_area_width) > 2.0 or absf(height - _last_area_height) > 2.0 or absf(unit - _last_unit) > 0.01 or wide != _last_wide:
		_last_area_width = width
		_last_area_height = height
		_last_unit = unit
		_last_wide = wide
		if not _level_ids.is_empty():
			_rebuild()


# ---------------------------------------------------------------------------
# Public API (gọi từ levels.gd / test)
# ---------------------------------------------------------------------------

## Dựng toàn bộ bản đồ từ dữ liệu chương hiện tại (`bonus_ids` = các màn BONUS trong `level_ids`)
func build(level_ids: Array[int], stars: Dictionary, unlocked: int, current_id: int,
		bonus_ids: Array[int] = []) -> void:
	_level_ids = level_ids
	_stars = stars
	_unlocked = unlocked
	_current_id = current_id
	_bonus_ids = bonus_ids
	_rebuild()


## Cuộn đến nút của `level_id` (đưa nút về giữa khung bản đồ)
func scroll_to(level_id: int, animate := true) -> void:
	var node := node_for(level_id)
	if node == null:
		return
	var target_y := clampf(_focus_y() - node.position.y, _min_scroll_y, _max_scroll_y)
	_stop_scroll_tween()
	if not animate:
		_set_scroll_y(target_y)
		return
	_scroll_tween = create_tween()
	_scroll_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_scroll_tween.tween_method(_set_scroll_y, scroll_offset_y(), target_y, scroll_to_duration)


## Nút của 1 màn (null nếu màn không thuộc chương đang xem)
func node_for(level_id: int) -> LevelMapNode:
	var node: LevelMapNode = _nodes.get(level_id, null)
	return node if node != null and is_instance_valid(node) else null


func node_count() -> int:
	return _nodes.size()


## Vị trí cuộn hiện tại của `Tracks` (px, dương = bản đồ trôi xuống)
func scroll_offset_y() -> float:
	return tracks.position.y if tracks != null else 0.0


## Độ cuộn so với GIỮA khoảng cuộn (px · dương = bản đồ trôi xuống).
## Nền parallax dùng giá trị này nhân với hệ số riêng của từng lớp ⇒ tốc độ nền luôn
## tỉ lệ CỐ ĐỊNH với tốc độ tay kéo (không bị "chậm dần/kịch trần" như cách chuẩn hoá theo
## độ dài chương trước đây).
func scroll_delta_y() -> float:
	if _max_scroll_y <= _min_scroll_y:
		return 0.0
	return scroll_offset_y() - (_max_scroll_y + _min_scroll_y) * 0.5


## Tiến độ cuộn chuẩn hoá [-1..1]: -1 = đáy (màn đầu), +1 = đỉnh (màn cuối), 0 = giữa
func scroll_progress() -> float:
	var half_span := (_max_scroll_y - _min_scroll_y) * 0.5
	if half_span <= 0.0:
		return 0.0
	return clampf(scroll_delta_y() / half_span, -1.0, 1.0)


# ---------------------------------------------------------------------------
# Dựng bản đồ
# ---------------------------------------------------------------------------
func _rebuild() -> void:
	_clear_items()
	if _level_ids.is_empty():
		_set_decor_visible(false)
		return

	var area := _area_size()
	var wide := is_wide()
	var spacing := spacing_landscape if wide else spacing_portrait
	var zigzag := _zigzag()
	var node_scale := _node_scale()
	var center_x := area.x * 0.5
	var cols := effective_columns()

	# Sắp xếp tăng dần: màn nhỏ nhất ở dưới cùng (y = 0), các màn sau leo dần lên (y âm)
	var sorted_ids := _level_ids.duplicate()
	sorted_ids.sort()
	var positions: Array[Vector2] = []
	if cols >= 2:
		positions = _snake_positions(sorted_ids.size(), center_x)
	else:
		for index in sorted_ids.size():
			var direction := 1.0 if index % 2 == 0 else -1.0
			positions.append(Vector2(center_x + direction * zigzag, -float(index) * spacing))

	if cols >= 2:
		_build_snake_paths(sorted_ids, positions, cols)
	else:
		_build_paths(sorted_ids, positions)
	_build_nodes(sorted_ids, positions, node_scale)

	# Giới hạn cuộn lấy theo VỊ TRÍ THẬT (đúng cho cả zigzag lẫn nhiều hàng kiểu rắn)
	var min_y := 0.0
	for point in positions:
		min_y = minf(min_y, point.y)
	var margin := scroll_margin * design_unit()
	_min_scroll_y = _focus_y() - margin
	_max_scroll_y = _focus_y() - min_y + margin
	_set_scroll_y(_focus_y() - _current_position_y(positions, sorted_ids))
	call_deferred("scroll_to", _current_id, true)


## Số cột THẬT SỰ dùng: bản dọc `columns`, bản ngang `columns_landscape` (< 2 ⇒ zigzag cũ)
func effective_columns() -> int:
	return maxi(columns_landscape if is_wide() else columns, 0)


## Độ phóng của khung thiết kế bản NGANG (960×540 ⇒ canvas, kiểu "contain"); bản dọc = 1
func design_unit() -> float:
	if not is_wide():
		return 1.0
	var canvas := get_viewport_rect().size
	if canvas.x <= 0.0 or canvas.y <= 0.0:
		return 1.0
	return maxf(minf(canvas.x / 960.0, canvas.y / 540.0), 0.1)


## Tỉ lệ của nút màn trên bản đồ (bản ngang = số đo thiết kế × `design_unit()`)
func _node_scale() -> float:
	return node_scale_landscape * design_unit() if is_wide() else node_scale_portrait


## Vị trí các nút kiểu RẮN: hàng 0 ở ĐÁY đi trái→phải, hàng 1 đi phải→trái…
## (màn 1-2-3 dưới, 4-5-6 giữa, 7-8-9 trên như mockup `level_final`).
func _snake_positions(count: int, center_x: float) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var cols := maxi(effective_columns(), 2)
	var half := float(cols - 1) * 0.5
	var unit := design_unit()
	var wide := is_wide()
	var col_spacing := column_spacing_landscape * unit if wide else column_spacing
	var row_gap := row_spacing_landscape * unit if wide else row_spacing
	var shift := (snake_center_shift_landscape * unit) if wide else snake_center_shift
	for index in count:
		var row := floori(float(index) / float(cols))
		var col := index % cols
		# Hàng lẻ chạy ngược để nét nối liền mạch (snake)
		var x_index := col if row % 2 == 0 else cols - 1 - col
		out.append(Vector2(
			center_x + shift + (float(x_index) - half) * col_spacing,
			-float(row) * row_gap))
	return out


## Đường nối kiểu RẮN: trong cùng hàng nối thẳng, giữa 2 hàng nối bằng cung vòng ra MÉP
## (điểm uốn nằm ngoài cột biên) nên nhìn như sợi dây quấn quanh mép bản đồ.
func _build_snake_paths(sorted_ids: Array[int], positions: Array[Vector2], cols: int) -> void:
	if items == null or sorted_ids.size() < 2:
		return
	var node_scale := _node_scale()
	var points := _snake_path_points(positions, cols, node_scale)
	var states: Array[int] = []
	for segment in range(points.size() - 1):
		var id_index := _snake_state_index(segment, cols, sorted_ids.size())
		states.append(int(_path_state_for(sorted_ids[id_index])))
	var road := path_scene.instantiate() as LevelMapPath
	items.add_child(road)
	var flat_points: Array[Vector2] = []
	for point in points:
		flat_points.append(Vector2(point.x, point.y + node_face_center_y * node_scale))
	road.edge_offset *= node_scale
	road.setup(flat_points, states, 0.0)


## Danh sách điểm cho đường nối kiểu rắn: mỗi nút 1 điểm, chèn thêm ĐIỂM UỐN ở mép khi
## chuyển hàng. Vector3(x, y, z) với `z = 1` đánh dấu điểm uốn (không phải nút màn).
func _snake_path_points(positions: Array[Vector2], cols: int, node_scale: float) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var edge_x := positions[0].x
	var min_x := positions[0].x
	for point in positions:
		edge_x = maxf(edge_x, point.x)
		min_x = minf(min_x, point.x)
	var bulge := (turn_bulge_landscape if is_wide() else turn_bulge) * node_scale
	for index in positions.size():
		if index > 0 and index % cols == 0:
			# Chuyển hàng: cung vòng ra mép (phải nếu hàng trước chạy xuôi, trái nếu chạy ngược)
			var prev := positions[index - 1]
			var next := positions[index]
			var row := floori(float(index) / float(cols))
			var outward := 1.0 if (row - 1) % 2 == 0 else -1.0
			var edge := edge_x if outward > 0.0 else min_x
			out.append(Vector3(edge + outward * bulge, (prev.y + next.y) * 0.5, 1.0))
		out.append(Vector3(positions[index].x, positions[index].y, 0.0))
	return out


## Chỉ số `sorted_ids` của nút ĐỨNG TRƯỚC đoạn nối thứ `segment` trong danh sách điểm
## (điểm uốn thuộc về nút đứng trước nó nên 2 đoạn liền nhau cùng một trạng thái).
func _snake_state_index(segment: int, cols: int, count: int) -> int:
	var elbows := 0
	if segment >= cols:
		elbows = floori(float(segment - cols) / float(cols + 1)) + 1
	return clampi(segment - elbows, 0, count - 1)


## Đường nối nằm DƯỚI các nút (thêm trước): MỘT đường uốn chữ S qua tâm TẤT CẢ các nút
func _build_paths(sorted_ids: Array[int], positions: Array[Vector2]) -> void:
	if items == null or sorted_ids.size() < 2:
		return
	var road := path_scene.instantiate() as LevelMapPath
	items.add_child(road)
	var node_scale := _node_scale()
	# Đường đi qua tâm MẶT nút (cao hơn tâm art vài px) + gờ đáy của đường theo tỉ lệ nút
	var face_points: Array[Vector2] = []
	for point in positions:
		face_points.append(point + Vector2(0.0, node_face_center_y * node_scale))
	road.edge_offset *= node_scale
	var states: Array[int] = []
	for index in range(sorted_ids.size() - 1):
		states.append(int(_path_state_for(sorted_ids[index])))
	road.setup(face_points, states, _road_sway())


## Độ lệch của điểm uốn giữa mỗi đoạn nối: theo nhịp dọc nhưng không vượt mép khung.
## Chọn tỉ lệ theo HƯỚNG của đoạn nối: bản dọc cần uốn ngang (chữ S), bản ngang đã uốn sẵn
## nhờ zigzag nên chỉ uốn rất nhẹ (xem `sway_flat_ratio`).
func _road_sway() -> float:
	var area := _area_size()
	var wide := is_wide()
	var spacing := spacing_landscape if wide else spacing_portrait
	var ratio := sway_flat_ratio if wide else sway_spacing_ratio
	if ratio <= 0.0:
		return 0.0
	var zigzag := _zigzag()
	var room := area.x * 0.5 - zigzag - sway_edge_margin
	return maxf(sway_min, minf(spacing * ratio, room))


## Các nút màn + canh cờ đích / mũi chỉ
func _build_nodes(sorted_ids: Array[int], positions: Array[Vector2], node_scale: float) -> void:
	if items == null:
		return
	for index in sorted_ids.size():
		var level_id := sorted_ids[index]
		var node := node_scene.instantiate() as LevelMapNode
		items.add_child(node)
		node.position = positions[index]
		node.scale = Vector2.ONE * node_scale
		node.setup(level_id, _node_state_for(level_id), int(_stars.get(level_id, 0)),
			_bonus_ids.has(level_id))
		# Nút sinh lúc chạy nên phải nối ở đây (scene không thể khai dây cho node động)
		node.pressed.connect(_on_node_pressed)
		_nodes[level_id] = node

	# Cờ đích cắm ở màn CHÍNH cuối cùng (BONUS nằm sau cờ)
	var last_index := sorted_ids.size() - 1
	while last_index > 0 and _bonus_ids.has(sorted_ids[last_index]):
		last_index -= 1
	var last_position := positions[last_index]
	var last_id: int = sorted_ids[last_index]
	if goal != null:
		goal.visible = true
		goal.scale = Vector2.ONE * node_scale
		# Cắm cờ vào MÉP TRÊN nút cuối (chồng nhẹ) — cờ nằm trong nút "End Level", không lơ lửng
		var lift := (node_face_top + flag_half_height - flag_overlap) * node_scale
		goal.position = last_position + Vector2(flag_pole_offset * node_scale, -lift)
	var current := node_for(_current_id)
	var show_marker := current != null and _current_id != last_id
	if marker != null:
		marker.visible = show_marker
		if show_marker:
			marker.scale = Vector2.ONE * node_scale
			marker.position = current.position + Vector2(0.0, -(node_face_top + marker_face_gap) * node_scale)


func _set_decor_visible(visible_now: bool) -> void:
	if marker != null:
		marker.visible = visible_now
	if goal != null:
		goal.visible = visible_now


func _current_position_y(positions: Array[Vector2], sorted_ids: Array[int]) -> float:
	var index := sorted_ids.find(_current_id)
	if index < 0:
		return 0.0
	return positions[index].y


func _clear_items() -> void:
	_nodes.clear()
	if items == null:
		return
	for child in items.get_children():
		items.remove_child(child)
		child.queue_free()


## Trạng thái của NÚT màn
func _node_state_for(level_id: int) -> LevelMapNode.State:
	if level_id > _unlocked:
		return LevelMapNode.State.LOCKED
	if int(_stars.get(level_id, 0)) > 0:
		return LevelMapNode.State.DONE
	if level_id == _current_id:
		return LevelMapNode.State.CURRENT
	if level_id < _current_id:
		return LevelMapNode.State.SKIPPED
	return LevelMapNode.State.NORMAL


## Trạng thái của ĐOẠN NỐI sau màn `level_id`
func _path_state_for(level_id: int) -> LevelMapPath.PathState:
	if level_id > _unlocked:
		return LevelMapPath.PathState.LOCKED
	if int(_stars.get(level_id, 0)) > 0:
		return LevelMapPath.PathState.COMPLETE
	if level_id < _current_id:
		return LevelMapPath.PathState.SKIPPED
	return LevelMapPath.PathState.UPCOMING


# ---------------------------------------------------------------------------
# Khung bản đồ (cha = `MapArea` trong scenes/levels.tscn)
# ---------------------------------------------------------------------------
func _map_area() -> Control:
	return get_parent() as Control


func _area_size() -> Vector2:
	var area := _map_area()
	return area.size if area != null else get_viewport_rect().size


func _focus_y() -> float:
	return _area_size().y * 0.5


## Có phải màn NGANG (canvas rộng hơn cao) — quyết định cỡ nút / khoảng cách.
## LẤY THEO CANVAS (không theo khung `MapArea`): khung này chỉ cao ~62% canvas và nằm trong
## CỘT NỘI DUNG canh giữa (xem `scripts/scenes/base.gd`), nên với màn DỌC rộng (3:4, cửa sổ
## lớn…) khung vẫn "rộng hơn cao" ⇒ trước đây bản đồ lỡ dùng thông số NGANG: zigzag 320 làm
## nút lòi ra ngoài khung + đổi cả trục uốn của đường nối ⇒ đường nối vẽ sai (đã gặp thật).
## Dùng canvas cho khớp cách `BaseUI` quyết định hướng layout.
func is_wide() -> bool:
	var canvas := get_viewport_rect().size
	if canvas.x > 0.0 and canvas.y > 0.0:
		return canvas.x > canvas.y
	var area := _area_size()
	return area.x > area.y


## Độ lệch zigzag đang dùng, KẸP để art nút không lòi ra ngoài khung bản đồ
func _zigzag() -> float:
	var area := _area_size()
	var wide := is_wide()
	var scale := _node_scale()
	var wanted := zigzag_landscape if wide else zigzag_portrait
	var room := maxf(0.0, area.x * 0.5 - node_half_width * scale - sway_edge_margin)
	return clampf(wanted, 0.0, room)


## Đặt vị trí cuộn (đã kẹp giới hạn) rồi phát độ dịch cho nền parallax
func _set_scroll_y(value: float) -> void:
	if tracks == null:
		return
	var clamped := clampf(value, _min_scroll_y, _max_scroll_y)
	if tracks.position.y != clamped:
		tracks.position.y = clamped
	scrolled.emit(scroll_delta_y())


# ---------------------------------------------------------------------------
# Kéo / cuộn (dọc, thân thiện cảm ứng)
# ---------------------------------------------------------------------------
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.index == 0:
		if event.pressed:
			if _inside_area(event.position):
				_begin_drag(event.position)
		else:
			_end_drag()
	elif event is InputEventScreenDrag and event.index == 0:
		_update_drag(event.position, event.relative)
	elif event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_LEFT:
			if button.pressed:
				if _inside_area(button.position):
					_begin_drag(button.position)
			else:
				_end_drag()
		elif button.pressed and button.button_index == MOUSE_BUTTON_WHEEL_UP and _inside_area(button.position):
			_set_scroll_y(scroll_offset_y() + wheel_step)
		elif button.pressed and button.button_index == MOUSE_BUTTON_WHEEL_DOWN and _inside_area(button.position):
			_set_scroll_y(scroll_offset_y() - wheel_step)
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		_update_drag(event.position, event.relative)


## Chỉ nhận kéo khi bắt đầu TRONG khung bản đồ (không giành input của header/nút)
func _inside_area(pos: Vector2) -> bool:
	var area := _map_area()
	return area == null or area.get_global_rect().has_point(pos)


func _begin_drag(pos: Vector2) -> void:
	_stop_scroll_tween()
	_drag_active = true
	_drag_start_y = pos.y
	_tracks_start_y = scroll_offset_y()
	_velocity_y = 0.0


func _update_drag(pos: Vector2, relative: Vector2) -> void:
	if not _drag_active:
		return
	_set_scroll_y(_tracks_start_y + (pos.y - _drag_start_y))
	_velocity_y = relative.y


func _end_drag() -> void:
	_drag_active = false
	set_process(absf(_velocity_y) >= drag_min_speed)


func _process(_delta: float) -> void:
	if _drag_active or absf(_velocity_y) < drag_min_speed:
		_velocity_y = 0.0
		set_process(false)
		return
	_set_scroll_y(scroll_offset_y() + _velocity_y)
	_velocity_y *= drag_friction


func _stop_scroll_tween() -> void:
	if _scroll_tween != null and _scroll_tween.is_valid():
		_scroll_tween.kill()
	_scroll_tween = null


# ---------------------------------------------------------------------------
# Events
# ---------------------------------------------------------------------------
func _on_node_pressed(level_id: int) -> void:
	level_selected.emit(level_id)
