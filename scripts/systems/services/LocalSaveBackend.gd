class_name LocalSaveBackend
extends SaveBackend
## ============================================================================
## Backend: Lưu trên máy (mặc định của game).
##
## - Ưu tiên dùng DataManager (user://inkmaze_data.json) để mọi dữ liệu người
##   chơi nằm chung một file JSON duy nhất.
## - Nếu không có DataManager (ví dụ khi chạy test bằng --script) thì tự ghi
##   ra user://inkmaze_save.json.
## ============================================================================

const DATA_MANAGER_KEY := "player_progress"
const FALLBACK_PATH := "user://inkmaze_save.json"


func id() -> String:
	return "local"


func display_name() -> String:
	return "Local"


func is_available() -> bool:
	return true


func supports_cloud() -> bool:
	return false


func load_data() -> Dictionary:
	var dm := _data_manager()
	if dm != null:
		var value: Variant = dm.call("get_value", DATA_MANAGER_KEY, {})
		if value is Dictionary:
			return value
		return {}
	return _read_file()


func save_data(data: Dictionary) -> bool:
	var dm := _data_manager()
	if dm != null:
		dm.call("set_value", DATA_MANAGER_KEY, data, true)
		return true
	return _write_file(data)


func clear_data() -> bool:
	var dm := _data_manager()
	if dm != null:
		dm.call("erase_value", DATA_MANAGER_KEY, true)
		return true
	if FileAccess.file_exists(FALLBACK_PATH):
		return DirAccess.remove_absolute(ProjectSettings.globalize_path(FALLBACK_PATH)) == OK
	return true


func _data_manager() -> Node:
	var main_loop := Engine.get_main_loop()
	var tree := main_loop as SceneTree
	if tree != null and tree.root != null:
		return tree.root.get_node_or_null("DataManager")
	return null


func _read_file() -> Dictionary:
	if not FileAccess.file_exists(FALLBACK_PATH):
		return {}
	var file := FileAccess.open(FALLBACK_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _write_file(data: Dictionary) -> bool:
	var file := FileAccess.open(FALLBACK_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("[LocalSaveBackend] Khong mo duoc file: %s" % FALLBACK_PATH)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	return true
