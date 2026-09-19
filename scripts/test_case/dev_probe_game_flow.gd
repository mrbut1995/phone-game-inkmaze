extends SceneTree
## DEV: đi ĐÚNG luồng người chơi (Main → CHOI → màn Game) rồi kiểm tra xem input có bị chặn không
## (màn loading/InputBlocker còn sót, popup Dim, hay node nào ăn sự kiện trên cùng).
##   godot --path . --rendering-driver opengl3 --script res://scripts/test_case/dev_probe_game_flow.gd

const SIZES := [Vector2i(1080, 1920), Vector2i(1920, 1080)]
const MODES := ["play", "dungeon", "minesweeper"]


func _initialize() -> void:
	_run.call_deferred()


func _frames(n: int) -> void:
	for _i in n:
		await process_frame


func _run() -> void:
	TranslationServer.set_locale("vi")
	for size in SIZES:
		DisplayServer.window_set_size(size)
		await _frames(4)
		for mode in MODES:
			await _flow(size, mode)
	quit()


func _flow(size: Vector2i, mode: String) -> void:
	var gm: Node = root.get_node_or_null("GameManager")
	if gm != null:
		gm.set("current_mode", mode)
		gm.set("current_level", 1)
	var main: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	current_scene = main
	await _frames(6)
	Nav.goto_game()
	await _frames(90)
	var scene := current_scene
	print("\n=== %dx%d  mode=%s  scene=%s  paused=%s" % [size.x, size.y, mode,
		scene.scene_file_path if scene != null else "<null>", str(paused)])
	if scene == null:
		return
	_check_overlays()
	var board := scene.get("board_view") as Control
	var gc: Node = scene.get("game_controller")
	if gc != null:
		print("   _run_active=%s" % str(gc.get("_run_active")))
	_check_controller_layout(scene, "game_controller", gc)
	_check_controller_layout(scene, "grid_controller", scene.get("grid_controller"))
	_check_controller_layout(scene, "tool_controller", scene.get("tool_controller"))
	_check_controller_layout(scene, "ui_controller", scene.get("ui_controller"))
	var tool_ctrl: Node = scene.get("tool_controller")
	if tool_ctrl != null:
		var bound := tool_ctrl.get("tool_path_btn") as Control
		print("   tool_controller.tool_path_btn = %s visible=%s" % [
			_path(bound) if bound != null else "<null>",
			str(bound.is_visible_in_tree()) if bound != null else "-"])
	if board != null:
		print("   board rect=%s interaction=%s" % [str(board.get_global_rect()),
			str(board.get("_interaction_enabled"))])
		_probe_point(board.get_global_rect().get_center(), "TÂM BÀN CỜ")
		_sweep_board(board)
	var tool: Control = scene.get("tool_path_btn") as Control
	if tool != null:
		_probe_point(tool.get_global_rect().get_center(), "NÚT VẼ ĐƯỜNG (HUD)")
	_sweep_canvas()
	# 1. Có swipe được không (mô phỏng đúng sự kiện cảm ứng như trên máy thật)
	await _swipe_test(scene, "ban đầu")
	# 2. XOAY màn hình giữa ván rồi kiểm tra lại (case người dùng hay gặp)
	DisplayServer.window_set_size(Vector2i(1080, 1920) if size.x > size.y else Vector2i(1920, 1080))
	await _frames(25)
	print("   --- sau khi XOAY: landscape=%s active=%s" % [str(scene.get("is_landscape")),
		str((scene.call("active_layout") as Node).name)])
	_check_controller_layout(scene, "game_controller", scene.get("game_controller"))
	_check_controller_layout(scene, "grid_controller", scene.get("grid_controller"))
	_check_controller_layout(scene, "tool_controller", scene.get("tool_controller"))
	_check_controller_layout(scene, "ui_controller", scene.get("ui_controller"))
	var tool2: Control = scene.get("tool_path_btn") as Control
	if tool2 != null:
		print("   tool_path_btn sau xoay = %s visible=%s" % [_path(tool2),
			str(tool2.is_visible_in_tree())])
	await _swipe_test(scene, "sau xoay")
	if scene != null:
		scene.queue_free()
	current_scene = null
	await _frames(4)


## Quét TOÀN canvas: node nào đang là "trên cùng" ở từng vùng (thống kê theo tên)
## — node lạ chiếm nhiều điểm = lớp đang chặn input.
func _sweep_canvas() -> void:
	var canvas := root.get_visible_rect().size
	var tally: Dictionary = {}
	for iy in 16:
		for ix in 9:
			var p := Vector2(canvas.x * (float(ix) + 0.5) / 9.0, canvas.y * (float(iy) + 0.5) / 16.0)
			var hits: Array[String] = []
			_collect(root, p, hits)
			var top: String = hits[hits.size() - 1].split(" rect=")[0] if not hits.is_empty() else "<none>"
			tally[top] = int(tally.get(top, 0)) + 1
	print("   --- Vùng input TRÊN CÙNG (144 điểm quét):")
	for key in tally.keys():
		print("      %3d điểm → %s" % [tally[key], key])


