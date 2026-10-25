extends SceneTree

func _init() -> void:
	await process_frame
	root.size = Vector2i(1080, 1920)
	TranslationServer.set_locale("vi")
	var scene := (load("res://scenes/splash.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	var layout = scene.get("layout")
	print("layout=", layout)
	var lc: Control = layout.logo_container
	var panel: Control = lc.get_parent()
	print("after 1 frame: panel.size=", panel.size, " lc.size=", lc.size, " pivot=", lc.pivot_offset)
	for i in 6:
		await process_frame
	print("after 7 frames: panel.size=", panel.size, " lc.size=", lc.size, " pivot=", lc.pivot_offset,
		" scale=", lc.scale, " pos=", lc.position)
	# Do scale theo từng frame để xem co gian (giat cuc)
	print("--- scale theo frame ---")
	for i in 24:
		await process_frame
		print("  f%02d scale=%.4f size=%s pivot=%s global_pos=%s" % [i, lc.scale.x, str(lc.size), str(lc.pivot_offset), str(lc.global_position)])
	quit(0)
