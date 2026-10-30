class_name GameManagerClass
extends Node
## ============================================================================
## Manager: Quản lý phiên chơi, chế độ được chọn, tiến trình mở khóa màn
## và điều hướng chuyển đổi Scene trên toàn bộ game.
## ============================================================================

signal level_completed(level_id: int, stars: int, score: int)
signal mode_changed(new_mode: String)
signal chapter_unlocked(chapter_id: int)
signal tool_inventory_changed(tool_id: String, remaining: int)
## Lượt chơi (life) đổi — LifeChip trên thanh trên nghe signal này để tự cập nhật
signal life_changed(lives: int, max_lives: int)
## Kỷ lục tầng của một kỳ ("day" · "week" · "month") vừa được nâng lên
signal floor_record_changed(kind: String, floor_number: int)
## Vừa nhận thưởng một RƯƠNG MỐC của chương (chapter_id, index 0..2)
signal chapter_chest_claimed(chapter_id: int, index: int)

const TOOL_SKIP := "skip"
const TOOL_UNDO := "undo"
const TOOL_HINT := "hint"
const TOOL_IDS: Array[String] = [TOOL_SKIP, TOOL_UNDO, TOOL_HINT]
const INITIAL_TOOL_USES := 3
## Scene của ván chơi (mọi chế độ đều vào đây)
const GAME_SCENE := "res://scenes/game.tscn"

var current_mode: String = "dungeon"
var current_difficulty: String = "medium"
var current_level: int = 1
## Số lượt dùng công cụ còn lại trên TOÀN BỘ trò chơi, không được cấp lại theo màn/tầng.
var tool_uses: Dictionary = {
	TOOL_SKIP: INITIAL_TOOL_USES,
	TOOL_UNDO: INITIAL_TOOL_USES,
	TOOL_HINT: INITIAL_TOOL_USES,
}

# ---------------------------------------------------------------------------
# LƯỢT CHƠI (life) — dùng chung TOÀN BỘ trò chơi
#   · Mỗi ván THUA mà người chơi KHÔNG thử lại (bỏ qua popup Retry) = mất 1 lượt.
#   · Còn lượt mới vào được ván nào (Play / Dungeon / Daily / Event / Special).
#   · Hết lượt: mỗi 30 phút hồi 1 lượt; mua ở Cửa hàng hoặc thưởng nhiệm vụ cũng cộng lượt.
# ---------------------------------------------------------------------------
const MAX_LIVES := 5
## Thời gian hồi 1 lượt (giây) — 30 phút
const LIFE_RECHARGE_SECONDS := 30 * 60
## Nguồn hợp lệ khi cộng lượt chơi (mua hàng · nhiệm vụ · mốc thưởng Daily · rương mốc chương)
const LIFE_GRANT_SOURCES: Array[String] = ["purchase", "mission", "daily_milestone", "chapter_chest"]

## Trạng thái lượt chơi nằm ở `LifeStore` (xem `scripts/core/life_store.gd`);
## dưới đây chỉ còn cửa ngõ công khai để mọi script cũ không phải đổi.
var _life := LifeStore.new()
var _life_tick := 0.0

## [TEST/DEBUG] Ép kết quả `can_start_run()`: 0 = theo lượt chơi · 1 = luôn cho vào · -1 = luôn chặn
var life_gate_override: int:
	get:
		return _life.gate_override
	set(value):
		_life.gate_override = value

## [TEST] Cho phép trừ lượt khi chạy test runner tự động (mặc định: test KHÔNG trừ lượt,
## để bộ test không làm cạn lượt của người chơi thật)
var life_cost_in_tests: bool:
	get:
		return _life.charge_in_tests
	set(value):
		_life.charge_in_tests = value

## Màn cần quay về sau khi vào Cửa hàng từ popup "hết lượt" (rỗng = không có)
var shop_return_path: String = ""

# ---------------------------------------------------------------------------
# KỶ LỤC TẦNG CAO NHẤT — theo NGÀY / TUẦN / THÁNG
#   · Chỉ tính tầng của ván VÔ TẬN (Dungeon) vì đó mới là "tầng" tăng dần vô hạn.
#   · Mỗi kỳ giữ `key` (mốc thời gian) + `floor`: sang ngày/tuần/tháng mới thì tự về 0.
#   · `week` dùng mốc THỨ HAI của tuần (ISO) để tuần luôn bắt đầu từ thứ Hai.
# ---------------------------------------------------------------------------
const FLOOR_RECORD_KINDS: Array[String] = ["day", "week", "month"]
## Kỷ lục tầng nằm ở `FloorRecordsStore` (xem `scripts/core/floor_records_store.gd`)
var _records := FloorRecordsStore.new()
## [TEST] Cho phép ghi kỷ lục khi chạy test runner tự động (mặc định: test KHÔNG ghi,
## để bộ test không làm bẩn kỷ lục của người chơi thật)
var floor_record_in_tests: bool:
	get:
		return _records.record_in_tests
	set(value):
		_records.record_in_tests = value

