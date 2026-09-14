class_name ChallengeController
extends Node
## ============================================================================
## Controller: 3 Thử thách (Challenge) của mỗi màn/tầng — nguồn tính Sao.
##
## LUẬT (Number_Maze_Game_Design.md — mục 3.1 & 5.10):
##   - Mỗi match-up (Màn ở Play Mode / Tầng ở Dungeon Mode / ngày Daily) có ĐÚNG 3 Thử thách.
##   - Hoàn thành 1 Thử thách = 1 Sao (tối đa 3 Sao). Sao KHÔNG tính theo thời gian còn lại.
##
## 3 thử thách chuẩn được suy ra từ dữ liệu màn (không cần dữ liệu riêng cho từng màn):
##   1. Không đâm vào tường vô hình.
##   2. Đi không quá N bước  (N = số bước thiết kế của màn/tầng).
##   3. Về đích dưới T giây   (T = N × 3 giây, kẹp trong 30..240 giây).
##
## HUD: panel "THỬ THÁCH" (Information/Challenge trong scenes/game.tscn) hiển thị trạng thái sống.
## Popup thua/kết quả lấy dữ liệu qua rows() (danh sách thử thách) và stars() (số Sao).
## ============================================================================

signal updated

const COUNT := 3
const SECONDS_PER_STEP := 3.0
const MIN_TIME_LIMIT := 30.0
const MAX_TIME_LIMIT := 240.0

const TYPE_NO_WALL := "no_wall"
const TYPE_STEPS := "steps"
const TYPE_TIME := "time"

const STAR_FULL := preload("res://assets/images/common/star_highlight.svg")
const STAR_EMPTY := preload("res://assets/images/common/star_empty.svg")

const COLOR_DONE := Color(0.18039216, 0.49019608, 0.19607843, 1)
const COLOR_FAIL := Color(0.84705883, 0.26666668, 0.26666668, 1)
const COLOR_LIVE := Color(0.70980394, 0.38431373, 0.101960786, 1)
const COLOR_IDLE := Color(0.44313726, 0.54509807, 0.61960787, 1)
const COLOR_NAME := Color(0.13333334, 0.29803923, 0.42745098, 1)

## Thẻ THỬ THÁCH trên HUD (Information/Challenge) — gán trong scenes/game.tscn
@export var card: Control = null

## Ngưỡng của màn/tầng đang chơi
var step_limit := 0
var time_limit := 0.0

var _rows: Array[Dictionary] = []
## Khoá trạng thái lần vẽ trước (tránh format chuỗi lại mỗi frame)
var _last_key := ""


func _ready() -> void:
	setup_for_floor(0)
	refresh(null, 0.0)


## Gọi khi bắt đầu màn/tầng: chốt ngưỡng 3 thử thách.
func setup_for_floor(design_steps: int) -> void:
	step_limit = maxi(design_steps, 1)
	time_limit = clampf(float(step_limit) * SECONDS_PER_STEP, MIN_TIME_LIMIT, MAX_TIME_LIMIT)

	_rows = [
		{
			"type": TYPE_NO_WALL,
			"title": tr("STR_CHALLENGE_NO_WALL"),
			"done": false,
			"status": tr("STR_CHALLENGE_NOT_DONE"),
			"status_color": COLOR_FAIL,
		},
		{
			"type": TYPE_STEPS,
			"title": tr("STR_CHALLENGE_STEPS").format([step_limit]),
			"done": false,
			"status": tr("STR_CHALLENGE_STEPS_PROGRESS").format([0, step_limit]),
			"status_color": COLOR_LIVE,
		},
		{
			"type": TYPE_TIME,
			"title": tr("STR_CHALLENGE_TIME").format([int(time_limit)]),
			"done": false,
			"status": tr("STR_CHALLENGE_TIME_LEFT").format([int(time_limit)]),
			"status_color": COLOR_LIVE,
		},
	]
	_last_key = ""
	_refresh_hud()


