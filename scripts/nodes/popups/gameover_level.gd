class_name GameOverLevelPopup
extends BasePopup
## ============================================================================
## Popup: Thua cuộc ở Play / Level Mode (nodes/popups/gameover_level.tscn)
## — mockup popup_game_over_level.svg
##
## Khác bản Dungeon (nodes/popups/gameover.tscn):
##   - Thay "Quãng đường đã đi / Va chạm tường / Điểm an ủi" bằng DANH SÁCH 3 THỬ THÁCH
##     kèm trạng thái ĐẠT / CHƯA ĐẠT.
##   - Con dấu (stamp) in SỐ THỬ THÁCH ĐÃ HOÀN THÀNH (thay cho "hết bước" của bản Dungeon).
##   - Nút HỒI SINH = "Quay lại bước trước đó" (Design.md 5.10).
##
## Dữ liệu: open({ floor, progress, wall_hits, score, stars, challenges: [ {title,done,status} ] })
## ============================================================================

signal retry_requested
signal menu_requested
signal revive_requested

const COUNT := 3
const STAR_FULL := preload("res://assets/images/common/star_highlight.svg")
const STAR_EMPTY := preload("res://assets/images/common/star_empty.svg")

const VAR_STATUS_OK := &"PopupStatValueSmGood"
const VAR_STATUS_FAIL := &"PopupStatValueBad"


func _on_open() -> void:
	# Tiêu đề riêng theo LÝ DO thua: hết đường (Fading Ink / One Stroke) · đi lại ô cũ
	# (One Stroke) · hết LƯỢT GỬI (Wall Builder)
	var reason := str(data.get("reason", ""))
	if reason == "dead_end" or reason == "revisit" or reason == "out_of_submits":
		var title_node := piece("Title") as Label
		if title_node != null:
			match reason:
				"dead_end":
					title_node.text = "STR_GAME_OVER_NO_PATH"
				"revisit":
					title_node.text = "STR_GAME_OVER_REVISIT"
				_:
					title_node.text = "STR_GAME_OVER_OUT_OF_SUBMITS"

	var subtitle := piece("Subtitle") as Label
	if subtitle != null:
		subtitle.text = tr("STR_GAME_OVER_LEVEL_SUBTITLE").format([int(data.get("progress", 0))])

	# Chế độ có LƯỢT THỬ LẠI (Fog of War) hoặc LƯỢT GỬI (Wall Builder): nút HỒI SINH
	# cộng thêm 1 lượt — dòng mô tả lấy theo khoá riêng của chế độ nếu có.
	var revive_desc := piece("Banner/Desc") as Label
	if revive_desc != null:
		var desc_key := str(data.get("revive_desc", ""))
		if not desc_key.is_empty():
			revive_desc.text = tr(desc_key)
		elif int(data.get("max_retries", 0)) > 0:
			revive_desc.text = tr("STR_REVIVE_DESC_RETRY")

	var rows: Array = data.get("challenges", [])
	var done := 0
	for i in COUNT:
		var row: Dictionary = rows[i] if i < rows.size() else {}
		var ok := bool(row.get("done", false))
		if ok:
			done += 1

		var star := piece("Row%d/Star" % (i + 1)) as TextureRect
		if star != null:
			star.texture = STAR_FULL if ok else STAR_EMPTY

		var title := piece("Row%d/Name" % (i + 1)) as Label
		if title != null and row.has("title"):
			title.text = str(row.get("title"))

		var status := piece("Row%d/Status" % (i + 1)) as Label
		if status != null:
			status.text = str(row.get("status", tr("STR_CHALLENGE_NOT_DONE")))
			status.theme_type_variation = VAR_STATUS_OK if ok else VAR_STATUS_FAIL

	var count_text := tr("STR_CHALLENGE_COUNT_FORMAT").format([done, COUNT])
	var stamp_count := piece("StampCount") as Label
	if stamp_count != null:
		stamp_count.text = count_text
	var header_count := piece("ChallengeCount") as Label
	if header_count != null:
		header_count.text = count_text

	bind_button("Panel/Content/Banner/ReviveBtn", _on_revive_pressed)
	bind_button("Panel/Content/MenuBtn", _on_menu_pressed)
	bind_button("Panel/Content/RetryBtn", _on_retry_pressed)


func _on_revive_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	# KHÔNG tự đóng popup: GameController chỉ đóng khi quảng cáo thưởng được chấp nhận
	# (nếu không, người chơi sẽ bị bỏ lại ở màn hình đứng yên vì ván đang ở trạng thái thua).
	revive_requested.emit()


func _on_retry_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	retry_requested.emit()
	close()


func _on_menu_pressed() -> void:
	Sfx.play(Sfx.BTN_WOOD_TAP)
	menu_requested.emit()
	close()
