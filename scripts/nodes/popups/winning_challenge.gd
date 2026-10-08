class_name WinningChallengePopup
extends WinningPopup
## ============================================================================
## Popup: HOÀN THÀNH THỬ THÁCH (nodes/popups/winning_challenge.tscn)
## — bản sao layout popup thắng màn (winning.tscn), đổi dòng phụ đề thành
##   "THỬ THÁCH HOÀN THÀNH · <TÊN LUẬT>" + con dấu "THỬ THÁCH".
## — Nút chính là "TRỞ VỀ" (quay lại MÀN TRƯỚC ĐÓ — xem `_on_back_requested` bên GameController),
##   KHÔNG phải "MÀN KẾ TIẾP" như popup thắng màn thường.
## Dữ liệu nhận qua open({ ..., challenge_id, challenge_name_key })
## ============================================================================

## Bấm "TRỞ VỀ" — UIController nối signal này tới GameController._on_back_requested
signal back_requested


func _on_open() -> void:
	super._on_open()
	if data.is_empty():
		return
	var name_key := str(data.get("challenge_name_key", ""))
	if label_subtitle != null and not name_key.is_empty():
		label_subtitle.text = tr("STR_CHALLENGE_WIN_SUBTITLE").format([tr(name_key)])
	if stamp_title != null:
		stamp_title.text = tr("STR_CHALLENGE_STAMP_TITLE")
	# Nút chính (BackBtn): "TRỞ VỀ" thay cho "MÀN KẾ TIẾP" — dây bấm khai trong .tscn
	if label_next != null:
		label_next.text = tr("STR_BTN_BACK_PREV")


## Bấm nút chính "TRỞ VỀ": đóng popup + báo về màn trước đó
func _on_back_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	back_requested.emit()
	close()
