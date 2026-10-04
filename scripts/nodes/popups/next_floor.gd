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

## Node binding: khai `node_paths` + `NodePath` trong `next_floor.tscn`
@export var value_bonus: Label = null
@export var value_base: Label = null
@export var value_move: Label = null
@export var value_perfect: Label = null
@export var value_total: Label = null
@export var warn_title: Label = null
@export var go_label: Label = null
@export var stamp_title: Label = null
@export var stamp_sub: Label = null
## Hiệu ứng riêng của popup (animation "bonus_pop") — node tên `FxAnim` vì popup đã có
## `AnimationPlayer` của base.tscn (mở/đóng popup) — không được trùng tên.
@export var fx_anim: AnimationPlayer = null


func _play_fx(anim_name: StringName) -> bool:
	if fx_anim == null or not fx_anim.has_animation(anim_name):
		return false
	fx_anim.play(anim_name)
	return true


func _on_open() -> void:
	var floor := int(data.get("floor", 1))
	var next_floor := int(data.get("next_floor", floor + 1))

	value_bonus.text = tr("STR_BONUS_STEPS_GAINED").format([int(data.get("steps_bonus", 0))])
	value_base.text = tr("STR_SCORE_FORMAT").format([int(data.get("base_score", 0))])
	value_move.text = tr("STR_SCORE_FORMAT").format([int(data.get("move_bonus", 0))])
	value_perfect.text = tr("STR_SCORE_FORMAT").format([int(data.get("perfect_bonus", 0))])
	var total_sc := int(data.get("total_score", 0))
	if DisplayServer.get_name() != "headless" and total_sc > 0:
		value_total.text = tr("STR_RANK_POINTS").format([0])
		# (GIỮ tween) Đếm số = NỘI SUY DỮ LIỆU (điểm lúc chạy) + format text mỗi khung hình
		var tw_sc := create_tween()
		tw_sc.tween_method(func(v: float) -> void:
			if is_instance_valid(value_total):
				value_total.text = tr("STR_RANK_POINTS").format([_thousands(int(round(v)))])
		, 0.0, float(total_sc), 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		value_total.text = tr("STR_RANK_POINTS").format([_thousands(total_sc)])

	value_bonus.pivot_offset = value_bonus.size * 0.5
	if not _play_fx(&"bonus_pop"):
		# Fallback khi scene thiếu FxAnim
		var tw_b := create_tween()
		tw_b.tween_property(value_bonus, "scale", Vector2(1.2, 1.2), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw_b.tween_property(value_bonus, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	warn_title.text = tr("STR_FLOOR_WARNING_TITLE").format([next_floor])
	go_label.text = tr("STR_BTN_ENTER_NEXT_FLOOR").format([next_floor])

	# Con dấu xanh lục ở góc: "ĐÃ QUA" + "TẦNG 0n ✔" (mockup popup_to_next_floor.svg)
	stamp_title.text = tr("STR_RESULT_STAMP_PASSED")
	stamp_sub.text = tr("STR_RESULT_STAMP_FLOOR").format(["%02d" % floor])

	# Dây 2 nút (Nghỉ / Vào tầng kế) khai trong `next_floor.tscn` (cùng scene)


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
