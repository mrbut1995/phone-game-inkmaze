@tool
class_name AchTabButton
extends NinePatchButton
## ============================================================================
## Nút TAB phân loại của Sổ tay thành tựu — scene `nodes/archivements/tab_button.tscn`:
## 1 hàng 5 tab (mỗi tab ~67px) nên nút thấp & chữ nhỏ (cao 32 · cỡ chữ 9) cho vừa khay
## `Sheet/Tabs` (HBox 355px).
## Các tab ("" = TẤT CẢ · levels · dungeon · daily · special) được KHAI SẴN trong scene bố cục
## (`scenes/layout/portrait/archivement.tscn` → `Sheet/Tabs/*`), mỗi tab tự khai `category`
## ⇒ script màn KHÔNG dựng tab bằng code nữa (chỉ gom lại: `ArchivementScene._collect_tabs`).
## Nhãn do màn cập nhật (`set_label_text`) vì có kèm SỐ LƯỢNG thành tựu đã đạt.
## Nút tự nối `pressed` → phát `tab_pressed(category)`.
##
## Dùng `NinePatchButton` (cắt 9 khúc art) + `size_flags_horizontal = EXPAND` ⇒ tab GIÃN KÍN ô
## của khay (HBox 5 tab) mà không méo góc bo.
## ============================================================================

const TAB_ACTIVE := preload("res://assets/images-png/archivements/tab_active.png")
const TAB_INACTIVE := preload("res://assets/images-png/archivements/tab_inactive.png")
const UIAnim := preload("res://scripts/utils/ui_anim.gd")
const LABEL_ACTIVE_COLOR := Color(1, 1, 1)
const LABEL_IDLE_COLOR := Color(0.44313726, 0.54509807, 0.61960787, 1)

## Báo cho màn Sổ tay biết tab nào vừa được bấm
signal tab_pressed(category: String)

## Mã phân loại của tab ("" = TẤT CẢ · levels · dungeon · daily · special) — KHAI TRONG SCENE
@export var category := ""
## Tab đang được chọn
var active := false

@onready var label: Label = $Label


func _ready() -> void:
	# Dây `pressed → _emit_tab_pressed` khai trong `.tscn` (cùng scene).
	# @tool: chỉ gắn hiệu ứng khi CHẠY (trong editor không cần bounce, tránh nhiễu)
	if Engine.is_editor_hint():
		return
	UIAnim.attach_press_bounce(self)


func _emit_tab_pressed() -> void:
	tab_pressed.emit(category)


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
