class_name GameOverLevelPopup
extends BasePopup
## ============================================================================
## Popup: Thua cuộc ở Play / Level Mode (nodes/popups/gameover_level.tscn)
## Bố cục "BẢN ĐỒ ĐƯỜNG ĐI":
##   1. Thẻ đường đi : đoạn đã đi / còn lại + % hoàn thành + thời gian · số lần đâm
##   2. 3 thẻ nhiệm vụ : sao đầy/rỗng + tên
##   3. Thẻ bút chì   : hàng bút (bút vừa gãy có nhãn −1) + "n/max" + đếm ngược hồi bút
##   4. Nút: Về Menu (xám) · Chơi lại (xanh)
##
## HỒI SINH đã chuyển sang popup Retry (hiện trước popup này) -> KHÔNG còn ở đây.
## Lượt (bút) đã bị trừ TRƯỚC khi popup này mở (UIController._charge_life_cost).
## Popup chỉ HIỂN THỊ + chặn "Chơi lại" khi hết bút.
##
## Dữ liệu: open({ progress, wall_hits, time, stars, missions:[{title,done}], guided, reason })
## ============================================================================

signal retry_requested
signal menu_requested
## ĐÃ BỎ (Hồi sinh nằm ở popup Retry). Giữ khai báo, KHÔNG BAO GIỜ phát, để các
## nơi cũ còn `connect(...revive_requested...)` không lỗi. Xoá khi dọn code.
signal revive_requested

@export var COUNT := 3
@export var star_full: Texture2D = null
@export var star_empty: Texture2D = null

const COLOR_MISSION_OK := Color("B07A0A")
const COLOR_MISSION_FAIL := Color("7A8794")

@export var label_title: Label = null
@export var path: GameOverPath = null
@export var label_percent: Label = null
@export var label_walked: Label = null
@export var label_stats: Label = null
@export var label_count: Label = null
@export var pencils: RetryPencils = null
@export var btn_menu: BaseButton = null
@export var btn_retry: BaseButton = null
@export var row1_star: TextureRect = null
@export var row1_name: Label = null
@export var row2_star: TextureRect = null
@export var row2_name: Label = null
@export var row3_star: TextureRect = null
@export var row3_name: Label = null

var _charged := false


func _on_open() -> void:
	# Tiêu đề riêng theo LÝ DO thua (giữ như bản cũ).
	# ⚠️ Mọi khối dưới đây đều PHẢI chịu được node null: `gameover_challenge.tscn` giữ layout
	# CŨ (Subtitle + Banner hồi sinh, không có thẻ đường đi / bút chì) nhưng vẫn kế thừa hàm này.
	if label_title != null:
		match str(data.get("reason", "")):
			"dead_end":
				label_title.text = tr("STR_GAME_OVER_NO_PATH")
			"revisit":
				label_title.text = tr("STR_GAME_OVER_REVISIT")
			"out_of_submits":
				label_title.text = tr("STR_GAME_OVER_OUT_OF_SUBMITS")

	# 1. Đường đi (chỉ popup có layout "BẢN ĐỒ ĐƯỜNG ĐI")
	if path != null:
		var progress := clampi(int(data.get("progress", 0)), 0, 100)
		path.set_progress(progress / 100.0)
		if label_percent != null:
			label_percent.text = "%d%%" % progress
		if label_walked != null:
			label_walked.text = tr("STR_GO_WALKED")
		if label_stats != null:
			label_stats.text = tr("STR_GO_STATS").format([
				_format_time(data.get("time", 0)), int(data.get("wall_hits", 0))])

	# 2. Nhiệm vụ
	var rows: Array = data.get("missions", [])
	var stars: Array[TextureRect] = [row1_star, row2_star, row3_star]
	var names: Array[Label] = [row1_name, row2_name, row3_name]
	for i in COUNT:
		var row: Dictionary = rows[i] if i < rows.size() else {}
		var ok := bool(row.get("done", false))
		if stars[i] != null:
			stars[i].texture = star_full if ok else star_empty
		if names[i] == null:
			continue
		if row.has("title"):
			names[i].text = str(row.get("title"))
		names[i].add_theme_color_override("font_color", COLOR_MISSION_OK if ok else COLOR_MISSION_FAIL)

	# 3. Bút (chỉ popup có thẻ bút chì)
	_charged = _will_charge_life()
	_connect_life_signal()
	if pencils != null:
		_refresh_pencils()

	# 4. Luồng học lần đầu: không cho "Về Menu"
	if btn_menu != null:
		btn_menu.visible = not bool(data.get("guided", false))


func _on_close() -> void:
	var gm := _game_manager()
	if gm != null and gm.has_signal("life_changed") \
			and gm.is_connected("life_changed", _on_life_changed):
		gm.disconnect("life_changed", _on_life_changed)


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
	if pencils == null:
		return
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
	if label_count != null:
		label_count.text = "%d/%d" % [lives, maximum]
	if not pencils.recover_finished.is_connected(_refresh_pencils):
		pencils.recover_finished.connect(_refresh_pencils, CONNECT_DEFERRED)
	# Hết bút: làm mờ nút Chơi lại (bấm vẫn mở popup Hết bút)
	if btn_retry != null:
		btn_retry.modulate = Color.WHITE if _can_play() else Color(0.72, 0.72, 0.72, 1.0)


## 84 -> "01:24". Chấp nhận số giây (int/float) hoặc chuỗi đã định dạng sẵn.
func _format_time(value: Variant) -> String:
	if value is String:
		return value
	var total := int(value)
	return "%02d:%02d" % [total / 60, total % 60]


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
