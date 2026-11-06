class_name ShopTabButton
extends TextureButton
## ============================================================================
## Nút TAB của màn Cửa hàng (nodes/shop/tab_button.tscn) — kiểu THANH TAB DƯỚI
## Mỗi tab = ICON (trắng, tô màu theo trạng thái) + NHÃN bên dưới; tab đang chọn là viên xanh 3D
## (art `tab_active`), tab chưa chọn TRONG SUỐT (art `tab_inactive`) — hai art CÙNG chiều cao.
## 4 tab (pen · theme · tool · coin) KHAI SẴN trong scene bố cục (`Tabs/*`), mỗi tab tự khai
## `category` + `label_key` + `icon_texture`. Bề rộng do HBox chia đều; cao = art × hệ số màn hình.
## ============================================================================
## Scene contract
## Exports:  category, label_key, icon_texture, LABEL_COLOR, panel_h, IDLE_TOP, IDLE_LABEL_TOP, FOCUS_BOTTOM, FOCUS_LABEL_FRAC, label, icon, art
## Emits:    tab_pressed
## Handlers wired in scene: _emit_tab_pressed
## Subscribes in code (EventBus/Model): (none)

const UIAnim := preload("res://scripts/utils/UIAnim.gd")
## Art theo TỪNG tab (kiểu DOCK): `tab_idle_<category>.png` (huy hiệu + icon) và `tab_focus_<category>.png`
## (thẻ trắng + huy hiệu to + icon) — xuất 2× (xem tools/gen_tabs_k.py). Icon đã NẰM TRONG art ⇒ script không vẽ gì.
## ĐỔI THEME = thay file cùng tên + cùng kích thước logic.
const ART_DIR := "res://assets/images-png/shop/"
## Chiều cao hàng tab thiết kế (cao tab ở màn dọc) — art co theo `hàng thực / ROW_H`
const ROW_H := 84.0
## Cỡ LOGIC (đơn vị thiết kế) của art — bằng width/height trong SVG. Cỡ PNG có thể là 1× hay 2× tuỳ lần xuất
## (tool svg_to_png xuất đúng cỡ SVG = 1×) ⇒ script quy đổi theo chiều rộng, KHÔNG giả định "PNG = 2×".
const IDLE_LOGIC_W := 56.0
const FOCUS_LOGIC_W := 81.0

signal tab_pressed(category: String)

## Mã nhóm hàng của tab (pen / theme / tool / coin) — KHAI TRONG SCENE
@export var category := ""
## Khoá dịch của nhãn (STR_SHOP_TAB_*) — KHAI TRONG SCENE
@export var label_key := ""
## Icon của tab (art trắng nav_*.svg) — KHAI TRONG SCENE; để trống thì chỉ hiện nhãn
@export var icon_texture: Texture2D = null

@export var LABEL_COLOR := Color("164663")
## > 0 ⇒ tab cao đủ CẢ panel (bố cục NGANG: panel tự cao theo hàng tab, lề trên/dưới của panel = 0). Màn dọc: để 0.
@export var panel_h := 0.0
## Vị trí theo hệ toạ độ hàng tab (đỉnh hàng = đỉnh vòng lò xo; giấy bắt đầu ở y=12), đơn vị thiết kế
@export_group("Vị trí (đơn vị thiết kế)")
@export var IDLE_TOP := 24.0             ## đỉnh art huy hiệu
@export var IDLE_LABEL_TOP := 78.0       ## đỉnh nhãn dưới huy hiệu
@export var FOCUS_BOTTOM := 108.0        ## đáy thẻ focus (≈ đáy giấy − 4) ⇒ thẻ nhô lên trên vòng lò xo
@export var FOCUS_LABEL_FRAC := 0.60    ## đỉnh nhãn trong thẻ / cao thẻ
@export_group("")

var active := false
var _row_h := 0.0
var _tex_idle: Texture2D = null
var _tex_focus: Texture2D = null
var _art: TextureRect = null

@export var label: Label = null
@export var icon: TextureRect = null
## Node hiển thị art tab (khai sẵn trong `tab_button.tscn`, nằm DƯỚI nhãn)
@export var art: TextureRect = null


func _ready() -> void:
	stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_build_art()
	set_label_text(TranslationServer.translate(label_key))
	if icon != null:
		icon.texture = icon_texture
		icon.visible = icon_texture != null
	UIAnim.attach_press_down(self)
	_apply_colors()
	_apply_own_size()


## Nạp art riêng của tab này + node con hiển thị art (nằm DƯỚI nhãn, không nhận chuột)
func _build_art() -> void:
	var key := category if not category.is_empty() else "pen"
	_tex_idle = _load(ART_DIR + "tab_idle_%s.png" % key)
	_tex_focus = _load(ART_DIR + "tab_focus_%s.png" % key)
	_art = art
	if _art == null:
		return
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_SCALE


static func _load(path: String) -> Texture2D:
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_apply_own_size()


## Màn Cửa hàng gọi khi cỡ màn hình đổi: `active_h` = chiều cao hàng tab
func apply_metrics(active_h: float) -> void:
	if panel_h > 0.0:
		_row_h = ROW_H          # bố cục NGANG: panel luôn cỡ thiết kế (không co theo màn hình thấp) ⇒ thẻ không lệch khỏi panel
	elif active_h > 0.0:
		_row_h = active_h
	_apply_own_size()


func set_label_text(text: String) -> void:
	if label != null and not text.is_empty():
		label.text = _strip_leading_symbols(text)
		_apply_own_size()


