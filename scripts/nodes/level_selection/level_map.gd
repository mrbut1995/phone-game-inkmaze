class_name LevelMap
extends Node2D
## ============================================================================
## LevelMap — Bản đồ road map theo chiều dọc (Vertical Road Map)
##
## Layout:
##   - Các node xếp dọc từ DƯỚI (Màn 1) lên TRÊN (Màn N).
##   - Các node nằm lệch zigzag nhẹ quanh trục giữa màn hình.
##   - Các node được nối với nhau bằng LevelMapPath (Line2D).
##   - Cuộn bản đồ bằng cách di chuyển node con `Tracks` (Node2D).
##     KHÔNG DÙNG Camera2D để tránh làm trôi UI (Header, Banner, ContinueButton).
##   - Node "current" được tự động cuộn đến giữa màn hình khi khởi tạo.
##
## Trạng thái từng node:
##   DONE    → đã hoàn thành (stars > 0)
##   SKIPPED → đã unlock node sau nhưng node này chưa đạt sao
##   CURRENT → màn tiếp theo cần chơi (chapter_continue_level)
##   NORMAL  → đã unlock, chưa phải current
##   LOCKED  → level_id > unlocked_level
## ============================================================================

signal level_selected(level_id: int)

const NODE_SCENE := preload("res://nodes/level_selection/level_node.tscn")
const PATH_SCENE := preload("res://nodes/level_selection/level_path.tscn")

## Khoảng cách giữa tâm 2 node theo trục Y (px)
const NODE_SPACING     := 140.0
## Lệch zigzag trái/phải quanh tâm màn hình
const ZIGZAG_AMPLITUDE := 60.0
## Kích thước hiển thị mục tiêu của node
const NODE_SIZE        := 76.0
## Tốc độ kéo / quán tính
const DRAG_FRICTION    := 0.88
const DRAG_MIN_SPEED   := 1.5
## Vị trí trục Y trên màn hình muốn node active được căn vào (giữa Header và ContinueButton)
const FOCUS_Y          := 470.0
## Thời gian auto-scroll đến current node
const SCROLL_TO_DURATION := 0.5

## Dữ liệu từ levels.gd
var _level_ids: Array[int] = []
var _stars: Dictionary     = {}   # level_id -> int(sao)
var _unlocked: int         = 1    # level_id cao nhất đã unlock
var _current_id: int       = 1    # màn tiếp theo cần chơi

var _nodes: Dictionary     = {}   # level_id -> LevelMapNode
var _min_scroll_y: float   = 0.0
var _max_scroll_y: float   = 0.0

# Touch/drag state
var _drag_active    := false
var _drag_start_y   := 0.0
var _tracks_start_y := 0.0
var _velocity_y     := 0.0
var _scroll_tween: Tween = null

var _last_vp_width: float = 0.0

@onready var _tracks: Node2D = $Tracks


func _ready() -> void:
	var vp := get_viewport()
	if vp != null:
		_last_vp_width = vp.get_visible_rect().size.x
		vp.size_changed.connect(_on_viewport_size_changed)


func _on_viewport_size_changed() -> void:
	var vp := get_viewport()
	if vp == null:
		return
	var new_w := vp.get_visible_rect().size.x
	# Chỉ rebuild khi chiều rộng thực sự thay đổi (tránh gọi trùng lặp lúc khởi động)
	if absf(new_w - _last_vp_width) > 2.0:
		_last_vp_width = new_w
		if not _level_ids.is_empty():
			_rebuild()


# ---------------------------------------------------------------------------
# Public API (gọi từ levels.gd)
# ---------------------------------------------------------------------------

## Dựng toàn bộ map từ dữ liệu được truyền vào
func build(level_ids: Array[int], stars: Dictionary, unlocked: int, current_id: int) -> void:
	_level_ids = level_ids
	_stars     = stars
	_unlocked  = unlocked
	_current_id = current_id
	_rebuild()


## Scroll đến node của level_id
func scroll_to(level_id: int, animate := true) -> void:
	var node: LevelMapNode = _nodes.get(level_id, null)
	if node == null or not is_instance_valid(node):
		return
	var target_y := clampf(FOCUS_Y - node.position.y, _min_scroll_y, _max_scroll_y)
	_stop_scroll_tween()
	if not animate:
		_tracks.position.y = target_y
		return
	_scroll_tween = create_tween()
	_scroll_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_scroll_tween.tween_property(_tracks, "position:y", target_y, SCROLL_TO_DURATION)


