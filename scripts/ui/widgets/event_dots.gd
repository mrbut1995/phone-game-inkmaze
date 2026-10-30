class_name EventDots
extends Control
## ============================================================================
## Node: EventDots — chấm phân trang cho EventCarousel.
##
## Các chấm được tạo từ scene EventDot theo số trang. Kích thước lấy từ scene,
## còn ActiveTemplate giữ cỡ và StyleBox của chấm đang chọn.
## ============================================================================

@export var active_color: Color = Color("#256C96")
@export var inactive_color: Color = Color("#D8E2E8")
@export var dot_scene: PackedScene

@onready var dots: HBoxContainer = $Dots
@onready var active_template: Panel = $ActiveTemplate

var _dot_nodes: Array[Panel] = []
var _inactive_size := Vector2.ZERO
var _active_size := Vector2.ZERO


func _ready() -> void:
	if dot_scene == null:
		push_error("[EventDots] Chưa gán scene EventDot.")
	if active_template != null:
		_active_size = active_template.custom_minimum_size


## Cập nhật số trang hiển thị và trang đang chọn
func set_pages(count: int, current: int) -> void:
	if dots == null:
		return
	while _dot_nodes.size() < count:
		if dot_scene == null:
			push_error("[EventDots] Không thể hiển thị đủ chấm vì thiếu scene EventDot.")
			return
		var dot := dot_scene.instantiate() as Panel
		if dot == null:
			push_error("[EventDots] Scene EventDot không có Panel làm root.")
			return
		if _inactive_size == Vector2.ZERO:
			_inactive_size = dot.custom_minimum_size
		dots.add_child(dot)
		_dot_nodes.append(dot)

	# 0 hoặc 1 thẻ → ẩn dấu chấm.
	visible = count > 1
	var base_sb: StyleBox = null
	if active_template != null:
		base_sb = active_template.get_theme_stylebox("panel")
	for i in _dot_nodes.size():
		var dot := _dot_nodes[i]
		if i >= count:
			dot.visible = false
			continue
		dot.visible = true
		var is_active := i == current
		if is_active and _active_size != Vector2.ZERO:
			dot.custom_minimum_size = _active_size
		elif _inactive_size != Vector2.ZERO:
			dot.custom_minimum_size = _inactive_size
		if base_sb is StyleBoxFlat:
			var sb := (base_sb as StyleBoxFlat).duplicate() as StyleBoxFlat  # keep-code: StyleBox nhân bản để tô màu theo dữ liệu (runtime)
			sb.bg_color = active_color if is_active else inactive_color
			dot.add_theme_stylebox_override("panel", sb)
