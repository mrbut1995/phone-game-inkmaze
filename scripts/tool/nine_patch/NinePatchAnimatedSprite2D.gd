@tool
class_name NinePatchAnimatedSprite2D
extends Node2D

signal animation_finished()
signal animation_looped()
signal frame_changed()

# ==================== ANIMATION FRAMES ====================
@export_group("Animation")
@export var sprite_frames: SpriteFrames:
	set(value):
		sprite_frames = value
		_update_animation_properties()
		queue_redraw()

@export var animation: StringName = &"default":
	set(value):
		animation = value
		frame = 0
		_timer = 0.0
		queue_redraw()

@export var frame: int = 0:
	set(value):
		frame = value
		_timer = 0.0
		frame_changed.emit()
		queue_redraw()

@export var speed_scale: float = 1.0
@export var is_playing: bool = true:
	set(value):
		is_playing = value
		set_process(is_playing)

# ==================== KÍCH THƯỚC & 9-PATCH ====================
@export_group("NinePatch Size & Margins")
@export var size: Vector2 = Vector2(64, 64):
	set(value):
		size = value.max(Vector2.ZERO)
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

@export var draw_center: bool = true:
	set(value):
		draw_center = value
		queue_redraw()

@export_tool_button("Edit Region (Current Frame)", "Edit")
var _open_editor_btn = _open_frame_editor

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

var _timer: float = 0.0


func _ready() -> void:
	set_process(is_playing)


func _process(delta: float) -> void:
	if not sprite_frames or not sprite_frames.has_animation(animation):
		return
		
	var frame_count = sprite_frames.get_frame_count(animation)
	if frame_count <= 1:
		return

	var fps = sprite_frames.get_animation_speed(animation) * speed_scale
	if is_zero_approx(fps):
		return

	_timer += delta * absf(fps)
	var duration = sprite_frames.get_frame_duration(animation, frame)

	if _timer >= duration:
		_timer -= duration
		var next_frame = frame + 1
		var loop = sprite_frames.get_animation_loop(animation)

		if next_frame >= frame_count:
			if loop:
				frame = 0
				animation_looped.emit()
			else:
				is_playing = false
				animation_finished.emit()
		else:
			frame = next_frame


func _draw() -> void:
	if not sprite_frames or not sprite_frames.has_animation(animation):
		return

	var frame_count = sprite_frames.get_frame_count(animation)
	if frame_count == 0:
		return

	var current_tex = sprite_frames.get_frame_texture(animation, clampi(frame, 0, frame_count - 1))
	if not current_tex:
		return

	var dest_pos = offset - (size * 0.5 if centered else Vector2.ZERO)
	var dest_rect = Rect2(dest_pos, size)
	var src_rect = Rect2(Vector2.ZERO, current_tex.get_size())

	# Xử lý lật
	var scale_x = -1.0 if flip_h else 1.0
	var scale_y = -1.0 if flip_v else 1.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_x, scale_y))

	RenderingServer.canvas_item_add_nine_patch(
		get_canvas_item(),
		dest_rect,
		src_rect,
		current_tex.get_rid(),
		Vector2(patch_margin_left, patch_margin_top),
		Vector2(patch_margin_right, patch_margin_bottom),
		RenderingServer.NINE_PATCH_STRETCH,
		RenderingServer.NINE_PATCH_STRETCH,
		draw_center
	)


func play(anim_name: StringName = &"", custom_speed: float = 1.0) -> void:
	if anim_name != &"":
		animation = anim_name
	speed_scale = custom_speed
	is_playing = true


func pause() -> void:
	is_playing = false


func stop() -> void:
	is_playing = false
	frame = 0


func _update_animation_properties() -> void:
	if sprite_frames and sprite_frames.has_animation(animation):
		var count = sprite_frames.get_frame_count(animation)
		frame = clampi(frame, 0, maxi(0, count - 1))


func _open_frame_editor() -> void:
	if not Engine.is_editor_hint() or not sprite_frames or not sprite_frames.has_animation(animation):
		return

	var tex = sprite_frames.get_frame_texture(animation, frame)
	if not tex:
		printerr("Frame hiện tại không có texture!")
		return

	NinePatchRegionDialog.open_generic(
		"NinePatch Animated - %s [#%d]" % [animation, frame],
		tex,
		Rect2(),
		Vector4(patch_margin_left, patch_margin_top, patch_margin_right, patch_margin_bottom),
		func(_new_reg: Rect2, new_margins: Vector4):
			patch_margin_left = new_margins.x
			patch_margin_top = new_margins.y
			patch_margin_right = new_margins.z
			patch_margin_bottom = new_margins.w
			queue_redraw()
	)
