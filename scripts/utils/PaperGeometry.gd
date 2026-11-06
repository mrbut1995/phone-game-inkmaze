class_name PaperGeometry
extends RefCounted
## Hình học TỜ GIẤY của bàn chơi (Panel nine-slice) — thuần toán, không giữ trạng thái.
##
## Tách khỏi `board.gd`: nhận ảnh texture / Panel / số đo qua tham số, trả Rect2 hoặc toạ độ.
## `board.gd` chỉ còn giữ field và gọi vào đây, nên kết quả tính toán y hệt bản cũ.


## Vùng GIẤY ĐẶC trong ảnh texture (bỏ bóng đổ mờ quanh tờ giấy).
## Quét bản thu nhỏ 128×128 rồi nhân ngược về pixel thật. Trả Rect2() nếu không tìm được.
static func sheet_tex_rect(img: Image, tex_px: Vector2) -> Rect2:
	if img == null or tex_px.x <= 0.0 or tex_px.y <= 0.0:
		return Rect2()
	const PROBE := 128
	var probe := img.duplicate() as Image
	probe.resize(PROBE, PROBE, Image.INTERPOLATE_BILINEAR)
	var min_x := PROBE
	var min_y := PROBE
	var max_x := -1
	var max_y := -1
	for y in PROBE:
		for x in PROBE:
			if probe.get_pixel(x, y).a > 0.7:
				min_x = mini(min_x, x)
				max_x = maxi(max_x, x)
				min_y = mini(min_y, y)
				max_y = maxi(max_y, y)
	if max_x < min_x or max_y < min_y:
		return Rect2()
	return Rect2(
		float(min_x) / PROBE * tex_px.x, float(min_y) / PROBE * tex_px.y,
		float(max_x + 1 - min_x) / PROBE * tex_px.x, float(max_y + 1 - min_y) / PROBE * tex_px.y)


## X của MÉP PHẢI vạch lề đỏ (pixel texture); -1.0 nếu không có.
## Quét 1 hàng ngang giữa ảnh (40% bên trái), lấy điểm đỏ cuối cùng liên tiếp.
static func margin_line_x(img: Image, tex_px: Vector2) -> float:
	if img == null or tex_px.x <= 0.0 or tex_px.y <= 0.0:
		return -1.0
	var row := int(tex_px.y * 0.5)
	var result := -1.0
	var in_line := false
	for x in range(0, int(tex_px.x * 0.4)):
		var c := img.get_pixel(x, row)
		var is_red := c.a > 0.5 and c.r > 0.7 and c.r - c.g > 0.3 and c.r - c.b > 0.3
		if is_red:
			in_line = true
			result = float(x + 1)
		elif in_line:
			break
	return result


## Đổi toạ độ pixel TEXTURE → toạ độ control của Panel theo luật NinePatch:
## góc không co giãn, phần giữa co theo kích thước Panel.
static func nine_map(tex_v: float, horizontal: bool, panel: NinePatchRect, tex_px: Vector2) -> float:
	if panel == null:
		return tex_v
	var tex_len := tex_px.x if horizontal else tex_px.y
	var ctrl_len := panel.size.x if horizontal else panel.size.y
	var m_a := float(panel.patch_margin_left if horizontal else panel.patch_margin_top)
	var m_b := float(panel.patch_margin_right if horizontal else panel.patch_margin_bottom)
	if tex_len <= 0.0:
		return tex_v
	if tex_len <= m_a + m_b or ctrl_len <= m_a + m_b:
		return tex_v / tex_len * ctrl_len
	if tex_v <= m_a:
		return tex_v
	if tex_v >= tex_len - m_b:
		return ctrl_len - (tex_len - tex_v)
	return m_a + (tex_v - m_a) * (ctrl_len - m_a - m_b) / (tex_len - m_a - m_b)


## Vùng vẽ thật trong Board (toạ độ cục bộ): tờ giấy đặc trừ biên `inset` (tỉ lệ 0..1),
## và (tuỳ chọn) nằm bên phải lề đỏ.
static func inner_rect(panel: Control, sheet: Rect2, tex_px: Vector2, margin_x: float,
		inset: Vector4, avoid_margin: bool, margin_gap: float, fallback_size: Vector2) -> Rect2:
	var full := Rect2(panel.position, panel.size)
	if sheet.size.x <= 0.0 or sheet.size.y <= 0.0 or tex_px.x <= 0.0:
		return full
	var l := nine_map(sheet.position.x, true, panel as NinePatchRect, tex_px)
	var t := nine_map(sheet.position.y, false, panel as NinePatchRect, tex_px)
	var r := nine_map(sheet.end.x, true, panel as NinePatchRect, tex_px)
	var b := nine_map(sheet.end.y, false, panel as NinePatchRect, tex_px)
	var sheet_w := r - l
	var sheet_h := b - t
	l += inset.x * sheet_w
	t += inset.y * sheet_h
	r -= inset.z * sheet_w
	b -= inset.w * sheet_h
	if avoid_margin and margin_x >= 0.0:
		l = maxf(l, nine_map(margin_x, true, panel as NinePatchRect, tex_px) + margin_gap)
	if r - l <= 1.0 or b - t <= 1.0:
		return full
	return Rect2(panel.position + Vector2(l, t), Vector2(r - l, b - t))
