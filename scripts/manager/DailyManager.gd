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

var completed_days: Array[int] = []


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
	cfg.save(CONFIG_PATH)


func _load_completed() -> void:
	completed_days.clear()
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return
	var saved: Variant = cfg.get_value(SECTION, "completed_days", PackedInt32Array())
	if saved is PackedInt32Array or saved is Array:
		for day in saved:
			completed_days.append(int(day))
