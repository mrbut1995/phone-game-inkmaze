class_name GameOverRuler
extends Control
## "Thước kỷ lục" của popup Game Over (Dungeon): đường số nằm ngang từ tầng 1 tới tầng cao nhất.
##   · ghim đỏ ✕  = tầng bạn vừa thua (đoạn đã đi tô đỏ)
##   · cờ xanh    = kỷ lục TUẦN · cờ vàng = kỷ lục THÁNG
## Trùng tầng thì gộp nhãn ("BẠN · TUẦN 12"). Vẽ hoàn toàn bằng code — không cần ảnh.
##
## gameover.gd gọi:  ruler.set_data(tầng_vừa_thua, kỷ_lục_tuần, kỷ_lục_tháng, "BẠN", "TUẦN", "THÁNG")
## (kỷ lục <= 0 = chưa có -> không vẽ cờ đó)

@export var color_track := Color("E3EBEF")
@export var color_you := Color("E5493A")
@export var color_week := Color("4B93C4")
@export var color_month := Color("E9A92A")
@export var color_ink := Color("333745")
@export var color_tick := Color("9AA6AE")
@export var color_text_you := Color("E5493A")
@export var color_text_week := Color("3D83AE")
@export var color_text_month := Color("B07A0A")
@export var font_size := 11
## Đường số nằm ở độ cao này (chừa chỗ phía trên cho ghim)
@export var line_y := 44.0
@export var pad_x := 18.0

var _floor := 1
var _week := 0
var _month := 0
var _tx_you := "BẠN"
var _tx_week := "TUẦN"
var _tx_month := "THÁNG"


func set_data(current_floor: int, best_week: int, best_month: int,
		text_you: String, text_week: String, text_month: String) -> void:
	_floor = maxi(current_floor, 1)
	_week = maxi(best_week, 0)
	_month = maxi(best_month, 0)
	_tx_you = text_you
	_tx_week = text_week
	_tx_month = text_month
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _x_of(f: int, hi: int) -> float:
	var span := float(maxi(hi - 1, 1))
	return pad_x + (size.x - pad_x * 2.0) * float(f - 1) / span


func _draw() -> void:
	if size.x < 80.0:
		return
	var hi := maxi(maxi(_floor, _week), maxi(_month, 2))
	var x0 := pad_x
	var x1 := size.x - pad_x
	# Đường nền + đoạn đã đi
	draw_rect(Rect2(x0, line_y - 4.0, x1 - x0, 8.0), color_track)
	draw_circle(Vector2(x0, line_y), 4.0, color_track)
	draw_circle(Vector2(x1, line_y), 4.0, color_track)
	var xf := _x_of(_floor, hi)
	draw_rect(Rect2(x0, line_y - 4.0, xf - x0, 8.0), color_you)
	draw_circle(Vector2(x0, line_y), 4.0, color_you)
	# Vạch chia: mỗi tầng nếu ít, thưa dần nếu nhiều
	var step := 1 if hi <= 20 else (5 if hi <= 60 else 10)
	var f := 1
	while f <= hi:
		var tx := _x_of(f, hi)
		var major := (f - 1) % (step * 5) == 0 if step == 1 else true
		draw_line(Vector2(tx, line_y + 6.0), Vector2(tx, line_y + (12.0 if major else 9.0)), color_tick, 2.0)
		f += step
	# Cờ kỷ lục
	if _week > 0:
		_draw_flag(_x_of(_week, hi), color_week)
	if _month > 0:
		_draw_flag(_x_of(_month, hi), color_month)
	# Ghim ✕ của tầng vừa thua
	_draw_pin(xf)
	_draw_labels(hi)


func _draw_flag(x: float, col: Color) -> void:
	draw_line(Vector2(x, line_y + 6.0), Vector2(x, line_y + 30.0), color_ink, 2.5)
	var tri := PackedVector2Array([Vector2(x, line_y + 12.0), Vector2(x + 15.0, line_y + 18.0), Vector2(x, line_y + 24.0)])
	draw_colored_polygon(tri, col)
	var outline := PackedVector2Array(tri)
	outline.append(tri[0])
	draw_polyline(outline, color_ink, 2.0, true)


func _draw_pin(x: float) -> void:
	var tip := Vector2(x, line_y - 4.0)
	var tri := PackedVector2Array([tip, tip + Vector2(-8.0, -14.0), tip + Vector2(8.0, -14.0)])
	draw_colored_polygon(tri, color_you)
	var c := Vector2(x, line_y - 28.0)
	draw_circle(c, 13.0, color_you)
	draw_circle(c, 10.0, Color.WHITE)
	draw_line(c + Vector2(-4.5, -4.5), c + Vector2(4.5, 4.5), color_you, 3.0, true)
	draw_line(c + Vector2(-4.5, 4.5), c + Vector2(4.5, -4.5), color_you, 3.0, true)


## Nhãn dưới đường số: gộp theo tầng, so le 2 hàng để không đè nhau.
func _draw_labels(hi: int) -> void:
	var groups := {}
	var add := func(fl: int, token: String, col: Color) -> void:
		if fl <= 0:
			return
		if not groups.has(fl):
			groups[fl] = {"tokens": [], "color": col}
		groups[fl]["tokens"].append(token)
		if token == _tx_you:
			groups[fl]["color"] = color_text_you
	add.call(_floor, _tx_you, color_text_you)
	add.call(_week, _tx_week, color_text_week)
	add.call(_month, _tx_month, color_text_month)
	var floors: Array = groups.keys()
	floors.sort()
	var font := get_theme_font(&"font", &"Label")
	var row_end := [-1000.0, -1000.0]
	var base_y := [line_y + 40.0, line_y + 54.0]
	for fl in floors:
		var g: Dictionary = groups[fl]
		var text := "%s %d" % [" · ".join(g["tokens"]), fl]
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var left := clampf(_x_of(fl, hi) - w * 0.5, 2.0, maxf(size.x - w - 2.0, 2.0))
		var row := 0 if left > row_end[0] + 8.0 else 1
		row_end[row] = left + w
		draw_string(font, Vector2(left, base_y[row]), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, g["color"])
