extends SceneTree
## DEV PROBE 2: in SÂU cây node của các thẻ chế độ (Countdown · Fog · Sum Path) để biết
## phần tử nào nằm ở đâu trước khi ẩn/cắt panel.
##   godot --headless --path . -s res://scripts/test_case/dev_probe_hud_sheet.gd

const PATHS := [
	"res://nodes/hud/portrait/game/countdown_hud.tscn",
	"res://nodes/hud/portrait/game/fog_of_war_hud.tscn",
	"res://nodes/hud/portrait/game/sum_path_hud.tscn",
	"res://nodes/hud/portrait/game/dungeon_mode.tscn",
]


func _init() -> void:
	root.size = Vector2i(1080, 1920)
	for path in PATHS:
		var packed := load(path) as PackedScene
		if packed == null:
			continue
		var hud := packed.instantiate()
		root.add_child(hud)
		await process_frame
		await process_frame
		print("\n=== %s  [DỌC]" % path.get_file())
		var info := hud.get_node_or_null("Content/ModeInformation")
		if info != null:
			_walk(info, 1)
		hud.queue_free()
		await process_frame
	quit(0)


func _walk(node: Node, depth: int) -> void:
	for child in node.get_children():
		var c := child as Control
		if c == null:
			continue
		print("%s%-18s %-14s vis=%-5s pos=(%6.0f,%6.0f) size=(%6.0f,%6.0f) min=(%4.0f,%4.0f) anchor=%.2f..%.2f" % [
			"    ".repeat(depth - 1), c.name, c.get_class(), str(c.visible),
			c.position.x, c.position.y, c.size.x, c.size.y,
			c.custom_minimum_size.x, c.custom_minimum_size.y, c.anchor_left, c.anchor_right])
		if depth < 4:
			_walk(c, depth + 1)
