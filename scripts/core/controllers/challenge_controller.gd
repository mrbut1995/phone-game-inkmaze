class_name ChallengeController
extends Node
## ============================================================================
## Controller: tối đa 3 Thử thách (Challenge) của mỗi màn/tầng — nguồn tính Sao.
##
## LUẬT (Number_Maze_Game_Design.md — mục 3.1 & 5.10):
##   - Mỗi match-up (Màn ở Play Mode / Tầng ở Dungeon Mode / ngày Daily) có TỐI ĐA 3 Thử thách.
##   - Hoàn thành 1 Thử thách = 1 Sao. Sao KHÔNG tính theo thời gian còn lại.
##   - Màn chưa chọn thử thách (màn cũ) -> dùng 3 thử thách mặc định:
##        no_wall · steps_max (N = max_steps) · time_max (T = N × 3, kẹp 30..240s)
##
## 16 loại thử thách: xem ChallengeTypes (id · nhãn · loại tham số).
## Thử thách do LevelData khai báo qua `challenge_types` + `challenge_params` (mảng song song).
##
## HUD: panel "THỬ THÁCH" (Information/Challenge trong scenes/game.tscn) hiển thị trạng thái sống.
## Popup thua/kết quả lấy dữ liệu qua rows() (danh sách thử thách + trạng thái) và stars().
## ============================================================================

signal updated

const SECONDS_PER_STEP := 3.0
const MIN_TIME_LIMIT := 30.0
const MAX_TIME_LIMIT := 240.0

const STAR_FULL := preload("res://assets/images/common/star_highlight.svg")
const STAR_EMPTY := preload("res://assets/images/common/star_empty.svg")

const COLOR_DONE := Color(0.18039216, 0.49019608, 0.19607843, 1)
const COLOR_FAIL := Color(0.84705883, 0.26666668, 0.26666668, 1)
const COLOR_LIVE := Color(0.70980394, 0.38431373, 0.101960786, 1)
const COLOR_IDLE := Color(0.44313726, 0.54509807, 0.61960787, 1)
const COLOR_NAME := Color(0.13333334, 0.29803923, 0.42745098, 1)

## Thẻ THỬ THÁCH trên HUD (Information/Challenge) — gán trong scenes/game.tscn
@export var card: Control = null

## Ngưỡng mặc định của màn/tầng đang chơi
var step_limit := 0
var time_limit := 0.0

## Thử thách của màn hiện tại: [{ type, param }]
var _entries: Array[Dictionary] = []
## Trạng thái hiện tại: [{ type, title, done, status, status_color }]
var _rows: Array[Dictionary] = []
## Khoá trạng thái lần vẽ trước (tránh format chuỗi lại mỗi frame)
var _last_key := ""
## Số ô thuộc board (để tính % độ dài đường đi / đi hết ô)
var _board_cells := 0


func _ready() -> void:
	setup_for_floor(0)
	var ctx := ChallengeContext.new()
	ctx.set_values(null, null, null, [], 0.0, false)
	refresh(ctx)


## Gọi khi bắt đầu màn/tầng. `level_data = null` -> dùng 3 thử thách mặc định.
func setup_for_floor(design_steps: int, level_data: LevelData = null) -> void:
	step_limit = maxi(design_steps, 1)
	time_limit = clampf(float(step_limit) * SECONDS_PER_STEP, MIN_TIME_LIMIT, MAX_TIME_LIMIT)
	_entries = _resolve_entries(level_data)
	_board_cells = 0
	_build_rows()
	_last_key = ""
	_refresh_hud()


## Cập nhật trạng thái thử thách theo số liệu ván đang chơi.
## `ctx.final = true` khi màn/tầng đã kết thúc -> chốt ĐẠT/CHƯA ĐẠT để tính Sao cho popup.
func refresh(ctx: ChallengeContext) -> void:
	if ctx == null or ctx.state == null:
		return
	if _entries.is_empty():
		_entries = _resolve_entries(null)
	if _rows.size() != _entries.size():
		_build_rows()

	if _board_cells <= 0:
		_board_cells = _count_active_cells(ctx.maze)

	var metrics := _collect_metrics(ctx)
	# Khoá trạng thái: chỉ tính lại khi số liệu đổi (refresh được gọi mỗi frame)
	var key := "%d|%d|%d|%d|%d|%d|%d|%d|%s|%s" % [
		ctx.state.floor_wall_hits,
		ctx.state.floor_moves,
		int(metrics["visited"]),
		int(metrics["revisits"]),
		int(metrics["sum"]),
		int(metrics["numbered_on_path"]),
		ctx.state.hints_used,
		ctx.state.undos_used,
		str(int(ctx.elapsed)),
		str(ctx.final),
	]
	if key != _last_key:
		_last_key = key
		for i in _entries.size():
			var verdict := _evaluate(_entries[i], ctx, metrics, ctx.final)
			_rows[i]["done"] = verdict["done"]
			_rows[i]["status"] = verdict["status"]
			_rows[i]["status_color"] = verdict["color"]
		_refresh_hud()
		updated.emit()


