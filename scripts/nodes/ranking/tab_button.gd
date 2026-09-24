class_name RankTabButton
extends NinePatchButton
## ============================================================================
## Nút TAB bảng xếp hạng (nodes/ranking/tab_button.tscn)
## Trước đây tab được tạo bằng code (`TextureButton.new()` + tự thêm Label) —
## nay là SCENE riêng: art + cỡ mặc định 120×26 (CỠ GỐC của `assets/images/ranking/tab_*.svg`
## — mockup vẽ 2× nên viewBox là 240×52) sửa được ngay trong scene.
## ============================================================================

const TAB_ACTIVE_ART := preload("res://assets/images/ranking/tab_active.svg")
const TAB_NORMAL_ART := preload("res://assets/images/ranking/tab_normal.svg")
const LABEL_ACTIVE_COLOR := Color(1, 1, 1)
const LABEL_IDLE_COLOR := Color(0.13333334, 0.29803923, 0.42745098)

## Mã bảng của tab (dungeon / play / daily)
var board_id := ""
var active := false

## Chiều cao mặc định khi scene KHÔNG khai `custom_minimum_size.y` (tránh tab cao 0px)
const DEFAULT_HEIGHT := 26.0

@onready var label: Label = $Label


## Gán bảng + tiêu đề + bề rộng riêng (chiều cao lấy từ scene, thiếu thì dùng DEFAULT_HEIGHT)
func setup(id: String, title: String, width: float = 0.0) -> void:
	board_id = id
	var height := custom_minimum_size.y
	if height <= 0.0:
		height = DEFAULT_HEIGHT
	var width_now := width if width > 0.0 else custom_minimum_size.x
	if width_now <= 0.0:
		width_now = 120.0
	custom_minimum_size = Vector2(width_now, height)
	if label != null:
		label.text = title


func set_label_text(text: String) -> void:
	if label != null:
		label.text = text


## Đổi trạng thái chọn: art + màu nhãn
func set_active(on: bool) -> void:
	active = on
	var art: Texture2D = TAB_ACTIVE_ART if on else TAB_NORMAL_ART
	texture_normal = art
	texture_pressed = art
	texture_hover = art
	texture_focus = art
	texture_disabled = art
	if label != null:
		label.add_theme_color_override("font_color",
			LABEL_ACTIVE_COLOR if on else LABEL_IDLE_COLOR)
