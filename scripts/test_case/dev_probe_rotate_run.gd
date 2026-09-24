extends SceneTree
## DEV: mô phỏng ĐÚNG lỗi user báo — chơi ở NGANG (Play Mode) → xoay sang DỌC → bấm REPLAY.
## Kiểm tra: board có maze không, chế độ có bị nhảy sang Dungeon không.
##   godot --path . --rendering-driver opengl3 --script res://scripts/test_case/dev_probe_rotate_run.gd


func _initialize() -> void:
	_run.call_deferred()


func _frames(n: int) -> void:
	for _i in n:
		await process_frame


func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	await _frames(6)
	TranslationServer.set_locale("vi")
	var gm: Node = root.get_node_or_null("GameManager")
	if gm != null:
		gm.set("current_mode", "play")
		gm.set("current_level", 1)
	var scene: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await _frames(12)
	_report(scene, "1. ban đầu — NGANG, Play Mode")
	_swipe_once(scene)
	await _frames(4)
	_report(scene, "2. sau khi kéo 1 bước")
	# XOAY sang DỌC
	DisplayServer.window_set_size(Vector2i(1080, 1920))
	await _frames(30)
	_report(scene, "3. sau khi XOAY sang DỌC")
	# Bấm REPLAY (như người dùng bấm nút Chơi lại)
	var gc: Node = scene.get("game_controller")
	if gc != null:
		gc.call("restart_run")
	await _frames(12)
	_report(scene, "4. sau khi bấm REPLAY")
	quit()


func _report(scene: Node, label: String) -> void:
	var canvas := root.get_visible_rect().size
	var grid: Node = scene.get("grid_controller")
	var gmc: Node = scene.get("game_mode_controller")
	var mode_id := "<null>"
	if gmc != null and gmc.get("game_mode") != null:
		mode_id = str(gmc.get("game_mode").get("mode_id"))
	var gc: Node = scene.get("game_controller")
	print("\n== %s" % label)
	print("   canvas=%.0f×%.0f  layout=%s  landscape=%s" % [canvas.x, canvas.y,
		(scene.call("active_layout") as Node).name, str(scene.get("is_landscape"))])
	print("   mode=%s   maze_null=%s   path=%s   run_active=%s" % [mode_id,
		str(grid.get("maze") == null) if grid != null else "-",
		str(grid.get("path")) if grid != null else "-",
		str(gc.get("_run_active")) if gc != null else "-"])
	var board := scene.get("board_view") as Control
	if board != null:
		var parent: Node = board.get_parent()
		var slot: Node = scene.call("active_layout").call("board_slot") if (scene.call("active_layout") as Node).has_method("board_slot") else null
		print("   board rect=%s  interaction=%s" % [str(board.get_global_rect()),
			str(board.get("_interaction_enabled"))])
		print("   board.parent=%s (%s)  slot rect=%s" % [
			parent.name if parent != null else "<none>",
			"ĐÚNG slot" if parent == slot else "SAI chỗ",
			str((slot as Control).get_global_rect()) if slot != null else "-"])


## Kéo nhân vật 1 bước (thử 4 hướng) để có tiến độ trước khi xoay
func _swipe_once(scene: Node) -> void:
	var board := scene.get("board_view") as Control
	var grid: Node = scene.get("grid_controller")
	if board == null or grid == null:
		return
	var cursor := board.get("_cursor") as Control
	if cursor == null:
		return
	var start := cursor.get_global_rect().get_center()
	# Bề rộng 1 Ô của bàn cờ (khác cỡ con trỏ) — lấy từ board nếu có
	var cell: float = float(board.get("_step")) if board.get("_step") != null else 0.0
	if cell <= 1.0:
		cell = cursor.get_global_rect().size.x
	var before: int = (grid.get("path") as Array).size()
	var seen := [0]
	board.gui_input.connect(func(_e: InputEvent) -> void: seen[0] += 1)
	for dir in [Vector2(cell, 0), Vector2(0, cell), Vector2(-cell, 0), Vector2(0, -cell)]:
		var target: Vector2 = start + dir
		var hit := InputEventScreenTouch.new()
		hit.position = start
		hit.pressed = true
		root.push_input(hit, true)
		await _frames(2)
		var local: Vector2 = board.get_global_transform_with_canvas().affine_inverse() * start
		print("      [dir %s] gui_input=%d · ô bấm(CHỦ ĐỘNG)=%s · đang kéo nhân vật=%s · đang kéo mỏ neo=%s" % [
			str(dir), int(seen[0]), str(board.call("_hit_cell", local)),
			str(board.get("_dragging_player")), str(board.get("_is_dragging_anchor"))])
		var drag := InputEventScreenDrag.new()
		drag.position = target
		root.push_input(drag, true)
		var up := InputEventScreenTouch.new()
		up.position = target
		up.pressed = false
		root.push_input(up, true)
		await _frames(3)
		if (grid.get("path") as Array).size() > before:
			return
