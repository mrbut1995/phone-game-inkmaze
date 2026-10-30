class_name ProfilerScroll
extends ScrollContainer
## ============================================================================
## Vùng CUỘN danh sách thông tin của popup Hồ sơ (`InfoScroll`).
##
## Trên ĐIỆN THOẠI, ScrollContainer đã tự xử lý kéo bằng ngón tay (chuột ảo) —
## không cần gì thêm. Trên DESKTOP (không có màn hình cảm ứng) ScrollContainer
## bỏ qua chuột nên script này thêm KÉO-THẢ bằng chuột trái cho tiện test:
##   · dọc : kéo lên/xuống  (portrait — `vertical_scroll_mode` BẬT)
##   · ngang: kéo trái/phải (landscape — `horizontal_scroll_mode` BẬT)
## ============================================================================

var _dragging := false


func _gui_input(event: InputEvent) -> void:
	# Máy có cảm ứng (điện thoại / touch laptop) → để ScrollContainer gốc xử lý
	if DisplayServer.is_touchscreen_available():
		return
	var mb := event as InputEventMouseButton
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT:
		_dragging = mb.pressed
		if mb.pressed:
			accept_event()
		return
	var mm := event as InputEventMouseMotion
	if mm == null or not _dragging:
		return
	if horizontal_scroll_mode != ScrollMode.SCROLL_MODE_DISABLED:
		scroll_horizontal -= int(mm.relative.x)
	if vertical_scroll_mode != ScrollMode.SCROLL_MODE_DISABLED:
		scroll_vertical -= int(mm.relative.y)
	accept_event()
