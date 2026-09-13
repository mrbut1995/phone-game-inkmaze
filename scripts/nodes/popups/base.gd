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

@onready var dim: ColorRect = get_node_or_null("Dim")
@onready var panel: Control = get_node_or_null("Panel")
@onready var content: Control = get_node_or_null("Panel/Content")


# --- Vòng đời ---------------------------------------------------------------

## Mở popup với dữ liệu kèm theo (được gọi bởi PopupManager)
func open(p_data: Dictionary = {}) -> void:
	data = p_data
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
	if _closing:
		return
	_closing = true
	_on_close()

	var tw := create_tween()
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
	closed.emit()
	queue_free()
