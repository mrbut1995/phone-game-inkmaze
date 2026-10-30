class_name DailyCalendar
extends Control
## ============================================================================
## Component: Lịch tháng của màn Daily (nodes/daily/calendar.tscn)
## - Điều hướng tháng trước / tháng sau
## - Tự dựng lại lưới 7×5 ô ngày (nodes/daily/day.tscn) theo tháng đang xem
## - Ngày hôm nay / ngày đã chơi lấy dữ liệu từ DailyManager
## ============================================================================

signal day_selected(day: int)

@export var COLS := 7
@export var ROWS := 5
## Ô ngày được DỰNG LÚC CHẠY (35 ô) vào `grid` — cùng quy ước với các danh sách
## động khác của project (`test_ui_scenes` vẫn thấy scene `day.tscn` + script riêng).
const DAY_SCENE: PackedScene = preload("res://nodes/daily/day.tscn")
const DOW_KEYS: Array[String] = [
	"STR_DOW_MON", "STR_DOW_TUE", "STR_DOW_WED", "STR_DOW_THU",
	"STR_DOW_FRI", "STR_DOW_SAT", "STR_DOW_SUN",
]
const MONTH_WIDTH: Array[int] = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

## Node binding: khai `node_paths` + NodePath trong `calendar.tscn`
@export var month_label: Label = null
@export var btn_prev: BaseButton = null
@export var btn_next: BaseButton = null
@export var dow_row: HBoxContainer = null
@export var grid: GridContainer = null

var year: int = 2026
var month: int = 9
## Ngày đang được CHỌN (0 = chưa chọn) — vẽ vòng sáng quanh ô tương ứng
var selected_day: int = 0


func _ready() -> void:
	# Dây 2 nút đổi tháng khai trong `calendar.tscn` (cùng scene, kèm `binds` -1/+1)
	var now := Time.get_date_dict_from_system()
	year = int(now.get("year", 2026))
	month = int(now.get("month", 1))
	_build_cells()
	_connect_cells()
	_refresh_dow()
	rebuild()


## Dựng lưới 7×5 ô ngày vào `grid` (mỗi ô là `day.tscn`)
func _build_cells() -> void:
	if grid == null:
		return
	for child in grid.get_children():
		child.queue_free()
	for i in COLS * ROWS:
		var cell := DAY_SCENE.instantiate() as DailyDayCell
		cell.name = "Day%02d" % (i + 1)
		grid.add_child(cell)


## Nối tín hiệu chọn ngày của từng ô lên cho scene cha
func _connect_cells() -> void:
	if grid == null:
		return
	for child in grid.get_children():
		var cell := child as DailyDayCell
		if cell != null and not cell.day_selected.is_connected(_on_cell_selected):
			cell.day_selected.connect(_on_cell_selected)


## Đặt chữ cho hàng thứ trong tuần (T2..CN) — màu đã khai sẵn trong scene
func _refresh_dow() -> void:
	if dow_row == null:
		return
	var children := dow_row.get_children()
	for i in mini(children.size(), DOW_KEYS.size()):
		var lbl := children[i] as Label
		if lbl != null:
			lbl.text = tr(DOW_KEYS[i])


## Dựng lại toàn bộ lưới ngày của tháng đang xem
func rebuild() -> void:
	if grid == null:
		return
	month_label.text = "%s • %d" % [tr("STR_MONTH_%02d" % month), year]
	_refresh_dow()

	var daily: Node = Svc.daily()
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

		var weekend := (i % COLS) == COLS - 1  # mockup: chỉ CN tô đỏ
		var unlocked := false
		if daily != null and daily.has_method("is_day_unlocked"):
			unlocked = bool(daily.call("is_day_unlocked", day))
		cell.setup(day, _state_for(day, is_current, today, daily), _stars_for(day, daily), weekend, unlocked)

	_apply_selection()


## Xác định trạng thái của một ngày trong tháng đang xem (theo mockup)
func _state_for(day: int, is_current: bool, today: int, daily: Node) -> DailyDayCell.State:
	if not is_current:
		# Chỉ theo dõi tháng hiện tại, các tháng khác xem như chưa mở khoá
		return DailyDayCell.State.LATER
	var stars := _stars_for(day, daily)
	if day == today:
		return DailyDayCell.State.TODAY
	if day > today:
		# 2 ngày kế tiếp chỉ hiện SỐ, xa hơn thì hiện ô NÉT ĐỨT (như mockup)
		return DailyDayCell.State.FUTURE if day - today <= 2 else DailyDayCell.State.LATER
	if stars >= DailyDayCell.MAX_STARS:
		return DailyDayCell.State.DONE
	if stars > 0:
		return DailyDayCell.State.PARTIAL
	return DailyDayCell.State.MISSED


## Số Sao đã đạt của một ngày (0..6)
func _stars_for(day: int, daily: Node) -> int:
	if daily == null:
		return 0
	if daily.has_method("get_day_stars"):
		return int(daily.call("get_day_stars", day))
	return DailyDayCell.MAX_STARS if bool(daily.call("is_completed", day)) else 0


## Đổi NGÀY ĐANG CHỌN (màn Daily gọi mỗi lần đổi ngày) — chỉ đổi vòng sáng, không dựng lại lưới
func set_selected_day(day: int) -> void:
	selected_day = day
	_apply_selection()


## Bật vòng sáng cho đúng ô đang chọn (ô trống / tháng khác thì không sáng)
func _apply_selection() -> void:
	if grid == null:
		return
	for child in grid.get_children():
		var cell := child as DailyDayCell
		if cell == null:
			continue
		cell.set_selected(selected_day > 0 and cell.day_number == selected_day
			and cell.state != DailyDayCell.State.NONE)


func _is_current_month() -> bool:
	var now := Time.get_date_dict_from_system()
	return int(now.get("year", 0)) == year and int(now.get("month", 0)) == month


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
