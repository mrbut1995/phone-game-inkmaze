extends SceneTree
## DEV: soi HUD + action bar của màn chơi ở cả 2 hướng màn hình.
##   godot --path . --rendering-driver opengl3 --script res://scripts/test_case/dev_probe_actionbar.gd

const SIZES := [Vector2i(1080, 1920), Vector2i(1920, 1080), Vector2i(1600, 1200)]
const BUTTONS := ["Tool", "Wall", "Undo", "Hint", "Replay"]


func _initialize() -> void:
	_run.call_deferred()


func _frames(n: int) -> void:
	for _i in n:
		await process_frame


func _run() -> void:
	for size in SIZES:
		DisplayServer.window_set_size(size)
		await _frames(4)
		TranslationServer.set_locale("vi")
		var gm: Node = root.get_node_or_null("GameManager")
		if gm != null:
			gm.set("current_mode", "play")
			gm.set("current_level", 1)
		var packed := load("res://scenes/game.tscn") as PackedScene
		var scene: Node = packed.instantiate()
		root.add_child(scene)
		await _frames(10)
		_dump(scene, size)
		scene.queue_free()
		await _frames(3)
	quit()


func _dump(scene: Node, size: Vector2i) -> void:
	var canvas := root.get_visible_rect().size
	print("=== %dx%d  canvas=%.0f×%.0f  is_landscape=%s" % [
		size.x, size.y, canvas.x, canvas.y, str(scene.get("is_landscape"))])
	var hud := scene.get("hud_host") as Control
	if hud == null:
		print("   !! hud_host = null")
		return
	print("   HUD  %s  rect=%s  min=%s" % [_path(hud), str(hud.get_global_rect()),
		str(hud.custom_minimum_size)])
	var bar := hud.get_node_or_null("Content/ActionBar") as Control
	if bar == null:
		print("   !! HUD không có ActionBar")
		return
	print("   ActionBar  rect=%s" % str(bar.get_global_rect()))
	for name in BUTTONS:
		var btn := bar.find_child(name, true, false) as Control
		if btn == null:
			print("     %-7s THIẾU" % name)
			continue
		print("     %-7s parent=%-14s rect=%s visible=%s" % [name, btn.get_parent().name,
			str(btn.get_global_rect()), str(btn.is_visible_in_tree())])
	for extra in ["Side", "HintGuide", "Board"]:
		var node := scene.call("ui", extra) as Control
		if node != null:
			print("   %-10s rect=%s" % [extra, str(node.get_global_rect())])


func _path(n: Node) -> String:
	var parts: Array[String] = []
	var cur: Node = n
	while cur != null and not (cur is Window):
		parts.push_front(cur.name)
		cur = cur.get_parent()
	return "/".join(parts)
