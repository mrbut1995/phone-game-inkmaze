class_name OneStrokeHUD
extends BaseHUD
## ============================================================================
## HUD One Stroke — mockup/matchup_one_stroke.svg
##
## THỜI GIAN (270×156, chip "ĐANG TÍNH GIỜ") + "BẢNG TIẾN ĐỘ PHỦ KÍN" (690×156):
##   · cột trái : "📐 ĐÃ PHỦ KÍN" + "13/25 Ô" + "CÒN LẠI 12 Ô" (đỏ)
##   · cột phải : hàng luật "✍️ MỘT NÉT KHÔNG LẶP" + chip "52% KÍN"
##                + thanh tiến độ (tô theo số ô đã đi) + 2 dòng nhắc luật
##
## Luật (xem `OneStrokeGameMode`): phủ kín mọi ô bằng 1 nét, không đi lại ô cũ
## (đi lại = thua ngay), F chỉ được chạm ở nước cuối cùng.
## Chế độ này KHÔNG hiện thẻ THỬ THÁCH (`challenge_card()` = null) — bảng Tiến Độ
## chiếm trọn bề ngang bên phải như mockup.
## ============================================================================

## Bề rộng gốc của thanh tiến độ (khớp card_stroke_slider_track.svg 410×14)
const SLIDER_WIDTH := 205


func _on_update(ctx: Dictionary) -> void:
	var mode := ctx.get("mode", null) as OneStrokeGameMode
	if mode == null:
		return
	var total := maxi(mode.total_cells(), 1)
	var done := mode.visited_count()

	set_label_text(get_node_or_null("Sheet/Cover/CoverValue"), str(done))
	set_label_text(get_node_or_null("Sheet/Cover/CoverMax"),
		tr("STR_HUD_OS_COVER_MAX").format([total]))

	var note := get_node_or_null("Sheet/Cover/CoverNote") as Label
	if note != null:
		note.text = tr("STR_HUD_OS_COVER_NOTE").format([maxi(total - done, 0)])

	var chip := get_node_or_null("Sheet/Row1/ChipLabel") as Label
	if chip != null:
		var percent := int(round(100.0 * float(done) / float(total)))
		chip.text = tr("STR_HUD_OS_CHIP").format([percent])

	# Thanh tiến độ: node cha cắt bớt phần đã phủ (không co giãn texture)
	var fill_clip := get_node_or_null("Sheet/Row2/SliderFillClip") as Control
	if fill_clip != null:
		var ratio := clampf(float(done) / float(total), 0.0, 1.0)
		fill_clip.size = Vector2(SLIDER_WIDTH * ratio, fill_clip.size.y)
