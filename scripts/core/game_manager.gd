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

## LUỒNG HỌC LẦN ĐẦU (TutorialManager điều khiển — xem scripts/manager/TutorialManager.gd):
## bước đang ở trong chuỗi onboarding + đã học xong luồng chưa. Lưu cùng tiến trình để
## thoát giữa chừng vẫn chạy tiếp đúng bước ở lần mở sau.
var tutorial_flow_step: int = 0
var tutorial_flow_done: bool = false

## Ván đang chơi có phải là MÀN trong mạch màn Chọn màn không (khác Daily / Dungeon / Debug).
## Dùng để: (1) hiện nút SKIP LEVEL trên thanh hành động, (2) cho chế độ SPECIAL chạy trên
## BÀN DO NHÀ THIẾT KẾ VẼ của màn thay vì tự sinh bàn (xem BaseGameMode.designed_maze).
var level_run: bool = false

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

var tutorial_progress: Dictionary = {
	"first_time": false,
	"how_to_play_move": false,
	"how_to_play_checking_wall": false,
	"how_to_play_writting_hint": false,
	"core_completed": false,
	"how_to_play_minesweeper": false,
	"how_to_play_one_stroke": false,
	"how_to_play_sum_path": false,
	"how_to_play_wall_builder": false,
}


func is_tutorial_completed(tutorial_id: String) -> bool:
	return bool(tutorial_progress.get(tutorial_id, false))


## Ghi vị trí luồng onboarding (TutorialManager gọi sau mỗi bước / khi xong luồng)
func set_tutorial_flow(step: int, done: bool) -> void:
	tutorial_flow_step = clampi(step, 0, 64)
	tutorial_flow_done = done
	Save.queue_save()


func set_tutorial_completed(tutorial_id: String, completed := true) -> void:
	tutorial_progress[tutorial_id] = completed
	if tutorial_progress.get("first_time", false) and \
		tutorial_progress.get("how_to_play_move", false) and \
		tutorial_progress.get("how_to_play_checking_wall", false):
		tutorial_progress["core_completed"] = true


func mark_core_tutorials_completed() -> void:
	tutorial_progress["first_time"] = true
	tutorial_progress["how_to_play_move"] = true
	tutorial_progress["how_to_play_checking_wall"] = true
	tutorial_progress["how_to_play_writting_hint"] = true
	tutorial_progress["core_completed"] = true


## Yêu cầu MỞ THẲNG 1 bài khi vào màn Tutorial (Debug Console đặt rồi đổi scene).
## Giá trị: "" = chạy chuỗi mặc định · id bài · `TutorialController.REQUEST_CORE` = chuỗi CORE.
var pending_tutorial: String = ""
## Khi mở tutorial từ màn chơi: trả về game thay vì Main sau khi kết thúc
var pending_return_to_game: bool = false


func request_tutorial(tutorial_id: String) -> void:
	pending_tutorial = tutorial_id.strip_edges()


## Màn Tutorial đọc 1 lần rồi xoá yêu cầu (không giữ lại cho lần sau)
func take_tutorial_request() -> String:
	var requested := pending_tutorial
	pending_tutorial = ""
	return requested


func take_return_to_game_flag() -> bool:
	var flag := pending_return_to_game
	pending_return_to_game = false
	return flag


## Xoá tiến trình tutorial (Debug Console) — KHÔNG đụng tới tiến trình màn chơi
func reset_tutorial_progress() -> void:
	for key in tutorial_progress:
		tutorial_progress[key] = false
	tutorial_flow_step = 0
	tutorial_flow_done = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Khởi động Dungeon Mode
func start_dungeon() -> void:
	current_mode = "dungeon"
	current_difficulty = "medium"
	daily_variant = ""
	level_run = false
	debug_run = false
	start_floor_override = 0
	mode_changed.emit(current_mode)
	_change_scene("res://scenes/game.tscn")


## Khởi động 1 MÀN trong màn Chọn màn.
## Màn có thể ghi CHẾ ĐỘ riêng trong LevelData (`mode_id`) — vd màn 13 = "minesweeper" —
## khi đó ván chơi chạy bằng chế độ Special TRÊN BÀN DO NHÀ THIẾT KẾ VẼ (xem BaseGameMode.designed_maze).
## Màn không khai gì (hoặc khai id lạ) = chế độ Play như trước.
func start_level(level_id: int) -> void:
	prepare_level_run(level_id)
	if _open_mode_tutorial_once():
		return
	_change_scene("res://scenes/game.tscn")


## Nạp cấu hình 1 MÀN nhưng KHÔNG chuyển scene (test gọi được). Trả về mode id sẽ dùng.
func prepare_level_run(level_id: int) -> String:
	current_level = maxi(level_id, 1)
	current_difficulty = difficulty_of_level(current_level)
	current_mode = mode_id_of_level(current_level)
	daily_variant = ""
	level_run = true
	debug_run = false
	start_floor_override = 0
	mode_changed.emit(current_mode)
	return current_mode


## LevelData của màn (null nếu KHÔNG có file).
## LƯU Ý: `LevelManager.load_level()` tự TẠO file cho id lạ ⇒ phải hỏi `has_level()` trước,
## không thì chỉ cần hỏi mode của 1 id linh tinh là mọc thêm màn rác trong resources/levels.
func level_data_of(level_id: int) -> LevelData:
	var lm := get_node_or_null("/root/LevelManager")
	if lm == null or not lm.has_method("load_level"):
		return null
	if lm.has_method("has_level") and not bool(lm.call("has_level", level_id)):
		return null
	return lm.call("load_level", level_id) as LevelData


