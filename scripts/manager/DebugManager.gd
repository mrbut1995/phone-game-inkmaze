extends Node
## ============================================================================
## Manager: DebugManager - Cờ debug & log phân loại.
## - Chỉ in log khi `enabled` (mặc định: build debug) và flag của nhóm bật.
## - Dùng: DebugManager.log(DebugManager.CAT_SFX, "...")
## ============================================================================

signal flag_changed(category: String, value: bool)

const CAT_GENERAL := "general"
const CAT_SFX := "sfx"
const CAT_FLOW := "flow"
const CAT_SAVE := "save"

var enabled := OS.is_debug_build()
var flags: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


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
