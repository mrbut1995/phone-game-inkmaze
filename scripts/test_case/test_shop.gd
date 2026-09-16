extends SceneTree
## ============================================================================
## Test Case: CỬA HÀNG (Shop) — tính năng 2026-09
##
## 1. Catalog: 4 nhóm hàng (bút · giấy vở · dụng cụ · nạp xu), mọi món có đủ
##    khoá dịch + icon tồn tại + giá hợp lệ.
## 2. Ví Xu: mua trừ Xu, không đủ Xu thì không mua được, món mặc định có sẵn.
## 3. Dụng cụ: mua cộng lượt (mua lại được), dùng trừ 1 lượt, hết lượt thì không dùng.
## 4. Bút / chủ đề: mua mở khoá vĩnh viễn, chọn SỬ DỤNG -> ThemeSkin.apply_* (đã chuẩn bị,
##    apply_enabled = false nên CHƯA đổi giao diện), bảng màu lấy đúng theo chủ đề.
## 5. Bền vững: export/import/reset giữ đúng đồ đã mua + lượt dụng cụ + món đang dùng.
## 6. Scene Cửa hàng: 4 tab, lưới 6 ô/trang, thẻ nạp Xu (hàng VIP + lưới 2 cột + icon cấp Xu),
##    nút mua thật, ví Xu, banner tiếp sức.
## 7. Vuốt: vuốt ngang đổi trang · vuốt dọc cuộn danh sách · không mua nhầm khi vừa vuốt.
## 8. Nối dây: Nav/SceneManager/menu Main/Debug Console.
## ============================================================================

const TITLE := "CỬA HÀNG"
const SCENE_PATH := "res://scenes/shop.tscn"
const EXPECTED_COUNTS := {"pen": 10, "theme": 8, "tool": 6, "coin": 6}

var _backup := ""
var _shop_backup: Dictionary = {}
var _coins_backup := 0
var _failed := 0
var _checks := 0


func _init() -> void:
	print("\n========================================================")
	print("  TEST: %s" % TITLE)
	print("========================================================\n")

	await process_frame
	root.size = Vector2i(1080, 1920)

	if FileAccess.file_exists("user://inkmaze_data.json"):
		var rf := FileAccess.open("user://inkmaze_data.json", FileAccess.READ)
		_backup = rf.get_as_text()

	var shop: Node = root.get_node_or_null("ShopManager")
	var themes: Node = root.get_node_or_null("ThemeManager")
	var wallet: Node = root.get_node_or_null("ArchivementManager")
	assert(shop != null, "Autoload ShopManager phai ton tai")
	assert(themes != null, "Autoload ThemeManager phai ton tai")
	_shop_backup = shop.call("export_progress")
	_coins_backup = int(wallet.get("coins")) if wallet != null else 0

	_section_1_catalog(shop)
	_section_2_wallet(shop, wallet)
	_section_3_tools(shop)
	_section_4_equip(shop, themes)
	_section_5_persist(shop)
	await _section_6_scene(shop, wallet)
	await _section_7_gestures(shop, wallet)
	_section_8_wiring()

	# --- Khôi phục dữ liệu người chơi ---
	shop.call("import_progress", _shop_backup)
	if wallet != null:
		wallet.set("coins", _coins_backup)
	if not _backup.is_empty():
		var wf := FileAccess.open("user://inkmaze_data.json", FileAccess.WRITE)
		wf.store_string(_backup)
	print("[INFO] Da khoi phuc tien trinh nguoi choi.")

	print("\n--------------------------------------------------------")
	if _failed == 0:
		print("  KET QUA: %d/%d CHECK PASS" % [_checks, _checks])
	else:
		print("  KET QUA: %d/%d CHECK FAIL" % [_failed, _checks])
	print("--------------------------------------------------------\n")
	quit(1 if _failed > 0 else 0)


