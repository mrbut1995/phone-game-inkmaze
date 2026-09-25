@tool
class_name StateTexture
extends Control

signal state_changed(new_state: State)

enum State { NORMAL, HOVER, PRESSED, DISABLED, FOCUSED }

# ==================== 1. CÁC TRẠNG THÁI TEXTURE ====================
@export_group("Textures (States)")
@export var texture_normal: Texture2D:
	set(value):
		texture_normal = value
		update_minimum_size()
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

@export var texture_focused: Texture2D:
	set(value):
		texture_focused = value
		queue_redraw()

# ==================== 2. DISPLAY MODES (EXPAND & STRETCH) ====================
@export_group("Display Modes")
## Chế độ tính toán Minimum Size của Control theo kích thước ảnh
@export var expand_mode: TextureRect.ExpandMode = TextureRect.EXPAND_KEEP_SIZE:
	set(value):
		expand_mode = value
		update_minimum_size()
		queue_redraw()

## Chế độ căn chỉnh và co giãn ảnh trong khung
@export var stretch_mode: TextureRect.StretchMode = TextureRect.STRETCH_SCALE:
	set(value):
		stretch_mode = value
		queue_redraw()

# ==================== 3. FLIP (LẬT ẢNH) ====================
@export_group("Flip")
@export var flip_h: bool = false:
	set(value):
		flip_h = value
		queue_redraw()

## Lật theo chiều dọc (Vertical / Flip Z)
@export var flip_v: bool = false:
	set(value):
		flip_v = value
		queue_redraw()

## Alias code: Cho phép bạn dùng .flip_z thay cho .flip_v
var flip_z: bool:
	get: return flip_v
	set(value): flip_v = value

# ==================== 4. ĐỒNG BỘ NÚT CHA & PREVIEW ====================
@export_group("State Sync & Preview")
@export var sync_with_parent_button: bool = true:
	set(value):
		sync_with_parent_button = value
		_update_parent_listeners()
		_check_and_update_state()

@export var editor_preview_state: State = State.NORMAL:
	set(value):
		editor_preview_state = value
		_check_and_update_state()

# Biến nội bộ
var _current_state: State = State.NORMAL
var _self_hovered: bool = false
var _self_pressed: bool = false
var _cached_parent: BaseButton = null


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_update_parent_listeners()
	_check_and_update_state()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PARENTED:
			_update_parent_listeners()
			_check_and_update_state()
		NOTIFICATION_UNPARENTED:
			_disconnect_parent_listeners()
			_check_and_update_state()


# ==================== LẮNG NGHE BUTTON CHA ====================
func _disconnect_parent_listeners() -> void:
	if _cached_parent:
		if _cached_parent.draw.is_connected(_on_parent_changed):
			_cached_parent.draw.disconnect(_on_parent_changed)
		if _cached_parent.mouse_entered.is_connected(_on_parent_changed):
			_cached_parent.mouse_entered.disconnect(_on_parent_changed)
		if _cached_parent.mouse_exited.is_connected(_on_parent_changed):
			_cached_parent.mouse_exited.disconnect(_on_parent_changed)
		if _cached_parent.button_down.is_connected(_on_parent_changed):
			_cached_parent.button_down.disconnect(_on_parent_changed)
		if _cached_parent.button_up.is_connected(_on_parent_changed):
			_cached_parent.button_up.disconnect(_on_parent_changed)
		_cached_parent = null


func _update_parent_listeners() -> void:
	_disconnect_parent_listeners()
	if not sync_with_parent_button:
		return

	var p = get_parent()
	if p is BaseButton:
		_cached_parent = p
		p.draw.connect(_on_parent_changed)
		p.mouse_entered.connect(_on_parent_changed)
		p.mouse_exited.connect(_on_parent_changed)
		p.button_down.connect(_on_parent_changed)
		p.button_up.connect(_on_parent_changed)


func _on_parent_changed() -> void:
	_check_and_update_state()


# ==================== TÍNH TOÁN TRẠNG THÁI ====================
func get_current_state() -> State:
	if Engine.is_editor_hint() and editor_preview_state != State.NORMAL:
		return editor_preview_state

	if sync_with_parent_button and _cached_parent:
		if _cached_parent.disabled:
			return State.DISABLED
		if _cached_parent.is_pressed():
			return State.PRESSED
		if _cached_parent.is_hovered():
			return State.HOVER
		if _cached_parent.has_focus():
			return State.FOCUSED
		return State.NORMAL

	if _self_pressed:
		return State.PRESSED
	if _self_hovered:
		return State.HOVER

	return State.NORMAL


