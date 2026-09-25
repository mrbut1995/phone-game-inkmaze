extends SceneTree
## DEV: gửi sự kiện CHUỘT thật (như người dùng) vào màn chơi và đo xem node nào nhận được
## (`board.gui_input` / nút `pressed`) — xác định input có bị lớp nào chặn không.
##   godot --path . --rendering-driver opengl3 --script res://scripts/test_case/dev_probe_input_delivery.gd

var _board_events := 0
var _btn_events := 0
var _drag_events := 0


func _initialize() -> void:
	_run.call_deferred()


func _frames(n: int) -> void:
	for _i in n:
		await process_frame


func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1080, 1920))
	await _frames(6)
	TranslationServer.set_locale("vi")
	var gm: Node = root.get_node_or_null("GameManager")
	if gm != null:
		gm.set("current_mode", "play")
		gm.set("current_level", 1)
	var scene: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await _frames(10)

	var board := scene.get("board_view") as Control
	var grid: Node = scene.get("grid_controller")
	var tool := scene.get("tool_path_btn") as Control
	if board != null:
		board.gui_input.connect(func(_e: InputEvent) -> void: _board_events += 1)
	if tool != null:
		(tool as BaseButton).pressed.connect(func() -> void: _btn_events += 1)

	var cursor := board.get("_cursor") as Control
	var start: Vector2 = cursor.get_global_rect().get_center()
	var cell: float = cursor.get_global_rect().size.x
	print("board=%s  cursor tại (%.0f,%.0f)  ô=%.0f px" % [_path(board), start.x, start.y, cell])
	var local: Vector2 = board.get_global_transform_with_canvas().affine_inverse() * start
	print("   local=%.0f,%.0f · _hit_cell=%s · _player_current_cell=%s" % [local.x, local.y,
		str(board.call("_hit_cell", local)), str(board.get("_player_current_cell"))])
	board.drag_updated.connect(func(_c: Vector2i) -> void: _drag_events += 1)
	print("   drag_updated nối tới %d đích:" % board.drag_updated.get_connections().size())
	for c in board.drag_updated.get_connections():
		var obj: Object = c.get("callable").get_object()
		print("   LISTENER: %s . %s" % [_path(obj as Node) if obj is Node else str(obj),
			str(c.get("callable").get_method())])
	print("   grid_controller: node=%s current_pos=%s maze_null=%s mode_null=%s path=%s" % [
		_path(grid) if grid != null else "<null>", str(grid.get("current_pos")) if grid != null else "-",
		str(grid.get("maze") == null) if grid != null else "-",
		str(grid.get("game_mode") == null) if grid != null else "-",
		str(grid.get("path")) if grid != null else "-"])
	# Bộ controller + bàn cờ nay DÙNG CHUNG (ở scene gốc) — mỗi bố cục chỉ còn UI + BoardSlot
	var gmc: Node = scene.get("game_mode_controller")
	print("   Controllers dùng chung: GameModeController.game_mode=%s · GridController.maze_null=%s" % [
		str(gmc.get("game_mode")) if gmc else "<none>",
		str(grid.get("maze") == null) if grid != null else "-"])
	for layout_name in ["Portrait"]:
		var holder := scene.get_node_or_null(layout_name)
		var slot: Node = holder.get_node_or_null("BoardSlot") if holder else null
		print("   %-9s: visible=%s · BoardSlot=%s" % [
			layout_name,
			str((holder as CanvasItem).is_visible_in_tree()) if holder else "-",
			str(slot != null)])
	# Bấm thử 1 lần rồi soi trạng thái nội bộ của Board
	_send("push_input", start, true)
	await _frames(2)
	print("   SAU KHI BẤM: _dragging_player=%s _pressed_cell=%s _is_dragging_anchor=%s" % [
		str(board.get("_dragging_player")), str(board.get("_pressed_cell")),
		str(board.get("_is_dragging_anchor"))])
	var target1: Vector2 = start + Vector2(cell, 0)
	_send("push_input", target1, true, true)
	await _frames(2)
	print("   SAU KHI KÉO 1 Ô: drag_updated=%d · path=%d" % [_drag_events,
		(grid.get("path") as Array).size()])
	_send("push_input", target1, false)
	await _frames(2)
	# Thử gọi TRỰC TIẾP controller: nếu cũng không đi được thì lỗi ở luật/maze, nếu đi được thì lỗi ở dây nối
	for dir_v in [Vector2i(1, 1), Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 2)]:
		grid.call("try_move_to", dir_v)
		await _frames(2)
	print("   GỌI TRỰC TIẾP try_move_to: current_pos=%s path=%s" % [str(grid.get("current_pos")),
		str(grid.get("path"))])

	for kind in ["push_input", "Input.parse_input_event"]:
		_board_events = 0
		var before: int = (grid.get("path") as Array).size()
		for dir_v in [Vector2(cell, 0), Vector2(0, cell), Vector2(-cell, 0), Vector2(0, -cell)]:
			var target: Vector2 = start + dir_v
			_send(kind, start, true)
			_send(kind, target, true, true)
			_send(kind, target, false)
			await _frames(3)
			if (grid.get("path") as Array).size() > before:
				break
		print("   %-24s : board nhận %d gui_input · path %d → %d %s" % [kind, _board_events, before,
			(grid.get("path") as Array).size(),
			"OK" if (grid.get("path") as Array).size() > before else "⚠ KHÔNG DI CHUYỂN"])

	if tool != null:
		_btn_events = 0
		_click(tool.get_global_rect().get_center())
		await _frames(3)
		print("   BẤM NÚT Tool (%s) : nhận %s tín hiệu pressed" % [_path(tool),
			"OK %d" % _btn_events if _btn_events > 0 else "⚠ 0"])
	var undo := scene.get("undo_btn") as Control
	if undo != null:
		_btn_events = 0
		_click(undo.get_global_rect().get_center())
		await _frames(3)
		print("   BẤM NÚT Undo (%s) : nhận %s tín hiệu pressed" % [_path(undo),
			"OK %d" % _btn_events if _btn_events > 0 else "⚠ 0"])
	quit()


func _send(kind: String, pos: Vector2, pressed: bool, is_drag := false) -> void:
	var ev: InputEvent
	if is_drag:
		var drag := InputEventScreenDrag.new()
		drag.position = pos
		ev = drag
	else:
		var touch := InputEventScreenTouch.new()
		touch.position = pos
		touch.pressed = pressed
		ev = touch
	if kind == "push_input":
		root.push_input(ev)
	else:
		Input.parse_input_event(ev)


func _click(pos: Vector2) -> void:
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = pressed
		ev.position = pos
		ev.global_position = pos
		root.push_input(ev)


func _path(n: Node) -> String:
	var parts: Array[String] = []
	var cur: Node = n
	while cur != null and not (cur is Window):
		parts.push_front(cur.name)
		cur = cur.get_parent()
	return "/".join(parts)
