extends RefCounted
## ============================================================================
## Dock kiểu "J" — TOÀN BỘ hình ảnh là ASSET (svg → png 2x), script không vẽ gì:
##   · panel giấy lò xo : `dock_panel.png`            (9-slice, giữa lát ngang theo chu kỳ vòng gáy)
##   · tab thường       : `dock_tab_<key>.png`        (huy hiệu tròn + icon)
##   · tab focus        : `dock_tab_<key>_focus.png`  (thẻ trắng nhô lên + huy hiệu to)
## <key> = shop · rank · daily · badges. ĐỔI THEME = thay các file này (cùng tên, cùng kích thước logic)
## hoặc đổi `ART_DIR`; nguồn SVG + script xuất: gen/gen_dock_j.py.
## Nút đang FOCUS (đang bấm giữ, hoặc là tab hiện hành qua `set_active`) hiện art focus; nút khác hiện art thường.
## Không có `class_name` (tránh trùng class toàn project) — dùng qua `preload`.
## ============================================================================

## Thư mục art + màu chữ nhãn (đổi theme: sửa 2 dòng này nếu cần)
const ART_DIR := "res://assets/images-png/dock/"
const LABEL_COLOR := Color("164663")

## Art xuất 2x ⇒ hiển thị ở nửa kích thước PNG (kích thước LOGIC dưới đây khớp SVG)
const PANEL_TEX := "dock_panel.png"
const PANEL_CAP := 28.0            ## cap trái/phải (logic px)
const PANEL_CAP_V := 30.0          ## cap trên/dưới (logic px)
const PANEL_OVERHANG := 12.0       ## vòng gáy nhô khỏi mép trên panel
const TAB_SIZE := Vector2(56.0, 62.0)
const FOCUS_SIZE := Vector2(96.0, 126.0)

const HEIGHT := 100.0              ## cao tối thiểu của nút dock
## Art neo theo ĐÁY nút (nhãn chữ cũng neo đáy) ⇒ nút cao/thấp hơn HEIGHT thì chữ vẫn nằm đúng trong thẻ
const TAB_BOTTOM := -34.0          ## mép dưới art thường (nằm trên nhãn)
const FOCUS_BOTTOM := 2.0          ## mép dưới art focus (đáy thẻ trắng ≈ đáy nút - 4)
const FOCUS_BOTTOM_REST := 14.0    ## vị trí khi chưa focus (trượt lên khi focus)
const ANIM_SEC := 0.14


## Panel chứa hàng nút: bỏ stylebox, thay bằng NinePatchRect `PaperArt` (đặt ở node `PaperHolder`)
static func apply_panel(panel: Control) -> void:
	if panel == null:
		return
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	if panel.get_node_or_null("PaperHolder") != null:
		return
	var tex := _tex(PANEL_TEX)
	if tex == null:
		return
	var holder := Control.new()
	holder.name = "PaperHolder"
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(holder)
	panel.move_child(holder, 0)
	var art := NinePatchRect.new()
	art.name = "PaperArt"
	art.texture = tex
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.patch_margin_left = int(PANEL_CAP * 2.0)
	art.patch_margin_right = int(PANEL_CAP * 2.0)
	art.patch_margin_top = int(PANEL_CAP_V * 2.0)
	art.patch_margin_bottom = int(PANEL_CAP_V * 2.0)
	art.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE_FIT
	art.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_STRETCH
	art.scale = Vector2(0.5, 0.5)      # art 2x ⇒ hiển thị đúng kích thước logic, nét trên màn dày điểm ảnh
	holder.add_child(art)
	var fit := func() -> void:
		art.position = Vector2(0.0, -PANEL_OVERHANG)
		art.size = Vector2(holder.size.x, holder.size.y + PANEL_OVERHANG) * 2.0
	holder.resized.connect(fit)
	fit.call()


