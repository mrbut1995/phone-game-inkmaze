extends SceneTree
## Dev: kiểm tra Main Scene ở nhiều tỉ lệ (dọc + ngang) — in vị trí/kích thước thật.
## Chạy: godot --path . --rendering-driver opengl3 --script res://scripts/test_case/dev_main_aspect.gd

const SIZES: Array[Vector2i] = [
	Vector2i(1080, 1920),  # 9:16 dọc cơ bản
	Vector2i(1080, 2340),  # 9:19.5 dọc dài
	Vector2i(1080, 1440),  # 3:4 tablet
	Vector2i(1600, 1200),  # 4:3 ngang
	Vector2i(1920, 1080),  # 16:9 ngang
	Vector2i(2340, 1080),  # 19.5:9 ngang
]


func _init() -> void:
	await process_frame
	TranslationServer.set_locale("vi")
	for size in SIZES:
		DisplayServer.window_set_size(size)
		await _frames(4)
		await _run(size)
	await _rotate_test()
	quit(0)


## Xoay màn hình NGAY TRONG LÚC ĐANG MỞ Main Scene (kiểm tra đổi layout + gắn lại node)
func _rotate_test() -> void:
	print("\n──────── XOAY MÀN HÌNH THỜI GIAN THỰC ────────")
	DisplayServer.window_set_size(Vector2i(1080, 1920))
	await _frames(4)
	var scene := (load("res://scenes/main.tscn") as PackedScene).instantiate() as MainScene
	root.add_child(scene)
	await _frames(6)
	var portrait := scene.get_node_or_null("Portrait") as Control
	var landscape := scene.get_node_or_null("Landscape") as Control
	var first_play := scene.layout.btn_play
	print("  dọc:  is_landscape=%s P=%s L=%s · btn_play ở x=%.0f" % [str(scene.is_landscape),
		str(portrait.visible), str(landscape.visible), first_play.global_position.x])

	DisplayServer.window_set_size(Vector2i(1920, 1080))
	await _frames(8)
	var canvas := root.get_visible_rect().size
	print("  ngang: is_landscape=%s P=%s L=%s" % [str(scene.is_landscape),
		str(portrait.visible), str(landscape.visible)])
	print("     · btn_play ĐỔI sang node layout ngang: %s (x=%.0f · canvas=%.0f)" % [
		str(scene.layout.btn_play != first_play), scene.layout.btn_play.global_position.x, canvas.x])
	print("     · nút mới bấm được: %s" % str(scene.layout.btn_play.pressed.get_connections().size() > 0))

	DisplayServer.window_set_size(Vector2i(1080, 1920))
	await _frames(8)
	print("  quay lại dọc: is_landscape=%s P=%s L=%s · btn_play về node cũ: %s" % [
		str(scene.is_landscape), str(portrait.visible), str(landscape.visible),
		str(scene.layout.btn_play == first_play)])
	scene.queue_free()
	await _frames(2)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _run(size: Vector2i) -> void:
	var canvas := root.get_visible_rect().size
	print("\n──────── %dx%d  →  canvas %.0fx%.0f" % [size.x, size.y, canvas.x, canvas.y])
	var scene := (load("res://scenes/main.tscn") as PackedScene).instantiate() as MainScene
	root.add_child(scene)
	await _frames(8)

	var portrait := scene.get_node_or_null("Portrait") as Control
	var landscape := scene.get_node_or_null("Landscape") as Control
	print("  root: pos=%s size=%s · is_landscape=%s" % [str(scene.position), str(scene.size), str(scene.is_landscape)])
	print("  Portrait.visible=%s · Landscape.visible=%s" % [
		str(portrait.visible if portrait != null else false),
		str(landscape.visible if landscape != null else false)])
	for name in ["Paper", "Panel", "Logo", "Play", "Dungeon", "DailyChallenge", "Leaderboard",
			"Shop", "Settings", "Archivement", "Stamp"]:
		var node := scene.ui(name) as Control
		if node == null:
			continue
		var r := Rect2(node.global_position, node.size)
		var inside := r.position.x >= -1.0 and r.position.y >= -1.0 and r.end.x <= canvas.x + 1.0 and r.end.y <= canvas.y + 1.0
		print("    %-16s %-34s %s" % [name, str(r), "OK" if inside else "!!! TRÀN" + str(size)])
	# Chi tiết trong thẻ Play + vùng logo (kiểm tra chữ có nằm gọn trong khung không)
	for pair in [["Play", "Tag"], ["Play", "Title"], ["Play", "Badge"], ["Play", "ModeIcon"],
			["Play", "VBoxContainer"], ["Archivement", "Count"], ["Stamp", "Label"]]:
		var child := scene.ui_child(str(pair[0]), str(pair[1])) as Control
		if child == null:
			continue
		print("      · %s/%s  %s" % [str(pair[0]), str(pair[1]), str(Rect2(child.global_position, child.size))])
	scene.queue_free()
	await _frames(2)
