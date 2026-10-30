@tool
class_name NinePatchButton
extends Button

# ==================== TEXTURES ====================
@export_group("Textures")
@export var texture_normal: Texture2D:
	set(value):
		texture_normal = value
		_update_styles()

@export var texture_hover: Texture2D:
	set(value):
		texture_hover = value
		_update_styles()

@export var texture_pressed: Texture2D:
	set(value):
		texture_pressed = value
		_update_styles()

@export var texture_disabled: Texture2D:
	set(value):
		texture_disabled = value
		_update_styles()

@export var texture_focus: Texture2D:
	set(value):
		texture_focus = value
		_update_styles()

# ==================== 9-SLICE PATCH MARGINS ====================
@export_group("Patch Margins & Region")
## Vùng cắt ảnh Atlas / SpriteSheet (để Rect2(0,0,0,0) nếu dùng toàn ảnh)
@export var region_rect: Rect2 = Rect2():
	set(value):
		region_rect = value
		_update_styles()

@export var patch_margin_left: float = 0.0:
	set(value):
		patch_margin_left = maxf(0.0, value)
		_update_styles()

@export var patch_margin_top: float = 0.0:
	set(value):
		patch_margin_top = maxf(0.0, value)
		_update_styles()

@export var patch_margin_right: float = 0.0:
	set(value):
		patch_margin_right = maxf(0.0, value)
		_update_styles()

@export var patch_margin_bottom: float = 0.0:
	set(value):
		patch_margin_bottom = maxf(0.0, value)
		_update_styles()

# Nút mở Region Editor trực quan
@export_tool_button("Open Region Editor", "Edit")
var _open_editor_btn = _open_region_editor

# ==================== AXIS STRETCH & DRAW CENTER ====================
@export_group("Stretch & Center")
## Có vẽ phần trung tâm hay không (Tắt đi nếu muốn làm khung viền rỗng)
@export var draw_center: bool = true:
	set(value):
		draw_center = value
		_update_styles()

## Chế độ dãn trục ngang: Stretch (Kéo dãn), Tile (Lặp lại), Tile Fit (Lặp vừa vặn)
@export var axis_stretch_horizontal: StyleBoxTexture.AxisStretchMode = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH:
	set(value):
		axis_stretch_horizontal = value
		_update_styles()

## Chế độ dãn trục dọc: Stretch (Kéo dãn), Tile (Lặp lại), Tile Fit (Lặp vừa vặn)
@export var axis_stretch_vertical: StyleBoxTexture.AxisStretchMode = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH:
	set(value):
		axis_stretch_vertical = value
		_update_styles()

# ==================== CONTENT PADDING ====================
@export_group("Content Margins (Padding)")
@export var use_custom_content_margin: bool = false:
	set(value):
		use_custom_content_margin = value
		_update_styles()

@export var content_margin_left: float = 4.0:
	set(value):
		content_margin_left = value
		_update_styles()

@export var content_margin_top: float = 4.0:
	set(value):
		content_margin_top = value
		_update_styles()

@export var content_margin_right: float = 4.0:
	set(value):
		content_margin_right = value
		_update_styles()

@export var content_margin_bottom: float = 4.0:
	set(value):
		content_margin_bottom = value
		_update_styles()


# ==================== LOGIC KHỞI TẠO & CẬP NHẬT ====================
func _ready() -> void:
	_update_styles()


func _create_stylebox(tex: Texture2D) -> StyleBoxTexture:
	if not tex:
		return null
		
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.region_rect = region_rect
	
	# Cắt 9-slice texture
	sb.texture_margin_left = patch_margin_left
	sb.texture_margin_top = patch_margin_top
	sb.texture_margin_right = patch_margin_right
	sb.texture_margin_bottom = patch_margin_bottom
	
	# Chế độ co giãn các cạnh và vẽ ruột giữa
	sb.axis_stretch_horizontal = axis_stretch_horizontal
	sb.axis_stretch_vertical = axis_stretch_vertical
	sb.draw_center = draw_center
	
	# Canh lề chữ (padding bên trong nút)
	if use_custom_content_margin:
		sb.content_margin_left = content_margin_left
		sb.content_margin_top = content_margin_top
		sb.content_margin_right = content_margin_right
		sb.content_margin_bottom = content_margin_bottom
	else:
		# Mặc định lấy theo patch margins để text không đè lên viền 9-slice
		sb.content_margin_left = patch_margin_left
		sb.content_margin_top = patch_margin_top
		sb.content_margin_right = patch_margin_right
		sb.content_margin_bottom = patch_margin_bottom
		
	return sb


func _apply_style(state_name: StringName, tex: Texture2D, fallback_tex: Texture2D = null) -> void:
	var target_tex = tex if tex != null else fallback_tex
	if target_tex:
		var sb = _create_stylebox(target_tex)
		add_theme_stylebox_override(state_name, sb)
	else:
		remove_theme_stylebox_override(state_name)


func _update_styles() -> void:
	_apply_style(&"normal", texture_normal)
	_apply_style(&"hover", texture_hover, texture_normal)
	_apply_style(&"pressed", texture_pressed, texture_normal)
	_apply_style(&"disabled", texture_disabled, texture_normal)
	_apply_style(&"focus", texture_focus)
	
	queue_redraw()


func _open_region_editor() -> void:
	if not Engine.is_editor_hint():
		return
	if not texture_normal:
		printerr("NinePatchButton: Vui lòng gán 'Texture Normal' trước khi mở Region Editor!")
		return
	
	NinePatchRegionDialog.open_for_button(self)
