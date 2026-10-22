class_name GameOverPopup
extends BasePopup
## ============================================================================
## Popup: Thua cuộc ở DUNGEON (nodes/popups/gameover.tscn)
## Bố cục:
##   1. Đầu: "Bạn thua ở TẦNG n" + nhãn lý do + dòng gợi ý kỷ lục
##   2. Thước kỷ lục (GameOverRuler): tầng vừa thua · kỷ lục TUẦN · kỷ lục THÁNG
##   3. Thẻ 3 cột: Đã đi trong tầng · Đâm tường · Điểm
##   4. Thẻ bút chì (bút vừa gãy có nhãn −1) + đếm ngược hồi bút
##   5. Nút: Về Menu · Chơi lại
##
## HỒI SINH đã chuyển sang popup Retry (hiện trước popup này) -> KHÔNG còn ở đây.
## Lượt (bút) đã bị trừ TRƯỚC khi popup này mở (UIController._charge_life_cost).
## Dữ liệu: open({ floor, progress, wall_hits, score, steps_left, steps_max,
##                 best_floor_week?, best_floor_month?, guided? })
## ============================================================================

signal retry_requested
signal menu_requested
## ĐÃ BỎ (Hồi sinh nằm ở popup Retry). Giữ khai báo, KHÔNG BAO GIỜ phát, để các
## nơi cũ còn `connect(...revive_requested...)` không lỗi. Xoá khi dọn code.
signal revive_requested

## Node binding: khai `node_paths` + `NodePath` trong `gameover.tscn`
@export var label_floor: Label = null
@export var label_reason: Label = null
@export var label_hint: Label = null
@export var ruler: GameOverRuler = null
@export var value_progress: Label = null
@export var value_walls: Label = null
@export var value_score: Label = null
@export var pencils: RetryPencils = null
@export var label_count: Label = null
@export var btn_menu: BaseButton = null
@export var btn_retry: BaseButton = null

var _charged := false


func _on_open() -> void:
	var floor_no := maxi(int(data.get("floor", 1)), 1)
	var progress := clampi(int(round(float(data.get("progress", 0.0)))), 0, 100)
	label_floor.text = tr("STR_GO_FLOOR").format([floor_no])
	label_reason.text = tr("STR_GO_REASON_STEPS")
	value_progress.text = "%d%%" % progress
	value_walls.text = str(int(data.get("wall_hits", 0)))
	value_score.text = _fmt_int(int(data.get("score", 0)))

	# Kỷ lục: ưu tiên số trong `data`, thiếu thì hỏi GameManager (đã gồm cả tầng vừa thua)
	var week := _record("week")
	var month := _record("month")
	ruler.set_data(floor_no, week, month, tr("STR_GO_YOU"), tr("STR_GO_WEEK"), tr("STR_GO_MONTH"))
	_refresh_hint(floor_no, week, month)

	# Bút
	_charged = _will_charge_life()
	_connect_life_signal()
	_refresh_pencils()

	if btn_menu != null:
		btn_menu.visible = not bool(data.get("guided", false))


func _on_close() -> void:
	var gm := _game_manager()
	if gm != null and gm.has_signal("life_changed") \
			and gm.is_connected("life_changed", _on_life_changed):
		gm.disconnect("life_changed", _on_life_changed)


# ---------------------------------------------------------------------------
# Kỷ lục
# ---------------------------------------------------------------------------
func _record(kind: String) -> int:
	var best := int(data.get("best_floor_%s" % kind, -1))
	if best >= 0:
		return best
	var gm := _game_manager()
	if gm != null and gm.has_method("best_floor"):
		return int(gm.call("best_floor", kind))
	return 0


## Dòng gợi ý dưới nhãn lý do. Kỷ lục được ghi ngay khi VÀO tầng, nên best >= tầng thua:
## best == tầng thua nghĩa là bạn đang giữ kỷ lục kỳ đó.
func _refresh_hint(floor_no: int, week: int, month: int) -> void:
	if label_hint == null:
		return
	if month <= 0:
		label_hint.text = ""
		label_hint.visible = false
		return
	label_hint.visible = true
	if floor_no >= month:
		label_hint.text = tr("STR_GO_REC_MONTH_HOLD")
	elif week > 0 and floor_no >= week:
		label_hint.text = tr("STR_GO_REC_WEEK_HOLD").format([month - floor_no])
	else:
		label_hint.text = tr("STR_GO_REC_REMAIN").format([month - floor_no])


## 1240 -> "1.240"
static func _fmt_int(value: int) -> String:
	var s := str(absi(value))
	var out := ""
	for i in s.length():
		if i > 0 and (s.length() - i) % 3 == 0:
			out += "."
		out += s[i]
	return ("-" if value < 0 else "") + out


# ---------------------------------------------------------------------------
# Bút chì (đọc từ GameManager)
# ---------------------------------------------------------------------------
func _game_manager() -> Node:
	return get_node_or_null("/root/GameManager")


## Ván này có bị trừ bút không? Khớp UIController._charge_life_cost (guided / debug_run miễn).
func _will_charge_life() -> bool:
	if bool(data.get("guided", false)):
		return false
	var gm := _game_manager()
	if gm != null and bool(gm.get("debug_run")):
		return false
	return true


func _connect_life_signal() -> void:
	var gm := _game_manager()
	if gm != null and gm.has_signal("life_changed") \
			and not gm.is_connected("life_changed", _on_life_changed):
		gm.connect("life_changed", _on_life_changed)


func _on_life_changed(_lives: int, _max: int) -> void:
	_refresh_pencils()


func _can_play() -> bool:
	if not _will_charge_life():
		return true
	var gm := _game_manager()
	if gm != null and gm.has_method("can_start_run"):
		return bool(gm.call("can_start_run"))
	return true


func _refresh_pencils() -> void:
	var gm := _game_manager()
	var lives := 0
	var maximum := 5
	var next_unix := 0.0
	if gm != null:
		if gm.has_method("lives_left"):
			lives = int(gm.call("lives_left"))
		if gm.has_method("max_lives"):
			maximum = int(gm.call("max_lives"))
		if gm.has_method("seconds_to_next_life"):
			var wait := int(gm.call("seconds_to_next_life"))
			if wait > 0:
				next_unix = Time.get_unix_time_from_system() + float(wait)
	# Bút vừa gãy = ô trống đầu tiên (đã bị trừ trước khi popup mở)
	var lost := lives if _charged else -1
	pencils.set_state(lives, maximum, next_unix, false, lost)
	label_count.text = "%d/%d" % [lives, maximum]
	if not pencils.recover_finished.is_connected(_refresh_pencils):
		pencils.recover_finished.connect(_refresh_pencils, CONNECT_DEFERRED)
	if btn_retry != null:
		btn_retry.modulate = Color.WHITE if _can_play() else Color(0.72, 0.72, 0.72, 1.0)


# ---------------------------------------------------------------------------
# Nút bấm
# ---------------------------------------------------------------------------
func _on_retry_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	# GameController._on_retry_requested KHÔNG kiểm tra bút -> chặn ở đây
	if not _can_play():
		var gm := _game_manager()
		if gm != null and gm.has_method("open_out_of_life_popup"):
			gm.call("open_out_of_life_popup")
		return
	retry_requested.emit()
	close()


func _on_menu_pressed() -> void:
	Sfx.play(Sfx.BTN_WOOD_TAP)
	menu_requested.emit()
	close()
