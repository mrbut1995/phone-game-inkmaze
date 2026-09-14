extends SceneTree
## ============================================================================
## Test Case: 16 LOẠI THỬ THÁCH (ChallengeTypes) + giới hạn 3 thử thách / màn.
##
## Vì ChallengeController chấm dựa trên `ctx.path` (danh sách ô đã đi), test có thể
## dựng đường đi tuỳ ý nên kiểm tra được từng loại một cách xác định (không phụ thuộc random).
## ============================================================================

var _failures := 0

var _cc: ChallengeController = null
var _maze: MazeData = null
var _mode: StandardGameMode = null
var _state: GameState = null
var _numbered: Array[Vector2i] = []
var _blank: Array[Vector2i] = []


func _init() -> void:
	print("\n========================================================")
	print("  TEST: 16 LOAI THU THACH (CHALLENGE TYPES)")
	print("========================================================\n")
	await process_frame

	_cc = ChallengeController.new()
	root.add_child(_cc)
	await process_frame

	_maze = MazeData.new()
	_maze.generate(5, 5, 0.35)
	_mode = StandardGameMode.new("medium")
	_state = GameState.new()
	_state.begin_run(20, "play", 1)

	for y in _maze.height:
		for x in _maze.width:
			var pos := Vector2i(x, y)
			if pos == _maze.get_start() or pos == _maze.get_end():
				continue
			if _mode.get_cell_text(pos, _maze).is_empty():
				_blank.append(pos)
			else:
				_numbered.append(pos)
	print("[CHECK] Ban co 5x5: %d o co so · %d o khong so · S=%s F=%s"
		% [_numbered.size(), _blank.size(), str(_maze.get_start()), str(_maze.get_end())])

	if _numbered.is_empty() or _blank.is_empty():
		_fail("Ban co test khong co du ca o co so lan o khong so")
		_finish()
		return

	_check_no_wall()
	_check_steps_and_time()
	_check_numbered_cells()
	_check_no_revisit()
	_check_visit_all()
	_check_length_percent()
	_check_sum()
	_check_tools()
	_check_limits_and_level_data()

	_finish()


# ---------------------------------------------------------------------------
# Từng nhóm thử thách
# ---------------------------------------------------------------------------
func _check_no_wall() -> void:
	_state.floor_wall_hits = 0
	_expect("no_wall · chưa đâm tường", ["no_wall"], [0], [], 0.0, false, [true])

	_state.floor_wall_hits = 2
	_expect("no_wall · đâm tường 2 lần", ["no_wall"], [0], [], 0.0, true, [false])
	_state.floor_wall_hits = 0


func _check_steps_and_time() -> void:
	for i in 12:
		_state.floor_moves += 1
	# Đang chơi: chưa chốt (dù đang trong ngưỡng)
	_expect("steps_max · đang chơi 12/15", ["steps_max"], [15], [], 10.0, false, [false])
	# Kết thúc: 12 <= 15 -> đạt
	_expect("steps_max · kết thúc 12/15", ["steps_max"], [15], [], 10.0, true, [true])
	for i in 6:
		_state.floor_moves += 1
	_expect("steps_max · kết thúc 18/15", ["steps_max"], [15], [], 10.0, true, [false])

	_expect("time_max · 30s/45s", ["time_max"], [45], [], 30.0, true, [true])
	_expect("time_max · 60s/45s", ["time_max"], [45], [], 60.0, true, [false])
	for i in 12:
		_state.floor_moves -= 1


func _check_numbered_cells() -> void:
	var on_numbers: Array[Vector2i] = [_maze.get_start(), _numbered[0], _numbered[1], _maze.get_end()]
	var with_blank: Array[Vector2i] = [_maze.get_start(), _numbered[0], _blank[0], _maze.get_end()]

	_expect("only_numbered · toàn ô có số", ["only_numbered"], [0], on_numbers, 0.0, true, [true])
	_expect("only_numbered · lỡ vào ô không số", ["only_numbered"], [0], with_blank, 0.0, false, [false])

	_expect("avoid_numbered · không vào ô có số", ["avoid_numbered"], [0], with_blank, 0.0, false, [false])
	var blanks_only: Array[Vector2i] = [_maze.get_start(), _blank[0], _maze.get_end()]
	_expect("avoid_numbered · chỉ ô không số", ["avoid_numbered"], [0], blanks_only, 0.0, true, [true])


