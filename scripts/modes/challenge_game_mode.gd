class_name ChallengeGameMode
extends StandardGameMode
## ============================================================================
## CHALLENGE MODE (2026-10) — "Thử thách" cho chế độ chuẩn (Play Mode).
##
## Ván chơi vẫn giống Play Mode (đâm tường = thua ngay, xếp hạng theo thời gian);
## chỉ KHÁC: màn có gắn 1 THỬ THÁCH (LevelData.challenge + LevelData.challenge_param).
## Người chơi phải HOÀN THÀNH yêu cầu thử thách để thắng — VI PHẠM quy tắc (hoặc quá hạn)
## là THUA NGAY, mở popup `gameover_challenge.tscn`. Thắng màn mở `winning_challenge.tscn`.
##
## 9 thử thách (id trong CHALLENGE_IDS):
##   countdown           — hoàn thành TRƯỚC khi hết đếm ngược (giây)
##   move_limit          — hoàn thành trong TỐI ĐA N bước (vượt N = thua)
##   step_timer          — MỖI BƯỚC phải đi trong X giây (đồng hồ con, reset sau mỗi bước)
##   no_tool             — KHÔNG dùng CÔNG CỤ: bấm GỢI Ý hoặc DỊCH CHUYỂN = thua
##   no_move_overlapped  — KHÔNG đi lại trên đường đã đi (thay luật cũ no_revisit, tên rõ hơn)
##   walk_number_only    — CHỈ đi trên ô CÓ SỐ (bước vào ô không số = thua)
##   walk_empty_only     — CHỈ đi trên ô KHÔNG SỐ (bước vào ô có số = thua)
##   backtrack_limit     — quay đầu (lùi về ô vừa rời) tối đa N lần (vượt N = thua)
##   fog_of_war          — SƯƠNG MÙ: chỉ thấy số ở các ô quanh nhân vật (bán kính 1), tường ẩn hết
##                         (gộp từ chế độ Special "Fog of War" cũ — đâm tường vẫn = thua như Play)
##
## HUD (ChallengeHUD): Head = tên luật · Value = số chính · Sub = chú thích nhỏ.
## Phần THEO DÕI VI PHẠM nằm ở GameController (xem `_challenge_tick/_challenge_after_step`).
## ============================================================================

const COUNTDOWN := "countdown"
const MOVE_LIMIT := "move_limit"
const STEP_TIMER := "step_timer"
const NO_TOOL := "no_tool"
const NO_MOVE_OVERLAPPED := "no_move_overlapped"
const WALK_NUMBER_ONLY := "walk_number_only"
const WALK_EMPTY_ONLY := "walk_empty_only"
const BACKTRACK_LIMIT := "backtrack_limit"
const FOG_OF_WAR := "fog_of_war"

const CHALLENGE_IDS: PackedStringArray = [
	COUNTDOWN, MOVE_LIMIT, STEP_TIMER, NO_TOOL,
	NO_MOVE_OVERLAPPED, WALK_NUMBER_ONLY, WALK_EMPTY_ONLY, BACKTRACK_LIMIT, FOG_OF_WAR,
]

