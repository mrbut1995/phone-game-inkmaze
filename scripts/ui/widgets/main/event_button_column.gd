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

## Cấu trúc tĩnh (khung, offset, separation, Timer, stylebox "Còn N ngày") nằm trong
## `nodes/main/event_button_column.tscn`; 1 nút event = `nodes/main/event_button_item.tscn`.
const ITEM_SCENE := preload("res://nodes/main/event_button_item.tscn")

const MAX_EVENTS := 5
const ICON_DIR := "res://assets/images-png/event_btn/"  # keep-code: đường dẫn art chọn theo theme_id của event (dữ liệu runtime)
const FALLBACK_THEME := "anniversary"                    # keep-code: art dự phòng khi theme event chưa có file nút

## Bề rộng vùng BỎ TRỐNG bên phải bản đồ cho cột nút (bản đồ co lại ⇒ node level không bị đè)
@export var gutter := 88.0
## Chừa mép TRÁI cho vạch đỏ + lỗ gáy vở (bản đồ dịch sang phải)
@export var left_inset := 34.0

var _events: Array = []
var _manager: Node = null
var _time_labels: Dictionary = {}   # event_id -> Label

@onready var _timer: Timer = $Refresh


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
		# keep-code: lề trái/phải đặt theo TRẠNG THÁI (có event hay không) của cha, không cố định được
		map_area.offset_left = left_inset
		map_area.offset_right = -gutter if visible else 0.0


func _make_item(ev: Object) -> Control:
	var id := StringName(str(ev.get("id")))
	var item := ITEM_SCENE.instantiate() as Control
	var button := item.get_node("Icon") as TextureButton
	var theme_id := _theme_id_of(ev)
	button.texture_normal = _load_icon(ev, theme_id, "normal")
	button.texture_pressed = _load_icon(ev, theme_id, "pressed")
	button.texture_disabled = _load_icon(ev, theme_id, "disabled")
	# keep-code: `item` sinh lúc chạy nên signal phải nối bằng code (mang theo event_id)
	button.pressed.connect(func() -> void: event_pressed.emit(id))
	_time_labels[id] = item.get_node("Pill/Label") as Label
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
