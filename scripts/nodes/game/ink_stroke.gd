class_name InkStroke
extends Line2D
## ============================================================================
## Nét mực "sống" theo NGÒI BÚT đang dùng (PenSkin):
##   · Đổi màu · bề rộng · đầu nét · nét đứt theo CHẤT LIỆU của bút.
##   · BẬT/TẮT 1 nét QUẦNG SÁNG (blend cộng) khai sẵn trong scene (`Glow`) cho bút có hiệu ứng
##     (nhũ vàng, bút gel, dạ quang...).
##
## Dùng thay Line2D ở `moving_line.tscn`.
## KHÔNG gọi apply_pen() thì node hành xử y như Line2D thường
## (ví dụ đường kẻ chỉ dẫn kéo anchor vẫn tự set width/default_color).
##
## ── CHẾ ĐỘ "VIẾT TAY" (mới) ────────────────────────────────────────────────
## Thay vì nối thẳng các tâm ô bằng góc vuông, nét được dựng từ:
##   1. `set_path_vertices()` : danh sách TÂM Ô đã chốt (đường đi thật).
##   2. `set_tip()`           : ĐẦU BÚT đang lơ lửng (đuôi mực kéo theo ngón tay / đang trượt
##                              tới ô vừa chốt). Gọi mỗi khung hình, rất rẻ.
## Nét tự: bo tròn góc, thêm chút run tay, và nối liền mạch phần đã chốt với đầu bút.
## Không gọi 2 hàm trên (chỉ dùng `set_stroke()` / `points`) thì node vẫn là Line2D thường.
## ============================================================================

var _pen_id := ""
var _base_width := 0.0
var _alpha_scale := 1.0
## Node binding: khai `node_paths` + NodePath trong `nodes/game/moving_line.tscn`
## (nét nào không khai `Glow` thì `_glow_node()` trả null — bỏ qua phần quầng sáng)
@export var glow_line: Line2D = null

@export_group("Pen feel")
## Lấy cảm giác viết (bo góc · run tay · áp lực · dạ quang · nhấp nháy) theo bảng PenSkin.FEELS.
## Tắt nếu muốn tự chỉnh tay các thông số bên dưới.
@export var use_pen_feel := true
@export_group("Hand-written stroke")
## Bán kính bo góc, tính theo BƯỚC Ô (0 = góc vuông như cũ). 0.26 ≈ bo nhẹ, giống nét bút thật.
@export_range(0.0, 0.45, 0.01) var corner_radius_ratio := 0.26
## Biên độ run tay (px ở tỉ lệ 1.0, tự co theo cỡ bàn). 0 = tắt. Nên để 0.4 – 1.0.
@export_range(0.0, 3.0, 0.05) var wobble_px := 0.7
## Khoảng cách giữa 2 điểm run trên đoạn thẳng (px)
@export_range(6.0, 40.0, 1.0) var wobble_spacing := 14.0
@export_group("")

var _step := 88.0
var _px_scale := 1.0

# --- Cảm giác theo bút ---
var _shimmer := 0.0
var _glow_alpha_base := 0.0
var _t := 0.0
static var _mul_material: CanvasItemMaterial = null

# --- Trạng thái chế độ "viết tay" ---
var _smart := false
var _verts := PackedVector2Array()        # tâm các ô đã chốt
var _tip := Vector2.ZERO
var _has_tip := false
var _body := PackedVector2Array()         # điểm đã làm mượt, kết thúc ở E (trước tâm ô cuối 1 đoạn)
var _body_count := 0                      # số đỉnh được dùng để dựng _body
var _body_end_dir := Vector2.ZERO         # hướng đoạn cuối của _body
var _body_corner_r := 0.0                 # bán kính bo dành cho góc tại tâm ô cuối


func _init() -> void:
	set_process(false)       # chỉ bật khi bút có quầng sáng nhấp nháy (xem `_apply_feel`)


## Áp ngòi bút (gọi set_base_width() để biết bề rộng GỐC trước khi nhân chất liệu)
func apply_pen(pen_id: String, alpha_scale := 1.0) -> void:
	_pen_id = pen_id if PenSkin.has_pen(pen_id) else PenSkin.DEFAULT_PEN
	_alpha_scale = alpha_scale
	if _base_width <= 0.0:
		_base_width = width
	_refresh()


