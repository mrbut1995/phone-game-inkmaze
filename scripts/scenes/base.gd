class_name BaseScene
extends Control
## ============================================================================
## Scene gốc dùng chung cho MỌI màn hình (instance của `scenes/base.tscn`).
##
## HỖ TRỢ MỌI TỈ LỆ MÀN HÌNH — portrait & landscape (4:3 · 16:9 · 9:16 · 18:9 · 9:18 · 9:21…):
##
## Toàn bộ UI được thiết kế trên khung 1080×1920. Khi màn hình rộng hơn tỉ lệ 9:16,
## root Control tự co thành **CỘT NỘI DUNG 1080px CANH GIỮA** thay vì để nội dung
## dính mép trái:
##   · Bề rộng = đúng 1080 (bằng bản thiết kế) → mọi mốc canh phải/trái giữ nguyên.
##   · Chiều cao = chiều cao canvas → màn cao (9:18 · 9:19.5 · 9:21) giãn dọc như trước.
##   · Canh giữa ngang → màn 4:3 / 16:9 / 18:9 (kể cả landscape) nội dung nằm giữa,
##     hai bên là nền giấy — 2 dải `SideL`/`SideR` (con của `Background`) tô tiếp
##     màu giấy ra hết mép màn hình nên nhìn như trang vở trải rộng.
##
## Nhờ vậy giao diện KHÔNG bị kéo giãn ngang, không lệch vị trí ở mọi tỉ lệ, và các
## màn con không cần sửa layout riêng.
##
## LƯU Ý KỸ THUẬT: mọi màn con override `_ready()` (không gọi super) nên logic ở đây
## KHÔNG đặt trong `_ready` được — dùng `_enter_tree()` + `_notification()` thay thế.
## ============================================================================

## Bề rộng thiết kế của cột nội dung (khớp `display/window/size/viewport_width`)
const DESIGN_WIDTH := 1080.0

var _responsive_ready := false


func _enter_tree() -> void:
	_responsive_ready = true
	# Bỏ anchors full-rect của node gốc — từ đây Root tự quản size/position (nếu giữ anchors
	# 0..1 thì Godot ghi đè `size` sau `_ready` và cảnh báo "non-equal opposite anchors").
	set_anchors_preset(Control.PRESET_TOP_LEFT, true)
	_connect_viewport()
	_apply_responsive_layout()


func _notification(what: int) -> void:
	# READY: áp lại lần cuối sau khi cả cây scene đã vào (tránh race lúc khởi động).
	# RESIZED: cửa sổ đổi cỡ (kéo cửa sổ trên Windows / xoay máy trên điện thoại).
	if what == NOTIFICATION_READY or what == NOTIFICATION_RESIZED:
		_apply_responsive_layout()


## Canvas đổi cỡ -> cập nhật lại cột nội dung (xoay máy, kéo giãn cửa sổ)
func _connect_viewport() -> void:
	var vp := get_viewport()
	if vp != null and not vp.size_changed.is_connected(_apply_responsive_layout):
		vp.size_changed.connect(_apply_responsive_layout)


## Cột nội dung 1080×canvas (canh giữa ngang) + nền giấy phủ toàn canvas
func _apply_responsive_layout() -> void:
	if not _responsive_ready or not is_inside_tree():
		return
	var canvas := get_viewport_rect().size
	if canvas.x <= 0.0 or canvas.y <= 0.0:
		return
	var target_pos := Vector2(floorf((canvas.x - DESIGN_WIDTH) * 0.5), 0.0)
	var target_size := Vector2(DESIGN_WIDTH, canvas.y)
	if position != target_pos:
		position = target_pos
	if size != target_size:
		size = target_size
	_apply_background_sides(canvas)


## Hai bên cột (màn rộng hơn 9:16) tô tiếp màu giấy bằng 2 ColorRect con của
## Background — nằm NGOÀI vùng art nên không che lề đỏ; canvas hẹp thì rộng 0.
func _apply_background_sides(canvas: Vector2) -> void:
	var bg := get_node_or_null("Background") as Control
	if bg == null:
		return
	var left := bg.get_node_or_null("SideL") as Control
	if left != null:
		left.position = Vector2(-position.x, 0.0)
		left.size = Vector2(position.x, canvas.y)
	var right := bg.get_node_or_null("SideR") as Control
	if right != null:
		right.position = Vector2(DESIGN_WIDTH, 0.0)
		right.size = Vector2(maxf(canvas.x - position.x - DESIGN_WIDTH, 0.0), canvas.y)
