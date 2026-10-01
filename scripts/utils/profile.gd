class_name Profile
extends RefCounted
## ============================================================================
## Helper tĩnh: truy cập PlayerProfileManager (autoload) qua /root.
##
## Lý do tồn tại: test runner chạy bằng `godot --script ...` không resolve được
## identifier autoload lúc parse, nên script khác KHÔNG được tham chiếu thẳng
## `PlayerProfileManager`. Ở đây lấy node động qua /root/PlayerProfileManager.
## ============================================================================


static func manager() -> Node:
	var tree := _tree()
	if tree != null and tree.root != null:
		return tree.root.get_node_or_null("PlayerProfileManager")
	return null


static func _call(method: String, args: Array = []) -> Variant:
	var m := manager()
	if m == null or not m.has_method(method):
		return null
	return m.callv(method, args)


# --- Định danh --------------------------------------------------------------
static func display_name() -> String:
	var value: Variant = _call("display_name_text")
	return str(value) if value != null else ""


static func set_display_name(new_name: String) -> bool:
	var value: Variant = _call("set_display_name", [new_name])
	return bool(value) if value != null else false


static func uid_text() -> String:
	var m := manager()
	if m == null:
		return "#IM-0000"
	return "#IM-%s • %s" % [str(m.get("uid_suffix")), str(m.get("joined_date"))]


static func avatar_id() -> String:
	var m := manager()
	return str(m.get("avatar_id")) if m != null else "avatar_ink"


static func frame_id() -> String:
	var m := manager()
	return str(m.get("frame_id")) if m != null else "frame_gear"


static func avatar_icon(ident: String) -> String:
	var value: Variant = _call("icon_of", ["avatar", ident])
	return str(value) if value != null else "res://assets/images/profiler/avatar_ink_knight.svg"


static func frame_icon(ident: String) -> String:
	var value: Variant = _call("icon_of", ["frame", ident])
	return str(value) if value != null else "res://assets/images/profiler/frame_gear_gold.svg"


# --- Danh mục / trang bị ----------------------------------------------------
static func avatars() -> Array:
	var value: Variant = _call("avatars")
	return value if value is Array else []


static func frames() -> Array:
	var value: Variant = _call("frames")
	return value if value is Array else []


static func equip_avatar(ident: String) -> bool:
	return bool(_call("equip_avatar", [ident]))


static func equip_frame(ident: String) -> bool:
	return bool(_call("equip_frame", [ident]))


static func buy_avatar(ident: String) -> bool:
	return bool(_call("buy_avatar", [ident]))


static func buy_frame(ident: String) -> bool:
	return bool(_call("buy_frame", [ident]))


static func lock_of(kind: String, ident: String) -> Dictionary:
	var value: Variant = _call("lock_of", [kind, ident])
	return value if value is Dictionary else {}


# --- Thống kê / EXP ---------------------------------------------------------
static func stats() -> Dictionary:
	var value: Variant = _call("stats")
	return value if value is Dictionary else {}


static func level() -> int:
	return int(_call("level"))


static func exp_in_level() -> int:
	return int(_call("exp_in_level"))


static func exp_step() -> int:
	return int(_call("exp_level_step"))


static func title_key() -> String:
	return str(_call("title_key"))


# --- Lịch sử ván ------------------------------------------------------------
static func record_run(info: Dictionary) -> void:
	_call("record_run", [info])


static func recent(limit: int = 3) -> Array:
	var value: Variant = _call("recent_activity", [limit])
	return value if value is Array else []


static func _tree() -> SceneTree:
	var main_loop := Engine.get_main_loop()
	return main_loop as SceneTree if main_loop is SceneTree else null
