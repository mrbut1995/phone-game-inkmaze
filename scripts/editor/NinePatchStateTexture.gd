@tool
class_name NinePatchStateTexture
extends StateTexture

# ==================== 9-PATCH MARGINS ====================
@export_group("NinePatch Margins")
@export var patch_margin_left: float = 0.0:
	set(value):
		patch_margin_left = maxf(0.0, value)
		update_minimum_size()
		queue_redraw()

@export var patch_margin_top: float = 0.0:
	set(value):
		patch_margin_top = maxf(0.0, value)
		update_minimum_size()
		queue_redraw()

@export var patch_margin_right: float = 0.0:
	set(value):
		patch_margin_right = maxf(0.0, value)
		update_minimum_size()
		queue_redraw()

@export var patch_margin_bottom: float = 0.0:
	set(value):
		patch_margin_bottom = maxf(0.0, value)
		update_minimum_size()
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
var _btn_edit = _open_region_editor


# ==================== GHI ĐÈ HÀM VẼ (HỖ TRỢ FLIP CHO 9-PATCH) ====================
func _draw() -> void:
	var tex = get_active_texture()
	if not tex:
		return

	# Nếu không set margin và không cắt region -> dùng vẽ thông thường của StateTexture (đầy đủ Expand & Stretch Mode)
	var has_margins = (patch_margin_left > 0 or patch_margin_top > 0 or patch_margin_right > 0 or patch_margin_bottom > 0)
	if not has_margins and region_rect.size == Vector2.ZERO:
		super._draw()
		return

	var src_rect = region_rect if region_rect.size != Vector2.ZERO else Rect2(Vector2.ZERO, tex.get_size())

	# Xử lý Flip H và Flip V quanh tâm
	var center = size * 0.5
	var scale_vec = Vector2(-1.0 if flip_h else 1.0, -1.0 if flip_v else 1.0)
	draw_set_transform(center, 0.0, scale_vec)

	var local_dest_rect = Rect2(-size * 0.5, size)

	RenderingServer.canvas_item_add_nine_patch(
		get_canvas_item(),
		local_dest_rect,
		src_rect,
		tex.get_rid(),
		Vector2(patch_margin_left, patch_margin_top),
		Vector2(patch_margin_right, patch_margin_bottom),
		axis_stretch_horizontal,
		axis_stretch_vertical,
		draw_center
	)


func _get_minimum_size() -> Vector2:
	var min_patch = Vector2(patch_margin_left + patch_margin_right, patch_margin_top + patch_margin_bottom)
	if min_patch != Vector2.ZERO:
		return min_patch
	return super._get_minimum_size()


# ==================== MỞ REGION DIALOG ====================
func _open_region_editor() -> void:
	if not Engine.is_editor_hint():
		return
		
	var tex = get_active_texture()
	if not tex:
		printerr("NinePatchStateTexture: Cần gán ít nhất Texture Normal!")
		return

	NinePatchRegionDialog.open_generic(
		"State NinePatch Editor - " + name,
		tex,
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
