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

var _claimable := false


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
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if _claimable else Control.CURSOR_ARROW
	tooltip_text = TranslationServer.translate("STR_CHAPTER_CHEST_TOOLTIP").format([
		threshold, _reward_text(def)])


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
