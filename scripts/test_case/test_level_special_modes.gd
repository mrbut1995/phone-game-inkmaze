extends SceneTree
## ============================================================================
## Test Case: MÀN CHƠI CHẾ ĐỘ SPECIAL + NÚT SKIP LEVEL
##
## 1. GameManager: ván MÀN đọc `mode_id`/`difficulty` từ LevelData (màn 13 = challenge,
##    màn 15 = blind_memory); cờ `level_run` bật cho ván màn, tắt cho Daily/Dungeon/Debug.
## 2. Chế độ Special chạy TRÊN BÀN CỦA MÀN: dùng đúng tường nhà thiết kế vẽ; luật thử thách /
##    trạng thái tường đọc từ LevelData nên chơi lại giống hệt; Daily vẫn tự sinh bàn.
## 3. skip_level(): mở khoá màn kế tiếp TRONG CHƯƠNG, KHÔNG ghi Sao; màn cuối chương -> -1.
## 4. Nút SKIP: có trong CẢ HAI action bar (dọc/ngang) và CHỈ HIỆN khi ván này là ván màn.
## 5. 'dungeon' bị loại khỏi màn (game chơi như 'play'); màn khai chế độ Special thì dùng đúng chế độ.
## 6. MỖI CHẾ ĐỘ 1 MÀN MẪU (13..17 — xem tools/level_designer/make_samples.py): chế độ chạy
##    ĐÚNG bàn nhà thiết kế vẽ, tường giữ nguyên, dữ liệu riêng (luật thử thách · ô khoá/chìa)
##    được tôn trọng.
##
## GHI CHÚ: 6 chế độ cũ (minesweeper · sum_path · countdown_cost · fading_ink · one_stroke ·
## fog_of_war dạng mode riêng) ĐÃ BỊ XOÁ — Fog of War nay là LUẬT thử thách `fog_of_war`.
## ============================================================================

