class_name DailyWeekStrip
extends Control
## ============================================================================
## DẢI TUẦN của màn Daily (nodes/daily/week_strip.tscn)
## 7 ô ngày (Thứ 2 → CN) của tuần chứa ngày đang chọn + nút mở LỊCH THÁNG.
## Chỉ theo dõi THÁNG HIỆN TẠI (dữ liệu Daily theo tháng); ô ngoài tháng chỉ hiện số mờ.
## ============================================================================

signal day_selected(day: int)
## Bấm nút lịch: màn Daily mở bảng lịch tháng
signal month_requested

@export var days_host: HBoxContainer = null
@export var btn_month: BaseButton = null

var selected_day := 0


func _ready() -> void:
	for child in days_host.get_children():
		var cell := child as DailyWeekDay
		if cell != null and not cell.day_selected.is_connected(_on_cell_selected):
			cell.day_selected.connect(_on_cell_selected)


## Dựng lại 7 ô cho tuần chứa `p_selected` (đồng thời đặt vòng "đang chọn")
func rebuild(p_selected: int) -> void:
	selected_day = p_selected
	if days_host == null:
		return
	var now := Time.get_date_dict_from_system()
	var year := int(now.get("year", 2026))
	var month := int(now.get("month", 1))
	var dim := DailyCalendar.days_in_month(year, month)
	var prev_dim := DailyCalendar.days_in_month(year, month - 1) if month > 1 \
		else DailyCalendar.days_in_month(year - 1, 12)
	var daily: Node = Svc.daily()
	var today := int(daily.call("get_today")) if daily != null else -1
	var anchor := p_selected if p_selected > 0 else today
	var offset := (DailyCalendar.weekday_of(year, month, clampi(anchor, 1, dim)) + 6) % 7
	var first := anchor - offset
	var cells := days_host.get_children()
	for i in mini(cells.size(), 7):
		var cell := cells[i] as DailyWeekDay
		if cell == null:
			continue
		var day := first + i
		var dow := tr(DailyCalendar.DOW_KEYS[i])
		if day < 1:
			cell.setup(prev_dim + day, dow, DailyDayCell.State.EMPTY, false)
		elif day > dim:
			cell.setup(day - dim, dow, DailyDayCell.State.EMPTY, false)
		else:
			var unlocked := daily != null and daily.has_method("is_day_unlocked") \
				and bool(daily.call("is_day_unlocked", day))
			cell.setup(day, dow, _state_for(day, today, daily), i == 6, unlocked)
		cell.set_selected(day == p_selected)


## Cùng quy tắc với `DailyCalendar._state_for` (tháng hiện tại)
func _state_for(day: int, today: int, daily: Node) -> DailyDayCell.State:
	var stars := _stars_for(day, daily)
	if day == today:
		return DailyDayCell.State.TODAY
	if day > today:
		return DailyDayCell.State.FUTURE if day - today <= 2 else DailyDayCell.State.LATER
	if stars >= DailyDayCell.MAX_STARS:
		return DailyDayCell.State.DONE
	if stars > 0:
		return DailyDayCell.State.PARTIAL
	return DailyDayCell.State.MISSED


func _stars_for(day: int, daily: Node) -> int:
	if daily == null:
		return 0
	if daily.has_method("get_day_stars"):
		return int(daily.call("get_day_stars", day))
	return DailyDayCell.MAX_STARS if bool(daily.call("is_completed", day)) else 0


func _on_cell_selected(day: int) -> void:
	day_selected.emit(day)


func _on_month_pressed() -> void:
	Sfx.play(Sfx.DAY_SWITCH)
	month_requested.emit()