## Khoá dịch TÊN LUẬT (Head HUD + chữ trong popup)
const HEAD_KEYS := {
	COUNTDOWN: "STR_CHALLENGE_HEAD_COUNTDOWN",
	MOVE_LIMIT: "STR_CHALLENGE_HEAD_MOVE_LIMIT",
	STEP_TIMER: "STR_CHALLENGE_HEAD_STEP_TIMER",
	NO_TOOL: "STR_CHALLENGE_HEAD_NO_TOOL",
	NO_MOVE_OVERLAPPED: "STR_CHALLENGE_HEAD_NO_OVERLAP",
	WALK_NUMBER_ONLY: "STR_CHALLENGE_HEAD_WALK_NUMBER",
	WALK_EMPTY_ONLY: "STR_CHALLENGE_HEAD_WALK_EMPTY",
	BACKTRACK_LIMIT: "STR_CHALLENGE_HEAD_BACKTRACK",
	FOG_OF_WAR: "STR_CHALLENGE_HEAD_FOG",
}
const NAME_KEYS := {
	COUNTDOWN: "STR_CHALLENGE_NAME_COUNTDOWN",
	MOVE_LIMIT: "STR_CHALLENGE_NAME_MOVE_LIMIT",
	STEP_TIMER: "STR_CHALLENGE_NAME_STEP_TIMER",
	NO_TOOL: "STR_CHALLENGE_NAME_NO_TOOL",
	NO_MOVE_OVERLAPPED: "STR_CHALLENGE_NAME_NO_OVERLAP",
	WALK_NUMBER_ONLY: "STR_CHALLENGE_NAME_WALK_NUMBER",
	WALK_EMPTY_ONLY: "STR_CHALLENGE_NAME_WALK_EMPTY",
	BACKTRACK_LIMIT: "STR_CHALLENGE_NAME_BACKTRACK",
	FOG_OF_WAR: "STR_CHALLENGE_NAME_FOG",
}
## Khoá dịch CHÚ THÍCH NHỎ dưới Value (Sub)
const SUB_KEYS := {
	COUNTDOWN: "STR_CHALLENGE_SUB_COUNTDOWN",
	MOVE_LIMIT: "STR_CHALLENGE_SUB_BUDGET",
	STEP_TIMER: "STR_CHALLENGE_SUB_STEP_TIMER",
	NO_TOOL: "STR_CHALLENGE_SUB_BAN_TOOL",
	NO_MOVE_OVERLAPPED: "STR_CHALLENGE_SUB_BAN_OVERLAP",
	WALK_NUMBER_ONLY: "STR_CHALLENGE_SUB_WALK_NUMBER",
	WALK_EMPTY_ONLY: "STR_CHALLENGE_SUB_WALK_EMPTY",
	BACKTRACK_LIMIT: "STR_CHALLENGE_SUB_BACKTRACK",
	FOG_OF_WAR: "STR_CHALLENGE_SUB_FOG",
}
## Khoá dịch LÝ DO THUA (popup GameOver thử thách) — theo `reason` GameController gửi
const FAIL_KEYS := {
	"challenge_timeout": "STR_CHALLENGE_FAIL_TIMEOUT",
	"challenge_moves": "STR_CHALLENGE_FAIL_MOVES",
	"challenge_step_timeout": "STR_CHALLENGE_FAIL_STEP_TIMEOUT",
	"challenge_tool": "STR_CHALLENGE_FAIL_TOOL",
	"challenge_overlap": "STR_CHALLENGE_FAIL_OVERLAP",
	"challenge_walk_number": "STR_CHALLENGE_FAIL_WALK_NUMBER",
	"challenge_walk_empty": "STR_CHALLENGE_FAIL_WALK_EMPTY",
	"challenge_backtrack": "STR_CHALLENGE_FAIL_BACKTRACK",
}

## Param mặc định khi màn không ghi `challenge_param` (0 = tự tính)
const DEFAULT_STEP_TIMER := {"easy": 30, "medium": 20, "hard": 15}
const DEFAULT_BACKTRACK_LIMIT := 3
## Countdown mặc định: 60 giây + 4 giây mỗi ô của bàn (tối thiểu 75 giây)
const COUNTDOWN_BASE := 60
const COUNTDOWN_PER_CELL := 4
const COUNTDOWN_MIN := 75
## Fog of War: bán kính nhìn thấy số quanh nhân vật (1 = 3×3 ô)
const FOG_RADIUS := 1

## Thử thách đang gắn (rỗng = ván này chơi như Play Mode thường)
var challenge_id := ""
## Tham số thử thách: số giây / số bước / số lượt tuỳ luật (0 = lấy mặc định)
var challenge_param := 0

## Fog of War: vị trí nhân vật + các ô đã được "soi sáng" (để Board làm mờ ô chưa khám phá)
var _fog_pos: Vector2i = Vector2i.ZERO
var _fog_explored: Dictionary = {}


func _init(p_difficulty := "medium") -> void:
	super._init(p_difficulty)
	mode_id = "challenge"
	mode_name = "Challenge Mode"
	mode_description = "Thử thách: hoàn thành yêu cầu đặc biệt — vi phạm là thua ngay!"


## Gắn thử thách trực tiếp (dùng cho debug/test); màn thiết kế có thể ghi đè khi vào màn
func set_challenge(id: String, param := 0) -> void:
	challenge_id = id if CHALLENGE_IDS.has(id) else ""
	challenge_param = maxi(param, 0)


func is_active() -> bool:
	return not challenge_id.is_empty()


## Khoá dịch TÊN LUẬT cho Head của HUD (xem ChallengeHUD)
func head_key() -> String:
	return str(HEAD_KEYS.get(challenge_id, ""))


func name_key() -> String:
	return str(NAME_KEYS.get(challenge_id, ""))


func sub_key() -> String:
	return str(SUB_KEYS.get(challenge_id, ""))