## Cập nhật trạng thái 3 thử thách theo số liệu ván đang chơi.
## `final = true` khi màn/tầng đã kết thúc -> chốt ĐẠT/CHƯA ĐẠT để tính Sao cho popup.
func refresh(state: GameState, floor_elapsed: float, final := false) -> void:
	if _rows.size() < COUNT:
		setup_for_floor(step_limit)
	if state == null:
		return

	var hits := state.floor_wall_hits
	var moves := state.floor_moves
	var seconds := maxf(floor_elapsed, 0.0)

	# Chỉ tính lại khi số liệu đổi (refresh được gọi mỗi frame từ GameController)
	var key := "%d|%d|%d|%s" % [hits, moves, int(seconds), final]
	if key == _last_key:
		return
	_last_key = key

	# 1. Không đâm vào tường vô hình
	var no_wall := hits == 0
	_set_row(0, no_wall, _pass_fail(no_wall))

	# 2. Đi không quá N bước (lúc đang chơi chỉ hiện tiến độ, chưa chốt Sao)
	var steps_ok := moves <= step_limit
	if final:
		_set_row(1, steps_ok, _pass_fail(steps_ok))
	else:
		_set_row(
			1,
			false,
			tr("STR_CHALLENGE_STEPS_PROGRESS").format([moves, step_limit]),
			COLOR_LIVE if steps_ok else COLOR_FAIL
		)

	# 3. Về đích dưới T giây (lúc đang chơi hiện thời gian còn lại)
	var time_ok := seconds <= time_limit
	if final:
		_set_row(2, time_ok, _pass_fail(time_ok))
	else:
		var left := time_limit - seconds
		var text := tr("STR_CHALLENGE_TIME_LEFT").format([int(ceil(left))]) if left >= 0.0 \
			else tr("STR_CHALLENGE_TIME_OVER").format([int(ceil(-left))])
		_set_row(2, false, text, COLOR_LIVE if left >= 0.0 else COLOR_FAIL)

	_refresh_hud()
	updated.emit()


## Danh sách 3 thử thách: [{ type, title, done, status, status_color }, ...]
func rows() -> Array[Dictionary]:
	return _rows


## Số Sao = số thử thách đã hoàn thành (0..3)
func stars() -> int:
	var total := 0
	for row in _rows:
		if bool(row.get("done", false)):
			total += 1
	return total


func all_done() -> bool:
	return stars() == COUNT


# ---------------------------------------------------------------------------
# Nội bộ
# ---------------------------------------------------------------------------
func _pass_fail(ok: bool) -> String:
	return tr("STR_CHALLENGE_DONE") if ok else tr("STR_CHALLENGE_NOT_DONE")


func _set_row(index: int, done: bool, status: String, pending_color := COLOR_DONE) -> void:
	if index < 0 or index >= _rows.size():
		return
	_rows[index]["done"] = done
	_rows[index]["status"] = status
	_rows[index]["status_color"] = COLOR_DONE if done else pending_color


## Vẽ trạng thái 3 thử thách lên thẻ HUD "THỬ THÁCH"
func _refresh_hud() -> void:
	if card == null:
		return

	var count_label := card.get_node_or_null("Count") as Label
	if count_label != null:
		var count_text := tr("STR_CHALLENGE_COUNT_FORMAT").format([stars(), COUNT])
		if count_label.text != count_text:
			count_label.text = count_text

	for i in COUNT:
		var row_node := card.get_node_or_null("Row%d" % (i + 1)) as Control
		if row_node == null:
			continue
		var row := _rows[i] if i < _rows.size() else {}
		var done := bool(row.get("done", false))

		var star := row_node.get_node_or_null("Star") as TextureRect
		if star != null:
			star.texture = STAR_FULL if done else STAR_EMPTY
			star.modulate = Color(1, 1, 1, 1) if done else Color(1, 1, 1, 0.8)

		var name_label := row_node.get_node_or_null("Name") as Label
		if name_label != null:
			var title_text := str(row.get("title", ""))
			if name_label.text != title_text:
				name_label.text = title_text
			name_label.modulate = COLOR_NAME if done else COLOR_IDLE

		var status_label := row_node.get_node_or_null("Status") as Label
		if status_label != null:
			var status_text := str(row.get("status", ""))
			if status_label.text != status_text:
				status_label.text = status_text
			status_label.modulate = row.get("status_color", COLOR_IDLE)
