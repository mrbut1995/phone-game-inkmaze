class_name LevelsPageDot
extends TextureButton
## ============================================================================
## Chấm chỉ số trang của màn Chọn màn (nodes/level_selection/page_dot.tscn)
## Trước đây chấm được tạo bằng code (`TextureButton.new()`) — nay là SCENE riêng.
## Bấm được để nhảy tới trang tương ứng (màn nối signal `pressed`).
## ============================================================================

const DOT_ACTIVE := preload("res://assets/images/level_selector/dot_active.svg")
const DOT_INACTIVE := preload("res://assets/images/level_selector/dot_inactive.svg")

const SIZE_ACTIVE := Vector2(34, 24)
const SIZE_INACTIVE := Vector2(12, 24)


func set_current(on: bool) -> void:
	texture_normal = DOT_ACTIVE if on else DOT_INACTIVE
	texture_pressed = texture_normal
	texture_hover = texture_normal
	texture_focused = texture_normal
	custom_minimum_size = SIZE_ACTIVE if on else SIZE_INACTIVE


## Chấm này có đang là trang đang xem không (dùng cho test/đồng bộ trạng thái)
func is_current() -> bool:
	return texture_normal == DOT_ACTIVE
