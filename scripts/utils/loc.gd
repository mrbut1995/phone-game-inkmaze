class_name Loc
extends RefCounted
## ============================================================================
## Helper tĩnh: truy cập LocalizationManager qua /root (autoload) để script
## chạy được cả khi test bằng `godot --script` (không resolve identifier autoload
## lúc parse). Xem thêm Sfx / Nav.
## ============================================================================


static func _mgr() -> Node:
	var main_loop := Engine.get_main_loop()
	var tree := main_loop as SceneTree
	if tree != null and tree.root != null:
		return tree.root.get_node_or_null("LocalizationManager")
	return null


## Danh sach ma ngon ngu duoc ho tro (nap tu string.csv)
static func locales() -> Array:
	var mgr := _mgr()
	if mgr != null:
		return mgr.get("supported_locales")
	return ["vi"]


## Mã ngôn ngữ đang dùng
static func current() -> String:
	var mgr := _mgr()
	if mgr != null:
		return str(mgr.get("current_locale"))
	return "vi"


## Đổi ngôn ngữ hiển thị (lưu vào SettingManager)
static func set_locale(code: String) -> void:
	var mgr := _mgr()
	if mgr != null:
		mgr.call("set_locale", code)


## Tên hiển thị: "Tiếng Việt (VN)"
static func display_name(code: String) -> String:
	var mgr := _mgr()
	if mgr != null:
		return str(mgr.call("get_display_name", code))
	return code.to_upper()


## Thông tin ngôn ngữ: { flag, name, sub }
static func info(code: String) -> Dictionary:
	var mgr := _mgr()
	if mgr != null:
		return mgr.call("get_locale_info", code)
	return {"flag": "", "name": code.to_upper(), "sub": ""}
