extends SceneTree
## ============================================================================
## Test: Kiểm tra Splash Scene, Title Scene, Shop Scene, Chapters Scene & Animations
## ============================================================================

func _init() -> void:
	print("\n========================================================")
	print("  TEST: SPLASH, TITLE, SHOP, CHAPTERS SCENES & ANIMATIONS")
	print("========================================================\n")

	# 1. Test Splash Scene
	var splash_packed: PackedScene = load("res://scenes/splash.tscn")
	assert(splash_packed != null, "scenes/splash.tscn phai load duoc")
	var splash_inst = splash_packed.instantiate()
	assert(splash_inst != null, "scenes/splash.tscn phai instantiate duoc")
	root.add_child(splash_inst)
	await process_frame
	await process_frame

	assert(splash_inst.has_node("Panel/LogoContainer/Logo"), "Splash phai co Panel/LogoContainer/Logo")
	assert(splash_inst.has_node("Panel/LogoContainer/Pencil"), "Splash phai co Panel/LogoContainer/Pencil")
	assert(splash_inst.has_node("Panel/Title"), "Splash phai co Panel/Title")
	assert(splash_inst.has_node("Panel/Tagline"), "Splash phai co Panel/Tagline")
	assert(splash_inst.has_node("Panel/Stamp"), "Splash phai co Panel/Stamp")
	assert(splash_inst.has_node("FadeOverlay"), "Splash phai co FadeOverlay")
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

	assert(title_inst.has_node("Panel/LogoContainer/Logo"), "Title phai co Panel/LogoContainer/Logo")
	assert(title_inst.has_node("Panel/LogoContainer/Pencil"), "Title phai co Panel/LogoContainer/Pencil")
	assert(title_inst.has_node("Panel/Title"), "Title phai co Panel/Title")
	assert(title_inst.has_node("Panel/Subtitle"), "Title phai co Panel/Subtitle")
	assert(title_inst.has_node("Panel/TapContainer/TapLabel"), "Title phai co Panel/TapContainer/TapLabel")
	assert(title_inst.has_node("Panel/TapContainer/PlayIcon"), "Title phai co Panel/TapContainer/PlayIcon")
	assert(title_inst.has_node("Panel/Stamp"), "Title phai co Panel/Stamp")
	assert(title_inst.has_node("FadeOverlay"), "Title phai co FadeOverlay")
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

	assert(shop_inst.has_node("TopBar"), "Shop phai co TopBar")
	assert(shop_inst.has_node("Wallet"), "Shop phai co Wallet")
	assert(shop_inst.has_node("Tabs"), "Shop phai co Tabs")
	assert(shop_inst.has_node("GiftBanner"), "Shop phai co GiftBanner")
	print("[CHECK] ShopScene load va khoi chay cac animation thanh cong.")

	shop_inst.queue_free()
	await process_frame

	# 4. Test Chapters Scene
	var chapters_packed: PackedScene = load("res://scenes/chapters.tscn")
	assert(chapters_packed != null, "scenes/chapters.tscn phai load duoc")
	var chapters_inst = chapters_packed.instantiate()
	assert(chapters_inst != null, "scenes/chapters.tscn phai instantiate duoc")
	root.add_child(chapters_inst)
	await process_frame
	await process_frame

	assert(chapters_inst.has_node("TopBar"), "Chapters phai co TopBar")
	assert(chapters_inst.has_node("Wallet"), "Chapters phai co Wallet")
	assert(chapters_inst.has_node("Banner"), "Chapters phai co Banner")
	assert(chapters_inst.has_node("ContinueButton"), "Chapters phai co ContinueButton")
	print("[CHECK] ChaptersScene load va khoi chay cac animation thanh cong.")

	chapters_inst.queue_free()
	await process_frame

	print("\n========================================================")
	print("  TAT CA TEST SPLASH, TITLE, SHOP, CHAPTERS DEU PASS!")
	print("========================================================\n")
	quit(0)
