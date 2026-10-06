@tool
class_name TextureButton2D
extends Node2D

## Tín hiệu phát ra khi click nút thành công
signal pressed

@export_group("Textures Các Trạng Thái")
## Texture ở trạng thái bình thường (bắt buộc)
@export var texture_normal: Texture2D:
	set(value):
		texture_normal = value
		queue_redraw()

## Texture khi chuột rê qua (Hover)
@export var texture_hover: Texture2D:
	set(value):
		texture_hover = value
		queue_redraw()

## Texture khi nhấn giữ chuột trái (Pressed)
@export var texture_pressed: Texture2D:
	set(value):
		texture_pressed = value
		queue_redraw()

## Texture khi nút bị vô hiệu hoá (Disabled)
@export var texture_disabled: Texture2D:
	set(value):
		texture_disabled = value
		queue_redraw()

@export_group("Thiết lập")
## Đặt gốc tọa độ (Pivot) nằm ở chính giữa hình
@export var centered: bool = true:
	set(value):
		centered = value
		queue_redraw()

## Vô hiệu hoá tương tác của nút
@export var disabled: bool = false:
	set(value):
		disabled = value
		_is_hovered = false
		_is_pressed = false
		queue_redraw()

# Các biến theo dõi trạng thái tương tác chuột
var _is_hovered: bool = false
var _is_pressed: bool = false


func _ready() -> void:
	queue_redraw()


## Lấy Texture tương ứng theo từng State
func _get_current_texture() -> Texture2D:
	if disabled:
		# Nếu không gán texture_disabled, sẽ dùng tạm texture_normal
		return texture_disabled if texture_disabled else texture_normal
	
	if not Engine.is_editor_hint():
		if _is_pressed and texture_pressed:
			return texture_pressed
		if _is_hovered and texture_hover:
			return texture_hover
			
	return texture_normal


## Tính toán vùng va chạm / khung vẽ của Texture
func _get_texture_rect() -> Rect2:
	var tex = _get_current_texture()
	var tex_size = tex.get_size() if tex else Vector2(64, 64)
	
	if centered:
		return Rect2(-tex_size / 2.0, tex_size)
	return Rect2(Vector2.ZERO, tex_size)


func _draw() -> void:
	var tex = _get_current_texture()
	var rect = _get_texture_rect()
	
	if tex:
		# Nếu bị disabled mà không có texture_disabled riêng, tự làm mờ texture_normal
		var modulate_color = Color(0.6, 0.6, 0.6, 0.7) if (disabled and not texture_disabled) else Color.WHITE
		draw_texture_rect(tex, rect, false, modulate_color)
	else:
		# Vẽ khung giữ chỗ (Placeholder) trên Editor khi chưa gán Texture
		draw_rect(rect, Color(1, 1, 1, 0.1), true)
		draw_rect(rect, Color.ORANGE, false, 2.0)
		var font = ThemeDB.fallback_font
		var text = "No Texture"
		var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 12)
		draw_string(font, rect.position + (rect.size - text_size) / 2.0 + Vector2(0, 10), text, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color.ORANGE)


## Vị trí con trỏ của SỰ KIỆN (theo hệ toạ độ của node).
## Dùng `event.position` thay cho `get_local_mouse_position()`: vị trí chuột của
## DisplayServer KHÔNG được cập nhật khi input đến từ CẢM ỨNG (chuột mô phỏng) hoặc
## từ sự kiện đẩy bằng code (test) ⇒ nút sẽ không bao giờ nhận được cú bấm.
func _event_local_pos(event: InputEventMouse) -> Vector2:
	return get_global_transform().affine_inverse() * event.position


func _unhandled_input(event: InputEvent) -> void:
	# Không xử lý tương tác khi đang trong Editor hoặc nút bị vô hiệu hóa
	if Engine.is_editor_hint() or disabled:
		return

	var mouse_event := event as InputEventMouse
	if mouse_event == null:
		return
	var rect = _get_texture_rect()
	var local_pos := _event_local_pos(mouse_event)

	# Xử lý Hover
	if event is InputEventMouseMotion:
		var hovered_now = rect.has_point(local_pos)
		if hovered_now != _is_hovered:
			_is_hovered = hovered_now
			queue_redraw()

	# Xử lý Click (Press / Release)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			# Nhấn TRONG nút ⇒ coi như đang rê lên nút (cảm ứng không có bước hover riêng)
			if rect.has_point(local_pos):
				_is_hovered = true
				_is_pressed = true
				queue_redraw()
		elif _is_pressed:
			_is_pressed = false
			queue_redraw()
			# Chỉ kích hoạt nếu thả chuột vẫn ở bên trong nút
			if rect.has_point(local_pos):
				pressed.emit()
