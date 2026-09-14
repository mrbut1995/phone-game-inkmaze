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

	print("[INFO] btn_play pos.y: %f" % main_scene.btn_play.position.y)
	print("[INFO] btn_dungeon pos.y: %f" % main_scene.btn_dungeon.position.y)
	print("[INFO] btn_daily pos.y: %f" % main_scene.btn_daily.position.y)

	print("[INFO] btn_leaderboard pos.x: %f" % main_scene.btn_leaderboard.position.x)
	print("[INFO] btn_shop pos.x: %f" % main_scene.btn_shop.position.x)
	print("[INFO] btn_settings pos.x: %f" % main_scene.btn_settings.position.x)
	print("[INFO] btn_archivement global: %s size: %s"
		% [str(main_scene.btn_archivement.global_position), str(main_scene.btn_archivement.size)])

	assert(main_scene.btn_play.position.y < main_scene.btn_dungeon.position.y,
		"btn_dungeon phai nam duoi btn_play, khong duoc de chong len nhau")
	assert(main_scene.btn_dungeon.position.y < main_scene.btn_daily.position.y,
		"btn_daily phai nam duoi btn_dungeon, khong duoc de chong len nhau")

	assert(main_scene.btn_leaderboard.position.x < main_scene.btn_shop.position.x,
		"btn_shop (Cua hang) phai nam ben phai btn_leaderboard")
	assert(main_scene.btn_shop.position.x < main_scene.btn_settings.position.x,
		"btn_settings phai nam ben phai btn_shop")

	# Nút Sổ tay thành tựu: icon LỚN ở góc TRÊN PHẢI tờ giấy, không nằm trong hàng Other
	assert(main_scene.btn_archivement.global_position.y < main_scene.btn_leaderboard.global_position.y,
		"Nút thành tựu phải nằm PHÍA TRÊN hàng nút Other")
	assert(main_scene.btn_archivement.global_position.x > main_scene.btn_play.global_position.x,
		"Nút thành tựu phải nằm bên PHẢI (góc trên phải tờ giấy)")
	assert(main_scene.btn_archivement.size.x >= 200.0 and main_scene.btn_archivement.size.y >= 200.0,
		"Nút thành tựu phải là icon LỚN (>= 200x200), đang %s" % str(main_scene.btn_archivement.size))
	assert(main_scene.btn_archivement.texture_normal != main_scene.btn_archivement.texture_pressed
			and main_scene.btn_archivement.texture_pressed != main_scene.btn_archivement.texture_focused,
		"Nút thành tựu phải có đủ trạng thái normal / pressed / focus")

	# Hàng Other phải còn đúng 3 nút: Xếp hạng · Cửa hàng · Cài đặt
	var other_box := main_scene.get_node_or_null("Panel/Other") as Control
	assert(other_box != null, "Phai co hang nut Other")
	if other_box != null:
		assert(other_box.get_child_count() == 3,
			"Hang Other phai co dung 3 nut, dang %d" % other_box.get_child_count())
		assert(other_box.get_node_or_null("Archivement") == null,
			"Nut thanh tuu KHONG con nam trong hang Other")
		for child in other_box.get_children():
			var button := child as TextureButton
			assert(button != null and button.size.x > 0.0, "Nut %s phai co kich thuoc" % child.name)
			assert(absf(button.size.x - 230.0) < 1.0 and absf(button.size.y - 130.0) < 1.0,
				"Nut %s phai dung kich thuoc art 230x130 (dang %s)" % [child.name, str(button.size)])

	print("\n[SUCCESS] Cac button va the tren Main Scene da duoc xep dung vi tri, khong bi de chong len nhau!\n")
	main_scene.queue_free()
	await process_frame
	quit(0)