## Màn mẫu (tools/level_designer/make_samples.py ghi vào resources/levels_samples/):
## 13 = challenge (walk_number_only) · 14 = challenge (fog_of_war) ·
## 15 = blind_memory · 16 = wall_builder · 17 = play có ô khoá + chìa
## Thư mục này CỐ Ý tách khỏi `resources/levels/` (id 10..17 đã là MÀN THẬT của game).
const SAMPLES_DIR := "res://data/levels_samples/"
## Thư mục màn THẬT — section 1/3/4 (GameManager · skip level · nút Skip) chạy trên màn thật
const LEVEL_SAMPLE := 13
const LEVEL_SAMPLE_BLIND := 15
## MỌI chế độ có 1 màn mẫu: level_id -> mode_id
const MODE_SAMPLES := {
	13: "challenge",
	14: "challenge",
	15: "blind_memory",
	16: "wall_builder",
	17: "play",
}
## Luật thử thách của 2 màn mẫu challenge
const SAMPLE_RULE := {
	13: "walk_number_only",
	14: "fog_of_war",
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
	var saved_dir := str(lm.call("get_levels_dir"))

	_section_1_level_run(gm, lm)
	_section_2_designed_board(gm, lm)
	_section_3_skip_level(gm, lm)
	await _section_4_skip_button(gm)
	_section_5_mode_edits(gm, lm)
	_section_6_all_mode_samples(gm, lm)

	lm.call("set_levels_dir", saved_dir)
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
func _section_1_level_run(gm: Node, lm: Node) -> void:
	print("--- 1. GAMEMANAGER: VAN MAN DOC CHE DO TU LevelData ---")

	# Màn THẬT (id 13) là màn thường
	var mode_saved := str(gm.call("prepare_level_run", LEVEL_SAMPLE))
	_check(mode_saved == str((lm.call("load_level", LEVEL_SAMPLE) as LevelData).mode_id),
		"Man 13 -> che do doc tu LevelData (dang '%s')" % mode_saved)
	_check(bool(gm.get("level_run")), "Van man: co `level_run` = true")
	_check(int(gm.get("current_level")) == LEVEL_SAMPLE, "Van man: current_level = 13")
	_check(str(gm.get("current_difficulty")) == str(gm.call("difficulty_of_level", LEVEL_SAMPLE)),
		"Van man: do kho lay tu LevelData ('%s')" % str(gm.get("current_difficulty")))

	# Màn khai chế độ Special: đọc đúng mode_id + độ khó từ file .tres
	var probe_dir := "user://probe_levels/"
	var saved_dir := str(lm.call("get_levels_dir"))
	DirAccess.make_dir_recursive_absolute(probe_dir)
	lm.call("set_levels_dir", probe_dir)
	var probe_blind := _probe_level("blind_memory")
	probe_blind.level_id = 74
	probe_blind.difficulty = "hard"
	lm.call("save_level", probe_blind)
	var probe_challenge := _probe_level("challenge")
	probe_challenge.level_id = 75
	lm.call("save_level", probe_challenge)

	_check(str(gm.call("prepare_level_run", 74)) == "blind_memory",
		"Man khai 'blind_memory' -> van man chay che do do")
	_check(str(gm.get("current_difficulty")) == "hard", "Do kho van man lay tu LevelData ('hard')")
	_check(str(gm.call("prepare_level_run", 75)) == "challenge",
		"Man khai 'challenge' -> van man chay che do do")
	lm.call("set_levels_dir", saved_dir)

	_check(str(gm.call("prepare_level_run", 1)) == "play", "Man thuong (id 1) -> che do 'play'")

	gm.call("prepare_daily_run", 1, "special")
	_check(not bool(gm.get("level_run")), "Daily: `level_run` = false")
	gm.call("prepare_mode_run", "challenge", "medium", true, 3)
	_check(not bool(gm.get("level_run")), "Van Debug/che do tu do: `level_run` = false")
	_check(str(gm.call("mode_id_of_level", 9999)) == "play", "Man khong ton tai -> mac dinh 'play'")


# ---------------------------------------------------------------------------
# 2. Bàn chơi = bàn nhà thiết kế vẽ + dữ liệu riêng cố định theo màn
# ---------------------------------------------------------------------------
func _section_2_designed_board(gm: Node, lm: Node) -> void:
	print("\n--- 2. CHE DO SPECIAL DUNG BAN CUA MAN (CO DINH KHI CHOI LAI) ---")

	# Màn mẫu nằm ở resources/levels_samples/ -> cho LevelManager trỏ vào đó
	var saved_dir := str(lm.call("get_levels_dir"))
	lm.call("set_levels_dir", SAMPLES_DIR)

	var lvl := lm.call("load_level", 13) as LevelData
	_check(lvl != null, "Nap duoc LevelData cua man mau 13")
	if lvl == null:
		return
	_check(str(lvl.mode_id) == "challenge", "File .tres man mau 13 khai mode_id = 'challenge'")

	# --- Challenge (luật walk_number_only) trên bàn của màn ---
	gm.call("prepare_level_run", 13)
	var mode := _new_mode("challenge", str(lvl.difficulty)) as ChallengeGameMode
	mode.current_level_data = lvl
	seed(13 * SEED_MULTIPLIER + SEED_OFFSET)
	var maze := mode.setup_floor(13)
	_check(maze != null and maze.width == lvl.width and maze.height == lvl.height,
		"Ban Challenge = dung kich thuoc man (%dx%d)" % [lvl.width, lvl.height])
	_check(_same_walls(maze, lvl.to_maze_data()), "Tuong cua ban = tuong nha thiet ke ve")
	_check(mode.is_active() and mode.challenge_id == "walk_number_only",
		"Luat thach thuc doc tu LevelData ('%s')" % mode.challenge_id)
	_check(mode.initial_steps >= int(lvl.max_steps),
		"Ngan sach buoc >= max_steps man (dang %d >= %d)" % [mode.initial_steps, int(lvl.max_steps)])
	_check(_has_rule_route(maze, mode), "Man mau 13: con duong S->F chi qua o CO SO")

	var mode_again := ChallengeGameMode.new(str(lvl.difficulty))
	mode_again.current_level_data = lvl
	seed(13 * SEED_MULTIPLIER + SEED_OFFSET)
	mode_again.setup_floor(13)
	_check(mode_again.challenge_id == mode.challenge_id,
		"Choi lai man: luat GIONG HET (%s)" % mode.challenge_id)

	# --- Blind Memory trên bàn của màn mẫu 15: tường bị ÉP ẨN khi chơi ---
	var lvl_blind := lm.call("load_level", 15) as LevelData
	_check(lvl_blind != null, "Nap duoc LevelData cua man mau 15")
	if lvl_blind == null:
		return
	gm.call("prepare_level_run", 15)
	var blind := BlindMemoryGameMode.new(str(lvl_blind.difficulty))
	blind.current_level_data = lvl_blind
	seed(15 * SEED_MULTIPLIER + SEED_OFFSET)
	var blind_maze := blind.setup_floor(15)
	_check(blind_maze != null and blind_maze.width == lvl_blind.width
		and blind_maze.height == lvl_blind.height,
		"Ban Blind Memory = dung kich thuoc man (%dx%d)" % [lvl_blind.width, lvl_blind.height])
	_check(_same_walls(blind_maze, lvl_blind.to_maze_data()), "Ban Blind Memory = tuong cua man mau")
	_check(not _any_wall_visible(blind_maze), "Blind Memory: tuong bi EP AN khi choi")

	# --- Ván KHÔNG phải ván màn: chế độ vẫn tự sinh bàn như trước ---
	gm.call("prepare_mode_run", "blind_memory", "medium", true, 3)
	var free_blind := BlindMemoryGameMode.new("medium")
	var free_maze := free_blind.setup_floor(3)
	_check(free_maze.width == 5 and free_maze.height == 5,
		"Daily tang 3: ban tu sinh 5x5 (dang %dx%d)" % [free_maze.width, free_maze.height])

	# --- Tiêu đề HUD: ván màn dùng ĐÚNG cách gọi của Play Mode ("MÀN nn") ---
	gm.call("prepare_level_run", 13)
	var titled := ChallengeGameMode.new("medium")
	titled.current_level_data = lvl
	var title := titled.get_hud_floor_title(13)
	_check(titled.is_level_run(), "Mode nhan dien duoc van man (is_level_run)")
	_check(title != titled.mode_name.to_upper(), "Tieu de HUD van man khac ten che do ('%s')" % title)

	lm.call("set_levels_dir", saved_dir)


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
		"res://scenes/objects/ui/hud/game/action_bar/portrait.tscn",
		"res://scenes/objects/ui/hud/game/action_bar/landscape.tscn",
	]:
		var packed := load(path) as PackedScene
		var bar := packed.instantiate() as ActionBar if packed != null else null
		_check(bar != null and bar.skip_btn() != null, "ActionBar co nut Skip (%s)" % path.get_file())
		_check(bar != null and bar.skip_btn().find_child("PanelLimit", true, false) != null,
			"Nut Skip co PanelLimit (%s)" % path.get_file())
		if bar != null:
			bar.free()

	# Ván THƯỜNG (Dungeon/Daily/Debug) -> nút Skip phải ẨN
	gm.call("prepare_mode_run", "play", "medium", true, 0)
	var scene: GameScene = (load("res://scenes/screens/game.tscn") as PackedScene).instantiate()
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
	scene.game_controller._update_hud()
	var skip_label := scene.skip_btn.find_child("Label", true, false) as Label
	_check(skip_label != null
		and skip_label.text == str(gm.call("tool_uses_left", GameManagerClass.TOOL_SKIP)),
		"Badge Skip hien so du dung chung")
	var saved_skip_uses := int(gm.call("tool_uses_left", GameManagerClass.TOOL_SKIP))
	gm.call("debug_set_tool_uses", GameManagerClass.TOOL_SKIP, 0)
	scene.game_controller._update_hud()
	_check(scene.skip_btn.disabled, "Het luot Skip: nut bi khoa")
	_check(not scene.game_controller.skip_current_level(),
		"Het luot Skip: bo qua man bi tu choi")
	gm.call("debug_set_tool_uses", GameManagerClass.TOOL_SKIP, saved_skip_uses)
	scene.game_controller._update_hud()

	scene.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# 5. 'dungeon' bị loại khỏi màn; màn khai chế độ Special thì dùng đúng chế độ
