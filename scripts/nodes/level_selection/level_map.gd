class_name LevelMap
extends Node2D
## ============================================================================
## LevelMap — Bản đồ road map dọc của màn Chọn màn
##
## Bố cục: các nút màn xếp DỌC từ dưới lên (màn 1 ở dưới cùng), lệch zigzag quanh trục
## giữa, nối nhau bằng MỘT đường `LevelMapPath` uốn liền mạch qua tâm các nút. Cuộn bản
## đồ bằng cách dịch node `Tracks` (KHÔNG dùng Camera2D để UI — header, banner — đứng yên).
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

const NODE_SCENE := preload("res://nodes/level_selection/level_node.tscn")
const PATH_SCENE := preload("res://nodes/level_selection/level_path.tscn")

## Khoảng cách tâm 2 nút theo trục Y (px) và độ lệch zigzag quanh tâm
const SPACING_PORTRAIT := 158.0
const SPACING_LANDSCAPE := 200.0
const ZIGZAG_PORTRAIT := 74.0
const ZIGZAG_LANDSCAPE := 320.0
## Nút cùng art to hơn ở màn ngang cho cân bề ngang rộng
const NODE_SCALE_LANDSCAPE := 1.28
## Nút màn hiển thị 112px (art 2× vẽ ở scale 0.5): nửa nút = 56, LÒNG nút (mặt giấy) = 96
## ⇒ mép trên mặt nút cách tâm 48 — dùng để cắm cờ đích / đặt mũi chỉ cho khớp nút.
const NODE_FACE_TOP := 48.0
## Art cờ đích 64×88 (tâm giữa ⇒ đáy cột cờ cách tâm 44) + độ chồng lên mép nút
const FLAG_HALF_HEIGHT := 44.0
const FLAG_OVERLAP := 20.0
## Cột cờ nằm lệch trái tâm art 18px (art 64 rộng, cột ở x≈14) ⇒ canh bù để CỘT CỜ
## trùng trục giữa nút cuối (nhìn như cắm giữa nút, không lệch ra ngoài)
const FLAG_POLE_OFFSET := 18.0
## Lề trên/dưới khi tính giới hạn cuộn
const SCROLL_MARGIN := 90.0
## Thời gian auto-scroll đến màn đang chơi
const SCROLL_TO_DURATION := 0.5
## Kéo / quán tính
const DRAG_FRICTION := 0.88
const DRAG_MIN_SPEED := 1.5
const WHEEL_STEP := 70.0

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


func _ready() -> void:
	set_process(false)   # chỉ bật khi đang có quán tính kéo
	_last_area_width = _area_size().x
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
	# Chỉ dựng lại khi bề rộng khung THẬT SỰ đổi (tránh gọi trùng lúc khởi động)
	if absf(width - _last_area_width) > 2.0:
		_last_area_width = width
		if not _level_ids.is_empty():
			_rebuild()


# ---------------------------------------------------------------------------
# Public API (gọi từ levels.gd / test)
# ---------------------------------------------------------------------------

## Dựng toàn bộ bản đồ từ dữ liệu chương hiện tại
func build(level_ids: Array[int], stars: Dictionary, unlocked: int, current_id: int) -> void:
	_level_ids = level_ids
	_stars = stars
	_unlocked = unlocked
	_current_id = current_id
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
	_scroll_tween.tween_method(_set_scroll_y, scroll_offset_y(), target_y, SCROLL_TO_DURATION)


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
	var wide := area.x > area.y
	var spacing := SPACING_LANDSCAPE if wide else SPACING_PORTRAIT
	var zigzag := ZIGZAG_LANDSCAPE if wide else ZIGZAG_PORTRAIT
	var node_scale := NODE_SCALE_LANDSCAPE if wide else 1.0
	var center_x := area.x * 0.5

	# Sắp xếp tăng dần: màn nhỏ nhất ở dưới cùng (y = 0), các màn sau leo dần lên (y âm)
	var sorted_ids := _level_ids.duplicate()
	sorted_ids.sort()
	var positions: Array[Vector2] = []
	for index in sorted_ids.size():
		var direction := 1.0 if index % 2 == 0 else -1.0
		positions.append(Vector2(center_x + direction * zigzag, -float(index) * spacing))

	_build_paths(sorted_ids, positions)
	_build_nodes(sorted_ids, positions, node_scale)

	var count := sorted_ids.size()
	_min_scroll_y = _focus_y() - SCROLL_MARGIN
	_max_scroll_y = _focus_y() + float(count - 1) * spacing + SCROLL_MARGIN
	_set_scroll_y(_focus_y() - _current_position_y(positions, sorted_ids))
	call_deferred("scroll_to", _current_id, true)


