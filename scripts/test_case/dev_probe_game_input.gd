extends SceneTree
## DEV: tìm node đang CHẶN input ở màn chơi (swipe bàn cờ / bấm nút không ăn).
##   godot --path . --rendering-driver opengl3 --script res://scripts/test_case/dev_probe_game_input.gd

const SIZES := [Vector2i(1080, 1920), Vector2i(1920, 1080)]


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
		var scene: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
		root.add_child(scene)
		await _frames(10)
		_dump(scene, size)
		scene.queue_free()
		await _frames(3)
	quit()


func _dump(scene: Node, size: Vector2i) -> void:
	var canvas := root.get_visible_rect().size
	print("\n=== %dx%d canvas=%s paused=%s landscape=%s" % [size.x, size.y, str(canvas),
		str(paused), str(scene.get("is_landscape"))])
	var gc: Node = scene.get("game_controller")
	var board := scene.get("board_view") as Control
	var ui: Node = scene.get("ui_controller")
	if gc != null:
		print("   game_controller._run_active = %s" % str(gc.get("_run_active")))
	if board != null:
		print("   board rect=%s  interaction=%s  mouse_filter=%d" % [
			str(board.get_global_rect()), str(board.get("_interaction_enabled")), board.mouse_filter])
	if ui != null:
		var hud := ui.get("hud") as Control
		if hud != null:
			print("   HUD = %s rect=%s mouse_filter=%d" % [_path(hud), str(hud.get_global_rect()),
				hud.mouse_filter])
	# Popup nào đang mở?
	var host := scene.get_node_or_null("Popups")
	if host != null:
		for child in host.get_children():
			var c := child as Control
			if c != null and c.visible:
				print("   POPUP đang mở: %s rect=%s" % [_path(c), str(c.get_global_rect())])
	# Điểm giữa bàn cờ + điểm của nút đầu tiên trên HUD
	if board != null:
		_probe_point(scene, board.get_global_rect().get_center(), "TÂM BÀN CỜ")
	var tool: Control = scene.get("tool_path_btn") as Control
	if tool != null:
		_probe_point(scene, tool.get_global_rect().get_center(), "NÚT VẼ ĐƯỜNG")
	_fullscreen_blockers(scene, canvas)


## Liệt kê mọi Control ăn input tại 1 điểm (theo thứ tự cây = thứ tự vẽ, phần tử cuối là TRÊN CÙNG)
func _probe_point(scene: Node, point: Vector2, label: String) -> void:
	var hits: Array[String] = []
	_collect(scene, point, hits)
	print("   %s @ (%.0f,%.0f) — %d node ăn input:" % [label, point.x, point.y, hits.size()])
	for i in hits.size():
		print("      [%d] %s%s" % [i, hits[i], "   <-- TRÊN CÙNG" if i == hits.size() - 1 else ""])


func _collect(node: Node, point: Vector2, out: Array[String]) -> void:
	for child in node.get_children():
		var c := child as Control
		if c != null:
			if not c.is_visible_in_tree():
				continue
			if c.mouse_filter != Control.MOUSE_FILTER_IGNORE:
				if c.get_global_rect().has_point(point):
					out.append("%s  rect=%s filter=%d clip=%s" % [_path(c),
						str(c.get_global_rect()), c.mouse_filter, str(c.clip_contents)])
			_collect(c, point, out)
		else:
			_collect(child, point, out)


## Node phủ gần kín canvas mà vẫn ăn input = nghi phạm chặn toàn màn hình
func _fullscreen_blockers(scene: Node, canvas: Vector2) -> void:
	var canvas_rect := Rect2(Vector2.ZERO, canvas)
	_scan_full(scene, canvas_rect, 0)


func _scan_full(node: Node, canvas_rect: Rect2, depth: int) -> void:
	for child in node.get_children():
		var c := child as Control
		if c != null:
			if c.is_visible_in_tree() and c.mouse_filter != Control.MOUSE_FILTER_IGNORE:
				var r := c.get_global_rect()
				if r.size.x >= canvas_rect.size.x * 0.9 and r.size.y >= canvas_rect.size.y * 0.9:
					print("   ⚠ PHỦ KÍN CANVAS + ĂN INPUT: %s rect=%s filter=%d" % [_path(c), str(r),
						c.mouse_filter])
			_scan_full(c, canvas_rect, depth + 1)
		else:
			_scan_full(child, canvas_rect, depth + 1)


func _path(n: Node) -> String:
	var parts: Array[String] = []
	var cur: Node = n
	while cur != null and not (cur is Window):
		parts.push_front(cur.name)
		cur = cur.get_parent()
	return "/".join(parts)
