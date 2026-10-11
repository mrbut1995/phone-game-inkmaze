extends SceneTree
## ============================================================================
## Test: Layout màn hình chính (Main Screen) — bố cục mới (§A)
##   · Thanh trên: Hồ sơ · Xu · Sao · Cài đặt
##   · Khối Sự kiện: header + carousel (Daily ghim đầu, KHÔNG còn thẻ Daily riêng)
##   · 2 thẻ chế độ: Play · Dungeon (ModeCard thẻ giấy)
##   · Dock 4 nút: Cửa hàng · Xếp hạng · Danh hiệu · Luật chơi
## ============================================================================

func _init() -> void:
	print("\n========================================================")
	print("  TEST: MAIN SCENE (bo cuc moi)")
	print("========================================================\n")

	root.size = Vector2i(1080, 1920)
	await process_frame

	var main_packed: PackedScene = load("res://scenes/main.tscn")
	var main_scene: MainScene = main_packed.instantiate()
	root.add_child(main_scene)
	for i in 25:
		await process_frame

	var portrait := main_scene.get_node_or_null("Portrait") as Control
	var landscape := main_scene.get_node_or_null("Landscape") as Control
	assert(portrait != null, "Phai co layout Portrait")
	assert(landscape != null, "Phai co layout Landscape")
	assert(not landscape.visible, "Man hinh DOC thi layout ngang phai an")

	# 1. Thanh trên — hồ sơ / xu / sao / cài đặt, xếp trái→phải
	var profile_card := main_scene.layout.profile_card
	var coin_chip := main_scene.layout.coin_chip
	var star_chip := main_scene.layout.star_chip
	var btn_settings := main_scene.layout.btn_settings
	assert(profile_card != null and coin_chip != null and star_chip != null and btn_settings != null,
		"Thanh tren phai co du Ho so · Xu · Sao · Cai dat")
	assert(profile_card.global_position.x < coin_chip.global_position.x,
		"Ho so phai nam ben trai vi Xu")
	assert(coin_chip.global_position.x < star_chip.global_position.x,
		"Vi Xu phai nam ben trai o Sao")
	assert(star_chip.global_position.x < btn_settings.global_position.x,
		"Nut Cai dat phai nam ben phai cung thanh tren")
	assert(profile_card.size.x >= 120.0, "The ho so phai du rong (%.0f)" % profile_card.size.x)

	# 2. Khối sự kiện — header TRÊN carousel
	var header: Node = main_scene.layout.event_header
	var carousel: Node = main_scene.layout.event_carousel
	assert(header != null, "Phai co EventHeader")
	assert(carousel != null, "Phai co EventCarousel")
	assert(header.global_position.y < carousel.global_position.y,
		"Tieu de khoi su kien phai nam TREN carousel")

	# 3. 2 thẻ chế độ — Play TRÊN Dungeon, đủ cấu trúc ModeCard
	var card_play: ModeCard = main_scene.layout.card_play
	var card_dungeon: ModeCard = main_scene.layout.card_dungeon
	assert(card_play != null and card_dungeon != null, "Phai co 2 the che do Play + Dungeon")
	assert(card_play.global_position.y < card_dungeon.global_position.y,
		"The Play phai nam TREN the Dungeon")
	for card in [card_play, card_dungeon]:
		assert(card.get_node_or_null("Content/IconBox/Icon") != null, "ModeCard phai co Icon")
		assert(card.get_node_or_null("Content/Texts/Title") != null, "ModeCard phai co Title")
		assert(card.get_node_or_null("Content/Right/StatValue") != null, "ModeCard phai co StatValue")
		assert(card.get_node_or_null("Content/Right/ActionButton") != null, "ModeCard phai co ActionButton")
		assert(card.size.x > 0.0 and card.size.y > 0.0, "ModeCard phai co kich thuoc")
		assert(card.card_pressed.get_connections().size() > 0, "ModeCard phai noi card_pressed")

	# 4. Dock 4 nút — đều nhau, đủ rộng
	var dock: Node = main_scene.ui("Dock")
	assert(dock != null, "Phai co Dock duoi cung")
	assert(dock.get_child_count() == 4, "Dock phai co dung 4 nut, dang %d" % dock.get_child_count())
	var names := ["DockShop", "DockRanking", "DockBadges", "DockRules"]
	for i in names.size():
		var btn := dock.get_node_or_null(names[i]) as Control
		assert(btn != null, "Dock phai co nut %s" % names[i])
		assert(btn.size.x > 40.0 and btn.size.y > 40.0, "Nut %s phai co kich thuoc" % names[i])
		var label := btn.get_node_or_null("Label") as Label
		assert(label != null and not label.text.is_empty(), "Nut %s phai co nhan chu" % names[i])

	# 5. Bỏ các thành phần cũ (tờ giấy, hàng nút Other, thẻ Daily riêng)
	assert(main_scene.ui("Paper") == null, "KHONG con to giay Paper")
	assert(main_scene.ui("Other") == null, "KHONG con hang nut Other")
	assert(main_scene.ui("DailyMission") == null, "KHONG con the Daily rieng")
	assert(main_scene.ui("GameMode") == null, "KHONG con khoi GameMode cu")
	assert(main_scene.ui("Archivement") == null, "KHONG con nut Danh hieu lon cu")

	# 6. Thẻ sự kiện có đúng cấu trúc con + dùng node khai sẵn
	var card_node: Node = main_scene.ui("EventCard")
	assert(card_node != null, "Carousel phai instantiate it nhat 1 EventCard")
	if card_node != null:
		for child in ["BgGradient", "BackArt", "ThemeChip", "TimerChip", "ProgressPanel", "CtaButton"]:
			assert(card_node.get_node_or_null(child) != null, "EventCard phai co node %s" % child)

	print("\n[SUCCESS] Bo cuc Main Screen moi dung: thanh tren · su kien · 2 the che do · dock 4 nut.\n")
	main_scene.queue_free()
	await process_frame
	quit(0)
