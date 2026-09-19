extends SceneTree
## ============================================================================
## DEV TOOL: in SỐ ĐO layout các màn ở tỉ lệ mong muốn (không cần soi ảnh):
##
##   godot --path . --rendering-driver opengl3 --script res://scripts/test_case/dev_dump_layout.gd
##
## Dùng để sửa: cell lệch trên · HUD lệch · popup không giữa · daily mission lệch · shop hụt đáy.
## ============================================================================

const SIZES := [Vector2i(1080, 2424), Vector2i(2400, 1080)]


func _init() -> void:
	print("\n=== DUMP LAYOUT ===")
	await process_frame
	TranslationServer.set_locale("vi")
	var gm: Node = root.get_node_or_null("GameManager")
	if gm != null:
		gm.set("unlocked_levels", 99)
	for size in SIZES:
		DisplayServer.window_set_size(size)
		await _frames(5)
		print("\n────── %dx%d   canvas=%s" % [size.x, size.y, str(root.get_visible_rect().size)])
		await _dump_game()
		await _dump_simple("daily", "res://scenes/daily.tscn")
		await _dump_simple("shop", "res://scenes/shop.tscn")
	quit(0)


func _r(c: Control) -> String:
	if c == null:
		return "none"
	return "P:%s S:%s" % [str(c.global_position.round()), str(c.size.round())]


func _dump_game() -> void:
	var gm: Node = root.get_node_or_null("GameManager")
	if gm != null:
		gm.set("current_mode", "play")
		gm.set("current_level", 1)
	var scene: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await _frames(20)
	var canvas := root.get_visible_rect().size
	print("  scene    %s" % _r(scene as Control))
	for path in ["Status", "BoardSlot", "Information", "HintGuide"]:
		print("  %-11s %s" % [path, _r(scene.call("ui", path) as Control)])
	var board: Node = scene.get("board_view")
	if board != null:
		print("  board  panel_inner=%s  step=%.1f fit=%.2f" % [
			str(board.call("panel_inner_rect")), float(board.get("_step")), float(board.get("_fit_scale"))])
		var cells: Array = board.get("_cell_nodes")
		for i in mini(2, cells.size()):
			var c = cells[i]
			if c != null:
				print("  cell[%d]   %s   (rel=%s)" % [i, _r(c), str(c.position.round())])
		var cursor: Control = board.get("_cursor")
		print("  cursor   %s" % _r(cursor))
	# HUD in-game (Time card / mode HUD)
	var ui: Node = scene.get("ui_controller")
	if ui != null:
		var hud: Control = ui.get("hud")
		print("  hud      %s" % _r(hud))
	# Popup: tạm dừng + thua
	if ui != null:
		ui.call("toggle_settings")
		await _frames(24)
		_dump_popup("pause", canvas)
		Popups.close_all()
		await _frames(8)
	var controller: Node = scene.get("game_controller")
	if controller != null:
		controller.call("_game_over")
		await _frames(30)
		_dump_popup("game_over_level", canvas)
		Popups.close_all()
		await _frames(8)
	scene.queue_free()
	await _frames(2)


func _dump_popup(tag: String, canvas: Vector2) -> void:
	var pop := Popups.top()
	if pop == null:
		print("  popup/%s: KHÔNG mở được" % tag)
		return
	var panel := pop.get_node_or_null("Panel") as Control
	var dim := pop.get_node_or_null("Dim") as Control
	if panel == null:
		print("  popup/%s: thiếu Panel" % tag)
		return
	var pr := Rect2(panel.global_position, panel.size)
	var center_y := pr.position.y + pr.size.y * 0.5
	print("  popup/%-15s panel=%s  canvas=%s  lệch_tâm_y=%.0f  lệch_tâm_x=%.0f  dim=%s" % [
		tag, str(pr), str(canvas),
		center_y - canvas.y * 0.5, (pr.position.x + pr.size.x * 0.5) - canvas.x * 0.5, _r(dim)])


func _dump_simple(id: String, path: String) -> void:
	var packed := load(path) as PackedScene
	if packed == null:
		return
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await _frames(20)
	print("  === %s  scene %s" % [id, _r(scene as Control)])
	var canvas := root.get_visible_rect().size
	if id == "daily":
		for path2 in ["Header", "Calendar", "Missions", "MissionList", "Content", "BottomBtn"]:
			var n := scene.get_node_or_null(path2) as Control
			if n != null:
				print("    %-12s %s" % [path2, _r(n)])
		_dump_tree(scene, 1, canvas)
	elif id == "shop":
		_dump_tree(scene, 1, canvas)
		print("    shop: tab=%s per_page=%d pages=%d page=%d cards=%d first_id=%s" % [
			str(scene.call("current_tab")), int(scene.call("items_per_page")),
			int(scene.call("page_count")), int(scene.call("current_page")),
			int(scene.call("item_count")), str(scene.get("_page_first_id"))])
	scene.queue_free()
	await _frames(2)


## In mọi Control con trực tiếp (để thấy khối nào hụt đáy ở Shop/Daily)
func _dump_tree(node: Node, depth: int, canvas: Vector2) -> void:
	if depth > 3:
		return
	for child in node.get_children():
		var c := child as Control
		if c == null or not c.visible:
			continue
		if not c is Node:
			continue
		var r := Rect2(c.global_position, c.size)
		if c.size.x < 8.0 or c.size.y < 8.0:
			continue
		var gap_bottom := canvas.y - (r.position.y + r.size.y)
		print("    %s%-18s %s   (đáy còn %.0f)" % ["  ".repeat(depth), String(c.name).substr(0, 18), str(r), gap_bottom])
		_dump_tree(child, depth + 1, canvas)


func _frames(n: int) -> void:
	for i in n:
		await process_frame

