extends SceneTree
## Tool tạm: soi rect của 2 layout + TopBar ở 1 cỡ màn hình (chẩn đoán harness báo "tràn màn hình").
## Chạy: godot --path . --rendering-driver opengl3 --script res://scripts/test_case/dev_probe_layout.gd -- levels 1080x1920

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var screen := str(args[0]) if args.size() > 0 else "levels"
	var size := str(args[1]) if args.size() > 1 else "1080x1920"
	var parts := size.split("x")
	DisplayServer.window_set_size(Vector2i(int(parts[0]), int(parts[1])))
	await process_frame
	await process_frame
	var packed := load("res://scenes/%s.tscn" % screen) as PackedScene
	if packed == null:
		print("!! không load được scenes/%s.tscn" % screen)
		quit()
		return
	var scene := packed.instantiate() as Control
	root.add_child(scene)
	current_scene = scene
	for i in 25:
		await process_frame
	var canvas := root.get_visible_rect().size
	print("canvas=", canvas, " root rect=", Rect2(scene.position, scene.size))
	for layout_name in ["Portrait"]:
		var lay := scene.get_node_or_null(layout_name) as Control
		if lay == null:
			continue
		print("%s visible=%s anchors=(%.3f,%.3f,%.3f,%.3f) offsets=(%.1f,%.1f,%.1f,%.1f) rect=%s" % [
			layout_name, str(lay.visible), lay.anchor_left, lay.anchor_top, lay.anchor_right,
			lay.anchor_bottom, lay.offset_left, lay.offset_top, lay.offset_right, lay.offset_bottom,
			str(Rect2(lay.global_position, lay.size))])
		for child in lay.get_children():
			var c := child as Control
			if c != null:
				print("   %s rect=%s visible=%s" % [c.name, str(Rect2(c.global_position, c.size)), str(c.visible)])
	quit()
