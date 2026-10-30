class_name DailyMilestonePopup
extends BasePopup
## ============================================================================
## Popup NHỎ: báo phần thưởng vừa nhận ở một MỐC SAO của màn Daily
## (nodes/popups/daily_milestone.tscn)
##
## Mở bằng `Popups.open(Popups.DAILY_MILESTONE, { "stars": <ngưỡng>, "reward": <def> })`
## trong đó `reward` là Dictionary của `DailyManager.MILESTONES`
## (`{stars, coins, hint, undo, skip}`) — script chỉ HIỂN THỊ, không tự cộng gì.
##
## RƯƠNG QUÀ: dùng `AnimatedSprite2D` + `SpriteFrames` sinh từ
## `assets/images/spritesheets/chest_spritesheet.png` (4 animation: `closed` ·
## `opening` · `idle` · `open` cũ). Toàn bộ HIỆU ỨNG viết bằng AnimationPlayer NGAY
## TRONG SCENE, script chỉ gọi `play("reveal")` — không tween/hiệu ứng nào trong code:
##   - `FxAnim` / `reveal` (~2.6s): rương rơi xuống nảy → rung tăng dần → ép xuống rồi
##     bật nắp (`opening`) kèm bùng sáng, 2 vòng sóng, tia sáng, nổ sparkle/xu/confetti
##     → rương `idle` lấp lánh → dòng phần thưởng bật ra.
##   - `LoopAnim` / `idle_loop` (autoplay, lặp vô hạn): tia sáng xoay + vầng sáng thở.
## SVG hiệu ứng nằm ở `assets/images/effects/` (fx_*.svg).
## ============================================================================

## Node binding: khai `node_paths` + NodePath trong `daily_milestone.tscn`
@export var title_label: Label = null
@export var sub_label: Label = null
@export var reward_label: Label = null
## Rương quà dạng sprite animation (SpriteFrames `chest_frames.tres`)
@export var chest_sprite: AnimatedSprite2D = null
@export var btn_ok: BaseButton = null
@export var lbl_ok: Label = null
@export var fx_anim: AnimationPlayer = null


func _on_open() -> void:
	if data.is_empty():
		return
	var threshold := int(data.get("stars", 0))
	var reward: Dictionary = data.get("reward", {}) if data.get("reward") is Dictionary else {}
	if title_label != null:
		# `title_text` = tiêu đề do nơi mở truyền sẵn (VD rương mốc của CHƯƠNG ở màn Chọn chương)
		if data.has("title_text"):
			title_label.text = str(data.get("title_text"))
		else:
			title_label.text = tr("STR_DAILY_MILESTONE_POPUP_TITLE").format([threshold])
	if sub_label != null:
		sub_label.text = str(data.get("sub_text", tr("STR_DAILY_MILESTONE_POPUP_SUB")))
	if reward_label != null:
		# `reward_text` = chuỗi phần thưởng dựng sẵn (rương chương có thêm "lượt chơi")
		reward_label.text = str(data.get("reward_text", _reward_text(reward)))
	if lbl_ok != null:
		lbl_ok.text = tr("STR_DAILY_MILESTONE_POPUP_OK")  # keep-code: chữ theo dữ liệu (runtime)
	_replay_reveal()


## Ghép chuỗi phần thưởng (Xu + lượt công cụ) từ định nghĩa mốc
func _reward_text(reward: Dictionary) -> String:
	var dm: Node = Svc.daily()
	if dm != null and dm.has_method("reward_text"):
		return str(dm.call("reward_text", reward))
	return ""


## Chạy lại chuỗi hiệu ứng rương (mở lại popup khi nó đã tồn tại)
func _replay_reveal() -> void:
	if fx_anim == null or not fx_anim.has_animation(&"reveal"):
		return
	fx_anim.stop()
	fx_anim.play(&"reveal")
	# Áp trạng thái t=0 ngay (rương/phần thưởng ẩn) để không lộ 1 khung hình sai trước khi chạy
	fx_anim.advance(0.0)


func _on_ok_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	close()
