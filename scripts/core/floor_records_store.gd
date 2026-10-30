class_name FloorRecordsStore
extends RefCounted
## ============================================================================
## KỶ LỤC TẦNG CAO NHẤT — theo NGÀY / TUẦN / THÁNG (tách khỏi `GameManager`).
##
## · Chỉ tính tầng của ván VÔ TẬN (Dungeon) vì đó mới là "tầng" tăng dần vô hạn.
## · Mỗi kỳ giữ `key` (mốc thời gian) + `floor`: sang ngày/tuần/tháng mới thì tự về 0.
## · `week` dùng mốc THỨ HAI của tuần (ISO) để tuần luôn bắt đầu từ thứ Hai.
##
## Ai gọi: CHỈ `GameManager` (uỷ thác `best_floor()` · `record_floor_reached()`),
## `SaveManager` chỉ nghe signal `floor_record_changed` do GameManager phát lại.
## ============================================================================

const KINDS: Array[String] = ["day", "week", "month"]

var records: Dictionary = {
	"day": {"key": "", "floor": 0},
	"week": {"key": "", "floor": 0},
	"month": {"key": "", "floor": 0},
}
## [TEST] Cho phép ghi kỷ lục khi chạy test runner tự động (mặc định: test KHÔNG ghi,
## để bộ test không làm bẩn kỷ lục của người chơi thật)
var record_in_tests := false


## Tầng cao nhất đạt được trong kỳ hiện tại (0 = chưa có kỷ lục). Kỳ đã đổi thì đọc ra 0.
func best(kind := "week") -> int:
	if not records.has(kind):
		return 0
	var bucket: Dictionary = records.get(kind, {})
	if str(bucket.get("key", "")) != current_period_key(kind):
		return 0
	return maxi(int(bucket.get("floor", 0)), 0)


## Ghi nhận vừa ĐẠT tới `floor_number`. Trả về danh sách kỳ (ngày/tuần/tháng) vừa lập kỷ lục mới.
func reach(floor_number: int) -> Array[String]:
	var improved: Array[String] = []
	if floor_number <= 0:
		return improved
	sync()
	for kind in KINDS:
		var bucket: Dictionary = records[kind]
		if floor_number > int(bucket.get("floor", 0)):
			bucket["floor"] = floor_number
			improved.append(kind)
	return improved


## Bỏ kỷ lục của kỳ đã qua (sang ngày/tuần/tháng mới thì kỷ lục bắt đầu lại từ 0)
func sync() -> void:
	var date := Time.get_datetime_dict_from_system()
	for kind in KINDS:
		var key := period_key(kind, date)
		var bucket: Dictionary = records.get(kind, {})
		if str(bucket.get("key", "")) != key:
			records[kind] = {"key": key, "floor": 0}


## Nạp từ blob tiến trình; kỳ nào đã qua (khác mốc hiện tại) thì coi như 0.
func load_state(value: Variant) -> void:
	reset()
	if value is Dictionary:
		var saved: Dictionary = value
		for kind in KINDS:
			var bucket: Variant = saved.get(kind, null)
			if bucket is Dictionary:
				records[kind] = {
					"key": str(bucket.get("key", "")),
					"floor": maxi(int(bucket.get("floor", 0)), 0),
				}
	sync()


func reset() -> void:
	records = {
		"day": {"key": "", "floor": 0},
		"week": {"key": "", "floor": 0},
		"month": {"key": "", "floor": 0},
	}


## Khoá thời gian của kỳ `kind` cho một mốc ngày cụ thể:
##  · "day"   -> "2026-10-21"
##  · "week"  -> ngày THỨ HAI của tuần chứa mốc đó (tuần ISO bắt đầu từ thứ Hai)
##  · "month" -> "2026-10"
static func period_key(kind: String, date: Dictionary) -> String:
	match kind:
		"month":
			return "%04d-%02d" % [int(date.get("year", 1970)), int(date.get("month", 1))]
		"week":
			return _week_start_key(date)
		_:
			return _date_key(date)


## Khoá của kỳ hiện tại theo đồng hồ hệ thống
static func current_period_key(kind: String) -> String:
	return period_key(kind, Time.get_datetime_dict_from_system())


static func _date_key(date: Dictionary) -> String:
	return "%04d-%02d-%02d" % [
		int(date.get("year", 1970)), int(date.get("month", 1)), int(date.get("day", 1))]


## Ngày THỨ HAI của tuần chứa `date` (`weekday`: 0 = Chủ nhật … 6 = thứ Bảy như Godot).
## Lùi số ngày bằng unix-time để tự xử lý đúng khi lùi qua tháng/năm.
static func _week_start_key(date: Dictionary) -> String:
	var back := (int(date.get("weekday", 0)) + 6) % 7
	var stamp := Time.get_unix_time_from_datetime_dict({
		"year": int(date.get("year", 1970)),
		"month": int(date.get("month", 1)),
		"day": int(date.get("day", 1)),
		"hour": 0, "minute": 0, "second": 0,
	})
	return Time.get_date_string_from_unix_time(int(stamp) - back * 86400)
