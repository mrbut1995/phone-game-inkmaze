extends SceneTree
## ============================================================================
## Test Case: MÀN CHƠI CHẾ ĐỘ SPECIAL + NÚT SKIP LEVEL (2026-09-27)
##
## 1. GameManager: ván MÀN đọc `mode_id`/`difficulty` từ LevelData (màn 13 = minesweeper,
##    màn 14 = sum_path); cờ `level_run` bật cho ván màn, tắt cho Daily/Dungeon/Debug.
## 2. Chế độ Special chạy TRÊN BÀN CỦA MÀN: dùng đúng tường nhà thiết kế vẽ, phần "gia vị"
##    (mìn · điểm ô) CỐ ĐỊNH theo level_id nên chơi lại giống hệt; Daily vẫn tự sinh bàn.
## 3. skip_level(): mở khoá màn kế tiếp TRONG CHƯƠNG, KHÔNG ghi Sao; màn cuối chương -> -1.
## 4. Nút SKIP: có trong CẢ HAI action bar (dọc/ngang) và CHỈ HIỆN khi ván này là ván màn.
## 5. KIỂU EDIT THEO CHẾ ĐỘ: Countdown Cost đọc chi phí tự đặt · Minesweeper giữ mìn GHIM
##    (bỏ mìn ghim nếu nó chặn hết đường) · Sum Path đọc điểm ô — và 'dungeon' bị loại khỏi màn.
## 6. MỖI CHẾ ĐỘ 1 MÀN MẪU (13..20 — xem tools/level_designer/make_samples.py): chế độ chạy
##    ĐÚNG bàn nhà thiết kế vẽ, tường giữ nguyên, dữ liệu riêng của chế độ được tôn trọng.
## ============================================================================

## Màn mẫu: 13 = Minesweeper, 14 = Sum Path (xem tools/level_designer/make_samples.py)
const LEVEL_SAMPLE := 13
const LEVEL_SAMPLE_SUM := 14
## MỌI chế độ có 1 màn mẫu: level_id -> mode_id (màn 15..20 thêm 2026-09-27)
const MODE_SAMPLES := {
	13: "minesweeper",
	14: "sum_path",
	15: "countdown_cost",
	16: "blind_memory",
	17: "fog_of_war",
	18: "fading_ink",
	19: "one_stroke",
	20: "wall_builder",
}
## Hằng số gieo hạt giống của GameController._seed_level_run (level_id * 7919 + 13)
const SEED_MULTIPLIER := 7919
const SEED_OFFSET := 13

var _failed := 0
var _checks := 0
var _backup := ""


func _init() -> void:
	print("\n========================================================")
	print("  TEST: MAN CHOI CHE DO SPECIAL + NUT SKIP LEVEL")
	print("========================================================\n")

	await process_frame
	root.size = Vector2i(1080, 1920)

	if FileAccess.file_exists("user://inkmaze_data.json"):
		var rf := FileAccess.open("user://inkmaze_data.json", FileAccess.READ)
		_backup = rf.get_as_text()

	var gm: Node = root.get_node_or_null("GameManager")
	assert(gm != null, "Autoload GameManager phai ton tai")
	var lm: Node = root.get_node_or_null("LevelManager")
	assert(lm != null, "Autoload LevelManager phai ton tai")

	var saved_mode := str(gm.get("current_mode"))
	var saved_diff := str(gm.get("current_difficulty"))
	var saved_level := int(gm.get("current_level"))
	var saved_level_run := bool(gm.get("level_run"))
	var saved_daily := str(gm.get("daily_variant"))
	var saved_debug := bool(gm.get("debug_run"))
	var saved_unlocked := int(gm.get("unlocked_levels"))
	var saved_chapters: Array = (gm.get("unlocked_chapters") as Array).duplicate()
	var saved_stars: Dictionary = (gm.get("level_stars") as Dictionary).duplicate()

	_section_1_level_run(gm)
	_section_2_designed_board(gm, lm)
	_section_3_skip_level(gm, lm)
	await _section_4_skip_button(gm)
	_section_5_mode_edits(gm, lm)
	_section_6_all_mode_samples(gm, lm)

	gm.set("current_mode", saved_mode)
	gm.set("current_difficulty", saved_diff)
	gm.set("current_level", saved_level)
	gm.set("level_run", saved_level_run)
	gm.set("daily_variant", saved_daily)
	gm.set("debug_run", saved_debug)
	gm.set("unlocked_levels", saved_unlocked)
	gm.set("unlocked_chapters", saved_chapters)
	gm.set("level_stars", saved_stars)
	if not _backup.is_empty():
		var wf := FileAccess.open("user://inkmaze_data.json", FileAccess.WRITE)
		wf.store_string(_backup)
	print("[INFO] Da khoi phuc trang thai GameManager.")

	print("\n--------------------------------------------------------")
	if _failed == 0:
		print("  KET QUA: %d/%d CHECK PASS" % [_checks, _checks])
	else:
		print("  KET QUA: %d/%d CHECK FAIL" % [_failed, _checks])
	print("--------------------------------------------------------\n")
	quit(1 if _failed > 0 else 0)


