class_name LevelMapPath
extends Node2D
## ============================================================================
## LevelMapPath — ĐƯỜNG NỐI LIỀN MẠCH giữa TẤT CẢ các nút màn (road map)
##
## MỘT đường duy nhất uốn lượn qua đúng tâm mọi nút (đường cong Catmull-Rom với tiếp
## tuyến liên tục tại từng nút) — không còn từng cung rời ghép theo cặp nên không có
## "khúc"/gãy góc giữa các đoạn nối.
##
## Trạng thái thể hiện qua màu / kiểu nét TỪNG ĐOẠN (đoạn i nối nút i → nút i+1):
##   COMPLETE  → nét liền đậm màu đỏ ink (#D84444); các đoạn liền nhau GỘP thành 1 nét
##   SKIPPED   → nét đứt màu cam (#E8A020)
##   UPCOMING  → nét đứt màu xanh mực (#507894)
##   LOCKED    → nét đứt màu xám (#8FA0B0)
##
## Quy ước của project: node con (`Path` giữ curve trọn vẹn) khai trong
## `level_path.tscn`; script chỉ còn phần ĐỘNG: dựng curve + cắt nét theo trạng thái.
## ============================================================================

enum PathState {
	LOCKED,   ## Cả 2 node chưa unlock
	UPCOMING, ## Node trước đã mở, node sau chưa chơi
	SKIPPED,  ## Node trước bị skip
	COMPLETE, ## Node trước đã hoàn thành
}

## Màu theo trạng thái
const COLOR_COMPLETE  := Color(0.847, 0.267, 0.267, 1.0)   # Đỏ ink mực phê
const COLOR_SKIPPED   := Color(0.910, 0.580, 0.120, 1.0)   # Cam cảnh báo
const COLOR_UPCOMING  := Color(0.320, 0.480, 0.620, 0.95)  # Xanh mực đậm rõ nét
const COLOR_LOCKED    := Color(0.550, 0.640, 0.720, 0.65)  # Xám xanh mờ hơn

const WIDTH_COMPLETE  := 5.0
const WIDTH_SKIPPED   := 4.5
const WIDTH_UPCOMING  := 4.0
const WIDTH_LOCKED    := 3.5

## Độ dài 1 gạch và 1 khe của nét đứt (px)
const DASH_LENGTH := 10.0
const DASH_GAP    := 7.0
## Bước lấy mẫu cho nét LIỀN (px) — nhỏ thì đường cong mượt hơn
const SOLID_SAMPLE_STEP := 3.0

## Node con — bind bằng `@export` trong `level_path.tscn`
@export var path_node: Path2D = null

## Curve trọn vẹn qua mọi nút (đặt vào `Path` để test/soi "nút nằm đúng trên đường")
var _curve: Curve2D = null
## Các nét đã cắt sẵn theo trạng thái: {points, color, width, dashed}
var _strokes: Array[Dictionary] = []


## Dựng đường nối qua `points` (tâm các nút, thứ tự dưới → trên).
## `states[i]` = trạng thái của đoạn nối `points[i]` → `points[i + 1]`.
func setup(points: Array[Vector2], states: Array[int]) -> void:
	_strokes.clear()
	_curve = null
	if points.size() >= 2:
		_curve = _build_road(points)
		_build_strokes(points, states)
	if path_node != null:
		path_node.curve = _curve if _curve != null else Curve2D.new()
	queue_redraw()


## Đường cong Catmull-Rom qua mọi điểm: tiếp tuyến tại mỗi nút = (nút trước → nút sau)/6
## nên 2 đoạn kề nhau dùng CHUNG một tiếp tuyến tại nút chung ⇒ đường trơn liền mạch.
func _build_road(points: Array[Vector2]) -> Curve2D:
	var curve := Curve2D.new()
	var count := points.size()
	for index in count:
		var prev := points[index - 1] if index > 0 else points[index] * 2.0 - points[index + 1]
		var next := points[index + 1] if index < count - 1 else points[index] * 2.0 - points[index - 1]
		var tangent := (next - prev) / 6.0
		curve.add_point(points[index], -tangent, tangent)
	return curve


## Cắt curve thành từng nét: các đoạn COMPLETE liền nhau GỘP thành 1 nét liền đỏ;
## đoạn còn lại cắt thành gạch đứt theo màu trạng thái.
func _build_strokes(points: Array[Vector2], states: Array[int]) -> void:
	var bounds := PackedFloat32Array()
	for point in points:
		bounds.append(_curve.get_closest_offset(point))
	var solid_run := PackedVector2Array()
	for index in points.size() - 1:
		var from_d := bounds[index]
		var to_d := bounds[index + 1]
		var state: int = states[index] if index < states.size() else PathState.LOCKED
		if state == PathState.COMPLETE:
			solid_run.append_array(_sample_range(from_d, to_d, not solid_run.is_empty()))
			continue
		if not solid_run.is_empty():
			_strokes.append(_solid_stroke(solid_run))
			solid_run = PackedVector2Array()
		_strokes.append(_dashed_stroke(from_d, to_d, state))
	if not solid_run.is_empty():
		_strokes.append(_solid_stroke(solid_run))


## Lấy mẫu curve trong khoảng [from_d, to_d] (đơn vị: độ dài cung px)
func _sample_range(from_d: float, to_d: float, skip_first := false) -> PackedVector2Array:
	var points := PackedVector2Array()
	var distance := from_d + (SOLID_SAMPLE_STEP if skip_first else 0.0)
	while distance < to_d:
		points.append(_curve.sample_baked(distance))
		distance += SOLID_SAMPLE_STEP
	points.append(_curve.sample_baked(to_d))
	return points


func _solid_stroke(points: PackedVector2Array) -> Dictionary:
	return {"points": points, "color": COLOR_COMPLETE, "width": WIDTH_COMPLETE, "dashed": false}


## Nét đứt của 1 đoạn: gạch nối tiếp nhau dọc theo cung (màu/độ rộng theo trạng thái)
func _dashed_stroke(from_d: float, to_d: float, state: int) -> Dictionary:
	var points := PackedVector2Array()
	var distance := from_d
	while distance < to_d:
		points.append(_curve.sample_baked(distance))
		points.append(_curve.sample_baked(minf(distance + DASH_LENGTH, to_d)))
		distance += DASH_LENGTH + DASH_GAP
	var color := COLOR_LOCKED
	var width := WIDTH_LOCKED
	match state:
		PathState.SKIPPED:
			color = COLOR_SKIPPED
			width = WIDTH_SKIPPED
		PathState.UPCOMING:
			color = COLOR_UPCOMING
			width = WIDTH_UPCOMING
	return {"points": points, "color": color, "width": width, "dashed": true}


func _draw() -> void:
	for stroke in _strokes:
		var points: PackedVector2Array = stroke["points"]
		var color: Color = stroke["color"]
		var width: float = stroke["width"]
		if bool(stroke["dashed"]):
			draw_multiline(points, color, width)
		else:
			draw_polyline(points, color, width, true)
