class_name WinningChallengePopup
extends WinningPopup
## ============================================================================
## Popup: HOÀN THÀNH THỬ THÁCH (nodes/popups/winning_challenge.tscn)
## — cùng bố cục với winning.tscn (kế thừa WinningPopup), khác:
##   · tiêu đề băng dính "HOÀN THÀNH THỬ THÁCH", dòng lớn = TÊN LUẬT thay cho "MÀN n"
##   · nút chính là "TRỞ VỀ" (quay lại MÀN TRƯỚC ĐÓ — xem `_on_back_requested` bên GameController),
##     KHÔNG phải "MÀN KẾ TIẾP"
## Dữ liệu nhận qua open({ ..., challenge_id, challenge_name_key })
## ============================================================================

## Bấm "TRỞ VỀ" — UIController nối signal này tới GameController._on_back_requested
signal back_requested

## Tên luật dài hơn "MÀN 12" -> thu cỡ chữ cho vừa thẻ
const NAME_FONT_SIZE := 24
const NAME_FONT_SIZE_LONG := 18
const LONG_NAME_CHARS := 16


func _on_open() -> void:
	super._on_open()
	if data.is_empty():
		return
	var name_key := str(data.get("challenge_name_key", ""))
	if label_level != null and not name_key.is_empty():
		var text := tr(name_key)
		label_level.text = text
		label_level.add_theme_font_size_override(&"font_size",
			NAME_FONT_SIZE_LONG if text.length() > LONG_NAME_CHARS else NAME_FONT_SIZE)
		label_level.clip_text = true
		label_level.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	# Nút chính (BackBtn): "TRỞ VỀ" thay cho "MÀN KẾ TIẾP" — dây bấm khai trong .tscn
	if label_next != null:
		label_next.text = tr("STR_BTN_BACK_PREV")


## Bấm nút chính "TRỞ VỀ": đóng popup + báo về màn trước đó
func _on_back_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	back_requested.emit()
	close()
