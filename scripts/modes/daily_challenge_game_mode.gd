class_name DailyChallengeGameMode
extends ChallengeGameMode
## ============================================================================
## Mode: DAILY — GAME CHALLENGE (1 trong 3 GAME của ngày Daily Mission, 2026-10)
##
## Giống DailyClassicGameMode (maze 5×5 sinh tại chỗ, KHÔNG nạp LevelData) nhưng gắn
## 1 LUẬT THỬ THÁCH của ngày — kế hoạch 3 game lấy từ `DailyManager.get_day_games()`:
##   · `GameManager.daily_challenge_id` giữ luật đang chơi (prepare_daily_game ghi vào)
##   · Luật walk_* (chỉ ô số / chỉ ô không số) SINH LẠI bàn tới khi có đường hợp lệ
##   · move_limit luôn nới đủ thắng (đường ngắn nhất + dự phòng)
## ============================================================================

const MAZE_SIZE := 2.5
const WALL_VISIBLE_RATIO := 0.5
## Giống maze thường của ngày (DailyClassicGameMode): 20 bước · 60 giây
const DESIGN_STEPS := 20
## Số lần sinh lại bàn khi luật walk_* chưa có đường hợp lệ
const GENERATE_ATTEMPTS := 40


func _init(p_difficulty := "medium") -> void:
	super._init(p_difficulty)
	mode_id = "daily_challenge"
	mode_name = "Daily Challenge"
	mode_description = "Game thử thách của ngày — theo đúng luật, vi phạm là thua ngay!"


## Maze của ngày: sinh tại chỗ như maze thường, luật lấy từ GameManager
func setup_floor(_floor_number: int) -> MazeData:
	var gm := _game_manager()
	var cid := str(gm.get("daily_challenge_id")) if gm != null else ""
	set_challenge(cid, 0)

	var maze := _generate_solvable_maze()
	initial_steps = DESIGN_STEPS
	current_level_data = null      # -> MissionController dùng 3 nhiệm vụ mặc định
	if is_active():
		mode_name = tr(name_key())
	if is_active() and challenge_param <= 0:
		challenge_param = _default_param(maze)
	# Bàn tự sinh: nới hạn mức sao cho LUÔN thắng được bằng đường ngắn nhất + dự phòng
	if challenge_id == MOVE_LIMIT:
		challenge_param = maxi(challenge_param, _shortest_moves(maze) + 3)
	return maze


## Sinh bàn 5×5 như maze thường; luật walk_* thì sinh tới khi có ĐƯỜNG HỢP LỆ
func _generate_solvable_maze() -> MazeData:
	var last := MazeData.new()
	for _attempt in GENERATE_ATTEMPTS:
		last = MazeData.new()
		last.generate(MAZE_SIZE, MAZE_SIZE, WALL_VISIBLE_RATIO)
		if not is_walk_rule() or _has_rule_path(last):
			break
	return last


## Có đường S→F chỉ đi qua ô HỢP LỆ theo luật walk_*? (BFS; S/F luôn hợp lệ)
func _has_rule_path(maze: MazeData) -> bool:
	var start := maze.get_start()
	var queue: Array[Vector2i] = [start]
	var seen := {start: true}
	while not queue.is_empty():
		var cur: Vector2i = queue.pop_front()
		if cur == maze.get_end():
			return true
		for dir: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cur + dir
			if next.x < 0 or next.y < 0 or next.x >= maze.width or next.y >= maze.height:
				continue
			if seen.has(next) or maze.has_wall(cur, next) or not cell_allowed_by_rule(next, maze):
				continue
			seen[next] = true
			queue.append(next)
	return false


## Số bước của đường ngắn nhất S→F bằng BFS (0 nếu không có đường)
func _shortest_moves(maze: MazeData) -> int:
	var start := maze.get_start()
	var queue: Array[Vector2i] = [start]
	var dist := {start: 0}
	while not queue.is_empty():
		var cur: Vector2i = queue.pop_front()
		if cur == maze.get_end():
			return int(dist[cur])
		for dir: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cur + dir
			if next.x < 0 or next.y < 0 or next.x >= maze.width or next.y >= maze.height:
				continue
			if dist.has(next) or maze.has_wall(cur, next):
				continue
			dist[next] = int(dist[cur]) + 1
			queue.append(next)
	return 0


## Tiêu đề HUD = tên luật đang gắn (chưa có luật -> như maze thường)
func get_hud_floor_title(_floor_number: int) -> String:
	return tr(name_key()) if is_active() else tr("STR_DAILY_WIN_CLASSIC")


func get_hud_subtitle(_floor_number: int) -> String:
	return tr("STR_DAILY_MISSION_TITLE")


func _game_manager() -> Node:
	var main_loop := Engine.get_main_loop()
	if main_loop is SceneTree:
		return (main_loop as SceneTree).root.get_node_or_null("GameManager")
	return null
