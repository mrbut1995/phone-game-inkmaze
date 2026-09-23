class_name CountdownSegment
extends TextureRect
## ============================================================================
## Một VẠCH trong dải phân đoạn ngân sách của HUD đếm ngược
## (nodes/hud/countdown_segment.tscn)
##
## Trước đây HUD tự dựng vạch bằng `TextureRect.new()` — nay là SCENE riêng:
## art (xám / cam) + cỡ sửa được ngay trong scene, HUD chỉ đặt bề rộng + trạng thái.
## ============================================================================

const OFF := preload("res://assets/images/game/budget_segment_off.svg")
const ON := preload("res://assets/images/game/budget_segment_on.svg")
const HEIGHT := 6
const MIN_WIDTH := 4.0
const MAX_WIDTH := 38.0


## Bề rộng vạch (dải tự co để cả dải luôn vừa bề rộng thẻ, ngân sách có thể > 16 bước)
func set_width(width: float) -> void:
	custom_minimum_size = Vector2(clampf(width, MIN_WIDTH, MAX_WIDTH), HEIGHT)


## Trạng thái: đã dùng (xám · OFF) hay còn lại (cam · ON)
func set_used(used: bool) -> void:
	texture = OFF if used else ON
