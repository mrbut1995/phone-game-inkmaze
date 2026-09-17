class_name ShopTabButton
extends TextureButton
## ============================================================================
## Nút TAB của màn Cửa hàng (nodes/shop/tab_button.tscn)
## Trước đây tab được tạo bằng code (`TextureButton.new()` + tự thêm Label) —
## nay là SCENE riêng: sửa cỡ/màu/nhãn ngay trong scene, script chỉ lo trạng thái.
##
## Cỡ: lấy từ ART `tab_active.svg` / `tab_inactive.svg` (xem `art_height()`);
## hàng tab do màn Cửa hàng dàn qua `apply_row_layout()`.
## ============================================================================

const TAB_ACTIVE := preload("res://assets/images/shop/tab_active.svg")
const TAB_INACTIVE := preload("res://assets/images/shop/tab_inactive.svg")

## Mã nhóm hàng của tab (pen / theme / tool / coin)
var category := ""
## Tab đang được chọn
var active := false

@onready var label: Label = $Label


## Gán nhóm hàng + khoá dịch của nhãn (gọi ngay sau khi instantiate)
func setup(p_category: String, label_key: String) -> void:
	category = p_category
	set_label_text(TranslationServer.translate(label_key))


func set_label_text(text: String) -> void:
	if label != null:
		label.text = text


## Chiều cao ART của tab đang chọn — màn Cửa hàng dùng làm mốc cỡ hàng tab
static func art_height() -> float:
	return float(TAB_ACTIVE.get_height())


## Tỉ lệ chiều cao tab CHƯA CHỌN / tab ĐANG CHỌN (suy từ 2 art)
static func inactive_ratio() -> float:
	var active_h := float(TAB_ACTIVE.get_height())
	if active_h <= 0.0:
		return 1.0
	return float(TAB_INACTIVE.get_height()) / active_h


## Đổi trạng thái chọn: đổi art + kiểu nhãn (đậm/nhạt)
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


## Dàn nút trong hàng tab: tab đang chọn cao hết hàng, tab chưa chọn thấp hơn + canh ĐÁY hàng.
## Nhãn của MỌI tab nằm cùng một đường ngang (theo tâm tab đang chọn).
func apply_row_layout(tab_w: float, active_h: float, inactive_h: float) -> void:
	var h := active_h if active else inactive_h
	custom_minimum_size = Vector2(tab_w, h)
	size_flags_vertical = Control.SIZE_SHRINK_END
	if label != null:
		var shift := 0.0 if active else (active_h - h)
		label.position = Vector2(0.0, -shift)
		label.size = Vector2(tab_w, active_h)
