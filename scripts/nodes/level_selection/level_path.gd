class_name LevelMapPath
extends Node2D
## ============================================================================
## LevelMapPath — ĐƯỜNG NỐI UỐN LƯỢN giữa TẤT CẢ các nút màn (road map)
##
## MỘT đường duy nhất uốn lượn qua đúng tâm mọi nút: mỗi đoạn nối 2 nút được chèn
## thêm 1 ĐIỂM UỐN ở giữa, lệch sang 2 bên XEN KẼ ⇒ đường cong dạng chữ S liên
## tiếp (không phải đường thẳng nối nút). Toàn bộ đi qua 1 đường cong Catmull-Rom
## nên không có "khúc"/gãy góc ở các mối nối.
##
## Trạng thái thể hiện qua màu / kiểu nét TỪNG ĐOẠN (đoạn i nối nút i → nút i+1):
##   COMPLETE  → nét mực navy (#164663) — đứt dài như bút kẻ (`complete_dashed`) hoặc liền
##   SKIPPED   → nét đứt màu cam (#E8A020)
##   UPCOMING  → nét đứt màu xanh mực (#507894)
##   LOCKED    → chấm tròn nhỏ xám nhạt (#B9C7D3)
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

@export_group("Màu theo trạng thái")
@export var color_complete := Color(0.0863, 0.2745, 0.3882, 1.0)  # Mực navy #164663
@export var color_skipped := Color(0.910, 0.580, 0.120, 1.0)    # Cam cảnh báo
@export var color_upcoming := Color(0.320, 0.480, 0.620, 0.95)  # Xanh mực đậm rõ nét
@export var color_locked := Color(0.725, 0.780, 0.827, 1.0)      # Xám nhạt #B9C7D3

@export_group("Độ dày nét theo trạng thái")
## Nét mảnh kiểu bút kẻ trên giấy ô ly (khớp mockup `level_final`)
@export var width_complete := 4.0
@export var width_skipped := 4.0
@export var width_upcoming := 3.5
@export var width_locked := 3.5

@export_group("Gờ đáy (khớp nút màn kiểu gờ)")
## Mỗi nét được vẽ 2 lớp: lớp dưới tối hơn, lệch xuống `edge_offset` px ⇒ đường có "gờ"
## giống gờ đáy của nút màn. `edge_offset` = 3 khớp gờ 6px thiết kế / 2 của art nút.
## Mặc định 0 = nét PHẲNG (không gờ) cho hợp phong cách giấy vở; đặt > 0 để bật lại gờ.
@export_range(0.0, 10.0, 0.5) var edge_offset := 0.0
@export_range(0.0, 0.8, 0.05) var edge_darken := 0.35

@export_group("Nét đứt / lấy mẫu")
## Độ dài 1 gạch và 1 khe của nét đứt (px)
@export var dash_length := 14.0
@export var dash_gap := 9.0
## Đoạn đã hoàn thành vẽ bằng nét ĐỨT dài (true, như mockup) hay nét LIỀN (false, kiểu cũ)
@export var complete_dashed := true
## Đoạn KHOÁ vẽ bằng CHẤM tròn nhỏ: độ dài chấm / khe (px)
@export var locked_dash_length := 2.5
@export var locked_dash_gap := 10.0
## Bước lấy mẫu cho nét LIỀN (px) — nhỏ thì đường cong mượt hơn
@export var solid_sample_step := 3.0

## Node con — bind bằng `@export` trong `level_path.tscn`
@export var path_node: Path2D = null

## Curve trọn vẹn qua mọi nút (đặt vào `Path` để test/soi "nút nằm đúng trên đường")
var _curve: Curve2D = null
## Các nét đã cắt sẵn theo trạng thái: {points, color, width, dashed}
var _strokes: Array[Dictionary] = []


## Dựng đường nối qua `points` (tâm các nút, thứ tự dưới → trên).
## `states[i]` = trạng thái của đoạn nối `points[i]` → `points[i + 1]`.
## `sway` = độ lệch ngang của ĐIỂM UỐN giữa mỗi đoạn (0 = đường thẳng qua nút).
func setup(points: Array[Vector2], states: Array[int], sway: float = 0.0) -> void:
	_strokes.clear()
	_curve = null
	if points.size() >= 2:
		_curve = _build_road(_build_route(points, sway))
		_build_strokes(points, states)
	if path_node != null:
		path_node.curve = _curve if _curve != null else Curve2D.new()
	queue_redraw()


