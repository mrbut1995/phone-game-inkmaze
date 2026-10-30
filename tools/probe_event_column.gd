extends SceneTree
## Probe A/B cho EventButtonColumn: dump giá trị HIỆU DỤNG của cột + từng nút + viên thuốc + label.
## Chạy: godot --headless --path . --script res://tools/probe_event_column.gd

class FakeEvent extends RefCounted:
	var id: StringName = &""
	var theme_id: String = ""
	var theme: Variant = null

	func _init(p_id: StringName) -> void:
		id = p_id


var _frames := 0
var _node: Control


func _initialize() -> void:
	if ResourceLoader.exists("res://nodes/main/event_button_column.tscn"):
		_node = load("res://nodes/main/event_button_column.tscn").instantiate() as Control
	else:
		_node = load("res://scripts/nodes/main/event_button_column.gd").new() as Control
	_node.name = "EventButtons"
	var host := Control.new()
	host.size = Vector2(420, 500)
	root.add_child(host)
	host.add_child(_node)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames < 2:
		return false
	_dump()
	quit()
	return true


func _dump() -> void:
	var out: Array[String] = []
	var fake: Array = [FakeEvent.new(&"anniversary"), FakeEvent.new(&"tet_2026")]
	_node.call("set_events", fake, null)
	out.append("COLUMN rect=%s anchors=(%s,%s,%s,%s) grow=(%s,%s) sep=%s mouse=%s visible=%s" % [
		str(_node.get_rect()), str(_node.anchor_left), str(_node.anchor_right), str(_node.anchor_top),
		str(_node.anchor_bottom), str(_node.grow_horizontal), str(_node.grow_vertical),
		str(_node.get_theme_constant("separation")), str(_node.mouse_filter), str(_node.visible)])
	var area := Control.new()
	area.size = Vector2(300, 300)
	root.add_child(area)
	_node.call("reserve_gutter", area)
	out.append("GUTTER offset_left=%s offset_right=%s" % [str(area.offset_left), str(area.offset_right)])
	_node.call("set_events", [], null)
	_node.call("reserve_gutter", area)
	out.append("GUTTER(empty) offset_left=%s offset_right=%s visible=%s" % [
		str(area.offset_left), str(area.offset_right), str(_node.visible)])
	_node.call("set_events", fake, null)
	for i in _node.get_child_count():
		var item := _node.get_child(i)
		if not (item is Control):
			out.append("  child%d name=%s type=%s" % [i, item.name, item.get_class()])
			continue
		out.append("  child%d name=%s type=%s rect=%s min=%s mouse=%s sep=%s" % [
			i, item.name, item.get_class(), str(item.get_rect()), str(item.custom_minimum_size),
			str(item.mouse_filter), str(item.get_theme_constant("separation") if item is BoxContainer else -1)])
		for j in item.get_child_count():
			var sub := item.get_child(j)
			out.append("    sub%d name=%s type=%s rect=%s min=%s flags_h=%s mouse=%s" % [
				j, sub.name, sub.get_class(), str(sub.get_rect()), str(sub.custom_minimum_size),
				str(sub.size_flags_horizontal), str(sub.mouse_filter)])
			if sub is TextureButton:
				out.append("      btn tex_n=%s tex_p=%s tex_d=%s ignore=%s stretch=%s cursor=%s" % [
					_text(sub.texture_normal), _text(sub.texture_pressed), _text(sub.texture_disabled),
					str(sub.ignore_texture_size), str(sub.stretch_mode), str(sub.mouse_default_cursor_shape)])
			if sub is PanelContainer:
				var box := sub.get_theme_stylebox("panel") as StyleBoxFlat
				out.append("      pill stylebox=%s" % _style_desc(box))
			for k in sub.get_child_count():
				var leaf := sub.get_child(k)
				out.append("      leaf name=%s type=%s text=%s font=%s color=%s align=%s mouse=%s" % [
					leaf.name, leaf.get_class(), str(leaf.get("text")),
					str(leaf.get_theme_font_size("font_size")), str(leaf.get_theme_color("font_color")),
					str(leaf.get("horizontal_alignment")), str(leaf.mouse_filter)])
	var path := "user://probe_event_column.txt"
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("\n".join(out))
	f.close()
	print("WROTE ", ProjectSettings.globalize_path(path))


func _text(t: Variant) -> String:
	return "<null>" if t == null else str((t as Resource).resource_path)


func _style_desc(box: StyleBoxFlat) -> String:
	if box == null:
		return "<null>"
	return "bg=%s border=%s bw=%s/%s/%s/%s cr=%s/%s/%s/%s cm=%s/%s/%s/%s" % [
		str(box.bg_color), str(box.border_color),
		str(box.border_width_left), str(box.border_width_top), str(box.border_width_right), str(box.border_width_bottom),
		str(box.corner_radius_top_left), str(box.corner_radius_top_right),
		str(box.corner_radius_bottom_right), str(box.corner_radius_bottom_left),
		str(box.content_margin_left), str(box.content_margin_top), str(box.content_margin_right), str(box.content_margin_bottom)]
