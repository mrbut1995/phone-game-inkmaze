extends SceneTree
## DEV PROBE: in ra cây node của `Content/ModeInformation` trong MỌI scene HUD (bản dọc)
## để quyết định ẩn/dời thẻ nào cho gọn (xem yêu cầu "chỉ hiện thứ cần thiết").
##   godot --headless --path . -s res://scripts/test_case/dev_probe_hud_layout.gd

const FOLDERS := ["res://nodes/hud/portrait/game"]


func _init() -> void:
	root.size = Vector2i(1080, 1920)
	for folder in FOLDERS:
		var dir := DirAccess.open(folder)
		if dir == null:
			continue
		for file_name in dir.get_files():
			if not file_name.ends_with(".tscn"):
				continue
			var packed := load("%s/%s" % [folder, file_name]) as PackedScene
			if packed == null:
				continue
			var hud := packed.instantiate()
			root.add_child(hud)
			await process_frame
			await process_frame
			var info := hud.get_node_or_null("Content/ModeInformation")
			print("\n=== %s  (DỌC · ModeInformation %s %.0fx%.0f @%.0f,%.0f)" % [
				file_name,
				info.get_class() if info != null else "KHONG CO",
				info.size.x if info != null else 0.0, info.size.y if info != null else 0.0,
				info.position.x if info != null else 0.0, info.position.y if info != null else 0.0])
			if info != null:
				for child in info.get_children():
					var c := child as Control
					if c == null:
						continue
					print("    %-16s %-14s vis=%-5s pos=(%6.0f,%6.0f) size=(%6.0f,%6.0f) anchor=%.2f..%.2f" % [
						c.name, c.get_class(), str(c.visible), c.position.x, c.position.y,
						c.size.x, c.size.y, c.anchor_left, c.anchor_right])
			hud.queue_free()
			await process_frame
	quit(0)
