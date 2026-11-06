class_name LevelMapPath
extends Node2D
## ============================================================================
## LevelMapPath — ĐƯỜNG NỐI giữa TẤT CẢ các nút màn (road map), kiểu VỆT BÚT DẠ QUANG
##
## MỘT đường uốn lượn qua đúng tâm mọi nút (Catmull-Rom, không gãy góc). Mỗi ĐOẠN nối 2
## điểm được tô thành một "vệt dạ quang" bản rộng, màu theo trạng thái (đoạn i nối điểm i → i+1):
##   COMPLETE  → vệt vàng + hàng chấm mực vàng đậm chạy giữa vệt (như gạch chân bút dạ)
##   UPCOMING  → vệt xanh nhạt (màn kế tiếp, chưa chơi)
##   SKIPPED   → vệt cam nhạt (đã bỏ qua — nhắc người chơi quay lại)
##   LOCKED    → vệt xám nhạt, mảnh hơn
## Mọi màu / độ dày là @export để đổi theme không cần sửa code.
##
## ANIMATION "VẼ DẦN": mỗi đoạn có tiến độ 0..1 (`_progress`). Sau khi hoàn thành màn, bản đồ
## gọi `hide_range()` rồi `play_reveal_range()` để vệt dạ quang được TÔ DẦN từ nút vừa xong
## sang nút kế (đầu vệt có chấm sáng như đầu bút).
## ============================================================================

## Scene contract
## Exports:  color_complete, color_complete_dots, color_upcoming, color_skipped, color_locked, width_ribbon, width_locked, dots_width, dots_length, dots_gap, sample_step, path_node
## Emits:    (none)
## Handlers wired in scene: (none)
## Subscribes in code (EventBus/Model): (none)

enum PathState {
	LOCKED,   ## Cả 2 node chưa unlock
	UPCOMING, ## Node trước đã mở, node sau chưa chơi
	SKIPPED,  ## Node trước bị skip
	COMPLETE, ## Node trước đã hoàn thành
}

@export_group("Màu vệt theo trạng thái")
@export var color_complete := Color(1.0, 0.878, 0.4, 1.0)        # Dạ quang vàng #FFE066
@export var color_complete_dots := Color(0.949, 0.718, 0.020, 1.0) # Chấm vàng đậm #F2B705
@export var color_upcoming := Color(0.749, 0.890, 1.0, 1.0)       # Xanh nhạt #BFE3FF
@export var color_skipped := Color(1.0, 0.827, 0.69, 1.0)         # Cam nhạt #FFD3B0
@export var color_locked := Color(0.894, 0.914, 0.933, 1.0)       # Xám nhạt #E4E9EE

@export_group("Độ dày vệt")
@export var width_ribbon := 16.0
@export var width_locked := 12.0
## Nhân với cỡ nút (map đặt = node_scale) để vệt luôn cân với nút
@export_range(0.2, 3.0, 0.01) var width_scale := 1.0

@export_group("Hàng chấm giữa vệt (đoạn COMPLETE)")
@export var dots_width := 2.5
@export var dots_length := 1.0
@export var dots_gap := 7.0

@export_group("Lấy mẫu")
## Bước lấy mẫu dọc cung (px) — nhỏ thì đường cong mượt hơn
@export var sample_step := 3.0
## Giữ cho tương thích map cũ (gờ đáy): vệt dạ quang phẳng nên mặc định không dùng
@export_range(0.0, 10.0, 0.5) var edge_offset := 0.0

## Node con — bind bằng `@export` trong `level_path.tscn`
@export var path_node: Path2D = null

var _curve: Curve2D = null
## Mỗi đoạn: {points: PackedVector2Array, dots: PackedVector2Array, color, width, state}
var _segments: Array[Dictionary] = []
## Tiến độ vẽ của từng đoạn (0 = ẩn · 1 = đủ)
var _progress := PackedFloat32Array()


## Dựng đường nối qua `points` (tâm các nút, thứ tự dưới → trên).
## `states[i]` = trạng thái của đoạn nối `points[i]` → `points[i + 1]`.
## `sway` = độ lệch ngang của ĐIỂM UỐN giữa mỗi đoạn (0 = đường thẳng qua nút).
func setup(points: Array[Vector2], states: Array[int], sway: float = 0.0) -> void:
	_segments.clear()
	_progress = PackedFloat32Array()
	_curve = null
	if points.size() >= 2:
		_curve = _build_road(_build_route(points, sway))
		_build_segments(points, states)
	if path_node != null:
		path_node.curve = _curve if _curve != null else Curve2D.new()
	queue_redraw()


func _build_route(points: Array[Vector2], sway: float) -> Array[Vector2]:
	if sway <= 0.0:
		return points
	var route: Array[Vector2] = [points[0]]
	for index in points.size() - 1:
		var from := points[index]
		var to := points[index + 1]
		var delta := to - from
		var axis := Vector2(1.0, 0.0) if absf(delta.y) >= absf(delta.x) else Vector2(0.0, 1.0)
		var side := 1.0 if index % 2 == 0 else -1.0
		route.append((from + to) * 0.5 + axis * (side * sway))
		route.append(to)
	return route


