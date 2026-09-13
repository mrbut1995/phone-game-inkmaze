extends Node
## ============================================================================
## Manager: DailyManager - Thử thách hằng ngày (Daily Challenge).
## - Xác định "hôm nay" là ngày nào (1..31) theo lịch máy.
## - Xoay vòng 7 Challenge Mode theo ngày (khớp GameManagerClass.DAILY_MODES).
## - Lưu danh sách ngày đã hoàn thành: user://daily.cfg
## ============================================================================

signal daily_completed(day: int)
signal daily_changed

const CONFIG_PATH := "user://daily.cfg"
const SECTION := "daily"
## Số sao tối đa của một ngày thử thách (khớp 3 nhiệm vụ trong STR_DAILY_TASK_*)
const MAX_STARS_PER_DAY := 3

var completed_days: Array[int] = []
## day (1..31) -> số sao đạt được (0..3)
var day_stars: Dictionary = {}


func _ready() -> void:
	_load_completed()


## Ngày hôm nay theo lịch máy (1..31)
func get_today() -> int:
	return int(Time.get_date_dict_from_system().get("day", 1))


func is_today(day: int) -> bool:
	return day == get_today()


func is_completed(day: int) -> bool:
	return completed_days.has(day)


func mark_completed(day: int) -> void:
	if completed_days.has(day):
		return
	completed_days.append(day)
	_save_completed()
	daily_completed.emit(day)
	daily_changed.emit()


## Số sao đã đạt được của một ngày (0 nếu chưa chơi)
func get_day_stars(day: int) -> int:
	if day_stars.has(day):
		return int(day_stars[day])
	return MAX_STARS_PER_DAY if completed_days.has(day) else 0


## Ghi nhận số sao của một ngày (chỉ tăng, không giảm)
func set_day_stars(day: int, stars: int) -> void:
	var clamped := clampi(stars, 0, MAX_STARS_PER_DAY)
	if get_day_stars(day) >= clamped:
		return
	day_stars[day] = clamped
	if not completed_days.has(day):
		completed_days.append(day)
	_save_completed()
	daily_changed.emit()


## Tổng số sao đã nhận trong tháng
func get_total_stars() -> int:
	var total := 0
	for day in completed_days:
		total += get_day_stars(int(day))
	return total


## Chuỗi ngày liên tiếp đã hoàn thành, tính lùi từ hôm nay (hoặc hôm qua)
func get_streak() -> int:
	var today := get_today()
	var cursor := today
	if not completed_days.has(today) and completed_days.has(today - 1):
		cursor = today - 1
	var streak := 0
	while cursor >= 1 and completed_days.has(cursor):
		streak += 1
		cursor -= 1
	return streak


## Số nhiệm vụ (0..3) đã hoàn thành của một ngày, suy ra từ số sao
func get_task_mask(day: int) -> Array[bool]:
	var stars := get_day_stars(day)
	return [stars >= 1, stars >= 2, stars >= 3]


## Mode xoay vòng cho 1 ngày (1 -> mode đầu tiên trong danh sách)
func get_mode_for_day(day: int) -> String:
	var modes := GameManagerClass.DAILY_MODES
	if modes.is_empty():
		return ""
	var index := posmod(day - 1, modes.size())
	return modes[index]


func get_completed_count() -> int:
	return completed_days.size()


func _save_completed() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, "completed_days", PackedInt32Array(completed_days))
	cfg.set_value(SECTION, "day_stars", day_stars)
	cfg.save(CONFIG_PATH)


func _load_completed() -> void:
	completed_days.clear()
	day_stars.clear()
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return
	var saved: Variant = cfg.get_value(SECTION, "completed_days", PackedInt32Array())
	if saved is PackedInt32Array or saved is Array:
		for day in saved:
			completed_days.append(int(day))
	var stars: Variant = cfg.get_value(SECTION, "day_stars", {})
	if stars is Dictionary:
		for day in stars:
			day_stars[int(day)] = int(stars[day])