# ---------------------------------------------------------------------------
# 1. Catalog
# ---------------------------------------------------------------------------
func _section_1_catalog(shop: Node) -> void:
	print("[1] Catalog...")
	var all: Array = shop.call("all_items") if shop.has_method("all_items") else []
	var total := 0
	for category in EXPECTED_COUNTS.keys():
		var items: Array = shop.call("items", category)
		total += items.size()
		_entry(items.size() == int(EXPECTED_COUNTS[category]),
			"Nhom '%s' co %d mon (nhan %d)" % [category, EXPECTED_COUNTS[category], items.size()])
		# Món mặc định: mỗi nhóm đổi được (bút/giấy) phải có 1 món mặc định
		if category == "pen" or category == "theme":
			_entry(not str(shop.call("default_item", category)).is_empty(),
				"Nhom '%s' co mon mac dinh" % category)
		for item in items:
			var item_id := str(item.get("id", ""))
			_entry(shop.call("item", item_id).size() > 0, "Tim thay mon '%s'" % item_id)
			_entry(int(item.get("price", -1)) >= 0, "Mon %s co gia hop le" % item_id)
			# Mọi món phải có icon thật trong assets/images/shop
			var icon_path := "res://assets/images/shop/icon_%s.svg" % str(item.get("icon", ""))
			_entry(ResourceLoader.exists(icon_path), "Co icon cho %s (%s)" % [item_id, icon_path])
	_entry(total == 30, "Tong cong 30 mon hang (nhan %d)" % total)

	# Mọi khoá dịch phải tồn tại trong file chuỗi (translate(key) != key)
	var missing: Array[String] = []
	for category in EXPECTED_COUNTS.keys():
		for item in shop.call("items", category):
			for field in ["name_key", "desc_key"]:
				var key := str(item.get(field, ""))
				if TranslationServer.translate(key) == key:
					missing.append(key)
			var badge := str(item.get("badge_key", ""))
			if not badge.is_empty() and TranslationServer.translate(badge) == badge:
				missing.append(badge)
	_entry(missing.is_empty(), "Moi khoa dich cua mon hang deu ton tai (thieu: %s)" % str(missing))
	for key in ["STR_SHOP_TITLE", "STR_SHOP_TAB_PEN", "STR_SHOP_TAB_THEME", "STR_SHOP_TAB_TOOL",
			"STR_SHOP_TAB_COIN", "STR_SHOP_USE", "STR_SHOP_EQUIPPED", "STR_SHOP_STOCK_FORMAT",
			"STR_SHOP_PAGE_FORMAT", "STR_SHOP_BANNER_TITLE", "STR_SHOP_BANNER_BTN"]:
		_entry(TranslationServer.translate(key) != key, "Co chuoi '%s'" % key)


# ---------------------------------------------------------------------------
# 2. Ví Xu + mua hàng
# ---------------------------------------------------------------------------
func _section_2_wallet(shop: Node, wallet: Node) -> void:
	print("[2] Vi Xu va mua hang...")
	shop.call("reset_progress")
	wallet.set("coins", 0)
	_entry(int(shop.call("coins")) == 0, "Vi Xu bat dau = 0")
	_entry(bool(shop.call("is_owned", "pen_blue")), "But mac dinh (Muc Xanh) da co san")
	_entry(bool(shop.call("is_equipped", "pen_blue")), "But mac dinh dang duoc dung")
	_entry(not bool(shop.call("is_owned", "pen_red_teacher")), "But Do Giao Vien chua mua")
	_entry(not bool(shop.call("can_afford", "pen_red_teacher")),
		"Vi 0 Xu -> khong the mua But Do (500 Xu)")
	_entry(not bool(shop.call("buy", "pen_red_teacher")), "Mua khi thieu Xu -> false")

	wallet.set("coins", 1000)
	_entry(int(shop.call("coins")) == 1000, "Nap 1000 Xu")
	_entry(bool(shop.call("can_afford", "pen_red_teacher")), "Du Xu -> mua duoc")
	_entry(bool(shop.call("buy", "pen_red_teacher")), "Mua But Do Giao Vien (500 Xu)")
	_entry(int(shop.call("coins")) == 500, "Vi con 500 Xu sau khi mua")
	_entry(bool(shop.call("is_owned", "pen_red_teacher")), "But Do da thuoc so huu")
	_entry(not bool(shop.call("buy", "pen_red_teacher")), "Mua lai mon da co -> false")
	var log: Array = shop.get("purchase_log")
	_entry(log.size() == 1 and str(log[0]) == "pen_red_teacher",
		"Nhat ky mua hang ghi dung mon vua mua (%s)" % str(log))


