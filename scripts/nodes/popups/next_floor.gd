class_name NextFloorPopup
extends BasePopup
## ============================================================================
## Popup: Phiếu thông qua tầng (nodes/popups/next_floor.tscn)
## Mockup: mockup/popup_to_next_floor.svg
## Dữ liệu: open({ floor, next_floor, steps_bonus, base_score, move_bonus,
##                perfect_bonus, total_score })
## ============================================================================

signal enter_requested
signal rest_requested


func _on_open() -> void:
	var floor := int(data.get("floor", 1))
	var next_floor := int(data.get("next_floor", floor + 1))

	_set_text("BonusBox/Value", tr("STR_BONUS_STEPS_GAINED").format([int(data.get("steps_bonus", 0))]))
	_set_text("StatValue1", tr("STR_SCORE_FORMAT").format([int(data.get("base_score", 0))]))
	_set_text("StatValue2", tr("STR_SCORE_FORMAT").format([int(data.get("move_bonus", 0))]))
	_set_text("StatValue3", tr("STR_SCORE_FORMAT").format([int(data.get("perfect_bonus", 0))]))
	_set_text("TotalValue", "%s PTS" % _thousands(int(data.get("total_score", 0))))
	_set_text("WarnBox/Title", tr("STR_FLOOR_WARNING_TITLE").format([next_floor]))
	_set_text("GoBtn/Label", tr("STR_BTN_ENTER_NEXT_FLOOR").format([next_floor]))

	bind_button("Panel/Content/RestBtn", _on_rest_pressed)
	bind_button("Panel/Content/GoBtn", _on_enter_pressed)


func _set_text(path: String, text: String) -> void:
	var label := piece(path) as Label
	if label != null:
		label.text = text


## 4690 -> "4,690" cho khớp mockup
func _thousands(value: int) -> String:
	var digits := str(absi(value))
	var out := ""
	var count := 0
	for i in range(digits.length() - 1, -1, -1):
		out = digits[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return ("-" if value < 0 else "") + out


func _on_rest_pressed() -> void:
	Sfx.play(Sfx.BTN_WOOD_TAP)
	rest_requested.emit()
	close()


func _on_enter_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	enter_requested.emit()
	close()
