class_name CountdownHUD
extends BaseHUD
## ============================================================================
## HUD Countdown Cost — mockup/matchup_countdown_cost.svg
##
## THỜI GIAN (250x156) + "SỔ THEO DÕI NGÂN SÁCH BƯỚC CHÂN" (715x156):
##   NGÂN SÁCH CÒN (số dư / tổng) · ĐÃ TIÊU TỐN (-N BƯỚC, số ô đã đi) ·
##   GIÁ CƯỚC MỖI Ô (chip rẻ / đắt theo độ khó + dự phòng) + dải phân đoạn ngân sách.
## Chế độ này KHÔNG hiện thẻ THỬ THÁCH nữa (challenge_card() = null).
## ============================================================================

const SEGMENT_SCENE := preload("res://nodes/hud/countdown_segment.tscn")
const SEGMENT_FALLBACK_WIDTH := 327
const SEGMENT_GAP := 2

## Số phân đoạn đã dựng (chỉ dựng lại khi ngân sách đổi)
var _built_segments: int = -1


func _on_update(ctx: Dictionary) -> void:
	var mode := ctx.get("mode", null) as CountdownCostGameMode
	if mode == null:
		return
	var total: int = maxi(mode.initial_steps, 1)
	var left: int = clampi(int(ctx.get("steps_remaining", 0)), 0, total)
	var spent: int = total - left

	set_label_text(get_node_or_null("ModeInformation/Sheet/Budget/Value"), "%02d" % left)
	set_label_text(get_node_or_null("ModeInformation/Sheet/Budget/Max"), "/ %d" % total)
	set_label_text(get_node_or_null("ModeInformation/Sheet/Spent/Value"), "-%02d" % spent)
	set_label_text(get_node_or_null("ModeInformation/Sheet/Spent/Note"),
		tr("STR_HUD_BUDGET_CELLS").format([int(ctx.get("moves", 0))]))
	set_label_text(get_node_or_null("ModeInformation/Sheet/Price/Reserve"),
		tr("STR_HUD_BUDGET_RESERVE").format([mode.budget_reserve()]))

	_update_price_chips(mode)
	_update_segments(total, spent)


## 2 chip giá cước: RẺ = [min..min+1], ĐẮT = [min+2..max].
## Độ khó không có mức đắt (easy 1-2) -> ẩn hẳn chip đắt.
func _update_price_chips(mode: CountdownCostGameMode) -> void:
	var range_v: Vector2i = mode.cost_range()
	var cheap := get_node_or_null("ModeInformation/Sheet/Price/ChipCheap")
	if cheap != null:
		set_label_text(cheap.get_node_or_null("Label"),
			tr("STR_HUD_PRICE_CHEAP").format([range_v.x, mini(range_v.x + 1, range_v.y)]))
	var pricey := get_node_or_null("ModeInformation/Sheet/Price/ChipPricey") as Control
	if pricey == null:
		return
	var has_pricey: bool = range_v.y >= range_v.x + 2
	pricey.visible = has_pricey
	if not has_pricey:
		return
	var top: int = range_v.x + 2
	var pricey_label := pricey.get_node_or_null("Label")
	if top == range_v.y:
		set_label_text(pricey_label, tr("STR_HUD_PRICE_PRICEY_ONE").format([top]))
	else:
		set_label_text(pricey_label, tr("STR_HUD_PRICE_PRICEY").format([top, range_v.y]))


## Dải phân đoạn: mỗi phân đoạn = 1 bước; đã dùng = xám (SEGMENT_OFF), còn lại = cam (SEGMENT_ON).
## Bề rộng phân đoạn tự co để cả dải luôn vừa đúng bề rộng thẻ (ngân sách có thể > 16 bước).
func _update_segments(total: int, spent: int) -> void:
	var box := get_node_or_null("ModeInformation/Sheet/Segments") as HBoxContainer
	if box == null:
		return
	if total != _built_segments:
		for child in box.get_children():
			box.remove_child(child)
			child.queue_free()
		var track: float = box.size.x if box.size.x > 0.0 else SEGMENT_FALLBACK_WIDTH
		var width: float = (track - SEGMENT_GAP * float(total - 1)) / float(total)
		for i in total:
			var seg := SEGMENT_SCENE.instantiate() as CountdownSegment
			seg.set_width(width)
			box.add_child(seg)
		_built_segments = total
	var index := 0
	for child in box.get_children():
		var seg := child as CountdownSegment
		if seg != null:
			seg.set_used(index < spent)
		index += 1