func _check_no_revisit() -> void:
	var unique: Array[Vector2i] = [_maze.get_start(), _numbered[0], _numbered[1], _maze.get_end()]
	_expect("no_revisit · đường không lặp", ["no_revisit"], [0], unique, 0.0, true, [true])
	var doubled: Array[Vector2i] = [_maze.get_start(), _numbered[0], _numbered[1], _numbered[0], _maze.get_end()]
	_expect("no_revisit · quay lại ô cũ", ["no_revisit"], [0], doubled, 0.0, false, [false])


func _check_visit_all() -> void:
	var all_cells: Array[Vector2i] = []
	for y in _maze.height:
		for x in _maze.width:
			all_cells.append(Vector2i(x, y))
	_expect("visit_all · đi hết board", ["visit_all"], [0], all_cells, 0.0, true, [true])
	var missing: Array[Vector2i] = all_cells.duplicate()
	missing.pop_back()
	_expect("visit_all · thiếu 1 ô", ["visit_all"], [0], missing, 0.0, true, [false])

	var numbered_path: Array[Vector2i] = [_maze.get_start()]
	for pos in _numbered:
		numbered_path.append(pos)
	numbered_path.append(_maze.get_end())
	_expect("visit_all_numbered · đi hết ô có số", ["visit_all_numbered"], [0], numbered_path, 0.0, true, [true])
	var fewer: Array[Vector2i] = numbered_path.duplicate()
	fewer.remove_at(1)
	_expect("visit_all_numbered · thiếu 1 ô có số", ["visit_all_numbered"], [0], fewer, 0.0, true, [false])


func _check_length_percent() -> void:
	# 13 ô KHÁC NHAU trên board 25 ô = 52%
	var cells: Array[Vector2i] = []
	for y in _maze.height:
		for x in _maze.width:
			cells.append(Vector2i(x, y))
	var thirteen: Array[Vector2i] = []
	for i in 13:
		thirteen.append(cells[i])
	_expect("len_min_percent 50 · đi 52%", ["len_min_percent"], [50], thirteen, 0.0, true, [true])
	_expect("len_min_percent 80 · đi 52%", ["len_min_percent"], [80], thirteen, 0.0, true, [false])
	_expect("len_max_percent 60 · đi 52%", ["len_max_percent"], [60], thirteen, 0.0, true, [true])
	_expect("len_max_percent 40 · đi 52%", ["len_max_percent"], [40], thirteen, 0.0, true, [false])


func _check_sum() -> void:
	var path: Array[Vector2i] = [_maze.get_start(), _numbered[0], _numbered[1], _maze.get_end()]
	var total := _path_sum(path)
	print("[CHECK] Tổng số trên đường đi test = %d" % total)
	_expect("sum_lt (total+1)", ["sum_lt"], [total + 1], path, 0.0, true, [true])
	_expect("sum_lt (total)", ["sum_lt"], [total], path, 0.0, true, [false])
	_expect("sum_le (total)", ["sum_le"], [total], path, 0.0, true, [true])
	_expect("sum_gt (total-1)", ["sum_gt"], [maxi(total - 1, 0)], path, 0.0, true, [true])
	_expect("sum_gt (total)", ["sum_gt"], [total], path, 0.0, true, [false])
	_expect("sum_ge (total)", ["sum_ge"], [total], path, 0.0, true, [true])


func _check_tools() -> void:
	_state.hints_used = 0
	_state.undos_used = 0
	_expect("no_hint · chưa dùng", ["no_hint"], [0], [], 0.0, false, [true])
	_expect("no_undo · chưa dùng", ["no_undo"], [0], [], 0.0, false, [true])
	_state.hints_used = 1
	_state.undos_used = 2
	_expect("no_hint · đã dùng 1", ["no_hint"], [0], [], 0.0, false, [false])
	_expect("no_undo · đã dùng 2", ["no_undo"], [0], [], 0.0, false, [false])
	_state.hints_used = 0
	_state.undos_used = 0


