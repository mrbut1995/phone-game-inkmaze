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
## `false` (mặc định) = "contain": khung giữ đúng 960×540 và canh GIỮA (màn dài/rộng hơn sẽ thừa lề hai bên).
## `true` = "fill": độ phóng vẫn như contain nhưng khung được KÉO DÀI theo trục thừa
## (màn 20:9 ⇒ khung rộng ~1200 đơn vị) để nội dung neo trái/phải/dưới chạm sát mép màn hình.
## Con của khung dùng neo (anchor) để bám theo mép; vẫn coi 960×540 là cỡ tối thiểu.
@export var fill := false


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
	pivot_offset = Vector2.ZERO
	scale = Vector2(unit, unit)
	if fill:
		size = Vector2(maxf(design_size.x, avail.x / unit), maxf(design_size.y, avail.y / unit))
		position = Vector2.ZERO
	else:
		size = design_size
		position = (avail - design_size * unit) * 0.5
	fitted.emit()
