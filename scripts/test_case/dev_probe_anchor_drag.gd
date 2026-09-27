extends SceneTree
## DEV: kiểm tra KÉO NỐI ANCHOR (tạo Tường Nghi Ngờ) có hoạt động không — bỏ qua đường GUI,
## gọi thẳng `BoardView._handle_press_release()` để tách lỗi LOGIC BÀN CỜ khỏi lỗi ĐỊNH TUYẾN SỰ KIỆN.
##   godot --headless --path . -s res://scripts/test_case/dev_probe_anchor_drag.gd


func _initialize() -> void:
	_run.call_deferred()


func _frames(n: int) -> void:
	for _i in n:
		await process_frame


func _run() -> void:
	var gm: Node = root.get_node_or_null("GameManager")
	if gm != null:
		gm.set("current_mode", "play")
		gm.set("current_level", 1)
	var scene: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await _frames(10)

	var board: Node = scene.get("board_view")
	var infos: Array = board.get("_anchor_nodes")
	print("anchor count = %d" % infos.size())
	var first := infos[0] as Dictionary
	var node: Control = first.node
	var corner: Vector2i = first.corner
	print("anchor[0] corner=%s pos=%s size=%s" % [str(corner), str(node.position), str(node.size)])

	# Nhấn vào TÂM anchor (toạ độ local của Board), rồi thả — không qua GUI
	var center: Vector2 = node.position + node.size * 0.5
	board.call("_handle_press_release", true, center)
	await _frames(2)
	print("after press: dragging=%s src_id=%s" % [
		str(board.get("_is_dragging_anchor")), str(board.get("_drag_source_anchor_id"))])
	var guide: Line2D = board.get("_drag_guide_line")
	print("guide visible=%s points=%d" % [str(guide.visible), guide.points.size()])
	board.call("_handle_press_release", false, center)
	await _frames(2)
	print("after release: dragging=%s" % str(board.get("_is_dragging_anchor")))

	# Quét TOÀN BỘ anchor: tâm nào KHÔNG nhấn trúng (hit radius quá nhỏ / lệch toạ độ)?
	var miss := 0
	for info in infos:
		var n: Control = info.node
		var c := n.position + n.size * 0.5
		if (board.call("_hit_anchor_info", c) as Dictionary).is_empty():
			miss += 1
	print("anchor nhan khong trung: %d / %d" % [miss, infos.size()])
	print("hit_radius = %.1f | anchor_size = %.1f | fit_scale = %.3f" % [
		float(board.get("_anchor_hit_radius")), float(board.get("_anchor_size")),
		float(board.get("_fit_scale"))])

	scene.queue_free()
	await _frames(3)
	quit()
