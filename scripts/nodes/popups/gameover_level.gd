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
const STAR_FULL := preload("res://assets/images-png/common/star_highlight.png")
const STAR_EMPTY := preload("res://assets/images-png/common/star_empty.png")

const VAR_STATUS_OK := &"PopupStatValueSmGood"
const VAR_STATUS_FAIL := &"PopupStatValueBad"

## Node binding: khai `node_paths` + `NodePath` trong `gameover_level.tscn`
@export var label_title: Label = null
@export var label_subtitle: Label = null
@export var revive_desc: Label = null
@export var stamp_count: Label = null
@export var challenge_count: Label = null
## Nút "Về Menu" — ẩn trong LUỒNG HỌC LẦN ĐẦU (xem `_on_open`)
@export var btn_menu: BaseButton = null
## 3 hàng thử thách cố định theo thiết kế (Row1/2/3 — Star/Name/Status)
@export var row1_star: TextureRect = null
@export var row1_name: Label = null
@export var row1_status: Label = null
@export var row2_star: TextureRect = null
@export var row2_name: Label = null
@export var row2_status: Label = null
@export var row3_star: TextureRect = null
@export var row3_name: Label = null
@export var row3_status: Label = null


func _on_open() -> void:
	# Tiêu đề riêng theo LÝ DO thua: hết đường (Fading Ink / One Stroke) · đi lại ô cũ
	# (One Stroke) · hết LƯỢT GỬI (Wall Builder)
	var reason := str(data.get("reason", ""))
	if reason == "dead_end" or reason == "revisit" or reason == "out_of_submits":
		match reason:
			"dead_end":
				label_title.text = "STR_GAME_OVER_NO_PATH"
			"revisit":
				label_title.text = "STR_GAME_OVER_REVISIT"
			_:
				label_title.text = "STR_GAME_OVER_OUT_OF_SUBMITS"

	label_subtitle.text = tr("STR_GAME_OVER_LEVEL_SUBTITLE").format([int(data.get("progress", 0))])

	# Chế độ có LƯỢT THỬ LẠI (Fog of War) hoặc LƯỢT GỬI (Wall Builder): nút HỒI SINH
	# cộng thêm 1 lượt — dòng mô tả lấy theo khoá riêng của chế độ nếu có.
	var desc_key := str(data.get("revive_desc", ""))
	if not desc_key.is_empty():
		revive_desc.text = tr(desc_key)
	elif int(data.get("max_retries", 0)) > 0:
		revive_desc.text = tr("STR_REVIVE_DESC_RETRY")

	var rows: Array = data.get("challenges", [])
	# Gom node ĐÃ BIND của 3 hàng (theo thiết kế cố định) — không dò "Row%d/..." lúc chạy
	var stars: Array[TextureRect] = [row1_star, row2_star, row3_star]
	var names: Array[Label] = [row1_name, row2_name, row3_name]
	var statuses: Array[Label] = [row1_status, row2_status, row3_status]
	var done := 0
	for i in COUNT:
		var row: Dictionary = rows[i] if i < rows.size() else {}
		var ok := bool(row.get("done", false))
		if ok:
			done += 1
		stars[i].texture = STAR_FULL if ok else STAR_EMPTY
		if row.has("title"):
			names[i].text = str(row.get("title"))
		statuses[i].text = str(row.get("status", tr("STR_CHALLENGE_NOT_DONE")))
		statuses[i].theme_type_variation = VAR_STATUS_OK if ok else VAR_STATUS_FAIL

	var count_text := tr("STR_CHALLENGE_COUNT_FORMAT").format([done, COUNT])
	stamp_count.text = count_text
	challenge_count.text = count_text

	# LUỒNG HỌC LẦN ĐẦU (onboarding): KHÔNG cho "Về Menu" (rời luồng giữa chừng) — vẫn giữ
	# HỒI SINH + THỬ LẠI để chơi tiếp đúng màn của luồng.
	if btn_menu != null:
		btn_menu.visible = not bool(data.get("guided", false))

	# Dây 3 nút (Hồi sinh / Menu / Thử lại) khai trong `gameover_level.tscn` (cùng scene)


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