# ---------------------------------------------------------------------------
# 3. Dụng cụ
# ---------------------------------------------------------------------------
func _section_3_tools(shop: Node) -> void:
	print("[3] Dung cu...")
	var wallet: Node = root.get_node_or_null("ArchivementManager")
	shop.call("reset_progress")
	wallet.set("coins", 500)
	_entry(int(shop.call("tool_count", "tool_undo_x10")) == 0, "Chua mua -> 0 luot undo")
	_entry(bool(shop.call("buy", "tool_undo_x10")), "Mua Goi Gom Tay 4B (150 Xu)")
	_entry(int(shop.call("tool_count", "tool_undo_x10")) == 10, "Nhan 10 luot undo")
	_entry(int(shop.call("coins")) == 350, "Vi con 350 Xu")
	_entry(bool(shop.call("buy", "tool_undo_x10")), "Dung cu MUA LAI duoc")
	_entry(int(shop.call("tool_count", "tool_undo_x10")) == 20, "Cong don thanh 20 luot")
	_entry(int(shop.call("coins")) == 200, "Vi con 200 Xu")
	_entry(bool(shop.call("use_tool", "tool_undo_x10")), "Dung 1 luot undo")
	_entry(int(shop.call("tool_count", "tool_undo_x10")) == 19, "Con 19 luot")
	_entry(not bool(shop.call("use_tool", "pen_blue")), "Mon khong phai dung cu -> khong dung duoc")
	for index in 19:
		shop.call("use_tool", "tool_undo_x10")
	_entry(int(shop.call("tool_count", "tool_undo_x10")) == 0, "Dung het 20 luot")
	_entry(not bool(shop.call("use_tool", "tool_undo_x10")), "Het luot -> khong dung duoc nua")


