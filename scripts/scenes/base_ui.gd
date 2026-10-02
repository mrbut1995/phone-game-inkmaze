class_name BaseUI
extends Control
## ============================================================================
## NỀN UI DÙNG CHUNG (bản PORTRAIT-ONLY) — Dàn UI theo CỘT NỘI DUNG DỌC
##
## Quy ước layout (như mọi màn hình của game): node khai 1 layout con tên `Portrait`
## (kế thừa `scenes/layout/portrait/base_layout.tscn`). BaseUI giữ layout luôn HIỆN và
## neo nó kín khung nội dung.
##
## ⚠️ CHỈ ÁP KHI node CÓ node con `Portrait` — node KHÔNG có thì GIỮ NGUYÊN hoàn toàn
## (không đụng visible/size/anchor). Nhờ vậy script này dùng được cho cả MÀN HÌNH đầy đủ
## (BaseScene kế thừa nó) lẫn NỘI DUNG NHÚNG trong popup (VD `nodes/popups/profiler_content.tscn`).
##
## LƯU Ý KỸ THUẬT: lớp con override `_ready()` (không gọi super) nên logic ở đây
## đặt trong `_enter_tree()` + `_notification()` — Godot gọi 2 hàm này xuyên suốt
## chuỗi kế thừa script (lớp con tự khai `_notification` riêng vẫn không mất lượt gọi).
##
## Lớp con muốn chèn code vào 2 thời điểm thì override hook:
##   · `_on_ui_enter_tree()`        — chạy ĐẦU `_enter_tree` (BaseScene bỏ anchors gốc ở đây)
##   · `_after_responsive_layout()` — chạy SAU mỗi lần áp layout (BaseScene căn cột ở đây)
## ============================================================================

## (PORTRAIT-ONLY) Giữ để tương thích API: phát ĐÚNG 1 LẦN lúc khởi động (`false`) để
## các handler `_on_orientation_changed` của màn con chạy bước dàn UI theo layout.
signal orientation_changed(is_landscape: bool)

## (PORTRAIT-ONLY) Luôn `false` — không còn chế độ ngang.
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


## Áp layout DỌC của màn hình rồi gọi hook cho lớp con. Chạy lại mỗi khi canvas đổi cỡ;
## gọi được thủ công khi cần (dev tool đang gọi tên này).
func _apply_responsive_layout() -> void:
	if not _ui_ready or not is_inside_tree():
		return
	var canvas := get_viewport_rect().size
	if canvas.x <= 0.0 or canvas.y <= 0.0:
		return
	_apply_portrait_layout(get_node_or_null("Portrait") as CanvasItem)
	_after_responsive_layout(canvas)
	if not _orientation_ready:
		_orientation_ready = true
		is_landscape = false
		orientation_changed.emit(false)


## Giữ layout `Portrait` luôn HIỆN + neo nó kín khung nội dung (chỉ gọi khi có layout này).
func _apply_portrait_layout(portrait_layout: CanvasItem) -> void:
	if portrait_layout == null:
		return
	portrait_layout.visible = true
	# Neo layout phụ kín khung nội dung để node con luôn co đúng theo cột.
	var ctrl := portrait_layout as Control
	if ctrl == null:
		return
	if ctrl.anchor_right != 1.0 or ctrl.anchor_bottom != 1.0 \
			or ctrl.offset_right != 0.0 or ctrl.offset_bottom != 0.0:
		ctrl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## Hook — chạy ĐẦU `_enter_tree` (trước lần áp layout đầu tiên)
func _on_ui_enter_tree() -> void:
	pass


## Hook — chạy SAU mỗi lần áp layout (lớp con canh khung nội dung ở đây)
func _after_responsive_layout(_canvas: Vector2) -> void:
	pass


# ---------------------------------------------------------------------------
# Truy cập node UI trong layout đang hiển thị
# ---------------------------------------------------------------------------
## Layout đang hiển thị — nơi chứa toàn bộ UI (portrait-only: node `Portrait`).
## Node chưa tách layout thì trả về chính nó.
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
## Nhờ vậy script chỉ cần đổi `$A/B` → `ui_path("A/B")` là tìm đúng node trong layout.
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
# Scene khai `[connection]` cho nút/thanh trượt (đường dẫn `Portrait/…`).
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