## Danh sách thử thách + trạng thái: [{ type, title, done, status, status_color }, ...]
func rows() -> Array[Dictionary]:
	return _rows


## Số Sao = số thử thách đã hoàn thành
func stars() -> int:
	var total := 0
	for row in _rows:
		if bool(row.get("done", false)):
			total += 1
	return total


## Tổng số thử thách của màn (tối đa 3)
func challenge_count() -> int:
	return _rows.size()


func all_done() -> bool:
	return stars() == _rows.size() and not _rows.is_empty()


# ---------------------------------------------------------------------------
# Dựng danh sách thử thách
# ---------------------------------------------------------------------------
func _resolve_entries(level_data: LevelData) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if level_data != null:
		var types := level_data.challenge_types
		var params := level_data.challenge_params
		for i in mini(types.size(), ChallengeTypes.MAX_PER_LEVEL):
			var type_id := str(types[i])
			if not ChallengeTypes.is_valid(type_id):
				push_warning("ChallengeController: bo qua loai thu thach la '%s'" % type_id)
				continue
			var param := int(params[i]) if i < params.size() else 0
			if ChallengeTypes.has_param(type_id) and param <= 0:
				param = _default_param(type_id)
			out.append({"type": type_id, "param": param})
	if out.is_empty():
		for entry in ChallengeTypes.defaults_for(step_limit, time_limit):
			out.append(entry)
	return out


func _default_param(type_id: String) -> int:
	match ChallengeTypes.param_kind(type_id):
		ChallengeTypes.PARAM_STEPS:
			return step_limit
		ChallengeTypes.PARAM_SECONDS:
			return int(round(time_limit))
		ChallengeTypes.PARAM_PERCENT:
			return 50
		ChallengeTypes.PARAM_SUM:
			return 20
		_:
			return 0


func _build_rows() -> void:
	_rows = []
	for entry in _entries:
		_rows.append({
			"type": str(entry.get("type", "")),
			"title": _title_for(entry),
			"done": false,
			"status": tr("STR_CHALLENGE_NOT_DONE"),
			"status_color": COLOR_FAIL,
		})


## Nhãn hiển thị của thử thách (đã điền tham số nếu có)
func _title_for(entry: Dictionary) -> String:
	var type_id := str(entry.get("type", ""))
	var key := ChallengeTypes.label_key(type_id)
	if key.is_empty():
		return type_id
	var text := tr(key)
	if ChallengeTypes.has_param(type_id):
		return text.format([int(entry.get("param", 0))])
	return text


# ---------------------------------------------------------------------------
# Số liệu của đường đi hiện tại
# ---------------------------------------------------------------------------
func _collect_metrics(ctx: ChallengeContext) -> Dictionary:
	var visited := {}
	var revisits := 0
	var sum := 0
	var start := ctx.maze.get_start() if ctx.maze != null else Vector2i(-1, -1)
	var end := ctx.maze.get_end() if ctx.maze != null else Vector2i(-1, -1)

	for pos in ctx.path:
		if visited.has(pos):
			revisits += 1
		else:
			visited[pos] = true
		if ctx.maze == null or pos == start or pos == end:
			continue
		var number := _cell_number(pos, ctx)
		if number >= 0:
			sum += number

	# Đếm số ô có số trên toàn board (để kiểm tra "đi qua hết mọi ô có số")
	var board_numbered := 0
	if ctx.maze != null:
		for y in ctx.maze.height:
			for x in ctx.maze.width:
				var pos := Vector2i(x, y)
				if not ctx.maze.is_cell_active(pos) or pos == start or pos == end:
					continue
				if _cell_number(pos, ctx) >= 0:
					board_numbered += 1

	# Ô "có số" mà người chơi đã đi
	var numbered_on_path := 0
	for pos in visited.keys():
		if pos == start or pos == end:
			continue
		if _cell_number(pos, ctx) >= 0:
			numbered_on_path += 1

	return {
		"visited": visited.size(),
		"revisits": revisits,
		"cells": visited,               # Dictionary<Vector2i, bool>
		"sum": sum,
		"numbered_on_path": numbered_on_path,
		"board_numbered": board_numbered,
		"board_cells": _board_cells,
	}