# ---------------------------------------------------------------------------
# 4. Trang bị bút / chủ đề (chuẩn bị sẵn việc apply)
# ---------------------------------------------------------------------------
func _section_4_equip(shop: Node, themes: Node) -> void:
	print("[4] Trang bi but / chu de...")
	var wallet: Node = root.get_node_or_null("ArchivementManager")
	shop.call("reset_progress")
	wallet.set("coins", 5000)

	_entry(not bool(shop.call("equip", "pen_green_tea")), "Chua mua -> khong chon dung duoc")
	_entry(bool(shop.call("buy", "pen_green_tea")), "Mua Muc Xanh Tra (400 Xu)")
	_entry(bool(shop.call("equip", "pen_green_tea")), "Chon dung Muc Xanh Tra")
	_entry(str(shop.get("equipped_pen")) == "pen_green_tea", "equipped_pen = pen_green_tea")
	_entry(bool(shop.call("is_equipped", "pen_green_tea")), "is_equipped() dung")
	_entry(not bool(shop.call("is_equipped", "pen_blue")), "But cu khong con dang dung")

	# ThemeManager đọc lại lựa chọn + bảng màu (CHƯA áp dụng vào giao diện)
	themes.call("sync_from_shop")
	_entry(str(themes.call("pen_id")) == "pen_green_tea", "ThemeManager.pen_id() khop ShopManager")
	_entry(themes.call("pen_color") == Color("#15803D"), "Mau muc lay dung mau but dang dung")
	_entry(not bool(themes.get("apply_enabled")),
		"Chua bat apply (dung yeu cau: chuan bi san, khong apply voi)")

	_entry(bool(shop.call("buy", "theme_blackboard")), "Mua chu de Bang Den Phan Trang (700 Xu)")
	_entry(bool(shop.call("buy", "theme_kraft")), "Mua chu de Giay Kraft Co Dien (900 Xu)")
	_entry(bool(shop.call("equip", "theme_kraft")), "Chon dung chu de Giay Kraft")
	_entry(str(shop.get("equipped_theme")) == "theme_kraft", "equipped_theme = theme_kraft")
	themes.call("sync_from_shop")
	_entry(str(themes.call("theme_id")) == "theme_kraft", "ThemeManager.theme_id() khop")
	var table: Dictionary = themes.call("palette")
	_entry(str(table.get("paper", "")) == "#F5E6D3",
		"Bang mau lay dung mau giay cua chu de (%s)" % str(table.get("paper", "")))
	_entry(str(table.get("line", "")) == "#B45309", "Bang mau lay dung mau duong ke")
	_entry(themes.call("color", "paper") == Color("#F5E6D3"), "color('paper') tra ve Color dung")

	_entry(not bool(shop.call("buy", "coin_500")), "Goi nap khong mua bang Xu (dung purchase_coin_pack)")
	var before := int(shop.call("coins"))
	_entry(bool(shop.call("purchase_coin_pack", "coin_500")), "Nap goi 500 Xu (STUB IAP)")
	_entry(int(shop.call("coins")) == before + 500, "Vi cong dung 500 Xu")
	var before_bonus := int(shop.call("coins"))
	shop.call("purchase_coin_pack", "coin_2000")
	_entry(int(shop.call("coins")) == before_bonus + 2200, "Goi 2,000 Xu cong ca 200 Xu thuong")


# ---------------------------------------------------------------------------
# 5. Bền vững
# ---------------------------------------------------------------------------
func _section_5_persist(shop: Node) -> void:
	print("[5] Luu / tai...")
	var data: Dictionary = shop.call("export_progress")
	_entry(data.has("owned") and data.has("tool_left") and data.has("equipped_pen")
		and data.has("equipped_theme"), "export_progress co du truong")
	shop.call("reset_progress")
	_entry(not bool(shop.call("is_owned", "theme_kraft")), "reset xoa do da mua")
	_entry(str(shop.get("equipped_pen")) == "pen_blue", "reset ve but mac dinh")
	shop.call("import_progress", data)
	_entry(bool(shop.call("is_owned", "theme_kraft")), "import khoi phuc chu de da mua")
	_entry(str(shop.get("equipped_pen")) == "pen_green_tea", "import khoi phuc but dang dung")
	_entry(str(shop.get("equipped_theme")) == "theme_kraft", "import khoi phuc chu de dang dung")
	var bad: Dictionary = {"equipped_pen": "khong_ton_tai", "owned": {"pen_red_teacher": true}}
	shop.call("import_progress", bad)
	_entry(str(shop.get("equipped_pen")) == "pen_blue",
		"Du lieu la -> but ve mac dinh (khong nhan mon khong ton tai)")
	_entry(not bool(shop.call("is_owned", "khong_ton_tai")), "Bo qua mon khong co trong catalog")


