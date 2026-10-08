class_name ShopPageDot
extends TextureRect
## ============================================================================
## Chấm chỉ số trang của màn Cửa hàng (nodes/shop/page_dot.tscn)
## Trước đây chấm được tạo bằng code (`TextureRect.new()`) — nay là SCENE riêng.
## Cỡ + art: chấm ĐANG XEM to (34×24), các chấm khác nhỏ (12×24).
## ============================================================================

## Art chấm — gán trong `page_dot.tscn` (ExtResource)
@export var dot_active: Texture2D = null
@export var dot_inactive: Texture2D = null

@export var SIZE_ACTIVE := Vector2(34, 24)
@export var SIZE_INACTIVE := Vector2(12, 24)


## Đặt trạng thái chấm: đang xem hay không
func set_current(on: bool) -> void:
	texture = dot_active if on else dot_inactive
	custom_minimum_size = SIZE_ACTIVE if on else SIZE_INACTIVE