## Số hiển thị trên ô (-1 = ô không có số; S/F trả về "S"/"F" nên cũng là -1)
func _cell_number(pos: Vector2i, ctx: ChallengeContext) -> int:
	if ctx.mode == null or ctx.maze == null or not ctx.maze.is_in_bounds(pos):
		return -1
	var text := ctx.mode.get_cell_text(pos, ctx.maze)
	if text.is_empty() or not text.is_valid_int():
		return -1
	return int(text)


func _count_active_cells(maze: MazeData) -> int:
	if maze == null:
		return 0
	if maze.is_full_rect():
		return maze.width * maze.height
	var total := 0
	for y in maze.height:
		for x in maze.width:
			if maze.is_cell_active(Vector2i(x, y)):
				total += 1
	return total


# ---------------------------------------------------------------------------
# Chấm điểm từng loại thử thách
# ---------------------------------------------------------------------------
func _evaluate(entry: Dictionary, ctx: ChallengeContext, m: Dictionary, is_final: bool) -> Dictionary:
	var type_id := str(entry.get("type", ""))
	var param := int(entry.get("param", 0))
	var state := ctx.state

	match type_id:
		ChallengeTypes.NO_WALL:
			var hits := state.floor_wall_hits
			var ok := hits == 0
			return _verdict(ok, _pass_fail(ok))

		ChallengeTypes.STEPS_MAX:
			var moves := state.floor_moves
			var ok := moves <= param
			if is_final:
				return _verdict(ok, _pass_fail(ok))
			return _pending(tr("STR_CHALLENGE_STEPS_PROGRESS").format([moves, param]), ok)

		ChallengeTypes.TIME_MAX:
			var left := float(param) - ctx.elapsed
			var ok := left >= 0.0
			if is_final:
				return _verdict(ok, _pass_fail(ok))
			var text := tr("STR_CHALLENGE_TIME_LEFT").format([int(ceil(left))]) if ok \
				else tr("STR_CHALLENGE_TIME_OVER").format([int(ceil(-left))])
			return _pending(text, ok)

		ChallengeTypes.ONLY_NUMBERED:
			var bad := _offending_cells(ctx, m, false)
			if bad > 0:
				return _verdict(false, tr("STR_CHALLENGE_ST_VIOLATED"))
			return _verdict(true, tr("STR_CHALLENGE_ST_NUMBERED_OK"))

		ChallengeTypes.AVOID_NUMBERED:
			var bad := _offending_cells(ctx, m, true)
			if bad > 0:
				return _verdict(false, tr("STR_CHALLENGE_ST_VIOLATED"))
			return _verdict(true, tr("STR_CHALLENGE_ST_OK"))

		ChallengeTypes.NO_REVISIT:
			var revisits := int(m["revisits"])
			if revisits > 0:
				return _verdict(false, tr("STR_CHALLENGE_ST_REVISITED").format([revisits]))
			return _verdict(true, tr("STR_CHALLENGE_ST_OK"))

		ChallengeTypes.VISIT_ALL:
			var visited := int(m["visited"])
			var cells := maxi(int(m["board_cells"]), 1)
			var ok := visited >= cells
			if ok:
				return _verdict(true, _pass_fail(true))
			if is_final:
				return _verdict(false, _pass_fail(false))
			return _pending(tr("STR_CHALLENGE_ST_VISIT_ALL").format([visited, cells]), true)

		ChallengeTypes.VISIT_ALL_NUMBERED:
			var done_cells := int(m["numbered_on_path"])
			var need := int(m["board_numbered"])
			var ok := need == 0 or done_cells >= need
			if ok:
				return _verdict(true, _pass_fail(true))
			if is_final:
				return _verdict(false, _pass_fail(false))
			return _pending(tr("STR_CHALLENGE_ST_VISIT_ALL").format([done_cells, need]), true)

		ChallengeTypes.LEN_MIN_PERCENT:
			return _percent_verdict(int(m["visited"]), int(m["board_cells"]), param, true, is_final)

		ChallengeTypes.LEN_MAX_PERCENT:
			return _percent_verdict(int(m["visited"]), int(m["board_cells"]), param, false, is_final)

		ChallengeTypes.SUM_LT:
			return _sum_verdict(int(m["sum"]), param, "<", is_final)
		ChallengeTypes.SUM_LE:
			return _sum_verdict(int(m["sum"]), param, "<=", is_final)
		ChallengeTypes.SUM_GT:
			return _sum_verdict(int(m["sum"]), param, ">", is_final)
		ChallengeTypes.SUM_GE:
			return _sum_verdict(int(m["sum"]), param, ">=", is_final)

		ChallengeTypes.NO_HINT:
			var used := state.hints_used
			var ok := used == 0
			return _verdict(ok, _pass_fail(ok) if ok else tr("STR_CHALLENGE_ST_HINT_USED").format([used]))

		ChallengeTypes.NO_UNDO:
			var used := state.undos_used
			var ok := used == 0
			return _verdict(ok, _pass_fail(ok) if ok else tr("STR_CHALLENGE_ST_UNDO_USED").format([used]))

		_:
			return _verdict(false, tr("STR_CHALLENGE_NOT_DONE"))


