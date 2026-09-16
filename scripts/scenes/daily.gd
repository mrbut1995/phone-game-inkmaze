class_name DailyScene
extends BaseScene
## ============================================================================
## View Controller: Màn hình Daily Challenge (scenes/daily.tscn)
## - Lịch tháng (nodes/daily/calendar.tscn) để chọn ngày thử thách
## - Bảng nhiệm vụ ngày: 3 nhiệm vụ + tiến độ + thưởng sao
## - Huy hiệu chuỗi ngày (streak) và nút chơi chế độ xoay vòng của hôm nay
## ============================================================================

const UIAnim := preload("res://scripts/utils/ui_anim.gd")
const MISSION_ROW := preload("res://nodes/daily/mission_row.tscn")
## Icon của nút CTA: bút chì (chơi) / đồng Xu (trả Xu mở khoá ngày bỏ lỡ)
const ICON_PLAY := preload("res://assets/images/calendar/pencil_icon.svg")
const ICON_UNLOCK := preload("res://assets/images/shop/icon_coin.svg")
## 3 nhiệm vụ đầu thuộc MAZE THƯỜNG (Game Classic), nhiệm vụ thứ 4 thuộc MAZE ĐẶC BIỆT
const CLASSIC_MISSION_COUNT := 3
## Chiều cao mỗi hàng nhiệm vụ trong bảng (khớp mockup daily_challenge.svg)
const ROW_HEIGHT := 110.0

@onready var btn_back: TextureButton = $TopBar/Back
@onready var calendar: DailyCalendar = $Calendar
@onready var lbl_streak: Label = $StreakBadge/Streak
@onready var lbl_date: Label = $Missions/DateTag/Label
@onready var lbl_mode: Label = $Missions/Mode
@onready var lbl_reward: Label = $Missions/Reward/Label
@onready var rows_host: Control = $Missions/Rows
@onready var lbl_progress: Label = $Missions/ProgressLabel
@onready var bar_progress: TextureProgressBar = $Missions/ProgressBar
@onready var lbl_claim: Label = $Missions/Claim
@onready var btn_play: TextureButton = $Play
@onready var lbl_play: Label = $Play/Label
@onready var icon_play: TextureRect = $Play/Icon

var _rows: Array[DailyMissionRow] = []
var _daily: Node = null
## Ngày đang xem (mặc định hôm nay). Bấm ngày khác trên lịch = xem nhiệm vụ ngày đó.
var _selected_day := 1


func _ready() -> void:
	_daily = get_node_or_null("/root/DailyManager")
	_selected_day = _today()

	if btn_back != null:
		btn_back.pressed.connect(_on_back_pressed)
		UIAnim.attach_press_bounce(btn_back)
	if btn_play != null:
		btn_play.pressed.connect(_on_play_pressed)
		UIAnim.attach_press_bounce(btn_play)
		UIAnim.play_pulse(btn_play, 1.03, 1.8)
	if calendar != null:
		calendar.day_selected.connect(_on_day_selected)
	if _daily != null and _daily.has_signal("daily_changed"):
		_daily.connect("daily_changed", _refresh)

	var streak_badge := get_node_or_null("StreakBadge") as Control
	if streak_badge != null:
		UIAnim.play_pop_in(streak_badge, 0.08, 0.8, 0.25)

	_build_rows()
	_refresh()


## Dựng 4 hàng nhiệm vụ (3 maze thường + 1 maze đặc biệt) trong bảng Mission
func _build_rows() -> void:
	if rows_host == null:
		return
	for child in rows_host.get_children():
		child.queue_free()
	_rows.clear()
	for i in _mission_total():
		var row: DailyMissionRow = MISSION_ROW.instantiate()
		row.name = "Row%d" % (i + 1)
		row.position = Vector2(0, ROW_HEIGHT * i)
		rows_host.add_child(row)
		row.action_pressed.connect(_on_row_action_pressed)
		_rows.append(row)
		UIAnim.play_fade_in(row, 0.04 * i, 0.22)


# --- API cho test -----------------------------------------------------------

## Ngày đang xem trên lịch
func selected_day() -> int:
	return _selected_day


## Đổi ngày đang xem (không nhảy vào màn chơi)
func select_day(day: int) -> void:
	if day <= 0:
		return
	_selected_day = day
	_refresh()


## Số hàng nhiệm vụ đang hiển thị
func row_count() -> int:
	return _rows.size()


func row_at(index: int) -> DailyMissionRow:
	if index < 0 or index >= _rows.size():
		return null
	return _rows[index]


