class_name GameManagerClass
extends Node
## ============================================================================
## Manager: Quản lý phiên chơi, chế độ được chọn, tiến trình mở khóa màn
## và điều hướng chuyển đổi Scene trên toàn bộ game.
## ============================================================================

signal level_completed(level_id: int, stars: int, score: int)
signal mode_changed(new_mode: String)

var current_mode: String = "dungeon"
var current_difficulty: String = "medium"
var current_level: int = 1

# Tiến trình người chơi
var unlocked_levels: int = 1
var level_stars: Dictionary = { 1: 0 }    # level_id -> stars (1-3)
var level_best_time: Dictionary = {}     # level_id -> seconds
var selected_daily_day: int = 1

const DAILY_MODES: Array[String] = [
	"time_attack",
	"minesweeper",
	"sum_path",
	"countdown_cost",
	"blind_memory",
	"fog_of_war",
	"area"
]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Khởi động Dungeon Mode
func start_dungeon() -> void:
	current_mode = "dungeon"
	current_difficulty = "medium"
	mode_changed.emit(current_mode)
	_change_scene("res://scenes/game.tscn")


## Khởi động Level cụ thể trong Classic / Play Mode
func start_level(level_id: int) -> void:
	current_mode = "play"
	current_level = level_id
	current_difficulty = "medium"
	mode_changed.emit(current_mode)
	_change_scene("res://scenes/game.tscn")


## Khởi động Daily Challenge theo ngày
func start_daily(day: int) -> void:
	selected_daily_day = day
	var mode_index := (day - 1) % DAILY_MODES.size()
	current_mode = DAILY_MODES[mode_index]
	current_difficulty = "medium"
	mode_changed.emit(current_mode)
	_change_scene("res://scenes/game.tscn")


## Điều hướng tới Main Menu
func go_to_main_menu() -> void:
	_change_scene("res://scenes/main.tscn")


## Điều hướng tới Màn hình Chọn Màn
func go_to_levels() -> void:
	_change_scene("res://scenes/levels.tscn")


## Điều hướng tới Màn hình Daily Challenge
func go_to_daily() -> void:
	_change_scene("res://scenes/daily.tscn")


## Chuyển màn qua Nav/SceneManager (tự có SFX lật trang + ghi lịch sử cho nút Back)
func _change_scene(path: String) -> void:
	Nav.change_scene(path)


## Ghi nhận hoàn thành màn
func record_level_clear(level_id: int, stars: int, clear_time: float) -> void:
	var prev_stars: int = level_stars.get(level_id, 0)
	if stars > prev_stars:
		level_stars[level_id] = stars

	var prev_time: float = level_best_time.get(level_id, 999999.0)
	if clear_time < prev_time:
		level_best_time[level_id] = clear_time

	if level_id >= unlocked_levels and unlocked_levels < 9:
		unlocked_levels = level_id + 1

	# Lưu tiến trình (local, sẵn sàng đẩy lên Google Play sau này)
	Save.queue_save()
	level_completed.emit(level_id, stars, int(clear_time))


# ---------------------------------------------------------------------------
# Lưu trữ tiến trình (SaveManager gọi export_progress / import_progress)
# ---------------------------------------------------------------------------
func export_progress() -> Dictionary:
	return {
		"unlocked_levels": unlocked_levels,
		"level_stars": level_stars.duplicate(),
		"level_best_time": level_best_time.duplicate(),
		"selected_daily_day": selected_daily_day,
		"current_level": current_level,
	}


func import_progress(data: Dictionary) -> void:
	if data.is_empty():
		return
	unlocked_levels = maxi(int(data.get("unlocked_levels", unlocked_levels)), 1)
	level_stars = _int_key_dict(data.get("level_stars", null), level_stars, true)
	level_best_time = _int_key_dict(data.get("level_best_time", null), level_best_time, false)
	selected_daily_day = int(data.get("selected_daily_day", selected_daily_day))
	current_level = clampi(int(data.get("current_level", current_level)), 1, 9)


func reset_progress() -> void:
	unlocked_levels = 1
	level_stars = { 1: 0 }
	level_best_time.clear()
	selected_daily_day = 1
	current_level = 1


## Chuyển Dictionary từ JSON về đúng kiểu khoá int (JSON biến khoá số thành chuỗi)
static func _int_key_dict(value: Variant, fallback: Dictionary, int_values: bool) -> Dictionary:
	if not (value is Dictionary):
		return fallback
	var out: Dictionary = {}
	for key in (value as Dictionary):
		var v: Variant = (value as Dictionary)[key]
		out[int(str(key))] = int(v) if int_values else float(v)
	return out
