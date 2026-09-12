class_name WallSegment
extends Line2D
## ============================================================================
## View: 1 đoạn tường (dùng Line2D nối 2 điểm neo Anchor).
## Màu theo state: "visible" (tường thật), "invisible" (ẩn),
##                 "suspected" (tường nghi ngờ - vàng cam), "hit" (va chạm - đỏ).
## ============================================================================

var _state := "invisible"

const COLOR_VISIBLE := Color(0.12, 0.16, 0.23, 1.0)        # #1E283A
const COLOR_SUSPECTED := Color(0.77, 0.52, 0.23, 1.0)      # #C4843A
const COLOR_HIT := Color(0.85, 0.27, 0.27, 1.0)            # #D84444


func get_state() -> String:
	return _state


func set_wall_points(p1: Vector2, p2: Vector2) -> void:
	points = PackedVector2Array([p1, p2])


func set_line_width(w: float) -> void:
	width = w


func set_state(state: String) -> void:
	_state = state
	match state:
		"visible":
			visible = true
			default_color = COLOR_VISIBLE
		"invisible":
			visible = false
		"suspected":
			visible = true
			default_color = COLOR_SUSPECTED
		"hit":
			visible = true
			default_color = COLOR_HIT


func animate_appear() -> void:
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func flash_hit_then_stay_visible() -> void:
	set_state("hit")
	var tw := create_tween()
	tw.tween_interval(0.45)
	tw.tween_callback(func() -> void:
		set_state("visible")
	)
