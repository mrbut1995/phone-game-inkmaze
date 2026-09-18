class_name GameManagerClass
extends Node
## ============================================================================
## Manager: Quản lý phiên chơi, chế độ được chọn, tiến trình mở khóa màn
## và điều hướng chuyển đổi Scene trên toàn bộ game.
## ============================================================================

signal level_completed(level_id: int, stars: int, score: int)
signal mode_changed(new_mode: String)
signal chapter_unlocked(chapter_id: int)

var current_mode: String = "dungeon"
var current_difficulty: String = "medium"
var current_level: int = 1

# Tiến trình người chơi
var unlocked_levels: int = 1
var level_stars: Dictionary = { 1: 0 }    # level_id -> stars (1-3)
var level_best_time: Dictionary = {}     # level_id -> seconds
var selected_daily_day: int = 1
## Loại ván Daily đang chơi: "" (không phải Daily) · "classic" (maze thường) · "special" (maze đặc biệt)
var daily_variant: String = ""
## CHƯƠNG: danh sách chương đã mở khóa + chương đang xem ở màn Chọn màn
var unlocked_chapters: Array[int] = [1]
var current_chapter: int = 1

# [DEBUG/TEST] Ván chơi thử (Debug Console): không ghi tiến trình, có thể ép tầng bắt đầu
var debug_run: bool = false
var start_floor_override: int = 0        # 0 = tự động (mode tự quyết định)

const DAILY_MODES: Array[String] = [
	"minesweeper",
	"sum_path",
	"countdown_cost",
	"blind_memory",
	"fog_of_war",
	"fading_ink",
	"one_stroke",
	"wall_builder"
]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Khởi động Dungeon Mode
func start_dungeon() -> void:
	current_mode = "dungeon"
	current_difficulty = "medium"
	daily_variant = ""
	debug_run = false
	start_floor_override = 0
	mode_changed.emit(current_mode)
	_change_scene("res://scenes/game.tscn")


## Khởi động Level cụ thể trong Classic / Play Mode
func start_level(level_id: int) -> void:
	current_mode = "play"
	current_level = level_id
	current_difficulty = "medium"
	daily_variant = ""
	debug_run = false
	start_floor_override = 0
	mode_changed.emit(current_mode)
	_change_scene("res://scenes/game.tscn")


## Khởi động Daily Challenge theo ngày — MAZE ĐẶC BIỆT (mode xoay vòng của ngày)
func start_daily(day: int) -> void:
	prepare_daily_run(day, "special")
	_change_scene("res://scenes/game.tscn")


## Khởi động Daily Challenge theo ngày — MAZE THƯỜNG (classic)
func start_daily_classic(day: int) -> void:
	prepare_daily_run(day, "classic")
	_change_scene("res://scenes/game.tscn")


## [DEBUG/TEST] Chuẩn bị ván Daily nhưng KHÔNG chuyển scene.
## variant = "classic" (maze thường) hoặc "special" (maze đặc biệt của ngày).
## Trả về mode id sẽ dùng.
func prepare_daily_run(day: int, variant := "special") -> String:
	selected_daily_day = maxi(day, 1)
	daily_variant = "classic" if variant == "classic" else "special"
	current_difficulty = "medium"
	debug_run = false
	start_floor_override = 0
	if daily_variant == "classic":
		current_mode = "daily_classic"
	else:
		var mode_index := (selected_daily_day - 1) % DAILY_MODES.size()
		current_mode = DAILY_MODES[mode_index]
	mode_changed.emit(current_mode)
	return current_mode


## Danh sách id của 8 chế độ SPECIAL (chỉ chơi được qua Daily Challenge)
func special_mode_ids() -> Array[String]:
	return DAILY_MODES.duplicate()


## [DEBUG/TEST] Chuẩn bị 1 ván test nhưng KHÔNG chuyển scene (để test gọi được).
##   test_run = true  -> không đánh dấu Daily, không tính vào danh hiệu
##   floor_override   -> bắt đầu ở tầng đó (0 = mặc định tầng 1) — để thử bàn to/nhỏ
func prepare_mode_run(mode_id: String, difficulty := "medium", test_run := false,
		floor_override := 0) -> void:
	current_mode = mode_id
	current_difficulty = difficulty
	daily_variant = ""
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


## Điều hướng tới Màn hình CHỌN CHƯƠNG (bước trước màn Chọn màn)
func go_to_chapters() -> void:
	_change_scene("res://scenes/chapters.tscn")


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
		# Mở khoá màn kế tiếp nếu màn đó THẬT SỰ tồn tại VÀ thuộc chương ĐÃ MỞ
		# (tránh nhảy sang màn của chương chưa unlock khi màn cuối chương vừa hoàn thành)
		var next_id := level_id + 1
		var lm: Node = get_node_or_null("/root/LevelManager")
		var has_next := true
		if lm != null and lm.has_method("has_level"):
			has_next = bool(lm.call("has_level", next_id))
		else:
			has_next = next_id <= 9
		if has_next and is_chapter_unlocked(chapter_of_level(next_id)):
			unlocked_levels = maxi(unlocked_levels, next_id)

	# Lưu tiến trình (local, sẵn sàng đẩy lên Google Play sau này)
	Save.queue_save()
	level_completed.emit(level_id, stars, int(clear_time))


# ---------------------------------------------------------------------------
# CHƯƠNG (màn "CHỌN CHƯƠNG")
# ---------------------------------------------------------------------------
## Tổng Sao đã đạt trong TOÀN BỘ màn (dùng làm điều kiện mở khóa chương)
func total_stars() -> int:
	var total := 0
	for value in level_stars.values():
		total += int(value)
	return total


