@tool
class_name AchTabButton
extends NinePatchButton
## ============================================================================
## Nút TAB phân loại của Sổ tay thành tựu — CÓ 2 SCENE RIÊNG THEO HƯỚNG MÀN HÌNH:
##   · `nodes/archivements/tab_button.tscn`           → bản DỌC: 1 hàng 5 tab (mỗi tab ~67px) nên
##     nút thấp & chữ nhỏ (cao 32 · cỡ chữ 9) cho vừa khay `Sheet/Tabs` (HBox 355px).
##   · `nodes/archivements/tab_button_landscape.tscn` → bản NGANG: lưới 2 cột rộng rãi (327px/tab)
##     nên nút cao & chữ to (cao 56 · cỡ chữ 16).
## Các tab ("" = TẤT CẢ · levels · dungeon · daily · special) được KHAI SẴN trong scene bố cục
## (`scenes/layout/<hướng>/archivement.tscn` → `Sheet/Tabs/*`), mỗi tab tự khai `category`
## ⇒ script màn KHÔNG dựng tab bằng code nữa (chỉ gom lại: `ArchivementScene._collect_tabs`).
## Nhãn do màn cập nhật (`set_label_text`) vì có kèm SỐ LƯỢNG thành tựu đã đạt.
## Nút tự nối `pressed` → phát `tab_pressed(category)`.
##
## Dùng `NinePatchButton` (cắt 9 khúc art) + `size_flags_horizontal = EXPAND` ⇒ tab GIÃN KÍN ô
## của khay (khay dọc = HBox 5 tab · khay ngang = GridContainer 2 cột) mà không méo góc bo.
## ============================================================================

## Art 2 trạng thái tab — gán trong `tab_button*.tscn` (ExtResource), KHÔNG hard-code
@export var art_active: Texture2D = null
@export var art_idle: Texture2D = null
const UIAnim := preload("res://scripts/utils/ui_anim.gd")
@export var LABEL_ACTIVE_COLOR := Color(1, 1, 1)
@export var LABEL_IDLE_COLOR := Color(0.44313726, 0.54509807, 0.61960787, 1)

## Báo cho màn Sổ tay biết tab nào vừa được bấm
signal tab_pressed(category: String)

## Mã phân loại của tab ("" = TẤT CẢ · levels · dungeon · daily · special) — KHAI TRONG SCENE
@export var category := ""
## Tab đang được chọn
var active := false

## Node binding: khai `node_paths` + NodePath trong `tab_button*.tscn`
@export var label: Label = null


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


## Đổi trạng thái chọn: đổi art + màu nhãn có hiệu ứng transition mượt
func set_active(on: bool) -> void:
	active = on
	var art: Texture2D = art_active if on else art_idle
	texture_normal = art
	texture_pressed = art
	texture_hover = art
	texture_focus = art
	if label != null:
		# Đổi màu TỨC THỜI (contract đồng bộ: set_active() xong là đọc được màu mới)
		label.modulate = LABEL_ACTIVE_COLOR if on else LABEL_IDLE_COLOR
	# Pop nhẹ khi tab được KÍCH HOẠT (chỉ hiệu ứng scale — không ảnh hưởng giá trị đọc được)
	if on and not Engine.is_editor_hint():
		UIAnim._update_pivot(self)
		var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw.tween_property(self, "scale", Vector2(1.06, 1.06), 0.10)
		tw.tween_property(self, "scale", Vector2.ONE, 0.12)