## Tab đã có icon riêng ⇒ bỏ emoji/ký hiệu đứng đầu chuỗi dịch ("📖 GIẤY VỞ" → "GIẤY VỞ")
static func _strip_leading_symbols(text: String) -> String:
	var cleaned := RegEx.create_from_string("^[^\\p{L}\\p{N}]+").sub(text, "").strip_edges()
	return cleaned if not cleaned.is_empty() else text


func _emit_tab_pressed() -> void:
	tab_pressed.emit(category)


## Chiều cao hàng tab thiết kế — màn Cửa hàng dùng làm mốc cỡ hàng tab
static func art_height() -> float:
	return ROW_H


func set_active(on: bool) -> void:
	var changed := on != active
	active = on
	if label != null:
		label.theme_type_variation = &"ShopTabLabelActive" if on else &"ShopTabLabel"
	# Nút không có art riêng (trong suốt); art tab là node con `TabArt` (xem `_apply_own_size`)
	_apply_colors()
	_apply_own_size()
	# Pop nhẹ khi tab được KÍCH HOẠT để tạo cảm giác responsive
	if on and changed and not Engine.is_editor_hint() and is_inside_tree():
		UIAnim._update_pivot(self)
		var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw.tween_property(self, "scale", Vector2(1.06, 1.06), 0.10)
		tw.tween_property(self, "scale", Vector2.ONE, 0.13)


func _apply_colors() -> void:
	if label != null:
		label.add_theme_color_override("font_color", LABEL_COLOR)
		label.visible = true
	if icon != null:
		icon.visible = false   # icon đã nằm trong art


## Art + nhãn dàn lại theo cỡ thật của nút. Thẻ focus giữ NGUYÊN tỉ lệ (dọc), canh giữa ô, nhô lên trên vòng lò xo.
func _apply_own_size() -> void:
	if _row_h <= 0.0:
		_row_h = art_height()
	var h := _row_h
	var k := h / ROW_H
	custom_minimum_size = Vector2(0.0, maxf(h, panel_h * k) if panel_h > 0.0 else h)
	size_flags_vertical = Control.SIZE_FILL if panel_h > 0.0 else Control.SIZE_SHRINK_CENTER
	var width := size.x if size.x > 0.0 else 88.0
	var tex: Texture2D = _tex_focus if active else _tex_idle
	if _art != null:
		_art.texture = tex
		if tex != null:
			var sz := _logic_size(tex, active) * k
			var y := (FOCUS_BOTTOM * k - sz.y) if active else IDLE_TOP * k
			_set_centered(_art, sz, y)
	if label != null:
		label.visible = true
		if active and tex != null:
			var csz := _logic_size(tex, true) * k
			var top := FOCUS_BOTTOM * k - csz.y + csz.y * FOCUS_LABEL_FRAC
			# Thẻ focus HẸP: nhãn dài ("BÚT & MỰC") XUỐNG DÒNG thay vì co chữ/cắt "BÚT & M…"
			_set_centered(label, Vector2(csz.x, csz.y * 0.36), top - csz.y * 0.04)
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
			label.clip_text = false
			_fit_label_words(csz.x - 8.0)
		else:
			label.autowrap_mode = TextServer.AUTOWRAP_OFF
			label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			label.anchor_left = 0.0
			label.anchor_right = 1.0
			label.anchor_top = 0.0
			label.anchor_bottom = 0.0
			label.offset_left = 0.0
			label.offset_right = 0.0
			label.offset_top = IDLE_LABEL_TOP * k
			label.offset_bottom = (IDLE_LABEL_TOP + 20.0) * k
			_fit_label(width - 4.0)


## Đặt control CĂN GIỮA theo chiều ngang bằng ANCHOR (không phụ thuộc bề rộng nút lúc gọi ⇒ không lệch khi nút chưa có cỡ thật)
func _set_centered(c: Control, sz: Vector2, top: float) -> void:
	c.anchor_left = 0.5
	c.anchor_right = 0.5
	c.anchor_top = 0.0
	c.anchor_bottom = 0.0
	c.offset_left = -sz.x * 0.5
	c.offset_right = sz.x * 0.5
	c.offset_top = top
	c.offset_bottom = top + sz.y


## Thu nhỏ chữ nhãn cho VỪA bề rộng `max_w` (tên tab dài / dịch ngôn ngữ khác); cỡ gốc nhớ lại ở lần đầu
var _label_base := 0
func _fit_label(max_w: float, min_size := 10) -> void:
	if label == null:
		return
	if _label_base <= 0:
		_label_base = label.get_theme_font_size("font_size")
	var font := label.get_theme_font("font")
	var fs := _label_base
	while fs > min_size and font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > max_w:
		fs -= 1
	label.add_theme_font_size_override("font_size", fs)


## Nhãn nhiều dòng: chỉ co chữ khi TỪ DÀI NHẤT vẫn rộng hơn `max_w` (không bao giờ nhỏ hơn 10)
func _fit_label_words(max_w: float, min_size := 10) -> void:
	if label == null:
		return
	if _label_base <= 0:
		_label_base = label.get_theme_font_size("font_size")
	var font := label.get_theme_font("font")
	var fs := _label_base
	var longest := 0.0
	for word in label.text.split(" ", false):
		longest = maxf(longest, font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
	while fs > min_size and longest > max_w:
		fs -= 1
		longest = 0.0
		for word in label.text.split(" ", false):
			longest = maxf(longest, font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
	label.add_theme_font_size_override("font_size", fs)


## Cỡ logic của art tab: PNG 1× (bằng SVG) hay 2× đều cho cùng kết quả
func _logic_size(tex: Texture2D, focus: bool) -> Vector2:
	var logic_w := FOCUS_LOGIC_W if focus else IDLE_LOGIC_W
	var px := tex.get_size()
	return px * (logic_w / maxf(px.x, 1.0))
