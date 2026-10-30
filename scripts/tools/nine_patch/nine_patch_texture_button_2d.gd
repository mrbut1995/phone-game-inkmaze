@tool
class_name NinePatchTextureButton2D
extends Node2D

## Tín hiệu kích hoạt khi click nút thành công
signal pressed

# ==================== KÍCH THƯỚC & TỌA ĐỘ ====================
@export_group("Transform & Size")
## Kích thước co dãn của Button trong không gian 2D
@export var size: Vector2 = Vector2(160, 60):
	set(value):
		size = value
		queue_redraw()

## Đặt gốc tọa độ (Pivot) nằm ở chính giữa Button
@export var centered: bool = true:
	set(value):
		centered = value
		queue_redraw()

# ==================== TEXTURES CÁC STATE ====================
@export_group("Textures")
@export var texture_normal: Texture2D:
	set(value):
		texture_normal = value
		queue_redraw()

@export var texture_hover: Texture2D:
	set(value):
		texture_hover = value
		queue_redraw()

@export var texture_pressed: Texture2D:
	set(value):
		texture_pressed = value
		queue_redraw()

@export var texture_disabled: Texture2D:
	set(value):
		texture_disabled = value
		queue_redraw()

# ==================== 9-SLICE PATCH MARGINS ====================
@export_group("Patch Margins & Region")
## Vùng cắt ảnh Atlas / SpriteSheet (để Rect2(0,0,0,0) nếu dùng toàn ảnh)
@export var region_rect: Rect2 = Rect2():
	set(value):
		region_rect = value
		queue_redraw()

@export var patch_margin_left: float = 0.0:
	set(value):
		patch_margin_left = maxf(0.0, value)
		queue_redraw()

@export var patch_margin_top: float = 0.0:
	set(value):
		patch_margin_top = maxf(0.0, value)
		queue_redraw()

@export var patch_margin_right: float = 0.0:
	set(value):
		patch_margin_right = maxf(0.0, value)
		queue_redraw()

@export var patch_margin_bottom: float = 0.0:
	set(value):
		patch_margin_bottom = maxf(0.0, value)
		queue_redraw()

## Nút mở Region Editor trực quan tích hợp với NinePatchRegionDialog
@export_tool_button("Open Region Editor", "Edit")
var _open_editor_btn = _open_region_editor

# ==================== STRETCH & DRAW CENTER ====================
@export_group("Stretch & Center")
@export var draw_center: bool = true:
	set(value):
		draw_center = value
		queue_redraw()

@export var axis_stretch_horizontal: StyleBoxTexture.AxisStretchMode = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH:
	set(value):
		axis_stretch_horizontal = value
		queue_redraw()

@export var axis_stretch_vertical: StyleBoxTexture.AxisStretchMode = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH:
	set(value):
		axis_stretch_vertical = value
		queue_redraw()

# ==================== TEXT (CHỮ TRÊN NÚT) ====================
@export_group("Text")
@export var text: String = "":
	set(value):
		text = value
		queue_redraw()

@export var font_size: int = 16:
	set(value):
		font_size = value
		queue_redraw()

@export var text_color: Color = Color.WHITE:
	set(value):
		text_color = value
		queue_redraw()

# ==================== TRẠNG THÁI ====================
@export_group("State")
@export var disabled: bool = false:
	set(value):
		disabled = value
		_is_hovered = false
		_is_pressed = false
		queue_redraw()

var _is_hovered: bool = false
var _is_pressed: bool = false


func _ready() -> void:
	queue_redraw()


# ==================== TÍNH TOÁN VÙNG VẼ & STYLE ====================
func _get_button_rect() -> Rect2:
	if centered:
		return Rect2(-size / 2.0, size)
	return Rect2(Vector2.ZERO, size)


func _get_current_texture() -> Texture2D:
	if disabled:
		return texture_disabled if texture_disabled != null else texture_normal
	
	if not Engine.is_editor_hint():
		if _is_pressed and texture_pressed != null:
			return texture_pressed
		if _is_hovered and texture_hover != null:
			return texture_hover
			
	return texture_normal


func _create_stylebox(tex: Texture2D) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.region_rect = region_rect
	
	# Cắt 9-Slice Margins
	sb.texture_margin_left = patch_margin_left
	sb.texture_margin_top = patch_margin_top
	sb.texture_margin_right = patch_margin_right
	sb.texture_margin_bottom = patch_margin_bottom
	
	# Cấu hình dãn các cạnh
	sb.axis_stretch_horizontal = axis_stretch_horizontal
	sb.axis_stretch_vertical = axis_stretch_vertical
	sb.draw_center = draw_center
	
	# Tự làm tối/mờ nếu bị Disabled mà không có texture_disabled riêng
	if disabled and texture_disabled == null:
		sb.modulate_color = Color(0.6, 0.6, 0.6, 0.7)
		
	return sb


# ==================== RENDER ====================
func _draw() -> void:
	var rect = _get_button_rect()
	var tex = _get_current_texture()

	# Vẽ 9-patch thông qua CanvasItem.draw_style_box
	if tex:
		var sb = _create_stylebox(tex)
		draw_style_box(sb, rect)
	else:
		# Khung giữ chỗ màu cam khi chưa gán texture
		draw_rect(rect, Color(1, 1, 1, 0.08), true)
		draw_rect(rect, Color.ORANGE, false, 2.0)
		var font = ThemeDB.fallback_font
		var placeholder = "No Texture"
		var p_sz = font.get_string_size(placeholder, HORIZONTAL_ALIGNMENT_CENTER, -1, 12)
		draw_string(font, rect.position + (rect.size - p_sz) / 2.0 + Vector2(0, 10), placeholder, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color.ORANGE)

	# Vẽ Text căn giữa (nếu có nội dung)
	if not text.is_empty():
		var font = ThemeDB.fallback_font
		var ascent = font.get_ascent(font_size)
		var descent = font.get_descent(font_size)
		var baseline_y = rect.position.y + (rect.size.y + ascent - descent) / 2.0
		var text_pos = Vector2(rect.position.x, baseline_y)
		draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size, text_color)


# ==================== XỬ LÝ CHUỘT (RUNTIME) ====================
func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or disabled:
		return

	var rect = _get_button_rect()
	var local_mouse_pos = get_local_mouse_position()

	# Hover
	if event is InputEventMouseMotion:
		var hovered_now = rect.has_point(local_mouse_pos)
		if hovered_now != _is_hovered:
			_is_hovered = hovered_now
			queue_redraw()

	# Click
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed() and _is_hovered:
			_is_pressed = true
			queue_redraw()
		elif not event.is_pressed() and _is_pressed:
			_is_pressed = false
			queue_redraw()
			if rect.has_point(local_mouse_pos):
				pressed.emit()


# ==================== KẾT NỐI REGION DIALOG ====================
func _open_region_editor() -> void:
	if not Engine.is_editor_hint():
		return
	if not texture_normal:
		printerr("NinePatchTextureButton2D: Vui lòng gán 'Texture Normal' trước khi mở Region Editor!")
		return

	# Gọi hàm static mở generic có sẵn trong NinePatchRegionDialog
	NinePatchRegionDialog.open_generic(
		"Region Editor - " + name,
		texture_normal,
		region_rect,
		Vector4(patch_margin_left, patch_margin_top, patch_margin_right, patch_margin_bottom),
		func(new_reg: Rect2, new_margins: Vector4):
			region_rect = new_reg
			patch_margin_left = new_margins.x
			patch_margin_top = new_margins.y
			patch_margin_right = new_margins.z
			patch_margin_bottom = new_margins.w
			queue_redraw()
	)
