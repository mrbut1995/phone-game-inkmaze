class_name VfStarFly
extends Node2D
## ============================================================================
## Ngôi sao BAY (VFX) từ thẻ hành động lên Sao lớn của thanh Sao tháng
## (scripts/nodes/daily/vf_star_fly.gd — gắn vào Fly0..2 trong `Panel/Stage/Fx` của layout Daily)
##
## Script CHỈ lo HÌNH HỌC: `setup(từ, tới)` nhận 2 điểm theo toạ độ GLOBAL (vị trí THẬT lúc chạy
## nên đúng ở mọi bố cục/độ phân giải), rồi đặt vị trí trên đường cong bậc 2 theo `t` (0..1)
## và xoay đầu theo hướng bay. Thời gian bay, độ nhanh chậm, scale, độ mờ, vệt sáng, hạt...
## đều do AnimationPlayer `VfxAnim` trong scene điều khiển (animate thuộc tính `t`).
## ============================================================================

## Độ cong của đường bay so với khoảng cách (âm = cong về phía ngược lại).
## Mỗi sao đặt 1 giá trị khác nhau trong scene để 3 sao bung ra thành hình quạt.
@export_range(-0.6, 0.6, 0.01) var arc := 0.22
## Tiến trình bay 0..1 (AnimationPlayer animate thuộc tính này)
@export_range(0.0, 1.0, 0.001) var t := 0.0: set = _set_t

var _p0 := Vector2.ZERO
var _p1 := Vector2.ZERO
var _p2 := Vector2.ZERO
var _has_path := false


## Đặt đường bay (toạ độ GLOBAL) và đưa sao về điểm xuất phát
func setup(from_global: Vector2, to_global: Vector2) -> void:
	_p0 = from_global
	_p2 = to_global
	var d := to_global - from_global
	var normal := Vector2(-d.y, d.x).normalized()
	_p1 = from_global.lerp(to_global, 0.5) + normal * d.length() * arc
	_has_path = true
	_apply()


func _set_t(value: float) -> void:
	t = clampf(value, 0.0, 1.0)
	_apply()


func _apply() -> void:
	if not _has_path or not is_inside_tree():
		return
	var u := 1.0 - t
	global_position = u * u * _p0 + 2.0 * u * t * _p1 + t * t * _p2
	var tangent := 2.0 * u * (_p1 - _p0) + 2.0 * t * (_p2 - _p1)
	if tangent.length_squared() > 0.0001:
		global_rotation = tangent.angle()
