extends VBoxContainer
## ============================================================================
## Node: EventButtonColumn (KHÔNG khai báo class_name — trong project đã có class trùng tên; main.gd nạp bằng preload) — CỘT NÚT ICON EVENT nổi bên phải bản đồ (Main, phương án C).
## Thay khối thẻ event (header + carousel). Mỗi event = 1 huy hiệu tròn theo theme + viên thuốc
## "Còn N ngày" NẰM DƯỚI nút. Tối đa MAX_EVENTS nút (game đảm bảo ≤ 5 event cùng lúc).
## Daily KHÔNG nằm ở đây (đã về dock).
##
## Art: assets/images-png/event_btn/event_btn_<theme_id>_{normal,pressed}.png
## (nguồn SVG: assets/images/event_btn/ — đổi theme = sửa SVG hoặc gen/gen_event_icons.py).
## ============================================================================

signal event_pressed(event_id: StringName)

const MAX_EVENTS := 5
const ICON_DIR := "res://assets/images-png/event_btn/"
const FALLBACK_THEME := "anniversary"
const BUTTON_SIZE := 58.0
## Tỉ lệ cao/rộng của art nút mới (209×216)
const ART_ASPECT := 216.0 / 209.0
## Bề rộng vùng BỎ TRỐNG bên phải bản đồ cho cột nút (bản đồ co lại ⇒ node level không bị đè)
const GUTTER := 88.0
## Chừa mép TRÁI cho vạch đỏ + lỗ gáy vở (bản đồ dịch sang phải)
const LEFT_INSET := 34.0
const MARGIN_RIGHT := 4.0
const MARGIN_TOP := 10.0
const INK := Color("164663")
const REFRESH_SECONDS := 20.0

var _events: Array = []
var _manager: Node = null
var _timer: Timer = null
var _time_labels: Dictionary = {}   # event_id -> Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 6)
	# Neo góc phải-trên của LevelSection (cha), rộng vừa nút
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	grow_vertical = Control.GROW_DIRECTION_END
	offset_right = -MARGIN_RIGHT
	offset_left = -MARGIN_RIGHT - BUTTON_SIZE - 14.0
	offset_top = MARGIN_TOP
	_timer = Timer.new()
	_timer.wait_time = REFRESH_SECONDS
	_timer.autostart = true
	_timer.timeout.connect(_refresh_times)
	add_child(_timer)


## `events`: Array[EventData] (đã bỏ Daily) · `manager`: EventManager (hỏi `seconds_left(id)`)
func set_events(events: Array, manager: Node) -> void:
	_manager = manager
	_events = events.slice(0, MAX_EVENTS)
	for child in get_children():
		if child != _timer:
			child.queue_free()
	_time_labels.clear()
	visible = not _events.is_empty()
	for ev in _events:
		add_child(_make_item(ev))
	_refresh_times()


## Chừa/thả vùng bên phải của `MapArea` (cha của LevelMap): có event ⇒ co bản đồ lại, không ⇒ trả đủ rộng
func reserve_gutter(map_area: Control) -> void:
	if map_area != null:
		map_area.offset_left = LEFT_INSET
		map_area.offset_right = -GUTTER if visible else 0.0


func _make_item(ev: Object) -> Control:
	var id := StringName(str(ev.get("id")))
	var item := VBoxContainer.new()
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_theme_constant_override("separation", 1)
	item.alignment = BoxContainer.ALIGNMENT_BEGIN

	var button := TextureButton.new()
	var theme_id := _theme_id_of(ev)
	button.texture_normal = _load_icon(ev, theme_id, "normal")
	button.texture_pressed = _load_icon(ev, theme_id, "pressed")
	button.texture_disabled = _load_icon(ev, theme_id, "disabled")
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.custom_minimum_size = Vector2(BUTTON_SIZE, BUTTON_SIZE * ART_ASPECT)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(func() -> void: event_pressed.emit(id))
	item.add_child(button)

	var pill := PanelContainer.new()
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var box := StyleBoxFlat.new()
	box.bg_color = Color.WHITE
	box.border_color = Color("E4DCC6")
	box.set_border_width_all(2)
	box.set_corner_radius_all(9)
	box.content_margin_left = 6.0
	box.content_margin_right = 6.0
	box.content_margin_top = 0.0
	box.content_margin_bottom = 0.0
	pill.add_theme_stylebox_override("panel", box)
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", INK)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pill.add_child(label)
	item.add_child(pill)
	_time_labels[id] = label
	return item


## theme_id của event: ưu tiên `theme_id`, rồi `theme.id`, cuối cùng chính `id`
func _theme_id_of(ev: Object) -> String:
	var t: Variant = ev.get("theme_id")
	if t == null or str(t) == "":
		var th: Variant = ev.get("theme")
		if th is Object and (th as Object).get("id") != null:
			t = (th as Object).get("id")
	if t == null or str(t) == "":
		t = ev.get("id")
	return str(t)


## Ưu tiên art NÚT khai báo trong EventTheme (`button_normal` / `button_pressed`); chưa khai báo thì
## tìm theo tên file `event_btn_<theme_id>_<state>.png`; cuối cùng dùng icon dự phòng.
func _load_icon(ev: Object, theme_id: String, state: String) -> Texture2D:
	var th: Variant = ev.get("theme")
	if th is Object:
		var tex: Variant = (th as Object).get("button_" + state)
		if tex is Texture2D:
			return tex as Texture2D
	var path := "%sevent_btn_%s_%s.png" % [ICON_DIR, theme_id, state]
	if not ResourceLoader.exists(path):
		path = "%sevent_btn_%s_%s.png" % [ICON_DIR, FALLBACK_THEME, state]
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _refresh_times() -> void:
	if _manager == null or not _manager.has_method("seconds_left"):
		return
	for id in _time_labels.keys():
		var label := _time_labels[id] as Label
		if label != null and is_instance_valid(label):
			label.text = format_left(int(_manager.call("seconds_left", id)))


## "Còn 9 ngày" · "Còn 6 giờ" · "Còn 20 phút" (≥ 1 ngày chỉ hiện ngày; < 1 ngày hiện giờ)
static func format_left(secs: int) -> String:
	if secs <= 0:
		return "Hết hạn"
	if secs >= 86400:
		return "Còn %d ngày" % int(ceil(secs / 86400.0))
	if secs >= 3600:
		return "Còn %d giờ" % int(ceil(secs / 3600.0))
	return "Còn %d phút" % maxi(1, int(ceil(secs / 60.0)))
