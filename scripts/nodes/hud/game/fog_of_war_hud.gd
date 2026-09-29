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

## LƯỢT THỬ LẠI còn lại (`Content/ModeInformation/Sheet/Retry/Value`)
@export var retry_value_node : Label
## Tổng lượt thử (`…/Sheet/Retry/Max`)
@export var retry_max_label : Label
## Dòng "CÒN n LẦN VỀ S" (`…/Sheet/Retry/Note`) — đổi màu theo số lượt còn lại
@export var retry_note_label : Label


func _on_update(ctx: Dictionary) -> void:
	var mode := ctx.get("mode", null) as FogOfWarGameMode
	if mode == null:
		return
	var left := mode.retries_left
	set_label_text(retry_value_node, str(left))
	set_label_text(retry_max_label, "/%d" % maxi(mode.max_retries, 0))
	if retry_note_label != null:
		retry_note_label.text = tr("STR_HUD_FOG_RETRY_NOTE").format([left])
		retry_note_label.add_theme_color_override("font_color",
			COLOR_NOTE_DANGER if left <= 1 else COLOR_NOTE_OK)
