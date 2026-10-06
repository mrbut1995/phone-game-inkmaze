class_name LevelMapPath
extends Node2D
## ============================================================================
## LevelMapPath — Vẽ đoạn nối đường cong mượt mà giữa 2 LevelMapNode
## Trạng thái thể hiện qua màu / kiểu nét:
##   COMPLETE  → nét liền đậm màu đỏ ink (#D84444) qua Line2D
##   SKIPPED   → nét đứt màu cam (#E8A020) qua draw_multiline
##   UPCOMING  → nét đứt màu xanh mực (#507894) qua draw_multiline
##   LOCKED    → nét đứt màu xám (#8FA0B0) qua draw_multiline
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

# Dữ liệu vẽ nét đứt bằng draw_multiline
var _dash_points: PackedVector2Array = PackedVector2Array()
var _dash_color: Color               = Color.WHITE
var _dash_width: float               = 4.0

var _path_node: Path2D = null
var _line_node: Line2D = null


func _get_line() -> Line2D:
	if _line_node != null and is_instance_valid(_line_node):
		return _line_node
	if has_node("Line"):
		_line_node = get_node("Line") as Line2D
	elif has_node("Path/Line"):
		_line_node = get_node("Path/Line") as Line2D
	elif has_node("Line2D"):
		_line_node = get_node("Line2D") as Line2D
	else:
		for child in get_children():
			if child is Line2D:
				_line_node = child
				break
	return _line_node


func _get_path() -> Path2D:
	if _path_node != null and is_instance_valid(_path_node):
		return _path_node
	if has_node("Path"):
		_path_node = get_node("Path") as Path2D
	elif has_node("Path2D"):
		_path_node = get_node("Path2D") as Path2D
	else:
		for child in get_children():
			if child is Path2D:
				_path_node = child
				break
	return _path_node


## Vẽ đoạn nối cong mượt mà từ điểm `from` đến `to` dùng Curve2D
func setup(from: Vector2, to: Vector2, path_state: PathState) -> void:
	var path_node := _get_path()
	var line_node := _get_line()

	# 1. Tạo đường cong vòng cung mượt mà tuyệt đối giữa 2 node
	var curve := Curve2D.new()
	var chord := to - from
	var chord_len := chord.length()
	var chord_dir := chord.normalized()
	var mid := (from + to) * 0.5
	var perp := Vector2(-chord_dir.y, chord_dir.x)

	# Hướng uốn cong ra phía ngoài biên bản đồ
	var curve_dir := 1.0 if from.x > to.x else -1.0
	if (perp.x * curve_dir) < 0.0:
		perp = -perp

	# Điểm đỉnh của vòng cung
	var arc_mid := mid + perp * 26.0

	# Tiếp tuyến tại đỉnh arc_mid song song tuyệt đối với chord_dir (đối xứng 180 độ)
	# để đảm bảo đường cong C1 trơn mượt 100%, không bị gãy góc nhọn
	var mid_tangent := chord_dir * (chord_len * 0.25)

	curve.add_point(from, Vector2.ZERO, (arc_mid - from) * 0.4)
	curve.add_point(arc_mid, -mid_tangent, mid_tangent)
	curve.add_point(to, (arc_mid - to) * 0.4, Vector2.ZERO)

	if path_node != null:
		path_node.curve = curve

	# 2. Xử lý hiển thị theo trạng thái
	if path_state == PathState.COMPLETE:
		# Màn hoàn thành: vẽ đường liền đỏ rực rỡ qua Line2D
		_dash_points.clear()
		queue_redraw()

		if line_node != null:
			line_node.visible = true
			line_node.width_curve = null
			line_node.gradient = null
			line_node.default_color = COLOR_COMPLETE
			line_node.width = WIDTH_COMPLETE
			line_node.joint_mode = Line2D.LINE_JOINT_ROUND
			line_node.begin_cap_mode = Line2D.LINE_CAP_ROUND
			line_node.end_cap_mode = Line2D.LINE_CAP_ROUND
			line_node.antialiased = true
			line_node.clear_points()
			var pts := curve.tessellate(6, 1.2)
			for pt in pts:
				line_node.add_point(pt)
	else:
		# Màn chưa hoàn thành / skipped / locked:
		# Ẩn Line2D và vẽ nét đứt cong mượt mà bằng draw_multiline
		if line_node != null:
			line_node.visible = false
			line_node.clear_points()

		_dash_points.clear()
		var total_len := curve.get_baked_length()
		var dash_len  := 10.0
		var gap_len   := 7.0

		var d := 0.0
		while d < total_len:
			var p1 := curve.sample_baked(d)
			var p2 := curve.sample_baked(minf(d + dash_len, total_len))
			_dash_points.append(p1)
			_dash_points.append(p2)
			d += dash_len + gap_len

		match path_state:
			PathState.SKIPPED:
				_dash_color = COLOR_SKIPPED
				_dash_width = WIDTH_SKIPPED
			PathState.UPCOMING:
				_dash_color = COLOR_UPCOMING
				_dash_width = WIDTH_UPCOMING
			PathState.LOCKED:
				_dash_color = COLOR_LOCKED
				_dash_width = WIDTH_LOCKED

		queue_redraw()


func _draw() -> void:
	if not _dash_points.is_empty():
		draw_multiline(_dash_points, _dash_color, _dash_width)
