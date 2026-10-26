class_name GameOverPath
extends Control
## Vẽ "bản đồ đường đi" của popup Game Over: chấm xuất phát -> đoạn đã đi (nét liền xanh)
## -> dấu ✕ nơi thua -> đoạn còn lại (nét đứt) -> cờ đích. Vẽ bằng code, KHÔNG cần ảnh.
##
## gameover_level.gd gọi:  path.set_progress(0.62)   # 0..1

@export var color_done := Color("5BA4D6")
@export var color_left := Color("C3CFDA")
@export var color_start := Color("6DBE2A")
@export var color_fail := Color("E5493A")
@export var color_ink := Color("333745")
@export var line_width := 5.0

const SAMPLES := 72
var _progress := 0.0
## Hiệu ứng "chạy": 0 -> 1 = nét xanh + ✕ chạy từ điểm xuất phát tới điểm thua. 1 = vẽ đầy đủ (mặc định).
var anim := 1.0:
	set(value):
		anim = clampf(value, 0.0, 1.0)
		queue_redraw()


func set_progress(value: float) -> void:
	_progress = clampf(value, 0.0, 1.0)
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


## Điểm thứ s (0..1) trên đường: dốc dần lên về phía cờ + một nhịp sóng.
func _point(s: float) -> Vector2:
	var x0 := 22.0
	var x1 := size.x - 24.0
	var y0 := size.y * 0.74
	var y1 := size.y * 0.26
	var amp := size.y * 0.26
	return Vector2(lerpf(x0, x1, s), lerpf(y0, y1, s) - amp * sin(s * TAU))


func _draw() -> void:
	if size.x < 40.0 or size.y < 30.0:
		return
	var s_fail := maxf(_progress * anim, 0.04)
	var done := PackedVector2Array()
	for i in SAMPLES + 1:
		var s := float(i) / SAMPLES
		if s <= s_fail:
			done.append(_point(s))
	done.append(_point(s_fail))
	# Đoạn còn lại: các nét đứt ngắn
	var i := int(ceil(s_fail * SAMPLES))
	while i < SAMPLES:
		if (i - int(ceil(s_fail * SAMPLES))) % 2 == 0:
			var a := _point(maxf(float(i) / SAMPLES, s_fail))
			var b := _point(minf(float(i + 1) / SAMPLES, 1.0))
			draw_line(a, b, color_left, line_width, true)
		i += 1
	if done.size() >= 2:
		draw_polyline(done, color_done, line_width, true)

	# Điểm xuất phát
	var p0 := _point(0.0)
	draw_circle(p0, 9.0, color_ink)
	draw_circle(p0, 6.5, color_start)

	# Cờ đích
	var pf := _point(1.0)
	draw_line(pf, pf + Vector2(0, -26), color_ink, 3.0, true)
	draw_colored_polygon(PackedVector2Array([
		pf + Vector2(1, -26), pf + Vector2(17, -20), pf + Vector2(1, -14)]), color_fail)

	# Dấu ✕ nơi thua
	var pe := _point(s_fail)
	draw_circle(pe, 14.0, color_fail)
	draw_circle(pe, 11.0, Color.WHITE)
	var r := 5.0
	draw_line(pe + Vector2(-r, -r), pe + Vector2(r, r), color_fail, 3.0, true)
	draw_line(pe + Vector2(-r, r), pe + Vector2(r, -r), color_fail, 3.0, true)