func _check_limits_and_level_data() -> void:
	# Tối đa 3 thử thách: khai báo 4 -> chỉ lấy 3 đầu
	var rows := _run(
		["no_wall", "steps_max", "time_max", "no_hint"],
		[0, 15, 45, 0],
		[],
		0.0,
		false
	)
	if rows.size() != ChallengeTypes.MAX_PER_LEVEL:
		_fail("Khai bao 4 thu thach phai bi cat con 3, dang co %d" % rows.size())

	# Loại thử thách lạ bị bỏ qua, phần còn lại giữ nguyên
	var lvl := LevelData.new()
	lvl.max_steps = 20
	lvl.challenge_types = PackedStringArray(["khong_ton_tai", "no_wall", "no_hint"])
	lvl.challenge_params = PackedInt32Array([0, 0, 0])
	var parsed := lvl.get_challenges()
	if parsed.size() != 2:
		_fail("Loai thu thach la phai bi bo qua, con lai 2, dang co %d" % parsed.size())
	elif str(parsed[0].get("type")) != "no_wall":
		_fail("Thu thach dau phai la no_wall, dang la '%s'" % str(parsed[0].get("type")))

	# Thiếu tham số -> game tự điền mặc định theo màn
	_cc.setup_for_floor(20, lvl)
	if _cc.rows().size() != 2:
		_fail("Man khai bao 2 thu thach phai co 2 dong, dang co %d" % _cc.rows().size())

	# Màn cũ (không khai báo) -> 3 thử thách mặc định
	_cc.setup_for_floor(20, null)
	var types: Array[String] = []
	for row in _cc.rows():
		types.append(str(row.get("type")))
	if types != ["no_wall", "steps_max", "time_max"]:
		_fail("Man cu phai dung 3 thu thach mac dinh, dang la %s" % str(types))
	print("[CHECK] Giới hạn 3 thử thách + đọc từ LevelData + mặc định cho màn cũ: OK")


# ---------------------------------------------------------------------------
# Helper
# ---------------------------------------------------------------------------
## Chạy 1 kịch bản và so sánh cờ `done` của từng thử thách
func _expect(
	label: String,
	types: Array,
	params: Array,
	path: Array[Vector2i],
	elapsed: float,
	is_final: bool,
	want_done: Array
) -> void:
	var rows := _run(types, params, path, elapsed, is_final)
	if rows.size() != want_done.size():
		_fail("%s: so dong thu thach = %d, mong doi %d" % [label, rows.size(), want_done.size()])
		return
	for i in rows.size():
		var got := bool(rows[i].get("done", false))
		if got != bool(want_done[i]):
			_fail("%s: thu thach '%s' done = %s, mong doi %s (trang thai '%s')"
				% [label, str(rows[i].get("type")), str(got), str(want_done[i]), str(rows[i].get("status"))])
		elif str(rows[i].get("status", "")).is_empty():
			_fail("%s: thu thach '%s' thieu chu trang thai" % [label, str(rows[i].get("type"))])


func _run(
	types: Array,
	params: Array,
	path: Array[Vector2i],
	elapsed: float,
	is_final: bool
) -> Array[Dictionary]:
	var lvl := LevelData.new()
	lvl.max_steps = 20
	var type_names := PackedStringArray()
	var param_values := PackedInt32Array()
	for t in types:
		type_names.append(str(t))
	for p in params:
		param_values.append(int(p))
	lvl.challenge_types = type_names
	lvl.challenge_params = param_values

	_cc.setup_for_floor(20, lvl)
	var ctx := ChallengeContext.new()
	ctx.set_values(_state, _mode, _maze, path, elapsed, is_final)
	_cc.refresh(ctx)
	return _cc.rows()


func _path_sum(path: Array[Vector2i]) -> int:
	var total := 0
	for pos in path:
		if pos == _maze.get_start() or pos == _maze.get_end():
			continue
		var text := _mode.get_cell_text(pos, _maze)
		if not text.is_empty() and text.is_valid_int():
			total += int(text)
	return total


func _fail(message: String) -> void:
	_failures += 1
	print("[FAIL] %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("[SUCCESS] 16 loai thu thach + gioi han 3/man hoat dong dung!")
	else:
		print("[FAILED] %d loi ve he thong thu thach." % _failures)
	quit(0)
