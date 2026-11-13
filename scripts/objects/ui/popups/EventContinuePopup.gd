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
## Exports:  label_title, label_event, label_floor, ruler_cells, cell_scene, label_remaining, go_label
## Emits:    rest_requested, enter_requested
## Handlers wired in scene: _on_enter_pressed, _on_rest_pressed
## Subscribes in code (EventBus/Model): (none)

signal rest_requested
signal enter_requested

@export var label_title: Label = null
@export var label_event: Label = null
@export var label_floor: Label = null
@export var ruler_cells: HBoxContainer = null
## Scene 1 vạch thước (event_ruler_cell.tscn) — nhân bản theo số tầng
@export var cell_scene: PackedScene = null
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
	_build_ruler(floor_no, total)


## Thước kẻ tiến độ: đã qua (✔ xanh) · sắp vào (bút chì) · chưa tới (chỉ vạch + số)
func _build_ruler(floor_no: int, total: int) -> void:
	for c in ruler_cells.get_children():
		c.queue_free()
	for i in total:
		var cell := cell_scene.instantiate() as EventRulerCell
		ruler_cells.add_child(cell)
		cell.setup(i + 1, i < floor_no, i == floor_no)


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
