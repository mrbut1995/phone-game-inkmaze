extends Node
## ============================================================================
## Manager: ShopManager — CỬA HÀNG (mockup/shopping_*.svg)
##
## 4 nhóm hàng (tab):
##   pen   · BÚT & MỰC  — skin ngòi bút (ĐỔI ĐƯỢC, xem ThemeManager.apply_pen)
##   theme · GIẤY VỞ    — chủ đề giấy/bàn cờ (ĐỔI ĐƯỢC, xem ThemeManager.apply_theme)
##   tool  · DỤNG CỤ    — vật phẩm tiêu hao mua bằng Xu (undo · gợi ý · ...)
##   coin  · NẠP XU     — gói nạp tiền thật (IAP) + gói xoá quảng cáo
##
## - Ví Xu dùng CHUNG với Sổ tay thành tựu (ArchivementManager.coins) — mua hàng
##   bằng Xu sẽ trừ trực tiếp vào ví đó.
## - Đã mua / đang dùng / số lượt còn lại của dụng cụ được LƯU vào save
##   (SaveManager tự gọi export_progress / import_progress).
## - "Áp dụng" theme/bút chỉ được GHI NHẬN ở đây (equipped_*), việc đổi giao diện
##   thật do ThemeManager lo — hiện mới CHUẨN BỊ, chưa bật (xem ThemeManager).
## ============================================================================

signal coins_changed(coins: int)                    # ví Xu đổi (mua/nạp/nhận thưởng)
signal item_purchased(id: String)                   # vừa mua 1 món
signal item_equipped(id: String, category: String)  # vừa chọn dùng bút/chủ đề
signal tool_used(id: String, left: int)             # vừa dùng 1 lượt dụng cụ

const CATEGORIES := ["pen", "theme", "tool", "coin"]
## Nhóm hàng đổi được trang bị (không tiêu hao)
const EQUIP_CATEGORIES := ["pen", "theme"]

