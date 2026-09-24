class_name LanguageRow
extends Button
## ============================================================================
## Một HÀNG ngôn ngữ trong popup Chọn ngôn ngữ (nodes/popups/language_row.tscn)
##
## Trước đây popup tự dựng hàng + cờ + 2 nhãn + dấu tích bằng `.new()` — nay là
## SCENE riêng: art (thường · đang chọn · nhấn · focus) + cỡ + vị trí cờ/nhãn/tích
## sửa được ngay trong scene. Popup chỉ việc: setup() rồi set_selected().
## ============================================================================

const FALLBACK_FLAG := preload("res://assets/images/icons/flags/flag_generic.svg")

@onready var flag: TextureRect = $Flag
@onready var name_label: Label = $Name
@onready var sub_label: Label = $Sub
@onready var check: TextureRect = $Check


## Điền thông tin ngôn ngữ (tên · phụ đề · cờ quốc gia)
func setup(info: Dictionary, flag_tex: Texture2D) -> void:
	name_label.text = str(info.get("name", ""))
	sub_label.text = str(info.get("sub", ""))
	flag.texture = flag_tex if flag_tex != null else FALLBACK_FLAG


## Trạng thái đang chọn: nền sáng (StyleBox `pressed`) + dấu tích đỏ
func set_selected(on: bool) -> void:
	button_pressed = on
	if check != null:
		check.visible = on