# ---------------------------------------------------------------------------
# Dữ liệu
# ---------------------------------------------------------------------------
## Cập nhật toàn bộ nội dung theo ngày đang chọn
func _refresh() -> void:
	if _daily == null:
		return
	var day := _selected_day
	var mode_name := _mode_name(day)
	var done := _missions_done(day)
	var total := _mission_total()

	lbl_streak.text = tr("STR_DAILY_STREAK_UNIT").format([_streak()])
	lbl_mode.text = tr("STR_DAILY_SPECIAL_LABEL").format([mode_name])
	lbl_date.text = tr("STR_DAILY_DATE_BADGE").format([
		day,
		DailyCalendar.days_in_month(_current_year(), _current_month()),
	])
	lbl_reward.text = tr("STR_DAILY_REWARD_STARS").format([_day_reward_max()])

	# Nút CTA: ngày bỏ lỡ đang khoá -> hiện yêu cầu trả Xu để mở khoá
	var unlockable := _can_unlock_day(day)
	if unlockable:
		lbl_play.text = tr("STR_DAILY_UNLOCK_COST").format([_unlock_cost()])
	else:
		lbl_play.text = tr("STR_DAILY_PLAY_MODE").format([mode_name])
	if icon_play != null:
		icon_play.texture = ICON_UNLOCK if unlockable else ICON_PLAY
	if btn_play != null:
		# Ngày tương lai (chưa mở) thì nút khoá hẳn; ngày bỏ lỡ vẫn bấm được để MỞ KHOÁ
		btn_play.disabled = not _is_day_playable(day) and not unlockable

	_refresh_rows(day, mode_name)
	_refresh_footer(day, done, total)

	# Ô ngày trên lịch đổi viện trạng thái ("ĐÃ MỞ") sau khi trả Xu mở khoá
	if calendar != null:
		calendar.rebuild()


## 4 hàng nhiệm vụ: 3 nhiệm vụ maze thường (0..2) + 1 nhiệm vụ maze đặc biệt (3)
func _refresh_rows(day: int, mode_name: String) -> void:
	var playable := _is_day_playable(day)
	for i in _rows.size():
		var done := false
		if _daily.has_method("is_mission_done"):
			done = bool(_daily.call("is_mission_done", day, i))
		_rows[i].setup(i, {
			"title": _mission_title(i, mode_name),
			"desc": _mission_desc(i),
			"progress": tr("STR_DAILY_MISSION_PROGRESS_DONE" if done else "STR_DAILY_MISSION_PROGRESS_TODO"),
			"reward": _mission_reward(i),
			"done": done,
			"special": i >= CLASSIC_MISSION_COUNT,
			"playable": playable,
		})


func _mission_title(index: int, mode_name: String) -> String:
	match index:
		0:
			return tr("STR_DAILY_MISSION_NO_WALL_TITLE")
		1:
			return tr("STR_DAILY_MISSION_STEPS_TITLE").format([_classic_steps()])
		2:
			return tr("STR_DAILY_MISSION_TIME_TITLE").format([_classic_time()])
		_:
			return tr("STR_DAILY_MISSION_SPECIAL_TITLE").format([mode_name])


func _mission_desc(index: int) -> String:
	match index:
		0:
			return tr("STR_DAILY_MISSION_NO_WALL_DESC")
		1:
			return tr("STR_DAILY_MISSION_STEPS_DESC")
		2:
			return tr("STR_DAILY_MISSION_TIME_DESC")
		_:
			return tr("STR_DAILY_MISSION_SPECIAL_DESC")


## Thanh tiến độ ngày (x/4 nhiệm vụ) + Xu đã nhận trong ngày
func _refresh_footer(day: int, done: int, total: int) -> void:
	var percent := int(round(100.0 * float(done) / float(maxi(total, 1))))
	lbl_progress.text = tr("STR_DAILY_TOTAL_PROGRESS").format([percent, "%d/%d" % [done, total]])
	if bar_progress != null:
		bar_progress.value = percent
	if lbl_claim != null:
		lbl_claim.text = tr("STR_DAILY_CLAIMED_REWARD").format([
			_day_coins_earned(day),
			_day_reward_max(),
		])


# --- Tiện ích đọc dữ liệu DailyManager --------------------------------------

func _today() -> int:
	return int(_daily.call("get_today")) if _daily != null else 1


func _mission_total() -> int:
	if _daily != null and _daily.has_method("mission_count"):
		return int(_daily.call("mission_count"))
	return CLASSIC_MISSION_COUNT + 1


func _missions_done(day: int) -> int:
	if _daily != null and _daily.has_method("get_day_missions"):
		return int(_daily.call("get_day_missions", day))
	return 0


func _mission_reward(index: int) -> int:
	if _daily != null and _daily.has_method("mission_reward"):
		return int(_daily.call("mission_reward", index))
	return 0


