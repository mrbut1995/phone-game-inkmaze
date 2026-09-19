extends SceneTree
## DEV: tái hiện lỗi "xoay NGANG → DỌC thì bàn cờ nằm sai chỗ" (user báo).
## In số đo TRONG bàn cờ (khung node · khung giấy thật · bước ô · ô đầu tiên) + chụp ảnh từng bước
## vào `tmp_aspect/rotate/`. Chạy:
##   godot --path . --rendering-driver opengl3 --script res://scripts/test_case/dev_probe_rotate_shot.gd


func _initialize() -> void:
	_run.call_deferred()


func _frames(n: int) -> void:
	for _i in n:
		await process_frame


func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	await _frames(8)
	TranslationServer.set_locale("vi")
	var gm: Node = root.get_node_or_null("GameManager")
	if gm != null:
		gm.set("current_mode", "play")
		gm.set("current_level", 1)
	var scene: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await _frames(14)
	await _report(scene, "1. NGANG")
	await _shot("land")
	DisplayServer.window_set_size(Vector2i(1080, 1920))
	await _frames(2)
	await _report(scene, "2. VỪA XOAY DỌC (sau 2 frame)")
	await _shot("port_2f")
	await _frames(40)
	await _report(scene, "3. SAU 40 FRAME")
	await _shot("port_42f")
	quit()


func _report(scene: Node, label: String) -> void:
	await _frames(0)
	var board := scene.get("board_view") as Control
	print("\n== %s" % label)
	print("   canvas=%s" % str(root.get_visible_rect().size))
	if board == null:
		print("   <không có board>")
		return
	var parent: Node = board.get_parent()
	print("   board rect=%s  parent=%s" % [str(board.get_global_rect()), parent.name if parent else "<none>"])
	print("   giấy thật=%s  step=%.1f  fit=%.2f" % [
		str(board.call("panel_inner_rect")), float(board.get("_step")), float(board.get("_fit_scale"))])
	var cells: Array = board.get("_cell_nodes")
	var first: Control = null
	for c in cells:
		if c != null:
			first = c
			break
	if first != null:
		print("   ô đầu tiên=%s" % str(first.get_global_rect()))


func _shot(name: String) -> void:
	await _frames(2)
	var img := root.get_texture().get_image()
	if img == null:
		print("   <không chụp được ảnh>")
		return
	var dir := "res://tmp_aspect/rotate"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var path := dir + "/" + name + ".png"
	img.save_png(path)
	print("   ảnh: %s" % path)
