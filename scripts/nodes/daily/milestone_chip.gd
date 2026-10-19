class_name DailyMilestoneChip
extends Button
## ============================================================================
## Component: MỐC THƯỞNG trên thanh Sao tháng (nodes/daily/milestone_chip.tscn)
##
## Bám ĐÚNG mockup/daily_challenge.svg: một "huy hiệu" tròn 86 px (scene dùng 43):
##   · Vòng hổ phách đậm = mốc đã đạt · vòng xanh nhạt = chưa đạt
##   · Ruột là rương quà · nhãn "N★" ngay dưới
##   · Huy hiệu ✓ xanh ở góc trên-phải khi mốc ĐÃ NHẬN thưởng
## Bấm khi đủ Sao ⇒ phát `claim_requested(threshold)` để màn Daily nhận thưởng.
## Dùng chung cho cả 2 hướng màn hình.
## ============================================================================

signal claim_requested(threshold: int)

const TEX_DIR := "res://assets/images-png/daily/"

## Ngưỡng Sao của mốc đang hiển thị
var threshold: int = 0

@export var ring: TextureRect = null
@export var chest: TextureRect = null
@export var badge: TextureRect = null
@export var lbl_stars: Label = null


## `stars_now` = tổng Sao của tháng, `claimed` = mốc này đã nhận chưa
func setup(def: Dictionary, stars_now: int, claimed: bool) -> void:
	threshold = int(def.get("stars", 0))
	if lbl_stars != null:
		lbl_stars.text = tr("STR_DAILY_MILESTONE_STARS").format([threshold])
	var reached := stars_now >= threshold
	if ring != null:
		ring.texture = _tex("ring_on.png" if reached else "ring_off.png")
	if chest != null:
		# Rương ĐÓNG (`chest_closed`) khi chưa nhận thưởng · rương MỞ (`chest`) khi đã nhận
		chest.texture = _tex("chest.png" if claimed else "chest_closed.png")
		chest.modulate = Color(1, 1, 1, 1) if reached else Color(1, 1, 1, 0.85)
	if badge != null:
		badge.visible = claimed
	var ready := reached and not claimed
	disabled = not ready
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if ready else Control.CURSOR_ARROW
	tooltip_text = "" if claimed else tr("STR_DAILY_MILESTONE_CLAIM")


func _tex(file: String) -> Texture2D:
	return load(TEX_DIR + file) as Texture2D


func _on_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	claim_requested.emit(threshold)