## ---------------------------------------------------------------------------
## CATALOG — mọi món bán trong tiệm.
## name_key / desc_key / badge_key: khoá dịch (string_extra.csv, id,en,vi)
## price: 0 = mặc định (đã có sẵn) · price > 0 = giá bằng XU
## vnd: giá tiền thật (chỉ nhóm "coin") · amount: số Xu / số lượt nhận được
## color: màu đại diện (tô icon + chấm màu trên thẻ) · icon: khoá art trong assets/images/shop
## ---------------------------------------------------------------------------
const ITEMS: Array[Dictionary] = [
	# --- BÚT & MỰC ---------------------------------------------------------
	{"id": "pen_blue", "category": "pen", "price": 0, "color": "#3D83AE", "icon": "pen",
		"name_key": "STR_SHOP_PEN_BLUE_NAME", "desc_key": "STR_SHOP_PEN_BLUE_DESC",
		"badge_key": "STR_SHOP_BADGE_BASIC", "default": true},
	{"id": "pen_purple", "category": "pen", "price": 250, "color": "#7C3AED", "icon": "ink",
		"name_key": "STR_SHOP_PEN_PURPLE_NAME", "desc_key": "STR_SHOP_PEN_PURPLE_DESC",
		"badge_key": "STR_SHOP_BADGE_UNLOCKED", "unlocked": true},
	{"id": "pen_pencil_2b", "category": "pen", "price": 350, "color": "#6B7280", "icon": "pen",
		"name_key": "STR_SHOP_PEN_PENCIL_NAME", "desc_key": "STR_SHOP_PEN_PENCIL_DESC",
		"badge_key": "STR_SHOP_BADGE_SOUND"},
	{"id": "pen_red_teacher", "category": "pen", "price": 500, "color": "#D84444", "icon": "ink",
		"name_key": "STR_SHOP_PEN_RED_NAME", "desc_key": "STR_SHOP_PEN_RED_DESC",
		"badge_key": "STR_SHOP_BADGE_MARK"},
	{"id": "pen_highlighter", "category": "pen", "price": 650, "color": "#F59E0B", "icon": "pen",
		"name_key": "STR_SHOP_PEN_HIGHLIGHT_NAME", "desc_key": "STR_SHOP_PEN_HIGHLIGHT_DESC",
		"badge_key": "STR_SHOP_BADGE_GLOW"},
	{"id": "pen_gold_ink", "category": "pen", "price": 1200, "color": "#B45309", "icon": "ink",
		"name_key": "STR_SHOP_PEN_GOLD_NAME", "desc_key": "STR_SHOP_PEN_GOLD_DESC",
		"badge_key": "STR_SHOP_BADGE_VIP"},
	{"id": "pen_green_tea", "category": "pen", "price": 400, "color": "#15803D", "icon": "ink",
		"name_key": "STR_SHOP_PEN_GREEN_NAME", "desc_key": "STR_SHOP_PEN_GREEN_DESC",
		"badge_key": "STR_SHOP_BADGE_RELAX"},
	{"id": "pen_pink_diary", "category": "pen", "price": 550, "color": "#DB2777", "icon": "pen",
		"name_key": "STR_SHOP_PEN_PINK_NAME", "desc_key": "STR_SHOP_PEN_PINK_DESC",
		"badge_key": "STR_SHOP_BADGE_DIARY"},
	{"id": "pen_graphite_4b", "category": "pen", "price": 750, "color": "#374151", "icon": "pen",
		"name_key": "STR_SHOP_PEN_GRAPHITE_NAME", "desc_key": "STR_SHOP_PEN_GRAPHITE_DESC",
		"badge_key": "STR_SHOP_BADGE_SKETCH"},
	{"id": "pen_navy_night", "category": "pen", "price": 900, "color": "#1E3A8A", "icon": "ink",
		"name_key": "STR_SHOP_PEN_NAVY_NAME", "desc_key": "STR_SHOP_PEN_NAVY_DESC",
		"badge_key": "STR_SHOP_BADGE_NIGHT"},

	# --- GIẤY VỞ (CHỦ ĐỀ) --------------------------------------------------
	{"id": "theme_gride_4ly", "category": "theme", "price": 0, "color": "#3D83AE", "icon": "paper",
		"name_key": "STR_SHOP_THEME_4LY_NAME", "desc_key": "STR_SHOP_THEME_4LY_DESC",
		"badge_key": "STR_SHOP_BADGE_BASIC", "default": true, "paper": "#FAF5EB", "line": "#8FB9D2"},
	{"id": "theme_blackboard", "category": "theme", "price": 700, "color": "#1E293B", "icon": "paper",
		"name_key": "STR_SHOP_THEME_BOARD_NAME", "desc_key": "STR_SHOP_THEME_BOARD_DESC",
		"badge_key": "STR_SHOP_BADGE_NIGHT_MODE", "paper": "#1E293B", "line": "#94A3B8"},
	{"id": "theme_campus", "category": "theme", "price": 500, "color": "#64748B", "icon": "paper",
		"name_key": "STR_SHOP_THEME_CAMPUS_NAME", "desc_key": "STR_SHOP_THEME_CAMPUS_DESC",
		"badge_key": "STR_SHOP_BADGE_MODERN", "paper": "#F8FAFC", "line": "#94A3B8"},
	{"id": "theme_bullet", "category": "theme", "price": 550, "color": "#94A3B8", "icon": "paper",
		"name_key": "STR_SHOP_THEME_BULLET_NAME", "desc_key": "STR_SHOP_THEME_BULLET_DESC",
		"badge_key": "STR_SHOP_BADGE_MINIMAL", "paper": "#FFFDF8", "line": "#CBD5E1"},
	{"id": "theme_tech_grid", "category": "theme", "price": 800, "color": "#14B8A6", "icon": "paper",
		"name_key": "STR_SHOP_THEME_TECH_NAME", "desc_key": "STR_SHOP_THEME_TECH_DESC",
		"badge_key": "STR_SHOP_BADGE_PRECISE", "paper": "#F0FDFA", "line": "#14B8A6"},
	{"id": "theme_kraft", "category": "theme", "price": 900, "color": "#B45309", "icon": "paper",
		"name_key": "STR_SHOP_THEME_KRAFT_NAME", "desc_key": "STR_SHOP_THEME_KRAFT_DESC",
		"badge_key": "STR_SHOP_BADGE_VINTAGE", "paper": "#F5E6D3", "line": "#B45309"},
	{"id": "theme_pastel_caro", "category": "theme", "price": 1000, "color": "#F472B6", "icon": "paper",
		"name_key": "STR_SHOP_THEME_PASTEL_NAME", "desc_key": "STR_SHOP_THEME_PASTEL_DESC",
		"badge_key": "STR_SHOP_BADGE_CUTE", "paper": "#FDF2F8", "line": "#F472B6"},
	{"id": "theme_exam", "category": "theme", "price": 1200, "color": "#DC2626", "icon": "paper",
		"name_key": "STR_SHOP_THEME_EXAM_NAME", "desc_key": "STR_SHOP_THEME_EXAM_DESC",
		"badge_key": "STR_SHOP_BADGE_EXAM", "paper": "#FFFFFF", "line": "#DC2626"},

	# --- DỤNG CỤ (mua bằng Xu, dùng 1 lượt = trừ 1) ------------------------
	{"id": "tool_undo_x10", "category": "tool", "price": 150, "amount": 10, "color": "#3D83AE",
		"icon": "tool_undo", "name_key": "STR_SHOP_TOOL_UNDO_NAME", "desc_key": "STR_SHOP_TOOL_UNDO_DESC",
		"badge_key": "STR_SHOP_BADGE_PACK"},
	{"id": "tool_hint_x5", "category": "tool", "price": 200, "amount": 5, "color": "#F59E0B",
		"icon": "tool_hint", "name_key": "STR_SHOP_TOOL_HINT_NAME", "desc_key": "STR_SHOP_TOOL_HINT_DESC",
		"badge_key": "STR_SHOP_BADGE_PACK"},
	{"id": "tool_reveal_x3", "category": "tool", "price": 320, "amount": 3, "color": "#6D28D9",
		"icon": "tool_reveal", "name_key": "STR_SHOP_TOOL_REVEAL_NAME",
		"desc_key": "STR_SHOP_TOOL_REVEAL_DESC", "badge_key": "STR_SHOP_BADGE_NEW"},
	{"id": "tool_time_x3", "category": "tool", "price": 280, "amount": 3, "color": "#256286",
		"icon": "tool_time", "name_key": "STR_SHOP_TOOL_TIME_NAME", "desc_key": "STR_SHOP_TOOL_TIME_DESC",
		"badge_key": "STR_SHOP_BADGE_NEW"},
	{"id": "tool_revive_x1", "category": "tool", "price": 450, "amount": 1, "color": "#15803D",
		"icon": "tool_revive", "name_key": "STR_SHOP_TOOL_REVIVE_NAME",
		"desc_key": "STR_SHOP_TOOL_REVIVE_DESC", "badge_key": "STR_SHOP_BADGE_NEW"},
	{"id": "tool_shield_x2", "category": "tool", "price": 600, "amount": 2, "color": "#D84444",
		"icon": "tool_shield", "name_key": "STR_SHOP_TOOL_SHIELD_NAME",
		"desc_key": "STR_SHOP_TOOL_SHIELD_DESC", "badge_key": "STR_SHOP_BADGE_NEW"},

	# --- NẠP XU (tiền thật) ------------------------------------------------
	{"id": "coin_500", "category": "coin", "price": 0, "vnd": 19000, "amount": 500,
		"color": "#F59E0B", "icon": "coin_t1", "name_key": "STR_SHOP_COIN_500_NAME",
		"desc_key": "STR_SHOP_COIN_500_DESC", "badge_key": ""},
	{"id": "coin_2000", "category": "coin", "price": 0, "vnd": 69000, "amount": 2000, "bonus": 200,
		"color": "#F59E0B", "icon": "coin_t2", "name_key": "STR_SHOP_COIN_2000_NAME",
		"desc_key": "STR_SHOP_COIN_2000_DESC", "badge_key": "STR_SHOP_BADGE_RECOMMEND", "hot": true},
	{"id": "coin_3500", "category": "coin", "price": 0, "vnd": 99000, "amount": 3500, "bonus": 500,
		"color": "#F59E0B", "icon": "coin_t3", "name_key": "STR_SHOP_COIN_3500_NAME",
		"desc_key": "STR_SHOP_COIN_3500_DESC", "badge_key": ""},
	{"id": "coin_8000", "category": "coin", "price": 0, "vnd": 199000, "amount": 8000, "bonus": 1600,
		"color": "#F59E0B", "icon": "coin_t4", "name_key": "STR_SHOP_COIN_8000_NAME",
		"desc_key": "STR_SHOP_COIN_8000_DESC", "badge_key": "STR_SHOP_BADGE_BEST"},
	{"id": "coin_20000", "category": "coin", "price": 0, "vnd": 399000, "amount": 20000, "bonus": 5000,
		"color": "#F59E0B", "icon": "coin_t5", "name_key": "STR_SHOP_COIN_20000_NAME",
		"desc_key": "STR_SHOP_COIN_20000_DESC", "badge_key": "STR_SHOP_BADGE_TYCOON"},
	{"id": "coin_no_ads", "category": "coin", "price": 0, "vnd": 49000, "amount": 0, "no_ads": true,
		"color": "#D84444", "icon": "coin", "name_key": "STR_SHOP_COIN_NOADS_NAME",
		"desc_key": "STR_SHOP_COIN_NOADS_DESC", "badge_key": "STR_SHOP_BADGE_RECOMMEND"},
]