# ---------------------------------------------------------------------------
# RƯƠNG MỐC THƯỞNG CỦA CHƯƠNG (tầng B của "Chiến lược thưởng chế độ Play")
#   · 3 rương nằm trên thanh tiến độ ở màn Chọn chương, mốc theo TỈ LỆ Sao của chương
#     (33% · 67% · 100% ⇒ chương 27★ được 9★/18★/27★).
#   · Mỗi rương nhận ĐÚNG MỘT LẦN cho mỗi chương (idempotent, không farm bằng chơi lại).
# ---------------------------------------------------------------------------
const CHAPTER_CHEST_RATIOS: Array[float] = [0.33, 0.67, 1.0]
## Thưởng theo planning §2 (Xu · lượt công cụ · 1 lượt chơi ở rương cuối)
const CHAPTER_CHEST_REWARDS: Array[Dictionary] = [
	{"coins": 50},
	{"hint": 2, "undo": 1},
	{"coins": 150, "life": 1},
]
## chapter_id -> Array[int] các mốc (0..2) đã nhận
var chapter_chests: Dictionary = {}

# Tiến trình người chơi
var unlocked_levels: int = 1
var level_stars: Dictionary = { 1: 0 }    # level_id -> stars (1-3)
var level_best_time: Dictionary = {}     # level_id -> seconds
var selected_daily_day: int = 1
## Loại ván Daily đang chơi: "" (không phải Daily) · "classic" (maze thường) ·
## "challenge" (1 game thử thách của ngày) · "special" (maze đặc biệt của ngày)
var daily_variant: String = ""
## Daily: đang chơi GAME thứ mấy của ngày (0..2) — -1 = không thuộc game nào (ván special / chơi tự do)
var daily_game: int = -1
## Daily: luật thử thách của game đang chơi (rỗng nếu không phải game challenge)
var daily_challenge_id: String = ""
## Ván Daily VỪA THẮNG trong phiên này — màn Daily đọc 1 LẦN để chạy hiệu ứng Sao
## trên đúng thẻ vừa chơi. `{ day: int, challenge: bool, stars: int, gained: int }` ·
## rỗng = không có gì để ăn mừng.
var daily_celebrate: Dictionary = {}
## CHƯƠNG: danh sách chương đã mở khóa + chương đang xem ở màn Chọn màn
var unlocked_chapters: Array[int] = [1]
var current_chapter: int = 1

# [DEBUG/TEST] Ván chơi thử (Debug Console): không ghi tiến trình, có thể ép tầng bắt đầu
var debug_run: bool = false
var start_floor_override: int = 0        # 0 = tự động (mode tự quyết định)

## LUỒNG HỌC LẦN ĐẦU (TutorialManager điều khiển — xem scripts/autoload/TutorialManager.gd):
## bước đang ở trong chuỗi onboarding + đã học xong luồng chưa. Lưu cùng tiến trình để
## thoát giữa chừng vẫn chạy tiếp đúng bước ở lần mở sau.
var tutorial_flow_step: int = 0
var tutorial_flow_done: bool = false

## Ván đang chơi có phải là MÀN trong mạch màn Chọn màn không (khác Daily / Dungeon / Debug).
## Dùng để: (1) hiện nút SKIP LEVEL trên thanh hành động, (2) cho chế độ SPECIAL chạy trên
## BÀN DO NHÀ THIẾT KẾ VẼ của màn thay vì tự sinh bàn (xem BaseGameMode.designed_maze).
var level_run: bool = false

## EVENT: id sự kiện đang chơi (rỗng = không phải ván sự kiện) + LevelData của màn event.
## Ván sự kiện KHÔNG ghi Sao/mở khoá vào mạch màn thường (xem `record_level_clear`).
var current_event_id: StringName = &""
var event_level: LevelData = null

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
## Khi mở tutorial từ DANH SÁCH bài học: Back/xong ⇒ về lại danh sách (không về Main)
var pending_return_to_list: bool = false


## `from_list = true` khi người chơi bấm 1 bài ở màn DANH SÁCH (`scenes/tutorial_list.tscn`)
func request_tutorial(tutorial_id: String, from_list := false) -> void:
	pending_tutorial = tutorial_id.strip_edges()
	pending_return_to_list = from_list


## Màn Tutorial đọc 1 lần rồi xoá yêu cầu (không giữ lại cho lần sau)
func take_tutorial_request() -> String:
	var requested := pending_tutorial
	pending_tutorial = ""
	return requested