## Chế độ ghi trong màn (`play` nếu không khai hoặc khai id lạ)
## LƯU Ý: "dungeon" KHÔNG dùng được cho màn (chế độ bất tận, chỉ vào từ Main Screen) ⇒ coi như `play`.
func mode_id_of_level(level_id: int) -> String:
	var data := level_data_of(level_id)
	if data == null:
		return "play"
	var mode_id := str(data.mode_id).strip_edges().to_lower()
	if mode_id.is_empty() or mode_id == "dungeon" or not is_known_mode(mode_id):
		return "play"
	return mode_id


## Độ khó ghi trong màn (`medium` nếu không khai)
func difficulty_of_level(level_id: int) -> String:
	var data := level_data_of(level_id)
	if data == null or str(data.difficulty).is_empty():
		return "medium"
	return str(data.difficulty)


## id chế độ có tồn tại không (Play · Dungeon · Daily Classic · 8 chế độ Special)
func is_known_mode(mode_id: String) -> bool:
	if mode_id in ["play", "classic", "standard", "dungeon", "daily_classic"]:
		return true
	return DAILY_MODES.has(mode_id)


## SKIP MÀN: mở khoá màn KẾ TIẾP trong cùng chương nhưng **KHÔNG ghi Sao / thời gian**
## (người chơi bỏ qua màn đang chơi). Trả về id màn kế tiếp, -1 nếu đây là màn cuối chương.
func skip_level(level_id: int) -> int:
	var next_id := next_level_in_chapter(level_id)
	if next_id <= 0:
		return -1
	if next_id > unlocked_levels and is_chapter_unlocked(chapter_of_level(next_id)):
		unlocked_levels = next_id
		Save.queue_save()
	return next_id


## Khởi động Daily Mission theo ngày — MAZE ĐẶC BIỆT (mode xoay vòng của ngày)
func start_daily(day: int) -> void:
	prepare_daily_run(day, "special")
	if _open_mode_tutorial_once():
		return
	_change_scene("res://scenes/game.tscn")


## Khởi động Daily Mission theo ngày — MAZE THƯỜNG (classic)
func start_daily_classic(day: int) -> void:
	prepare_daily_run(day, "classic")
	if _open_mode_tutorial_once():
		return
	_change_scene("res://scenes/game.tscn")


## LẦN ĐẦU vào 1 chế độ Special (từ Daily hoặc từ màn có `mode_id`): mở bài học của chế
## độ trước rồi mới vào màn chơi (TutorialManager quyết định — xem `MODE_TUTORIALS`).
## Ván TEST từ Debug Console không tự mở tutorial.
func _open_mode_tutorial_once() -> bool:
	if debug_run:
		return false
	var tm := get_node_or_null("/root/TutorialManager")
	if tm == null or not tm.has_method("begin_mode_tutorial"):
		return false
	return bool(tm.call("begin_mode_tutorial", current_mode))


## [DEBUG/TEST] Chuẩn bị ván Daily nhưng KHÔNG chuyển scene.
## variant = "classic" (maze thường) hoặc "special" (maze đặc biệt của ngày).
## Trả về mode id sẽ dùng.
func prepare_daily_run(day: int, variant := "special") -> String:
	selected_daily_day = maxi(day, 1)
	daily_variant = "classic" if variant == "classic" else "special"
	current_difficulty = "medium"
	level_run = false
	debug_run = false
	start_floor_override = 0
	if daily_variant == "classic":
		current_mode = "daily_classic"
	else:
		var mode_index := (selected_daily_day - 1) % DAILY_MODES.size()
		current_mode = DAILY_MODES[mode_index]
	mode_changed.emit(current_mode)
	return current_mode


## Danh sách id của 8 chế độ SPECIAL (chỉ chơi được qua Daily Mission)
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
	level_run = false
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


## Điều hướng tới Màn hình Daily Mission
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
		"tutorial_progress": tutorial_progress.duplicate(),
		"tutorial_flow_step": tutorial_flow_step,
		"tutorial_flow_done": tutorial_flow_done,
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
	if data.has("tutorial_progress") and data["tutorial_progress"] is Dictionary:
		for k in (data["tutorial_progress"] as Dictionary):
			tutorial_progress[k] = bool(data["tutorial_progress"][k])
	tutorial_flow_step = clampi(int(data.get("tutorial_flow_step", 0)), 0, 64)
	if data.has("tutorial_flow_done"):
		tutorial_flow_done = bool(data["tutorial_flow_done"])
	else:
		# Save cũ (trước khi có luồng "bài học ⇄ màn thực hành"): ai đã học xong bộ CORE
		# thì coi như xong luồng, KHÔNG bắt học lại từ first_time.
		tutorial_flow_done = bool(tutorial_progress.get("core_completed", false))


func reset_progress() -> void:
	unlocked_levels = 1
	level_stars = { 1: 0 }
	level_best_time.clear()
	selected_daily_day = 1
	daily_variant = ""
	current_level = 1
	unlocked_chapters = [1]
	current_chapter = 1
	tutorial_flow_step = 0
	tutorial_flow_done = false
	for k in tutorial_progress:
		tutorial_progress[k] = false


## Chuyển Dictionary từ JSON về đúng kiểu khoá int (JSON biến khoá số thành chuỗi)
static func _int_key_dict(value: Variant, fallback: Dictionary, int_values: bool) -> Dictionary:
	if not (value is Dictionary):
		return fallback
	var out: Dictionary = {}
	for key in (value as Dictionary):
		var v: Variant = (value as Dictionary)[key]
		out[int(str(key))] = int(v) if int_values else float(v)
	return out
