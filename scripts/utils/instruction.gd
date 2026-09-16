class_name Instruction
extends RefCounted
## ============================================================================
## Nội dung popup HƯỚNG DẪN (nodes/popups/instruction.tscn).
##
## - Mỗi chế độ chơi có 3 trang: CÁCH CHƠI (dùng chung) · LUẬT CHẾ ĐỘ · THỬ THÁCH & THƯỞNG.
## - Ảnh minh hoạ là SVG trong assets/images/instructions/ (sinh bằng
##   tools/mockup/gen_instructions.py — ThorVG không render chữ nên ảnh không có text).
## - `title`/`body` là KHOÁ DỊCH (resources/localization/string_extra.csv);
##   popup gọi tr() khi hiển thị nên đổi ngôn ngữ là đổi ngay.
## ============================================================================

const IMG_DIR := "res://assets/images/instructions/"
## Chế độ mặc định khi không xác định được mode_id
const FALLBACK_MODE := "play"

## mode_id -> [{img, title, body}, ...]
const PAGES := {
	"play": [
		{"img": "guide_control", "title": "STR_INSTRUCTION_T_CONTROL", "body": "STR_INSTRUCTION_B_CONTROL"},
		{"img": "mode_play", "title": "STR_MODE_PLAY_NAME", "body": "STR_INSTRUCTION_B_MODE_PLAY"},
		{"img": "guide_score", "title": "STR_INSTRUCTION_T_SCORE", "body": "STR_INSTRUCTION_B_SCORE_PLAY"},
	],
	"daily_classic": [
		{"img": "guide_control", "title": "STR_INSTRUCTION_T_CONTROL", "body": "STR_INSTRUCTION_B_CONTROL"},
		{"img": "mode_daily_classic", "title": "STR_MODE_DAILY_CLASSIC_NAME", "body": "STR_INSTRUCTION_B_MODE_DAILY"},
		{"img": "guide_score", "title": "STR_INSTRUCTION_T_SCORE", "body": "STR_INSTRUCTION_B_SCORE_DAILY"},
	],
	"dungeon": [
		{"img": "guide_control", "title": "STR_INSTRUCTION_T_CONTROL", "body": "STR_INSTRUCTION_B_CONTROL"},
		{"img": "mode_dungeon", "title": "STR_MODE_DUNGEON_NAME", "body": "STR_INSTRUCTION_B_MODE_DUNGEON"},
		{"img": "guide_score", "title": "STR_INSTRUCTION_T_SCORE", "body": "STR_INSTRUCTION_B_SCORE_DUNGEON"},
	],
	"time_attack": [
		{"img": "guide_control", "title": "STR_INSTRUCTION_T_CONTROL", "body": "STR_INSTRUCTION_B_CONTROL"},
		{"img": "mode_time_attack", "title": "STR_MODE_TIME_ATTACK", "body": "STR_INSTRUCTION_B_MODE_TIME"},
		{"img": "guide_score", "title": "STR_INSTRUCTION_T_SCORE", "body": "STR_INSTRUCTION_B_SCORE_TIME"},
	],
	"minesweeper": [
		{"img": "guide_control", "title": "STR_INSTRUCTION_T_CONTROL", "body": "STR_INSTRUCTION_B_CONTROL"},
		{"img": "mode_minesweeper", "title": "STR_MODE_MINESWEEPER", "body": "STR_INSTRUCTION_B_MODE_MINESWEEPER"},
		{"img": "guide_score", "title": "STR_INSTRUCTION_T_SCORE", "body": "STR_INSTRUCTION_B_SCORE_MINESWEEPER"},
	],
	"sum_path": [
		{"img": "guide_control", "title": "STR_INSTRUCTION_T_CONTROL", "body": "STR_INSTRUCTION_B_CONTROL"},
		{"img": "mode_sum_path", "title": "STR_MODE_SUM_PATH", "body": "STR_INSTRUCTION_B_MODE_SUM_PATH"},
		{"img": "guide_score", "title": "STR_INSTRUCTION_T_SCORE", "body": "STR_INSTRUCTION_B_SCORE_SUM_PATH"},
	],
	"countdown_cost": [
		{"img": "guide_control", "title": "STR_INSTRUCTION_T_CONTROL", "body": "STR_INSTRUCTION_B_CONTROL"},
		{"img": "mode_countdown_cost", "title": "STR_MODE_COUNTDOWN_COST", "body": "STR_INSTRUCTION_B_MODE_COUNTDOWN"},
		{"img": "guide_score", "title": "STR_INSTRUCTION_T_SCORE", "body": "STR_INSTRUCTION_B_SCORE_COUNTDOWN"},
	],
	"blind_memory": [
		{"img": "guide_control", "title": "STR_INSTRUCTION_T_CONTROL", "body": "STR_INSTRUCTION_B_CONTROL"},
		{"img": "mode_blind_memory", "title": "STR_MODE_BLIND_MEMORY", "body": "STR_INSTRUCTION_B_MODE_BLIND"},
		{"img": "guide_score", "title": "STR_INSTRUCTION_T_SCORE", "body": "STR_INSTRUCTION_B_SCORE_BLIND"},
	],
	"fog_of_war": [
		{"img": "guide_control", "title": "STR_INSTRUCTION_T_CONTROL", "body": "STR_INSTRUCTION_B_CONTROL"},
		{"img": "mode_fog_of_war", "title": "STR_MODE_FOG_OF_WAR", "body": "STR_INSTRUCTION_B_MODE_FOG"},
		{"img": "guide_score", "title": "STR_INSTRUCTION_T_SCORE", "body": "STR_INSTRUCTION_B_SCORE_FOG"},
	],
	"fading_ink": [
		{"img": "guide_control", "title": "STR_INSTRUCTION_T_CONTROL", "body": "STR_INSTRUCTION_B_CONTROL"},
		{"img": "mode_fading_ink", "title": "STR_MODE_FADING_INK", "body": "STR_INSTRUCTION_B_MODE_FADING"},
		{"img": "guide_score", "title": "STR_INSTRUCTION_T_SCORE", "body": "STR_INSTRUCTION_B_SCORE_FADING"},
	],
}


## Danh sách mode_id có nội dung hướng dẫn riêng
static func mode_ids() -> Array:
	var ids := PAGES.keys()
	ids.sort()
	return ids


## Các trang hướng dẫn của một chế độ (mode lạ -> dùng bộ của "play")
static func pages_for(mode_id: String) -> Array:
	var key := mode_id.strip_edges().to_lower()
	if not PAGES.has(key):
		key = FALLBACK_MODE
	var pages: Array = PAGES[key]
	return pages.duplicate(true)


## Số trang hướng dẫn của một chế độ
static func page_count(mode_id: String) -> int:
	return pages_for(mode_id).size()


## Đường dẫn đầy đủ của ảnh minh hoạ
static func image_path(img_name: String) -> String:
	return IMG_DIR + img_name + ".svg"


## Khoá dịch tên hiển thị của chế độ ("" nếu chưa khai báo)
static func name_key(mode_id: String) -> String:
	var key := mode_id.strip_edges().to_lower()
	if not PAGES.has(key):
		return ""
	return str((PAGES[key] as Array)[1].get("title", ""))
