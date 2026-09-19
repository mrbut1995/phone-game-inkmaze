extends SceneTree
## DEV: kiểm tra hàng nhiệm vụ màn Daily có nằm ĐÚNG trong `Slot1..Slot4` của scene không.
##   godot --path . --rendering-driver opengl3 --script res://scripts/test_case/dev_probe_daily_slots.gd

const SIZES := [Vector2i(1080, 1920), Vector2i(1080, 1440), Vector2i(1920, 1080)]


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
		var scene: Node = (load("res://scenes/daily.tscn") as PackedScene).instantiate()
		root.add_child(scene)
		await _frames(8)
		_dump(scene, size)
		scene.queue_free()
		await _frames(3)
	quit()


func _dump(scene: Node, size: Vector2i) -> void:
	print("=== %dx%d  canvas=%s  landscape=%s" % [size.x, size.y,
		str(root.get_visible_rect().size), str(scene.get("is_landscape"))])
	var rows_host := scene.call("ui", "Rows") as Control
	if rows_host == null:
		print("   !! thiếu node Rows")
		return
	for i in 4:
		var slot := rows_host.get_node_or_null("Slot%d" % (i + 1)) as Control
		var row := scene.call("row_at", i) as Control
		var slot_rect := "THIẾU" if slot == null else str(Rect2(slot.global_position, slot.size))
		if row == null:
			print("   Slot%d %s  →  Row: THIẾU" % [i + 1, slot_rect])
			continue
		var inside := slot != null and Rect2(slot.global_position, slot.size)\
			.encloses(Rect2(row.global_position, row.size))
		print("   Slot%d %s  →  Row%s in slot=%s parent=%s" % [i + 1, slot_rect,
			str(Rect2(row.global_position, row.size)), str(inside), row.get_parent().name])
