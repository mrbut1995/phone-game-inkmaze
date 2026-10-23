class_name FitStage
extends Control
## ============================================================================
## Khung thiết kế cố định (mặc định 960×540) — tự PHÓNG/THU để vừa gọn vào node cha và
## canh giữa (kiểu "contain"). Dùng cho bố cục NGANG: toạ độ trong scene luôn là toạ độ
## thiết kế 960×540 dù canvas thật là 1635×920, 844×390…
##
## `LevelMap` dùng cùng công thức: design_unit = min(canvas.x / 960, canvas.y / 540).
## ============================================================================

## Phát mỗi khi khung đổi tỉ lệ/vị trí (node nào cần bám theo khung nghe signal này)
signal fitted

@export var design_size := Vector2(960, 540)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var host := get_parent() as Control
	if host != null and not host.resized.is_connected(_fit):
		host.resized.connect(_fit)
	_fit()
	_fit.call_deferred()


func _fit() -> void:
	var host := get_parent() as Control
	if host == null:
		return
	var avail := host.size
	if avail.x <= 0.0 or avail.y <= 0.0 or design_size.x <= 0.0 or design_size.y <= 0.0:
		return
	var unit := minf(avail.x / design_size.x, avail.y / design_size.y)
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	size = design_size
	pivot_offset = Vector2.ZERO
	scale = Vector2(unit, unit)
	position = (avail - design_size * unit) * 0.5
	fitted.emit()
