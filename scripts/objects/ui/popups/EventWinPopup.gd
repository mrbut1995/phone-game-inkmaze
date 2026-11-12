class_name EventWinPopup
extends BasePopup
## ============================================================================
## Popup: HOÀN THÀNH SỰ KIỆN — người chơi đã đi hết mọi tầng (popup_event_win.tscn).
## Quà đã được GameController phát lúc thắng tầng cuối (idempotent) — popup chỉ hiển thị.
##
## Dữ liệu (result["event_info"]): event_id, floor, total, claimed_now, rewards[{kind, amount, label_key}]
## Signal: rest_requested -> _emit_home
## ============================================================================

## Scene contract
## Exports:  label_title, label_event, label_done, rewards_box, label_rewards_head
## Emits:    rest_requested
## Handlers wired in scene: _on_rest_pressed
## Subscribes in code (EventBus/Model): (none)

signal rest_requested

@export var label_title: Label = null
@export var label_event: Label = null
@export var label_done: Label = null
@export var label_rewards_head: Label = null
@export var rewards_box: VBoxContainer = null


func _on_open() -> void:
	var info: Dictionary = data.get("event_info", {})
	var total := int(info.get("total", 0))
	label_title.text = tr("STR_EVENT_WIN_TITLE")
	label_event.text = _event_name(StringName(info.get("event_id", &"")))
	label_done.text = tr("STR_EVENT_WIN_DONE").format([total])
	for c in rewards_box.get_children():
		c.queue_free()
	var rows: Array = info.get("rewards", [])
	label_rewards_head.visible = not rows.is_empty()
	for r in rows:
		var l := Label.new()
		l.text = "★ " + _reward_text(r)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", 26)
		l.add_theme_color_override("font_color", Color(0.18, 0.49, 0.2, 1))
		rewards_box.add_child(l)
	if not rows.is_empty() and not bool(info.get("claimed_now", false)):
		var done := Label.new()
		done.text = tr("STR_EVENT_CTA_CLAIMED")
		done.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rewards_box.add_child(done)


func _reward_text(r: Dictionary) -> String:
	var key := str(r.get("label_key", ""))
	if not key.is_empty():
		return tr(key)
	return str(int(r.get("amount", 0)))


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