#    (KIỂU EDIT THEO CHẾ ĐỘ / custom_cell_values đã bị bỏ cùng 6 chế độ cũ)
# ---------------------------------------------------------------------------
func _section_5_mode_edits(gm: Node, lm: Node) -> void:
	print("\n--- 5. 'dungeon' BI LOAI KHOI MAN + MAN KHAI CHE DO SPECIAL ---")

	var saved_dir := str(lm.call("get_levels_dir"))
	var tmp_dir := "user://probe_levels/"
	DirAccess.make_dir_recursive_absolute(tmp_dir)
	lm.call("set_levels_dir", tmp_dir)

	var probe := _probe_level("dungeon")
	probe.level_id = 71
	lm.call("save_level", probe)
	_check(str(gm.call("mode_id_of_level", 71)) == "play",
		"Man khai 'dungeon' -> game choi nhu 'play' (dungeon la che do bat tan)")

	var probe_special := _probe_level("blind_memory")
	probe_special.level_id = 72
	lm.call("save_level", probe_special)
	_check(str(gm.call("mode_id_of_level", 72)) == "blind_memory",
		"Man khai che do Special -> game dung dung che do do")

	# Chế độ đã bị xoá -> game chơi như 'play' (không còn lớp game mode nào để chạy)
	var probe_removed := _probe_level("minesweeper")
	probe_removed.level_id = 73
	lm.call("save_level", probe_removed)
	_check(str(gm.call("mode_id_of_level", 73)) == "play",
		"Man khai che do DA XOA ('minesweeper') -> choi nhu 'play'")

	lm.call("set_levels_dir", saved_dir)


