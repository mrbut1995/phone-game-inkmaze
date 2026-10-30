@tool
class_name Button2D
extends Node2D

## Tín hiệu phát ra khi nút được nhấn
signal pressed

@export_group("Nội dung & Kích thước")
@export var text: String = "Click Me":
	set(value):
		text = value
		queue_redraw()

@export var size: Vector2 = Vector2(140, 50):
	set(value):
		size = value
		queue_redraw()

@export var corner_radius: int = 8:
	set(value):
		corner_radius = value
		queue_redraw()

@export_group("Màu sắc")
@export var normal_color: Color = Color("2e5bfc"):
	set(value):
		normal_color = value
		queue_redraw()

@export var hover_color: Color = Color("4f75ff"):
	set(value):
		hover_color = value
		queue_redraw()

@export var pressed_color: Color = Color("1e3ea8"):
	set(value):
		pressed_color = value
		queue_redraw()

@export var text_color: Color = Color.WHITE:
	set(value):
		text_color = value
		queue_redraw()

# Trạng thái tương tác khi chạy game
var _is_hovered: bool = false
var _is_pressed: bool = false


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	var rect = Rect2(-size / 2.0, size)
	
	# Chọn màu theo trạng thái (chỉ áp dụng hover/press khi game đang chạy)
	var current_color = normal_color
	if not Engine.is_editor_hint():
		if _is_pressed:
			current_color = pressed_color
		elif _is_hovered:
			current_color = hover_color
	
	# Vẽ nền nút bo góc bằng StyleBoxFlat
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = current_color
	style_box.set_corner_radius_all(corner_radius)
	draw_style_box(style_box, rect)
	
	# Vẽ Text căn giữa
	var font = ThemeDB.fallback_font
	var font_size = 16
	var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	# Tính baseline để chữ nằm chính giữa nút
	var text_pos = Vector2(-text_size.x / 2.0, (font_size / 2.0) - 2)
	draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, text_color)


func _unhandled_input(event: InputEvent) -> void:
	# Không bắt input tương tác chuột khi đang ở chế độ Editor
	if Engine.is_editor_hint():
		return
	
	var rect = Rect2(-size / 2.0, size)
	var local_mouse_pos = get_local_mouse_position()
	
	if event is InputEventMouseMotion:
		var hovered_now = rect.has_point(local_mouse_pos)
		if hovered_now != _is_hovered:
			_is_hovered = hovered_now
			queue_redraw()

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed() and _is_hovered:
			_is_pressed = true
			queue_redraw()
		elif not event.is_pressed() and _is_pressed:
			_is_pressed = false
			queue_redraw()
			# Kích hoạt signal nếu thả chuột trong phạm vi nút
			if rect.has_point(local_mouse_pos):
				pressed.emit()