## Bề rộng nét TRƯỚC khi nhân hệ số chất liệu (board đổi khi co giãn theo cỡ lưới)
func set_base_width(base_width: float) -> void:
	if is_equal_approx(_base_width, base_width):
		return
	_base_width = base_width
	_refresh()


func pen_id() -> String:
	return _pen_id


## Cập nhật toàn bộ điểm của nét (đồng bộ luôn quầng sáng). Đây là đường THÔ:
## tắt chế độ viết tay cho tới khi `set_path_vertices()` được gọi lại.
func set_stroke(p_points: PackedVector2Array) -> void:
	_smart = false
	_verts = PackedVector2Array()
	_write(p_points)


## Áp chất liệu cho 1 Line2D thường (không quầng sáng) — vệt bút mờ, đường phụ...
static func style_plain(line: Line2D, pen_id: String, base_width: float,
		alpha_scale := 1.0) -> void:
	PenSkin.apply_line(line, pen_id, base_width, alpha_scale)


# ============================================================================
# CHẾ ĐỘ VIẾT TAY
# ============================================================================
## `step` = bước ô (px), `px_scale` = hệ số co của bàn (để bo góc + run tay co theo)
func set_metrics(step: float, px_scale: float) -> void:
	var new_step := maxf(step, 1.0)
	var new_scale := maxf(px_scale, 0.1)
	if is_equal_approx(new_step, _step) and is_equal_approx(new_scale, _px_scale):
		return
	_step = new_step
	_px_scale = new_scale
	if _smart:
		_rebuild_body()
		_compose()


## Danh sách TÂM Ô đã chốt (theo thứ tự đi). Dựng lại phần thân nét.
func set_path_vertices(verts: PackedVector2Array) -> void:
	_smart = true
	_verts = verts
	_rebuild_body()
	_compose()


## Đầu bút hiện tại. `active=false` ⇒ không có đuôi mực, nét dừng đúng ở tâm ô cuối.
## Gọi mỗi khung hình khi bút đang trượt — chỉ dựng lại vài điểm cuối.
func set_tip(tip: Vector2, active: bool) -> void:
	_tip = tip
	_has_tip = active
	if not _smart:
		return
	if _effective_count() != _body_count:
		_rebuild_body()
	_compose()


## Số đỉnh đã chốt được dùng làm "thân". Khi đầu bút đang TRƯỢT trên đoạn cuối
## (từ ô trước tới ô vừa chốt) thì ô vừa chốt chưa được vẽ hết ⇒ bỏ nó, để đầu bút thay thế.
func _effective_count() -> int:
	var n := _verts.size()
	if not _has_tip or n < 2:
		return n
	var a := _verts[n - 2]
	var b := _verts[n - 1]
	var seg := b - a
	var l2 := seg.length_squared()
	if l2 < 0.0001:
		return n
	var rel := _tip - a
	var u := rel.dot(seg) / l2
	var perp := absf(rel.cross(seg)) / sqrt(l2)
	if u > -0.001 and u < 0.999 and perp < 2.0 * _px_scale + 1.0:
		return n - 1
	return n


