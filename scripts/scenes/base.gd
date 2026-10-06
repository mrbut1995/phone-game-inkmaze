class_name BaseScene
extends BaseUI
## ============================================================================
## Scene gốc dùng chung cho MỌI MÀN HÌNH (instance của `scenes/base.tscn`).
##
## Phần NHẬN BIẾT HƯỚNG + ĐỔI LAYOUT Portrait ⇄ Landscape đã tách sang `BaseUI`
## (scripts/scenes/base_ui.gd) và được BaseScene kế thừa. Ở đây chỉ còn phần
## DÀNH RIÊNG CHO MÀN HÌNH:
##
## CỘT NỘI DUNG canh giữa — toàn bộ UI thiết kế trên khung 1080×1920; khi màn hình
## rộng hơn tỉ lệ 9:16, root Control tự co thành CỘT NỘI DUNG canh giữa thay vì để
## nội dung dính mép trái:
##   · Bề rộng = clamp(canvas.x, 540, 1440) → màn hẹp giữ đúng bề ngang thiết kế,
##     tablet 3:4 (canvas 1440×1920) nở hết bề ngang màn.
##   · Chiều cao = chiều cao canvas → màn cao (9:18 · 9:19.5 · 9:21) giãn dọc.
##   · Màn NGANG có layout `Landscape` → root PHỦ KÍN canvas (layout tự dàn bằng anchors).
##   · Hai bên cột là nền giấy — 2 dải `SideL`/`SideR` (con của `Background`) tô tiếp
##     màu giấy ra hết mép màn hình nên nhìn như trang vở trải rộng.
##
## LƯU Ý KỸ THUẬT: mọi màn con override `_ready()` (không gọi super) nên logic ở đây
## đặt trong hook của BaseUI — `_on_ui_enter_tree()` + `_after_responsive_layout()` —
## KHÔNG đặt trong `_ready`.
## ============================================================================

## Bề rộng thiết kế của cột nội dung (khớp `display/window/size/viewport_width`)
const DESIGN_WIDTH := 540
## Bề rộng TỐI ĐA của cột nội dung ở màn DỌC: máy tính bảng 3:4 (canvas 1440×1920) nở ra
## dùng trọn bề ngang màn hình; màn nào hẹp hơn thì cột đúng bằng bề ngang canvas.
const MAX_CONTENT_WIDTH := 1440.0


## Bỏ anchors full-rect của node gốc — từ đây Root tự quản size/position (nếu giữ anchors
## 0..1 thì Godot ghi đè `size` sau `_ready` và cảnh báo "non-equal opposite anchors").
## `mouse_filter = IGNORE` (khai trong `scenes/base.tscn`): node gốc phủ kín canvas nên nếu
## để STOP nó sẽ NUỐT mọi cú bấm ⇒ các nút Node2D con bên dưới (vd `TextureButton2D` trên
## bản đồ màn Chọn màn — dùng `_unhandled_input`) KHÔNG bao giờ nhận được input.
func _on_ui_enter_tree() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT, true)


## Cột nội dung (canh giữa ngang) + nền giấy phủ toàn canvas.
## Được BaseUI gọi SAU khi đã bật/tắt layout theo hướng canvas.
func _after_responsive_layout(canvas: Vector2, landscape_now: bool, has_landscape: bool) -> void:
	if landscape_now and has_landscape:
		# Bố cục NGANG tự dàn bằng anchors/container tỉ lệ 0..1 → root phủ KÍN canvas
		if position != Vector2.ZERO:
			position = Vector2.ZERO
		if size != canvas:
			size = canvas
	else:
		var column := DESIGN_WIDTH
		if has_landscape:
			# Màn đã có layout ngang → màn dọc nở tối đa 1440 (dùng hết bề ngang tablet 3:4)
			column = clampf(canvas.x, DESIGN_WIDTH, MAX_CONTENT_WIDTH)
		var target_pos := Vector2(floorf((canvas.x - column) * 0.5), 0.0)
		var target_size := Vector2(column, canvas.y)
		if position != target_pos:
			position = target_pos
		if size != target_size:
			size = target_size
	_apply_background_sides(canvas)


## Hai bên cột (màn rộng hơn 9:16) tô tiếp màu giấy bằng 2 ColorRect con của
## `Background` — nền (`SceneBackground`) tự lo node con của mình, màn hình chỉ đưa số đo.
func _apply_background_sides(canvas: Vector2) -> void:
	var bg := get_node_or_null("Background") as SceneBackground
	if bg != null:
		bg.apply_sides(canvas, Rect2(position, size))
