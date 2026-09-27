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
## ============================================================================

var _pen_id := ""
var _base_width := 0.0
var _alpha_scale := 1.0
var _glow: Line2D = null


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


## Cập nhật toàn bộ điểm của nét (đồng bộ luôn quầng sáng)
func set_stroke(p_points: PackedVector2Array) -> void:
	points = p_points
	var glow_node := _glow_node()
	if glow_node != null:
		glow_node.points = p_points


## Áp chất liệu cho 1 Line2D thường (không quầng sáng) — vệt bút mờ, đường phụ...
static func style_plain(line: Line2D, pen_id: String, base_width: float,
		alpha_scale := 1.0) -> void:
	PenSkin.apply_line(line, pen_id, base_width, alpha_scale)


func _refresh() -> void:
	if _pen_id.is_empty():
		return
	PenSkin.apply_line(self, _pen_id, _base_width, _alpha_scale)

	var glow := PenSkin.glow_of(_pen_id)
	var glow_node := _glow_node()
	if glow_node == null:
		return
	if glow.is_empty():
		# Bút không có quầng sáng -> chỉ ẨN node khai sẵn trong scene (không xoá/tạo lại)
		glow_node.visible = false
		return
	glow_node.width = maxf(width * float(glow.get("width_mult", 1.0)), 1.0)
	var ink := PenSkin.ink_color(_pen_id)
	glow_node.default_color = Color(ink.r, ink.g, ink.b,
		clampf(float(glow.get("alpha", 0.0)) * _alpha_scale, 0.0, 1.0))
	glow_node.points = points
	glow_node.visible = true


## Quầng sáng KHAI SẴN trong scene (`Glow` — Line2D blend CỘNG, z_index = -1;
## xem nodes/game/moving_line.tscn). Nét nào không khai `Glow` thì bỏ qua phần quầng sáng.
func _glow_node() -> Line2D:
	if _glow == null or not is_instance_valid(_glow):
		_glow = get_node_or_null("Glow") as Line2D
	return _glow
