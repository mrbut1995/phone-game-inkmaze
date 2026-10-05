class_name RankTabButton
extends NinePatchButton
## ============================================================================
## Nút TAB bảng xếp hạng (nodes/ranking/tab_button.tscn)
## 3 tab (dungeon · play · daily) được KHAI SẴN trong scene bố cục
## (`scenes/layout/<hướng>/ranking.tscn` → `Sheet/Tabs/*`), mỗi tab tự khai `board_id` +
## `label_key` ⇒ script màn KHÔNG dựng tab bằng code nữa (chỉ gom lại: `RankingScene._collect_tabs`).
## Art + cỡ mặc định 120×26 (CỠ GỐC của `assets/images/ranking/tab_*.svg` — mockup vẽ 2×
## nên viewBox là 240×52) sửa được ngay trong scene; bề rộng do HBox chia đều.
## Nút tự nối `pressed` → phát `tab_pressed(board_id)`.
## ============================================================================

const TAB_ACTIVE_ART := preload("res://assets/images-png/ranking/tab_active.png")
const TAB_NORMAL_ART := preload("res://assets/images-png/ranking/tab_normal.png")
const UIAnim := preload("res://scripts/utils/ui_anim.gd")

const LABEL_ACTIVE_COLOR := Color(1, 1, 1)
const LABEL_IDLE_COLOR := Color(0.13333334, 0.29803923, 0.42745098)

## Chiều cao mặc định khi scene KHÔNG khai `custom_minimum_size.y` (tránh tab cao 0px)
const DEFAULT_HEIGHT := 26.0

## Báo cho màn Xếp hạng biết tab nào vừa được bấm
signal tab_pressed(board_id: String)

## Mã bảng của tab (dungeon / play / daily) — KHAI TRONG SCENE
@export var board_id := ""
## Khoá dịch của nhãn (STR_RANK_TAB_*) — KHAI TRONG SCENE
@export var label_key := ""

@export var label: Label = null

## Tab đang được chọn
var active := false



func _ready() -> void:
	# Bề rộng do HBox chia đều (`size_flags_horizontal = EXPAND_FILL` khai trong scene) ⇒ bỏ
	# bề rộng tối thiểu của scene, chỉ giữ CHIỀU CAO (thiếu thì dùng DEFAULT_HEIGHT).
	var height := custom_minimum_size.y if custom_minimum_size.y > 0.0 else DEFAULT_HEIGHT
	custom_minimum_size = Vector2(0.0, height)
	set_label_text(TranslationServer.translate(label_key))
	UIAnim.attach_press_bounce(self)
	# Dây `pressed → _emit_tab_pressed` khai trong `.tscn` (cùng scene)


func set_label_text(text: String) -> void:
	if label != null and not text.is_empty():
		label.text = text


func _emit_tab_pressed() -> void:
	tab_pressed.emit(board_id)


## Đổi trạng thái chọn: art + màu nhãn có hiệu ứng transition mượt
func set_active(on: bool) -> void:
	active = on
	var art: Texture2D = TAB_ACTIVE_ART if on else TAB_NORMAL_ART
	texture_normal = art
	texture_pressed = art
	texture_hover = art
	texture_focus = art
	texture_disabled = art
	if label != null:
		# Đổi màu TỨC THỜI (contract đồng bộ: set_active() xong là đọc được màu mới)
		label.add_theme_color_override("font_color",
				LABEL_ACTIVE_COLOR if on else LABEL_IDLE_COLOR)
	# Pop nhẹ khi tab được KÍCH HOẠT (chỉ hiệu ứng scale — không ảnh hưởng giá trị đọc được)
	if on and not Engine.is_editor_hint():
		UIAnim._update_pivot(self)
		var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw.tween_property(self, "scale", Vector2(1.06, 1.06), 0.10)
		tw.tween_property(self, "scale", Vector2.ONE, 0.12)
