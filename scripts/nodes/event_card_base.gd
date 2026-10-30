class_name EventCardBase
extends AspectRatioContainer
## ============================================================================
## Node gốc dùng chung của 2 loại thẻ trên Main Screen:
##   · `EventCard`  (nodes/main/event_card.tscn)  — sự kiện THẬT (có theme + hạn)
##   · `DailyCard`  (nodes/main/daily_card.tscn)  — Thử thách hằng ngày (event ảo)
##
## Ở đây chỉ có phần CHUNG: tỉ lệ thẻ, bấm/kéo để phát `card_pressed`, vòng đời
## `setup()` + timer làm mới, và các helper tô màu theo `EventTheme`.
## Mỗi lớp con tự khai node + tự áp nội dung trong `_apply_card()`.
##
## Không tạo node mới lúc chạy (§13.15 GDD) — mọi node con khai sẵn trong scene.
## ============================================================================

signal card_pressed(event_id: StringName)

## Ngưỡng nhích chuột để coi là KÉO (không phải bấm thẻ)
const CARD_CLICK_DRAG_THRESHOLD := 12.0

## Nút CTA kiểu 3D (gờ đáy + bóng đổ)
const CTA_LIP := 4
const CTA_RADIUS := 10  # keep-code: hằng dùng cho hiệu ứng/dữ liệu runtime (không phải bố cục tĩnh)
const CTA_PRESS_OFFSET := 2.0  # keep-code: hằng dùng cho hiệu ứng/dữ liệu runtime (không phải bố cục tĩnh)
const CTA_PRESS_TIME := 0.05

var _event_data: EventData = null
var _event_id: StringName = &""
var _preview_mode := false
var _card_press_active := false
var _card_press_position := Vector2.ZERO


## Id event đang hiển thị (test/tiện ích đọc)
func event_id() -> StringName:
	return _event_id


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_aspect_width()


func _update_aspect_width() -> void:
	if size.y > 0.0:
		var target_w := roundf(size.y * ratio)
		if not is_equal_approx(custom_minimum_size.x, target_w):
			custom_minimum_size.x = target_w


func _ready() -> void:
	_bind_interactions()
	var timer := _timer_node()
	if timer != null and not timer.timeout.is_connected(_on_timer_tick):
		timer.timeout.connect(_on_timer_tick)
		timer.start()


## Nối nút CTA + bấm-ở-đâu-cũng-được trên thẻ
func _bind_interactions() -> void:
	var cta := _cta_node()
	if cta != null and not cta.pressed.is_connected(_on_cta_pressed):
		cta.pressed.connect(_on_cta_pressed)
	if not gui_input.is_connected(_on_card_gui_input):
		gui_input.connect(_on_card_gui_input)


## Thiết lập thẻ từ dữ liệu EventData (mỗi lớp con áp nội dung trong `_apply_card`)
func setup(data: EventData, preview_mode: bool = false) -> void:
	_event_data = data
	_event_id = data.id
	_preview_mode = preview_mode
	_bind_interactions()
	_apply_card(data)


# --- Hook cho lớp con --------------------------------------------------------

## Áp theme + chữ + trạng thái của thẻ. Lớp con BẮT BUỘC override.
func _apply_card(_data: EventData) -> void:
	pass


## Nút CTA của thẻ (null nếu thẻ không có)
func _cta_node() -> BaseButton:
	return null


## Timer làm mới nội dung định kỳ (null nếu không cần)
func _timer_node() -> Timer:
	return null


## Làm mới phần phụ thuộc thời gian (đồng hồ đếm ngược / tiến độ)
func _refresh_live() -> void:
	pass


# --- Tương tác ---------------------------------------------------------------

func _on_cta_pressed() -> void:
	if _event_data == null:
		return
	card_pressed.emit(_event_id)


func _on_card_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			var cta := _cta_node()
			_card_press_active = cta == null or not cta.get_global_rect().has_point(mb.global_position)
			_card_press_position = mb.global_position
			return
		if not _card_press_active:
			return
		_card_press_active = false
		if _card_press_position.distance_to(mb.global_position) < CARD_CLICK_DRAG_THRESHOLD:
			card_pressed.emit(_event_id)


func _on_timer_tick() -> void:
	_refresh_live()


# --- Helper tô màu theo theme (dùng cho cả 2 lớp con) ------------------------

## Chip nhỏ (nền + chấm màu + chữ)
func _paint_chip(chip: PanelContainer, dot: ColorRect, label: Label, t: EventTheme) -> void:
	if t == null:
		return
	if dot != null:
		dot.color = t.accent
	if label != null:
		label.add_theme_color_override("font_color", t.chip_text)
	if chip != null:
		var style := StyleBoxFlat.new()  # keep-code: stylebox của hiệu ứng vẽ runtime
		style.bg_color = t.chip_fill
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_right = 8
		style.corner_radius_bottom_left = 8
		chip.add_theme_stylebox_override("panel", style)


