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
## Bề rộng TỐI ĐA của cột nội dung ở màn DỌC: máy tính bảng 3:4 (canvas 1440×1920) nở ra
## dùng trọn bề ngang màn hình; màn nào hẹp hơn thì cột đúng bằng bề ngang canvas.
const MAX_CONTENT_WIDTH := 1440.0

## Game chỉ chạy DỌC (portrait) — giữ hằng số này để các màn cũ không phải sửa.
const is_landscape := false

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


## ============================================================================
## BỐ CỤC THEO HƯỚNG MÀN HÌNH (2026-02 — theo `guide/GUIDE.MD`)
##
## Mỗi màn hình có thể khai 2 layout con CÙNG CẤP, CÙNG TÊN NODE bên trong:
##   · `Portrait`  — bố cục 1 cột (thiết kế 1080×1920) — KẾ THỪA `scenes/orientation/portrait/portrait.tscn`
##   · `Landscape` — bố cục 2 cột (thiết kế 1920×1080) — KẾ THỪA `scenes/orientation/landscape/landscape.tscn`
## BaseScene tự bật/tắt đúng layout theo hướng canvas — màn con KHÔNG cần code gì.
##
## Khung nội dung (root Control):
##   · Màn DỌC  → cột canh giữa: rộng `clamp(canvas.x, 1080, 1440)` × cao canvas.
##   · Màn NGANG có `Landscape` → root PHỦ KÍN canvas (bố cục ngang tự lo bằng anchors).
##   · Màn NGANG chưa tách layout → giữ nguyên hành vi cũ (cột 1080 canh giữa).
##
## LƯU Ý: 2 layout không thể dùng unique-name `%Tên` vì trùng tên — màn con lấy node bằng
## `ui("Tên")` (tìm trong layout đang hiển thị, tên node phải giống nhau ở cả 2 layout).
## ============================================================================
## Cột nội dung (canh giữa ngang) + nền giấy phủ toàn canvas + bật layout theo hướng
func _apply_responsive_layout() -> void:
	if not _responsive_ready or not is_inside_tree():
		return
	var canvas := get_viewport_rect().size
	if canvas.x <= 0.0 or canvas.y <= 0.0:
		return

	# Màn chỉ có 1 bố cục DỌC: neo phủ kín cột nội dung
	var portrait_ctrl := get_node_or_null("Portrait") as Control
	if portrait_ctrl != null:
		portrait_ctrl.visible = true
		if portrait_ctrl.anchor_right != 1.0 or portrait_ctrl.anchor_bottom != 1.0 \
				or portrait_ctrl.offset_right != 0.0 or portrait_ctrl.offset_bottom != 0.0:
			portrait_ctrl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Cột nội dung canh giữa (tablet 3:4 nở tối đa 1440, còn lại đúng 1080 thiết kế)
	var column := clampf(canvas.x, DESIGN_WIDTH, MAX_CONTENT_WIDTH)
	var target_pos := Vector2(floorf((canvas.x - column) * 0.5), 0.0)
	var target_size := Vector2(column, canvas.y)
	if position != target_pos:
		position = target_pos
	if size != target_size:
		size = target_size
	_apply_background_sides(canvas)


## Layout đang hiển thị — bản PORTRAIT thuần: màn nào có layout `Portrait` thì trả về nó,
## màn chưa tách layout thì trả về chính root.
func active_layout() -> Node:
	var portrait_layout := get_node_or_null("Portrait")
	if portrait_layout != null:
		return portrait_layout
	return self


## Tìm node UI theo TÊN trong layout đang hiển thị (2 layout dùng CÙNG tên node).
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


## Lấy node theo ĐƯỜNG DẪN trong layout đang hiển thị.
## Dùng khi 2 layout giữ CÙNG cấu trúc đường dẫn (VD `TopBar/Back`, `List/Cards`) —
## nhờ vậy script chỉ cần đổi `$A/B` → `ui_path("A/B")` là chạy được ở cả 2 hướng.
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
