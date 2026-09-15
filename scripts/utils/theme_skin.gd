class_name ThemeSkin
extends RefCounted
## ============================================================================
## Facade tĩnh cho ThemeManager (skin giấy + màu mực) — dùng trong UI/test.
##
## Hiện mới CHUẨN BỊ: `ThemeSkin.apply_theme(id)` / `ThemeSkin.apply_pen(id)` ghi nhận
## lựa chọn (qua ShopManager) và phát `skin_changed`, nhưng CHƯA đổi giao diện thật
## (ThemeManager.apply_enabled = false). Xem ThemeManager để biết chỗ cần bật.
## ============================================================================


static func manager() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("ThemeManager")


static func theme_id() -> String:
	var node := manager()
	return str(node.call("theme_id")) if node != null else ""


static func pen_id() -> String:
	var node := manager()
	return str(node.call("pen_id")) if node != null else ""


## Màu mực đang dùng (Color) — dùng cho vết vẽ/nét bút khi bật skin
static func pen_color() -> Color:
	var node := manager()
	if node == null:
		return Color("#224C6D")
	var value: Variant = node.call("pen_color")
	return value if value is Color else Color("#224C6D")


## Bảng màu chủ đề đang dùng
static func palette() -> Dictionary:
	var node := manager()
	var value: Variant = node.call("palette") if node != null else null
	return value if value is Dictionary else {}


## Màu 1 thành phần trong bảng màu
static func color(key: String) -> Color:
	var node := manager()
	if node == null:
		return Color("#FFFFFF")
	var value: Variant = node.call("color", key)
	return value if value is Color else Color("#FFFFFF")


static func apply_theme(theme_id: String) -> bool:
	var node := manager()
	return bool(node.call("apply_theme", theme_id)) if node != null else false


static func apply_pen(pen_id: String) -> bool:
	var node := manager()
	return bool(node.call("apply_pen", pen_id)) if node != null else false


static func is_apply_enabled() -> bool:
	var node := manager()
	return bool(node.get("apply_enabled")) if node != null else false
