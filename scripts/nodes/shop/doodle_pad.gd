class_name ShopDoodlePad
extends Control
## ============================================================================
## BÀN NHÁP THỬ BÚT (mockup/shopping_pencil.svg — khu "DOODLE TEST PAD"):
## Người chơi VẼ THỬ bằng ngón tay để cảm nhận MÀU MỰC + CHẤT LIỆU nét của
## ngòi bút đang chọn (chạm thẻ bút trong lưới để đổi ngòi).
##
## - Nét vẽ thử dùng đúng `InkStroke` như moving_line trong game (cùng màu · bề rộng
##   · nét đứt · quầng sáng) nên "thấy sao chơi vậy".
## - Thẻ ĐANG XEM THỬ: tên ngòi bút + icon con trỏ trong game + con dấu trạng thái
##   (DÙNG THỬ ✓ / ĐANG DÙNG ✓).
## - Đổi ngòi: xoá nét cũ + vẽ sẵn 1 NÉT MẪU để thấy ngay chất liệu mới.
## ============================================================================

signal pen_changed(pen_id: String)

const STAMP_TRY := preload("res://assets/images/shop/btn_tile_normal.svg")
const STAMP_USING := preload("res://assets/images/shop/btn_equipped.svg")

const STROKE_WIDTH := 7        ## bề rộng nét vẽ thử (px) trước khi nhân chất liệu
const MIN_POINT_DIST := 2.5       ## khoảng cách tối thiểu để ghi thêm điểm (px)
const MAX_POINTS := 800           ## chặn nét quá dài (bỏ điểm cũ nhất)
const MAX_STROKES := 16           ## số nét tối đa giữ trên bàn nháp
const DEFAULT_AREA := Vector2(616.0, 150.0)

@onready var _title: Label = $Title
@onready var _hint: Label = $Hint
@onready var _draw_area: Control = $DrawArea
@onready var _strokes_layer: Control = $DrawArea/Strokes
@onready var _pen_tip: TextureRect = $DrawArea/PenTip
@onready var _badge_eyebrow: Label = $Badge/Eyebrow
@onready var _badge_name: Label = $Badge/Name
@onready var _badge_icon: TextureRect = $Badge/Icon
@onready var _stamp: TextureRect = $Badge/Stamp
@onready var _stamp_label: Label = $Badge/StampLabel

var _pen_id := PenSkin.DEFAULT_PEN
var _strokes: Array[InkStroke] = []
var _drawing := false
var _active: InkStroke = null
var _last_point := Vector2.ZERO


func _ready() -> void:
	if _title != null:
		_title.text = tr("STR_SHOP_TRY_TITLE")
	if _hint != null:
		_hint.text = tr("STR_SHOP_TRY_HINT")
	if _draw_area != null:
		_draw_area.gui_input.connect(_on_draw_input)
	if _pen_tip != null:
		_pen_tip.visible = false
	_refresh_badge()


# ---------------------------------------------------------------------------
# API cho shop + test
# ---------------------------------------------------------------------------
func setup(pen_id: String) -> void:
	select_pen(pen_id)


func pen_id() -> String:
	return _pen_id


func stroke_count() -> int:
	return _strokes.size()


## Chọn ngòi bút để xem thử: xoá nét cũ + vẽ nét mẫu theo chất liệu mới
func select_pen(pen_id: String) -> void:
	_pen_id = pen_id if PenSkin.has_pen(pen_id) else PenSkin.DEFAULT_PEN
	clear()
	_refresh_badge()
	_draw_sample()
	pen_changed.emit(_pen_id)


func clear() -> void:
	for stroke in _strokes:
		if is_instance_valid(stroke):
			stroke.queue_free()
	_strokes.clear()
	_active = null
	_drawing = false


## Vẽ 1 nét bằng code (test) — trả về node nét để kiểm tra màu/chất liệu
func draw_test_stroke(p_points: PackedVector2Array) -> InkStroke:
	if p_points.size() < 2:
		return null
	var stroke := _new_stroke()
	stroke.set_stroke(p_points)
	return stroke


func badge_name() -> String:
	return _badge_name.text if _badge_name != null else ""


func stamp_text() -> String:
	return _stamp_label.text if _stamp_label != null else ""


func is_using_pen() -> bool:
	return Shop.is_equipped(_pen_id)


