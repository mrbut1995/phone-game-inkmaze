class_name DailyScene
extends BaseScene
## ============================================================================
## View Controller: Màn hình Daily Challenge (scenes/daily.tscn)
## - Lịch tháng (nodes/daily/calendar.tscn) để chọn ngày thử thách
## - Bảng nhiệm vụ ngày: 3 nhiệm vụ + tiến độ + thưởng sao
## - Huy hiệu chuỗi ngày (streak) và nút chơi chế độ xoay vòng của hôm nay
## ============================================================================

## Thưởng sao cho 3 nhiệm vụ trong ngày (khớp mockup)
const TASK_REWARDS: Array[int] = [15, 10, 10]

@onready var btn_back: TextureButton = $TopBar/Back
@onready var calendar: DailyCalendar = $Calendar
@onready var lbl_streak: Label = $StreakBadge/Streak
@onready var lbl_date: Label = $Missions/DateTag/Label
@onready var lbl_mode: Label = $Missions/Mode
@onready var lbl_reward: Label = $Missions/Reward/Label
@onready var lbl_progress: Label = $Missions/ProgressLabel
@onready var bar_progress: TextureProgressBar = $Missions/ProgressBar
@onready var lbl_claim: Label = $Missions/Claim
@onready var btn_play: TextureButton = $Play
@onready var lbl_play: Label = $Play/Label

var _rows: Array[Control] = []
var _daily: Node = null


func _ready() -> void:
	_daily = get_node_or_null("/root/DailyManager")
	_rows = [$Missions/Row1, $Missions/Row2, $Missions/Row3]

	if btn_back != null:
		btn_back.pressed.connect(_on_back_pressed)
	if btn_play != null:
		btn_play.pressed.connect(_on_play_pressed)
	if calendar != null:
		calendar.day_selected.connect(_on_day_selected)
	if _daily != null and _daily.has_signal("daily_changed"):
		_daily.connect("daily_changed", _refresh)

	_refresh()


## Cập nhật toàn bộ nội dung theo dữ liệu của DailyManager
func _refresh() -> void:
	var today := _today()
	var stars := _stars_of(today)
	var mode_name := _mode_name(today)

	lbl_streak.text = tr("STR_DAILY_STREAK_UNIT").format([_streak()])
	lbl_mode.text = tr("STR_DAILY_TODAY_MODE").format([mode_name])
	lbl_date.text = tr("STR_DAILY_DATE_BADGE").format([
		today,
		DailyCalendar.days_in_month(_current_year(), _current_month()),
	])
	lbl_reward.text = tr("STR_DAILY_REWARD_STARS").format([TASK_REWARDS[0] + TASK_REWARDS[1] + TASK_REWARDS[2]])
	lbl_play.text = tr("STR_DAILY_PLAY_MODE").format([mode_name])

	_refresh_tasks(stars)
	_refresh_footer(stars)


## Ba hàng nhiệm vụ: nội dung chữ, trạng thái tick và nút hành động
func _refresh_tasks(stars: int) -> void:
	for i in _rows.size():
		var row := _rows[i]
		var index := i + 1
		var done := stars > i

		(row.get_node("Title") as Label).text = tr("STR_DAILY_TASK_%d_TITLE" % index)
		(row.get_node("Desc") as Label).text = tr("STR_DAILY_TASK_%d_DESC" % index)
		(row.get_node("Progress") as Label).text = tr("STR_DAILY_TASK_%d_PROGRESS" % index)
		(row.get_node("Progress") as Label).theme_type_variation = (
			&"DailyTaskProgress" if done else &"DailyTaskProgressTodo"
		)
		(row.get_node("Reward") as Label).text = tr("STR_DAILY_REWARD_STARS").format([TASK_REWARDS[i]])

		var box := row.get_node("Box") as TextureRect
		box.texture = load("res://assets/images/calendar/%s.svg" % (
			"box_task_done" if done else "box_task_todo"
		))

		var status := row.get_node("Status") as Label
		status.theme_type_variation = &"DailyTaskStatusDone" if done else &"DailyTaskStatusTodo"
		status.text = tr("STR_STATUS_DONE_SHORT") if done else tr("STR_DAILY_TODO_FORMAT").format([0, 1])

		# Nút hành động: đã xong -> chơi lại / xem lại, chưa xong -> vào chơi
		var action := row.get_node("Action") as TextureButton
		var action_label := action.get_node("Label") as Label
		if done:
			action.texture_normal = load("res://assets/images/calendar/btn_completed_normal.svg")
			action.texture_pressed = load("res://assets/images/calendar/btn_completed_pressed.svg")
			action.texture_hover = load("res://assets/images/calendar/btn_completed_pressed.svg")
			action.texture_focused = load("res://assets/images/calendar/btn_completed_focus.svg")
			action_label.theme_type_variation = &"DailyActionIdle"
			action_label.text = tr("STR_BTN_REPLAY") if i == 0 else tr("STR_BTN_REVIEW")
		else:
			action.texture_normal = load("res://assets/images/calendar/btn_primary_normal.svg")
			action.texture_pressed = load("res://assets/images/calendar/btn_primary_pressed.svg")
			action.texture_hover = load("res://assets/images/calendar/btn_primary_pressed.svg")
			action.texture_focused = load("res://assets/images/calendar/btn_primary_focus.svg")
			action_label.theme_type_variation = &"DailyActionPrimary"
			action_label.text = tr("STR_BTN_PLAY_NOW")


## Thanh tiến độ ngày + số sao đã nhận
func _refresh_footer(stars: int) -> void:
	var percent := int(round(100.0 * float(stars) / float(DailyDayCell.MAX_STARS)))
	lbl_progress.text = tr("STR_DAILY_TOTAL_PROGRESS").format([percent, stars])
	if bar_progress != null:
		bar_progress.value = percent

	var claimed := 0
	var max_total := 0
	if _daily != null:
		claimed = int(_daily.call("get_total_stars"))
		max_total = maxi(_today(), 1) * DailyDayCell.MAX_STARS
	lbl_claim.text = tr("STR_DAILY_CLAIMED_REWARD").format([claimed, max_total])


# --- Tiện ích đọc dữ liệu DailyManager --------------------------------------

func _today() -> int:
	return int(_daily.call("get_today")) if _daily != null else 1


func _stars_of(day: int) -> int:
	return int(_daily.call("get_day_stars", day)) if _daily != null else 0


func _streak() -> int:
	return int(_daily.call("get_streak")) if _daily != null else 0


func _mode_name(day: int) -> String:
	if _daily == null:
		return ""
	var mode_id := str(_daily.call("get_mode_for_day", day))
	return tr("STR_MODE_%s" % mode_id.to_upper())


func _current_year() -> int:
	return int(Time.get_date_dict_from_system().get("year", 2026))


func _current_month() -> int:
	return int(Time.get_date_dict_from_system().get("month", 1))


# --- Sự kiện ----------------------------------------------------------------

func _on_day_selected(day: int) -> void:
	_start_day(day)


func _on_play_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	_start_day(_today())


func _start_day(day: int) -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm != null:
		gm.start_daily(day)
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
