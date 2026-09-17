class_name ShopPageDot
extends TextureRect
## ============================================================================
## Chấm chỉ số trang của màn Cửa hàng (nodes/shop/page_dot.tscn)
## Trước đây chấm được tạo bằng code (`TextureRect.new()`) — nay là SCENE riêng.
## Cỡ + art: chấm ĐANG XEM to (34×24), các chấm khác nhỏ (12×24).
## ============================================================================

const DOT_ACTIVE := preload("res://assets/images/level_selector/dot_active.svg")
const DOT_INACTIVE := preload("res://assets/images/level_selector/dot_inactive.svg")

const SIZE_ACTIVE := Vector2(34, 24)
const SIZE_INACTIVE := Vector2(12, 24)


## Đặt trạng thái chấm: đang xem hay không
func set_current(on: bool) -> void:
	texture = DOT_ACTIVE if on else DOT_INACTIVE
	custom_minimum_size = SIZE_ACTIVE if on else SIZE_INACTIVE
