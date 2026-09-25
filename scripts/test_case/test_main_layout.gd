extends SceneTree
## ============================================================================
## Test: Kiểm tra layout các nút và thẻ trong Main Scene
## ============================================================================

func _init() -> void:
	print("\n========================================================")
	print("  TEST: MAIN SCENE BUTTONS LAYOUT")
	print("========================================================\n")

	root.size = Vector2i(1080, 1920)
	await process_frame

	var main_packed: PackedScene = load("res://scenes/main.tscn")
	var main_scene: MainScene = main_packed.instantiate()
	root.add_child(main_scene)

	# Cho 10 frames de container sap xep layout va animation chay xong
	for i in 25:
		await process_frame

	print("[INFO] btn_play pos.y: %f" % main_scene.layout.btn_play.position.y)
	print("[INFO] btn_dungeon pos.y: %f" % main_scene.layout.btn_dungeon.position.y)
	print("[INFO] btn_daily pos.y: %f" % main_scene.layout.btn_daily.position.y)

	print("[INFO] btn_leaderboard pos.x: %f" % main_scene.layout.btn_leaderboard.position.x)
	print("[INFO] btn_shop pos.x: %f" % main_scene.layout.btn_shop.position.x)
	print("[INFO] btn_settings pos.x: %f" % main_scene.layout.btn_settings.position.x)
	print("[INFO] btn_archivement global: %s size: %s"
		% [str(main_scene.layout.btn_archivement.global_position), str(main_scene.layout.btn_archivement.size)])

	assert(main_scene.layout.btn_play.position.y < main_scene.layout.btn_dungeon.position.y,
		"btn_dungeon phai nam duoi btn_play, khong duoc de chong len nhau")
	assert(main_scene.layout.btn_dungeon.position.y < main_scene.layout.btn_daily.position.y,
		"btn_daily phai nam duoi btn_dungeon, khong duoc de chong len nhau")

	assert(main_scene.layout.btn_leaderboard.position.x < main_scene.layout.btn_shop.position.x,
		"btn_shop (Cua hang) phai nam ben phai btn_leaderboard")
	assert(main_scene.layout.btn_shop.position.x < main_scene.layout.btn_settings.position.x,
		"btn_settings phai nam ben phai btn_shop")

	# Nút Sổ tay thành tựu: icon LỚN ở góc TRÊN PHẢI tờ giấy, không nằm trong hàng Other
	assert(main_scene.layout.btn_archivement.global_position.y < main_scene.layout.btn_leaderboard.global_position.y,
		"Nút thành tựu phải nằm PHÍA TRÊN hàng nút Other")
	assert(main_scene.layout.btn_archivement.global_position.x > main_scene.layout.btn_play.global_position.x,
		"Nút thành tựu phải nằm bên PHẢI (góc trên phải tờ giấy)")
	assert(main_scene.layout.btn_archivement.size.x >= 100.0 and main_scene.layout.btn_archivement.size.y >= 100.0,
		"Nút thành tựu phải là icon LỚN (>= 100x100), đang %s" % str(main_scene.layout.btn_archivement.size))
	assert(main_scene.layout.btn_archivement.texture_normal != main_scene.layout.btn_archivement.texture_pressed
			and main_scene.layout.btn_archivement.texture_pressed != main_scene.layout.btn_archivement.texture_focused,
		"Nút thành tựu phải có đủ trạng thái normal / pressed / focus")

	# Hàng Other phải còn đúng 3 nút: Xếp hạng · Cửa hàng · Cài đặt
	var other_box := main_scene.ui("Other") as Control
	assert(other_box != null, "Phai co hang nut Other (layout doc)")
	if other_box != null:
		assert(other_box.get_child_count() == 3,
			"Hang Other phai co dung 3 nut, dang %d" % other_box.get_child_count())
		assert(other_box.get_node_or_null("Archivement") == null,
			"Nut thanh tuu KHONG con nam trong hang Other")
		for child in other_box.get_children():
			var button := child as BaseButton
			assert(button != null and button.size.x > 0.0, "Nut %s phai co kich thuoc" % child.name)
			assert(absf(button.size.x - 115.0) < 1.0 and absf(button.size.y - 65.0) < 1.0,
				"Nut %s phai dung kich thuoc art 115x65 (dang %s)" % [child.name, str(button.size)])

	# 2 LAYOUT theo hướng màn hình phải cùng tồn tại, đúng layout được bật
	assert(main_scene.get_node_or_null("Portrait") != null, "Phai co layout Portrait")
	assert(main_scene.get_node_or_null("Landscape") != null, "Phai co layout Landscape")
	assert(main_scene.ui("Paper") != null, "Layout NGANG phai co to giay Paper")
	var landscape_layout := main_scene.get_node_or_null("Landscape") as Control
	assert(landscape_layout != null and not landscape_layout.visible,
		"Man hinh DỌC thi layout ngang phai ẩn")

	# 2b. Mỗi thẻ chế độ phải được tách 3 phần: CircleIcon / TopBadge / BottomLabel
	for card_name in ["Play", "Dungeon", "DailyChallenge"]:
		var card := main_scene.ui(card_name) as Control
		assert(card != null, "Phai co the %s" % card_name)
		var circle := card.get_node_or_null("CircleIcon")
		var top_badge := card.get_node_or_null("TopBadge")
		var bottom := card.get_node_or_null("BottomLabel")
		assert(circle != null and top_badge != null and bottom != null,
			"The %s phai co du 3 node phan CircleIcon/TopBadge/BottomLabel" % card_name)
		assert(circle.get_node_or_null("ModeIcon") != null, "%s/CircleIcon phai chua ModeIcon" % card_name)
		assert(top_badge.get_node_or_null("Tag") != null, "%s/TopBadge phai chua Tag" % card_name)
		assert(bottom.get_node_or_null("Badge") != null, "%s/BottomLabel phai chua Badge" % card_name)

	# 3 huy hieu tren the che do phai duoc DIEN SO luc chay (chuoi dich co "{0}")
	for pair in [["Play", "Badge"], ["Dungeon", "Badge"], ["DailyChallenge", "Badge"]]:
		var badge := main_scene.ui_child(str(pair[0]), "BottomLabel/%s" % str(pair[1])) as Label
		assert(badge != null, "Phai co Label huy hieu tai %s/BottomLabel/Badge" % str(pair[0]))
		assert(not badge.text.contains("{0}"),
			"Huy hieu %s phai duoc dien so (dang '%s')" % [str(pair[0]), badge.text])
		print("[INFO] %s/Badge -> %s" % [str(pair[0]), badge.text])

	print("\n[SUCCESS] Cac button va the tren Main Scene da duoc xep dung vi tri, khong bi de chong len nhau!\n")
	main_scene.queue_free()
	await process_frame
	quit(0)
