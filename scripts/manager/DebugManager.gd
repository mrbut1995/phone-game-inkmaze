extends Node
## ============================================================================
## Manager: DebugManager - Cờ debug, log phân loại và màn hình Debug Console.
## - Chỉ in log khi `enabled` (mặc định: build debug) và flag của nhóm bật.
##   Dùng: DebugManager.log(DebugManager.CAT_SFX, "...")
## - Mở/đóng màn debug: phím F9 (action "debug_console" đăng ký trong code)
##   hoặc bấm liên tiếp vào con dấu phiên bản ở màn Settings (bản debug).
## ============================================================================

signal flag_changed(category: String, value: bool)

const CAT_GENERAL := "general"
const CAT_SFX := "sfx"
const CAT_FLOW := "flow"
const CAT_SAVE := "save"

## Input action mở màn debug + phím mặc định
const ACTION_TOGGLE := "debug_console"
const TOGGLE_KEY := KEY_F9

var enabled := OS.is_debug_build()
var flags: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_toggle_action()


## Đăng ký input action bằng code (không cần khai báo trong project.godot)
func _ensure_toggle_action() -> void:
	if not InputMap.has_action(ACTION_TOGGLE):
		InputMap.add_action(ACTION_TOGGLE)
	var key := InputEventKey.new()
	key.physical_keycode = TOGGLE_KEY
	if not InputMap.action_has_event(ACTION_TOGGLE, key):
		InputMap.action_add_event(ACTION_TOGGLE, key)


## Có được phép mở màn debug không (chỉ bản debug / khi bật cờ debug)
func can_open_console() -> bool:
	return enabled or OS.is_debug_build()


## Mở màn Debug Console, hoặc đóng nếu đang ở trong đó
func toggle_console() -> void:
	if not can_open_console():
		return
	var scene_manager: Node = get_node_or_null("/root/SceneManager")
	if scene_manager == null:
		return
	if bool(scene_manager.call("is_debug_scene")):
		close_console()
	else:
		scene_manager.call("goto_debug")


## Đóng màn debug: quay lại màn trước đó, nếu không có thì về Main
func close_console() -> void:
	var screen: Node = get_node_or_null("/root/ScreenManager")
	if screen != null and bool(screen.call("can_go_back")) and bool(screen.call("go_back")):
		return
	var scene_manager: Node = get_node_or_null("/root/SceneManager")
	if scene_manager != null:
		scene_manager.call("goto_main")


func _unhandled_input(event: InputEvent) -> void:
	if not can_open_console():
		return
	if event.is_action_pressed(ACTION_TOGGLE):
		toggle_console()
		get_viewport().set_input_as_handled()


func set_enabled(value: bool) -> void:
	enabled = value


func set_flag(category: String, value: bool) -> void:
	flags[category] = value
	flag_changed.emit(category, value)


func is_flag_on(category: String) -> bool:
	return bool(flags.get(category, true))


func log(category: String, message: String) -> void:
	if not enabled or not is_flag_on(category):
		return
	print("[%s] %s" % [category.to_upper(), message])


## Log quan trọng: luôn hiện dạng warning để dễ thấy trong editor
func warn(category: String, message: String) -> void:
	if not enabled:
		return
	push_warning("[%s] %s" % [category.to_upper(), message])