## Dựng 1 nút dock: 2 TextureRect (thường / focus), ẩn Icon gốc, nhãn chữ giữ nguyên (đa ngôn ngữ)
static func style_button(button: Control, key: String) -> void:
	if button == null:
		return
	var empty := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(state, empty)
	button.custom_minimum_size.y = HEIGHT
	button.clip_contents = false

	if button.get_node_or_null("TabArt") == null:
		button.add_child(_art_rect("TabArt", "dock_tab_%s.png" % key, TAB_SIZE, TAB_BOTTOM))
		var focus_art := _art_rect("TabArtFocus", "dock_tab_%s_focus.png" % key, FOCUS_SIZE, FOCUS_BOTTOM_REST)
		focus_art.modulate.a = 0.0
		focus_art.visible = false
		button.add_child(focus_art)
		button.move_child(button.get_node("TabArt"), 0)
		button.move_child(focus_art, 1)

	var icon := button.get_node_or_null("Icon") as Control
	if icon != null:
		icon.visible = false          # icon đã nằm trong art huy hiệu
	var label := button.get_node_or_null("Label") as Label
	if label != null:
		label.anchor_left = 0.0
		label.anchor_right = 1.0
		label.anchor_top = 1.0
		label.anchor_bottom = 1.0
		label.offset_left = 2.0
		label.offset_right = -2.0
		label.offset_top = -34.0
		label.offset_bottom = -8.0
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", LABEL_COLOR)
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0))
		label.add_theme_constant_override("outline_size", 0)
		label.add_theme_font_size_override("font_size", 12)

	button.set_meta("dock_key", key)
	if not button.has_meta("j_wired"):
		button.set_meta("j_wired", true)
		button.button_down.connect(func() -> void: _set_flag(button, "j_down", true))
		button.button_up.connect(func() -> void: _set_flag(button, "j_down", false))
		button.mouse_exited.connect(func() -> void: _set_flag(button, "j_down", false))
	button.set_meta("j_focus", false)
	_apply_focus(button, false, false)


## Tab HIỆN HÀNH (nhô lên cố định): key ("shop" · "rank" · "daily" · "badges") hoặc "" để bỏ
static func set_active(buttons: Array, active_key: String) -> void:
	for button in buttons:
		var b := button as Control
		if b != null and is_instance_valid(b):
			_set_flag(b, "j_active", String(b.get_meta("dock_key", "")) == active_key and active_key != "")


static func _art_rect(node_name: String, file: String, size: Vector2, bottom: float) -> TextureRect:
	var rect := TextureRect.new()
	rect.name = node_name
	rect.texture = _tex(file)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.anchor_left = 0.5
	rect.anchor_right = 0.5
	rect.offset_left = -size.x * 0.5
	rect.offset_right = size.x * 0.5
	rect.anchor_top = 1.0
	rect.anchor_bottom = 1.0
	rect.offset_top = bottom - size.y
	rect.offset_bottom = bottom
	return rect


static func _tex(file: String) -> Texture2D:
	var path := ART_DIR + file
	if not ResourceLoader.exists(path):
		push_warning("Dock art thiếu: " + path)
		return null
	return load(path) as Texture2D


static func _set_flag(button: Control, flag: String, value: bool) -> void:
	button.set_meta(flag, value)
	var on := bool(button.get_meta("j_down", false)) or bool(button.get_meta("j_active", false))
	if bool(button.get_meta("j_focus", false)) == on:
		return
	button.set_meta("j_focus", on)
	_apply_focus(button, on, true)


static func _apply_focus(button: Control, focused: bool, animate: bool) -> void:
	var normal := button.get_node_or_null("TabArt") as Control
	var focus := button.get_node_or_null("TabArtFocus") as Control
	var label := button.get_node_or_null("Label") as Label
	if label != null:
		label.add_theme_font_size_override("font_size", 12)
	if focus != null and focused:
		focus.visible = true
	var bottom := FOCUS_BOTTOM if focused else FOCUS_BOTTOM_REST
	if animate and button.is_inside_tree():
		var tween := button.create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if focus != null:
			tween.tween_property(focus, "offset_top", bottom - FOCUS_SIZE.y, ANIM_SEC)
			tween.tween_property(focus, "offset_bottom", bottom, ANIM_SEC)
			tween.tween_property(focus, "modulate:a", 1.0 if focused else 0.0, ANIM_SEC)
		if normal != null:
			tween.tween_property(normal, "modulate:a", 0.0 if focused else 1.0, ANIM_SEC)
		if not focused and focus != null:
			tween.chain().tween_callback(func() -> void:
				focus.visible = bool(button.get_meta("j_focus", false)))
	else:
		if focus != null:
			focus.offset_top = bottom - FOCUS_SIZE.y
			focus.offset_bottom = bottom
			focus.modulate.a = 1.0 if focused else 0.0
			focus.visible = focused
		if normal != null:
			normal.modulate.a = 0.0 if focused else 1.0
