class_name BaseUI
extends Control
## ============================================================================
## NỀN UI DÙNG CHUNG — NHẬN BIẾT HƯỚNG MÀN HÌNH + ĐỔI LAYOUT Portrait ⇄ Landscape
##
## Quy ước layout (như mọi màn hình của game): node có thể khai 2 node con CÙNG CẤP
## tên `Portrait` / `Landscape` với CÙNG TÊN node bên trong. BaseUI tự bật/tắt đúng
## layout theo hướng canvas (rộng hơn cao = NGANG) và neo cả 2 kín khung nội dung.
##
## ⚠️ CHỈ ÁP KHI node CÓ node con `Portrait`/`Landscape` — node KHÔNG có thì GIỮ
## NGUYÊN hoàn toàn (không đụng visible/size/anchor). Nhờ vậy script này dùng được
## cho cả MÀN HÌNH đầy đủ (BaseScene kế thừa nó) lẫn NỘI DUNG NHÚNG trong popup
## (VD `nodes/popups/profiler_content.tscn`).
##
## LƯU Ý KỸ THUẬT: lớp con override `_ready()` (không gọi super) nên logic ở đây
## đặt trong `_enter_tree()` + `_notification()` — Godot gọi 2 hàm này xuyên suốt
## chuỗi kế thừa script (lớp con tự khai `_notification` riêng vẫn không mất lượt gọi).
##
## Lớp con muốn chèn code vào 2 thời điểm thì override hook:
##   · `_on_ui_enter_tree()`        — chạy ĐẦU `_enter_tree` (BaseScene bỏ anchors gốc ở đây)
##   · `_after_responsive_layout()` — chạy SAU mỗi lần đổi layout (BaseScene căn cột ở đây)
## ============================================================================

## Phát khi hướng canvas ĐỔI (dọc ⇄ ngang) để lớp con đổi layout/bind lại node.
## Lần áp ĐẦU TIÊN cũng phát (lớp con đọc `is_landscape` trong `_ready` là chắc nhất).
signal orientation_changed(is_landscape: bool)

## Canvas đang NGANG hay không (rộng hơn cao)
var is_landscape := false

var _ui_ready := false
var _orientation_ready := false


func _enter_tree() -> void:
	_ui_ready = true
	_on_ui_enter_tree()
	var vp := get_viewport()
	if vp != null and not vp.size_changed.is_connected(_apply_responsive_layout):
		vp.size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()


func _notification(what: int) -> void:
	# READY: áp lại lần cuối sau khi cả cây scene đã vào (tránh race lúc khởi động).
	# RESIZED: cửa sổ đổi cỡ (kéo cửa sổ trên Windows / xoay máy trên điện thoại).
	if what == NOTIFICATION_READY or what == NOTIFICATION_RESIZED:
		_apply_responsive_layout()


## Nhận biết hướng canvas → đổi layout Portrait ⇄ Landscape → gọi hook cho lớp con.
## Chạy lại mỗi khi canvas đổi cỡ; gọi được thủ công khi cần (dev tool đang gọi tên này).
func _apply_responsive_layout() -> void:
	if not _ui_ready or not is_inside_tree():
		return
	var canvas := get_viewport_rect().size
	if canvas.x <= 0.0 or canvas.y <= 0.0:
		return
	var portrait_layout := get_node_or_null("Portrait") as CanvasItem
	var landscape_layout := get_node_or_null("Landscape") as CanvasItem
	var landscape_now := canvas.x > canvas.y
	if portrait_layout != null or landscape_layout != null:
		_apply_orientation_layout(portrait_layout, landscape_layout, landscape_now)
	_after_responsive_layout(canvas, landscape_now, landscape_layout != null)
	if not _orientation_ready or landscape_now != is_landscape:
		_orientation_ready = true
		is_landscape = landscape_now
		orientation_changed.emit(is_landscape)


## Bật/tắt + neo kín khung nội dung 2 layout (chỉ gọi khi có ít nhất 1 layout).
func _apply_orientation_layout(portrait_layout: CanvasItem, landscape_layout: CanvasItem, landscape_now: bool) -> void:
	var use_landscape := landscape_now and landscape_layout != null
	if portrait_layout != null:
		portrait_layout.visible = not use_landscape
	if landscape_layout != null:
		landscape_layout.visible = use_landscape
	# Neo 2 layout phụ kín khung nội dung: layout đang ẨN vẫn phải co theo khung,
	# nếu không các node con giữ kích thước của lần NGANG trước đó (bị báo "tràn màn hình").
	for ctrl: Control in [portrait_layout as Control, landscape_layout as Control]:
		if ctrl == null:
			continue
		if ctrl.anchor_right != 1.0 or ctrl.anchor_bottom != 1.0 \
				or ctrl.offset_right != 0.0 or ctrl.offset_bottom != 0.0:
			ctrl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## Hook — chạy ĐẦU `_enter_tree` (trước lần áp layout đầu tiên)
func _on_ui_enter_tree() -> void:
	pass


## Hook — chạy SAU mỗi lần nhận biết hướng/đổi layout (lớp con canh khung nội dung ở đây)
func _after_responsive_layout(_canvas: Vector2, _landscape_now: bool, _has_landscape: bool) -> void:
	pass


# ---------------------------------------------------------------------------
# Truy cập node UI trong layout đang hiển thị
# ---------------------------------------------------------------------------
## Layout đang hiển thị (Portrait / Landscape) — nơi chứa toàn bộ UI.
## Node chưa tách layout thì trả về chính nó.
func active_layout() -> Node:
	var landscape_layout := get_node_or_null("Landscape")
	if landscape_layout != null and is_landscape:
		return landscape_layout
	var portrait_layout := get_node_or_null("Portrait")
	if portrait_layout != null and landscape_layout != null:
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


# ---------------------------------------------------------------------------
# Dây tín hiệu khai trong .tscn — hàm này chỉ là LƯỚI AN TOÀN
#
# Scene khai `[connection]` cho nút/thanh trượt (đường dẫn `Portrait/…` + `Landscape/…`).
# Nếu người dùng sửa layout làm đường dẫn node đổi, Godot có thể bỏ dây ⇒ gọi
# `ensure_signal()` khi bind lại để nối lại ĐÚNG KHI dây bị mất (không nhân đôi).
# ---------------------------------------------------------------------------
## `target` mặc định là CHÍNH NODE NÀY; truyền target khác khi đích là node khác
## (VD nút "?" của màn chơi nối thẳng tới `GameController`).
func ensure_signal(source: Object, signal_name: StringName, handler: StringName, binds: Array = [], target: Object = null) -> void:
	var to: Object = target if target != null else self
	if source == null or to == null or not source.has_signal(signal_name) or not to.has_method(handler):
		return
	for c in source.get_signal_connection_list(signal_name):
		var cb: Callable = c.get("callable", Callable())
		if cb.is_valid() and cb.get_object() == to and cb.get_method() == handler:
			return
	var cb2 := Callable(to, handler)
	source.connect(signal_name, cb2 if binds.is_empty() else cb2.bindv(binds))
