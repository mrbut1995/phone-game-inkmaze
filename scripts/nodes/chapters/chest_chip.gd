class_name ChapterChestChip
extends Button
## ============================================================================
## Component: RƯƠNG MỐC THƯỞNG của CHƯƠNG — một chấm tròn nằm trên thanh tiến độ
## ở màn Chọn chương (nodes/chapters/chest_chip.tscn).
##
## Cùng ngôn ngữ hình ảnh với huy hiệu mốc thưởng ở màn Daily (dùng lại art
## `assets/images-png/daily/`):
##   · Vòng hổ phách = đã đủ Sao · vòng xanh nhạt = chưa đủ
##   · Ruột là rương quà (đóng khi chưa nhận · mở khi đã nhận)
##   · Huy hiệu ✓ ở góc trên-phải khi ĐÃ NHẬN
## Bấm khi đủ Sao ⇒ `claim_requested(index)` để màn Chọn chương trao thưởng.
## ============================================================================

signal claim_requested(index: int)

const TEX_DIR := "res://assets/images-png/daily/"

## Mốc (0..2) mà chip này đang hiển thị
var index: int = 0
## Ngưỡng Sao của mốc này (0 = chưa biết)
var threshold: int = 0

@export var ring: TextureRect = null
@export var chest: TextureRect = null
@export var badge: TextureRect = null
## Nhãn ngưỡng "9★" cạnh chip (thanh dọc ở lề trái) — rỗng = ẩn
@export var lbl_threshold: Label = null
## Huy hiệu đỏ "!" khi ĐỦ Sao mà chưa nhận (chip đang "thở" để hút mắt)
@export var ready_badge: Control = null
@export var pulse_anim: AnimationPlayer = null

var _claimable := false
var _label_below := false


## Nhãn ngưỡng nằm DƯỚI chip (thanh NGANG) thay vì bên phải (thanh dọc)
func set_label_below(below: bool) -> void:
	_label_below = below
	if lbl_threshold == null:
		return
	if below:
		lbl_threshold.anchor_left = 0.5
		lbl_threshold.anchor_right = 0.5
		lbl_threshold.anchor_top = 1.0
		lbl_threshold.anchor_bottom = 1.0
		lbl_threshold.offset_left = -24.0
		lbl_threshold.offset_right = 24.0
		lbl_threshold.offset_top = 1.0
		lbl_threshold.offset_bottom = 17.0
		lbl_threshold.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	else:
		lbl_threshold.anchor_left = 1.0
		lbl_threshold.anchor_right = 1.0
		lbl_threshold.anchor_top = 0.5
		lbl_threshold.anchor_bottom = 0.5
		lbl_threshold.offset_left = 4.0
		lbl_threshold.offset_right = 44.0
		lbl_threshold.offset_top = -9.0
		lbl_threshold.offset_bottom = 9.0
		lbl_threshold.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT


## `def` = định nghĩa rương (`GameManager.chapter_chest_defs()`), `stars_now` = Sao hiện có của chương
func setup(def: Dictionary, stars_now: int, claimed: bool) -> void:
	index = int(def.get("index", 0))
	threshold = int(def.get("stars", 0))
	var reached := threshold > 0 and stars_now >= threshold
	if ring != null:
		ring.texture = _tex("ring_on.png" if reached else "ring_off.png")
	if chest != null:
		chest.texture = _tex("chest.png" if claimed else "chest_closed.png")
		chest.modulate = Color(1, 1, 1, 1) if reached else Color(1, 1, 1, 0.8)
	if badge != null:
		badge.visible = claimed
	_claimable = reached and not claimed
	# Khoá (chưa đủ Sao) ⇒ làm mờ cả chip; sẵn sàng ⇒ hiện "!" + nhịp thở
	if ready_badge != null:
		ready_badge.visible = _claimable
	modulate = Color(1, 1, 1, 1) if reached else Color(1, 1, 1, 0.62)
	_update_pulse()
	if lbl_threshold != null:
		lbl_threshold.text = tr("STR_DAILY_MILESTONE_STARS").format([threshold]) \
			if threshold > 0 else ""
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if _claimable else Control.CURSOR_ARROW
	tooltip_text = TranslationServer.translate("STR_CHAPTER_CHEST_TOOLTIP").format([
		threshold, _reward_text(def)])


## Chip "thở" khi đủ Sao mà chưa nhận; các trạng thái khác đứng yên
func _update_pulse() -> void:
	if pulse_anim == null or not pulse_anim.has_animation(&"ready"):
		return
	if _claimable:
		if not pulse_anim.is_playing():
			pulse_anim.play(&"ready")
	elif pulse_anim.is_playing():
		pulse_anim.stop()


## Đang ở trạng thái "đủ Sao và chưa nhận" (bấm được)
func is_claimable() -> bool:
	return _claimable


## Đã nhận thưởng mốc này chưa (dấu ✓ đang hiện)
func is_claimed() -> bool:
	return badge != null and badge.visible


## Chuỗi phần thưởng ("+50 XU" · "Gợi ý ×2 + Hoàn tác ×1") — GameManager lo phần ghép chuỗi
func _reward_text(def: Dictionary) -> String:
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("chapter_chest_reward_text"):
		return str(gm.call("chapter_chest_reward_text", def))
	return ""


func _tex(file: String) -> Texture2D:
	return load(TEX_DIR + file) as Texture2D


func _on_pressed() -> void:
	if not _claimable:
		return
	Sfx.play(Sfx.BTN_CLICK)
	claim_requested.emit(index)