## Đường nối nằm DƯỚI các nút (thêm trước): MỘT đường liền mạch qua tâm TẤT CẢ các nút
func _build_paths(sorted_ids: Array[int], positions: Array[Vector2]) -> void:
	if items == null or sorted_ids.size() < 2:
		return
	var road := PATH_SCENE.instantiate() as LevelMapPath
	items.add_child(road)
	var states: Array[int] = []
	for index in range(sorted_ids.size() - 1):
		states.append(int(_path_state_for(sorted_ids[index])))
	road.setup(positions, states)


## Các nút màn + canh cờ đích / mũi chỉ
func _build_nodes(sorted_ids: Array[int], positions: Array[Vector2], node_scale: float) -> void:
	if items == null:
		return
	for index in sorted_ids.size():
		var level_id := sorted_ids[index]
		var node := NODE_SCENE.instantiate() as LevelMapNode
		items.add_child(node)
		node.position = positions[index]
		node.scale = Vector2.ONE * node_scale
		node.setup(level_id, _node_state_for(level_id), int(_stars.get(level_id, 0)))
		# Nút sinh lúc chạy nên phải nối ở đây (scene không thể khai dây cho node động)
		node.pressed.connect(_on_node_pressed)
		_nodes[level_id] = node

	var last_position := positions[positions.size() - 1]
	var last_id: int = sorted_ids[sorted_ids.size() - 1]
	if goal != null:
		goal.visible = true
		goal.scale = Vector2.ONE * node_scale
		# Cắm cờ vào MÉP TRÊN nút cuối (chồng nhẹ) — cờ nằm trong nút "End Level", không lơ lửng
		var lift := (NODE_FACE_TOP + FLAG_HALF_HEIGHT - FLAG_OVERLAP) * node_scale
		goal.position = last_position + Vector2(FLAG_POLE_OFFSET * node_scale, -lift)
	var current := node_for(_current_id)
	var show_marker := current != null and _current_id != last_id
	if marker != null:
		marker.visible = show_marker
		if show_marker:
			marker.scale = Vector2.ONE * node_scale
			marker.position = current.position + Vector2(0.0, -(NODE_FACE_TOP + 20.0) * node_scale)


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


## Có phải màn NGANG (khung rộng hơn cao) — quyết định cỡ nút / khoảng cách
func is_wide() -> bool:
	var area := _area_size()
	return area.x > area.y


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
			_set_scroll_y(scroll_offset_y() + WHEEL_STEP)
		elif button.pressed and button.button_index == MOUSE_BUTTON_WHEEL_DOWN and _inside_area(button.position):
			_set_scroll_y(scroll_offset_y() - WHEEL_STEP)
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
	set_process(absf(_velocity_y) >= DRAG_MIN_SPEED)


func _process(_delta: float) -> void:
	if _drag_active or absf(_velocity_y) < DRAG_MIN_SPEED:
		_velocity_y = 0.0
		set_process(false)
		return
	_set_scroll_y(scroll_offset_y() + _velocity_y)
	_velocity_y *= DRAG_FRICTION


func _stop_scroll_tween() -> void:
	if _scroll_tween != null and _scroll_tween.is_valid():
		_scroll_tween.kill()
	_scroll_tween = null


# ---------------------------------------------------------------------------
# Events
# ---------------------------------------------------------------------------
func _on_node_pressed(level_id: int) -> void:
	level_selected.emit(level_id)