# ---------------------------------------------------------------------------
# 6. Scene Cửa hàng
# ---------------------------------------------------------------------------
func _section_6_scene(shop: Node, wallet: Node) -> void:
	print("[6] Scene Cua hang...")
	var packed := load(SCENE_PATH) as PackedScene
	_entry(packed != null, "Load duoc %s" % SCENE_PATH)
	if packed == null:
		return
	shop.call("reset_progress")
	wallet.set("coins", 1234)
	var scene: ShopScene = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	_entry(scene.get_node_or_null("TopBar/Back") is TextureButton, "Co nut Back")
	_entry(scene.get_node_or_null("Tabs") is HBoxContainer, "Co hang tab")
	_entry(scene.get_node_or_null("Wallet/Count") is Label, "Co vi Xu")
	_entry(scene.get_node_or_null("Content/List") is VBoxContainer, "Co danh sach mon hang")
	_entry(scene.get_node_or_null("GiftBanner/GiftBtn") is TextureButton, "Co nut o banner tiep suc")
	_entry(scene.tabs_box.get_child_count() == 4, "4 tab duoc dung bang code")
	for category in ["pen", "theme", "tool", "coin"]:
		_entry(scene.tab_button(category) != null, "Co tab '%s'" % category)
	_entry(scene.wallet_text() == "1,234", "Vi hien dung dinh dang 1,234 (nhan '%s')" % scene.wallet_text())

	# Tab BÚT & MỰC: lưới 2 cột, 6 món/trang, 10 món -> 2 trang
	_entry(scene.current_tab() == "pen", "Tab mac dinh = BÚT & MỰC")
	_entry(scene.item_count() == 6, "Trang 1 co 6 the mon hang (nhan %d)" % scene.item_count())
	_entry(scene.page_count() == 2, "10 mon but -> 2 trang (nhan %d)" % scene.page_count())
	_entry(scene.items_per_page() == 6, "items_per_page() = 6")
	var first_id := scene.item_id_at(0)
	# Thẻ ô dựng đúng mockup: 475×315, có vòng icon + nét mực + nút 200×46
	var tile := scene.card_at(0)
	_entry(tile != null and tile.size == Vector2(475, 315),
		"The o dung co 475x315 (nhan %s)" % str(tile.size if tile != null else Vector2.ZERO))
	if tile != null:
		_entry(tile.get_node_or_null("IconCircle") is TextureRect, "The o co vong icon (IconCircle)")
		_entry(tile.get_node_or_null("Stroke") is TextureRect, "The o co net muc ve thu (Stroke)")
		_entry(tile.get_node_or_null("BadgeLabel") is Label, "The o co nhan goc (Badge)")
		var action := tile.get_node_or_null("Action") as TextureButton
		_entry(action != null and action.size == Vector2(200, 46),
			"Nut the o dung 200x46 (nhan %s)" % str(action.size if action != null else Vector2.ZERO))
		# BÚT & MỰC: thẻ hiện đúng icon CON TRỎ trong game của chính ngòi bút đó
		var first_icon := tile.get_node_or_null("Icon") as TextureRect
		_entry(first_icon != null and first_icon.texture == PenSkin.cursor_texture(first_id),
			"The but dau tien dung icon con tro cua chinh no (%s)" % first_id)

	# Bàn nháp thử bút (mockup/shopping_pencil.svg): có ở tab BÚT & MỰC, nằm TRÊN lưới
	var pad: Control = scene.doodle_pad()
	_entry(pad != null, "Tab BUT & MUC co Ban nhap thu but")
	if pad != null:
		_entry(scene.get_node("Content/List").get_child(0) == pad,
			"Ban nhap nam TREN luoi mon hang")
		_entry(pad.size.x >= 960.0 and absf(pad.size.y - 215.0) < 2.0,
			"Ban nhap dung co 980x215 (nhan %s)" % str(pad.size))
		_entry(str(pad.call("pen_id")) == Shop.equipped_pen(),
			"Ban nhap mo dau voi but dang dung (%s)" % str(pad.call("pen_id")))
		_entry(str(pad.call("stamp_text")) == TranslationServer.translate("STR_SHOP_TRY_USING"),
			"Con dau bao DANG DUNG voi but dang dung (nhan '%s')" % str(pad.call("stamp_text")))
		_entry(int(pad.call("stroke_count")) >= 1, "Ban nhap ve san NET MAU de thay chat lieu")
		var badge_icon := pad.get_node_or_null("Badge/Icon") as TextureRect
		_entry(badge_icon != null
				and badge_icon.texture == PenSkin.cursor_texture(str(pad.call("pen_id"))),
			"The DANG XEM THU hien icon con tro cua but")
		# Vẽ thử bằng code: nét phải dùng đúng MÀU MỰC + CHẤT LIỆU của ngòi đang xem
		var probe: InkStroke = pad.call("draw_test_stroke",
			PackedVector2Array([Vector2(20, 30), Vector2(140, 60), Vector2(260, 40)]))
		_entry(probe != null and probe.default_color.is_equal_approx(
				PenSkin.line_color(str(pad.call("pen_id")))), "Net ve thu dung MAU MUC cua but")
		# Chạm thẻ bút khác -> bàn nháp đổi ngòi + nét đổi màu + con dấu đổi trạng thái
		scene.select_pen_for_preview("pen_purple")
		_entry(str(pad.call("pen_id")) == "pen_purple",
			"Cham the but -> ban nhap doi ngòi (nhan '%s')" % str(pad.call("pen_id")))
		_entry(scene.preview_pen_id() == "pen_purple", "Shop nho ngòi đang xem thử")
		_entry(str(pad.call("stamp_text")) == TranslationServer.translate("STR_SHOP_TRY_STAMP"),
			"Ngòi chưa dùng -> con dau DUNG THU (nhan '%s')" % str(pad.call("stamp_text")))
		var purple_stroke: InkStroke = pad.call("draw_test_stroke",
			PackedVector2Array([Vector2(10, 20), Vector2(120, 80)]))
		_entry(purple_stroke != null and purple_stroke.default_color.is_equal_approx(
				PenSkin.line_color("pen_purple")), "Net ve thu doi mau theo ngòi mới")
		# Vùng bàn nháp chặn cuộn trang để người chơi VẼ THỬ
		_entry(bool(pad.call("blocks_scroll_at", pad.get_global_rect().get_center())),
			"Vung ban nhap chan cuon/vuot trang (de ve thu)")
		_entry(not bool(pad.call("blocks_scroll_at", Vector2(-40, -40))),
			"Ngoai ban nhap van cuon binh thuong")
		# Tab khác không có bàn nháp; quay lại thì nhớ ngòi đang xem thử
		scene.show_tab("theme")
		await process_frame
		_entry(scene.doodle_pad() == null, "Tab GIAY VO khong co ban nhap thu but")
		scene.show_tab("pen")
		await process_frame
		var pad_back: Control = scene.doodle_pad()
		_entry(pad_back != null and str(pad_back.call("pen_id")) == "pen_purple",
			"Quay lai tab BUT & MUC nho ngòi đang xem thử")
	scene.goto_page(1)
	await process_frame
	_entry(scene.item_count() == 4, "Trang 2 con 4 mon (nhan %d)" % scene.item_count())
	_entry(scene.item_id_at(0) != first_id, "Sang trang thi doi danh sach mon")
	_entry(scene.current_page() == 1, "current_page() = 1")

	# Tab DỤNG CỤ: danh sách thẻ ngang, không phân trang
	scene.show_tab("tool")
	await process_frame
	_entry(scene.current_tab() == "tool", "Doi sang tab DUNG CU")
	_entry(scene.doodle_pad() == null, "Tab DUNG CU khong co ban nhap thu but")
	_entry(scene.item_count() == 6, "Tab dung cu hien 6 mon (nhan %d)" % scene.item_count())
	_entry(scene.page_count() == 1, "Tab dung cu khong phan trang")
	_entry(not scene.get_node("Pager").visible, "An thanh phan trang khi 1 trang")

	# Tab NẠP XU: hàng VIP no-ads TRÊN CÙNG (1 hàng) + lưới 2 cột các gói Xu
	scene.show_tab("coin")
	await process_frame
	_entry(scene.item_count() == 6, "Tab nap xu hien 6 the (nhan %d)" % scene.item_count())
	_entry(scene.page_count() == 1, "Tab nap xu khong phan trang")
	var noads := scene.card_at(0)
	_entry(noads != null and noads.get_script() == preload("res://scripts/nodes/shop/noads_row.gd"),
		"The dau tien la hang VIP xoa quang cao (ShopNoadsRow)")
	if noads != null:
		_entry(str(noads.get("item_id")) == "coin_no_ads", "Hang dau la coin_no_ads")
		_entry(noads.size == Vector2(980, 200), "Hang VIP cao 200 va rong 980 (bao trum 1 hang)")
	var pack_tile := scene.card_at(1)
	_entry(pack_tile != null and pack_tile.get_script() == preload("res://scripts/nodes/shop/coin_tile.gd"),
		"Cac the sau la goi nap (ShopCoinTile)")
	if pack_tile != null:
		_entry(str(pack_tile.get("item_id")) == "coin_500", "The goi dau tien la coin_500")
		_entry(pack_tile.size == Vector2(475, 240), "The goi nap dung 475x240 (nhan %s)" % str(pack_tile.size))
		var icon: Texture2D = pack_tile.call("icon_texture")
		_entry(icon != null and icon.resource_path.ends_with("icon_coin_t1.svg"),
			"Goi 500 Xu dung icon cap 1 (%s)" % str(icon.resource_path if icon != null else ""))
	var pack2 := scene.card_at(2)
	if pack2 != null:
		var icon2: Texture2D = pack2.call("icon_texture")
		_entry(str(pack2.get("item_id")) == "coin_2000", "The goi thu hai la coin_2000")
		_entry(icon2 != null and icon2.resource_path.ends_with("icon_coin_t2.svg"),
			"Goi 2,000 Xu dung icon cap 2 (%s)" % str(icon2.resource_path if icon2 != null else ""))
	var last_tile := scene.card_at(5)
	if last_tile != null:
		var icon5: Texture2D = last_tile.call("icon_texture")
		_entry(icon5 != null and icon5.resource_path.ends_with("icon_coin_t5.svg"),
			"Goi 20,000 Xu dung icon cap 5 (ruong vang)")

	# Mua thật qua nút trên thẻ: mua gói 500 Xu rồi ví phải tăng
	if pack_tile != null:
		var before_coins := int(shop.call("coins"))
		(pack_tile.get_node("Action") as TextureButton).pressed.emit()
		await process_frame
		await process_frame
		_entry(int(shop.call("coins")) == before_coins + 500,
			"Bam nut the -> nap dung 500 Xu (vi = %d)" % int(shop.call("coins")))
		_entry(scene.wallet_text() == "%s" % Shop.thousands(before_coins + 500),
			"Vi tren man cap nhat theo (%s)" % scene.wallet_text())
	scene.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# 7. Vuốt ngang đổi trang · vuốt dọc cuộn danh sách (sửa lỗi không cuộn được)
