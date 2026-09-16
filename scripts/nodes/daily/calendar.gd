class_name DailyCalendar
extends Control
## ============================================================================
## Component: Lịch tháng của màn Daily Challenge (nodes/daily/calendar.tscn)
## - Điều hướng tháng trước / tháng sau
## - Tự dựng lại lưới 7x5 ô ngày (nodes/daily/day.tscn) theo tháng đang xem
## - Ngày hôm nay / ngày đã hoàn thành lấy dữ liệu từ DailyManager
## ============================================================================

signal day_selected(day: int)

const COLS := 7
const ROWS := 5
const DOW_KEYS: Array[String] = [
	"STR_DOW_MON", "STR_DOW_TUE", "STR_DOW_WED", "STR_DOW_THU",
	"STR_DOW_FRI", "STR_DOW_SAT", "STR_DOW_SUN",
]
const MONTH_WIDTH: Array[int] = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

@onready var month_label: Label = $Months/Label
@onready var btn_prev: TextureButton = $Months/Previous
@onready var btn_next: TextureButton = $Months/Next
@onready var dow_row: HBoxContainer = $DayTitle
@onready var grid: GridContainer = $Days

var year: int = 2026
var month: int = 9


func _ready() -> void:
	if btn_prev != null:
		btn_prev.pressed.connect(_on_month_switch_pressed.bind(-1))
	if btn_next != null:
		btn_next.pressed.connect(_on_month_switch_pressed.bind(1))

	var now := Time.get_date_dict_from_system()
	year = int(now.get("year", 2026))
	month = int(now.get("month", 1))
	_connect_cells()
	_refresh_dow()
	rebuild()


## Nối tín hiệu chọn ngày của từng ô lên cho scene cha
func _connect_cells() -> void:
	if grid == null:
		return
	for child in grid.get_children():
		var cell := child as DailyDayCell
		if cell != null and not cell.day_selected.is_connected(_on_cell_selected):
			cell.day_selected.connect(_on_cell_selected)


## Đặt chữ cho hàng thứ trong tuần (T2..CN)
func _refresh_dow() -> void:
	if dow_row == null:
		return
	var today_col := _today_column()
	var real_month := _is_current_month()
	var children := dow_row.get_children()
	for i in children.size():
		var lbl := children[i] as Label
		if lbl == null:
			continue
		lbl.text = tr(DOW_KEYS[i])
		if i == 6:
			lbl.theme_type_variation = &"DailyDowSun"
		elif real_month and i == today_col:
			lbl.theme_type_variation = &"DailyDowActive"
		else:
			lbl.theme_type_variation = &"DailyDow"


## Dựng lại toàn bộ lưới ngày của tháng đang xem
func rebuild() -> void:
	if grid == null:
		return
	month_label.text = "%s • %d" % [tr("STR_MONTH_%02d" % month), year]
	_refresh_dow()

	var daily: Node = get_node_or_null("/root/DailyManager")
	var days_in_month := days_in_month(year, month)
	var days_in_prev := days_in_month(year, month - 1) if month > 1 else days_in_month(year - 1, 12)
	var offset := (weekday_of(year, month, 1) + 6) % 7  # cột bắt đầu, tuần tự Thứ 2
	var is_current := _is_current_month()
	var today := int(daily.call("get_today")) if daily != null else -1

	var children := grid.get_children()
	for i in mini(children.size(), COLS * ROWS):
		var cell := children[i] as DailyDayCell
		if cell == null:
			continue

		var day := i - offset + 1
		if day < 1:
			# Ngày cuối của tháng trước
			cell.setup(days_in_prev + day, DailyDayCell.State.EMPTY)
			continue
		if day > days_in_month:
			# Ô trống cuối tháng (không hiển thị ngày tháng sau)
			cell.setup(0, DailyDayCell.State.NONE)
			continue

		var weekend := (i % COLS) >= 5
		var unlocked := false
		if daily != null and daily.has_method("is_day_unlocked"):
			unlocked = bool(daily.call("is_day_unlocked", day))
		cell.setup(day, _state_for(day, is_current, today, daily), _missions_for(day, daily), weekend, unlocked)


## Xác định trạng thái của một ngày trong tháng đang xem
func _state_for(day: int, is_current: bool, today: int, daily: Node) -> DailyDayCell.State:
	if not is_current:
		# Chỉ theo dõi tháng hiện tại, các tháng khác xem như chưa mở khoá
		return DailyDayCell.State.LATER
	var missions := _missions_for(day, daily)
	if day == today:
		return DailyDayCell.State.TODAY
	if day > today:
		# 3 ngày kế tiếp hiển thị viên "CHƯA MỞ", xa hơn thì mờ gọn lại
		return DailyDayCell.State.FUTURE if day - today <= 3 else DailyDayCell.State.LATER
	if missions >= DailyDayCell.MAX_MISSIONS:
		return DailyDayCell.State.DONE
	if missions > 0:
		return DailyDayCell.State.PARTIAL
	return DailyDayCell.State.MISSED


func _missions_for(day: int, daily: Node) -> int:
	if daily == null:
		return 0
	if daily.has_method("get_day_missions"):
		return int(daily.call("get_day_missions", day))
	return DailyDayCell.MAX_MISSIONS if bool(daily.call("is_completed", day)) else 0


func _is_current_month() -> bool:
	var now := Time.get_date_dict_from_system()
	return int(now.get("year", 0)) == year and int(now.get("month", 0)) == month


func _today_column() -> int:
	var now := Time.get_date_dict_from_system()
	return (weekday_of(year, month, int(now.get("day", 1))) + 6) % 7


func _on_month_switch_pressed(delta: int) -> void:
	# SFX: miết mép giấy khi lật tháng
	Sfx.play(Sfx.DAY_SWITCH)
	month += delta
	if month < 1:
		month = 12
		year -= 1
	elif month > 12:
		month = 1
		year += 1
	rebuild()


func _on_cell_selected(day: int) -> void:
	day_selected.emit(day)


## Số ngày của một tháng (month có thể vượt biên 1..12)
static func days_in_month(p_year: int, p_month: int) -> int:
	var m := p_month
	m = 12 if m == 0 else m
	var days: int = MONTH_WIDTH[m - 1]
	if m == 2 and _is_leap(p_year):
		days = 29
	return days


## Thứ của một ngày theo quy ước của Godot: 0 = Chủ nhật, 1 = Thứ 2, ... 6 = Thứ 7
static func weekday_of(p_year: int, p_month: int, p_day: int) -> int:
	var stamp := Time.get_unix_time_from_datetime_dict({
		"year": p_year, "month": p_month, "day": p_day,
		"hour": 12, "minute": 0, "second": 0,
	})
	return int(Time.get_datetime_dict_from_unix_time(int(stamp)).get("weekday", 0))


static func _is_leap(p_year: int) -> bool:
	return (p_year % 4 == 0 and p_year % 100 != 0) or p_year % 400 == 0
