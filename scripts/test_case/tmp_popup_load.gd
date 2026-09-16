extends SceneTree

# Kiem tra nhanh 9 scene popup huong dan: nap, instance, cau truc co ban.
const MODES := ["normal_maze", "dungeon", "minesweeper", "sumpath", "countdowncost",
		"fadingink", "blindmemory", "fog_of_war", "time_attack"]

func _init() -> void:
	var fails := 0
	for m in MODES:
		var path := "res://nodes/popups/instruction/%s.tscn" % m
		var ps: PackedScene = load(path)
		if ps == null:
			print("[FAIL] khong nap duoc ", path)
			fails += 1
			continue
		var inst: Node = ps.instantiate()
		get_root().add_child(inst)
		var pages := inst.get_node_or_null("Panel/Guide/Pages")
		var n := pages.get_child_count() if pages != null else -1
		var panel := inst.get_node_or_null("Panel")
		var offsets := [panel.offset_left, panel.offset_top, panel.offset_right, panel.offset_bottom] if panel != null else []
		var p1 := inst.get_node_or_null("Panel/Guide/Pages/Page1")
		var kids := []
		if p1 != null:
			for c in p1.get_children():
				kids.append(c.name)
		print(m, " pages=", n, " panel=", offsets, " page1kids=", kids.size())
		var ok := n == 3 and offsets.size() == 4 \
				and is_equal_approx(offsets[0], 80.0) and is_equal_approx(offsets[1], 200.0) \
				and is_equal_approx(offsets[2], 1000.0) and is_equal_approx(offsets[3], 1680.0)
		if not ok:
			print("   [FAIL] cau truc sai")
			fails += 1
		inst.queue_free()
	print("fails=", fails)
	quit(1 if fails > 0 else 0)
