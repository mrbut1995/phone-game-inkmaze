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

# [DEBUG/TEST] Ván chơi thử (Debug Console): không ghi tiến trình, có thể ép tầng bắt đầu
var debug_run: bool = false
var start_floor_override: int = 0        # 0 = tự động (mode tự quyết định)

const DAILY_MODES: Array[String] = [
	"time_attack",
	"minesweeper",
	"sum_path",
	"countdown_cost",
	"blind_memory",
	"fog_of_war",
	"fading_ink"
]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Khởi động Dungeon Mode
func start_dungeon() -> void:
	current_mode = "dungeon"
	current_difficulty = "medium"
	debug_run = false
	start_floor_override = 0
	mode_changed.emit(current_mode)
	_change_scene("res://scenes/game.tscn")


## Khởi động Level cụ thể trong Classic / Play Mode
func start_level(level_id: int) -> void:
	current_mode = "play"
	current_level = level_id
	current_difficulty = "medium"
	debug_run = false
	start_floor_override = 0
	mode_changed.emit(current_mode)
	_change_scene("res://scenes/game.tscn")


## Khởi động Daily Challenge theo ngày
func start_daily(day: int) -> void:
	selected_daily_day = day
	var mode_index := (day - 1) % DAILY_MODES.size()
	current_mode = DAILY_MODES[mode_index]
	current_difficulty = "medium"
	debug_run = false
	start_floor_override = 0
	mode_changed.emit(current_mode)
	_change_scene("res://scenes/game.tscn")


## Danh sách id của 7 chế độ SPECIAL (chỉ chơi được qua Daily Challenge)
func special_mode_ids() -> Array[String]:
	return DAILY_MODES.duplicate()


## [DEBUG/TEST] Chuẩn bị 1 ván test nhưng KHÔNG chuyển scene (để test gọi được).
##   test_run = true  -> không đánh dấu Daily, không tính vào danh hiệu
##   floor_override   -> bắt đầu ở tầng đó (0 = mặc định tầng 1) — để thử bàn to/nhỏ
func prepare_mode_run(mode_id: String, difficulty := "medium", test_run := false,
		floor_override := 0) -> void:
	current_mode = mode_id
	current_difficulty = difficulty
	debug_run = test_run
	start_floor_override = maxi(floor_override, 0)
	mode_changed.emit(current_mode)


## [DEBUG/TEST] Vào thẳng 1 chế độ bất kỳ (kể cả 7 chế độ Special) — dùng cho Debug Console
func start_mode(mode_id: String, difficulty := "medium", test_run := false,
		floor_override := 0) -> void:
	prepare_mode_run(mode_id, difficulty, test_run, floor_override)
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

	if level_id >= unlocked_levels:
		# Mở khoá màn kế tiếp nếu màn đó thật sự tồn tại (danh sách màn có thể > 9)
		var next_id := level_id + 1
		var lm: Node = get_node_or_null("/root/LevelManager")
		var has_next := true
		if lm != null and lm.has_method("has_level"):
			has_next = bool(lm.call("has_level", next_id))
		else:
			has_next = next_id <= 9
		if has_next:
			unlocked_levels = maxi(unlocked_levels, next_id)

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
