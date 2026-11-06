@tool
class_name AchTabButton
extends NinePatchButton
## ============================================================================
## Nút TAB phân loại của Sổ tay thành tựu — CÓ 2 SCENE RIÊNG THEO HƯỚNG MÀN HÌNH:
##   · `nodes/achievements/tab_button.tscn`           → bản DỌC: 1 hàng 5 tab (mỗi tab ~67px) nên
##     nút thấp & chữ nhỏ (cao 32 · cỡ chữ 9) cho vừa khay `Sheet/Tabs` (HBox 355px).
##   · `nodes/achievements/tab_button_landscape.tscn` → bản NGANG: lưới 2 cột rộng rãi (327px/tab)
##     nên nút cao & chữ to (cao 56 · cỡ chữ 16).
## Các tab ("" = TẤT CẢ · levels · dungeon · daily · special) được KHAI SẴN trong scene bố cục
## (`scenes/layout/<hướng>/achievement.tscn` → `Sheet/Tabs/*`), mỗi tab tự khai `category`
## ⇒ script màn KHÔNG dựng tab bằng code nữa (chỉ gom lại: `AchievementScene._collect_tabs`).
## Nhãn do màn cập nhật (`set_label_text`) vì có kèm SỐ LƯỢNG thành tựu đã đạt.
## Nút tự nối `pressed` → phát `tab_pressed(category)`.
##
## Dùng `NinePatchButton` (cắt 9 khúc art) + `size_flags_horizontal = EXPAND` ⇒ tab GIÃN KÍN ô
## của khay (khay dọc = HBox 5 tab · khay ngang = GridContainer 2 cột) mà không méo góc bo.
## ============================================================================

## Art 2 trạng thái tab — gán trong `tab_button*.tscn` (ExtResource), KHÔNG hard-code
@export var art_active: Texture2D = null
@export var art_idle: Texture2D = null
const UIAnim := preload("res://scripts/utils/UIAnim.gd")
@export var LABEL_ACTIVE_COLOR := Color(1, 1, 1)
@export var LABEL_IDLE_COLOR := Color(0.44313726, 0.54509807, 0.61960787, 1)

@export_group("Kiểu S (bật trong tab_button_seg.tscn)")
## Bật ⇒ ô trắng viền màu (chưa chọn: chỉ icon, KHÔNG nhãn) · thẻ đặc màu (đang chọn: icon to + nhãn)
@export var j_style := false
## Bản NGANG (cột tab dọc): tab chưa chọn = icon ở GIỮA ô; tab chọn = icon trái + nhãn bên phải
@export var j_side := false
@export var J_LABEL_COLOR := Color("164663")
@export var J_LABEL_ACTIVE_COLOR := Color(1, 1, 1)
const J_DIR := "res://assets/images-png/achievements/"
## Cỡ/vị trí tính theo CHIỀU CAO tab (tab phủ từ ~12px trên mép giấy đến đáy giấy)
const J_ACTIVE_ICON := 0.42
const J_ACTIVE_ICON_TOP := 0.13
const J_ACTIVE_LABEL_TOP := 0.64
## (bản DỌC) art kiểu DOCK `tab_idle_<k>.png` / `tab_focus_<k>.png` (2×, icon nằm trong art — xem tools/gen_tabs_k.py)
const J_ROW_H := 92.0          ## cao tab thiết kế; art co theo `cao thực / J_ROW_H`
const J_IDLE_TOP := 22.0       ## đỉnh art huy hiệu (đỉnh tab = đỉnh vòng lò xo); tab chưa chọn KHÔNG nhãn ⇒ huy hiệu nằm giữa giấy
const J_FOCUS_BOTTOM := 88.0   ## đáy thẻ focus ⇒ thẻ nhô lên trên vòng lò xo
const J_FOCUS_LABEL_FRAC := 0.60
## Chiều rộng LOGIC của art (bằng width trong SVG) — PNG xuất 1× hay 2× đều quy đổi đúng (tool svg_to_png xuất 1×)
const J_IDLE_LOGIC_W := 54.0
const J_FOCUS_LOGIC_W := 73.0
## (bản NGANG) ô vuông trắng của tab chưa chọn
const J_BADGE_ICON := 0.62     ## icon / cạnh ô vuông
## Màu ĐẬM của icon khi chưa chọn (trùng màu gờ đáy trong art) — theo category; thiếu ⇒ navy
const J_ICON_IDLE := {
	"": Color("1D5FB8"), "levels": Color("12703F"), "dungeon": Color("5F36B8"),
	"daily": Color("A3262B"), "special": Color("B86A00"),
}
var _j_active: Texture2D = null
var _j_art: TextureRect = null      ## (bản DỌC) art huy hiệu / thẻ focus
var _j_idle: Texture2D = null
var _j_focus: Texture2D = null
var _j_badge: NinePatchRect = null  ## (bản NGANG) ô vuông trắng tab chưa chọn