# ---------------------------------------------------------------------------
# 6. MỖI CHẾ ĐỘ 1 MÀN MẪU: chế độ chạy trên ĐÚNG bàn của màn + dữ liệu riêng được tôn trọng
# ---------------------------------------------------------------------------
func _section_6_all_mode_samples(gm: Node, lm: Node) -> void:
	print("\n--- 6. MOI CHE DO CO MAN MAU (resources/levels_samples) ---")

	# Màn mẫu nằm ở resources/levels_samples/ -> cho LevelManager trỏ vào đó
	var saved_dir := str(lm.call("get_levels_dir"))
	lm.call("set_levels_dir", SAMPLES_DIR)

	var ids: Array = MODE_SAMPLES.keys()
	ids.sort()
	for level_id: int in ids:
		var expected := str(MODE_SAMPLES[level_id])
		gm.call("prepare_level_run", level_id)
		var lvl := lm.call("load_level", level_id) as LevelData
		_check(lvl != null, "Man mau %d (%s): co file .tres" % [level_id, expected])
		if lvl == null:
			continue
		_check(str(lvl.mode_id) == expected, "Man mau %d khai mode_id = '%s'" % [level_id, expected])
		_check(int(lvl.chapter) == 2, "Man mau %d thuoc chuong 2" % level_id)
		_check(str(gm.call("mode_id_of_level", level_id)) == expected,
			"GameManager doc dung che do cua man mau %d" % level_id)

		# Chạy chế độ của màn trên đúng bàn thiết kế (cùng seed như GameController._seed_level_run)
		var mode := _new_mode(expected, str(lvl.difficulty))
		_check(mode != null, "Tao duoc che do '%s' cho man mau %d" % [expected, level_id])
		if mode == null:
			continue
		seed(level_id * SEED_MULTIPLIER + SEED_OFFSET)
		var maze := mode.setup_floor(level_id)
		var designed := lvl.to_maze_data()
		_check(maze != null and maze.width == lvl.width and maze.height == lvl.height
			and maze.get_start() == lvl.start_pos and maze.get_end() == lvl.end_pos,
			"Man mau %d (%s): ban choi DUNG ban thiet ke %dx%d S=%s F=%s"
				% [level_id, expected, lvl.width, lvl.height, lvl.start_pos, lvl.end_pos])
		_check(_same_walls(maze, designed), "Man mau %d (%s): tuong giu nguyen" % [level_id, expected])
		_check(_has_safe_route(maze), "Man mau %d (%s): van con duong S->F" % [level_id, expected])

		match expected:
			"challenge":
				# Luật + tham số đọc từ LevelData (tool Level Designer ghi) — tham số 0 = tự tính
				_check(mode.challenge_id == str(SAMPLE_RULE[level_id]),
					"Man %d: luat lay tu LevelData (dang '%s')" % [level_id, mode.challenge_id])
				_check(mode.is_active(), "Man %d: thach thuc duoc KICH HOAT" % level_id)
				_check(mode.challenge_param == 0,
					"Man %d: luat '%s' KHONG dung tham so -> param giu 0 (%d)"
						% [level_id, mode.challenge_id, mode.challenge_param])
				if mode.is_walk_rule():
					_check(_has_rule_route(maze, mode),
						"Man %d: co duong S->F chi qua o hop le theo luat" % level_id)
				if mode.is_fog_rule():
					# Sương mù là LUẬT: vào ván thì MỌI tường bị ẩn, chỉ quanh nhân vật mới sáng dần
					_check(not _any_wall_visible(maze),
						"Man %d (fog_of_war): luat suong mu AN toan bo tuong khi vao van" % level_id)
			"blind_memory", "wall_builder":
				_check(not _any_wall_visible(maze), "Man %d (%s): tuong bi EP AN khi choi" % [level_id, expected])
			"play":
				# Màn 17: ô KHOÁ + CHÌA KHOÁ (bộ ba x,y,id) — LevelData -> MazeData
				_check(lvl.lock_cells.size() == 3,
					"Man %d: co 1 o khoa trong lock_cells (dang %d so)" % [level_id, lvl.lock_cells.size()])
				_check(lvl.key_cells.size() == 3,
					"Man %d: co 1 chia khoa trong key_cells (dang %d so)" % [level_id, lvl.key_cells.size()])
				var lock_pos := Vector2i(lvl.lock_cells[0], lvl.lock_cells[1])
				var key_pos := Vector2i(lvl.key_cells[0], lvl.key_cells[1])
				var lock_id := int(lvl.lock_cells[2])
				_check(lock_id > 0 and int(lvl.key_cells[2]) == lock_id,
					"Man %d: chia khoa cung id voi o khoa (%d)" % [level_id, lock_id])
				_check(maze.lock_id_at(lock_pos) == lock_id,
					"Man %d: MazeData nhan o khoa %s (id %d)" % [level_id, lock_pos, lock_id])
				_check(maze.key_id_at(key_pos) == lock_id,
					"Man %d: MazeData nhan o chia %s (id %d)" % [level_id, key_pos, lock_id])
				# Đường (S -> F) phải đi QUA ô khoá (chìa mở được) — BFS có tập chìa
				var play_path := maze.get_play_path(maze.get_start(), maze.get_end())
				_check(play_path.size() > 1,
					"Man %d: co duong S->F khi tinh ca o khoa/chia (%d o)" % [level_id, play_path.size()])
				_check(play_path.has(lock_pos),
					"Man %d: duong ngan nhat BUOC phai qua o khoa" % level_id)
			_:
				pass

	lm.call("set_levels_dir", saved_dir)


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
		"blind_memory":
			return BlindMemoryGameMode.new(difficulty)
		"wall_builder":
			return WallBuilderGameMode.new(difficulty)
		"challenge":
			return ChallengeGameMode.new(difficulty)
		"play":
			return StandardGameMode.new(difficulty)
	return null