func take_return_to_game_flag() -> bool:
	var flag := pending_return_to_game
	pending_return_to_game = false
	return flag


func take_return_to_list_flag() -> bool:
	var flag := pending_return_to_list
	pending_return_to_list = false
	return flag


## Xoá tiến trình tutorial (Debug Console) — KHÔNG đụng tới tiến trình màn chơi
func reset_tutorial_progress() -> void:
	for key in tutorial_progress:
		tutorial_progress[key] = false
	tutorial_flow_step = 0
	tutorial_flow_done = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_life.changed.connect(_on_life_changed)


## Số lượt đổi (hồi theo giờ mua · thưởng · thua) ⇒ phát cho UI + hẹn lưu
func _on_life_changed(current: int, max_value: int) -> void:
	life_changed.emit(current, max_value)
	Save.queue_save()


## Đồng hồ hồi lượt chạy cả khi đang ở menu (và bắt kịp thời gian offline khi vào lại game)
func _process(delta: float) -> void:
	_life_tick += delta
	if _life_tick < 0.5:
		return
	_life_tick = 0.0
	_life.refresh()


## Khởi động Dungeon Mode
func start_dungeon() -> void:
	clear_event_run()
	current_mode = "dungeon"
	current_difficulty = "medium"
	daily_variant = ""
	level_run = false
	debug_run = false
	start_floor_override = 0
	mode_changed.emit(current_mode)
	_enter_game_scene()


## Khởi động 1 MÀN trong màn Chọn màn.
## Màn có thể ghi CHẾ ĐỘ riêng trong LevelData (`mode_id`) — vd màn 13 = "minesweeper" —
## khi đó ván chơi chạy bằng chế độ Special TRÊN BÀN DO NHÀ THIẾT KẾ VẼ (xem BaseGameMode.designed_maze).
## Màn không khai gì (hoặc khai id lạ) = chế độ Play như trước.
func start_level(level_id: int) -> void:
	clear_event_run()
	prepare_level_run(level_id)
	if _open_mode_tutorial_once():
		return
	_enter_game_scene()


## Chơi 1 MÀN của SỰ KIỆN (LevelData truyền thẳng, không tra theo id — §B7).
## Màn event dùng id riêng (1000+) nằm ngoài danh sách chương và KHÔNG ảnh hưởng mở khoá Sao.
func start_level_from_event(level: LevelData, event_id: StringName) -> void:
	if level == null:
		return
	event_level = level
	current_event_id = event_id
	current_level = maxi(level.level_id, 1)
	current_difficulty = str(level.difficulty) if not str(level.difficulty).is_empty() else "medium"
	current_mode = _mode_of_level_data(level)
	daily_variant = ""
	level_run = true
	debug_run = false
	start_floor_override = 0
	mode_changed.emit(current_mode)
	_enter_game_scene()


## Xoá trạng thái ván sự kiện (gọi khi bắt đầu ván KHÔNG phải event)
func clear_event_run() -> void:
	current_event_id = &""
	event_level = null


## Đọc + XOÁ trạng thái "vừa thắng ván Daily" (màn Daily gọi 1 lần để chạy hiệu ứng Sao).
## Rỗng = không có gì để ăn mừng (ván không phải Daily, hoặc vừa ăn mừng xong).
func take_daily_celebrate() -> Dictionary:
	var info := daily_celebrate
	daily_celebrate = {}
	return info


## Chế độ của 1 LevelData ("play" nếu không khai hoặc khai id lạ — khớp mode_id_of_level)
func _mode_of_level_data(data: LevelData) -> String:
	if data == null:
		return "play"
	var mode_id := str(data.mode_id).strip_edges().to_lower()
	if mode_id.is_empty() or mode_id == "dungeon" or not is_known_mode(mode_id):
		return "play"
	return mode_id


## Nạp cấu hình 1 MÀN nhưng KHÔNG chuyển scene (test gọi được). Trả về mode id sẽ dùng.
func prepare_level_run(level_id: int) -> String:
	clear_event_run()
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
	# Ván SỰ KIỆN: màn event không nằm trong danh sách chương → trả LevelData đã truyền vào
	if event_level != null and not current_event_id.is_empty() and level_id == current_level:
		return event_level
	var lm := Svc.level()
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
	if mode_id in ["play", "classic", "standard", "challenge", "dungeon", "daily_classic", "daily_challenge"]:
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


## Số lượt còn lại của công cụ trên toàn tài khoản người chơi.
func tool_uses_left(tool_id: String) -> int:
	if not TOOL_IDS.has(tool_id):
		return 0
	return maxi(int(tool_uses.get(tool_id, 0)), 0)


