class_name DailyMilestonePopup
extends BasePopup
## ============================================================================
## Popup NHỎ: báo phần thưởng vừa nhận ở một MỐC SAO của màn Daily
## (nodes/popups/daily_milestone.tscn)
##
## Mở bằng `Popups.open(Popups.DAILY_MILESTONE, { "stars": <ngưỡng>, "reward": <def> })`
## trong đó `reward` là Dictionary của `DailyManager.MILESTONES`
## (`{stars, coins, hint, undo, skip}`) — script chỉ HIỂN THỊ, không tự cộng gì.
## ============================================================================

## Node binding: khai `node_paths` + NodePath trong `daily_milestone.tscn`
@export var title_label: Label = null
@export var sub_label: Label = null
@export var reward_label: Label = null
@export var chest_icon: TextureRect = null
@export var btn_ok: BaseButton = null
@export var lbl_ok: Label = null
@export var fx_anim: AnimationPlayer = null


func _on_open() -> void:
	if data.is_empty():
		return
	var threshold := int(data.get("stars", 0))
	var reward: Dictionary = data.get("reward", {}) if data.get("reward") is Dictionary else {}
	if title_label != null:
		title_label.text = tr("STR_DAILY_MILESTONE_POPUP_TITLE").format([threshold])
	if sub_label != null:
		sub_label.text = tr("STR_DAILY_MILESTONE_POPUP_SUB")
	if reward_label != null:
		reward_label.text = _reward_text(reward)
	if lbl_ok != null:
		lbl_ok.text = tr("STR_DAILY_MILESTONE_POPUP_OK")
	_pop_chest()


## Ghép chuỗi phần thưởng (Xu + lượt công cụ) từ định nghĩa mốc
func _reward_text(reward: Dictionary) -> String:
	var dm: Node = get_node_or_null("/root/DailyManager")
	if dm != null and dm.has_method("reward_text"):
		return str(dm.call("reward_text", reward))
	return ""


## Rương nảy nhẹ khi popup mở (animation "chest_pop" khai trong scene)
func _pop_chest() -> void:
	if DisplayServer.get_name() == "headless" or chest_icon == null:
		return
	chest_icon.pivot_offset = chest_icon.size * 0.5
	if fx_anim != null and fx_anim.has_animation(&"chest_pop"):
		fx_anim.play(&"chest_pop")
		return
	chest_icon.scale = Vector2.ONE * 0.6
	var tw := create_tween()
	tw.tween_property(chest_icon, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_ok_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	close()