# ---------------------------------------------------------------------------
# 1. Ván MÀN: mode + độ khó đọc từ LevelData, cờ `level_run`
# ---------------------------------------------------------------------------
func _section_1_level_run(gm: Node) -> void:
	print("--- 1. GAMEMANAGER: VAN MAN DOC CHE DO TU LevelData ---")

	var mode_id := str(gm.call("prepare_level_run", LEVEL_SAMPLE))
	_check(mode_id == "minesweeper", "Man 13 -> che do 'minesweeper' (dang '%s')" % mode_id)
	_check(bool(gm.get("level_run")), "Van man: co `level_run` = true")
	_check(int(gm.get("current_level")) == LEVEL_SAMPLE, "Van man: current_level = 13")
	_check(str(gm.get("current_difficulty")) == str(gm.call("difficulty_of_level", LEVEL_SAMPLE)),
		"Van man: do kho lay tu LevelData ('%s')" % str(gm.get("current_difficulty")))

	var mode_sum := str(gm.call("prepare_level_run", LEVEL_SAMPLE_SUM))
	_check(mode_sum == "sum_path", "Man 14 -> che do 'sum_path' (dang '%s')" % mode_sum)
	_check(str(gm.get("current_difficulty")) == "hard", "Man 14: do kho 'hard' tu LevelData")

	var mode_plain := str(gm.call("prepare_level_run", 1))
	_check(mode_plain == "play", "Man thuong (id 1) -> che do 'play'")

	gm.call("prepare_daily_run", 1, "special")
	_check(not bool(gm.get("level_run")), "Daily: `level_run` = false")
	gm.call("prepare_mode_run", "minesweeper", "medium", true, 3)
	_check(not bool(gm.get("level_run")), "Van Debug/che do tu do: `level_run` = false")
	_check(str(gm.call("mode_id_of_level", 9999)) == "play", "Man khong ton tai -> mac dinh 'play'")


