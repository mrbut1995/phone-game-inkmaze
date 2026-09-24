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

# ==================== 2. LIÊN KẾT BUTTON CHA & PREVIEW ====================
@export_group("State Sync & Preview")
## Tự động đồng bộ trạng thái khi là con của Button / BaseButton
@export var sync_with_parent_button: bool = true:
	set(value):
		sync_with_parent_button = value
		_update_parent_listeners()
		_check_and_update_state()

## Menu xem trước trạng thái trực tiếp trong Editor Viewport
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
	# Để MOUSE_FILTER_PASS để click không bị chặn, Button cha vẫn nhận được chuột
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
	# 1. Preview trên Editor
	if Engine.is_editor_hint() and editor_preview_state != State.NORMAL:
		return editor_preview_state

	# 2. Đồng bộ theo nút cha
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

	# 3. Độc lập khi không có nút cha
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


# ==================== VẼ CƠ BẢN (NHƯ TEXTURERECT) ====================
func _draw() -> void:
	var tex = get_active_texture()
	if tex:
		draw_texture_rect(tex, Rect2(Vector2.ZERO, size), false)


func _get_minimum_size() -> Vector2:
	var tex = get_active_texture()
	return tex.get_size() if tex else Vector2.ZERO
