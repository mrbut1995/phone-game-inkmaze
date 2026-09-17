class_name FadingInkHUD
extends BaseHUD
## ============================================================================
## HUD Fading Ink — mockup/matchup_fading_ink.svg
##
## THỜI GIAN (250x156) + "TRẠM ĐO ĐỘ PHAI MỰC" (715x156):
##   BƯỚC ĐÃ ĐI (+ số mực đã phai) · QUANG PHỔ ĐẬM NHẠT CỦA MỰC (4 mức, tĩnh) ·
##   cảnh báo "N Ô ĐÃ CẠN MỰC" (ẩn khi chưa có ô nào cạn).
## Chế độ này KHÔNG hiện thẻ THỬ THÁCH (challenge_card() = null).
## ============================================================================


func _on_update(ctx: Dictionary) -> void:
	var mode := ctx.get("mode", null) as FadingInkGameMode
	if mode == null:
		return
	var moves := mode.moves_made
	set_label_text(get_node_or_null("Steps/Value"), "%02d" % moves)
	set_label_text(get_node_or_null("Steps/Delta"), tr("STR_HUD_INK_LOST").format([moves]))
	var exhausted := mode.count_exhausted()
	set_label_text(get_node_or_null("Warn/Bg/Label"), tr("STR_HUD_INK_WARN").format([exhausted]))
	var warn := get_node_or_null("Warn") as Control
	if warn != null:
		warn.visible = exhausted > 0
