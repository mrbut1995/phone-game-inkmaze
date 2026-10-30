extends SceneTree
## Probe: dock kiểu "J" sau khi dựng scene (art + focus) — chạy headless:
##   godot --headless --path . --script res://tools/probe_dock_j.gd

var _frame := 0
var _main: Node = null
var _fails: Array[String] = []
var _checks := 0
var _pressed: Control = null


func _initialize() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fails.append("không nạp được res://scenes/main.tscn")
		return
	_main = packed.instantiate()
	root.add_child(_main)


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < 3:
		return false
	if _frame == 3:
		_check_static()
		if _pressed != null:
			_pressed.button_down.emit()
	elif _frame == 20:
		_check_focus()
	elif _frame > 20:
		_report()
		return true
	return false


func _check(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_fails.append(msg)


## Nút dock của bố cục ĐANG HIỆN (main.tscn chứa cả Portrait + Landscape)
func _dock_buttons() -> Array:
	var out: Array = []
	for child in _main.find_children("*", "DockButton", true, false):
		var c := child as Control
		if c != null and c.is_visible_in_tree():
			out.append(c)
	return out


func _check_static() -> void:
	var buttons := _dock_buttons()
	_check(buttons.size() == 4, "phải có 4 nút dock đang hiện, thực tế %d" % buttons.size())
	for b in buttons:
		if _pressed == null:
			_pressed = b
		var key := String(b.get_meta("dock_key", ""))
		_check(key != "", "%s thiếu meta dock_key" % b.name)
		var art := b.get_node_or_null("TabArt") as TextureRect
		var focus := b.get_node_or_null("TabArtFocus") as TextureRect
		_check(art != null, "%s thiếu node TabArt" % b.name)
		_check(focus != null, "%s thiếu node TabArtFocus" % b.name)
		if art != null:
			_check(art.texture != null, "%s: TabArt chưa nạp art (%s)" % [b.name, key])
			_check(is_equal_approx(art.modulate.a, 1.0), "%s: TabArt phải hiện khi chưa focus" % b.name)
		if focus != null:
			_check(not focus.visible, "%s: TabArtFocus phải ẩn khi chưa focus" % b.name)
		var icon := b.get_node_or_null("Icon") as Control
		_check(icon != null and not icon.visible, "%s: Icon gốc phải ẩn (huy hiệu đã nằm trong art)" % b.name)
		var panel := b.get_parent().get_parent() as Control
		var paper := panel.get_node_or_null("PaperHolder/PaperArt") as NinePatchRect
		_check(paper != null, "Dock thiếu PaperHolder/PaperArt")
		if paper != null:
			_check(paper.texture != null, "PaperArt chưa nạp dock_panel.png")
			var holder := paper.get_parent() as Control
			_check(holder.size.x > 0.0, "PaperHolder chưa được bố cục (size.x = %.1f)" % holder.size.x)
			_check(absf(paper.size.x - holder.size.x * 2.0) < 1.0,
				"PaperArt phải rộng gấp đôi panel (%.1f vs %.1f)" % [paper.size.x, holder.size.x * 2.0])


func _check_focus() -> void:
	var b := _pressed
	if b == null:
		return
	var focus := b.get_node_or_null("TabArtFocus") as Control
	var art := b.get_node_or_null("TabArt") as Control
	_check(focus != null and focus.visible, "%s: nhấn giữ phải hiện TabArtFocus" % b.name)
	_check(focus != null and focus.modulate.a > 0.9, "%s: TabArtFocus phải rõ lên (a=%.2f)" % [b.name, focus.modulate.a if focus != null else -1.0])
	_check(art != null and art.modulate.a < 0.1, "%s: TabArt phải mờ đi khi focus (a=%.2f)" % [b.name, art.modulate.a if art != null else -1.0])
	b.button_up.emit()


func _report() -> void:
	if _fails.is_empty():
		print("PROBE DOCK J: PASS %d check" % _checks)
	else:
		for f in _fails:
			print("PROBE DOCK J: FAIL ", f)
		print("PROBE DOCK J: %d/%d check FAIL" % [_fails.size(), _checks])
	_main.queue_free()
	quit(1 if not _fails.is_empty() else 0)