func _rebuild_body() -> void:
	_body_count = _effective_count()
	_body = PackedVector2Array()
	_body_end_dir = Vector2.ZERO
	_body_corner_r = 0.0
	var m := _body_count
	if m <= 0:
		return
	_body.append(_verts[0])
	if m == 1:
		return

	var radius_max := corner_radius_ratio * _step
	var cut_in := 0.0
	for i in range(1, m):
		var a := _verts[i - 1]
		var b := _verts[i]
		var seg := b - a
		var seg_len := seg.length()
		if seg_len < 0.001:
			continue
		var dir := seg / seg_len

		# Bán kính cắt ở cuối đoạn này (= tại đỉnh b)
		var cut_out := 0.0
		var next_dir := Vector2.ZERO
		if i < m - 1:
			var nxt := _verts[i + 1] - b
			var nxt_len := nxt.length()
			if nxt_len > 0.001:
				next_dir = nxt / nxt_len
				var dt := dir.dot(next_dir)
				# Chỉ bo khi thật sự rẽ (không bo đường thẳng / quay đầu 180°)
				if dt < 0.98 and dt > -0.98:
					cut_out = minf(radius_max, minf(seg_len * 0.5, nxt_len * 0.5))
		else:
			# Đỉnh cuối: chừa chỗ để bo nếu đuôi mực rẽ hướng
			cut_out = minf(radius_max, seg_len * 0.5)

		var s := a + dir * cut_in
		var e := b - dir * cut_out
		_emit_straight(s, e, dir)

		if i < m - 1 and cut_out > 0.0:
			_emit_arc(_body, e, b, b + next_dir * cut_out)
			cut_in = cut_out
		elif i < m - 1:
			cut_in = 0.0          # đỉnh thẳng / quay đầu: `e` đã trùng `b`, không bo
		else:
			_body_end_dir = dir
			_body_corner_r = cut_out


## Đoạn thẳng s→e có chút run tay (độ lệch ngang, mượt, bằng 0 ở 2 đầu đoạn).
func _emit_straight(s: Vector2, e: Vector2, dir: Vector2) -> void:
	var amp := wobble_px * _px_scale
	var length := s.distance_to(e)
	if amp > 0.01 and length > wobble_spacing * 1.5:
		var count := int(length / (wobble_spacing * _px_scale + 0.001))
		count = clampi(count, 1, 64)
		var perp := Vector2(-dir.y, dir.x)
		for k in range(1, count):
			var t := float(k) / float(count)
			var p := s.lerp(e, t)
			p += perp * (_noise(p) * amp * sin(PI * t))
			_body.append(p)
	_body.append(e)


## Cung bo góc (Bezier bậc 2): from → (control) → to. Không thêm lại điểm `from`.
static func _emit_arc(out: PackedVector2Array, from: Vector2, control: Vector2, to: Vector2) -> void:
	const STEPS := 4
	for k in range(1, STEPS + 1):
		var t := float(k) / float(STEPS)
		var u := 1.0 - t
		out.append(from * (u * u) + control * (2.0 * u * t) + to * (t * t))


static func _noise(p: Vector2) -> float:
	return sin(p.x * 0.093 + p.y * 0.071) * 0.6 + sin(p.x * 0.17 - p.y * 0.13 + 1.7) * 0.4


## Ghép thân nét + đầu bút thành điểm vẽ cuối cùng
func _compose() -> void:
	if _body_count <= 0:
		_write(PackedVector2Array())
		return
	var pts := _body.duplicate()
	var center := _verts[_body_count - 1]

	var tail_len := 0.0
	var tail_dir := Vector2.ZERO
	if _has_tip:
		var t := _tip - center
		tail_len = t.length()
		if tail_len > 0.6:
			tail_dir = t / tail_len
		else:
			tail_len = 0.0

	if tail_len <= 0.0:
		# Không có đuôi: nét dừng đúng ở tâm ô (1 đỉnh duy nhất thì chưa có gì để vẽ)
		if _body_count >= 2:
			pts.append(center)
	elif _body_count < 2 or _body_end_dir == Vector2.ZERO:
		if _body_count >= 2:
			pts.append(center)
		pts.append(_tip)
	else:
		var dt := _body_end_dir.dot(tail_dir)
		if dt > 0.98:
			pts.append(_tip)                       # đi thẳng tiếp
		elif dt < -0.98:
			pts.append(center)                     # quay đầu: vẽ chồng lên nét cũ
			pts.append(_tip)
		else:
			var r := minf(_body_corner_r, tail_len)
			var exit_pt := center + tail_dir * r
			_emit_arc(pts, pts[pts.size() - 1], center, exit_pt)
			if tail_len > r + 0.01:
				pts.append(_tip)
	_write(pts)


func _write(pts: PackedVector2Array) -> void:
	points = pts
	var glow_node := _glow_node()
	if glow_node != null:
		glow_node.points = pts


