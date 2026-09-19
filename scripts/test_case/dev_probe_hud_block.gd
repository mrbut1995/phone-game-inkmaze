extends SceneTree
## DEV: kiểm tra HUD đang gắn có ĐÚNG biến thể (dọc/ngang) với layout đang hiển thị không,
## và action bar của nó có ĐÈ LÊN bàn cờ (⇒ chặn swipe / nút bấm) không.
##   godot --path . --rendering-driver opengl3 --script res://scripts/test_case/dev_probe_hud_block.gd

const SIZES := [Vector2i(1080, 1920), Vector2i(1920, 1080)]
const MODES := ["play", "dungeon", "minesweeper", "sum_path"]


func _initialize() -> void:
	_run.call_deferred()


func _frames(n: int) -> void:
	for _i in n:
		await process_frame


func _run() -> void:
	TranslationServer.set_locale("vi")
	for size in SIZES:
		for mode in MODES:
			DisplayServer.window_set_size(size)
			await _frames(6)
			var gm: Node = root.get_node_or_null("GameManager")
			if gm != null:
				gm.set("current_mode", mode)
				gm.set("current_level", 1)
			var scene: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
			root.add_child(scene)
			await _frames(10)
			_dump(scene, mode)
			scene.queue_free()
			await _frames(3)
	quit()


func _dump(scene: Node, mode: String) -> void:
	var canvas := root.get_visible_rect().size
	var active: Node = scene.call("active_layout")
	var hud := scene.get("hud_host") as Control
	print("\n== %s  canvas=%.0f×%.0f  landscape=%s  layout=%s" % [mode, canvas.x, canvas.y,
		str(scene.get("is_landscape")), active.name])
	if hud == null:
		print("   !! hud_host null")
		return
	print("   HUD scene = %s   rect=%s" % [hud.scene_file_path, str(hud.get_global_rect())])
	var board := scene.get("board_view") as Control
	var board_rect := board.get_global_rect() if board != null else Rect2()
	var bar := hud.get_node_or_null("ActionBar") as Control
	if bar == null:
		print("   !! HUD không có ActionBar")
		return
	_rows_report(bar, board_rect)
	for btn_name in ["Tool", "Wall", "Undo", "Hint", "Replay"]:
		var btn := bar.find_child(btn_name, true, false) as Control
		if btn == null:
			continue
		var r := btn.get_global_rect()
		var overlap := r.intersection(board_rect).get_area()
		print("   nút %-6s rect=%s  đè bàn cờ=%.0f px²  visible=%s" % [btn_name, str(r), overlap,
			str(btn.is_visible_in_tree())])


func _rows_report(bar: Control, board_rect: Rect2) -> void:
	_scan_rows(bar, board_rect, 0)


func _scan_rows(node: Node, board_rect: Rect2, depth: int) -> void:
	for child in node.get_children():
		var c := child as Control
		if c != null:
			if c.get_class().ends_with("Container") and c.mouse_filter != Control.MOUSE_FILTER_IGNORE:
				var r := c.get_global_rect()
				var overlap := r.intersection(board_rect).get_area()
				if overlap > 0.0 or c.size.y > 200.0:
					print("   ⚠ vùng chứa %-10s rect=%s filter=%d đè bàn cờ=%.0f px²" % [c.name,
						str(r), c.mouse_filter, overlap])
			_scan_rows(c, board_rect, depth + 1)
		else:
			_scan_rows(child, board_rect, depth + 1)