## Tiêu thụ một lượt dùng. Trả false khi công cụ không hợp lệ hoặc đã hết lượt.
func consume_tool_use(tool_id: String) -> bool:
	if not TOOL_IDS.has(tool_id) or tool_uses_left(tool_id) <= 0:
		return false
	tool_uses[tool_id] = tool_uses_left(tool_id) - 1
	tool_inventory_changed.emit(tool_id, tool_uses_left(tool_id))
	Save.queue_save()
	return true


## Nguồn hợp lệ khi cấp lượt dùng công cụ: mua ở Shop, thưởng nhiệm vụ, thưởng mốc Sao Daily
const GRANT_SOURCES: Array[String] = ["purchase", "mission", "daily_milestone", "chapter_chest"]


## Cấp lượt từ nguồn mua hàng/nhiệm vụ/mốc thưởng Daily.
func grant_tool_uses(tool_id: String, amount: int, source: String) -> bool:
	if not TOOL_IDS.has(tool_id) or amount <= 0 or not GRANT_SOURCES.has(source):
		return false
	return _set_tool_uses(tool_id, tool_uses_left(tool_id) + amount)


## Chỉnh số dư trong Debug Console; giá trị được lưu như tiến trình người chơi.
func debug_set_tool_uses(tool_id: String, amount: int) -> bool:
	if not OS.is_debug_build():
		push_warning("[GameManager] Chi cho phep chinh so du cong cu trong debug build")
		return false
	return _set_tool_uses(tool_id, amount)


func _set_tool_uses(tool_id: String, amount: int) -> bool:
	if not TOOL_IDS.has(tool_id):
		push_warning("[GameManager] Cong cu khong hop le: '%s'" % tool_id)
		return false
	var remaining := maxi(amount, 0)
	if tool_uses_left(tool_id) == remaining:
		return true
	tool_uses[tool_id] = remaining
	tool_inventory_changed.emit(tool_id, remaining)
	Save.queue_save()
	return true


# ---------------------------------------------------------------------------
# LƯỢT CHƠI (life)
# ---------------------------------------------------------------------------
func max_lives() -> int:
	return _life.max_lives()


## Số lượt còn lại (đã tính cả lượt vừa hồi theo thời gian)
func lives_left() -> int:
	return _life.lives_left()


func has_life() -> bool:
	return _life.has_life()


## Giây còn lại tới lượt kế tiếp (0 = đang đầy lượt)
func seconds_to_next_life() -> int:
	return _life.seconds_to_next_life()


## Trừ 1 lượt khi THUA chốt ván. Trả về true nếu vừa trừ.
func consume_life() -> bool:
	return _life.consume_life()


## Chốt MỘT lần thua cho mỗi ván (UIController gọi khi popup thua cuối cùng hiện ra).
## Ván Debug Console / test runner tự động không bị trừ lượt.
func register_run_loss() -> bool:
	if debug_run:
		return false
	if _is_automated_test() and not _life.charge_in_tests:
		return false
	return _life.charge_loss_once()


## Đang chạy bộ test tự động (tiến trình chạy bằng `--script` trỏ tới `scripts/test_case/`) hay không
func _is_automated_test() -> bool:
	var main_loop := Engine.get_main_loop()
	if main_loop == null:
		return false
	var script: Variant = main_loop.get_script()
	return script != null and str(script.resource_path).contains("test_case")


## Ván mới bắt đầu (kể cả bấm Thử lại) ⇒ ván sau lại được trừ lượt khi thua
func begin_run_guard() -> void:
	_life.begin_run_guard()


## Cộng lượt từ nguồn hợp lệ (mua ở Cửa hàng · thưởng nhiệm vụ · mốc Sao Daily).
## Trả về false khi nguồn không hợp lệ hoặc đã đầy lượt.
func grant_lives(amount: int, source: String) -> bool:
	return _life.grant_lives(amount, source)


## Chỉnh số lượt trong Debug Console (chỉ debug build)
func debug_set_lives(amount: int) -> bool:
	if not OS.is_debug_build():
		push_warning("[GameManager] Chi cho phep chinh luot choi trong debug build")
		return false
	_life.set_lives(amount)
	return true


## [DEBUG] Đẩy nhanh đồng hồ hồi lượt để thử luồng hồi lượt (giây)
func debug_advance_life_recharge(seconds: int) -> void:
	if not OS.is_debug_build():
		return
	_life.advance_recharge(seconds)


## Còn lượt thì mới được vào ván (ván Debug/test bỏ qua kiểm tra)
func can_start_run() -> bool:
	if _life.gate_override != 0:
		return _life.gate_override > 0
	if debug_run or _is_automated_test():
		return true
	return _life.lives_left() > 0