func _refresh() -> void:
	if _pen_id.is_empty():
		return
	PenSkin.apply_line(self, _pen_id, _base_width, _alpha_scale)
	_apply_feel()

	var glow := PenSkin.glow_of(_pen_id)
	var glow_node := _glow_node()
	if glow_node == null:
		return
	if glow.is_empty():
		# Bút không có quầng sáng -> chỉ ẨN node khai sẵn trong scene (không xoá/tạo lại)
		glow_node.visible = false  # keep-code: trạng thái theo dữ liệu (runtime)
		set_process(false)
		return
	glow_node.width = maxf(width * float(glow.get("width_mult", 1.0)), 1.0)
	var ink := PenSkin.ink_color(_pen_id)
	glow_node.default_color = Color(ink.r, ink.g, ink.b,
		clampf(float(glow.get("alpha", 0.0)) * _alpha_scale, 0.0, 1.0))
	glow_node.points = points
	glow_node.visible = true  # keep-code: trạng thái theo dữ liệu (runtime)
	_glow_alpha_base = glow_node.default_color.a
	set_process(use_pen_feel and _shimmer > 0.0)


## Quầng sáng KHAI SẴN trong scene (`Glow` — Line2D blend CỘNG, z_index = -1;
## xem nodes/game/moving_line.tscn). Nét nào không khai `Glow` thì bỏ qua phần quầng sáng.
func _glow_node() -> Line2D:
	if glow_line == null or not is_instance_valid(glow_line):
		glow_line = get_node_or_null("Glow") as Line2D
	return glow_line


# ============================================================================
# CẢM GIÁC VIẾT THEO TỪNG BÚT (bảng PenSkin.FEELS)
# ============================================================================
func _apply_feel() -> void:
	_shimmer = 0.0
	if not use_pen_feel:
		return
	var f := PenSkin.feel_of(_pen_id)
	corner_radius_ratio = float(f.get("corner", corner_radius_ratio))
	wobble_px = float(f.get("wobble", wobble_px))
	wobble_spacing = float(f.get("spacing", wobble_spacing))
	_shimmer = float(f.get("shimmer", 0.0))

	# Áp lực bút: dày mỏng dọc theo nét (đầu nét vuốt lên · phình giữa · không đều)
	width_curve = _make_width_curve(float(f.get("start_w", 1.0)), float(f.get("taper", 0.0)),
		float(f.get("swell", 0.0)), float(f.get("noise", 0.0)), hash(_pen_id))

	# Bút dạ quang: NHÂN màu với nền như bút thật ⇒ số và ô bên dưới vẫn đọc được
	if str(f.get("blend", "mix")) == "mul":
		if _mul_material == null:
			_mul_material = CanvasItemMaterial.new()
			_mul_material.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
		material = _mul_material

	if _smart:
		_rebuild_body()
		_compose()


## Đường cong bề dày dọc nét (0 = đầu nét · 1 = đầu bút). null = bề dày đều.
static func _make_width_curve(start_w: float, taper: float, swell: float, noise: float,
		seed_v: int) -> Curve:
	if start_w >= 0.999 and swell <= 0.001 and noise <= 0.001:
		return null
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var curve := Curve.new()
	curve.min_value = 0.0
	curve.max_value = 1.6
	const SAMPLES := 24
	var walk := 0.0
	for i in range(SAMPLES + 1):
		var x := float(i) / float(SAMPLES)
		var y := 1.0
		if taper > 0.0 and x < taper:
			y = lerpf(start_w, 1.0, smoothstep(0.0, 1.0, x / taper))
		y += swell * sin(PI * x)
		walk = lerpf(walk, rng.randf_range(-1.0, 1.0), 0.45)    # nhiễu mượt, không giật
		y += noise * walk
		curve.add_point(Vector2(x, clampf(y, 0.15, 1.6)), 0.0, 0.0,
			Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)
	return curve


## Quầng sáng nhấp nháy (mực nhũ vàng)
func _process(delta: float) -> void:
	var glow_node := _glow_node()
	if glow_node == null or not glow_node.visible or _shimmer <= 0.0:
		set_process(false)
		return
	_t += delta
	var c := glow_node.default_color
	c.a = clampf(_glow_alpha_base * (1.0 + _shimmer * sin(_t * 4.2)), 0.0, 1.0)
	glow_node.default_color = c
