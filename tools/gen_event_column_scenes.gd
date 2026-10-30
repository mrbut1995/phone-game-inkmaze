extends SceneTree
## Oracle sinh resource/scene chuẩn format cho cột nút Event (chạy 1 lần):
##   godot --headless --path . --script res://tools/gen_event_column_scenes.gd

const STYLE_PATH := "res://resources/settings/styles/event/pill.tres"
const ITEM_PATH := "res://nodes/main/event_button_item.tscn"
const COLUMN_PATH := "res://nodes/main/event_button_column.tscn"


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://resources/settings/styles/event"))
	var box := StyleBoxFlat.new()
	box.bg_color = Color.WHITE
	box.border_color = Color("E4DCC6")
	box.set_border_width_all(2)
	box.set_corner_radius_all(9)
	box.content_margin_left = 6.0
	box.content_margin_right = 6.0
	box.content_margin_top = 0.0
	box.content_margin_bottom = 0.0
	print("style err=", ResourceSaver.save(box, STYLE_PATH))
	_build_item()
	_build_column()
	quit()


func _build_item() -> void:
	var root := VBoxContainer.new()
	root.name = "EventButtonItem"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_theme_constant_override("separation", 1)

	var icon := TextureButton.new()
	icon.name = "Icon"
	icon.ignore_texture_size = true
	icon.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(58.0, 58.0 * 216.0 / 209.0)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	root.add_child(icon)

	var pill := PanelContainer.new()
	pill.name = "Pill"
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pill.add_theme_stylebox_override("panel", load(STYLE_PATH))
	root.add_child(pill)

	var label := Label.new()
	label.name = "Label"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color("164663"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pill.add_child(label)

	_pack(root, ITEM_PATH)


func _build_column() -> void:
	var root := VBoxContainer.new()
	root.name = "EventButtonColumn"
	root.set_script(load("res://scripts/nodes/main/event_button_column.gd"))
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_theme_constant_override("separation", 6)
	root.anchor_left = 1.0
	root.anchor_right = 1.0
	root.anchor_top = 0.0
	root.anchor_bottom = 0.0
	root.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	root.grow_vertical = Control.GROW_DIRECTION_END
	root.offset_left = -76.0
	root.offset_right = -4.0
	root.offset_top = 10.0
	root.offset_bottom = 10.0

	var timer := Timer.new()
	timer.name = "Refresh"
	timer.wait_time = 20.0
	timer.autostart = true
	root.add_child(timer)

	_pack(root, COLUMN_PATH)


func _pack(root: Node, path: String) -> void:
	_set_owner_recursive(root, root)
	var scene := PackedScene.new()
	var e := scene.pack(root)
	print(path, " pack=", e, " save=", ResourceSaver.save(scene, path))
	root.free()


func _set_owner_recursive(n: Node, owner: Node) -> void:
	for c in n.get_children():
		c.owner = owner
		_set_owner_recursive(c, owner)