## Luật "không công cụ" — GameController chặn TRƯỚC khi thao tác (gợi ý / hoàn tác)
func blocks_tool() -> bool:
	return challenge_id == NO_TOOL


## 2 luật "đi trên ô ...": kiểm ô ĐÍCH trước khi bước (xem `evaluate_move`)
func is_fog_rule() -> bool:
	return challenge_id == FOG_OF_WAR


func is_walk_rule() -> bool:
	return challenge_id == WALK_NUMBER_ONLY or challenge_id == WALK_EMPTY_ONLY


## Hazard type khi bước vào ô vi phạm — GameController nhận diện TIỀN TỐ "challenge_"
## để mở popup thua thử thách thay vì tính là đâm tường
static func hazard_type_for(id: String) -> String:
	return "challenge_" + id


## Lý do thua ứng với từng luật (dùng làm `reason` của popup GameOver)
static func fail_reason_for(id: String) -> String:
	match id:
		COUNTDOWN:
			return "challenge_timeout"
		MOVE_LIMIT:
			return "challenge_moves"
		STEP_TIMER:
			return "challenge_step_timeout"
		NO_TOOL:
			return "challenge_tool"
		NO_MOVE_OVERLAPPED:
			return "challenge_overlap"
		WALK_NUMBER_ONLY:
			return "challenge_walk_number"
		WALK_EMPTY_ONLY:
			return "challenge_walk_empty"
		BACKTRACK_LIMIT:
			return "challenge_backtrack"
	return "challenge_failed"


## Khoá dịch của lý do thua (rỗng/không khớp -> dòng thông báo chung)
static func fail_key(reason: String) -> String:
	return str(FAIL_KEYS.get(reason, "STR_CHALLENGE_FAIL_OTHER"))


## Nạp thử thách từ LevelData của màn (nếu có) + tính param mặc định theo độ khó/bàn cờ.
## Gọi SAU `super.setup_floor()` để có `initial_steps` + `current_level_data` đúng.
func setup_floor(floor_number: int) -> MazeData:
	var maze := super.setup_floor(floor_number)
	var lvl: LevelData = current_level_data
	if lvl != null and not lvl.challenge.is_empty():
		set_challenge(lvl.challenge, lvl.challenge_param)
	if is_active() and challenge_param <= 0:
		challenge_param = _default_param(maze)
	prepare_rule(maze)
	return maze


## Chuẩn bị riêng của từng luật SAU khi có bàn (Fog of War: ẩn mọi tường + mở sương quanh S).
## `DailyChallengeGameMode` (tự sinh bàn) cũng gọi hàm này.
func prepare_rule(maze: MazeData) -> void:
	if not is_fog_rule() or maze == null:
		return
	maze.set_all_walls_visible(false)
	_fog_explored.clear()
	_fog_pos = maze.get_start()
	_fog_reveal(_fog_pos, maze)


## Param mặc định khi màn không ghi (countdown theo diện tích bàn · move_limit = ngân sách bước)
func _default_param(maze: MazeData) -> int:
	match challenge_id:
		COUNTDOWN:
			var cells := maze.width * maze.height if maze != null else 9
			return maxi(COUNTDOWN_MIN, COUNTDOWN_BASE + cells * COUNTDOWN_PER_CELL)
		MOVE_LIMIT:
			return maxi(initial_steps, 4)
		STEP_TIMER:
			return int(DEFAULT_STEP_TIMER.get(difficulty, 20))
		BACKTRACK_LIMIT:
			return DEFAULT_BACKTRACK_LIMIT
	return 0


## 2 luật "đi trên ô ...": kiểm TRA TRƯỚC khi bước — bước vào SAI LOẠI ô = THUA NGAY.
## Trả hazard `challenge_<luật>` để GridController giữ nguyên vị trí (hành xử như đâm tường,
## nhưng KHÔNG vẽ đoạn tường gãy và KHÔNG tính vào "ván hoàn hảo").
func evaluate_move(from_pos: Vector2i, to_pos: Vector2i, maze: MazeData) -> Dictionary:
	var base_eval := super.evaluate_move(from_pos, to_pos, maze)
	if not base_eval.get("allowed", false) or base_eval.get("is_hazard", false):
		return base_eval
	if is_active() and is_walk_rule() and not cell_allowed_by_rule(to_pos, maze):
		return {
			"allowed": false,
			"is_hazard": true,
			"hazard_type": hazard_type_for(challenge_id),
			"from": from_pos,
			"to": to_pos,
		}
	return base_eval


