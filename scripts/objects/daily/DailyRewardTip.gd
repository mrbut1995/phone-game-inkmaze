class_name DailyRewardTip
extends Control
## ============================================================================
## Bong bóng THÔNG TIN PHẦN THƯỞNG khi NHẤN GIỮ một mốc thưởng
## (scripts/ui/widgets/daily/reward_tip.gd + nodes/daily/reward_tip.tscn)
##
## Màn Daily instance 1 bóng, đặt làm con của `Stage` (cùng hệ toạ độ thiết kế). `popup_at()`
## nhận chip mốc + dữ liệu, tự đo kích thước, đặt phía TRÊN chip (đuôi chỉ xuống); thiếu chỗ ở
## phía trên thì đặt phía DƯỚI (đuôi lật lên). Hiện/ẩn bằng AnimationPlayer `Anim`
## (`show` / `hide`) — script chỉ chọn animation.
## ============================================================================

## Khoảng đệm giữa bóng và chip + mép an toàn của khung thiết kế
## Scene contract
## Exports:  bg, tail, content, lbl_title, lbl_reward, lbl_status, anim, pad
## Emits:    (none)
## Handlers wired in scene: _on_anim_finished
## Subscribes in code (EventBus/Model): (none)

const GAP := 4.0  # keep-code: hằng dùng cho hiệu ứng/dữ liệu runtime (không phải bố cục tĩnh)
const EDGE := 6.0

@export var bg: Control = null
@export var tail: TextureRect = null
@export var content: Control = null
@export var lbl_title: Label = null
@export var lbl_reward: Label = null
@export var lbl_status: Label = null
## Hàng ICON phần thưởng (dựng sẵn trong scene): Xu / Gợi ý / Dịch chuyển
@export var icons: HBoxContainer = null
@export var row_coins: Control = null
@export var lbl_coins: Label = null
@export var row_hint: Control = null
@export var lbl_hint: Label = null
@export var row_teleport: Control = null
@export var lbl_teleport: Label = null
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
	_show_reward(row_coins, lbl_coins, int(def.get("coins", 0)), "+%d")
	_show_reward(row_hint, lbl_hint, int(def.get("hint", 0)), "×%d")
	_show_reward(row_teleport, lbl_teleport, int(def.get("teleport", 0)), "×%d")

	# Đo kích thước theo nội dung
	# Đo theo hàng icon (container chỉ cập nhật cỡ tối thiểu ở khung sau)
	var inner := icons.get_combined_minimum_size() if icons != null else Vector2(80, 40)
	var need := inner + pad * 2.0  # EXCEPTION(R1-keep): hệ số 2 = lề 2 phía
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
	var dm: Node = Svc.daily()
	if dm != null and dm.has_method("reward_text"):
		return str(dm.call("reward_text", def))
	return ""


## Hiện / ẩn một dòng icon thưởng theo số lượng (>0 mới hiện)
func _show_reward(row: Control, lbl: Label, amount: int, fmt: String) -> void:
	if row == null:
		return
	row.visible = amount > 0
	if lbl != null and amount > 0:
		lbl.text = fmt % amount