## Vào Cửa hàng từ popup "hết lượt": nhớ màn hiện tại để nút Back của Shop quay lại đúng màn đó.
func request_shop_from_life_gate() -> void:
	var scene := get_tree().current_scene if is_inside_tree() else null
	shop_return_path = scene.scene_file_path if scene != null else ""
	Nav.goto_shop()


## Shop đọc 1 lần rồi xoá: màn cần quay về sau khi xem Cửa hàng ("" = không có yêu cầu)
func take_shop_return_path() -> String:
	var path := shop_return_path
	shop_return_path = ""
	return path


# ---------------------------------------------------------------------------
# KỶ LỤC TẦNG — ngày / tuần / tháng
# ---------------------------------------------------------------------------

## Khoá thời gian của kỳ `kind` cho một mốc ngày cụ thể (xem `FloorRecordsStore.period_key`)
static func period_key(kind: String, date: Dictionary) -> String:
	return FloorRecordsStore.period_key(kind, date)


## Khoá của kỳ hiện tại theo đồng hồ hệ thống
static func current_period_key(kind: String) -> String:
	return FloorRecordsStore.current_period_key(kind)


## Tầng cao nhất đạt được trong kỳ hiện tại (0 = chưa có kỷ lục). Kỳ đã đổi thì đọc ra 0.
func best_floor(kind := "week") -> int:
	return _records.best(kind)


## Ghi nhận vừa ĐẠT tới `floor_number` (gọi khi vào tầng mới của ván Dungeon).
## Trả về true nếu có ít nhất một kỳ (ngày/tuần/tháng) lập kỷ lục mới.
func record_floor_reached(floor_number := 0) -> bool:
	if floor_number <= 0 or debug_run:
		return false
	if _is_automated_test() and not _records.record_in_tests:
		return false
	var improved := _records.reach(floor_number)
	for kind in improved:
		floor_record_changed.emit(kind, floor_number)
	return not improved.is_empty()


# ---------------------------------------------------------------------------
# RƯƠNG MỐC THƯỞNG CỦA CHƯƠNG
# ---------------------------------------------------------------------------

