class_name SumPathHUD
extends BaseHUD
## ============================================================================
## HUD Sum Path — thẻ "CÂN BẰNG TỔNG ĐIỂM ĐƯỜNG ĐI".
##
## 2026-09-27 — theo yêu cầu "chỉ hiện thứ cần thiết": HUD này CHỈ hiện **TỔNG hiện tại ·
## TOÁN TỬ (< = >) · MỤC TIÊU** (+ chip "CẦN THÊM / CÒN ĐƯỢC / ĐANG VƯỢT" nằm trong khối MỤC TIÊU).
## Đã gỡ khỏi HUD: dòng tiêu đề thẻ · thanh tiến độ (tổng/mục tiêu) · đồng hồ THỜI GIAN
## (node `Time` của bản DỌC để `visible = false`, bản NGANG đã xoá khỏi scene).
## ============================================================================

## TỔNG hiện tại (`…/Sheet/BlockCurrent/Sum/Value`)
@export var sum_value_node : Label
## Dòng "n BƯỚC" trong khối TỔNG (`…/Sheet/BlockCurrent/Sum/Note`)
@export var sum_note_label : Label
## Toán tử `<` `=` `>` (`…/Sheet/Emblem/Operator/Value`)
@export var operator_value_label : Label
## MỤC TIÊU (`…/Sheet/BlockTarget/Target/Value`)
@export var target_value_node : Label
## Chip trạng thái trong khối MỤC TIÊU (`…/BlockTarget/Target/ChipNeed/Need`)
@export var need_label : Label


func _on_update(ctx: Dictionary) -> void:
	var mode := ctx.get("mode", null) as SumPathGameMode
	if mode == null:
		return
	set_label_text(sum_value_node, str(mode.current_sum))
	set_label_text(operator_value_label, mode.operator)
	set_label_text(target_value_node, str(mode.target_val))
	set_label_text(sum_note_label, tr("STR_HUD_SUM_MOVES").format([int(ctx.get("moves", 0))]))
	set_label_text(need_label, _need_text(mode))


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
