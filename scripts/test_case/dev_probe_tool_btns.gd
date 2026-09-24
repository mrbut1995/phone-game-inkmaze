extends SceneTree
## DEV PROBE: nút công cụ của màn chơi có được gắn sau khi vào màn không?
##   godot --headless --path . --script res://scripts/test_case/dev_probe_tool_btns.gd

func _init() -> void:
	await process_frame
	var scene: GameScene = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var layout: Node = scene.get("layout")
	var hud: Node = scene.get("hud_host")
	print("[probe] mode=%s  layout=%s  hud_host=%s" % [str(scene.get("_mode_id")), str(layout), str(hud)])
	print("[probe] layout.pause_btn=%s  status_bar=%s" % [str(layout.pause_btn), str(layout.status_bar)])
	print("[probe] tool_path=%s  tool_wall=%s  undo=%s  hint=%s  replay=%s" % [
		str(scene.get("tool_path_btn")), str(scene.get("tool_wall_btn")), str(scene.get("undo_btn")),
		str(scene.get("hint_btn")), str(scene.get("replay_btn"))])
	if hud != null:
		print("[probe] hud script=%s  has(tool_wall_btn)=%s"
			% [hud.get_script().resource_path, str(hud.has_method("tool_wall_btn"))])
		if hud.has_method("tool_wall_btn"):
			print("[probe]   hud.tool_wall_btn()=%s" % str(hud.call("tool_wall_btn")))
		print("[probe]   hud children=%s" % str(hud.get_children().map(func(c: Node) -> String: return c.name)))
	quit(0)
