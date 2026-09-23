class_name FogOfWarHUD
extends BaseHUD
## ============================================================================
## HUD Fog of War — mockup/matchup_fog_of_war.svg
##
## THỜI GIAN (250×156) + "BẢNG SƯƠNG MÙ" (690×156):
##   ❤️ LƯỢT THỬ LẠI "n/3" (đỏ) + dòng "CÒN n LẦN VỀ S" (xanh · đỏ khi còn ≤ 1) ·
##   hàng TẦM NHÌN bán kính 1 ô (chip XUNG QUANH) + 2 dòng cảnh báo luật chơi.
##
## Luật (xem `FogOfWarGameMode`): đâm tường vô hình -> về ô S và TRỪ 1 LƯỢT THỬ;
## hết 3 lượt là thua. Hồi sinh bằng quảng cáo -> cộng thêm 1 lượt thử.
## Chế độ này KHÔNG hiện thẻ THỬ THÁCH (`challenge_card()` = null) — bảng Sương Mù
## chiếm trọn bề ngang bên phải như mockup.
## ============================================================================

## Màu dòng "CÒN n LẦN VỀ S": xanh khi còn nhiều, đỏ khi chỉ còn ≤ 1 lượt
const COLOR_NOTE_OK := Color(0.18039216, 0.49019608, 0.19607843)
const COLOR_NOTE_DANGER := Color(0.84705883, 0.26666668, 0.26666668)


func _on_update(ctx: Dictionary) -> void:
	var mode := ctx.get("mode", null) as FogOfWarGameMode
	if mode == null:
		return
	var left := mode.retries_left
	set_label_text(get_node_or_null("Content/ModeInformation/Sheet/Retry/Value"), str(left))
	set_label_text(get_node_or_null("Content/ModeInformation/Sheet/Retry/Max"), "/%d" % maxi(mode.max_retries, 0))
	var note := get_node_or_null("Content/ModeInformation/Sheet/Retry/Note") as Label
	if note != null:
		note.text = tr("STR_HUD_FOG_RETRY_NOTE").format([left])
		note.add_theme_color_override("font_color",
			COLOR_NOTE_DANGER if left <= 1 else COLOR_NOTE_OK)
