class_name BasePopup
extends Control
## ============================================================================
## Popup cơ sở (nodes/popups/base.tscn)
## - Được PopupManager tạo khi mở và tự xoá khi đóng (không instance sẵn).
## - Tự chạy hiệu ứng: nền mờ fade + mảnh giấy phóng nhẹ như dán lên màn hình.
## - Chặn input phía sau, đóng bằng nút Back nếu close_on_back = true.
##
## Popup con override _on_open() / _on_close() để nạp dữ liệu và phát signal.
## ============================================================================

signal opened
signal closed

const DUR_IN := 0.22
const DUR_OUT := 0.14
const SCALE_FROM := 0.92

## Id do PopupManager gán khi mở (khoá trong POPUPS hoặc tên file scene)
var popup_id: String = ""
## Dữ liệu truyền vào lúc mở popup
var data: Dictionary = {}
## Có đóng popup khi bấm nút Back / Esc không
@export var close_on_back := true

var _closing := false
## Tween hiệu ứng đang chạy (mở HOẶC đóng) — phải HUỶ khi bắt đầu hiệu ứng mới,
## nếu không tween đóng cũ vẫn chạy tiếp và `_finish_close()` sẽ xoá popup ngay
## sau khi vừa mở lại (bug: popup Game Over "nháy hiện rồi biến mất").
var _tween: Tween = null

@onready var dim: ColorRect = get_node_or_null("Dim")
@onready var panel: Control = get_node_or_null("Panel")
@onready var content: Control = get_node_or_null("Panel/Content")


# --- Bố cục theo tỉ lệ màn hình ---------------------------------------------

func _enter_tree() -> void:
	# Popup con override `_ready()` nên dùng `_enter_tree` + `_notification` (xem base scene).
	var vp := get_viewport()
	if vp != null and not vp.size_changed.is_connected(_apply_canvas_layout):
		vp.size_changed.connect(_apply_canvas_layout)
	_apply_canvas_layout()


func _notification(what: int) -> void:
	if what == NOTIFICATION_READY or what == NOTIFICATION_RESIZED:
		_apply_canvas_layout()


## Nền mờ (Dim) phủ TOÀN màn hình: popup nằm trong CỘT NỘI DUNG 1080px canh giữa
## (xem scripts/scenes/base.gd) nên màn rộng hơn 9:16 sẽ có 2 bên là nền giấy —
## dim phải trùm cả hai bên, còn thẻ popup (Panel) canh GIỮA CẢ HAI CHIỀU của canvas
## (màn cao hơn thiết kế 1920 thì thẻ phải ở giữa màn hình, không dính lên trên).
func _apply_canvas_layout() -> void:
	if not is_inside_tree():
		return
	var dim_rect := get_node_or_null("Dim") as Control
	if dim_rect == null:
		return
	var canvas := get_viewport_rect().size
	var dim_pos := -global_position
	if dim_rect.position != dim_pos:
		dim_rect.position = dim_pos
	if dim_rect.size != canvas:
		dim_rect.size = canvas
	# Thẻ nội dung: canh giữa theo canvas (bỏ qua offset thiết kế của từng popup)
	var panel := get_node_or_null("Panel") as Control
	if panel != null and panel.size.x > 0.0 and panel.size.y > 0.0:
		var target := Vector2(
			floorf((canvas.x - panel.size.x) * 0.5) - global_position.x,
			floorf((canvas.y - panel.size.y) * 0.5) - global_position.y)
		if panel.position != target:
			panel.position = target


# --- Vòng đời ---------------------------------------------------------------

## Mở popup với dữ liệu kèm theo (được gọi bởi PopupManager)
func open(p_data: Dictionary = {}) -> void:
	data = p_data
	# Mở lại trong lúc đang đóng (mở trùng id, mở nhanh liên tiếp): huỷ tween đóng cũ
	_kill_tween()
	_closing = false
	visible = true

	_on_open()

	if dim != null:
		dim.modulate = Color(1, 1, 1, 0)
	if panel != null:
		panel.pivot_offset = panel.size * 0.5
		panel.scale = Vector2.ONE * SCALE_FROM
		panel.modulate = Color(1, 1, 1, 0)

	var tw := create_tween()
	_tween = tw
	tw.set_parallel(true)
	if dim != null:
		tw.tween_property(dim, "modulate:a", 1.0, DUR_IN)
	if panel != null:
		tw.tween_property(panel, "modulate:a", 1.0, DUR_IN)
		tw.tween_property(panel, "scale", Vector2.ONE, DUR_IN).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_callback(_on_opened_anim_done)

	opened.emit()


## Đóng popup: chạy hiệu ứng rồi tự xoá khỏi cây scene
func close() -> void:
	# Nếu đã đang đóng thì bỏ qua (tránh chạy 2 tween đóng chồng nhau)
	if _closing:
		return
	var utc_time = Time.get_datetime_string_from_system(true)
	print("Close Popup %s" % utc_time)
	_closing = true
	_on_close()

	_kill_tween()
	var tw := create_tween()
	_tween = tw
	tw.set_parallel(true)
	if dim != null:
		tw.tween_property(dim, "modulate:a", 0.0, DUR_OUT)
	if panel != null:
		tw.tween_property(panel, "modulate:a", 0.0, DUR_OUT)
		tw.tween_property(panel, "scale", Vector2.ONE * SCALE_FROM, DUR_OUT)
	tw.chain().tween_callback(_finish_close)


func is_closing() -> bool:
	return _closing


# --- Hook cho popup con -----------------------------------------------------

## Nạp dữ liệu / dựng nội dung trước khi hiệu ứng mở chạy
func _on_open() -> void:
	pass


## Dọn dẹp (ngắt kết nối, dừng tween...) trước khi hiệu ứng đóng chạy
func _on_close() -> void:
	pass


## Hiệu ứng mở kết thúc
func _on_opened_anim_done() -> void:
	pass


# --- Tiện ích cho popup con -------------------------------------------------

## Nối nhanh nút bấm theo đường dẫn node trong popup
func bind_button(path: NodePath, handler: Callable) -> TextureButton:
	var btn := get_node_or_null(path) as TextureButton
	if btn == null:
		push_warning("%s: khong tim thay nut '%s'" % [name, path])
		return null
	if not btn.pressed.is_connected(handler):
		btn.pressed.connect(handler)
	return btn


## Lấy node trong khu vực nội dung trên mảnh giấy.
## Tìm theo đường dẫn tương đối, nếu không thấy thì tìm sâu theo tên node.
func piece(path: NodePath) -> Node:
	var scope: Node = content if content != null else self
	var node := scope.get_node_or_null(path)
	if node == null:
		node = scope.find_child(String(path).get_file(), true, false)
	return node


func _finish_close() -> void:
	# Trong lúc tween đóng chạy, popup có thể được MỞ LẠI (open) -> không xoá nữa.
	if not _closing:
		return
	closed.emit()
	queue_free()


## Huỷ tween hiệu ứng đang chạy (nếu có) để không chồng hiệu ứng lên nhau
func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
