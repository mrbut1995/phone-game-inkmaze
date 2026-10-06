class_name LevelMapPath
extends Node2D
## ============================================================================
## LevelMapPath — Đoạn nối giữa 2 nút màn trên bản đồ (road map)
## Trạng thái thể hiện qua màu / kiểu nét:
##   COMPLETE  → nét liền đậm màu đỏ ink (#D84444) qua `Line`
##   SKIPPED   → nét đứt màu cam (#E8A020)
##   UPCOMING  → nét đứt màu xanh mực (#507894)
##   LOCKED    → nét đứt màu xám (#8FA0B0)
##
## Quy ước của project: node con (`Path` + `Line`) và cấu hình nét TĨNH (độ rộng, nối tròn,
## khử răng cưa, màu mặc định) khai trong `level_path.tscn`; script bind bằng `@export`,
## chỉ còn phần ĐỘNG: dựng `Curve2D` nối 2 nút và chọn kiểu nét theo trạng thái.
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
## Lực uốn cong của đoạn nối (px) — cung vòng ra phía ngoài biên bản đồ
const ARC_BULGE   := 26.0

## Node con — bind bằng `@export` trong `level_path.tscn`
@export var path_node: Path2D = null
@export var line_node: Line2D = null

## Dữ liệu vẽ nét đứt bằng `draw_multiline`
var _dash_points: PackedVector2Array = PackedVector2Array()
var _dash_color: Color = Color.WHITE
var _dash_width: float = 4.0


## Vẽ đoạn nối cong mượt mà từ điểm `from` đến `to` theo trạng thái `path_state`
func setup(from: Vector2, to: Vector2, path_state: PathState) -> void:
	var curve := _build_curve(from, to)
	if path_node != null:
		path_node.curve = curve
	if path_state == PathState.COMPLETE:
		_show_solid(curve)
	else:
		_show_dashed(curve, path_state)


## Cung nối 2 điểm: đỉnh cung lệch ra phía ngoài biên, tiếp tuyến tại đỉnh song song
## tuyệt đối với dây cung nên đường cong trơn 100% (không gãy góc).
func _build_curve(from: Vector2, to: Vector2) -> Curve2D:
	var chord := to - from
	var chord_dir := chord.normalized()
	var perp := Vector2(-chord_dir.y, chord_dir.x)
	# Hướng uốn cong ra phía ngoài biên bản đồ
	var curve_dir := 1.0 if from.x > to.x else -1.0
	if (perp.x * curve_dir) < 0.0:
		perp = -perp

	var arc_mid := (from + to) * 0.5 + perp * ARC_BULGE
	var mid_tangent := chord_dir * (chord.length() * 0.25)

	var curve := Curve2D.new()
	curve.add_point(from, Vector2.ZERO, (arc_mid - from) * 0.4)
	curve.add_point(arc_mid, -mid_tangent, mid_tangent)
	curve.add_point(to, (arc_mid - to) * 0.4, Vector2.ZERO)
	return curve


## Màn đã xong: nét LIỀN đỏ qua Line2D
func _show_solid(curve: Curve2D) -> void:
	_dash_points.clear()
	queue_redraw()
	if line_node == null:
		return
	line_node.visible = true
	line_node.default_color = COLOR_COMPLETE
	line_node.width = WIDTH_COMPLETE
	line_node.clear_points()
	for point in curve.tessellate(6, 1.2):
		line_node.add_point(point)


## Màn chưa xong / bỏ qua / khoá: nét ĐỨT vẽ bằng `draw_multiline`
func _show_dashed(curve: Curve2D, path_state: PathState) -> void:
	if line_node != null:
		line_node.visible = false
		line_node.clear_points()

	_dash_points.clear()
	var total_len := curve.get_baked_length()
	var distance := 0.0
	while distance < total_len:
		_dash_points.append(curve.sample_baked(distance))
		_dash_points.append(curve.sample_baked(minf(distance + DASH_LENGTH, total_len)))
		distance += DASH_LENGTH + DASH_GAP

	match path_state:
		PathState.SKIPPED:
			_dash_color = COLOR_SKIPPED
			_dash_width = WIDTH_SKIPPED
		PathState.UPCOMING:
			_dash_color = COLOR_UPCOMING
			_dash_width = WIDTH_UPCOMING
		_:
			_dash_color = COLOR_LOCKED
			_dash_width = WIDTH_LOCKED
	queue_redraw()


func _draw() -> void:
	if not _dash_points.is_empty():
		draw_multiline(_dash_points, _dash_color, _dash_width)
