class_name GameOverChallengePopup
extends BasePopup
## ============================================================================
## Popup: THUA VÌ THỬ THÁCH (scenes/objects/ui/popups/gameover_challenge.tscn)
## Cùng họ với popup thua màn / qua tầng: trang sổ + băng washi đỏ + kẹp giấy.
##   · Băng đỏ: "THỬ THÁCH THẤT BẠI!"
##   · Trái: TÊN LUẬT (to) + LÝ DO vi phạm (đỏ) · Phải: con dấu "NHIỆM VỤ x / 3"
##   · Thẻ checklist 3 nhiệm vụ của màn (đạt = ✔ xanh, chưa đạt = ô trống)
##   · Nút: Về Menu (xám) · Chơi lại (xanh) — KHÔNG có hồi sinh (vi phạm là thua)
## Dữ liệu: open({ reason: "challenge_*", challenge_name_key, missions:[{title,done}], guided })
## Lượt (bút) đã bị trừ TRƯỚC khi popup mở (UIController._charge_life_cost);
## popup chỉ chặn "Chơi lại" khi hết bút.
## ============================================================================

## Scene contract
## Exports:  COUNT, check_on, check_off, label_title, label_rule, label_reason, stamp_count, row1_check, row1_name, row2_check, row2_name, row3_check, row3_name, btn_menu, btn_retry
## Emits:    retry_requested, menu_requested, revive_requested
## Handlers wired in scene: _on_menu_pressed, _on_retry_pressed
## Subscribes in code (EventBus/Model): (none)

signal retry_requested
signal menu_requested
## ĐÃ BỎ (thử thách không hồi sinh). Giữ khai báo, KHÔNG BAO GIỜ phát, để
## UIController.show_direct_game_over còn `has_signal` an toàn. Xoá khi dọn code.
signal revive_requested

@export var COUNT := 3
@export var check_on: Texture2D = null
@export var check_off: Texture2D = null

@export var label_title: Label = null
@export var label_rule: Label = null
@export var label_reason: Label = null
@export var stamp_count: Label = null
@export var row1_check: TextureRect = null
@export var row1_name: Label = null
@export var row2_check: TextureRect = null
@export var row2_name: Label = null
@export var row3_check: TextureRect = null
@export var row3_name: Label = null
@export var btn_menu: BaseButton = null
@export var btn_retry: BaseButton = null

const COLOR_OK := Color("224C6D")  # keep-code: màu theo dữ liệu runtime (đạt / chưa đạt)
const COLOR_FAIL := Color("7A8794")  # keep-code: màu theo dữ liệu runtime (đạt / chưa đạt)
const COLOR_DIM := Color(0.72, 0.72, 0.72, 1.0)  # keep-code: làm mờ nút Chơi lại khi hết bút


func _on_open() -> void:
	var name_key := str(data.get("challenge_name_key", ""))
	label_title.text = tr("STR_CHALLENGE_FAIL_TITLE")
	label_reason.text = tr(ChallengeGameMode.fail_key(str(data.get("reason", ""))))
	label_rule.text = "" if name_key.is_empty() else tr(name_key)

	var rows: Array = data.get("missions", [])
	var checks: Array[TextureRect] = [row1_check, row2_check, row3_check]
	var names: Array[Label] = [row1_name, row2_name, row3_name]
	var done_count := 0
	for i in COUNT:
		var row: Dictionary = rows[i] if i < rows.size() else {}
		var ok := bool(row.get("done", false))
		done_count += 1 if ok else 0
		checks[i].texture = check_on if ok else check_off
		if row.has("title"):
			names[i].text = str(row.get("title"))
		names[i].add_theme_color_override("font_color", COLOR_OK if ok else COLOR_FAIL)  # EXCEPTION(R2-runtime-style): style tính từ dữ liệu runtime
	stamp_count.text = "%d / %d" % [done_count, COUNT]

	# Luồng học lần đầu: không cho "Về Menu"
	btn_menu.visible = not bool(data.get("guided", false))
	btn_retry.modulate = Color.WHITE if _can_play() else COLOR_DIM


# ---------------------------------------------------------------------------
# Lượt chơi (đọc từ GameManager) — khớp GameOverLevelPopup
# ---------------------------------------------------------------------------
func _will_charge_life() -> bool:
	if bool(data.get("guided", false)):
		return false
	var gm := Svc.game()
	return not (gm != null and bool(gm.get("debug_run")))


func _can_play() -> bool:
	if not _will_charge_life():
		return true
	var gm := Svc.game()
	if gm != null and gm.has_method("can_start_run"):
		return bool(gm.call("can_start_run"))
	return true


func _on_retry_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	if not _can_play():
		var gm := Svc.game()
		if gm != null and gm.has_method("open_out_of_life_popup"):
			gm.call("open_out_of_life_popup")
		return
	retry_requested.emit()
	close()


func _on_menu_pressed() -> void:
	Sfx.play(Sfx.BTN_WOOD_TAP)
	menu_requested.emit()
	close()