func _check_and_update_state() -> void:
	var new_state = get_current_state()
	if new_state != _current_state:
		_current_state = new_state
		state_changed.emit(_current_state)
		queue_redraw()


func get_active_texture() -> Texture2D:
	match _current_state:
		State.PRESSED:
			if texture_pressed: return texture_pressed
		State.HOVER:
			if texture_hover: return texture_hover
		State.DISABLED:
			if texture_disabled: return texture_disabled
		State.FOCUSED:
			if texture_focused: return texture_focused

	return texture_normal


# ==================== SỰ KIỆN CHUỘT (ĐỘC LẬP) ====================
func _gui_input(event: InputEvent) -> void:
	if sync_with_parent_button and _cached_parent:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_self_pressed = event.pressed
		_check_and_update_state()


func _on_mouse_entered() -> void:
	_self_hovered = true
	_check_and_update_state()


func _on_mouse_exited() -> void:
	_self_hovered = false
	_self_pressed = false
	_check_and_update_state()


# ==================== VẼ THEO STRETCH MODE & FLIP ====================
func _draw() -> void:
	var tex = get_active_texture()
	if not tex:
		return

	var tex_sz = tex.get_size()
	var draw_pos = Vector2.ZERO
	var draw_sz = size
	var is_tile = false

	# Tính toán vị trí và kích thước vẽ theo StretchMode
	match stretch_mode:
		TextureRect.STRETCH_SCALE:
			draw_pos = Vector2.ZERO
			draw_sz = size
		TextureRect.STRETCH_TILE:
			draw_pos = Vector2.ZERO
			draw_sz = size
			is_tile = true
		TextureRect.STRETCH_KEEP:
			draw_pos = Vector2.ZERO
			draw_sz = tex_sz
		TextureRect.STRETCH_KEEP_CENTERED:
			draw_pos = (size - tex_sz) * 0.5
			draw_sz = tex_sz
		TextureRect.STRETCH_KEEP_ASPECT:
			var scale_f = minf(size.x / tex_sz.x, size.y / tex_sz.y)
			draw_sz = tex_sz * scale_f
			draw_pos = Vector2.ZERO
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED:
			var scale_f = minf(size.x / tex_sz.x, size.y / tex_sz.y)
			draw_sz = tex_sz * scale_f
			draw_pos = (size - draw_sz) * 0.5
		TextureRect.STRETCH_KEEP_ASPECT_COVERED:
			var scale_f = maxf(size.x / tex_sz.x, size.y / tex_sz.y)
			draw_sz = tex_sz * scale_f
			draw_pos = (size - draw_sz) * 0.5

	# Xử lý Flip H và Flip V quanh tâm của Control
	var center = size * 0.5
	var scale_vec = Vector2(-1.0 if flip_h else 1.0, -1.0 if flip_v else 1.0)
	draw_set_transform(center, 0.0, scale_vec)

	var local_rect = Rect2(draw_pos - center, draw_sz)

	if is_tile:
		draw_texture_rect(tex, local_rect, true)
	else:
		draw_texture_rect(tex, local_rect, false)


# ==================== TÍNH MINIMUM SIZE THEO EXPAND MODE ====================
func _get_minimum_size() -> Vector2:
	var tex = get_active_texture()
	if not tex:
		return Vector2.ZERO

	var tex_sz = tex.get_size()
	match expand_mode:
		TextureRect.EXPAND_KEEP_SIZE:
			return tex_sz
		TextureRect.EXPAND_IGNORE_SIZE:
			return Vector2.ZERO
		TextureRect.EXPAND_FIT_WIDTH:
			return Vector2(tex_sz.x, 0.0)
		TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL:
			if size.x > 0.0 and tex_sz.x > 0.0:
				return Vector2(tex_sz.x, tex_sz.y * (size.x / tex_sz.x))
			return Vector2(tex_sz.x, 0.0)
		TextureRect.EXPAND_FIT_HEIGHT:
			return Vector2(0.0, tex_sz.y)
		TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL:
			if size.y > 0.0 and tex_sz.y > 0.0:
				return Vector2(tex_sz.x * (size.y / tex_sz.y), tex_sz.y)
			return Vector2(0.0, tex_sz.y)

	return Vector2.ZERO