# ---------------------------------------------------------------------------
# 2. Bàn chơi = bàn nhà thiết kế vẽ + "gia vị" cố định theo màn
# ---------------------------------------------------------------------------
func _section_2_designed_board(gm: Node, lm: Node) -> void:
	print("\n--- 2. CHE DO SPECIAL DUNG BAN CUA MAN (CO DINH KHI CHOI LAI) ---")

	var lvl := lm.call("load_level", LEVEL_SAMPLE) as LevelData
	_check(lvl != null, "Nap duoc LevelData cua man 13")
	if lvl == null:
		return
	_check(str(lvl.mode_id) == "minesweeper", "File .tres man 13 khai mode_id = 'minesweeper'")

	# --- Minesweeper trên bàn của màn ---
	gm.call("prepare_level_run", LEVEL_SAMPLE)
	var mines := MinesweeperPathGameMode.new()
	seed(LEVEL_SAMPLE * SEED_MULTIPLIER + SEED_OFFSET)
	var maze := mines.setup_floor(LEVEL_SAMPLE)
	_check(maze != null and maze.width == lvl.width and maze.height == lvl.height,
		"Ban Minesweeper = dung kich thuoc man (%dx%d)" % [lvl.width, lvl.height])
	_check(_same_walls(maze, lvl.to_maze_data()), "Tuong cua ban = tuong nha thiet ke ve")
	_check(mines.get_total_mines() > 0, "Min duoc rai tren ban (tong %d)" % mines.get_total_mines())
	_check(mines.initial_steps >= 25, "Ngan sach buoc >= mac dinh che do (dang %d)" % mines.initial_steps)
	var info_first := mines.get_hud_extra_info()

	var mines_again := MinesweeperPathGameMode.new()
	seed(LEVEL_SAMPLE * SEED_MULTIPLIER + SEED_OFFSET)
	mines_again.setup_floor(LEVEL_SAMPLE)
	_check(mines_again.get_hud_extra_info() == info_first,
		"Choi lai man: so min GIONG HET (%s)" % info_first)
	_check(mines.is_mine(Vector2i(0, 2)) and mines.is_mine(Vector2i(2, 3)),
		"Man mau 13: 2 min GHIM trong file .tres co mat tren ban")
	_check(_has_safe_route(maze, mines), "Man mau 13: van con duong S->F tranh moi min")
	# --- Sum Path trên bàn của màn ---
	gm.call("prepare_level_run", LEVEL_SAMPLE_SUM)
	var lvl_sum := lm.call("load_level", LEVEL_SAMPLE_SUM) as LevelData
	var sum_mode := SumPathGameMode.new(str(lvl_sum.difficulty))
	seed(LEVEL_SAMPLE_SUM * SEED_MULTIPLIER + SEED_OFFSET)
	var sum_maze := sum_mode.setup_floor(LEVEL_SAMPLE_SUM)
	_check(sum_maze != null and sum_maze.width == lvl_sum.width and sum_maze.height == lvl_sum.height,
		"Ban Sum Path = dung kich thuoc man (%dx%d)" % [lvl_sum.width, lvl_sum.height])
	_check(_same_walls(sum_maze, lvl_sum.to_maze_data()), "Ban Sum Path = tuong cua man 14")
	_check(sum_mode.target_val > 0, "Sum Path co muc tieu > 0 (%s %d)" % [sum_mode.operator, sum_mode.target_val])
	_check(sum_mode.initial_steps >= 24, "Sum Path ngan sach buoc >= max_steps man (dang %d)" % sum_mode.initial_steps)
	var probe := sum_mode.get_cell_text(Vector2i(1, 1), sum_maze)

	var sum_again := SumPathGameMode.new(str(lvl_sum.difficulty))
	seed(LEVEL_SAMPLE_SUM * SEED_MULTIPLIER + SEED_OFFSET)
	var sum_maze_again := sum_again.setup_floor(LEVEL_SAMPLE_SUM)
	_check(sum_again.target_val == sum_mode.target_val
		and sum_again.get_cell_text(Vector2i(1, 1), sum_maze_again) == probe,
		"Sum Path choi lai: diem o + muc tieu GIONG HET")

	# --- Ván KHÔNG phải ván màn: chế độ vẫn tự sinh bàn như trước ---
	gm.call("prepare_mode_run", "minesweeper", "medium", true, 3)
	var daily_mines := MinesweeperPathGameMode.new()
	var daily_maze := daily_mines.setup_floor(3)
	_check(daily_maze.width == 5 and daily_maze.height == 5,
		"Daily tang 3: ban tu sinh 5x5 (dang %dx%d)" % [daily_maze.width, daily_maze.height])

	# --- Tiêu đề HUD: ván màn dùng ĐÚNG cách gọi của Play Mode ("MÀN nn") ---
	gm.call("prepare_level_run", LEVEL_SAMPLE)
	var titled := MinesweeperPathGameMode.new()
	var title := titled.get_hud_floor_title(LEVEL_SAMPLE)
	_check(titled.is_level_run(), "Mode nhan dien duoc van man (is_level_run)")
	_check(title != titled.mode_name.to_upper(), "Tieu de HUD van man khac ten che do ('%s')" % title)


