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

	# 2. Khối sự kiện — Main bản GỘP bỏ hẳn khối THẺ (header + carousel); event là CỘT NÚT icon
	# (bố cục DỌC đã xoá hẳn 2 node đó; bố cục NGANG còn nhưng bị `main.gd` ẩn)
	var header: Control = main_scene.layout.event_header
	var carousel: Control = main_scene.layout.event_carousel
	assert(header == null or not header.visible,
		"Khoi the event: EventHeader phai AN (hoac da xoa) — event la cot nut icon")
	assert(carousel == null or not carousel.visible,
		"Khoi the event: EventCarousel phai AN (hoac da xoa) — event la cot nut icon")
	var section_for_events: Node = main_scene.layout.level_section
	var event_column: Node = section_for_events.get_node_or_null("EventButtons") if section_for_events != null else null
	assert(event_column != null, "LevelSection phai co cot nut `EventButtons`")
	# Cot nut event: toi da 5 nut, art lay tu EventTheme
	assert(event_column.get_child_count() <= 6,
		"Cot nut event toi da 5 nut + Timer (dang %d con)" % event_column.get_child_count())
	var em_node := root.get_node_or_null("EventManager")
	var active_events: Array = em_node.call("get_active_events") if em_node != null and em_node.has_method("get_active_events") else []
	# Bo qua event Daily (theme `daily` khong co art NUT ? Daily da ve dock)
	var ev_theme: EventTheme = null
	for ev in active_events:
		var th: EventTheme = ev.get("theme") as EventTheme
		if th != null and th.button_normal != null:
			ev_theme = th
			break
	if ev_theme != null:
		assert(ev_theme.button_pressed != null, "EventTheme phai khai bao `button_pressed`")

	# 3. KH?I B?N ?? (b?n G?P ? m?n Levels ?? g?, b?n ?? n?m ngay trong Main)
	var section: LevelSection = main_scene.layout.level_section
	assert(section != null, "Main phai co LevelSection (ban do man choi)")
	assert(section.map != null, "LevelSection phai bind LevelMap (bang @export)")
	assert(section.map.node_count() > 0, "Ban do phai co nut man")
	# Duong LIEN: nhan "CHUONG n" nam duoi CONG nen chip noi da bi xoa (co the con o bo cuc khac)
	assert(section.chapter_chip == null or not section.chapter_chip.visible,
		"Chip chuong noi phai AN (hoac da xoa) — nhan chuong nam duoi cong")
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
	var names := ["DockShop", "DockRanking", "DockDaily", "DockBadges"]
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
	assert(main_scene.ui("Achievement") == null, "KHONG con nut Danh hieu lon cu")

	# 7. Nut THU THACH (Daily) o dock mo thang scenes/daily.tscn
	var dock_daily: Node = dock_row.get_node_or_null("DockDaily")
	assert(dock_daily != null, "Dock phai co nut Thu thach (Daily)")
	if dock_daily != null:
		(dock_daily as BaseButton).pressed.emit()
		for i in 3:
			await process_frame
		var sm := root.get_node_or_null("SceneManager")
		var now_path := str(sm.call("current_scene_path")) if sm != null else ""
		assert(now_path == "res://scenes/daily.tscn",
			"Bam nut Thu thach phai mo scenes/daily.tscn (dang '%s')" % now_path)

	print("\n[SUCCESS] Bo cuc Main Screen moi dung: thanh tren · su kien · 2 the che do · dock 4 nut.\n")
	main_scene.queue_free()
	await process_frame
	quit(0)