## Báo cho màn Sổ tay biết tab nào vừa được bấm
signal tab_pressed(category: String)

## Mã phân loại của tab ("" = TẤT CẢ · levels · dungeon · daily · special) — KHAI TRONG SCENE
@export var category := ""
## Tab đang được chọn
var active := false

## Node binding: khai `node_paths` + NodePath trong `tab_button*.tscn`
@export var label: Label = null
## Icon phân loại (trắng) — tô màu theo trạng thái cùng nhãn. Có thể để trống
@export var tab_icon: TextureRect = null


func _ready() -> void:
	# Dây `pressed → _emit_tab_pressed` khai trong `.tscn` (cùng scene).
	# @tool: chỉ gắn hiệu ứng khi CHẠY (trong editor không cần bounce, tránh nhiễu)
	if Engine.is_editor_hint():
		return
	if j_style:
		_build_j()
	UIAnim.attach_press_down(self)


func _j_key() -> String:
	return "all" if category.is_empty() else category


func _jload(file: String) -> Texture2D:
	var path := J_DIR + file
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


## Dựng huy hiệu + nạp art theo tab (thiếu file ⇒ giữ art cũ của scene)
func _build_j() -> void:
	_j_active = _jload("tab_active_%s.png" % _j_key())
	var idle := _jload("tab_inactive.png")
	if idle != null:
		art_idle = idle
	if _j_active != null and j_side:
		art_active = _j_active      # bản NGANG: thẻ chọn là chính art của nút (giãn kín ô)
	elif idle != null:
		art_active = idle           # bản DỌC: nút luôn trong suốt, thẻ vẽ bằng node con
	if j_side:
		_j_badge = _j_patch("JBadge", _jload("tab_badge_%s.png" % _j_key()))
	else:
		_j_idle = _jload("tab_idle_%s.png" % _j_key())
		_j_focus = _jload("tab_focus_%s.png" % _j_key())
		_j_art = TextureRect.new()  # EXCEPTION(R2-keep): art tab kiểu J sinh theo DỮ LIỆU (category → file art)
		_j_art.name = "JArt"
		_j_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_j_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_j_art.stretch_mode = TextureRect.STRETCH_SCALE
		add_child(_j_art)
		move_child(_j_art, 0)
	set_active(active)


func _j_patch(node_name: String, tex: Texture2D) -> NinePatchRect:
	var patch := NinePatchRect.new()  # keep-code: art kiểu J sinh theo DỮ LIỆU (texture truyền vào)
	patch.name = node_name
	patch.texture = tex
	patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "top", "right", "bottom"]:
		patch.set("patch_margin_" + side, 18)
	add_child(patch)
	move_child(patch, 0)
	return patch


func _layout_j_side(on: bool) -> void:
	var h := maxf(size.y, custom_minimum_size.y)
	var bs := h * 0.76
	var px := h * 0.58 if on else bs * J_BADGE_ICON
	if _j_badge != null:
		_j_badge.visible = not on
		_j_badge.position = Vector2(10.0, (h - bs) * 0.5)
		_j_badge.size = Vector2(bs, bs)
	var ic := get_node_or_null("Icon") as Control
	if ic != null:
		var x0 := 14.0 if on else 10.0 + (bs - px) * 0.5
		ic.anchor_left = 0.0
		ic.anchor_right = 0.0
		ic.anchor_top = 0.5
		ic.anchor_bottom = 0.5
		ic.offset_left = x0
		ic.offset_right = x0 + px
		ic.offset_top = -px * 0.5
		ic.offset_bottom = px * 0.5
	if label != null:
		label.visible = true
		label.offset_left = (14.0 + px + 8.0) if on else (10.0 + bs + 10.0)


