class_name BaseScene
extends Control
## ============================================================================
## Scene gốc dùng chung cho MỌI màn hình (instance của `scenes/base.tscn`).
##
## BẢN PORTRAIT-ONLY — mọi tỉ lệ màn hình DỌC (9:16 · 9:18 · 9:19.5 · 9:21 · tablet 3:4…):
##
## Toàn bộ UI được thiết kế trên khung 540×920. Khi màn hình rộng hơn tỉ lệ 9:16
## (tablet 3:4…), root Control tự co thành **CỘT NỘI DUNG CANH GIỮA** thay vì để
## nội dung dính mép trái:
##   · Bề rộng = clamp(bề ngang canvas, 540, 1440) → mọi mốc canh phải/trái giữ nguyên.
##   · Chiều cao = chiều cao canvas → màn cao (9:18 · 9:19.5 · 9:21) giãn dọc như trước.
##   · Canh giữa ngang → hai bên là nền giấy — 2 dải `SideL`/`SideR` (con của
##     `Background`) tô tiếp màu giấy ra hết mép màn hình nên nhìn như trang vở trải rộng.
##
## Nhờ vậy giao diện KHÔNG bị kéo giãn ngang, không lệch vị trí ở mọi tỉ lệ, và các
## màn con không cần sửa layout riêng.
##
## LƯU Ý KỸ THUẬT: mọi màn con override `_ready()` (không gọi super) nên logic ở đây
## KHÔNG đặt trong `_ready` được — dùng `_enter_tree()` + `_notification()` thay thế.
## ============================================================================

## Bề rộng thiết kế của cột nội dung (khớp `display/window/size/viewport_width`)
const DESIGN_WIDTH := 540
## Bề rộng TỐI ĐA của cột nội dung ở màn DỌC: máy tính bảng 3:4 (canvas 1440×1920) nở ra
## dùng trọn bề ngang màn hình; màn nào hẹp hơn thì cột đúng bằng bề ngang canvas.
const MAX_CONTENT_WIDTH := 1440.0

## (PORTRAIT-ONLY) Giữ để tương thích API: phát ĐÚNG 1 LẦN lúc khởi động (`false`) để
## các handler `_on_orientation_changed` của màn con chạy bước dàn UI theo layout.
signal orientation_changed(is_landscape: bool)

## (PORTRAIT-ONLY) Luôn `false` — không còn chế độ ngang.
var is_landscape := false

var _responsive_ready := false
var _orientation_ready := false


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


## ============================================================================
## BỐ CỤC MÀN HÌNH (bản PORTRAIT-ONLY)
##
## Mỗi màn khai 1 layout con tên `Portrait` (kế thừa `scenes/layout/portrait/base_layout.tscn`).
## Khung nội dung (root Control): cột canh giữa — rộng `clamp(canvas.x, 540, 1440)` × cao canvas.
## ============================================================================
## Cột nội dung (canh giữa ngang) + nền giấy phủ toàn canvas
func _apply_responsive_layout() -> void:
	if not _responsive_ready or not is_inside_tree():
		return
	var canvas := get_viewport_rect().size
	if canvas.x <= 0.0 or canvas.y <= 0.0:
		return

	var portrait_layout := get_node_or_null("Portrait") as CanvasItem
	if portrait_layout != null:
		portrait_layout.visible = true
		# Neo layout phụ kín khung nội dung để node con luôn co đúng theo cột.
		var portrait_ctrl: Control = portrait_layout as Control
		if portrait_ctrl.anchor_right != 1.0 or portrait_ctrl.anchor_bottom != 1.0 \
				or portrait_ctrl.offset_right != 0.0 or portrait_ctrl.offset_bottom != 0.0:
			portrait_ctrl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var column := clampf(canvas.x, DESIGN_WIDTH, MAX_CONTENT_WIDTH)
	var target_pos := Vector2(floorf((canvas.x - column) * 0.5), 0.0)
	var target_size := Vector2(column, canvas.y)
	if position != target_pos:
		position = target_pos
	if size != target_size:
		size = target_size
	_apply_background_sides(canvas)

	# Portrait-only: hướng luôn DỌC — vẫn phát 1 lần lúc khởi động để màn con dàn UI.
	if not _orientation_ready:
		_orientation_ready = true
		is_landscape = false
		orientation_changed.emit(false)


## Layout đang hiển thị — nơi chứa toàn bộ UI của màn hình (portrait-only: node `Portrait`).
## Màn chưa tách layout thì trả về chính root.
func active_layout() -> Node:
	var portrait_layout := get_node_or_null("Portrait")
	if portrait_layout != null:
		return portrait_layout
	return self


## Tìm node UI theo TÊN trong layout đang hiển thị (node `Portrait`).
func ui(node_name: String) -> Node:
	var holder := active_layout()
	if holder != self:
		var found := holder.find_child(node_name, true, false)
		if found != null:
			return found
	return find_child(node_name, true, false)


## Tìm node con theo tên trong 1 node cha (tránh trùng tên: Badge của 3 thẻ, Label của Stamp…)
func ui_child(parent_name: String, child_name: String) -> Node:
	var parent := ui(parent_name)
	if parent == null:
		return null
	return parent.get_node_or_null(child_name)


## Lấy node theo ĐƯỜNG DẪN trong layout đang hiển thị (node `Portrait`).
## Nhờ vậy script màn chỉ cần dùng `ui_path("A/B")` là tìm đúng node trong layout.
func ui_path(path: String) -> Node:
	var holder := active_layout()
	if holder != self:
		var found := holder.get_node_or_null(NodePath(path))
		if found != null:
			return found
	return get_node_or_null(NodePath(path))


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
		right.position = Vector2(size.x, 0.0)
		right.size = Vector2(maxf(canvas.x - position.x - size.x, 0.0), canvas.y)
