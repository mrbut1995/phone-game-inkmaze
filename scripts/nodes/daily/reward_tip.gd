class_name DailyRewardTip
extends Control
## ============================================================================
## Bong bóng THÔNG TIN PHẦN THƯỞNG khi NHẤN GIỮ một mốc thưởng
## (scripts/nodes/daily/reward_tip.gd + nodes/daily/reward_tip.tscn)
##
## Màn Daily instance 1 bóng, đặt làm con của `Stage` (cùng hệ toạ độ thiết kế). `popup_at()`
## nhận chip mốc + dữ liệu, tự đo kích thước, đặt phía TRÊN chip (đuôi chỉ xuống); thiếu chỗ ở
## phía trên thì đặt phía DƯỚI (đuôi lật lên). Hiện/ẩn bằng AnimationPlayer `Anim`
## (`show` / `hide`) — script chỉ chọn animation.
## ============================================================================

## Khoảng đệm giữa bóng và chip + mép an toàn của khung thiết kế
const GAP := 4.0  # keep-code: hằng dùng cho hiệu ứng/dữ liệu runtime (không phải bố cục tĩnh)
const EDGE := 6.0

@export var bg: Control = null
@export var tail: TextureRect = null
@export var content: Control = null
@export var lbl_title: Label = null
@export var lbl_reward: Label = null
@export var lbl_status: Label = null
@export var anim: AnimationPlayer = null

## Lề giữa viền bóng và nội dung
@export var pad := Vector2(14, 10)

var _shown := false


## `chip` = chip đang nhấn giữ · `def` = định nghĩa mốc · `stars_now` = Sao tháng hiện có ·
## `claimed` = đã nhận chưa · `stage` = Control cha (khung thiết kế) để quy đổi toạ độ · `anchor` = vùng bám
func popup_at(chip: Control, def: Dictionary, stars_now: int, claimed: bool, stage: Control,
		anchor: Control = null) -> void:
	if chip == null or stage == null:
		return
	# `anchor` = phần nhìn thấy của chip (vòng huy hiệu) để bóng bám sát; mặc định cả chip
	if anchor == null:
		anchor = chip
	var threshold := int(def.get("stars", 0))
	if lbl_title != null:
		lbl_title.text = tr("STR_DAILY_MILESTONE_STARS").format([threshold])
	if lbl_reward != null:
		lbl_reward.text = _reward_text(def)
	if lbl_status != null:
		if claimed:
			lbl_status.text = "✓"  # keep-code: chữ theo dữ liệu (runtime)
		elif stars_now >= threshold:
			lbl_status.text = tr("STR_DAILY_MILESTONE_CLAIM")  # keep-code: chữ theo dữ liệu (runtime)
		else:
			lbl_status.text = "%d/%d ★" % [stars_now, threshold]
		var tint := Color(0.13, 0.5, 0.27) if (claimed or stars_now >= threshold) \
			else Color(0.55, 0.36, 0.05)
		lbl_status.add_theme_color_override("font_color", tint)

	# Đo kích thước theo nội dung
	var need := (content.get_combined_minimum_size() if content != null else Vector2(80, 40)) + pad * 2.0
	need.x = maxf(need.x, 84.0)
	size = need
	if bg != null:
		bg.size = need * 2.0  # nền vẽ gấp đôi, node scale 0.5 (nét sắc)
	if content != null:
		content.position = pad
		content.size = need - pad * 2.0

	# Toạ độ chip theo hệ của Stage (đã tính cả scale của Stage)
	var inv := stage.get_global_transform().affine_inverse()
	var gt := anchor.get_global_transform()
	var top_c := inv * (gt * Vector2(anchor.size.x * 0.5, 0.0))
	var bot_c := inv * (gt * Vector2(anchor.size.x * 0.5, anchor.size.y))
	var tail_h := tail.size.y if tail != null else 0.0

	var above := top_c.y - GAP - tail_h - need.y >= EDGE
	var y := top_c.y - GAP - tail_h - need.y if above else bot_c.y + GAP + tail_h
	var x := clampf(top_c.x - need.x * 0.5, EDGE, maxf(stage.size.x - need.x - EDGE, EDGE))
	position = Vector2(x, y)

	if tail != null:
		var tx := clampf(top_c.x - x, tail.size.x * 0.5 + 8.0, need.x - tail.size.x * 0.5 - 8.0)
		tail.flip_v = not above
		tail.position = Vector2(tx - tail.size.x * 0.5, need.y - 3.0 if above else -tail.size.y + 3.0)
		pivot_offset = Vector2(tx, need.y + tail_h if above else -tail_h)
	else:
		pivot_offset = need * 0.5

	visible = true
	_shown = true
	if anim != null and anim.has_animation(&"show"):
		anim.stop()
		anim.play(&"show")


func dismiss() -> void:
	if not _shown:
		return
	_shown = false
	if anim != null and anim.has_animation(&"hide"):
		anim.stop()
		anim.play(&"hide")
	else:
		visible = false


func is_open() -> bool:
	return _shown


## Dây `animation_finished` của `Anim` khai trong scene
func _on_anim_finished(anim_name: StringName) -> void:
	if anim_name == &"hide" and not _shown:
		visible = false


func _reward_text(def: Dictionary) -> String:
	var dm: Node = get_node_or_null("/root/DailyManager")
	if dm != null and dm.has_method("reward_text"):
		return str(dm.call("reward_text", def))
	return ""