# ---------------------------------------------------------------------------
# 3. skip_level(): mở khoá màn kế, KHÔNG ghi Sao
# ---------------------------------------------------------------------------
func _section_3_skip_level(gm: Node, lm: Node) -> void:
	print("\n--- 3. SKIP LEVEL: MO KHOA MAN KE TRONG CHUONG, KHONG GHI SAO ---")

	_check(int(gm.call("chapter_of_level", LEVEL_SAMPLE)) == 2, "Man 13 thuoc chuong 2")
	_check(int(gm.call("chapter_of_level", LEVEL_SAMPLE + 1)) == 2, "Man 14 cung chuong 2")

	# ĐIỀU KIỆN MÔI TRƯỜNG: skip_level() cố ý KHÔNG mở màn thuộc chương còn khoá, nên phải
	# bảo đảm chương chứa màn kế đang mở — save cục bộ của máy dev có thể chỉ mới tới chương 1
	# (đã backup/restore unlocked_chapters ở main() nên không ảnh hưởng save thật).
	var unlocked: Array = (gm.get("unlocked_chapters") as Array).duplicate()
	var chapter_next := int(gm.call("chapter_of_level", LEVEL_SAMPLE + 1))
	if not unlocked.has(chapter_next):
		unlocked.append(chapter_next)
		gm.set("unlocked_chapters", unlocked)

	var stars_before: Dictionary = (gm.get("level_stars") as Dictionary).duplicate()
	var next_id := int(gm.call("skip_level", LEVEL_SAMPLE))
	_check(next_id == LEVEL_SAMPLE + 1, "skip_level(13) -> man ke = 14 (dang %d)" % next_id)
	_check(int(gm.get("unlocked_levels")) >= LEVEL_SAMPLE + 1,
		"Mo khoa man 14 (unlocked_levels = %d)" % int(gm.get("unlocked_levels")))

	var stars_after: Dictionary = gm.get("level_stars")
	_check(stars_after.size() == stars_before.size(),
		"Skip KHONG them Sao (so man co Sao: %d -> %d)" % [stars_before.size(), stars_after.size()])
	_check(int(stars_after.get(LEVEL_SAMPLE, 0)) == int(stars_before.get(LEVEL_SAMPLE, 0)),
		"Man 13 khong duoc ghi Sao khi bam Skip")

	var last_in_chapter := int(gm.call("skip_level", _last_level_in_chapter(lm, 2)))
	_check(last_in_chapter == -1,
		"Man cuoi chuong 2 (%d): skip_level -> -1 (dang %d)" % [_last_level_in_chapter(lm, 2), last_in_chapter])


# ---------------------------------------------------------------------------
# 4. Nút SKIP trên thanh hành động
# ---------------------------------------------------------------------------
func _section_4_skip_button(gm: Node) -> void:
	print("\n--- 4. NUT SKIP: CO O CA 2 HUONG + CHI HIEN KHI CHOI MAN ---")

	for path in [
		"res://nodes/hud/portrait/game/action_bar.tscn",
		"res://nodes/hud/landscape/game/action_bar.tscn",
	]:
		var packed := load(path) as PackedScene
		var bar := packed.instantiate() as ActionBar if packed != null else null
		_check(bar != null and bar.skip_btn() != null, "ActionBar co nut Skip (%s)" % path.get_file())
		if bar != null:
			bar.free()

	# Ván THƯỜNG (Dungeon/Daily/Debug) -> nút Skip phải ẨN
	gm.call("prepare_mode_run", "play", "medium", true, 0)
	var scene: GameScene = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	_check(scene.skip_btn != null, "GameScene lay duoc nut Skip tu HUD dang choi")
	if scene.skip_btn == null:
		scene.queue_free()
		await process_frame
		return
	_check(not scene.skip_btn.visible, "Van khong phai van man: nut Skip AN")
	_check(scene.skip_btn.pressed.is_connected(Callable(scene, "_on_skip_pressed")),
		"Nut Skip da noi vao _on_skip_pressed")
	_check(not scene.game_controller.skip_current_level(),
		"Van khong phai van man: skip_current_level() -> false (khong chuyen man)")

	# Ván MÀN -> nút Skip HIỆN
	gm.call("prepare_level_run", LEVEL_SAMPLE)
	scene._apply_mode_buttons(str(gm.get("current_mode")))
	_check(scene.skip_btn.visible, "Van man: nut Skip HIEN")

	scene.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# 5. Dữ liệu nhà thiết kế tô trong tool (custom_cell_values) theo KIỂU EDIT của chế độ
