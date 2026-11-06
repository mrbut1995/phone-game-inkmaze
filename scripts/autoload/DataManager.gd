extends Node
## ============================================================================
## Manager: DataManager - Lưu/đọc dữ liệu người chơi dạng JSON.
## - File: user://inkmaze_data.json
## - API đơn giản dạng key/value cho các manager khác (Daily, Ads...) dùng chung.
## ============================================================================

signal data_changed(key: String, value: Variant)
signal data_saved
signal data_loaded

const SAVE_PATH := "user://inkmaze_data.json"

var data: Dictionary = {}


func _ready() -> void:
	load_data()


func load_data() -> void:
	data.clear()
	if FileAccess.file_exists(SAVE_PATH):
		var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file != null:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			if parsed is Dictionary:
				data = parsed
			else:
				push_warning("[DataManager] File save sai định dạng, bỏ qua: %s" % SAVE_PATH)
	data_loaded.emit()


func save_data() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("[DataManager] Không mở được file để ghi: %s" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(data, "\t"))
	data_saved.emit()


func set_value(key: String, value: Variant, autosave := true) -> void:
	data[key] = value
	data_changed.emit(key, value)
	if autosave:
		save_data()


func get_value(key: String, default_value: Variant = null) -> Variant:
	return data.get(key, default_value)


func has_key(key: String) -> bool:
	return data.has(key)


func erase_value(key: String, autosave := true) -> void:
	if not data.has(key):
		return
	data.erase(key)
	data_changed.emit(key, null)
	if autosave:
		save_data()


func reset(autosave := true) -> void:
	data.clear()
	data_changed.emit("", null)
	if autosave:
		save_data()