## Mô phỏng 1 cú KÉO từ đúng ô nhân vật (đường đi thật của người chơi) — thử 4 hướng,
## hướng nào không có tường thì nhân vật phải đi được.
func _swipe_test(scene: Node, label: String) -> void:
	var board := scene.get("board_view") as Control
	var gc: Node = scene.get("game_controller")
	if board == null or gc == null:
		return
	var state: Object = gc.get("game_state")
	if state == null:
		return
	var cursor := board.get("_cursor") as Control
	var start: Vector2 = cursor.get_global_rect().get_center() if cursor != null \
		else board.get_global_rect().get_center()
	var cell: float = cursor.get_global_rect().size.x if cursor != null else 60.0
	var before: int = state.get("path").size()
	var moved := ""
	for dir in [Vector2(cell, 0), Vector2(0, cell), Vector2(-cell, 0), Vector2(0, -cell)]:
		var target: Vector2 = start + dir
		var hit := InputEventScreenTouch.new()
		hit.position = start
		hit.pressed = true
		root.push_input(hit)
		var drag := InputEventScreenDrag.new()
		drag.position = target
		root.push_input(drag)
		var release := InputEventScreenTouch.new()
		release.position = target
		release.pressed = false
		root.push_input(release)
		await _frames(3)
		if state.get("path").size() > before:
			moved = "hướng %s" % str(dir)
			break
	print("   SWIPE (%s) từ (%.0f,%.0f) ô=%.0f: path %d → %d  %s" % [label, start.x, start.y, cell,
		before, state.get("path").size(),
		("OK (" + moved + ")") if moved != "" else "⚠ KHÔNG DI CHUYỂN ĐƯỢC"])


## Quét nhiều điểm trên bàn cờ: điểm nào KHÔNG trỏ vào Board = có node khác nằm trên (chặn swipe)
func _sweep_board(board: Control) -> void:
	var r := board.get_global_rect()
	var bad: Array[String] = []
	for iy in 5:
		for ix in 5:
			var p := Vector2(r.position.x + r.size.x * (0.1 + 0.2 * ix),
				r.position.y + r.size.y * (0.1 + 0.2 * iy))
			var hits: Array[String] = []
			_collect(root, p, hits)
			var top := hits[hits.size() - 1] if not hits.is_empty() else "<không có>"
			if not top.begins_with("Scene/Portrait/Board") and not top.begins_with("Scene/Landscape/Board"):
				bad.append("(%.0f,%.0f) → %s" % [p.x, p.y, top])
	if bad.is_empty():
		print("   25 điểm trên bàn cờ: OK (mọi điểm đều vào Board)")
	else:
		print("   ⚠ %d/25 điểm bị node khác chặn:" % bad.size())
		for line in bad:
			print("      %s" % line)


## Các lớp phủ toàn màn hình còn sót (loading/transition/popup)
func _check_overlays() -> void:
	for child in root.get_children():
		var cl := child as CanvasLayer
		if cl != null:
			var c := cl as Node
			print("   CanvasLayer: %s visible=%s" % [_path(c), str(c.get("visible"))])
			_scan_input_blockers(c, 0)
		elif not (child is Window):
			_scan_input_blockers(child, 0)


func _scan_input_blockers(node: Node, depth: int) -> void:
	for child in node.get_children():
		var c := child as Control
		if c != null:
			if c.is_visible_in_tree() and c.mouse_filter == Control.MOUSE_FILTER_STOP \
					and c.get_global_rect().size.x > 500.0 and c.get_global_rect().size.y > 500.0:
				print("   ⚠ node lớn ăn input: %s rect=%s" % [_path(c), str(c.get_global_rect())])
			_scan_input_blockers(c, depth + 1)
		else:
			_scan_input_blockers(child, depth + 1)


func _probe_point(point: Vector2, label: String) -> void:
	var hits: Array[String] = []
	_collect(root, point, hits)
	print("   %s @ (%.0f,%.0f) — %d node ăn input:" % [label, point.x, point.y, hits.size()])
	for i in hits.size():
		print("      [%d] %s%s" % [i, hits[i], "   <-- TRÊN CÙNG" if i == hits.size() - 1 else ""])


func _collect(node: Node, point: Vector2, out: Array[String]) -> void:
	for child in node.get_children():
		var c := child as Control
		if c != null:
			if not c.is_visible_in_tree():
				continue
			if c.mouse_filter != Control.MOUSE_FILTER_IGNORE and c.get_global_rect().has_point(point):
				out.append("%s rect=%s filter=%d" % [_path(c), str(c.get_global_rect()), c.mouse_filter])
			_collect(c, point, out)
		else:
			_collect(child, point, out)


## Controller phải thuộc ĐÚNG layout đang hiển thị — nếu thuộc layout ẨN thì mọi nút/sự kiện
## sẽ nối vào UI không nhìn thấy ⇒ bấm không ăn, kéo bàn cờ không chạy.
func _check_controller_layout(scene: Node, label: String, node: Node) -> void:
	if node == null:
		print("   %s = <null>" % label)
		return
	var active: Node = scene.call("active_layout")
	var owner_layout := _layout_owner(scene, node)
	print("   %s thuộc layout=%s (đang hiển thị=%s) %s" % [label, owner_layout, active.name,
		"OK" if owner_layout == active.name else "⚠ SAI LAYOUT"])


func _layout_owner(scene: Node, node: Node) -> String:
	var cur: Node = node.get_parent()
	while cur != null and cur.get_parent() != scene:
		cur = cur.get_parent()
	return cur.name if cur != null else "<ngoài scene>"


func _path(n: Node) -> String:
	var parts: Array[String] = []
	var cur: Node = n
	while cur != null and not (cur is Window):
		parts.push_front(cur.name)
		cur = cur.get_parent()
	return "/".join(parts)


var pid := 0