# ---------------------------------------------------------------------------
func _section_5_mode_edits(gm: Node, lm: Node) -> void:
	print("\n--- 5. KIEU EDIT THEO CHE DO: CHI PHI O · MIN GHIM · DIEM O ---")

	# --- Countdown Cost: chi phí tô tay được giữ đúng (ô không tô thì random theo độ khó) ---
	var cost_mode := CountdownCostGameMode.new("medium")
	cost_mode.current_level_data = _probe_level("countdown_cost", {"0,1": 1, "1,1": 4})
	seed(4242)
	var cost_maze := cost_mode.setup_floor(1)
	_check(cost_mode.get_step_cost(Vector2i(0, 1), Vector2i(1, 1), cost_maze) == 4,
		"Countdown Cost: chi phí ô (1,1) = 4 như nhà thiết kế tô")
	_check(cost_mode.get_cell_text(Vector2i(0, 1), cost_maze) == "1",
		"Countdown Cost: số trên ô (0,1) = 1 như nhà thiết kế tô")
	_check(cost_maze.get_shortest_path(cost_maze.get_start(), cost_maze.get_end()).size() > 0,
		"Countdown Cost: bàn của màn vẫn có đường tới F")

	# --- Sum Path: điểm ô tô tay được giữ đúng ---
	var sum_mode := SumPathGameMode.new("medium")
	sum_mode.current_level_data = _probe_level("sum_path", {"0,1": 9})
	seed(4243)
	var sum_maze := sum_mode.setup_floor(1)
	_check(sum_mode.get_cell_text(Vector2i(0, 1), sum_maze) == "9",
		"Sum Path: điểm ô (0,1) = 9 như nhà thiết kế tô")

	# --- Minesweeper: mìn GHIM được giữ, và luôn còn đường an toàn ---
	var mines := MinesweeperPathGameMode.new()
	mines.current_level_data = _probe_level("minesweeper", {"1,1": 1})
	seed(4244)
	var mine_maze := mines.setup_floor(1)
	_check(mines.is_mine(Vector2i(1, 1)), "Minesweeper: ô (1,1) là mìn GHIM trong tool")
	_check(_has_safe_route(mine_maze, mines), "Minesweeper: luôn còn đường S→F tránh mọi mìn")

	# --- Minesweeper: mìn ghim CHẶN HẾT đường thì game tự bỏ (màn vẫn thắng được) ---
	var blocked := MinesweeperPathGameMode.new()
	blocked.current_level_data = _corridor_level({"1,0": 1})
	seed(4245)
	var corridor := blocked.setup_floor(1)
	_check(not blocked.is_mine(Vector2i(1, 0)),
		"Minesweeper: mìn ghim chặn hết đường S→F bị BỎ (màn không thể thua vì bàn vô nghiệm)")
	_check(_has_safe_route(corridor, blocked), "Minesweeper: bàn hành lang vẫn có đường an toàn")

	# --- 'dungeon' KHÔNG dùng được cho màn: game coi như 'play' ---
	var saved_dir := str(lm.call("get_levels_dir"))
	var tmp_dir := "user://probe_levels/"
	DirAccess.make_dir_recursive_absolute(tmp_dir)
	lm.call("set_levels_dir", tmp_dir)
	var probe := _probe_level("dungeon", {})
	probe.level_id = 71
	lm.call("save_level", probe)
	_check(str(gm.call("mode_id_of_level", 71)) == "play",
		"Màn khai 'dungeon' -> game chơi như 'play' (dungeon là chế độ bất tận)")
	var probe_special := _probe_level("sum_path", {})
	probe_special.level_id = 72
	lm.call("save_level", probe_special)
	_check(str(gm.call("mode_id_of_level", 72)) == "sum_path",
		"Màn khai chế độ Special -> game dùng đúng chế độ đó")
	lm.call("set_levels_dir", saved_dir)


