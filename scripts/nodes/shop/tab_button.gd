class_name ShopTabButton
extends TextureButton
## ============================================================================
## Nút TAB của màn Cửa hàng (nodes/shop/tab_button.tscn)
## 4 tab (pen · theme · tool · coin) được KHAI SẴN trong scene bố cục
## (`scenes/layout/<hướng>/shop.tscn` → `Tabs/*`), mỗi tab tự khai `category` + `label_key`
## ⇒ script màn KHÔNG dựng tab bằng code nữa (chỉ gom lại: `ShopScene._collect_tabs`).
##
## Cỡ: bề rộng do HBox chia đều (`size_flags_horizontal = EXPAND_FILL` khai trong scene);
## chiều cao lấy từ ART `tab_active.svg` × hệ số màn hình (màn gọi `apply_metrics`).
## Nút tự nối `pressed` → phát `tab_pressed(category)` nên scene chỉ cần khai nhóm hàng.
## ============================================================================

const TAB_ACTIVE := preload("res://assets/images/shop/tab_active.svg")
const TAB_INACTIVE := preload("res://assets/images/shop/tab_inactive.svg")
const UIAnim := preload("res://scripts/utils/ui_anim.gd")

## Báo cho màn Cửa hàng biết tab nào vừa được bấm
signal tab_pressed(category: String)

## Mã nhóm hàng của tab (pen / theme / tool / coin) — KHAI TRONG SCENE
@export var category := ""
## Khoá dịch của nhãn (STR_SHOP_TAB_*) — KHAI TRONG SCENE
@export var label_key := ""

## Tab đang được chọn
var active := false
## Chiều cao hàng tab (tab đang chọn) — màn Cửa hàng set theo cỡ màn hình
var _row_h := 0.0

@onready var label: Label = $Label


func _ready() -> void:
	set_label_text(TranslationServer.translate(label_key))
	UIAnim.attach_press_bounce(self)
	# Dây `pressed → _emit_tab_pressed` khai trong `.tscn` (cùng scene)
	_apply_own_size()


func _notification(what: int) -> void:
	# HBox đổi bề rộng ⇒ nhãn (canh theo bề rộng nút) phải cập nhật lại
	if what == NOTIFICATION_RESIZED:
		_apply_own_size()


## Màn Cửa hàng gọi khi cỡ màn hình đổi: `active_h` = chiều cao tab ĐANG CHỌN
func apply_metrics(active_h: float) -> void:
	if active_h > 0.0:
		_row_h = active_h
	_apply_own_size()


func set_label_text(text: String) -> void:
	if label != null and not text.is_empty():
		label.text = text


func _emit_tab_pressed() -> void:
	tab_pressed.emit(category)


## Chiều cao ART của tab đang chọn — màn Cửa hàng dùng làm mốc cỡ hàng tab
static func art_height() -> float:
	return float(TAB_ACTIVE.get_height())


## Tỉ lệ chiều cao tab CHƯA CHỌN / tab ĐANG CHỌN (suy từ 2 art)
static func inactive_ratio() -> float:
	var active_h := float(TAB_ACTIVE.get_height())
	if active_h <= 0.0:
		return 1.0
	return float(TAB_INACTIVE.get_height()) / active_h


## Đổi trạng thái chọn: đổi art + kiểu nhãn (đậm/nhạt) rồi tự chỉnh cỡ theo hàng
func set_active(on: bool) -> void:
	active = on
	if label != null:
		label.theme_type_variation = &"ShopTabLabelActive" if on else &"ShopTabLabel"
	var art: Texture2D = TAB_ACTIVE if on else TAB_INACTIVE
	texture_normal = art
	texture_hover = art
	texture_pressed = art
	texture_focused = art
	texture_disabled = art
	_apply_own_size()


## Tab đang chọn cao hết hàng, tab chưa chọn thấp hơn + canh ĐÁY hàng.
## Nhãn của MỌI tab nằm cùng một đường ngang (theo tâm hàng) nên tab chưa chọn
## phải kéo nhãn LÊN đúng phần chênh lệch chiều cao.
func _apply_own_size() -> void:
	if _row_h <= 0.0:
		_row_h = art_height()
	var h := _row_h if active else _row_h * inactive_ratio()
	custom_minimum_size = Vector2(0.0, h)
	size_flags_vertical = Control.SIZE_SHRINK_END
	if label != null:
		var shift := 0.0 if active else (_row_h - h)
		var width := size.x if size.x > 0.0 else custom_minimum_size.x
		label.position = Vector2(0.0, -shift)
		label.size = Vector2(width, _row_h)