## ---------------------------------------------------------------------------
## Trạng thái người chơi (được lưu vào save)
## ---------------------------------------------------------------------------
var owned: Dictionary = {}            # item_id -> true (đã mua / đã tặng)
var tool_left: Dictionary = {}        # item_id -> số lượt còn lại (dụng cụ)
var equipped_pen: String = "pen_blue"
var equipped_theme: String = "theme_gride_4ly"
var purchase_log: Array[String] = []  # thứ tự món đã mua (dùng cho thống kê/test)


func _ready() -> void:
	_reset_defaults()


# ---------------------------------------------------------------------------
# Truy vấn catalog
# ---------------------------------------------------------------------------
## Toàn bộ món của 1 nhóm, theo đúng thứ tự trong ITEMS
func items(category: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for item_data in ITEMS:
		if str(item_data.get("category", "")) == category:
			out.append(item_data)
	return out


func item(item_id: String) -> Dictionary:
	for item_data in ITEMS:
		if str(item_data.get("id", "")) == item_id:
			return item_data
	return {}


func has_item(item_id: String) -> bool:
	return not item(item_id).is_empty()


## Giá mua bằng Xu (0 = mặc định/không bán bằng Xu)
func price_of(item_id: String) -> int:
	return maxi(int(item(item_id).get("price", 0)), 0)


## Số lượt nhận được khi mua (dụng cụ) / số Xu (gói nạp)
func amount_of(item_id: String) -> int:
	return maxi(int(item(item_id).get("amount", 0)), 0)


func category_of(item_id: String) -> String:
	return str(item(item_id).get("category", ""))


func is_consumable(item_id: String) -> bool:
	return category_of(item_id) == "tool"


func is_equippable(item_id: String) -> bool:
	return EQUIP_CATEGORIES.has(category_of(item_id))


## Là món mặc định (đã có sẵn từ đầu, không cần mua)
func is_default(item_id: String) -> bool:
	return bool(item(item_id).get("default", false))


# ---------------------------------------------------------------------------
# Ví Xu (dùng chung với Sổ tay thành tựu)
# ---------------------------------------------------------------------------
func coins() -> int:
	var wallet: Node = get_node_or_null("/root/ArchivementManager")
	return maxi(int(wallet.get("coins")), 0) if wallet != null else 0


func _add_coins(amount: int) -> void:
	var wallet: Node = get_node_or_null("/root/ArchivementManager")
	if wallet == null:
		return
	wallet.set("coins", maxi(int(wallet.get("coins")) + amount, 0))
	if wallet.has_method("notify_coins_changed"):
		wallet.call("notify_coins_changed")
	coins_changed.emit(coins())


func can_afford(item_id: String) -> bool:
	return coins() >= price_of(item_id)


# ---------------------------------------------------------------------------
# Mua / dùng
# ---------------------------------------------------------------------------
## Mua 1 món bằng Xu. Trả về true nếu mua được.
## - Dụng cụ: cộng thêm lượt (mua lại được nhiều lần)
## - Bút / chủ đề: mở khoá vĩnh viễn (đã có thì không mua lại)
func buy(item_id: String) -> bool:
	var item_data := item(item_id)
	if item_data.is_empty():
		return false
	if is_consumable(item_id):
		return _buy_consumable(item_id, item_data)
	if is_owned(item_id):
		return false
	var price := price_of(item_id)
	if price <= 0 or not can_afford(item_id):
		return false
	_add_coins(-price)
	owned[item_id] = true
	purchase_log.append(item_id)
	item_purchased.emit(item_id)
	queue_save()
	return true


func _buy_consumable(item_id: String, item_data: Dictionary) -> bool:
	var price := int(item_data.get("price", 0))
	if price <= 0 or not can_afford(item_id):
		return false
	_add_coins(-price)
	var gain := amount_of(item_id)
	tool_left[item_id] = int(tool_left.get(item_id, 0)) + gain
	if not owned.has(item_id):
		owned[item_id] = true
	purchase_log.append(item_id)
	item_purchased.emit(item_id)
	queue_save()
	return true


## Nạp gói Xu bằng tiền thật (IAP) — hiện là STUB: cộng Xu ngay để test luồng chơi.
## Khi nối Google Play Billing chỉ cần thay thân hàm này bằng luồng thanh toán thật.
func purchase_coin_pack(item_id: String) -> bool:
	var item_data := item(item_id)
	if item_data.is_empty() or category_of(item_id) != "coin":
		return false
	var gain := amount_of(item_id) + maxi(int(item_data.get("bonus", 0)), 0)
	if gain > 0:
		_add_coins(gain)
	if bool(item_data.get("no_ads", false)) and not owned.has(item_id):
		owned[item_id] = true
	purchase_log.append(item_id)
	item_purchased.emit(item_id)
	queue_save()
	return true


func is_owned(item_id: String) -> bool:
	return bool(owned.get(item_id, false)) or is_default(item_id)


func is_equipped(item_id: String) -> bool:
	match category_of(item_id):
		"pen":
			return equipped_pen == item_id
		"theme":
			return equipped_theme == item_id
	return false


## Số lượt còn lại của dụng cụ
func tool_count(item_id: String) -> int:
	return maxi(int(tool_left.get(item_id, 0)), 0)


## Dùng 1 lượt dụng cụ (trả về true nếu còn lượt để dùng)
func use_tool(item_id: String) -> bool:
	if not is_consumable(item_id):
		return false
	var left := tool_count(item_id)
	if left <= 0:
		return false
	tool_left[item_id] = left - 1
	tool_used.emit(item_id, left - 1)
	queue_save()
	return true


## Chọn dùng bút / chủ đề — CHỈ ghi nhận trạng thái "đang dùng".
## Việc đổi giao diện thật do ThemeManager đảm nhiệm (đang chuẩn bị, chưa bật).
func equip(item_id: String) -> bool:
	if not is_equippable(item_id) or not is_owned(item_id):
		return false
	match category_of(item_id):
		"pen":
			equipped_pen = item_id
		"theme":
			equipped_theme = item_id
		_:
			return false
	item_equipped.emit(item_id, category_of(item_id))
	_tell_theme_manager()
	queue_save()
	return true


func equipped_item(category: String) -> String:
	match category:
		"pen":
			return equipped_pen
		"theme":
			return equipped_theme
	return ""


## Món mặc định của mỗi nhóm (dùng khi reset)
func default_item(category: String) -> String:
	for item_data in items(category):
		if bool(item_data.get("default", false)):
			return str(item_data.get("id", ""))
	return ""


# ---------------------------------------------------------------------------
# Lưu trữ (SaveManager gọi export_progress / import_progress / reset_progress)
# ---------------------------------------------------------------------------
func export_progress() -> Dictionary:
	return {
		"owned": owned.duplicate(),
		"tool_left": tool_left.duplicate(),
		"equipped_pen": equipped_pen,
		"equipped_theme": equipped_theme,
		"purchase_log": purchase_log.duplicate(),
	}


func import_progress(data: Dictionary) -> void:
	_reset_defaults()
	var owned_data: Variant = data.get("owned", null)
	if owned_data is Dictionary:
		for key in owned_data.keys():
			if has_item(str(key)) and bool(owned_data[key]):
				owned[str(key)] = true
	var left_data: Variant = data.get("tool_left", null)
	if left_data is Dictionary:
		for key in left_data.keys():
			if has_item(str(key)):
				tool_left[str(key)] = maxi(int(left_data[key]), 0)
	var pen := str(data.get("equipped_pen", equipped_pen))
	if has_item(pen) and category_of(pen) == "pen" and is_owned(pen):
		equipped_pen = pen
	var theme := str(data.get("equipped_theme", equipped_theme))
	if has_item(theme) and category_of(theme) == "theme" and is_owned(theme):
		equipped_theme = theme
	var log_data: Variant = data.get("purchase_log", null)
	if log_data is Array:
		purchase_log.clear()
		for entry in log_data:
			purchase_log.append(str(entry))
	_tell_theme_manager()


func reset_progress() -> void:
	_reset_defaults()
	_tell_theme_manager()


func _reset_defaults() -> void:
	owned.clear()
	tool_left.clear()
	purchase_log.clear()
	for item_data in ITEMS:
		if bool(item_data.get("default", false)) or bool(item_data.get("unlocked", false)):
			owned[str(item_data.get("id", ""))] = true
	equipped_pen = default_item("pen")
	equipped_theme = default_item("theme")


## Đồng bộ sang ThemeManager (nó đọc lại equipped_* + màu tương ứng)
func _tell_theme_manager() -> void:
	var themes: Node = get_node_or_null("/root/ThemeManager")
	if themes != null and themes.has_method("sync_from_shop"):
		themes.call("sync_from_shop")


func queue_save() -> void:
	var save_api := load("res://scripts/utils/save.gd")
	if save_api != null and save_api.has_method("queue_save"):
		save_api.call("queue_save")