# ---------------------------------------------------------------------------
# 6. MỖI CHẾ ĐỘ 1 MÀN MẪU: chế độ chạy trên ĐÚNG bàn của màn + dữ liệu riêng được tôn trọng
# ---------------------------------------------------------------------------
func _section_6_all_mode_samples(gm: Node, lm: Node) -> void:
	print("\n--- 6. MOI CHE DO CO MAN MAU (13..20) ---")

	var ids: Array = MODE_SAMPLES.keys()
	ids.sort()
	for level_id: int in ids:
		var expected := str(MODE_SAMPLES[level_id])
		var lvl := lm.call("load_level", level_id) as LevelData
		_check(lvl != null, "Man %d (%s): co file .tres" % [level_id, expected])
		if lvl == null:
			continue
		_check(str(lvl.mode_id) == expected, "Man %d khai mode_id = '%s'" % [level_id, expected])
		_check(int(lm.call("chapter_of_level", level_id)) == 2, "Man %d thuoc chuong 2" % level_id)
		_check(str(gm.call("mode_id_of_level", level_id)) == expected,
			"GameManager doc dung che do cua man %d" % level_id)

		# Chạy chế độ của màn trên đúng bàn thiết kế (cùng seed như GameController._seed_level_run)
		gm.call("prepare_level_run", level_id)
		var mode := _new_mode(expected, str(lvl.difficulty))
		if mode == null:
			_check(false, "Tao duoc che do '%s' cho man %d" % [expected, level_id])
			continue
		seed(level_id * SEED_MULTIPLIER + SEED_OFFSET)
		var maze := mode.setup_floor(level_id)
		var designed := lvl.to_maze_data()
		_check(maze != null and maze.width == lvl.width and maze.height == lvl.height
			and maze.get_start() == lvl.start_pos and maze.get_end() == lvl.end_pos,
			"Man %d (%s): ban choi DUNG ban thiet ke %dx%d S=%s F=%s"
				% [level_id, expected, lvl.width, lvl.height, lvl.start_pos, lvl.end_pos])
		_check(_same_walls(maze, designed), "Man %d (%s): tuong giu nguyen" % [level_id, expected])
		_check(_has_safe_route(maze, mode), "Man %d (%s): van con duong S->F" % [level_id, expected])

		match expected:
			"minesweeper":
				_check(mode.get_total_mines() > 0, "Man 13: co min tren ban")
			"sum_path":
				# Tổng điểm của ĐƯỜNG NGẮN NHẤT phải = đúng tổng nhà thiết kế tô trong tool (60)
				_check(mode.target_val > 0, "Man 14: co muc tieu tong diem (%d)" % mode.target_val)
				var sum_shortest := maze.get_shortest_path(maze.get_start(), maze.get_end())
				var path_total := 0
				for p: Vector2i in sum_shortest:
					if p == maze.get_start() or p == maze.get_end():
						continue
					path_total += int(mode.get_cell_text(p, maze))
				var design_total := 0
				for key in lvl.custom_cell_values.keys():
					design_total += int(lvl.custom_cell_values[key])
				_check(path_total == design_total,
					"Man 14: tổng điểm đường ngắn nhất = tổng đã tô trong tool (%d)" % design_total)
			"countdown_cost":
				# Chi phí tô tay giữ đúng (màn 15 = 8 ô, tổng 30 bước)
				_check(mode.get_cell_text(Vector2i(3, 1), maze) == "4",
					"Man 15: chi phi o (3,1) = 4 nhu tool to")
				_check(mode.get_cell_text(Vector2i(3, 2), maze) == "3",
					"Man 15: chi phi o (3,2) = 3 nhu tool to")
				var painted_total := 0
				for key in lvl.custom_cell_values.keys():
					painted_total += int(lvl.custom_cell_values[key])
				_check(painted_total == 30, "Man 15: tong chi phi da to = 30 (dang %d)" % painted_total)
				_check(mode.initial_steps >= int(lvl.max_steps),
					"Man 15: ngan sach ton trong max_steps cua man (%d >= %d)"
						% [mode.initial_steps, int(lvl.max_steps)])
			"blind_memory", "fog_of_war", "wall_builder":
				_check(not _any_wall_visible(maze), "Man %d (%s): tuong bi EP AN khi choi" % [level_id, expected])
			"fading_ink":
				var shortest := maze.get_shortest_path(maze.get_start(), maze.get_end())
				_check(int(mode.get("design_moves")) == maxi(shortest.size() - 1, 0),
					"Man 18: muc cap theo duong ngan nhat (%d)" % int(mode.get("design_moves")))
				# MỰC tô tay trong tool được giữ ĐÚNG (ô ở bước j có mực = j + 3, kẹp 9)
				_check(int(mode.call("ink_initial", Vector2i(1, 0))) == 4,
					"Man 18: muc o (1,0) = 4 nhu tool to")
				_check(int(mode.call("ink_initial", Vector2i(3, 0))) == 6,
					"Man 18: muc o (3,0) = 6 nhu tool to")
				var ink_steps := 0
				for key in lvl.custom_cell_values.keys():
					var pos := Vector2i(int(str(key).split(",")[0]), int(str(key).split(",")[1]))
					if int(mode.call("ink_left", pos)) <= 0:
						ink_steps += 1
				_check(ink_steps == 0, "Man 18: luc dau MOI o da to con muc (%d o het muc)" % ink_steps)
			"one_stroke":
				_check(int(mode.call("total_cells")) == lvl.width * lvl.height,
					"Man 19: che do PHU KIN duoc ca %d o (khong roi ve ban tu sinh)" % (lvl.width * lvl.height))
				_check(_has_no_inner_wall(maze), "Man 19: ban trong (chi co vien ngoai) — du dieu kien phu kin")
			_:
				pass

	# --- Sum Path: S/F KHÔNG tính điểm (nhờ vậy tổng khớp đúng số nhà thiết kế tô) ---
	var sum_probe := SumPathGameMode.new("medium", "=")
	sum_probe.current_level_data = _probe_level("sum_path", {"1,1": 5, "0,2": 9, "2,0": 9})
	seed(4246)
	var probe_maze := sum_probe.setup_floor(1)
	_check(sum_probe.current_sum == 0, "Sum Path: vua vao man tong = 0 (S khong tinh diem)")
	var probe_path := probe_maze.get_shortest_path(probe_maze.get_start(), probe_maze.get_end())
	var probe_total := 0
	for p: Vector2i in probe_path:
		if p == probe_maze.get_start() or p == probe_maze.get_end():
			continue
		probe_total += int(sum_probe.get_cell_text(p, probe_maze))
	_check(sum_probe.target_val == probe_total,
		"Sum Path: muc tieu '=' = tong cac o DI QUA, KHONG tinh S/F (%d)" % probe_total)


