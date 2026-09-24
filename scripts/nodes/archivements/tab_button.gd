@tool
class_name AchTabButton
extends NinePatchButton
## ============================================================================
## Nút TAB phân loại của Sổ tay thành tựu (nodes/archivements/tab_button.tscn)
## Trước đây tab được tạo bằng code (`TextureButton.new()` + tự thêm Label) —
## nay là SCENE riêng: cỡ 134×46 và nhãn sửa được ngay trong scene.
##
## Dùng `NinePatchButton` (cắt 9 khúc art) + `size_flags_horizontal = EXPAND` ⇒ tab GIÃN KÍN ô
## của khay (khay dọc = HBox 5 tab · khay ngang = GridContainer 2 cột) mà không méo góc bo.
## ============================================================================

const TAB_ACTIVE := preload("res://assets/images/archivements/tab_active.svg")
const TAB_INACTIVE := preload("res://assets/images/archivements/tab_inactive.svg")
const LABEL_ACTIVE_COLOR := Color(1, 1, 1)
const LABEL_IDLE_COLOR := Color(0.44313726, 0.54509807, 0.61960787, 1)

## Mã phân loại của tab ("" = TẤT CẢ · levels · dungeon · daily · special)
var category := ""
var active := false

@onready var label: Label = $Label


func setup(p_category: String) -> void:
	category = p_category


func set_label_text(text: String) -> void:
	if label != null:
		label.text = text


## Đổi trạng thái chọn: đổi art + màu nhãn
func set_active(on: bool) -> void:
	active = on
	var art: Texture2D = TAB_ACTIVE if on else TAB_INACTIVE
	texture_normal = art
	texture_pressed = art
	texture_hover = art
	texture_focus = art
	if label != null:
		label.modulate = LABEL_ACTIVE_COLOR if on else LABEL_IDLE_COLOR