## Chèn 1 ĐIỂM UỐN vào giữa mỗi đoạn nút→nút, lệch XEN KẼ 2 bên theo trục ngang
## (đoạn dọc) hoặc trục dọc (đoạn ngang) — nút vẫn nằm đúng trên đường vì
## Catmull-Rom đi QUA mọi điểm kiểm soát.
func _build_route(points: Array[Vector2], sway: float) -> Array[Vector2]:
	if sway <= 0.0:
		return points
	var route: Array[Vector2] = [points[0]]
	for index in points.size() - 1:
		var from := points[index]
		var to := points[index + 1]
		var delta := to - from
		# Đoạn chủ yếu DỌC thì uốn ngang, chủ yếu NGANG thì uốn dọc
		var axis := Vector2(1.0, 0.0) if absf(delta.y) >= absf(delta.x) else Vector2(0.0, 1.0)
		var side := 1.0 if index % 2 == 0 else -1.0
		route.append((from + to) * 0.5 + axis * (side * sway))
		route.append(to)
	return route


## Đường cong Catmull-Rom qua mọi điểm: tiếp tuyến tại mỗi nút = (điểm trước → điểm sau)/6
## nên 2 đoạn kề nhau dùng CHUNG một tiếp tuyến tại điểm chung ⇒ trơn liền mạch.
func _build_road(route: Array[Vector2]) -> Curve2D:
	var curve := Curve2D.new()
	var count := route.size()
	for index in count:
		var prev := route[index - 1] if index > 0 else route[index] * 2.0 - route[index + 1]
		var next := route[index + 1] if index < count - 1 else route[index] * 2.0 - route[index - 1]
		var tangent := (next - prev) / 6.0
		curve.add_point(route[index], -tangent, tangent)
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
		if state == PathState.COMPLETE and not complete_dashed:
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
	var distance := from_d + (solid_sample_step if skip_first else 0.0)
	while distance < to_d:
		points.append(_curve.sample_baked(distance))
		distance += solid_sample_step
	points.append(_curve.sample_baked(to_d))
	return points


func _solid_stroke(points: PackedVector2Array) -> Dictionary:
	return {"points": points, "color": color_complete, "width": width_complete, "dashed": false}


## Nét đứt của 1 đoạn: gạch nối tiếp nhau dọc theo cung (màu/độ rộng theo trạng thái)
func _dashed_stroke(from_d: float, to_d: float, state: int) -> Dictionary:
	var points := PackedVector2Array()
	var distance := from_d
	var dash := dash_length
	var gap := dash_gap
	if state == PathState.LOCKED:
		dash = locked_dash_length
		gap = locked_dash_gap
	while distance < to_d:
		points.append(_curve.sample_baked(distance))
		points.append(_curve.sample_baked(minf(distance + dash, to_d)))
		distance += dash + gap
	var color := color_locked
	var width := width_locked
	match state:
		PathState.COMPLETE:
			color = color_complete
			width = width_complete
		PathState.SKIPPED:
			color = color_skipped
			width = width_skipped
		PathState.UPCOMING:
			color = color_upcoming
			width = width_upcoming
	return {"points": points, "color": color, "width": width, "dashed": true}


func _draw() -> void:
	# Lượt 0: GỜ ĐÁY (tối, lệch xuống) · lượt 1: MẶT đường — cùng kiểu với nút màn có gờ
	for pass_index in 2:
		var is_edge := pass_index == 0
		if is_edge and edge_offset <= 0.0:
			continue
		draw_set_transform(Vector2(0.0, edge_offset) if is_edge else Vector2.ZERO)
		for stroke in _strokes:
			var points: PackedVector2Array = stroke["points"]
			var color: Color = stroke["color"]
			if is_edge:
				color = color.darkened(edge_darken)
			var width: float = stroke["width"]
			if bool(stroke["dashed"]):
				draw_multiline(points, color, width)
			else:
				draw_polyline(points, color, width, true)
	draw_set_transform(Vector2.ZERO)