## 3 định nghĩa rương của một chương có `stars_total` Sao tối đa.
## Mỗi phần tử: `{ index, stars, coins, hint, undo, skip, life }` (`stars` = ngưỡng Sao cần).
func chapter_chest_defs(stars_total: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var total := maxi(stars_total, 0)
	for i in CHAPTER_CHEST_REWARDS.size():
		var def: Dictionary = (CHAPTER_CHEST_REWARDS[i] as Dictionary).duplicate(true)
		def["index"] = i
		def["stars"] = chest_threshold(CHAPTER_CHEST_RATIOS[i], total)
		out.append(def)
	return out


## Ngưỡng Sao của một mốc = `ratio × tổng Sao chương` (làm tròn), kẹp trong [1, tổng].
## Chương 27★: 33% → 9★ · 67% → 18★ · 100% → 27★ (đúng tinh thần mốc 10/20/30 của planning).
static func chest_threshold(ratio: float, stars_total: int) -> int:
	if stars_total <= 0:
		return 0
	if ratio >= 1.0:
		return stars_total
	return clampi(roundi(stars_total * ratio), 1, stars_total)


## Các mốc đã nhận của chương (bản sao — UI không sửa được dữ liệu gốc)
func claimed_chapter_chests(chapter_id: int) -> Array[int]:
	var out: Array[int] = []
	var saved: Variant = chapter_chests.get(chapter_id, null)
	if saved is Array:
		for item in saved:
			out.append(int(item))
	return out


func is_chapter_chest_claimed(chapter_id: int, index: int) -> bool:
	return claimed_chapter_chests(chapter_id).has(index)


## Đủ Sao + chưa nhận ⇒ nhận được rương này
func can_claim_chapter_chest(chapter_id: int, index: int, stars_own: int, stars_total: int) -> bool:
	var defs := chapter_chest_defs(stars_total)
	if chapter_id < 1 or index < 0 or index >= defs.size():
		return false
	if is_chapter_chest_claimed(chapter_id, index):
		return false
	return stars_own >= int((defs[index] as Dictionary).get("stars", 0))


## Nhận thưởng rương mốc của chương. Trả về định nghĩa rương ĐÃ TRAO ({} nếu không nhận được).
func claim_chapter_chest(chapter_id: int, index: int, stars_own: int, stars_total: int) -> Dictionary:
	if not can_claim_chapter_chest(chapter_id, index, stars_own, stars_total):
		return {}
	var def: Dictionary = (chapter_chest_defs(stars_total)[index] as Dictionary).duplicate(true)
	# Đánh dấu ĐÃ NHẬN TRƯỚC khi trao (tránh nhận 2 lần nếu UI bấm liên tiếp)
	var claimed := claimed_chapter_chests(chapter_id)
	claimed.append(index)
	chapter_chests[chapter_id] = claimed
	_grant_chapter_chest(def)
	chapter_chest_claimed.emit(chapter_id, index)
	Save.queue_save()
	return def


## Trao thưởng của một rương: Xu (ví chung) + lượt công cụ + lượt chơi (qua API có nguồn)
func _grant_chapter_chest(def: Dictionary) -> void:
	var coins := int(def.get("coins", 0))
	if coins > 0:
		var wallet: Node = Svc.achievement()
		if wallet != null:
			wallet.set("coins", maxi(int(wallet.get("coins")) + coins, 0))
			if wallet.has_method("notify_coins_changed"):
				wallet.call("notify_coins_changed")
	for tool_id in TOOL_IDS:
		var amount := int(def.get(tool_id, 0))
		if amount > 0:
			grant_tool_uses(tool_id, amount, "chapter_chest")
	var extra_lives := int(def.get("life", 0))
	if extra_lives > 0:
		grant_lives(extra_lives, "chapter_chest")


## Chuỗi mô tả phần thưởng của một rương chương — dùng chung cho UI (chip + popup)
func chapter_chest_reward_text(def: Dictionary) -> String:
	var parts: Array[String] = []
	var coins := int(def.get("coins", 0))
	if coins > 0:
		parts.append(tr("STR_DAILY_REWARD_COINS").format([coins]))
	for tool_id in TOOL_IDS:
		var amount := int(def.get(tool_id, 0))
		if amount > 0:
			parts.append(tr("STR_DAILY_TOOL_%s" % tool_id.to_upper()).format([amount]))
	var extra_lives := int(def.get("life", 0))
	if extra_lives > 0:
		parts.append(tr("STR_CHAPTER_CHEST_LIFE").format([extra_lives]))
	return " + ".join(parts)


## Xoá trạng thái “đã nhận rương” của MỌI chương (Debug Console “Reset progress”).
## Dùng chung một chỗ để UI/Debug không phải sửa thẳng `chapter_chests`.
func reset_chapter_chests() -> void:
	if chapter_chests.is_empty():
		return
	chapter_chests.clear()
	Save.queue_save()


## Mở popup HẾT LƯỢT CHƠI (dùng cho test / khi cần báo thủ công)
func open_out_of_life_popup() -> void:
	_show_out_of_life()


func _show_out_of_life() -> void:
	var popup := Popups.open(Popups.OUT_OF_LIFE, {"max_lives": MAX_LIVES})
	if popup == null:
		return
	if popup.has_signal("shop_requested") \
			and not popup.is_connected("shop_requested", request_shop_from_life_gate):  # keep-code: signal của AUTOLOAD / node sinh lúc chạy — không phải node tĩnh
		popup.connect("shop_requested", request_shop_from_life_gate)  # keep-code: signal của AUTOLOAD / node sinh lúc chạy — không phải node tĩnh


## Vào màn chơi — chặn khi hết lượt và mở popup báo hết lượt
func _enter_game_scene() -> void:
	if not can_start_run():
		_show_out_of_life()
		return
	_change_scene(GAME_SCENE)


## Khởi động Daily Mission theo ngày — MAZE ĐẶC BIỆT (mode xoay vòng của ngày)
func start_daily(day: int) -> void:
	prepare_daily_run(day, "special")
	if _open_mode_tutorial_once():
		return
	_enter_game_scene()


## Khởi động Daily Mission theo ngày — MAZE THƯỜNG (classic)
func start_daily_classic(day: int) -> void:
	prepare_daily_run(day, "classic")
	if _open_mode_tutorial_once():
		return
	_enter_game_scene()


## Khởi động phần CHƠI của ngày (1 màn maze thường, tối đa 3 Sao theo nhiệm vụ)
func start_daily_play(day: int) -> void:
	start_daily_classic(day)


## Khởi động phần THỬ THÁCH của ngày (luật Special xoay vòng, thắng = 3 Sao)
func start_daily_challenge(day: int) -> void:
	var dm := Svc.daily()
	daily_challenge_id = ""
	if dm != null and dm.has_method("challenge_mode_for_day"):
		daily_challenge_id = str(dm.call("challenge_mode_for_day", maxi(day, 1)))
	prepare_daily_run(day, "challenge")
	if _open_mode_tutorial_once():
		return
	_enter_game_scene()


## [DEBUG/TEST] Chuẩn bị 1 GAME (0..2) trong ngày nhưng KHÔNG chuyển scene.
## Kế hoạch ngày (`DailyManager.get_day_games`) quyết định game là MAZE THƯỜNG hay CHALLENGE.
func prepare_daily_game(day: int, index: int) -> String:
	var dm := Svc.daily()
	var plan: Array = []
	if dm != null and dm.has_method("get_day_games"):
		var raw: Variant = dm.call("get_day_games", maxi(day, 1))
		if raw is Array:
			plan = raw as Array
	var game_index := clampi(index, 0, maxi(plan.size() - 1, 0))
	var entry: Dictionary = {}
	if game_index < plan.size() and plan[game_index] is Dictionary:
		entry = plan[game_index] as Dictionary
	var mode := ""
	if str(entry.get("mode", "standard")) == "challenge":
		daily_challenge_id = str(entry.get("challenge_id", ""))
		mode = prepare_daily_run(day, "challenge")
	else:
		daily_challenge_id = ""
		mode = prepare_daily_run(day, "classic")
	daily_game = game_index
	return mode


## Khởi động GAME thứ `index` (0..2) của ngày Daily — ván này tính vào tiến trình ngày
func start_daily_game(day: int, index: int) -> void:
	prepare_daily_game(day, index)
	if _open_mode_tutorial_once():
		return
	_enter_game_scene()


## LẦN ĐẦU vào 1 chế độ Special (từ Daily hoặc từ màn có `mode_id`): mở bài học của chế
## độ trước rồi mới vào màn chơi (TutorialManager quyết định — xem `MODE_TUTORIALS`).
## Ván TEST từ Debug Console không tự mở tutorial.
func _open_mode_tutorial_once() -> bool:
	if debug_run:
		return false
	var tm := Svc.tutorial()
	if tm == null or not tm.has_method("begin_mode_tutorial"):
		return false
	return bool(tm.call("begin_mode_tutorial", current_mode))


## [DEBUG/TEST] Chuẩn bị ván Daily nhưng KHÔNG chuyển scene.
## variant = "classic" (maze thường) · "challenge" (game thử thách của ngày) ·
## "special" (maze đặc biệt của ngày). Trả về mode id sẽ dùng.
## (Luật của game challenge do `daily_challenge_id` giữ — xem `prepare_daily_game`.)
func prepare_daily_run(day: int, variant := "special") -> String:
	clear_event_run()
	selected_daily_day = maxi(day, 1)
	if variant == "classic":
		daily_variant = "classic"
	elif variant == "challenge":
		daily_variant = "challenge"
	else:
		daily_variant = "special"
	current_difficulty = "medium"
	level_run = false
	debug_run = false
	start_floor_override = 0
	daily_game = -1
	if daily_variant == "special":
		daily_challenge_id = ""
	if daily_variant == "classic":
		current_mode = "daily_classic"
	elif daily_variant == "challenge":
		current_mode = "daily_challenge"
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
	clear_event_run()
	current_mode = mode_id
	current_difficulty = difficulty
	daily_variant = ""
	daily_game = -1
	daily_challenge_id = ""
	level_run = false
	debug_run = test_run
	start_floor_override = maxi(floor_override, 0)
	mode_changed.emit(current_mode)


## [DEBUG/TEST] Vào thẳng 1 chế độ bất kỳ (kể cả 7 chế độ Special) — dùng cho Debug Console
func start_mode(mode_id: String, difficulty := "medium", test_run := false,
		floor_override := 0) -> void:
	prepare_mode_run(mode_id, difficulty, test_run, floor_override)
	_enter_game_scene()


## Điều hướng tới Main Menu
func go_to_main_menu() -> void:
	_change_scene("res://scenes/main.tscn")


## DEPRECATED — Levels đã GỘP vào Main: bản đồ màn chơi nằm ngay trong Main.
## Giữ tên hàm để không phải sửa mọi nơi gọi (màn thắng/thua, Game back, Debug…).
func go_to_levels() -> void:
	return_to_levels()


## Quay về màn CÓ BẢN ĐỒ (nay là Main) sau khi ván chơi KẾT THÚC (thắng/thua/bỏ qua màn cuối).
## KHÔNG đẩy màn CHƠI vào lịch sử và gỡ luôn mục Main đã đẩy lúc vào ván ⇒ Back ở Main về
## đúng màn trước đó, không nhảy ngược lại ván vừa chơi.
func return_to_levels() -> void:
	_return_to("res://scenes/main.tscn")


## Điều hướng tới Màn hình Daily Mission (đi TIẾN — có ghi lịch sử)
func go_to_daily() -> void:
	_change_scene("res://scenes/daily.tscn")


## Quay về Màn hình Daily sau khi ván Daily kết thúc (xem `return_to_levels()`)
func return_to_daily() -> void:
	_return_to("res://scenes/daily.tscn")


## Lùi về `path` như một thao tác BACK: gỡ mục `path` còn sót trên đỉnh lịch sử (do lúc vào
## ván đã đẩy) rồi chuyển màn KHÔNG ghi thêm lịch sử.
func _return_to(path: String) -> void:
	var screen := Svc.screen()
	if screen != null and screen.has_method("drop_history"):
		screen.call("drop_history", path)
	Nav.back_to(path)


## Chuyển màn qua Nav/SceneManager (tự có SFX lật trang + ghi lịch sử cho nút Back)
func _change_scene(path: String) -> void:
	Nav.change_scene(path)


## Ghi nhận hoàn thành màn
func record_level_clear(level_id: int, stars: int, clear_time: float) -> void:
	# Ván SỰ KIỆN: chỉ báo cho EventManager, KHÔNG ghi Sao/mở khoá vào mạch màn thường (§B7)
	if not current_event_id.is_empty():
		var em := Svc.event()
		var lvl := level_data_of(level_id)
		if em != null and em.has_method("on_level_won") and lvl != null:
			em.call("on_level_won", current_event_id, lvl, stars)
		level_completed.emit(level_id, stars, int(clear_time))
		return

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
		var lm: Node = Svc.level()
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
	var lm := Svc.level()
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
	# Đường liền có CỔNG: mở khoá xong thì màn ĐẦU của chương phải SÁNG ngay, nếu không cả chương
	# vẫn hiện xám vì `unlocked_levels` còn dừng ở màn cuối chương trước.
	var lm := Svc.level()
	if lm != null and lm.has_method("levels_in_chapter"):
		var ids: Array[int] = []
		ids.assign(lm.call("levels_in_chapter", chapter_id))
		if not ids.is_empty():
			unlocked_levels = maxi(unlocked_levels, ids.min())
	chapter_unlocked.emit(chapter_id)
	Save.queue_save()
	return true


## Đổi chương đang xem ở màn Chọn màn
func set_chapter(chapter_id: int) -> void:
	current_chapter = maxi(chapter_id, 1)


## Chương chứa màn này (1 nếu không có LevelManager)
func chapter_of_level(level_id: int) -> int:
	var lm := Svc.level()
	if lm != null and lm.has_method("chapter_of_level"):
		return maxi(int(lm.call("chapter_of_level", level_id)), 1)
	return 1


## Màn kế tiếp TRONG CÙNG CHƯƠNG (-1 nếu đây là màn cuối của chương)
## Màn chọn màn / popup thắng dựa vào đây để KHÔNG nhảy sang chương khác.
func next_level_in_chapter(level_id: int) -> int:
	var lm := Svc.level()
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
	var lm := Svc.level()
	if lm != null and lm.has_method("has_level") and not bool(lm.call("has_level", level_id)):
		return false
	return level_id <= unlocked_levels


## Có chương nào ĐỦ Sao để mở mà chưa mở không (màn Chọn màn nhấp nháy banner báo tin)
func has_unlockable_chapter() -> bool:
	var lm := Svc.level()
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
		"tool_uses": tool_uses.duplicate(),
		"lives": _life.lives,
		"next_life_at": _life.next_life_at,
		"floor_records": _records.records.duplicate(true),
		"chapter_chests": chapter_chests.duplicate(true),
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
	if data.get("tool_uses", null) is Dictionary:
		var saved_tool_uses: Dictionary = data["tool_uses"]
		for tool_id in TOOL_IDS:
			if saved_tool_uses.has(tool_id):
				tool_uses[tool_id] = maxi(int(saved_tool_uses[tool_id]), 0)
	_life.load_state(data.get("lives", _life.lives), data.get("next_life_at", 0))
	life_changed.emit(_life.lives, MAX_LIVES)
	_import_floor_records(data.get("floor_records", null))
	_import_chapter_chests(data.get("chapter_chests", null))
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


## Nạp kỷ lục tầng từ blob tiến trình; kỳ nào đã qua (khác mốc hiện tại) thì coi như 0.
func _import_floor_records(value: Variant) -> void:
	_records.load_state(value)


## Nạp trạng thái "đã nhận rương mốc" của từng chương từ blob tiến trình.
## JSON biến khoá số thành CHUỖI và phần tử thành float ⇒ phải ép kiểu lại.
func _import_chapter_chests(value: Variant) -> void:
	chapter_chests.clear()
	if not (value is Dictionary):
		return
	for key in (value as Dictionary):
		var chapter_id := int(str(key))
		if chapter_id < 1:
			continue
		var saved: Variant = (value as Dictionary)[key]
		var indices: Array[int] = []
		if saved is Array:
			for item in saved:
				var index := int(item)
				if index >= 0 and not indices.has(index):
					indices.append(index)
		chapter_chests[chapter_id] = indices


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
	_life.reset()
	shop_return_path = ""
	_records.reset()
	chapter_chests.clear()
	life_changed.emit(_life.lives, MAX_LIVES)
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