# ---------------------------------------------------------------------------
func _section_7_gestures(shop: Node, wallet: Node) -> void:
	print("[7] Vuot / cuon...")
	shop.call("reset_progress")
	wallet.set("coins", 2000)
	var scene: ShopScene = (load(SCENE_PATH) as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	# Vuốt NGANG sang trái -> sang trang sau
	scene.show_tab("pen")
	await process_frame
	_entry(scene.current_page() == 0, "Bat dau o trang 1")
	_entry(not scene.clicks_locked(), "Chua vuot thi chua khoa bam nut")
	scene.call("_begin_drag", Vector2(700, 800))
	scene.call("_update_drag", Vector2(300, 806))
	scene.call("_end_drag")
	await process_frame
	_entry(scene.current_page() == 1, "Vuot ngang sang trai -> sang trang 2 (nhan %d)" % scene.current_page())
	_entry(scene.clicks_locked(), "Sau khi vuot thi KHOA bam nut (tranh mua nham)")

	# Đang bị khoá thì bấm thẻ/nút không ăn
	var before_coins := int(shop.call("coins"))
	scene.call("_on_item_action", "pen_green_tea")
	await process_frame
	_entry(int(shop.call("coins")) == before_coins, "Dang khoa bam -> bam the KHONG mua")

	# Hết thời gian khoá -> nút mũi tên lại hoạt động
	scene.set("_click_lock_until", 0.0)
	_entry(not scene.clicks_locked(), "Het thoi gian khoa -> mo khoa lai")
	(scene.get_node("Pager/Prev") as TextureButton).pressed.emit()
	await process_frame
	_entry(scene.current_page() == 0, "Nut lui trang chay lai binh thuong")

	# Vuốt NGANG sang phải khi đang ở trang 1 -> không vượt biên
	scene.call("_begin_drag", Vector2(300, 800))
	scene.call("_update_drag", Vector2(700, 800))
	scene.call("_end_drag")
	await process_frame
	_entry(scene.current_page() == 0, "Vuot nguoc khi dang o trang 1 -> dung yen")

	# Vuốt DỌC -> cuộn danh sách (tab DỤNG CỤ dài hơn khung nhìn)
	scene.set("_click_lock_until", 0.0)
	scene.show_tab("tool")
	await process_frame
	await process_frame
	var content := scene.get_node("Content") as ScrollContainer
	_entry(content != null and content.get_v_scroll_bar().max_value > content.size.y,
		"Danh sach dung cu dai hon khung nhin (max %.0f > %.0f)" % [
			content.get_v_scroll_bar().max_value if content != null else 0.0,
			content.size.y if content != null else 0.0])
	_entry(content.scroll_vertical == 0, "Dau danh sach o vi tri 0")
	scene.call("_begin_drag", Vector2(540, 1100))
	scene.call("_update_drag", Vector2(540, 700))
	scene.call("_end_drag")
	await process_frame
	_entry(content.scroll_vertical > 0,
		"Vuot doc -> cuon duoc danh sach (scroll_vertical = %d)" % content.scroll_vertical)

	# Kéo dọc nhưng chưa qua ngưỡng -> coi như bấm thường (không khoá)
	scene.set("_click_lock_until", 0.0)
	content.scroll_vertical = 0
	scene.call("_begin_drag", Vector2(540, 900))
	scene.call("_update_drag", Vector2(540, 905))
	scene.call("_end_drag")
	_entry(not scene.clicks_locked(), "Keo rat ngan -> khong tinh la vuot, khong khoa bam")
	_entry(content.scroll_vertical == 0, "Keo rat ngan -> khong cuon")

	scene.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# 8. Nối dây điều hướng
# ---------------------------------------------------------------------------
func _section_8_wiring() -> void:
	print("[8] Noi day dieu huong...")
	_entry(Nav.SCENE_SHOP == SCENE_PATH, "Nav.SCENE_SHOP tro dung scenes/shop.tscn")
	var nav_src := FileAccess.get_file_as_string("res://scripts/utils/nav.gd")
	_entry(nav_src.contains("func goto_shop"), "Nav co ham goto_shop()")
	var sm: Node = root.get_node_or_null("SceneManager")
	if sm != null:
		_entry(sm.get_script().get_script_constant_map().get("SCENE_SHOP", "") == SCENE_PATH,
			"SceneManager.SCENE_SHOP tro dung scenes/shop.tscn")
		_entry(sm.has_method("goto_shop"), "SceneManager co goto_shop()")
	var main_src := FileAccess.get_file_as_string("res://scripts/scenes/main.gd")
	_entry(main_src.contains("_on_shop_pressed") and main_src.contains("Nav.goto_shop()"),
		"Nut CUA HANG o Main mo man Cua hang")
	var debug_src := FileAccess.get_file_as_string("res://scripts/scenes/debug.gd")
	_entry(debug_src.contains("scenes/shop.tscn"), "Debug Console co muc mo Cua hang")
	var save_src := FileAccess.get_file_as_string("res://scripts/manager/SaveManager.gd")
	_entry(save_src.contains("ShopManager"), "ShopManager da dang ky luu vao save")


# ---------------------------------------------------------------------------
# Harness
# ---------------------------------------------------------------------------
func _entry(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("  [PASS] %s" % label)
	else:
		_failed += 1
		print("  [FAIL] %s" % label)