## Vùng này "ăn" sự kiện kéo — shop phải bỏ qua để không cuộn/vuốt trang (shop.gd::_begin_drag)
func blocks_scroll_at(global_pos: Vector2) -> bool:
	return get_global_rect().has_point(global_pos)


# ---------------------------------------------------------------------------
# Thẻ ĐANG XEM THỬ
# ---------------------------------------------------------------------------
func _refresh_badge() -> void:
	if _badge_eyebrow != null:
		_badge_eyebrow.text = tr("STR_SHOP_TRY_BADGE")
	if _badge_name != null:
		_badge_name.text = TranslationServer.translate(str(Shop.item(_pen_id).get("name_key", "")))

	var cursor_tex := PenSkin.cursor_texture(_pen_id)
	if _badge_icon != null:
		_badge_icon.texture = cursor_tex
	if _pen_tip != null:
		_pen_tip.texture = cursor_tex

	var using := is_using_pen()
	if _stamp != null:
		_stamp.texture = STAMP_USING if using else STAMP_TRY
		_stamp.modulate = Color.WHITE if using else PenSkin.ink_color(_pen_id)
	if _stamp_label != null:
		_stamp_label.text = tr("STR_SHOP_TRY_USING") if using else tr("STR_SHOP_TRY_STAMP")
		_stamp_label.theme_type_variation = &"ShopBtnTextDone" if using else &"ShopBtnText"


# ---------------------------------------------------------------------------
# Nét vẽ thử
# ---------------------------------------------------------------------------
## Nét mẫu "dải sóng" để vừa chọn ngòi là thấy ngay chất liệu
func _draw_sample() -> void:
	var area := _draw_area.size if _draw_area != null else DEFAULT_AREA
	if area.x <= 1.0 or area.y <= 1.0:
		area = DEFAULT_AREA
	var path := PackedVector2Array()
	for i in 24:
		var t := float(i) / 23.0
		var x := lerpf(area.x * 0.06, area.x * 0.6, t)
		var y := area.y * 0.55 + sin(t * PI * 2.1) * area.y * 0.22
		path.append(Vector2(x, y))
	draw_test_stroke(path)


func _new_stroke() -> InkStroke:
	var stroke := InkStroke.new()
	stroke.apply_pen(_pen_id)
	stroke.set_base_width(STROKE_WIDTH)
	_strokes_layer.add_child(stroke)
	stroke.set_stroke(PackedVector2Array())
	_strokes.append(stroke)
	while _strokes.size() > MAX_STROKES:
		var oldest: InkStroke = _strokes.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()
	return stroke


func _on_draw_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_stroke(event.position)
		else:
			_end_stroke()
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		_extend_stroke(event.position)
	elif event is InputEventMouseMotion:
		# Desktop: ngòi bút chạy theo chuột để xem trước con trỏ trong game
		_move_tip(event.position)
	elif event is InputEventScreenTouch and event.index == 0:
		if event.pressed:
			_begin_stroke(event.position)
		else:
			_end_stroke()
	elif event is InputEventScreenDrag and event.index == 0:
		_extend_stroke(event.position)


func _begin_stroke(pos: Vector2) -> void:
	if _strokes_layer == null:
		return
	_drawing = true
	_active = _new_stroke()
	_last_point = pos
	# Chấm nhỏ để cú chạm đơn cũng để lại dấu mực
	_active.set_stroke(PackedVector2Array([pos, pos + Vector2(0.6, 0.6)]))
	_move_tip(pos)
	Sfx.play(Sfx.PATH_DRAW, 0.1, -6.0)


func _extend_stroke(pos: Vector2) -> void:
	if not _drawing or _active == null or not is_instance_valid(_active):
		return
	_move_tip(pos)
	if pos.distance_to(_last_point) < MIN_POINT_DIST:
		return
	_last_point = pos
	var pts := _active.points
	pts.append(pos)
	if pts.size() > MAX_POINTS:
		pts = pts.slice(pts.size() - MAX_POINTS)
	_active.set_stroke(pts)


func _end_stroke() -> void:
	_drawing = false
	_active = null


func _move_tip(pos: Vector2) -> void:
	if _pen_tip == null:
		return
	_pen_tip.visible = true
	_pen_tip.position = pos - _pen_tip.size * 0.5
