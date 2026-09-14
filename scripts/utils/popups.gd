class_name Popups
extends RefCounted
## ============================================================================
## Helper tĩnh: mở/đóng popup qua autoload PopupManager.
##
## Vì sao không gọi thẳng `PopupManager.open_popup(...)`?
##   Test runner chạy bằng `godot --script ...` -> identifier của autoload không
##   resolve được lúc parse. Vì vậy mọi nơi chỉ tham chiếu class `Popups` này,
##   node autoload được lấy động qua /root/PopupManager.
## ============================================================================

## Id các popup có sẵn (khớp PopupManager.POPUPS)
const WIN := "win"
const GAME_OVER := "game_over"
## Popup thua của Play/Level Mode: 3 thử thách + số Sao thay cho bước còn lại
const GAME_OVER_LEVEL := "game_over_level"
const NEXT_FLOOR := "next_floor"
const PAUSE := "pause"
const LANGUAGE := "language"


static func _mgr() -> Node:
	var main_loop := Engine.get_main_loop()
	var tree := main_loop as SceneTree
	if tree != null and tree.root != null:
		return tree.root.get_node_or_null("PopupManager")
	return null


## Mở popup theo id. Trả về node popup (null nếu chưa có manager).
static func open(id: String, data: Dictionary = {}) -> BasePopup:
	var mgr := _mgr()
	if mgr == null:
		return null
	return mgr.call("open_popup", id, data) as BasePopup


## Mở popup từ đường dẫn scene
static func open_path(path: String, data: Dictionary = {}) -> BasePopup:
	var mgr := _mgr()
	if mgr == null:
		return null
	return mgr.call("open_path", path, data) as BasePopup


static func close_id(id: String) -> bool:
	var mgr := _mgr()
	return bool(mgr.call("close_id", id)) if mgr != null else false


static func close_top() -> bool:
	var mgr := _mgr()
	return bool(mgr.call("close_top")) if mgr != null else false


static func close_all() -> void:
	var mgr := _mgr()
	if mgr != null:
		mgr.call("close_all")


static func has_open() -> bool:
	var mgr := _mgr()
	return bool(mgr.call("has_open")) if mgr != null else false


static func is_open(id: String) -> bool:
	var mgr := _mgr()
	return bool(mgr.call("is_open", id)) if mgr != null else false


static func get_popup(id: String) -> BasePopup:
	var mgr := _mgr()
	if mgr == null:
		return null
	return mgr.call("get_popup", id) as BasePopup


static func top() -> BasePopup:
	var mgr := _mgr()
	if mgr == null:
		return null
	return mgr.call("top") as BasePopup
