@tool
class_name NinePatchSprite2D
extends Node2D

# ==================== TEXTURE & KÍCH THƯỚC ====================
@export_group("Texture")
@export var texture: Texture2D:
	set(value):
		texture = value
		if texture and size == Vector2(64, 64):
			size = texture.get_size()
		queue_redraw()

## Kích thước của Sprite sau khi co giãn 9 lát cắt
@export var size: Vector2 = Vector2(64, 64):
	set(value):
		size = value.max(Vector2.ZERO)
		queue_redraw()

# ==================== 9-PATCH MARGINS ====================
@export_group("Patch Margins")
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

# ==================== STRETCH MODES & DRAW CENTER ====================
@export_group("Stretch & Center")
## Có vẽ phần trung tâm không (Tắt đi để tạo khung viền rỗng)
@export var draw_center: bool = true:
	set(value):
		draw_center = value
		queue_redraw()

## Chế độ dãn trục ngang: Stretch (Kéo dãn), Tile (Lặp lại), Tile Fit (Lặp vừa vặn)
@export var axis_stretch_horizontal: RenderingServer.NinePatchAxisMode = RenderingServer.NINE_PATCH_STRETCH:
	set(value):
		axis_stretch_horizontal = value
		queue_redraw()

## Chế độ dãn trục dọc: Stretch (Kéo dãn), Tile (Lặp lại), Tile Fit (Lặp vừa vặn)
@export var axis_stretch_vertical: RenderingServer.NinePatchAxisMode = RenderingServer.NINE_PATCH_STRETCH:
	set(value):
		axis_stretch_vertical = value
		queue_redraw()

# ==================== REGION ====================
@export_group("Region")
@export var region_rect: Rect2 = Rect2():
	set(value):
		region_rect = value
		queue_redraw()

@export_tool_button("Edit Region & Margins", "Edit")
var _open_editor_btn = _open_region_editor

# ==================== OFFSET & FLIP ====================
@export_group("Offset & Flip")
@export var centered: bool = true:
	set(value):
		centered = value
		queue_redraw()

@export var offset: Vector2 = Vector2.ZERO:
	set(value):
		offset = value
		queue_redraw()

@export var flip_h: bool = false:
	set(value):
		flip_h = value
		queue_redraw()

@export var flip_v: bool = false:
	set(value):
		flip_v = value
		queue_redraw()


func _draw() -> void:
	if not texture:
		return

	var src_rect = region_rect
	if src_rect.size == Vector2.ZERO:
		src_rect = Rect2(Vector2.ZERO, texture.get_size())

	# Xác định tâm lật (Flip quanh tâm của sprite)
	var center_point = offset if centered else offset + size * 0.5
	var scale_vec = Vector2(-1.0 if flip_h else 1.0, -1.0 if flip_v else 1.0)
	
	draw_set_transform(center_point, 0.0, scale_vec)
	var local_rect = Rect2(-size * 0.5, size)

	RenderingServer.canvas_item_add_nine_patch(
		get_canvas_item(),
		local_rect,
		src_rect,
		texture.get_rid(),
		Vector2(patch_margin_left, patch_margin_top),
		Vector2(patch_margin_right, patch_margin_bottom),
		axis_stretch_horizontal,
		axis_stretch_vertical,
		draw_center
	)


func _open_region_editor() -> void:
	if not Engine.is_editor_hint() or not texture:
		printerr("NinePatchSprite2D: Chưa gán Texture!")
		return

	NinePatchRegionDialog.open_generic(
		"NinePatch Sprite2D - " + name,
		texture,
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