## Nạp 1 MÀN MẪU trong resources/levels_samples/ (không đi qua LevelManager vì thư mục
## này bắt đầu từ id 10 — bộ quét id của game chỉ chịu 3 lần trượt liên tiếp)
func _sample_level(level_id: int) -> LevelData:
	var path := "%slevel_%d.tres" % [SAMPLES_DIR, level_id]
	if not ResourceLoader.exists(path):
		return null
	return load(path) as LevelData


## LevelData nhỏ 3×3 (S góc dưới-trái, F góc trên-phải) mang đúng chế độ
func _probe_level(mode_id: String) -> LevelData:
	var lvl := LevelData.new()
	lvl.level_id = 901
	lvl.level_title = "Probe %s" % mode_id
	lvl.width = 3
	lvl.height = 3
	lvl.start_pos = Vector2i(0, 2)
	lvl.end_pos = Vector2i(2, 0)
	lvl.max_steps = 20
	lvl.mode_id = mode_id
	return lvl


## Còn đường S→F không (BFS theo tường của bàn)
func _has_safe_route(maze: MazeData) -> bool:
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
			seen[nxt] = true
			queue.append(nxt)
	return false


## Còn đường S→F chỉ qua các ô HỢP LỆ theo luật "đi trên ô" không (walk_number_only/walk_empty_only)
func _has_rule_route(maze: MazeData, mode: BaseGameMode) -> bool:
	if maze == null or mode == null:
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
			if not bool(mode.call("cell_allowed_by_rule", nxt, maze)):
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
