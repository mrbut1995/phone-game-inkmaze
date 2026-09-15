class_name Shop
extends RefCounted
## ============================================================================
## Facade tĩnh cho CỬA HÀNG (ShopManager) — dùng trong UI/test thay vì tham chiếu
## thẳng autoload (test `--script` không resolve được identifier autoload).
##
## Ví dụ: Shop.items("pen") · Shop.buy("pen_red_teacher") · Shop.coins_text()
## ============================================================================

const CATEGORIES := ["pen", "theme", "tool", "coin"]


static func manager() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("ShopManager")


static func available() -> bool:
	var node := manager()
	return node != null and node.has_method("items")


# ---------------------------------------------------------------------------
# Catalog
# ---------------------------------------------------------------------------
static func items(category: String) -> Array[Dictionary]:
	var node := manager()
	if node == null or not node.has_method("items"):
		return []
	var out: Array[Dictionary] = []
	for entry in node.call("items", category):
		out.append(entry)
	return out


static func item(item_id: String) -> Dictionary:
	var node := manager()
	if node == null or not node.has_method("item"):
		return {}
	var data: Variant = node.call("item", item_id)
	return data if data is Dictionary else {}


static func all_items() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for category in CATEGORIES:
		out.append_array(items(category))
	return out


# ---------------------------------------------------------------------------
# Trạng thái
# ---------------------------------------------------------------------------
static func coins() -> int:
	var node := manager()
	return int(node.call("coins")) if node != null and node.has_method("coins") else 0


static func is_owned(item_id: String) -> bool:
	var node := manager()
	return bool(node.call("is_owned", item_id)) if node != null else false


## Dụng cụ tiêu hao (mua lại được, mỗi lần dùng trừ 1 lượt)
static func is_consumable(item_id: String) -> bool:
	var node := manager()
	return bool(node.call("is_consumable", item_id)) if node != null else false


## Nhóm hàng: pen / theme / tool / coin
static func category_of(item_id: String) -> String:
	var node := manager()
	return str(node.call("category_of", item_id)) if node != null else ""


## Giá bằng Xu (0 = món mặc định hoặc không bán bằng Xu)
static func price_of(item_id: String) -> int:
	var node := manager()
	return int(node.call("price_of", item_id)) if node != null else 0


static func is_equipped(item_id: String) -> bool:
	var node := manager()
	return bool(node.call("is_equipped", item_id)) if node != null else false


static func can_afford(item_id: String) -> bool:
	var node := manager()
	return bool(node.call("can_afford", item_id)) if node != null else false


static func tool_count(item_id: String) -> int:
	var node := manager()
	return int(node.call("tool_count", item_id)) if node != null else 0


static func equipped_pen() -> String:
	var node := manager()
	return str(node.get("equipped_pen")) if node != null else ""


static func equipped_theme() -> String:
	var node := manager()
	return str(node.get("equipped_theme")) if node != null else ""


# ---------------------------------------------------------------------------
# Hành động
# ---------------------------------------------------------------------------
static func buy(item_id: String) -> bool:
	var node := manager()
	return bool(node.call("buy", item_id)) if node != null else false


static func use_tool(item_id: String) -> bool:
	var node := manager()
	return bool(node.call("use_tool", item_id)) if node != null else false


static func equip(item_id: String) -> bool:
	var node := manager()
	return bool(node.call("equip", item_id)) if node != null else false


static func purchase_coin_pack(item_id: String) -> bool:
	var node := manager()
	return bool(node.call("purchase_coin_pack", item_id)) if node != null else false


# ---------------------------------------------------------------------------
# Định dạng hiển thị
# ---------------------------------------------------------------------------
## 1250 -> "1,250"
static func thousands(value: int) -> String:
	var digits := str(absi(value))
	var out := ""
	var count := 0
	for index in range(digits.length() - 1, -1, -1):
		out = digits[index] + out
		count += 1
		if count % 3 == 0 and index > 0:
			out = "," + out
	return ("-" if value < 0 else "") + out


## 19000 -> "19.000 VNĐ"
static func vnd_text(value: int) -> String:
	var digits := str(maxi(value, 0))
	var out := ""
	var count := 0
	for index in range(digits.length() - 1, -1, -1):
		out = digits[index] + out
		count += 1
		if count % 3 == 0 and index > 0:
			out = "." + out
	return "%s VNĐ" % out