## Ô có được đi qua theo luật "chỉ ô số / chỉ ô không số"? (S/F LUÔN được phép —
## chặn cả 2 đầu thì không bao giờ tới đích được)
func cell_allowed_by_rule(pos: Vector2i, maze: MazeData) -> bool:
	if maze == null or not is_walk_rule():
		return true
	if pos == maze.get_start() or pos == maze.get_end():
		return true
	var has_number := not get_cell_text(pos, maze).is_empty()
	return has_number if challenge_id == WALK_NUMBER_ONLY else not has_number


## Fog of War: số chỉ hiện ở ô trong tầm nhìn quanh nhân vật (S/F luôn hiện)
func get_cell_text(pos: Vector2i, maze: MazeData) -> String:
	if maze == null or not is_fog_rule():
		return super.get_cell_text(pos, maze)
	if pos == maze.get_start():
		return "S"
	if pos == maze.get_end():
		return "F"
	var d := (pos - _fog_pos).abs()
	if d.x <= FOG_RADIUS and d.y <= FOG_RADIUS:
		var count := maze.get_wall_count(pos)
		return "" if count == 0 else str(count)
	return ""


func on_grid_setup(grid_view: Control, maze: MazeData) -> void:
	if is_fog_rule() and maze != null:
		prepare_rule(maze)
		_fog_apply(grid_view)


func on_player_moved(grid_view: Control, new_pos: Vector2i, maze: MazeData) -> void:
	if is_fog_rule() and maze != null:
		_fog_pos = new_pos
		_fog_reveal(new_pos, maze)
		_fog_apply(grid_view)


## Hồi sinh / về lại ô: mở sương quanh vị trí mới
func on_respawned(grid_view: Control, pos: Vector2i, maze: MazeData) -> void:
	on_player_moved(grid_view, pos, maze)


func _fog_reveal(center: Vector2i, maze: MazeData) -> void:
	for dy in range(-FOG_RADIUS, FOG_RADIUS + 1):
		for dx in range(-FOG_RADIUS, FOG_RADIUS + 1):
			var p := center + Vector2i(dx, dy)
			if maze.is_in_bounds(p):
				_fog_explored[p] = true


func _fog_apply(grid_view: Control) -> void:
	if grid_view != null and grid_view.has_method("apply_fog_of_war"):
		grid_view.apply_fog_of_war(_fog_pos, FOG_RADIUS, _fog_explored)


## Dòng phụ dưới tiêu đề màn = tên luật thử thách (chưa có thử thách -> như Play Mode)
func get_hud_subtitle(_floor_number: int) -> String:
	if not is_active():
		return super.get_hud_subtitle(_floor_number)
	return tr(name_key())


## Chữ cho khối THỜI GIAN của ChallengeHUD:
##   head  = tên luật · value = số chính · sub = chú thích nhỏ · low = cận kề thất bại (đổi đỏ)
func hud_state(seconds_left: float, moves_used: int, step_seconds_left: float, backtracks_left: int) -> Dictionary:
	if not is_active():
		return {}
	var value := "—"
	var low := false
	match challenge_id:
		COUNTDOWN:
			value = _format_seconds(seconds_left)
			low = seconds_left <= 10.0
		MOVE_LIMIT:
			value = str(moves_used)
			low = challenge_param - moves_used <= 2
		STEP_TIMER:
			value = _format_seconds(step_seconds_left)
			low = step_seconds_left <= 5.0
		BACKTRACK_LIMIT:
			value = str(backtracks_left)
			low = backtracks_left <= 1
		FOG_OF_WAR:
			value = str(FOG_RADIUS)
	var sub := tr(sub_key())
	# 2 luật "đếm số" hiện kèm hạn mức: "12  /20 BƯỚC" · "2  /3 LƯỢT"
	if challenge_id == MOVE_LIMIT or challenge_id == BACKTRACK_LIMIT:
		sub = "/%d %s" % [challenge_param, sub]
	return {"head": tr(head_key()), "value": value, "sub": sub, "low": low}


## Dữ liệu thử thách gửi kèm popup thắng/thua (rỗng nếu ván này không có thử thách)
func result_info() -> Dictionary:
	if not is_active():
		return {}
	return {
		"challenge_id": challenge_id,
		"challenge_name_key": name_key(),
		"challenge_param": challenge_param,
	}


## Giây -> "m:ss" (đồng hồ đếm ngược của thử thách)
static func _format_seconds(seconds: float) -> String:
	var total := maxi(int(ceil(seconds)), 0)
	return "%d:%02d" % [total / 60, total % 60]
