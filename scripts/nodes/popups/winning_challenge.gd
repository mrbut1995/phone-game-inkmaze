class_name WinningChallengePopup
extends WinningPopup
## ============================================================================
## Popup: HOÀN THÀNH THỬ THÁCH (nodes/popups/winning_challenge.tscn)
## — bản sao layout popup thắng màn (winning.tscn), đổi dòng phụ đề thành
##   "THỬ THÁCH HOÀN THÀNH · <TÊN LUẬT>" + con dấu "THỬ THÁCH".
## Dữ liệu nhận qua open({ ..., challenge_id, challenge_name_key })
## ============================================================================


func _on_open() -> void:
	super._on_open()
	if data.is_empty():
		return
	var name_key := str(data.get("challenge_name_key", ""))
	if label_subtitle != null and not name_key.is_empty():
		label_subtitle.text = tr("STR_CHALLENGE_WIN_SUBTITLE").format([tr(name_key)])
	if stamp_title != null:
		stamp_title.text = tr("STR_CHALLENGE_STAMP_TITLE")
