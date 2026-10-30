class_name LevelsPageDot
extends TextureButton
## ============================================================================
## Chấm chỉ số trang của màn Chọn màn (nodes/level_selection/page_dot.tscn)
## Trước đây chấm được tạo bằng code (`TextureButton.new()`) — nay là SCENE riêng.
## Bấm được để nhảy tới trang tương ứng (màn nối signal `pressed`).
## ============================================================================

## Art chấm — gán trong `page_dot.tscn` (ExtResource)
@export var dot_active: Texture2D = null
@export var dot_inactive: Texture2D = null

@export var SIZE_ACTIVE := Vector2(34, 24)
@export var SIZE_INACTIVE := Vector2(12, 24)


func set_current(on: bool) -> void:
	texture_normal = dot_active if on else dot_inactive
	texture_pressed = texture_normal
	texture_hover = texture_normal
	texture_focused = texture_normal
	custom_minimum_size = SIZE_ACTIVE if on else SIZE_INACTIVE


## Chấm này có đang là trang đang xem không (dùng cho test/đồng bộ trạng thái)
func is_current() -> bool:
	return texture_normal == dot_active
