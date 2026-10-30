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
## NHẤN GIỮ (~0.35 s) ở BẤT KỲ trạng thái nào ⇒ `hold_started(chip)` (màn Daily hiện bóng thông tin
## phần thưởng), thả tay ⇒ `hold_ended`; lần nhả đó KHÔNG tính là bấm nhận thưởng.
## Dùng chung cho cả 2 hướng màn hình.
## ============================================================================

signal claim_requested(threshold: int)
signal hold_started(chip: DailyMilestoneChip)
signal hold_ended

const TEX_DIR := "res://assets/images-png/daily/"  # keep-code: hằng dùng cho hiệu ứng/dữ liệu runtime (không phải bố cục tĩnh)

## Ngưỡng Sao của mốc đang hiển thị
var threshold: int = 0

@export var ring: TextureRect = null
@export var chest: TextureRect = null
@export var badge: TextureRect = null
@export var lbl_stars: Label = null
## Bản "đường mốc" (road_chip.tscn): nhãn phần thưởng + bảng chứa 2 nhãn, đặt cạnh vòng huy hiệu
@export var lbl_reward: Label = null
@export var tag: Control = null
## AnimationPlayer: `unlock` (vừa đạt mốc: nảy + toả sáng) · `ready` (lặp: lắc nhẹ gọi bấm NHẬN) · `RESET`
@export var fx_anim: AnimationPlayer = null
## Timer one-shot: hết giờ = coi là nhấn giữ
@export var hold_timer: Timer = null

## Mốc đã đủ Sao nhưng chưa nhận ⇒ chạy `ready` để hút mắt
var _claimable := false
## Lần nhấn hiện tại đã thành "nhấn giữ" (chặn `pressed` ngay sau đó)
var _hold_shown := false


## `stars_now` = tổng Sao của tháng, `claimed` = mốc này đã nhận chưa
func setup(def: Dictionary, stars_now: int, claimed: bool) -> void:
	threshold = int(def.get("stars", 0))
	if lbl_stars != null:
		lbl_stars.text = tr("STR_DAILY_MILESTONE_STARS").format([threshold])
	if lbl_reward != null:
		lbl_reward.text = _reward_text(def)
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
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if ready else Control.CURSOR_ARROW
	_claimable = ready
	_update_idle_fx()


## Vừa đạt mốc (Sao bay xong, thanh vượt ngưỡng): nảy + toả sáng rồi chuyển sang `ready` lặp
func play_unlock() -> void:
	if fx_anim == null or not fx_anim.has_animation(&"unlock"):
		return
	fx_anim.play(&"unlock")
	if _claimable and fx_anim.has_animation(&"ready"):
		fx_anim.queue(&"ready")


## Chip đủ Sao + chưa nhận ⇒ `ready` lặp; còn lại ⇒ về trạng thái nghỉ (không restart nếu đang chạy)
func _update_idle_fx() -> void:
	if fx_anim == null:
		return
	if _claimable:
		if (not fx_anim.is_playing() or fx_anim.current_animation == "RESET") \
				and fx_anim.has_animation(&"ready"):
			fx_anim.play(&"ready")
	elif fx_anim.is_playing() and fx_anim.current_animation != "RESET":
		fx_anim.stop()
		if fx_anim.has_animation(&"RESET"):
			fx_anim.play(&"RESET")
			fx_anim.seek(0.0, true)


## Đặt bảng phần thưởng bên PHẢI (true) hoặc bên TRÁI (false) vòng huy hiệu
func set_tag_side(on_right: bool) -> void:
	if tag == null or ring == null:
		return
	var center := size * 0.5
	var gap := 6.0
	var half := ring.size.x * 0.5
	var x := center.x + half + gap if on_right else center.x - half - gap - tag.size.x
	tag.position = Vector2(x, center.y - tag.size.y * 0.5)


## Bản NGANG: bảng phần thưởng nằm DƯỚI (true) hoặc TRÊN (false) vòng huy hiệu, canh giữa theo chiều ngang
func set_tag_vertical(below: bool) -> void:
	if tag == null or ring == null:
		return
	var center := size * 0.5
	var gap := 4.0
	var half := ring.size.y * 0.5
	var y := center.y + half + gap if below else center.y - half - gap - tag.size.y
	tag.position = Vector2(center.x - tag.size.x * 0.5, y)


func _reward_text(def: Dictionary) -> String:
	var dm: Node = Svc.daily()
	if dm != null and dm.has_method("reward_text"):
		return str(dm.call("reward_text", def))
	return ""


func _tex(file: String) -> Texture2D:
	return load(TEX_DIR + file) as Texture2D


func _on_pressed() -> void:
	if _hold_shown or not _claimable:
		return
	Sfx.play(Sfx.BTN_CLICK)
	claim_requested.emit(threshold)


func _on_button_down() -> void:
	_hold_shown = false
	if hold_timer != null:
		hold_timer.start()


func _on_button_up() -> void:
	if hold_timer != null:
		hold_timer.stop()
	if _hold_shown:
		hold_ended.emit()
		# `pressed` có thể đến SAU `button_up` trong cùng khung ⇒ chỉ xoá cờ ở cuối khung
		_clear_hold.call_deferred()


func _on_hold_timeout() -> void:
	_hold_shown = true
	hold_started.emit(self)


func _clear_hold() -> void:
	_hold_shown = false
