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
	assert(_has(splash_inst, "Panel/LogoContainer/Pencil"), "Splash phai co Panel/LogoContainer/Pencil")
	assert(_has(splash_inst, "Panel/Title"), "Splash phai co Panel/Title")
	assert(_has(splash_inst, "Panel/Tagline"), "Splash phai co Panel/Tagline")
	assert(_has(splash_inst, "Panel/Stamp"), "Splash phai co Panel/Stamp")
	assert(_has(splash_inst, "FadeOverlay"), "Splash phai co FadeOverlay")
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
	assert(_has(shop_inst, "TopBar/Wallet"), "Shop phai co Wallet (nam trong TopBar)")
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
	assert(_has(chapters_inst, "TopBar/Wallet"), "Chapters phai co Wallet (nam trong TopBar)")
	assert(_has(chapters_inst, "Banner"), "Chapters phai co Banner")
	assert(_has(chapters_inst, "ContinueButton"), "Chapters phai co ContinueButton")
	print("[CHECK] ChaptersScene load va khoi chay cac animation thanh cong.")

	chapters_inst.queue_free()
	await process_frame

	print("\n========================================================")
	print("  TAT CA TEST SPLASH, TITLE, SHOP, CREDIT, CHAPTERS DEU PASS!")
	print("========================================================\n")
	quit(0)
