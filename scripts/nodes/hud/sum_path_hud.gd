class_name SumPathHUD
extends BaseHUD
## ============================================================================
## HUD Sum Path — mockup/matchup_sum_path.svg
##
## THỜI GIAN (250x156) + thẻ "CÂN BẰNG TỔNG ĐIỂM ĐƯỜNG ĐI" (715x156) gồm:
##   TỔNG HIỆN TẠI — con dấu TOÁN TỬ (< > =) — MỤC TIÊU PHẢI ĐẠT
##   + thanh tiến độ (tổng / mục tiêu) + chip trạng thái "CẦN THÊM / CÒN ĐƯỢC / ĐANG VƯỢT / ĐÃ ĐỦ".
## Chế độ này KHÔNG hiện thẻ THỬ THÁCH (challenge_card() = null) — thử thách chốt ở popup kết quả.
## ============================================================================


func _on_update(ctx: Dictionary) -> void:
	var mode := ctx.get("mode", null) as SumPathGameMode
	if mode == null:
		return
	set_label_text(get_node_or_null("Content/ModeInformation/Sheet/BlockCurrent/Sum/Value"), str(mode.current_sum))
	set_label_text(get_node_or_null("Content/ModeInformation/Sheet/Emblem/Operator/Value"), mode.operator)
	set_label_text(get_node_or_null("Content/ModeInformation/Sheet/BlockTarget/Target/Value"), str(mode.target_val))
	set_label_text(get_node_or_null("Content/ModeInformation/Sheet/BlockCurrent/Sum/Note"),
		tr("STR_HUD_SUM_MOVES").format([int(ctx.get("moves", 0))]))
	set_label_text(get_node_or_null("Content/ModeInformation/Sheet/BlockTarget/Target/ChipNeed/Need"), _need_text(mode))
	_update_progress(mode)


## Chip trạng thái theo toán tử:
##   "=" -> CẦN THÊM +N / ĐÃ ĐỦ / ĐANG VƯỢT N
##   "<" -> CÒN ĐƯỢC +N (được phép cộng thêm) / ĐANG VƯỢT N
##   ">" -> CẦN THÊM +N (phải vượt mục tiêu) / ĐÃ ĐỦ
func _need_text(mode: SumPathGameMode) -> String:
	match mode.operator:
		"<":
			var room := mode.target_val - 1 - mode.current_sum
			if room >= 0:
				return tr("STR_HUD_SUM_LEFT").format([room])
			return tr("STR_HUD_SUM_OVER").format([-room])
		">":
			var need := mode.target_val + 1 - mode.current_sum
			if need > 0:
				return tr("STR_HUD_SUM_NEED").format([need])
			return tr("STR_HUD_SUM_OK")
		_:
			var delta := mode.target_val - mode.current_sum
			if delta > 0:
				return tr("STR_HUD_SUM_NEED").format([delta])
			return tr("STR_HUD_SUM_OK") if delta == 0 else tr("STR_HUD_SUM_OVER").format([-delta])


## Thanh tiến độ = tổng hiện tại / mục tiêu (kẹp 0..1); phần đã đạt bị cắt bởi "Bar".
func _update_progress(mode: SumPathGameMode) -> void:
	var bar := get_node_or_null("Content/ModeInformation/Sheet/Bar") as Control
	var fill := get_node_or_null("Content/ModeInformation/Sheet/Bar/Fill") as Control
	if bar == null or fill == null:
		return
	var ratio := 0.0
	if mode.target_val > 0:
		ratio = clampf(float(mode.current_sum) / float(mode.target_val), 0.0, 1.0)
	fill.size = Vector2(bar.size.x * ratio, bar.size.y)