## Bàn KHÔNG có tường bên trong (chỉ viền ngoài) — điều kiện để One Stroke phủ kín dễ dàng
func _has_no_inner_wall(maze: MazeData) -> bool:
	if maze == null:
		return false
	for ix in range(1, maze.width):
		for iy in maze.height:
			if maze.has_v_wall(ix, iy):
				return false
	for ix in maze.width:
		for iy in range(1, maze.height):
			if maze.has_h_wall(ix, iy):
				return false
	return true


## Màn cuối cùng của 1 chương (id lớn nhất) — dùng cho check "skip ở màn cuối -> -1"
func _last_level_in_chapter(lm: Node, chapter_id: int) -> int:
	var ids: Array = lm.call("levels_in_chapter", chapter_id)
	if ids.is_empty():
		return -1
	return int(ids[ids.size() - 1])


## Có tường nào đang HIỆN không (kiểm chế độ ÉP ẨN toàn bộ tường)
func _any_wall_visible(maze: MazeData) -> bool:
	if maze == null:
		return false
	for ix in maze.width + 1:
		for iy in maze.height:
			if maze.is_v_wall_visible(ix, iy):
				return true
	for ix in maze.width:
		for iy in maze.height + 1:
			if maze.is_h_wall_visible(ix, iy):
				return true
	return false