## Bản DỌC (khay tab nằm ngang): kiểu DOCK — art giữ NGUYÊN tỉ lệ, canh giữa ô, thẻ focus nhô lên; không kéo ngang
func _layout_j(on: bool) -> void:
	if j_side:
		_layout_j_side(on)
		return
	var h := maxf(size.y, custom_minimum_size.y)
	var k := h / J_ROW_H
	var tex: Texture2D = _j_focus if on else _j_idle
	var ic := get_node_or_null("Icon") as Control
	if ic != null:
		ic.visible = tex == null      # icon đã nằm trong art
	if _j_art != null:
		_j_art.texture = tex
		if tex != null:
			var sz := _j_logic(tex, on) * k
			_j_center(_j_art, sz, (J_FOCUS_BOTTOM * k - sz.y) if on else J_IDLE_TOP * k)
	if label != null:
		label.visible = on         # NHIỀU TAB ⇒ chỉ tab đang chọn hiện chữ
		if on and tex != null:
			var csz := _j_logic(tex, true) * k
			_j_center(label, Vector2(csz.x, csz.y * 0.26), J_FOCUS_BOTTOM * k - csz.y + csz.y * J_FOCUS_LABEL_FRAC)
			_fit_label(csz.x - 6.0)


## Căn GIỮA theo chiều ngang bằng ANCHOR (không phụ thuộc bề rộng nút lúc gọi ⇒ lần đầu vào màn không bị lệch chữ)
func _j_center(c: Control, sz: Vector2, top: float) -> void:
	c.anchor_left = 0.5
	c.anchor_right = 0.5
	c.anchor_top = 0.0
	c.anchor_bottom = 0.0
	c.offset_left = -sz.x * 0.5
	c.offset_right = sz.x * 0.5
	c.offset_top = top
	c.offset_bottom = top + sz.y


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and j_style:
		_layout_j(active)


func _emit_tab_pressed() -> void:
	tab_pressed.emit(category)


func set_label_text(text: String) -> void:
	if label != null:
		label.text = text
		if j_style and not j_side:
			_layout_j(active)


## Thu nhỏ chữ nhãn cho VỪA bề rộng `max_w` (vd "TẤT CẢ (28)"); cỡ gốc nhớ lại ở lần đầu
var _label_base := 0
func _fit_label(max_w: float, min_size := 8) -> void:
	if label == null:
		return
	if _label_base <= 0:
		_label_base = label.get_theme_font_size("font_size")
	var font := label.get_theme_font("font")
	var fs := _label_base
	while fs > min_size and font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > max_w:
		fs -= 1
	label.add_theme_font_size_override("font_size", fs)


## Đổi trạng thái chọn: đổi art + màu nhãn có hiệu ứng transition mượt
func set_active(on: bool) -> void:
	active = on
	var art: Texture2D = art_active if (on and (j_side or not j_style)) else art_idle
	texture_normal = art
	texture_pressed = art
	texture_hover = art
	texture_focus = art
	if j_style:
		if label != null:
			label.modulate = Color.WHITE
			label.add_theme_color_override("font_color", J_LABEL_ACTIVE_COLOR if (on and j_side) else J_LABEL_COLOR)
		if tab_icon != null:
			tab_icon.modulate = Color.WHITE if on else J_ICON_IDLE.get(category, J_LABEL_COLOR)
		_layout_j(on)
	else:
		if label != null:
			# Đổi màu TỨC THỜI (contract đồng bộ: set_active() xong là đọc được màu mới)
			label.modulate = LABEL_ACTIVE_COLOR if on else LABEL_IDLE_COLOR
		if tab_icon != null:
			tab_icon.modulate = LABEL_ACTIVE_COLOR if on else LABEL_IDLE_COLOR
		var offset = 0
		if on:
			offset = 6
		$Label.position.y = 38 - offset
		$Icon.position.y = 12 - offset
	
	# Pop nhẹ khi tab được KÍCH HOẠT (chỉ hiệu ứng scale — không ảnh hưởng giá trị đọc được)
	if on and not Engine.is_editor_hint():
		UIAnim._update_pivot(self)
		var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw.tween_property(self, "scale", Vector2(1.06, 1.06), 0.10)
		tw.tween_property(self, "scale", Vector2.ONE, 0.12)


## Cỡ logic của art tab (không giả định PNG = 2×)
func _j_logic(tex: Texture2D, focus: bool) -> Vector2:
	var px := tex.get_size()
	return px * ((J_FOCUS_LOGIC_W if focus else J_IDLE_LOGIC_W) / maxf(px.x, 1.0))
