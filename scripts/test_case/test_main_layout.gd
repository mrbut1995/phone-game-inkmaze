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
	var life_chip := portrait.get_node_or_null("TopBar/LifeChip") as Control
	assert(profile_card != null and coin_chip != null and star_chip != null and btn_settings != null,
		"Thanh tren phai co du Ho so · Xu · Sao · Cai dat")
	assert(profile_card.global_position.x < coin_chip.global_position.x,
		"Ho so phai nam ben trai vi Xu")
	# v2.40: mọi node của thanh trên nằm TRỰC TIẾP trong `TopBar` (không còn `HeaderRow`), thứ tự
	# đúng như thiết kế cũ: Hồ sơ → Xu → Lượt chơi → Sao → Cài đặt.
	assert(portrait.get_node_or_null("TopBar/HeaderRow") == null,
		"Thanh tren KHONG con node boc HeaderRow")
	assert(coin_chip.get_index() < star_chip.get_index(), "Vi Xu phai dung TRUOC o Sao")
	assert(life_chip != null and coin_chip.get_index() < life_chip.get_index(),
		"LifeChip phai nam ben phai CoinChip")
	assert(life_chip != null and life_chip.get_index() < star_chip.get_index(),
		"LifeChip phai dung TRUOC o Sao")
	assert(star_chip.get_index() < btn_settings.get_index(),
		"Nut Cai dat phai la o CUOI thanh tren")
	assert(life_chip != null and life_chip.global_position.x < btn_settings.global_position.x,
		"Hai chip phai nam ben trai nut Cai dat")
	assert(profile_card.size.x >= 120.0, "The ho so phai du rong (%.0f)" % profile_card.size.x)

	# 2. Khối sự kiện — header TRÊN carousel
	var header: Node = main_scene.layout.event_header
	var carousel: Node = main_scene.layout.event_carousel
	assert(header != null, "Phai co EventHeader")
	assert(carousel != null, "Phai co EventCarousel")
	assert(header.global_position.y < carousel.global_position.y,
		"Tieu de khoi su kien phai nam TREN carousel")
	var preview_carousel := carousel as EventCarousel
	assert(preview_carousel != null and preview_carousel.show_all_events_for_preview,
		"Main bat che do xem thu tat ca EventData")
	if preview_carousel != null:
		var em := root.get_node_or_null("EventManager")
		var expected_event_count := (em.call("get_all_events_for_preview") as Array).size() if em != null else 0
		assert(preview_carousel.get_displayed_event_count() == expected_event_count,
			"Carousel hien thi du %d EventData" % expected_event_count)
		var badge_label := header.get_node_or_null("Badge/CountLabel") as Label
		assert(badge_label != null and badge_label.text == str(expected_event_count),
			"Badge dem dung so EventData dang hien")
		var daily_first := carousel.get_node_or_null("ScrollContainer/HBox/DailyCard") as Control
		assert(daily_first is DailyCard, "The DAILY dung lop DailyCard (tach khoi EventCard)")
		assert(daily_first != null and daily_first.get_node_or_null("Content/Text/DailyDate") != null,
			"DailyCard co la lich (Content/Text/DailyDate)")
		var first_event_card := carousel.get_node_or_null("ScrollContainer/HBox/EventCard") as Control
		assert(first_event_card != null, "Carousel co the event de kiem tra thu tu lop")
		assert(first_event_card is EventCard, "The su kien that dung lop EventCard")
		assert(first_event_card.get_node_or_null("Content/Text/DailyDate") == null,
			"EventCard KHONG con la lich Daily (da tach sang DailyCard)")
		if first_event_card != null:
			var event_background := first_event_card.get_node("Content/Background") as Control
			var event_text := first_event_card.get_node("Content/Text") as Control
			var event_chips := first_event_card.get_node("Content/Chips") as Control
			var event_information := first_event_card.get_node("Content/Information") as Control
			assert(event_text.z_index > event_background.z_index,
				"Title va ngay Daily nam tren lop artwork")
			assert(event_chips.z_index > event_background.z_index,
				"Chip chu nam tren lop artwork")
			assert(event_information.z_index > event_background.z_index,
				"Thong tin tien do va CTA nam tren lop artwork")
			for title_path in ["Content/Text/Title/Title1", "Content/Text/Title/Title2"]:
				var title_label := first_event_card.get_node(title_path) as Label
				assert(title_label.get_theme_constant("outline_size") >= 5,
					"%s co outline de title_outline trong theme resource co hieu luc" % title_path)

	# 3. KH?I B?N ?? (b?n G?P ? m?n Levels ?? g?, b?n ?? n?m ngay trong Main)
	var section: LevelSection = main_scene.layout.level_section
	assert(section != null, "Main phai co LevelSection (ban do man choi)")
	assert(section.map != null, "LevelSection phai bind LevelMap (bang @export)")
	assert(section.map.node_count() > 0, "Ban do phai co nut man")
	assert(section.chapter_chip != null, "LevelSection phai co ChapterChip")
	assert(section.chest != null, "LevelSection phai co ruong moc thuong")
	assert(section.dungeon_pill != null, "LevelSection phai co nut Dungeon noi")
	assert(section.dungeon_pill.pressed.get_connections().size() > 0,
		"Nut Dungeon noi phai noi toi Main")

	# 4. Dock 4 nút — đều nhau, đủ rộng
	var dock: Node = main_scene.ui("Dock")
	assert(dock != null, "Phai co Dock duoi cung")
	# Dock la thanh kem (PanelContainer) chua hang nut Row
	var dock_row: Node = dock.get_node_or_null("Row")
	assert(dock_row != null, "Dock phai la thanh kem chua hang nut Row")
	if dock_row == null:
		dock_row = dock
	assert(dock_row.get_child_count() == 4, "Dock phai co dung 4 nut, dang %d" % dock_row.get_child_count())
	var names := ["DockShop", "DockRanking", "DockBadges", "DockRules"]
	for i in names.size():
		var btn := dock_row.get_node_or_null(names[i]) as Control
		assert(btn != null, "Dock phai co nut %s" % names[i])
		assert(btn.size.x > 40.0 and btn.size.y > 40.0, "Nut %s phai co kich thuoc" % names[i])
		var label := btn.get_node_or_null("Label") as Label
		assert(label != null and not label.text.is_empty(), "Nut %s phai co nhan chu" % names[i])

	# 5. Bỏ các thành phần cũ (tờ giấy, hàng nút Other, thẻ Daily riêng)
	assert(main_scene.ui("Paper") == null, "KHONG con to giay Paper")
	assert(main_scene.ui("Other") == null, "KHONG con hang nut Other")
	assert(main_scene.ui("DailyMission") == null, "KHONG con the Daily rieng")
	assert(main_scene.ui("GameMode") == null, "KHONG con khoi GameMode cu")
	assert(main_scene.ui("Modes") == null, "KHONG con khoi 2 the che do (ModeCard da xoa)")
	assert(main_scene.ui("Archivement") == null, "KHONG con nut Danh hieu lon cu")

	# 6. Thẻ sự kiện có đúng cấu trúc con + dùng node khai sẵn
	var card_node: Node = main_scene.ui("EventCard")
	assert(card_node != null, "Carousel phai instantiate it nhat 1 EventCard")
	assert(card_node is EventCard and not (card_node is DailyCard),
		"EventCard va DailyCard la 2 lop rieng")
	if card_node != null:
		for child in [
			"Content/Background/ContentMask/BgGradient",
			"Content/Background/ContentMask/BackArt",
			"Content/Background/ContentMask/FrontArt",
			"Content/Chips/ThemeChip",
			"Content/Chips/TimerChip",
			"Content/Information/ProgressPanel",
			"Content/Information/CtaButton",
		]:
			assert(card_node.get_node_or_null(child) != null, "EventCard phai co node %s" % child)

	# 7. Thẻ DAILY phải mở THẲNG màn Daily (`scenes/daily.tscn`), KHÔNG qua màn chi tiết Event
	# (Daily là event ẢO: không có file .tres và không có màn chi tiết riêng).
	var daily_card: DailyCard = null
	for child in carousel.get_node("ScrollContainer/HBox").get_children():
		if child is DailyCard:
			daily_card = child as DailyCard
			break
	assert(daily_card != null, "Carousel phai co the Daily (ghim dau)")
	for daily_child in [
		"Content/Background/BackArt",
		"Content/Chips/ThemeChip",
		"Content/Text/DailyDate/Month",
		"Content/Text/DailyDate/Day",
		"Content/Text/DailyDate/Weekday",
		"Content/Stars/Row/Value",
		"Content/CtaButton",
	]:
		assert(daily_card.get_node_or_null(daily_child) != null,
			"DailyCard phai co node %s" % daily_child)
	# Bấm thẻ = phát signal như cú chạm thật (DailyCard -> EventCarousel -> MainScene)
	daily_card.card_pressed.emit(&"daily")
	for i in 3:
		await process_frame
	var scene_manager := root.get_node_or_null("SceneManager")
	var now_path := str(scene_manager.call("current_scene_path")) if scene_manager != null else ""
	assert(now_path == "res://scenes/daily.tscn",
		"Bam the Daily phai mo scenes/daily.tscn (dang '%s')" % now_path)

	print("\n[SUCCESS] Bo cuc Main Screen moi dung: thanh tren · su kien · 2 the che do · dock 4 nut.\n")
	main_scene.queue_free()
	await process_frame
	quit(0)
