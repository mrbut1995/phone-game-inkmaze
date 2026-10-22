class_name DailyRoad
extends Control
## ============================================================================
## ĐƯỜNG PHẦN THƯỞNG của màn Daily (scripts/nodes/daily/road_path.gd)
##
## Vẽ con đường nét chấm bút chì đi từ ngôi sao tổng (`start`) qua lần lượt các mốc
## (`slots_host` — mỗi con = TÂM của một mốc, theo thứ tự). Đoạn đã đi (`progress`) tô hổ phách,
## phần còn lại tô xám xanh. Bút chì (`pencil`) đứng ở đầu phần đã đi.
##
## `progress` tính theo ĐOẠN: 0 = ở sao · 1 = tới mốc 1 · 2.5 = giữa mốc 2 và mốc 3 …
## Màn Daily/DailyLayout chỉ đặt số này (và gọi `rebuild()` khi bố cục đổi); toàn bộ vị trí
## sao/mốc/bút chì nằm trong SCENE `scenes/layout/portrait/daily.tscn`.
## ============================================================================

## Sao tổng (điểm xuất phát). Tâm của nó là gốc đường.
@export var start: Control = null
## Node chứa các điểm mốc (Control con, vị trí = tâm mốc)
@export var slots_host: Control = null
## Gốc bút chì (Control không kích thước) — đặt đúng đầu phần đã đi
@export var pencil: Control = null
@export var dot_radius := 3.0
@export var dot_spacing := 14.0
## Độ cong: tay nắm Bezier = khoảng cách ngang × hệ số này
@export_range(0.0, 1.0, 0.01) var bend := 0.55
## Bán kính "trùm" của sao: bút chì không chui vào dưới sao khi chưa có tiến độ
@export var start_clearance := 34.0
@export var color_done := Color("#FBBF24")
@export var color_todo := Color("#BFD0DE")
## Tiến độ theo đoạn (0..số mốc)
@export_range(0.0, 8.0, 0.001) var progress := 0.0: set = set_progress

const SAMPLES := 40

var _segs: Array[PackedVector2Array] = []
var _seg_len: Array[float] = []
var _marker := Vector2.ZERO


func _ready() -> void:
	resized.connect(rebuild)
	rebuild.call_deferred()


## Dựng lại hình học đường từ vị trí hiện tại của sao + các mốc (gọi sau khi bố cục đổi cỡ)
func rebuild() -> void:
	var pts := _node_points()
	_segs.clear()
	_seg_len.clear()
	for i in range(1, pts.size()):
		var a := pts[i - 1]
		var b := pts[i]
		var dx := (b.x - a.x) * bend
		var c1 := a + Vector2(dx, 0.0)
		var c2 := b - Vector2(dx, 0.0)
		var seg := PackedVector2Array()
		var length := 0.0
		for k in SAMPLES + 1:
			var p := a.bezier_interpolate(c1, c2, b, float(k) / SAMPLES)
			if k > 0:
				length += p.distance_to(seg[k - 1])
			seg.append(p)
		_segs.append(seg)
		_seg_len.append(length)
	_update_marker()
	queue_redraw()


func set_progress(value: float) -> void:
	progress = clampf(value, 0.0, maxf(float(_segs.size()), 8.0))
	_update_marker()
	queue_redraw()


## Vị trí (toạ độ cục bộ của Road) của đầu phần đã đi — nơi bút chì đứng
func marker_position() -> Vector2:
	return _marker


## Số đoạn của đường (= số mốc)
func segment_count() -> int:
	return _segs.size()


func _node_points() -> PackedVector2Array:
	var out := PackedVector2Array()
	var inv := get_global_transform().affine_inverse()
	if start != null:
		out.append(inv * (start.get_global_transform() * (start.size * 0.5)))
	if slots_host != null:
		for child in slots_host.get_children():
			var c := child as Control
			if c != null:
				out.append(inv * (c.get_global_transform() * (c.size * 0.5)))
	return out


## Độ dài phần đã đi (theo cung), tính từ gốc đường
func _progress_length() -> float:
	var n := _segs.size()
	if n == 0:
		return 0.0
	var p := clampf(progress, 0.0, float(n))
	var whole := mini(int(p), n - 1)
	var frac := p - float(whole)
	var length := 0.0
	for i in whole:
		length += _seg_len[i]
	var seg := _segs[whole]
	var upto := frac * SAMPLES
	var k := mini(int(upto), SAMPLES - 1)
	for j in k:
		length += seg[j].distance_to(seg[j + 1])
	length += seg[k].distance_to(seg[k + 1]) * (upto - float(k))
	return length


## Điểm trên đường ở độ dài `dist` tính từ gốc
func _point_at(dist: float) -> Vector2:
	var travelled := 0.0
	var last := Vector2.ZERO
	for seg in _segs:
		for k in range(1, seg.size()):
			var l := seg[k - 1].distance_to(seg[k])
			if travelled + l >= dist:
				return seg[k - 1].lerp(seg[k], (dist - travelled) / maxf(l, 0.0001))
			travelled += l
		last = seg[seg.size() - 1]
	return last


func _update_marker() -> void:
	if _segs.is_empty():
		return
	_marker = _point_at(maxf(_progress_length(), start_clearance))
	if pencil != null:
		pencil.position = _marker


func _draw() -> void:
	if _segs.is_empty():
		return
	var done_len := _progress_length()
	var travelled := 0.0
	var next_dot := dot_spacing * 0.5
	for seg in _segs:
		for k in range(1, seg.size()):
			var a := seg[k - 1]
			var b := seg[k]
			var l := a.distance_to(b)
			while next_dot <= travelled + l:
				var pos := a.lerp(b, (next_dot - travelled) / maxf(l, 0.0001))
				draw_circle(pos, dot_radius, color_done if next_dot <= done_len else color_todo)
				next_dot += dot_spacing
			travelled += l
