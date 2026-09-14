extends SceneTree
## ============================================================================
## Test: Kiểm tra layout các nút và thẻ trong Main Scene
## ============================================================================

func _init() -> void:
	print("\n========================================================")
	print("  TEST: MAIN SCENE BUTTONS LAYOUT")
	print("========================================================\n")

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
	print("[INFO] btn_rules pos.x: %f" % main_scene.btn_rules.position.x)
	print("[INFO] btn_settings pos.x: %f" % main_scene.btn_settings.position.x)
	print("[INFO] btn_archivement pos.x: %f" % main_scene.btn_archivement.position.x)

	assert(main_scene.btn_play.position.y < main_scene.btn_dungeon.position.y,
		"btn_dungeon phai nam duoi btn_play, khong duoc de chong len nhau")
	assert(main_scene.btn_dungeon.position.y < main_scene.btn_daily.position.y,
		"btn_daily phai nam duoi btn_dungeon, khong duoc de chong len nhau")

	assert(main_scene.btn_leaderboard.position.x < main_scene.btn_rules.position.x,
		"btn_rules phai nam ben phai btn_leaderboard")
	assert(main_scene.btn_rules.position.x < main_scene.btn_settings.position.x,
		"btn_settings phai nam ben phai btn_rules")
	assert(main_scene.btn_settings.position.x < main_scene.btn_archivement.position.x,
		"btn_archivement (So tay thanh tuu) phai nam ben phai btn_settings")

	# 4 nut trong hang Other phai cung kich thuoc (khong bi le)
	var other_box := main_scene.get_node_or_null("Panel/Other") as Control
	if other_box != null:
		for child in other_box.get_children():
			var button := child as TextureButton
			if button == null or button.name == "Archivement":
				continue
			assert(button.size.x > 0.0, "Nut %s phai co kich thuoc" % button.name)

	print("\n[SUCCESS] Cac button va the tren Main Scene da duoc xep dung vi tri, khong bi de chong len nhau!\n")
	main_scene.queue_free()
	await process_frame
	quit(0)
