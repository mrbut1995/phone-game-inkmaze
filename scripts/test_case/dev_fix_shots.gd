extends SceneTree
## ============================================================================
## DEV TOOL: chụp ảnh các màn cần sửa theo tỉ lệ mong muốn (render thật):
##
##   godot --path . --rendering-driver opengl3 --script res://scripts/test_case/dev_fix_shots.gd
##
## Ảnh lưu vào tmp_fix/<WxH>_<id>.png (nửa phân giải).
## Dùng để soi lỗi: cell lệch trên · HUD lệch · popup không giữa · daily mission lệch · shop hụt đáy.
## ============================================================================

const SIZES := [Vector2i(1080, 2400), Vector2i(1080, 1920), Vector2i(2400, 1080)]


func _init() -> void:
	print("\n=== FIX SHOTS ===")
	await process_frame
	TranslationServer.set_locale("vi")
	var gm: Node = root.get_node_or_null("GameManager")
	if gm != null:
		gm.set("unlocked_levels", 99)
	DirAccess.make_dir_recursive_absolute("res://tmp_fix")
	for size in SIZES:
		DisplayServer.window_set_size(size)
		await _frames(5)
		print("── %dx%d canvas=%s" % [size.x, size.y, str(root.get_visible_rect().size)])
		await _screen("main", "res://scenes/main.tscn", size)
		await _screen("daily", "res://scenes/daily.tscn", size)
		await _screen("shop", "res://scenes/shop.tscn", size)
		await _game_play(size)
		for mode_id in ["countdown_cost", "fading_ink", "sum_path", "fog_of_war"]:
			await _game_mode(mode_id, size)
	quit(0)


func _screen(id: String, path: String, size: Vector2i) -> void:
	var packed := load(path) as PackedScene
	if packed == null:
		print("   [FAIL] không load được %s" % path)
		return
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await _frames(20)
	_shot("%dx%d_%s" % [size.x, size.y, id])
	scene.queue_free()
	await _frames(2)


func _game_play(size: Vector2i) -> void:
	var gm: Node = root.get_node_or_null("GameManager")
	if gm != null:
		gm.set("current_mode", "play")
		gm.set("current_level", 1)
	var packed := load("res://scenes/game.tscn") as PackedScene
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await _frames(24)
	_shot("%dx%d_game" % [size.x, size.y])
	# Popup Tạm dừng
	var ui: Node = scene.get("ui_controller")
	if ui != null:
		ui.call("toggle_settings")
		await _frames(24)
		_shot("%dx%d_game_pause" % [size.x, size.y])
		Popups.close_all()
		await _frames(8)
	# Popup thua (Play mode)
	var controller: Node = scene.get("game_controller")
	if controller != null:
		controller.call("_game_over")
		await _frames(30)
		_shot("%dx%d_game_over" % [size.x, size.y])
		Popups.close_all()
		await _frames(8)
	scene.queue_free()
	await _frames(2)


## Một chế độ dùng art sheet HUD -> chụp riêng khung HUD ở độ phân giải 1:1
func _game_mode(mode_id: String, size: Vector2i) -> void:
	var gm: Node = root.get_node_or_null("GameManager")
	if gm != null:
		gm.set("current_mode", mode_id)
		gm.set("current_level", 1)
	var packed := load("res://scenes/game.tscn") as PackedScene
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await _frames(24)
	var ui: Node = scene.get("ui_controller")
	var hud: Control = (ui.get("hud") as Control) if ui != null else null
	if hud != null:
		_hud_shot("%dx%d_hud_%s" % [size.x, size.y, mode_id], hud)
	scene.queue_free()
	await _frames(2)


## Cắt đúng khung HUD (980×249) từ ảnh canvas 1:1 để soi từng pixel
func _hud_shot(id: String, hud: Control) -> void:
	var img := root.get_texture().get_image()
	if img == null:
		print("   [FAIL] không lấy được ảnh %s" % id)
		return
	var full := Rect2i(Vector2i.ZERO, img.get_size())
	var r := Rect2i(Vector2i(hud.global_position.round()), Vector2i(hud.size.round())).intersection(full)
	if r.size.x <= 0 or r.size.y <= 0:
		print("   [FAIL] khung HUD rỗng %s" % id)
		return
	var crop := img.get_region(r)
	crop.save_png("res://tmp_fix/%s.png" % id)
	print("   [hud] %s %s" % [id, str(r)])


func _shot(id: String) -> void:
	var img := root.get_texture().get_image()
	if img == null:
		print("   [FAIL] không lấy được ảnh %s" % id)
		return
	img.resize(maxi(int(img.get_width() * 0.5), 1), maxi(int(img.get_height() * 0.5), 1), Image.INTERPOLATE_LANCZOS)
	img.save_png("res://tmp_fix/%s.png" % id)
	print("   [shot] %s" % id)


func _frames(n: int) -> void:
	for i in n:
		await process_frame