# ---------------------------------------------------------------------------
# Build nội dung
# ---------------------------------------------------------------------------
func _rebuild() -> void:
	if _tracks == null:
		return

	# Gỡ ngay lập tức các node cũ khỏi cây scene để tránh nháy đè frame
	for child in _tracks.get_children():
		_tracks.remove_child(child)
		child.queue_free()
	_nodes.clear()

	if _level_ids.is_empty():
		return

	var vp_size := get_viewport_rect().size
	var center_x := vp_size.x * 0.5 if vp_size.x > 0.0 else 270.0

	# Sắp xếp tăng dần: index 0 = màn nhỏ nhất (ở dưới cùng, Y = 0)
	var sorted_ids := _level_ids.duplicate()
	sorted_ids.sort()

	var n := sorted_ids.size()

	# Tính toạ độ cho từng node trước để tiện vẽ path
	var positions: Array[Vector2] = []
	for idx in n:
		var dir := 1.0 if (idx % 2 == 0) else -1.0
		var nx  := center_x + dir * ZIGZAG_AMPLITUDE
		# Node nhỏ nhất ở Y = 0; các node tiếp theo leo dần lên trên (Y âm)
		var ny  := -float(idx) * NODE_SPACING
		positions.append(Vector2(nx, ny))

	# 1. Vẽ các đoạn nối (LevelMapPath) nằm DƯỚI các node
	for idx in range(n - 1):
		var lid: int      = sorted_ids[idx]
		var next_lid: int = sorted_ids[idx + 1]
		var path_state    := _path_state_for(lid, next_lid)
		var path_node     := PATH_SCENE.instantiate() as LevelMapPath
		_tracks.add_child(path_node)
		path_node.position = Vector2.ZERO
		path_node.setup(positions[idx], positions[idx + 1], path_state)

	# 2. Vẽ các LevelMapNode
	for idx in n:
		var lid: int = sorted_ids[idx]
		var map_node := NODE_SCENE.instantiate() as LevelMapNode
		_tracks.add_child(map_node)
		map_node.position = positions[idx]
		map_node.setup(lid, _node_state_for(lid), int(_stars.get(lid, 0)))
		map_node.pressed.connect(_on_node_pressed)
		_nodes[lid] = map_node

		# Hiệu ứng mờ xuất hiện nhẹ
		map_node.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_interval(idx * 0.04)
		tw.tween_property(map_node, "modulate:a", 1.0, 0.16)

	# Giới hạn cuộn:
	# Node nhỏ nhất (idx=0, y=0): FOCUS_Y - 0 = FOCUS_Y (kéo xuống xem màn 1)
	# Node lớn nhất (idx=n-1, y=-(n-1)*SPACING): FOCUS_Y + (n-1)*SPACING (kéo lên xem màn N)
	_min_scroll_y = FOCUS_Y - 80.0
	_max_scroll_y = FOCUS_Y + float(n - 1) * NODE_SPACING + 80.0

	# Đặt vị trí ban đầu và cuộn mượt đến current node
	var init_node: LevelMapNode = _nodes.get(_current_id, null)
	var init_y := init_node.position.y if init_node != null else 0.0
	_tracks.position.y = clampf(FOCUS_Y - init_y, _min_scroll_y, _max_scroll_y)

	call_deferred("scroll_to", _current_id, true)


## Xác định trạng thái của NODE
func _node_state_for(lid: int) -> LevelMapNode.State:
	var stars := int(_stars.get(lid, 0))
	if lid > _unlocked:
		return LevelMapNode.State.LOCKED
	if stars > 0:
		return LevelMapNode.State.DONE
	if lid == _current_id:
		return LevelMapNode.State.CURRENT
	if lid < _current_id:
		return LevelMapNode.State.SKIPPED
	return LevelMapNode.State.NORMAL


## Xác định trạng thái của PATH giữa 2 màn
func _path_state_for(current_lid: int, _next_lid: int) -> LevelMapPath.PathState:
	var stars_curr := int(_stars.get(current_lid, 0))
	if current_lid > _unlocked:
		return LevelMapPath.PathState.LOCKED
	if stars_curr > 0:
		return LevelMapPath.PathState.COMPLETE
	if current_lid < _current_id:
		return LevelMapPath.PathState.SKIPPED
	return LevelMapPath.PathState.UPCOMING


# ---------------------------------------------------------------------------
# Drag / scroll (vertical, mobile-friendly)
# ---------------------------------------------------------------------------
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.index == 0:
		if event.pressed:
			_begin_drag(event.position)
		else:
			_end_drag()
	elif event is InputEventScreenDrag and event.index == 0:
		_update_drag(event.position, event.relative)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_begin_drag(mb.position)
			else:
				_end_drag()
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_tracks.position.y = clampf(_tracks.position.y + 70.0, _min_scroll_y, _max_scroll_y)
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_tracks.position.y = clampf(_tracks.position.y - 70.0, _min_scroll_y, _max_scroll_y)
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		_update_drag(event.position, event.relative)


func _begin_drag(pos: Vector2) -> void:
	_stop_scroll_tween()
	_drag_active    = true
	_drag_start_y   = pos.y
	_tracks_start_y = _tracks.position.y
	_velocity_y     = 0.0


func _update_drag(pos: Vector2, relative: Vector2) -> void:
	if not _drag_active:
		return
	var delta_y := pos.y - _drag_start_y
	_tracks.position.y = clampf(_tracks_start_y + delta_y, _min_scroll_y, _max_scroll_y)
	_velocity_y = relative.y


func _end_drag() -> void:
	_drag_active = false


func _process(_delta: float) -> void:
	if _drag_active:
		return
	if absf(_velocity_y) < DRAG_MIN_SPEED:
		_velocity_y = 0.0
		return
	_tracks.position.y = clampf(_tracks.position.y + _velocity_y, _min_scroll_y, _max_scroll_y)
	_velocity_y *= DRAG_FRICTION


func _stop_scroll_tween() -> void:
	if _scroll_tween != null and _scroll_tween.is_valid():
		_scroll_tween.kill()
	_scroll_tween = null


# ---------------------------------------------------------------------------
# Events
# ---------------------------------------------------------------------------
func _on_node_pressed(lid: int) -> void:
	level_selected.emit(lid)
