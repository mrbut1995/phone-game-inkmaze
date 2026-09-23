class_name WallBuilderHUD
extends BaseHUD
## ============================================================================
## HUD Wall Builder — mockup/matchup_wall_builder.svg
##
## THỜI GIAN (270×156, chip "ĐANG SUY LUẬN") + "BẢNG TƯỜNG ĐÃ VẼ" (690×156):
##   · cột trái : "🧱 ĐÃ DỰNG" + "14/18 ĐOẠN" + "CÒN THIẾU 4 ĐOẠN" (đỏ)
##   · cột phải : hàng "❤️ LƯỢT GỬI: 3 / 3 LẦN" + chip trạng thái
##                (ĐANG NỐI TƯỜNG / ĐỦ TƯỜNG / SẴN SÀNG GỬI)
##                + thanh tiến độ dựng tường + 2 dòng nhắc luật
##
## Luật (xem `WallBuilderGameMode`): đọc số trên ô để nối đủ tường rồi bấm GỬI;
## sai ⇒ mất 1 trong 3 LƯỢT GỬI (hết lượt là thua).
## Chế độ này KHÔNG hiện thẻ THỬ THÁCH (`challenge_card()` = null).
## ============================================================================

## Bề rộng gốc của thanh tiến độ (khớp card_wall_slider_track.svg 400×14)
const SLIDER_WIDTH := 200


func _on_update(ctx: Dictionary) -> void:
	var mode := ctx.get("mode", null) as WallBuilderGameMode
	if mode == null:
		return
	var required := maxi(mode.required_segments, 0)
	var built := mode.built_count()

	set_label_text(get_node_or_null("Sheet/Cover/CoverValue"), str(built))
	set_label_text(get_node_or_null("Sheet/Cover/CoverMax"),
		tr("STR_HUD_WB_COVER_MAX").format([required]))
	set_label_text(get_node_or_null("Sheet/Cover/CoverNote"),
		tr("STR_HUD_WB_COVER_NOTE").format([mode.missing_count()]))
	set_label_text(get_node_or_null("Sheet/Row1/Submit"),
		tr("STR_HUD_WB_SUBMIT").format([mode.retries_left, maxi(mode.max_retries, 0)]))
	set_label_text(get_node_or_null("Sheet/Row1/ChipLabel"),
		tr("STR_HUD_WB_CHIP_%s" % mode.build_state().to_upper()))

	# Thanh tiến độ: node cha cắt bớt phần đã dựng (không co giãn texture)
	var fill_clip := get_node_or_null("Sheet/Row2/SliderFillClip") as Control
	if fill_clip != null:
		var ratio := 0.0 if required <= 0 else clampf(float(built) / float(required), 0.0, 1.0)
		fill_clip.size = Vector2(SLIDER_WIDTH * ratio, fill_clip.size.y)