## Tiêu đề (màu chữ + màu viền)
func _paint_title(label: Label, t: EventTheme) -> void:
	if label == null or t == null:
		return
	label.add_theme_color_override("font_color", t.title_color)
	label.add_theme_color_override("font_outline_color", t.title_outline)


## Panel bo góc (khung tiến độ / khung Sao)
func _paint_panel(panel: Panel, t: EventTheme) -> void:
	if panel == null or t == null:
		return
	var ps := StyleBoxFlat.new()  # keep-code: stylebox của hiệu ứng vẽ runtime
	ps.bg_color = t.panel_color
	ps.border_color = t.panel_stroke
	ps.border_width_top = 1
	ps.border_width_right = 1
	ps.border_width_bottom = 1
	ps.border_width_left = 1
	ps.corner_radius_top_left = 10
	ps.corner_radius_top_right = 10
	ps.corner_radius_bottom_right = 10
	ps.corner_radius_bottom_left = 10
	panel.add_theme_stylebox_override("panel", ps)


## Nút CTA kiểu 3D: nền + gờ đáy + bóng đổ, nhấn thì lún xuống (chữ dịch theo)
func _paint_cta(button: Button, label: Label, t: EventTheme) -> void:
	if t == null:
		return
	if button != null:
		var fill: Color = t.cta_fill
		var lip: Color = (t.cta_stroke as Color).darkened(0.2)
		button.add_theme_stylebox_override("normal", _make_cta_style(fill, lip, false))
		button.add_theme_stylebox_override("hover", _make_cta_style(fill.lightened(0.08), lip, false))
		button.add_theme_stylebox_override("pressed",
			_make_cta_style(fill.darkened(0.12), lip.darkened(0.1), true))
		var dis := _make_cta_style(Color(0.62, 0.5, 0.5, 1.0), Color(0.43, 0.34, 0.34, 1.0), false)
		dis.shadow_size = 0
		button.add_theme_stylebox_override("disabled", dis)
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	if label != null:
		label.add_theme_color_override("font_color", t.cta_text)
	_bind_cta_press(button, label)


func _make_cta_style(fill: Color, lip: Color, pressed: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()  # keep-code: stylebox của hiệu ứng vẽ runtime
	s.bg_color = fill
	s.border_color = lip
	s.border_width_left = 1
	s.border_width_top = 1
	s.border_width_right = 1
	s.border_width_bottom = 2 if pressed else CTA_LIP
	s.set_corner_radius_all(CTA_RADIUS)  # keep-code: stylebox của hiệu ứng vẽ runtime
	s.shadow_color = Color(0, 0, 0, 0.3 if pressed else 0.4)
	s.shadow_size = 3 if pressed else 6
	s.shadow_offset = Vector2(0, 1 if pressed else 4)
	return s


## Khi nhấn nút, chữ lún xuống theo mặt nút (chỉ nối 1 lần cho mỗi nút)
func _bind_cta_press(button: Button, label: Label) -> void:
	if button == null or label == null or button.has_meta("cta_press_bound"):
		return
	button.set_meta("cta_press_bound", true)
	var top := label.offset_top
	var bottom := label.offset_bottom
	button.button_down.connect(_shift_cta_label.bind(label, top, bottom, CTA_PRESS_OFFSET))
	button.button_up.connect(_shift_cta_label.bind(label, top, bottom, 0.0))
	button.mouse_exited.connect(_shift_cta_label.bind(label, top, bottom, 0.0))


func _shift_cta_label(label: Label, top: float, bottom: float, amount: float) -> void:
	if not is_instance_valid(label):
		return
	var tw := label.create_tween().set_parallel(true)
	tw.tween_property(label, "offset_top", top + amount, CTA_PRESS_TIME)
	tw.tween_property(label, "offset_bottom", bottom + amount, CTA_PRESS_TIME)


## Gờ đáy + viền ngoài của card theo theme (mỗi event một màu)
##   · gờ đáy  = cta_stroke của theme, tối thêm 30%
##   · viền    = accent của theme (chỉ khi thẻ có node Frame)
func _paint_card_edges(lip: Panel, frame: Panel, t: EventTheme) -> void:
	if t == null:
		return
	if lip != null:
		var ls := lip.get_theme_stylebox("panel") as StyleBoxFlat
		if ls != null:
			ls = ls.duplicate() as StyleBoxFlat  # keep-code: StyleBox nhân bản để tô màu theo dữ liệu (runtime)
			ls.bg_color = (t.cta_stroke as Color).darkened(0.3)
			lip.add_theme_stylebox_override("panel", ls)
	if frame != null:
		var fs := frame.get_theme_stylebox("panel") as StyleBoxFlat
		if fs != null:
			fs = fs.duplicate() as StyleBoxFlat  # keep-code: StyleBox nhân bản để tô màu theo dữ liệu (runtime)
			var c: Color = t.accent
			fs.border_color = Color(c.r, c.g, c.b, 0.9)
			frame.add_theme_stylebox_override("panel", fs)


# --- Helper dữ liệu ----------------------------------------------------------

func _get_event_manager() -> Node:
	return Svc.event()


func _get_daily_manager() -> Node:
	return Svc.daily()
