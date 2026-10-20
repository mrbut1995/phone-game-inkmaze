extends SceneTree
## ============================================================================
## Test: Kiểm tra Splash, Title, Shop, Credit, Chapters & music wiring
## ============================================================================

## Màn đã tách 2 layout ⇒ node nằm trong layout đang hiển thị (dọc/ngang)
func _has(scene: Node, path: String) -> bool:
	return scene.call("ui_path", path) != null


func _init() -> void:
	print("\n========================================================")
	print("  TEST: SPLASH, TITLE, SHOP, CREDIT, CHAPTERS + MUSIC")
	print("========================================================\n")

	await process_frame
	var music := root.get_node_or_null("MusicManager")
	assert(music != null, "Autoload MusicManager phai ton tai")
	if music != null:
		assert(music.has_method("current_track_path"), "MusicManager phai co API current_track_path")
		music.call("set_context", "credits", true)
		await process_frame
		assert(str(music.call("context_name")) == "credits",
			"MusicManager phai doi context credits khi duoc yeu cau")
		var track_path := str(music.call("current_track_path"))
		assert(track_path.ends_with("Wallpaper.mp3"),
			"Credit context phai dung soundtrack Wallpaper (nhan '%s')" % track_path)
		music.call("set_context", "menu", false)

	# 1. Test Splash Scene
	var splash_packed: PackedScene = load("res://scenes/splash.tscn")
	assert(splash_packed != null, "scenes/splash.tscn phai load duoc")
	var splash_inst = splash_packed.instantiate()
	assert(splash_inst != null, "scenes/splash.tscn phai instantiate duoc")
	root.add_child(splash_inst)
	await process_frame
	await process_frame

	assert(_has(splash_inst, "Panel/LogoContainer/Logo"), "Splash phai co Panel/LogoContainer/Logo")
	assert(_has(splash_inst, "Panel/Title"), "Splash phai co Panel/Title")
	assert(_has(splash_inst, "FadeOverlay"), "Splash phai co FadeOverlay")
	# Node riêng của bố cục — kiểm tra TRỰC TIẾP trên layout (không phụ thuộc hướng màn hình
	# đang bật, vốn thay đổi theo môi trường chạy test).
	var splash_portrait := splash_inst.get_node_or_null("Portrait")
	assert(splash_portrait != null, "Splash phai co bo cuc Portrait")
	## Splash moi (10/2026): bo Tagline/HintTap/Stamp
	assert(splash_portrait.get_node_or_null("Panel/Tagline") == null,
		"Splash moi khong con Panel/Tagline")
	assert(splash_portrait.get_node_or_null("Panel/Stamp") == null,
		"Splash khong con Panel/Stamp")

	# Thanh tiến trình nạp — do autoload LoadingManager điều khiển (xem §13.26)
	var loading_manager: Node = root.get_node_or_null("LoadingManager")
	assert(loading_manager != null, "Autoload LoadingManager phai ton tai")
	if loading_manager != null:
		assert(loading_manager.has_method("add_step") and loading_manager.has_method("progress"),
			"LoadingManager phai co add_step/progress/is_loading_done")
		assert(loading_manager.has_method("is_loading_done") and bool(loading_manager.call("is_loading_done")),
			"Headless: LoadingManager phai nap xong ngay trong _ready")
		assert(int(loading_manager.call("pending_steps")) == 0,
			"Headless: khong con buoc nap nao treo")
		assert(is_equal_approx(float(loading_manager.call("progress")), 1.0),
			"Headless: tien do nap = 1.0")
		var preloaded: Array = loading_manager.get("_preloaded")
		assert(preloaded.size() > 0, "LoadingManager phai nap san scene cho man ke tiep")
	for side in [splash_portrait]:
		assert(side.get_node_or_null("Panel/LoadingBox/LoadingBar") != null,
			"Splash phai co thanh tien trinh nap (Panel/LoadingBox/LoadingBar)")
		assert(side.get_node_or_null("Panel/LoadingBox/LoadingLabel") != null,
			"Splash phai co nhan tien trinh nap")
	var splash_layout: SplashLayout = splash_inst.layout as SplashLayout
	assert(splash_layout != null, "SplashScene phai bind duoc SplashLayout")
	if splash_layout != null:
		assert(splash_layout.loading_bar != null and splash_layout.loading_label != null,
			"SplashLayout phai bind loading_bar/loading_label bang @export")
		if splash_layout.loading_bar != null:
			assert(is_equal_approx(splash_layout.loading_bar.value, 1.0),
				"Nap xong thi thanh tien trinh o 100%% (dang %.2f)" % splash_layout.loading_bar.value)
		if splash_layout.loading_label != null:
			assert(not splash_layout.loading_label.text.begins_with("STR_"),
				"Nhan tien trinh hien chu da dich, khong lo khoa tho ('%s')" % splash_layout.loading_label.text)
	print("[CHECK] SplashScene load va chua day du cac node giao dien truc quan.")

	splash_inst.queue_free()
	await process_frame

	# 2. Test Title Scene
	var title_packed: PackedScene = load("res://scenes/title.tscn")
	assert(title_packed != null, "scenes/title.tscn phai load duoc")
	var title_inst = title_packed.instantiate()
	assert(title_inst != null, "scenes/title.tscn phai instantiate duoc")
	root.add_child(title_inst)
	await process_frame
	await process_frame

	assert(_has(title_inst, "Panel/LogoContainer/Logo"), "Title phai co Panel/LogoContainer/Logo")
	assert(_has(title_inst, "Panel/LogoContainer/Pencil"), "Title phai co Panel/LogoContainer/Pencil")
	assert(_has(title_inst, "Panel/Title"), "Title phai co Panel/Title")
	assert(_has(title_inst, "Panel/Subtitle"), "Title phai co Panel/Subtitle")
	assert(_has(title_inst, "Panel/TapContainer/TapLabel"), "Title phai co Panel/TapContainer/TapLabel")
	assert(_has(title_inst, "Panel/TapContainer/PlayIcon"), "Title phai co Panel/TapContainer/PlayIcon")
	assert(_has(title_inst, "Panel/Stamp"), "Title phai co Panel/Stamp")
	assert(_has(title_inst, "FadeOverlay"), "Title phai co FadeOverlay")
	print("[CHECK] TitleScene load va chua day du cac node giao dien truc quan.")

	title_inst.queue_free()
	await process_frame

	# 3. Test Shop Scene
	var shop_packed: PackedScene = load("res://scenes/shop.tscn")
	assert(shop_packed != null, "scenes/shop.tscn phai load duoc")
	var shop_inst = shop_packed.instantiate()
	assert(shop_inst != null, "scenes/shop.tscn phai instantiate duoc")
	root.add_child(shop_inst)
	await process_frame
	await process_frame

	assert(_has(shop_inst, "TopBar"), "Shop phai co TopBar")
	assert(_has(shop_inst, "TopBar/HeaderRow/CoinChip"), "Shop phai dung CoinChip dung chung (nam trong TopBar)")
	assert(_has(shop_inst, "Tabs"), "Shop phai co Tabs")
	assert(_has(shop_inst, "GiftBanner"), "Shop phai co GiftBanner")
	print("[CHECK] ShopScene load va khoi chay cac animation thanh cong.")

	shop_inst.queue_free()
	await process_frame

	# 4. Test Credit Scene
	var credit_packed: PackedScene = load("res://scenes/credit.tscn")
	assert(credit_packed != null, "scenes/credit.tscn phai load duoc")
	var credit_inst = credit_packed.instantiate()
	assert(credit_inst != null, "scenes/credit.tscn phai instantiate duoc")
	root.add_child(credit_inst)
	await process_frame
	await process_frame

	assert(_has(credit_inst, "TopBar/Back"), "Credit phai co nut Back")
	assert(_has(credit_inst, "Panel/Content/VBox/MusicSection/ThemeRow/Value"),
		"Credit phai hien theme dang dung")
	assert(_has(credit_inst, "Panel/Content/VBox/MusicSection/TrackRow/Value"),
		"Credit phai hien track dang phat")
	assert(_has(credit_inst, "Panel/Content/VBox/Footer/Stamp/VersionLabel"),
		"Credit phai co con dau version")
	print("[CHECK] CreditScene load va co day du thong tin soundtrack/attribution.")

	credit_inst.queue_free()
	await process_frame

	# 5. Test Chapters Scene
	var chapters_packed: PackedScene = load("res://scenes/chapters.tscn")
	assert(chapters_packed != null, "scenes/chapters.tscn phai load duoc")
	var chapters_inst = chapters_packed.instantiate()
	assert(chapters_inst != null, "scenes/chapters.tscn phai instantiate duoc")
	root.add_child(chapters_inst)
	await process_frame
	await process_frame

	assert(_has(chapters_inst, "TopBar"), "Chapters phai co TopBar")
	assert(_has(chapters_inst, "TopBar/Wallet"), "Chapters phai co Wallet Sao (nam trong TopBar)")
	assert(_has(chapters_inst, "TopBar/CoinChip"), "Chapters phai co CoinChip dung chung")
	assert(_has(chapters_inst, "Banner"), "Chapters phai co Banner")
	assert(_has(chapters_inst, "ContinueButton"), "Chapters phai co ContinueButton")
	print("[CHECK] ChaptersScene load va khoi chay cac animation thanh cong.")

	chapters_inst.queue_free()
	await process_frame

	print("\n========================================================")
	print("  TAT CA TEST SPLASH, TITLE, SHOP, CREDIT, CHAPTERS DEU PASS!")
	print("========================================================\n")
	quit(0)
