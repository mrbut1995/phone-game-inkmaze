extends SceneTree
## TẠM (refactor Phase 2B): dump giá trị HIỆU DỤNG của màn Main ở 2 bố cục để so trước/sau.
## Chạy: godot --headless --path . --script res://scripts/test_case/dev_probe_main_metrics.gd

const OUT := "user://main_metrics.txt"

var _lines: PackedStringArray = []


func _initialize() -> void:
	_go()


func _go() -> void:
	var screen = load("res://scenes/main.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame

	for dir in ["portrait", "landscape"]:
		var lay = load("res://scenes/layout/%s/main.tscn" % dir).instantiate()
		root.add_child(lay)
		lay.set("size", Vector2(540, 920) if dir == "portrait" else Vector2(1174, 540))
		await process_frame
		screen.set("layout", lay)
		screen.call("_setup_buttons")
		screen.call("_setup_event_buttons")
		await process_frame
		_dump(dir, lay)
		lay.queue_free()
		await process_frame

	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string("\n".join(_lines))
	f.close()
	print("PROBE -> ", ProjectSettings.globalize_path(OUT))
	quit(0)


func _dump(dir: String, lay) -> void:
	_lines.append("========== %s ==========" % dir)
	var body := lay.get_node_or_null("Body") as Control
	if body == null:
		body = lay.get_node_or_null("Scaler/Body") as Control
	if body != null:
		_lines.append("Body.offset_top=%s separation=%s" % [body.offset_top, body.get_theme_constant("separation")])
	_chip("CoinChip", lay.find_child("CoinChip", true, false) as Control)
	_chip("LifeChip", lay.find_child("LifeChip", true, false) as Control)
	var star := lay.find_child("StarChip", true, false) as Control
	if star != null:
		_lines.append("StarChip visible=%s min=%s" % [star.visible, star.custom_minimum_size])
	var sb := lay.get("btn_settings") as TextureButton
	if sb != null:
		_lines.append("Settings min=%s ignore_tex=%s stretch=%s flags_v=%s" % [
			sb.custom_minimum_size, sb.ignore_texture_size, sb.stretch_mode, sb.size_flags_vertical])
		for st in ["normal", "pressed", "hover", "disabled", "focused"]:
			var t = sb.get("texture_" + st)
			_lines.append("  Settings.texture_%s=%s" % [st, t.resource_path if t != null else "<null>"])
	_lines.append("EventHeader.visible=%s" % [lay.get("event_header") != null and (lay.get("event_header") as Control).visible])
	var car: Control = lay.get("event_carousel") as Control
	if car != null:
		_lines.append("EventCarousel.visible=%s" % [car.visible])
	var stamp := lay.get("stamp_panel") as Control
	if stamp != null:
		_lines.append("Stamp.visible=%s  StampParentVisible=%s" % [stamp.visible, stamp.get_parent().visible])
	var dock_shop := lay.get("dock_shop") as Control
	if dock_shop != null:
		var row := dock_shop.get_parent()
		var panel := row.get_parent() as Control
		_lines.append("DockPanel min=%s size=%s children=%d" % [panel.custom_minimum_size, panel.size, row.get_child_count()])
		_lines.append("  Row order=%s" % [str(row.get_children().map(func(c): return c.name))])
		for b in row.get_children():
			_dock_button(b as Control)
	var sec = lay.get("level_section")
	if sec != null:
		var chest := sec.get("chest") as Control
		if chest != null:
			_lines.append("Chest min=%s off=(%s,%s,%s,%s)" % [
				chest.custom_minimum_size, chest.offset_left, chest.offset_top, chest.offset_right, chest.offset_bottom])
		var mp: Node = sec.get("map") as Node
		if mp != null:
			_lines.append("Map.bottom_reserve=%s" % [mp.get("bottom_reserve")])


func _chip(name_: String, chip: Control) -> void:
	if chip == null:
		_lines.append("%s=<null>" % name_)
		return
	_lines.append("%s min=%s visible=%s" % [name_, chip.custom_minimum_size, chip.visible])
	var icon := chip.find_child("Icon", true, false) as Control
	if icon != null:
		_lines.append("  Icon min=%s offsets=(%s,%s,%s,%s)" % [icon.custom_minimum_size,
			icon.offset_left, icon.offset_top, icon.offset_right, icon.offset_bottom])
	var value := chip.find_child("Value", true, false) as Label
	if value != null:
		_lines.append("  Value font=%s variation=%s" % [value.get_theme_font_size("font_size"), value.theme_type_variation])
	var plus := chip.find_child("Plus", true, false) as Control
	if plus != null:
		_lines.append("  Plus min=%s font=%s corner=%s" % [plus.custom_minimum_size,
			(plus as Button).get_theme_font_size("font_size"), _corner(plus)])


func _corner(b: Control) -> String:
	var st := b.get_theme_stylebox("normal")
	if st is StyleBoxFlat:
		return str((st as StyleBoxFlat).corner_radius_top_left)
	if st is StyleBoxTexture:
		return "tex"
	return "<%s>" % (st.get_class() if st != null else "null")


func _dock_button(b: Control) -> void:
	if b == null:
		return
	_lines.append("  DockBtn %s min=%s variation=%s flags_v=%s visible=%s" % [
		b.name, b.custom_minimum_size, b.theme_type_variation, b.size_flags_vertical, b.visible])
	var icon := b.get_node_or_null("Icon") as Control
	if icon != null:
		_lines.append("    Icon off=(%s,%s,%s,%s) tex=%s" % [icon.offset_left, icon.offset_top,
			icon.offset_right, icon.offset_bottom,
			(icon as TextureRect).texture.resource_path if (icon as TextureRect).texture != null else "<null>"])
	var lbl := b.get_node_or_null("Label") as Label
	if lbl != null:
		_lines.append("    Label off=(%s,%s,%s,%s) font=%s color=%s outline=%s osize=%s vary=%s text=%s" % [
			lbl.offset_left, lbl.offset_top, lbl.offset_right, lbl.offset_bottom,
			lbl.get_theme_font_size("font_size"), lbl.get_theme_color("font_color"),
			lbl.get_theme_color("font_outline_color"), lbl.get_theme_constant("outline_size"),
			lbl.theme_type_variation, lbl.text])
	for st in ["normal", "hover", "pressed", "focus"]:
		var box := b.get_theme_stylebox(st)
		var desc := "<null>"
		if box is StyleBoxTexture:
			var tex := box as StyleBoxTexture
			desc = "tex %s m=(%s,%s,%s,%s)" % [tex.texture.resource_path if tex.texture != null else "<null>",
				tex.texture_margin_left, tex.texture_margin_top, tex.texture_margin_right, tex.texture_margin_bottom]
		elif box is StyleBoxFlat:
			desc = "flat bg=%s r=%s" % [(box as StyleBoxFlat).bg_color, (box as StyleBoxFlat).corner_radius_top_left]
		elif box is StyleBoxEmpty:
			desc = "empty"
		_lines.append("    style.%s=%s" % [st, desc])
