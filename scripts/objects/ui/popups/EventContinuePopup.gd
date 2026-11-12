class_name EventContinuePopup
extends BasePopup
## ============================================================================
## Popup: QUA TẦNG của SỰ KIỆN chạy theo chuỗi màn tạo sẵn (popup_event_continue.tscn).
## Giống popup Dungeon nhưng nêu RÕ còn bao nhiêu tầng nữa là kết thúc sự kiện.
##
## Dữ liệu (GameController._complete_floor → result["event_info"]):
##   event_id, floor (1-based), total, remaining
## Signal giữ tên cũ để UIController nối như popup Dungeon:
##   rest_requested -> _emit_home      enter_requested -> _emit_continue
## ============================================================================

## Scene contract
## Exports:  label_title, label_event, label_floor, dots, label_remaining, go_label
## Emits:    rest_requested, enter_requested
## Handlers wired in scene: _on_enter_pressed, _on_rest_pressed
## Subscribes in code (EventBus/Model): (none)

signal rest_requested
signal enter_requested

const DOT_DONE := Color(0.18, 0.62, 0.34, 1.0)
const DOT_NOW := Color(1.0, 0.72, 0.15, 1.0)
const DOT_TODO := Color(0.78, 0.8, 0.82, 1.0)
const DOT_SIZE := 18.0

@export var label_title: Label = null
@export var label_event: Label = null
@export var label_floor: Label = null
@export var dots: HBoxContainer = null
@export var label_remaining: Label = null
@export var go_label: Label = null


func _on_open() -> void:
	var info: Dictionary = data.get("event_info", {})
	var floor_no := int(info.get("floor", 1))
	var total := maxi(int(info.get("total", floor_no + 1)), floor_no + 1)
	var remaining := maxi(int(info.get("remaining", total - floor_no)), 0)

	label_title.text = tr("STR_EVENT_CONT_TITLE")
	label_event.text = _event_name(StringName(info.get("event_id", &"")))
	label_floor.text = tr("STR_EVENT_FLOOR_FORMAT").format([floor_no, total])
	if remaining == 1:
		label_remaining.text = tr("STR_EVENT_CONT_LAST")
	else:
		label_remaining.text = tr("STR_EVENT_CONT_REMAIN").format([remaining])
	go_label.text = tr("STR_NF_ENTER").format([floor_no + 1])
	_build_dots(floor_no, total)


## Hàng chấm tiến độ: đã qua (xanh) · sắp vào (vàng) · chưa tới (xám)
func _build_dots(floor_no: int, total: int) -> void:
	for c in dots.get_children():
		c.queue_free()
	for i in total:
		var dot := Panel.new()
		dot.custom_minimum_size = Vector2(DOT_SIZE, DOT_SIZE)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(int(DOT_SIZE))
		sb.bg_color = DOT_DONE if i < floor_no else (DOT_NOW if i == floor_no else DOT_TODO)
		dot.add_theme_stylebox_override("panel", sb)
		dots.add_child(dot)


func _event_name(id: StringName) -> String:
	var em := Svc.event()
	var ev: EventData = em.call("get_event", id) if em != null and not id.is_empty() else null
	if ev == null:
		return ""
	return (tr(str(ev.title_key_1)) + " " + tr(str(ev.title_key_2))).strip_edges()


func _on_rest_pressed() -> void:
	Sfx.play(Sfx.BTN_WOOD_TAP)
	rest_requested.emit()
	close()


func _on_enter_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	enter_requested.emit()
	close()