## Đếm số ô đã đi VI PHẠM: `forbid_numbered = false` -> chỉ được đi ô có số;
## `true` -> không được đi ô có số.
func _offending_cells(ctx: ChallengeContext, m: Dictionary, forbid_numbered: bool) -> int:
	var cells: Dictionary = m["cells"]
	var start := ctx.maze.get_start() if ctx.maze != null else Vector2i(-1, -1)
	var end := ctx.maze.get_end() if ctx.maze != null else Vector2i(-1, -1)
	var bad := 0
	for pos in cells.keys():
		if pos == start or pos == end:
			continue
		var has_number := _cell_number(pos, ctx) >= 0
		if forbid_numbered and has_number:
			bad += 1
		elif not forbid_numbered and not has_number:
			bad += 1
	return bad


func _percent_verdict(visited: int, cells: int, percent: int, need_min: bool, is_final: bool) -> Dictionary:
	var total := maxi(cells, 1)
	var got := int(round(100.0 * float(visited) / float(total)))
	var ok := got >= percent if need_min else got <= percent
	if is_final:
		return _verdict(ok, _pass_fail(ok))
	var text := tr("STR_CHALLENGE_ST_VISITED_PCT").format([got])
	return _pending(text, ok)


func _sum_verdict(current: int, target: int, op: String, is_final: bool) -> Dictionary:
	var ok := false
	match op:
		"<":
			ok = current < target
		"<=":
			ok = current <= target
		">":
			ok = current > target
		_:
			ok = current >= target
	if is_final:
		return _verdict(ok, _pass_fail(ok))
	return _pending(tr("STR_CHALLENGE_ST_PATH_SUM").format([current]), ok)


# ---------------------------------------------------------------------------
# Nội bộ
# ---------------------------------------------------------------------------
func _pass_fail(ok: bool) -> String:
	return tr("STR_CHALLENGE_DONE") if ok else tr("STR_CHALLENGE_NOT_DONE")


func _verdict(done: bool, status: String) -> Dictionary:
	return {"done": done, "status": status, "color": COLOR_DONE if done else COLOR_FAIL}


func _pending(status: String, on_track: bool) -> Dictionary:
	return {"done": false, "status": status, "color": COLOR_LIVE if on_track else COLOR_FAIL}


## Vẽ trạng thái các thử thách lên thẻ HUD "THỬ THÁCH"
func _refresh_hud() -> void:
	if card == null:
		return

	var count_label := card.get_node_or_null("Count") as Label
	if count_label != null:
		var count_text := tr("STR_CHALLENGE_COUNT_FORMAT").format([stars(), maxi(_rows.size(), 1)])
		if count_label.text != count_text:
			count_label.text = count_text

	for i in _rows.size():
		var row_node := card.get_node_or_null("Row%d" % (i + 1)) as Control
		if row_node == null:
			continue
		var row := _rows[i]
		var done := bool(row.get("done", false))

		var star := row_node.get_node_or_null("Star") as TextureRect
		if star != null:
			star.texture = STAR_FULL if done else STAR_EMPTY
			star.modulate = Color(1, 1, 1, 1) if done else Color(1, 1, 1, 0.8)

		var name_label := row_node.get_node_or_null("Name") as Label
		if name_label != null:
			var title_text := str(row.get("title", ""))
			if name_label.text != title_text:
				name_label.text = title_text
			name_label.modulate = COLOR_NAME if done else COLOR_IDLE

		var status_label := row_node.get_node_or_null("Status") as Label
		if status_label != null:
			var status_text := str(row.get("status", ""))
			if status_label.text != status_text:
				status_label.text = status_text
			status_label.modulate = row.get("status_color", COLOR_IDLE)
