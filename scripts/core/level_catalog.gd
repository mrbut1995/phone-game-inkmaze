class_name LevelCatalog
extends RefCounted
## ============================================================================
## TRA CỨU CHẾ ĐỘ / ĐỘ KHÓ của MÀN — phần "đọc dữ liệu màn" tách khỏi `GameManager`.
##
## Chỉ là hàm THUẦN trên `LevelData` (không đụng state của ván):
##   · màn không khai `mode_id` (hoặc khai id lạ, hoặc "dungeon") ⇒ chế độ `play`.
##   · màn không khai `difficulty` ⇒ `medium`.
##
## Ai gọi: `GameManager.mode_id_of_level()` · `difficulty_of_level()` · `is_known_mode()` ·
## `special_mode_ids()` (uỷ thác), `DailyManager`/Debug dùng qua GameManager như cũ.
## ============================================================================

## 8 chế độ Special xoay vòng cho Daily (thứ tự cũng là thứ tự xoay theo ngày)
const SPECIAL_MODES: Array[String] = [
	"minesweeper",
	"sum_path",
	"countdown_cost",
	"blind_memory",
	"fog_of_war",
	"fading_ink",
	"one_stroke",
	"wall_builder",
]
## Id chế độ "không phải màn thường" nhưng vẫn hợp lệ
const BASE_MODES: Array[String] = ["play", "classic", "standard", "challenge", "dungeon",
		"daily_classic", "daily_challenge"]


## Chế độ dùng cho 1 màn (`play` nếu không khai hoặc khai id lạ)
## LƯU Ý: "dungeon" KHÔNG dùng được cho màn (chế độ bất tận, chỉ vào từ Main Screen).
static func mode_of(data: LevelData) -> String:
	if data == null:
		return "play"
	var mode_id := str(data.mode_id).strip_edges().to_lower()
	if mode_id.is_empty() or mode_id == "dungeon" or not is_known_mode(mode_id):
		return "play"
	return mode_id


## Độ khó của 1 màn (`medium` nếu không khai)
static func difficulty_of(data: LevelData) -> String:
	if data == null or str(data.difficulty).is_empty():
		return "medium"
	return str(data.difficulty)


## id chế độ có tồn tại không (Play · Dungeon · Daily Classic · 8 chế độ Special)
static func is_known_mode(mode_id: String) -> bool:
	if mode_id in BASE_MODES:
		return true
	return SPECIAL_MODES.has(mode_id)


## Danh sách id chế độ Special (Daily xoay vòng theo danh sách này)
static func special_mode_ids() -> Array[String]:
	return SPECIAL_MODES.duplicate()