## Tạo chế độ theo id (giống bảng chọn trong Debug Console)
func _new_mode(mode_id: String, difficulty: String) -> BaseGameMode:
	match mode_id:
		"minesweeper":
			return MinesweeperPathGameMode.new()
		"sum_path":
			return SumPathGameMode.new(difficulty)
		"countdown_cost":
			return CountdownCostGameMode.new(difficulty)
		"blind_memory":
			return BlindMemoryGameMode.new(difficulty)
		"fog_of_war":
			return FogOfWarGameMode.new(difficulty)
		"fading_ink":
			return FadingInkGameMode.new(difficulty)
		"one_stroke":
				return OneStrokeGameMode.new(difficulty)
		"wall_builder":
			return WallBuilderGameMode.new(difficulty)
	return null


## LevelData nhỏ 3×3 (S góc dưới-trái, F góc trên-phải) mang đúng chế độ + dữ liệu tô tay
func _probe_level(mode_id: String, custom: Dictionary) -> LevelData:
	var lvl := LevelData.new()
	lvl.level_id = 901
	lvl.level_title = "Probe %s" % mode_id
	lvl.width = 3
	lvl.height = 3
	lvl.start_pos = Vector2i(0, 2)
	lvl.end_pos = Vector2i(2, 0)
	lvl.max_steps = 20
	lvl.mode_id = mode_id
	lvl.custom_cell_values = custom
	return lvl


## Bàn HÀNH LANG 3×2: S=(0,1) -> F=(2,0) chỉ có DUY NHẤT 1 đường (hàng dưới là nhánh cụt)
func _corridor_level(custom: Dictionary) -> LevelData:
	var lvl := _probe_level("minesweeper", custom)
	lvl.level_id = 902
	lvl.width = 3
	lvl.height = 2
	lvl.start_pos = Vector2i(0, 1)
	lvl.end_pos = Vector2i(2, 0)
	var h := PackedByteArray()
	h.resize(lvl.width * (lvl.height + 1))
	h.fill(0)
	h[1 * (lvl.height + 1) + 1] = 1     # h(1,1): chặn (1,0)-(1,1)
	h[2 * (lvl.height + 1) + 1] = 1     # h(2,1): chặn (2,0)-(2,1)
	lvl.h_walls = h
	var v := PackedByteArray()
	v.resize((lvl.width + 1) * lvl.height)
	v.fill(0)
	lvl.v_walls = v
	return lvl


## Còn đường S→F KHÔNG đi qua ô mìn nào không (BFS tránh mìn)
func _has_safe_route(maze: MazeData, mode: BaseGameMode) -> bool:
	if maze == null:
		return false
	var start := maze.get_start()
	var end := maze.get_end()
	var seen := {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var cur: Vector2i = queue.pop_front()
		if cur == end:
			return true
		for d: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT]:
			var nxt: Vector2i = cur + d
			if seen.has(nxt) or not maze.is_in_bounds(nxt) or not maze.is_cell_active(nxt):
				continue
			if maze.has_wall(cur, nxt):
				continue
			if mode != null and mode.has_method("is_mine") and bool(mode.call("is_mine", nxt)):
				continue
			seen[nxt] = true
			queue.append(nxt)
	return false


# ---------------------------------------------------------------------------
# Tiện ích
# ---------------------------------------------------------------------------
func _same_walls(a: MazeData, b: MazeData) -> bool:
	if a == null or b == null or a.width != b.width or a.height != b.height:
		return false
	for ix in a.width + 1:
		for iy in a.height:
			if a.has_v_wall(ix, iy) != b.has_v_wall(ix, iy):
				return false
	for ix in a.width:
		for iy in a.height + 1:
			if a.has_h_wall(ix, iy) != b.has_h_wall(ix, iy):
				return false
	return true


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failed += 1
	print("[%s] %s" % ["CHECK" if condition else "FAIL", label])
