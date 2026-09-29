class_name WallSegment
extends Line2D
## ============================================================================
## View: 1 đoạn tường (dùng Line2D nối 2 điểm neo Anchor).
## Màu theo state: "visible" (tường thật), "invisible" (ẩn),
##                 "suspected" (tường nghi ngờ - vàng cam), "hit" (va chạm - đỏ).
## Tích hợp animation vẽ nét bút chì (Pencil Stroke) & phản hồi va chạm nảy nét.
## ============================================================================

var _state := "invisible"
var _base_width := 11.0
var _p1 := Vector2.ZERO
var _p2 := Vector2.ZERO
var _preview_pulse: Tween = null

const COLOR_VISIBLE := Color(0.12, 0.16, 0.23, 1.0)        # #1E283A
const COLOR_SUSPECTED := Color(0.77, 0.52, 0.23, 1.0)      # #C4843A
const COLOR_HIT := Color(0.85, 0.27, 0.27, 1.0)            # #D84444
## Wall Builder: đoạn tường người chơi TỰ DỰNG (xanh lá — khớp tông "xây tường" của mode)
const COLOR_BUILT := Color(0.18039216, 0.49019608, 0.19607843, 1.0)   # #2E7D32


func get_state() -> String:
	return _state


func set_wall_points(p1: Vector2, p2: Vector2) -> void:
	_p1 = p1
	_p2 = p2
	points = PackedVector2Array([p1, p2])


func set_line_width(w: float) -> void:
	_base_width = w
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
		"built":
			# Wall Builder: đoạn tường người chơi TỰ DỰNG
			visible = true
			default_color = COLOR_BUILT
		"hit":
			visible = true
			default_color = COLOR_HIT


## Hiệu ứng xuất hiện kèm nét vẽ bút chì lướt từ điểm đầu đến điểm cuối
func animate_appear() -> void:
	animate_stroke_draw(0.14)


## Hiệu ứng nét bút chì/mực kéo dài từ p1 sang p2
func animate_stroke_draw(duration := 0.12) -> void:
	if points.size() < 2:
		modulate.a = 0.0
		var tw_fade := create_tween()
		tw_fade.tween_property(self, "modulate:a", 1.0, duration)
		return

	var start_pt := points[0]
	var end_pt := points[1]
	points = PackedVector2Array([start_pt, start_pt])
	visible = true
	modulate.a = 1.0

	var tw := create_tween()
	tw.tween_method(func(prog: float) -> void:
		points = PackedVector2Array([start_pt, start_pt.lerp(end_pt, prog)])
	, 0.0, 1.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## Bật/tắt kiểu NÉT ĐỨT (Wall Builder tutorial: preview "tường đứt đoạn").
## Line2D không có nét đứt gốc — dùng texture lặp như chất liệu bút chì (PenSkin).
func set_dashed(on: bool) -> void:
	if on:
		var w := maxf(width, 1.0)
		texture_mode = Line2D.LINE_TEXTURE_TILE
		texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		texture = PenSkin.dash_texture_for(w * 2.2, w)
	else:
		texture_mode = Line2D.LINE_TEXTURE_NONE
		texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
		texture = null


## Nhấp nháy nhẹ lớp preview (tường đứt đoạn) để mắt bám vào — tắt thì trả alpha về 1
func set_preview_pulse(on: bool) -> void:
	if _preview_pulse != null and _preview_pulse.is_valid():
		_preview_pulse.kill()
	_preview_pulse = null
	if on:
		_preview_pulse = create_tween().set_loops()
		_preview_pulse.tween_property(self, "modulate:a", 0.45, 0.7)
		_preview_pulse.tween_property(self, "modulate:a", 1.0, 0.7)
	else:
		modulate.a = 1.0


## Hiệu ứng nảy dày nét và đỏ rực khi người chơi đâm trúng tường
func flash_hit_then_stay_visible() -> void:
	set_state("hit")
	var target_width := _base_width * 1.75
	var tw := create_tween()
	# Nở to nét tường giật mình
	tw.tween_property(self, "width", target_width, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "width", _base_width, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.28)
	tw.tween_callback(func() -> void:
		set_state("visible")
		width = _base_width
	)
