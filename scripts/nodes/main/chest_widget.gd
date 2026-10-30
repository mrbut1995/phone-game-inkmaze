class_name ChapterChestWidget
extends Button
## ============================================================================
## Node: ChapterChestWidget — RƯƠNG MỐC THƯỞNG của chương, nằm góc dưới-phải bản đồ Main
## (nodes/main/chest_widget.tscn). Thay cho thanh `ChapterProgress` + 3 `ChapterChestChip`
## của màn Levels cũ: chỉ hiện MỘT rương = mốc CHƯA NHẬN kế tiếp, kèm "★ sao_hiện_có/ngưỡng".
##
## Trạng thái:
##   · CHƯA ĐỦ sao  ⇒ đĩa nét đứt, rương xám xanh, đứng yên (bấm ⇒ animation `nudge` + tooltip)
##   · ĐỦ sao, chưa nhận ⇒ đĩa vàng, huy hiệu "!", rương lắc + sáng (animation `ready`)
##   · ĐÃ NHẬN HẾT ⇒ rương mở + dấu ✓, nhãn "sao/tổng", đứng yên
## Bấm khi đủ sao ⇒ `claim_requested(index)`; LevelSection gọi GameManager trao thưởng.
## Art dùng lại của chest_chip.gd (assets/images-png/daily + level_selector).
## ============================================================================

signal claim_requested(index: int)

const TEX_DIR := "res://assets/images-png/daily/"  # keep-code: hằng dùng cho hiệu ứng/dữ liệu runtime (không phải bố cục tĩnh)
const RING_DIR := "res://assets/images-png/level_selector/"  # keep-code: hằng dùng cho hiệu ứng/dữ liệu runtime (không phải bố cục tĩnh)
const CHEST_LOCKED := Color(0.62, 0.72, 0.8, 1.0)  # keep-code: hằng dùng cho hiệu ứng/dữ liệu runtime (không phải bố cục tĩnh)

@export var ring: TextureRect = null
@export var chest: TextureRect = null
@export var badge_done: TextureRect = null
@export var badge_ready: Control = null
@export var glow: Control = null
@export var lbl_stars: Label = null
@export var anim: AnimationPlayer = null

var _claimable := false
var _index := -1


## `defs` = `GameManager.chapter_chest_defs(total)` · `claimed[i]` = mốc i đã nhận chưa
func setup(defs: Array, stars_own: int, stars_total: int, claimed: Array) -> void:
	_index = -1
	var next_def := {}
	for i in defs.size():
		var is_claimed := i < claimed.size() and bool(claimed[i])
		if not is_claimed:
			next_def = defs[i] as Dictionary
			break
	var all_done := next_def.is_empty() and not defs.is_empty()
	visible = not defs.is_empty()
	if defs.is_empty():
		return

	if all_done:
		_claimable = false
		_apply_look(true, true)
		_set_label(stars_own, stars_total)
		tooltip_text = ""
		_play(&"RESET")
		return

	var threshold := int(next_def.get("stars", 0))
	_index = int(next_def.get("index", 0))
	var reached := threshold > 0 and stars_own >= threshold
	_claimable = reached
	_apply_look(reached, false)
	_set_label(stars_own, threshold)
	tooltip_text = TranslationServer.translate("STR_CHAPTER_CHEST_TOOLTIP").format([
		threshold, _reward_text(next_def)])
	_play(&"ready" if reached else &"RESET")


func is_claimable() -> bool:
	return _claimable


func _apply_look(reached: bool, opened: bool) -> void:
	# Không còn đĩa tròn nền: chỉ hiện icon rương (Ring chỉ là trục xoay cho animation lắc)
	if chest != null:
		chest.texture = load(TEX_DIR + ("chest.png" if opened else "chest_closed.png")) as Texture2D
		chest.modulate = Color(1, 1, 1, 1) if reached else CHEST_LOCKED
	if badge_done != null:
		badge_done.visible = opened
	if badge_ready != null:
		badge_ready.visible = _claimable
	if glow != null:
		glow.visible = _claimable
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if _claimable else Control.CURSOR_ARROW


func _set_label(own: int, goal: int) -> void:
	if lbl_stars != null:
		lbl_stars.text = "%d/%d" % [own, goal]


func _play(name: StringName) -> void:
	if anim == null or not anim.has_animation(name):
		return
	if name == &"RESET":
		anim.stop()
		anim.play(&"RESET")
		anim.advance(0.0)
	elif anim.current_animation != name or not anim.is_playing():
		anim.play(name)


func _reward_text(def: Dictionary) -> String:
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("chapter_chest_reward_text"):
		return str(gm.call("chapter_chest_reward_text", def))
	return ""


func _on_pressed() -> void:
	if _claimable and _index >= 0:
		Sfx.play(Sfx.BTN_CLICK)
		claim_requested.emit(_index)
	elif anim != null and anim.has_animation(&"nudge"):
		Sfx.play(Sfx.BTN_CLICK)
		anim.play(&"nudge")
