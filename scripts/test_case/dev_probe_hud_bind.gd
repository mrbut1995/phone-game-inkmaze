extends SceneTree
## DEV PROBE: in ra giá trị các `@export` node của vài scene HUD để tìm scene chưa bind.
##   godot --headless --path . -s res://scripts/test_case/dev_probe_hud_bind.gd

const PATHS := [
	"res://nodes/hud/portrait/game/game_hud.tscn",
	"res://nodes/hud/portrait/game/level_mode.tscn",
	"res://nodes/hud/portrait/game/sum_path_hud.tscn",
	"res://nodes/hud/portrait/game/countdown_hud.tscn",
]


func _init() -> void:
	for path in PATHS:
		var packed := load(path) as PackedScene
		if packed == null:
			print("%s: KHONG LOAD DUOC" % path)
			continue
		var node := packed.instantiate()
		var script: Script = node.get_script()
		print("\n=== %s" % path)
		print("    script = %s" % (script.resource_path if script != null else "<null>"))
		for prop in script.get_script_property_list() if script != null else []:
			if prop.hint != PROPERTY_HINT_NODE_TYPE:
				continue
			var value: Variant = node.get(prop.name)
			print("    %-28s hint=%d -> %s" % [prop.name, prop.hint,
				str(value) if value != null else "NULL"])
		node.free()
	quit(0)
