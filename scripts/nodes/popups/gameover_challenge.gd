class_name GameOverChallengePopup
extends GameOverLevelPopup
## ============================================================================
## Popup: THUA VÌ THỬ THÁCH (nodes/popups/gameover_challenge.tscn)
## — bản sao layout popup thua màn (gameover_level.tscn):
##   · Tiêu đề riêng "THỬ THÁCH THẤT BẠI"
##   · Dòng phụ = "<TÊN LUẬT> · <LÝ DO VI PHẠM>" (theo `reason` = "challenge_*")
##   · Nút HỒI SINH bị GỠ (thử thách không hồi sinh — vi phạm là thua)
## Dữ liệu nhận qua open({ ..., reason: "challenge_timeout", challenge_name_key })
## ============================================================================

## Nút HỒI SINH của layout gốc — ẩn trong bản thử thách
@export var btn_revive: BaseButton = null


func _on_open() -> void:
	super._on_open()
	var name_key := str(data.get("challenge_name_key", ""))
	var fail_text := tr(ChallengeGameMode.fail_key(str(data.get("reason", ""))))
	if label_title != null:
		label_title.text = tr("STR_CHALLENGE_FAIL_TITLE")
	if label_subtitle != null:
		label_subtitle.text = fail_text if name_key.is_empty() \
			else "%s · %s" % [tr(name_key), fail_text]
	if revive_desc != null and not name_key.is_empty():
		revive_desc.text = tr("STR_CHALLENGE_RULE_LINE").format([tr(name_key)])
	if btn_revive != null:
		btn_revive.visible = false
