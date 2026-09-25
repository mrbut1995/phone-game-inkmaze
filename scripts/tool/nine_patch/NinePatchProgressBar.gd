@tool
class_name NinePatchProgressBar
extends ProgressBar

# ==================== 1. BACKGROUND (NỀN) ====================
@export_group("Background")
@export var texture_background: Texture2D:
	set(value):
		texture_background = value
		_update_styles()

@export var bg_region_rect: Rect2 = Rect2():
	set(value):
		bg_region_rect = value
		_update_styles()

@export var bg_margin_left: float = 0.0:
	set(value):
		bg_margin_left = maxf(0.0, value)
		_update_styles()

@export var bg_margin_top: float = 0.0:
	set(value):
		bg_margin_top = maxf(0.0, value)
		_update_styles()

@export var bg_margin_right: float = 0.0:
	set(value):
		bg_margin_right = maxf(0.0, value)
		_update_styles()

@export var bg_margin_bottom: float = 0.0:
	set(value):
		bg_margin_bottom = maxf(0.0, value)
		_update_styles()

## Vẽ ruột của Background (Tắt đi nếu muốn làm khung viền rỗng nhìn xuyên qua)
@export var bg_draw_center: bool = true:
	set(value):
		bg_draw_center = value
		_update_styles()

@export var bg_axis_stretch_horizontal: StyleBoxTexture.AxisStretchMode = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH:
	set(value):
		bg_axis_stretch_horizontal = value
		_update_styles()

@export var bg_axis_stretch_vertical: StyleBoxTexture.AxisStretchMode = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH:
	set(value):
		bg_axis_stretch_vertical = value
		_update_styles()

@export_tool_button("Edit Background Region", "Edit")
var _btn_edit_bg = _open_bg_editor

# ==================== 2. FILL (THANH TIẾN TRÌNH) ====================
@export_group("Fill (Progress)")
@export var texture_fill: Texture2D:
	set(value):
		texture_fill = value
		_update_styles()

@export var fill_region_rect: Rect2 = Rect2():
	set(value):
		fill_region_rect = value
		_update_styles()

@export var fill_margin_left: float = 0.0:
	set(value):
		fill_margin_left = maxf(0.0, value)
		_update_styles()

@export var fill_margin_top: float = 0.0:
	set(value):
		fill_margin_top = maxf(0.0, value)
		_update_styles()

@export var fill_margin_right: float = 0.0:
	set(value):
		fill_margin_right = maxf(0.0, value)
		_update_styles()

@export var fill_margin_bottom: float = 0.0:
	set(value):
		fill_margin_bottom = maxf(0.0, value)
		_update_styles()

## Vẽ ruột của Fill
@export var fill_draw_center: bool = true:
	set(value):
		fill_draw_center = value
		_update_styles()

## Cực kỳ hữu ích: Chọn Tile nếu muốn làm thanh máu chia từng vạch đốt
@export var fill_axis_stretch_horizontal: StyleBoxTexture.AxisStretchMode = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH:
	set(value):
		fill_axis_stretch_horizontal = value
		_update_styles()

@export var fill_axis_stretch_vertical: StyleBoxTexture.AxisStretchMode = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH:
	set(value):
		fill_axis_stretch_vertical = value
		_update_styles()

@export_tool_button("Edit Fill Region", "Edit")
var _btn_edit_fill = _open_fill_editor

# ==================== 3. FILL PADDING (INSET LỌT LÒNG) ====================
@export_group("Fill Padding (Inset)")
@export var padding_left: float = 0.0:
	set(value):
		padding_left = value
		_update_styles()

@export var padding_top: float = 0.0:
	set(value):
		padding_top = value
		_update_styles()

@export var padding_right: float = 0.0:
	set(value):
		padding_right = value
		_update_styles()

@export var padding_bottom: float = 0.0:
	set(value):
		padding_bottom = value
		_update_styles()


# ==================== LOGIC KHỞI TẠO & CẬP NHẬT ====================
func _ready() -> void:
	_update_styles()


func _create_stylebox(
	tex: Texture2D,
	reg: Rect2,
	ml: float, mt: float, mr: float, mb: float,
	draw_ctr: bool,
	axis_h: StyleBoxTexture.AxisStretchMode,
	axis_v: StyleBoxTexture.AxisStretchMode,
	c_left: float = -1.0, c_top: float = -1.0, c_right: float = -1.0, c_bottom: float = -1.0
) -> StyleBoxTexture:
	if not tex:
		return null
		
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.region_rect = reg
	
	# Margins 9-slice
	sb.texture_margin_left = ml
	sb.texture_margin_top = mt
	sb.texture_margin_right = mr
	sb.texture_margin_bottom = mb
	
	# Chế độ co giãn & ruột
	sb.draw_center = draw_ctr
	sb.axis_stretch_horizontal = axis_h
	sb.axis_stretch_vertical = axis_v
	
	# Content padding (áp dụng cho background để thụt lề thanh fill vào trong)
	if c_left >= 0.0:
		sb.content_margin_left = c_left
		sb.content_margin_top = c_top
		sb.content_margin_right = c_right
		sb.content_margin_bottom = c_bottom
		
	return sb


func _update_styles() -> void:
	# Cập nhật Background StyleBox
	if texture_background:
		var sb_bg = _create_stylebox(
			texture_background, bg_region_rect,
			bg_margin_left, bg_margin_top, bg_margin_right, bg_margin_bottom,
			bg_draw_center, bg_axis_stretch_horizontal, bg_axis_stretch_vertical,
			padding_left, padding_top, padding_right, padding_bottom
		)
		add_theme_stylebox_override(&"background", sb_bg)
	else:
		remove_theme_stylebox_override(&"background")
		
	# Cập nhật Fill StyleBox
	if texture_fill:
		var sb_fill = _create_stylebox(
			texture_fill, fill_region_rect,
			fill_margin_left, fill_margin_top, fill_margin_right, fill_margin_bottom,
			fill_draw_center, fill_axis_stretch_horizontal, fill_axis_stretch_vertical
		)
		add_theme_stylebox_override(&"fill", sb_fill)
	else:
		remove_theme_stylebox_override(&"fill")

	queue_redraw()


# ==================== MỞ REGION DIALOG ====================
func _open_bg_editor() -> void:
	if not Engine.is_editor_hint(): return
	if not texture_background:
		printerr("NinePatchProgressBar: Chưa chọn Texture Background!")
		return
	
	NinePatchRegionDialog.open_generic(
		"Edit Background Region - " + name,
		texture_background,
		bg_region_rect,
		Vector4(bg_margin_left, bg_margin_top, bg_margin_right, bg_margin_bottom),
		func(new_reg: Rect2, new_margins: Vector4):
			bg_region_rect = new_reg
			bg_margin_left = new_margins.x
			bg_margin_top = new_margins.y
			bg_margin_right = new_margins.z
			bg_margin_bottom = new_margins.w
			_update_styles()
	)


func _open_fill_editor() -> void:
	if not Engine.is_editor_hint(): return
	if not texture_fill:
		printerr("NinePatchProgressBar: Chưa chọn Texture Fill!")
		return
		
	NinePatchRegionDialog.open_generic(
		"Edit Fill Region - " + name,
		texture_fill,
		fill_region_rect,
		Vector4(fill_margin_left, fill_margin_top, fill_margin_right, fill_margin_bottom),
		func(new_reg: Rect2, new_margins: Vector4):
			fill_region_rect = new_reg
			fill_margin_left = new_margins.x
			fill_margin_top = new_margins.y
			fill_margin_right = new_margins.z
			fill_margin_bottom = new_margins.w
			_update_styles()
	)