func _build_road(route: Array[Vector2]) -> Curve2D:
	var curve := Curve2D.new()
	var count := route.size()
	for index in count:
		var prev := route[index - 1] if index > 0 else route[index] * 2.0 - route[index + 1]
		var next := route[index + 1] if index < count - 1 else route[index] * 2.0 - route[index - 1]
		var tangent := (next - prev) / 6.0
		curve.add_point(route[index], -tangent, tangent)
	return curve


## Cắt curve thành từng đoạn (mỗi đoạn một vệt riêng, màu theo trạng thái)
func _build_segments(points: Array[Vector2], states: Array[int]) -> void:
	var bounds := PackedFloat32Array()
	for point in points:
		bounds.append(_curve.get_closest_offset(point))
	for index in points.size() - 1:
		var state: int = states[index] if index < states.size() else PathState.LOCKED
		var from_d := bounds[index]
		var to_d := bounds[index + 1]
		var line := PackedVector2Array()
		var distance := from_d
		while distance < to_d:
			line.append(_curve.sample_baked(distance))
			distance += sample_step
		line.append(_curve.sample_baked(to_d))
		var dots := PackedVector2Array()
		if state == PathState.COMPLETE:
			distance = from_d
			while distance < to_d:
				dots.append(_curve.sample_baked(distance))
				dots.append(_curve.sample_baked(minf(distance + dots_length, to_d)))
				distance += dots_length + dots_gap
		_segments.append({
			"points": line, "dots": dots,
			"color": _color_of(state),
			"width": width_locked if state == PathState.LOCKED else width_ribbon,
		})
		_progress.append(1.0)


func _color_of(state: int) -> Color:
	match state:
		PathState.COMPLETE:
			return color_complete
		PathState.UPCOMING:
			return color_upcoming
		PathState.SKIPPED:
			return color_skipped
	return color_locked


# ---------------------------------------------------------------------------
# Animation "vẽ dần"
# ---------------------------------------------------------------------------
## Ẩn các đoạn [from_point, to_point) (chuẩn bị cho `play_reveal_range`)
func hide_range(from_point: int, to_point: int) -> void:
	for index in range(maxi(from_point, 0), mini(to_point, _progress.size())):
		_progress[index] = 0.0
	queue_redraw()


## Hiện NGAY (không animation) các đoạn [from_point, to_point)
func show_range(from_point: int, to_point: int) -> void:
	for index in range(maxi(from_point, 0), mini(to_point, _progress.size())):
		_progress[index] = 1.0
	queue_redraw()


## Tô dần các đoạn [from_point, to_point) lần lượt từ đầu tới cuối; trả về Tween để `await`
func play_reveal_range(from_point: int, to_point: int, duration: float = 0.7) -> Tween:  # EXCEPTION(R4-tween): endpoints tính lúc chạy (tween dựng bằng code — docs/refactor/tween_backlog.md)
	var first := maxi(from_point, 0)
	var last := mini(to_point, _progress.size())
	var count := last - first
	if count <= 0 or not is_inside_tree():
		return null
	var tween := create_tween()  # EXCEPTION(R4-tween): endpoints tính lúc chạy (tween dựng bằng code — docs/refactor/tween_backlog.md)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)  # EXCEPTION(R4-tween): endpoints tính lúc chạy (tween dựng bằng code — docs/refactor/tween_backlog.md)
	tween.tween_method(_set_reveal.bind(first, count), 0.0, float(count), duration)
	return tween


func _set_reveal(value: float, first: int, count: int) -> void:
	for offset in count:
		_progress[first + offset] = clampf(value - float(offset), 0.0, 1.0)
	queue_redraw()


# ---------------------------------------------------------------------------
# Vẽ
# ---------------------------------------------------------------------------
func _draw() -> void:
	var front := Vector2.ZERO
	var front_radius := 0.0
	var has_front := false
	for index in _segments.size():
		var progress := _progress[index]
		if progress <= 0.0:
			continue
		var segment: Dictionary = _segments[index]
		var points: PackedVector2Array = segment["points"]
		var color: Color = segment["color"]
		var width: float = float(segment["width"]) * width_scale
		var shown := clampi(ceili(float(points.size()) * progress), 2, points.size())
		var part := points.slice(0, shown)
		draw_polyline(part, color, width, true)
		# Đầu vệt tròn (cap) — nằm dưới nút nên chỉ lộ khi đang vẽ dần
		draw_circle(part[0], width * 0.5, color)
		draw_circle(part[part.size() - 1], width * 0.5, color)
		var dots: PackedVector2Array = segment["dots"]
		if dots.size() >= 2:
			var pairs := clampi(ceili(float(dots.size()) * 0.5 * progress), 0, int(dots.size() * 0.5))
			if pairs > 0:
				draw_multiline(dots.slice(0, pairs * 2), color_complete_dots, dots_width * width_scale, true)
		if progress < 1.0:
			front = part[part.size() - 1]
			front_radius = width * 0.62
			has_front = true
	if has_front:
		draw_circle(front, front_radius, Color(1.0, 1.0, 1.0, 0.85))
		draw_circle(front, front_radius * 0.55, color_complete_dots)