## Chương 1 luôn mở; các chương khác phải được mở bằng Sao
func is_chapter_unlocked(chapter_id: int) -> bool:
	if chapter_id <= 1:
		return true
	return unlocked_chapters.has(chapter_id)


## Số Sao cần để mở chương này (0 = không cần điều kiện)
func chapter_star_cost(chapter_id: int) -> int:
	var lm := get_node_or_null("/root/LevelManager")
	if lm == null or not lm.has_method("get_chapter"):
		return 0
	var data: Variant = lm.call("get_chapter", chapter_id)
	return maxi(int(data.get("star_cost")) if data != null else 0, 0)


## Đủ Sao để mở chưa (chương đã mở cũng coi như đủ)
func can_unlock_chapter(chapter_id: int) -> bool:
	if is_chapter_unlocked(chapter_id):
		return true
	return total_stars() >= chapter_star_cost(chapter_id)


## Mở khóa chương bằng Sao — trả về true nếu VỪA mở
func unlock_chapter(chapter_id: int) -> bool:
	if is_chapter_unlocked(chapter_id) or not can_unlock_chapter(chapter_id):
		return false
	unlocked_chapters.append(chapter_id)
	chapter_unlocked.emit(chapter_id)
	Save.queue_save()
	return true


## Đổi chương đang xem ở màn Chọn màn
func set_chapter(chapter_id: int) -> void:
	current_chapter = maxi(chapter_id, 1)


## Chương chứa màn này (1 nếu không có LevelManager)
func chapter_of_level(level_id: int) -> int:
	var lm := get_node_or_null("/root/LevelManager")
	if lm != null and lm.has_method("chapter_of_level"):
		return maxi(int(lm.call("chapter_of_level", level_id)), 1)
	return 1


## Màn kế tiếp TRONG CÙNG CHƯƠNG (-1 nếu đây là màn cuối của chương)
## Màn chọn màn / popup thắng dựa vào đây để KHÔNG nhảy sang chương khác.
func next_level_in_chapter(level_id: int) -> int:
	var lm := get_node_or_null("/root/LevelManager")
	if lm == null or not lm.has_method("levels_in_chapter"):
		return level_id + 1 if level_id < 9 else -1
	var ids: Array = lm.call("levels_in_chapter", chapter_of_level(level_id))
	var index := ids.find(level_id)
	if index < 0 or index + 1 >= ids.size():
		return -1
	return int(ids[index + 1])


## Màn này có bấm chơi được ngay không: file tồn tại + chương ĐÃ MỞ + đã mở theo tiến trình
func can_play_level(level_id: int) -> bool:
	if level_id < 1 or not is_chapter_unlocked(chapter_of_level(level_id)):
		return false
	var lm := get_node_or_null("/root/LevelManager")
	if lm != null and lm.has_method("has_level") and not bool(lm.call("has_level", level_id)):
		return false
	return level_id <= unlocked_levels


## Có chương nào ĐỦ Sao để mở mà chưa mở không (màn Chọn màn nhấp nháy banner báo tin)
func has_unlockable_chapter() -> bool:
	var lm := get_node_or_null("/root/LevelManager")
	if lm == null or not lm.has_method("get_chapters"):
		return false
	for chapter in lm.call("get_chapters"):
		var chapter_id := maxi(int(chapter.get("chapter_id")), 1)
		if not is_chapter_unlocked(chapter_id) and can_unlock_chapter(chapter_id):
			return true
	return false


## Chuyển Array từ JSON (số có thể là chuỗi/float) về Array[int] duy nhất
static func _int_array(value: Variant) -> Array[int]:
	var out: Array[int] = []
	if value is Array:
		for item in value:
			var id := int(item)
			if id > 0 and not out.has(id):
				out.append(id)
	return out


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
		"unlocked_chapters": unlocked_chapters.duplicate(),
		"current_chapter": current_chapter,
	}


func import_progress(data: Dictionary) -> void:
	if data.is_empty():
		return
	unlocked_levels = maxi(int(data.get("unlocked_levels", unlocked_levels)), 1)
	level_stars = _int_key_dict(data.get("level_stars", null), level_stars, true)
	level_best_time = _int_key_dict(data.get("level_best_time", null), level_best_time, false)
	selected_daily_day = int(data.get("selected_daily_day", selected_daily_day))
	current_level = maxi(int(data.get("current_level", current_level)), 1)
	unlocked_chapters = _int_array(data.get("unlocked_chapters", null))
	if unlocked_chapters.is_empty():
		unlocked_chapters = [1]
	elif not unlocked_chapters.has(1):
		unlocked_chapters.append(1)
	current_chapter = maxi(int(data.get("current_chapter", current_chapter)), 1)


func reset_progress() -> void:
	unlocked_levels = 1
	level_stars = { 1: 0 }
	level_best_time.clear()
	selected_daily_day = 1
	daily_variant = ""
	current_level = 1
	unlocked_chapters = [1]
	current_chapter = 1


## Chuyển Dictionary từ JSON về đúng kiểu khoá int (JSON biến khoá số thành chuỗi)
static func _int_key_dict(value: Variant, fallback: Dictionary, int_values: bool) -> Dictionary:
	if not (value is Dictionary):
		return fallback
	var out: Dictionary = {}
	for key in (value as Dictionary):
		var v: Variant = (value as Dictionary)[key]
		out[int(str(key))] = int(v) if int_values else float(v)
	return out
