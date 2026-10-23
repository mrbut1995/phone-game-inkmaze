class_name ShopTabButton
extends TextureButton
## ============================================================================
## Nút TAB của màn Cửa hàng (nodes/shop/tab_button.tscn) — kiểu THANH TAB DƯỚI
## Mỗi tab = ICON (trắng, tô màu theo trạng thái) + NHÃN bên dưới; tab đang chọn là viên xanh 3D
## (art `tab_active`), tab chưa chọn TRONG SUỐT (art `tab_inactive`) — hai art CÙNG chiều cao.
## 4 tab (pen · theme · tool · coin) KHAI SẴN trong scene bố cục (`Tabs/*`), mỗi tab tự khai
## `category` + `label_key` + `icon_texture`. Bề rộng do HBox chia đều; cao = art × hệ số màn hình.
## ============================================================================
const TAB_ACTIVE := preload("res://assets/images-png/shop/tab_active.png")
const TAB_INACTIVE := preload("res://assets/images-png/shop/tab_inactive.png")
const UIAnim := preload("res://scripts/utils/ui_anim.gd")

signal tab_pressed(category: String)

## Mã nhóm hàng của tab (pen / theme / tool / coin) — KHAI TRONG SCENE
@export var category := ""
## Khoá dịch của nhãn (STR_SHOP_TAB_*) — KHAI TRONG SCENE
@export var label_key := ""
## Icon của tab (art trắng nav_*.svg) — KHAI TRONG SCENE; để trống thì chỉ hiện nhãn
@export var icon_texture: Texture2D = null

## Màu icon + nhãn theo trạng thái
@export var COLOR_ACTIVE := Color(1, 1, 1)
@export var COLOR_IDLE := Color(0.1843, 0.3725, 0.5098)
## Bố cục bên trong tab theo CHIỀU CAO tab: lề trên của icon, cỡ icon, vị trí nhãn
@export var ICON_TOP := 0.10
@export var ICON_SIZE := 0.43
@export var LABEL_TOP := 0.55

var active := false
var _row_h := 0.0

@export var label: Label = null
@export var icon: TextureRect = null


func _ready() -> void:
	set_label_text(TranslationServer.translate(label_key))
	if icon != null:
		icon.texture = icon_texture
		icon.visible = icon_texture != null
	UIAnim.attach_press_down(self)
	_apply_colors()
	_apply_own_size()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_apply_own_size()


## Màn Cửa hàng gọi khi cỡ màn hình đổi: `active_h` = chiều cao hàng tab
func apply_metrics(active_h: float) -> void:
	if active_h > 0.0:
		_row_h = active_h
	_apply_own_size()


func set_label_text(text: String) -> void:
	if label != null and not text.is_empty():
		label.text = _strip_leading_symbols(text)


## Tab đã có icon riêng ⇒ bỏ emoji/ký hiệu đứng đầu chuỗi dịch ("📖 GIẤY VỞ" → "GIẤY VỞ")
static func _strip_leading_symbols(text: String) -> String:
	var cleaned := RegEx.create_from_string("^[^\\p{L}\\p{N}]+").sub(text, "").strip_edges()
	return cleaned if not cleaned.is_empty() else text


func _emit_tab_pressed() -> void:
	tab_pressed.emit(category)


## Chiều cao ART tab — màn Cửa hàng dùng làm mốc cỡ hàng tab
static func art_height() -> float:
	return float(TAB_ACTIVE.get_height())


## Tỉ lệ chiều cao tab CHƯA CHỌN / ĐANG CHỌN (hai art cùng cao ⇒ 1,0)
static func inactive_ratio() -> float:
	var active_h := float(TAB_ACTIVE.get_height())
	if active_h <= 0.0:
		return 1.0
	return float(TAB_INACTIVE.get_height()) / active_h


func set_active(on: bool) -> void:
	var changed := on != active
	active = on
	if label != null:
		label.theme_type_variation = &"ShopTabLabelActive" if on else &"ShopTabLabel"
	var art: Texture2D = TAB_ACTIVE if on else TAB_INACTIVE
	texture_normal = art
	texture_hover = art
	texture_pressed = art
	texture_focused = art
	texture_disabled = art
	_apply_colors()
	_apply_own_size()
	# Pop nhẹ khi tab được KÍCH HOẠT để tạo cảm giác responsive
	if on and changed and not Engine.is_editor_hint() and is_inside_tree():
		UIAnim._update_pivot(self)
		var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw.tween_property(self, "scale", Vector2(1.06, 1.06), 0.10)
		tw.tween_property(self, "scale", Vector2.ONE, 0.13)


func _apply_colors() -> void:
	var color := COLOR_ACTIVE if active else COLOR_IDLE
	if label != null:
		label.add_theme_color_override("font_color", color)
	if icon != null:
		icon.self_modulate = color


## Cao theo hàng tab; icon + nhãn dàn lại theo cỡ thật của nút
func _apply_own_size() -> void:
	if _row_h <= 0.0:
		_row_h = art_height()
	var h := _row_h if active else _row_h * inactive_ratio()
	custom_minimum_size = Vector2(0.0, h)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var width := size.x if size.x > 0.0 else custom_minimum_size.x
	var offset = Vector2(0,0 if active else 5)
	if icon != null:
		var icon_px := h * ICON_SIZE
		icon.size = Vector2(icon_px, icon_px) + offset
		icon.position = Vector2((width - icon_px) * 0.5, h * ICON_TOP)
	if label != null:
		label.position = Vector2(0.0, h * LABEL_TOP) + offset
		label.size = Vector2(width, h * (0.96 - LABEL_TOP))
