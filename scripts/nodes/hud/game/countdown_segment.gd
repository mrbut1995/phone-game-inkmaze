class_name CountdownSegment
extends TextureRect
## ============================================================================
## Một VẠCH trong dải phân đoạn ngân sách của HUD đếm ngược
## (nodes/hud/countdown_segment.tscn)
##
## Trước đây HUD tự dựng vạch bằng `TextureRect.new()` — nay là SCENE riêng:
## art (xám / cam) + cỡ sửa được ngay trong scene, HUD chỉ đặt bề rộng + trạng thái.
## ============================================================================

## Màu vạch — art TRẮNG trong `countdown_segment.tscn`, màu do `self_modulate` này
@export var color_on := Color(0.917647, 0.345098, 0.047059, 1)
@export var color_off := Color(0.886275, 0.909804, 0.941176, 1)
@export var HEIGHT := 6
@export var MIN_WIDTH := 4.0
@export var MAX_WIDTH := 38.0


## Bề rộng vạch (dải tự co để cả dải luôn vừa bề rộng thẻ, ngân sách có thể > 16 bước)
func set_width(width: float) -> void:
	custom_minimum_size = Vector2(clampf(width, MIN_WIDTH, MAX_WIDTH), HEIGHT)


## Trạng thái: đã dùng (xám · OFF) hay còn lại (cam · ON)
func set_used(used: bool) -> void:
	self_modulate = color_off if used else color_on