func _day_reward_max() -> int:
	if _daily != null and _daily.has_method("day_reward_max"):
		return int(_daily.call("day_reward_max"))
	return 0


func _day_coins_earned(day: int) -> int:
	if _daily != null and _daily.has_method("day_coins_earned"):
		return int(_daily.call("day_coins_earned", day))
	return 0


## Ngày chơi được: hôm nay, ngày đã có tiến độ, hoặc ngày bỏ lỡ đã trả Xu mở khoá.
## Ngày khác chỉ để XEM nhiệm vụ.
func _is_day_playable(day: int) -> bool:
	return day == _today() or _missions_done(day) > 0 or _is_day_unlocked(day)


## Ngày đã được trả Xu mở khoá
func _is_day_unlocked(day: int) -> bool:
	if _daily != null and _daily.has_method("is_day_unlocked"):
		return bool(_daily.call("is_day_unlocked", day))
	return false


## Ngày bỏ lỡ có thể trả Xu mở khoá (ngày đã qua, chưa chơi gì, chưa mở khoá)
func _can_unlock_day(day: int) -> bool:
	if _daily != null and _daily.has_method("can_unlock_day"):
		return bool(_daily.call("can_unlock_day", day))
	return false


## Giá mở khoá một ngày bỏ lỡ (Xu)
func _unlock_cost() -> int:
	if _daily != null and _daily.has_method("unlock_cost"):
		return int(_daily.call("unlock_cost"))
	return 0


func _streak() -> int:
	return int(_daily.call("get_streak")) if _daily != null else 0


func _mode_name(day: int) -> String:
	if _daily == null:
		return ""
	var mode_id := str(_daily.call("get_mode_for_day", day))
	return tr("STR_MODE_%s" % mode_id.to_upper())


## Số bước / giới hạn thời gian của maze thường trong ngày (khớp DailyClassicGameMode)
func _classic_steps() -> int:
	return DailyClassicGameMode.DESIGN_STEPS


func _classic_time() -> int:
	return DailyClassicGameMode.TIME_LIMIT_SEC


func _current_year() -> int:
	return int(Time.get_date_dict_from_system().get("year", 2026))


func _current_month() -> int:
	return int(Time.get_date_dict_from_system().get("month", 1))


# --- Sự kiện ----------------------------------------------------------------

## Bấm 1 ngày trên lịch: CHỈ đổi ngày đang xem (không nhảy thẳng vào màn chơi)
func _on_day_selected(day: int) -> void:
	select_day(day)


## Nút CTA dưới cùng: chơi MAZE ĐẶC BIỆT của ngày đang chọn
## (ngày bỏ lỡ đang khoá -> nút đổi thành trả Xu MỞ KHOÁ)
func _on_play_pressed() -> void:
	if _can_unlock_day(_selected_day):
		_unlock_selected_day()
		return
	_play_special()


## Ngày đang xem bị BỎ LỠ: trả Xu để mở khoá, sau đó ngày chơi được như bình thường
func _unlock_selected_day() -> void:
	if _daily == null or not _daily.has_method("unlock_day"):
		return
	if bool(_daily.call("unlock_day", _selected_day)):
		# "Cộp" con dấu khi mở khoá thành công
		Sfx.play(Sfx.STAMP_IMPACT)
		return
	# Ví không đủ Xu: gãy ngòi chì báo không mở được
	Sfx.play(Sfx.WALL_HIT)


## Nút trên hàng nhiệm vụ: 3 hàng đầu -> MAZE THƯỜNG, hàng 4 -> MAZE ĐẶC BIỆT
func _on_row_action_pressed(index: int) -> void:
	if index < CLASSIC_MISSION_COUNT:
		_play_classic()
	else:
		_play_special()


func _play_classic() -> void:
	if not _is_day_playable(_selected_day):
		return
	Sfx.play(Sfx.BTN_CLICK)
	_start_daily(_selected_day, true)


func _play_special() -> void:
	if not _is_day_playable(_selected_day):
		return
	Sfx.play(Sfx.BTN_CLICK)
	_start_daily(_selected_day, false)


## `classic = true` -> Game Classic (maze thường), false -> maze đặc biệt của ngày
func _start_daily(day: int, classic: bool) -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm == null:
		Nav.goto_game()
		return
	if classic and gm.has_method("start_daily_classic"):
		gm.call("start_daily_classic", day)
	elif gm.has_method("start_daily"):
		gm.call("start_daily", day)
	else:
		Nav.goto_game()


func _on_back_pressed() -> void:
	# SFX: gõ thẻ giấy cho nút phụ (Back)
	Sfx.play(Sfx.BTN_WOOD_TAP)
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm != null:
		gm.go_to_main_menu()
	else:
		Nav.goto_main()
