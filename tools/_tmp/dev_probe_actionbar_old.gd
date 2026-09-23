extends SceneTree
## Probe nhanh: bố cục màn chơi + thanh nút hành động trong HUD ở 2 hướng màn hình.
## Chạy: godot --path . --rendering-driver opengl3 --script res://scripts/test_case/dev_probe_actionbar.gd

const SIZES := [Vector2i(1080, 1920), Vector2i(1920, 1080), Vector2i(1600, 1200)]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for size in SIZES:
		DisplayServer.window_set_size(size)
		get_root().content_scale_size = size
		var packed := load("res://scenes/game.tscn") as PackedScene
		var scene := packed.instantiate()
		get_root().add_child(scene)
		await process_frame
		await process_frame
		await process_frame
		var layout: Node = scene.call("active_layout")
		var info := scene.call("ui", "Information") as Control
		print("=== %s | landscape=%s | layout=%s" % [str(size), str(scene.get("is_landscape")),
			layout.name if layout != null else "<none>"])
		if info != null:
			print("   Information: %s  pos=%s size=%s scale=%s" % [_path_of(info),
				str(info.global_position), str(info.size), str(info.scale)])
			var bar: Node = info.get_node_or_null("Content/ActionBar")
			print("   ActionBar: %s" % ("OK" if bar != null else "THIẾU"))
			if bar != null:
				for n in ["Tool", "Wall", "Undo", "Hint", "Replay"]:
					var b := bar.get_node_or_null(n) as Control
					print("     %-7s %s  parent=%s pos=%s size=%s visible=%s" % [n,
						"OK" if b != null else "THIẾU",
						b.get_parent().name if b != null else "-",
						str(b.position) if b != null else "-",
						str(b.size) if b != null else "-",
						str(b.visible) if b != null else "-"])
		for n in ["Board", "Side", "HintGuide"]:
			var c := scene.call("ui", n) as Control
			if c != null:
				print("   %-9s pos=%s size=%s" % [n, str(c.global_position), str(c.size)])
		var gc: Node = scene.get("game_controller")
		if gc != null:
			print("   tool=%s" % str(scene.get("tool_controller").get("current_tool")))
		scene.queue_free()
		await process_frame
	quit()


func _path_of(n: Node) -> String:
	var parts: Array[String] = []
	var cur := n
	while cur != null and not (cur is Window):
		parts.push_front(cur.name)
		cur = cur.get_parent()
	return "/".join(parts)
