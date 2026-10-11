class_name EventDots
extends Control
## ============================================================================
## Node: EventDots — chấm phân trang cho EventCarousel.
##
## KHÔNG tạo node lúc chạy (§13.15 GDD): 8 chấm khai SẴN trong scene, script chỉ
## bật/tắt + đổi màu. CỠ chấm lấy từ scene (không hard-code px trong script):
##   · `Dot1`..`Dot8`  = cỡ chấm THƯỜNG (custom_minimum_size trong scene)
##   · `ActiveTemplate` = node MẪU (ẩn) giữ cỡ chấm ĐANG CHỌN + StyleBoxFlat bo góc
## ============================================================================

@export var active_color: Color = Color("#256C96")
@export var inactive_color: Color = Color("#D8E2E8")

@onready var dots: HBoxContainer = $Dots
@onready var active_template: Panel = $ActiveTemplate

var _inactive_size := Vector2.ZERO
var _active_size := Vector2.ZERO


func _ready() -> void:
	if active_template != null:
		_active_size = active_template.custom_minimum_size
	if dots != null and dots.get_child_count() > 0:
		var first := dots.get_child(0) as Panel
		if first != null:
			_inactive_size = first.custom_minimum_size


## Cập nhật số trang hiển thị và trang đang chọn
func set_pages(count: int, current: int) -> void:
	if dots == null:
		return
	# 0 hoặc 1 thẻ → ẩn dấu chấm (trạng thái rỗng chỉ có Daily — §B5)
	visible = count > 1
	var base_sb: StyleBox = null
	if active_template != null:
		base_sb = active_template.get_theme_stylebox("panel")
	var children := dots.get_children()
	for i in children.size():
		var dot := children[i] as Panel
		if dot == null:
			continue
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
			var sb := (base_sb as StyleBoxFlat).duplicate() as StyleBoxFlat
			sb.bg_color = active_color if is_active else inactive_color
			dot.add_theme_stylebox_override("panel", sb)
