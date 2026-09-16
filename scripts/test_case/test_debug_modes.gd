extends SceneTree
## ============================================================================
## Test Case: DEBUG CONSOLE — TEST 7 CHẾ ĐỘ SPECIAL (2026-02)
##
## 1. GameManager: prepare_mode_run() đặt đúng mode · độ khó · cờ ván test · tầng ép.
## 2. GameModeController: 7 id Special map đúng sang class mode (mode_id khớp).
## 3. DebugScene: có mục "SPECIAL MODES" + 1 hàng lệnh cho mỗi chế độ + toggle test mode.
## 4. Ván TEST không ghi tiến trình (không đánh dấu Daily, không báo danh hiệu).
## 5. Tầng ép: minesweeper ở tầng 3 -> bàn 5x5 (2 + tầng), tầng 1 -> 3x3.
## ============================================================================

const MINESWEEPER := "minesweeper"

var _backup := ""
var _failed := 0
var _checks := 0


func _init() -> void:
	print("\n========================================================")
	print("  TEST: DEBUG CONSOLE — 7 CHE DO SPECIAL")
	print("========================================================\n")

	await process_frame
	root.size = Vector2i(1080, 1920)

	if FileAccess.file_exists("user://inkmaze_data.json"):
		var rf := FileAccess.open("user://inkmaze_data.json", FileAccess.READ)
		_backup = rf.get_as_text()

	var gm: Node = root.get_node_or_null("GameManager")
	var dm: Node = root.get_node_or_null("DailyManager")
	assert(gm != null, "Autoload GameManager phai ton tai")
	assert(dm != null, "Autoload DailyManager phai ton tai")

	var saved_mode := str(gm.get("current_mode"))
	var saved_diff := str(gm.get("current_difficulty"))
	var saved_test := bool(gm.get("debug_run"))
	var saved_floor := int(gm.get("start_floor_override"))
	var today := int(dm.call("get_today"))
	var today_mask := int(dm.call("get_day_mission_mask", today))
	var arch: Node = root.get_node_or_null("ArchivementManager")
	var saved_seconds := int(arch.call("stat_value", "play_seconds")) if arch != null else 0

	_section_1_game_manager(gm)
	_section_2_mode_mapping(gm)
	await _section_3_debug_scene(gm)
	await _section_4_no_progress(gm, dm, today, today_mask, arch)
	await _section_5_floor_override(gm)

	# Khôi phục trạng thái (không phá dữ liệu người chơi)
	gm.set("current_mode", saved_mode)
	gm.set("current_difficulty", saved_diff)
	gm.set("debug_run", saved_test)
	gm.set("start_floor_override", saved_floor)
	dm.call("set_day_mission_mask", today, today_mask)
	if arch != null:
		arch.call("set_stat_for_test", "play_seconds", saved_seconds)
	if not _backup.is_empty():
		var wf := FileAccess.open("user://inkmaze_data.json", FileAccess.WRITE)
		wf.store_string(_backup)
	print("[INFO] Da khoi phuc trang thai GameManager/Daily/danh hieu.")

	print("\n--------------------------------------------------------")
	if _failed == 0:
		print("  KET QUA: %d/%d CHECK PASS" % [_checks, _checks])
	else:
		print("  KET QUA: %d/%d CHECK FAIL" % [_failed, _checks])
	print("--------------------------------------------------------\n")
	quit(1 if _failed > 0 else 0)


# ---------------------------------------------------------------------------
# 1. GameManager API
# ---------------------------------------------------------------------------
func _section_1_game_manager(gm: Node) -> void:
	print("--- 1. GAMEMANAGER: CO VAN TEST + TANG EP ---")
	var ids: Array = gm.call("special_mode_ids")
	_check(ids.size() == 7, "Liet ke dung 7 che do Special (dang %d)" % ids.size())

	for mode_id in ids:
		gm.call("prepare_mode_run", str(mode_id), "hard", true, 3)
		var ok := str(gm.get("current_mode")) == str(mode_id) \
			and str(gm.get("current_difficulty")) == "hard" \
			and bool(gm.get("debug_run")) \
			and int(gm.get("start_floor_override")) == 3
		_check(ok, "prepare_mode_run('%s', hard, test, 3) -> mode/do kho/co test/tang dung" % mode_id)

	gm.call("prepare_mode_run", "dungeon", "medium", false, 0)
	_check(not bool(gm.get("debug_run")), "Van thuong: co van TEST tat")
	_check(int(gm.get("start_floor_override")) == 0, "Van thuong: khong ep tang")


# ---------------------------------------------------------------------------
# 2. Map id -> mode class
# ---------------------------------------------------------------------------
func _section_2_mode_mapping(gm: Node) -> void:
	print("\n--- 2. GAME MODE CONTROLLER: MAP ID -> MODE ---")
	var controller := GameModeController.new()
	var count := 0
	for mode_id in (gm.call("special_mode_ids") as Array):
		var mode: BaseGameMode = controller.set_mode_by_name(str(mode_id), "medium")
		var ok := mode != null and mode.mode_id == str(mode_id) and not mode.mode_name.is_empty()
		_check(ok, "set_mode_by_name('%s') -> %s" % [mode_id, mode.mode_name if mode != null else "null"])
		count += 1
	_check(count == 7, "Ca 7 id Special deu map duoc sang mode class")
	_check(controller.set_mode_by_name("play", "medium").mode_id == "play", "map 'play' -> StandardGameMode")
	_check(controller.set_mode_by_name("dungeon", "medium").mode_id == "dungeon", "map 'dungeon' -> DungeonGameMode")
	controller.free()


# ---------------------------------------------------------------------------
# 3. Debug scene
# ---------------------------------------------------------------------------
func _section_3_debug_scene(gm: Node) -> void:
	print("\n--- 3. DEBUG SCENE: MUC SPECIAL MODES ---")
	var scene: Node = (load("res://scenes/debug.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame

	var rows: Node = scene.get_node_or_null("Panel/Content/Scroll/Rows")
	_check(rows != null, "Debug scene co vung Rows")
	if rows == null:
		return

	var texts := _collect_texts(rows)
	_check(_contains(texts, "SPECIAL MODES"), "Co muc 'SPECIAL MODES (TEST)'")
	_check(_contains(texts, "Test mode"), "Co toggle 'Test mode (khong ghi tien trinh)'")
	_check(_contains(texts, "Do kho") or _contains(texts, "Độ khó"), "Co chon do kho")
	_check(_contains(texts, "ng") and _contains(texts, "Tầng") or _contains(texts, "Tang"),
		"Co chon tang bat dau")

	var missing: Array[String] = []
	for mode_id in (gm.call("special_mode_ids") as Array):
		if not _contains(texts, str(mode_id)):
			missing.append(str(mode_id))
	_check(missing.is_empty(), "Moi che do Special co 1 hang lenh (thieu: %s)" % str(missing))
	_check(_contains(texts, "Chế độ ngẫu nhiên"), "Co hang 'Che do ngau nhien'")

	# Lựa chọn trong console phải được lưu lại
	scene.call("_set_difficulty", "easy")
	scene.call("_set_test_floor", 2)
	_check(str(scene.get("_difficulty")) == "easy" and int(scene.get("_floor")) == 2,
		"Do kho + tang chon trong Debug duoc giu lai")

	# Toggle test mode phải ghi vào GameManager
	scene.call("_set_test_mode", false)
	_check(not bool(gm.get("debug_run")), "Toggle 'Test mode' TAT -> GameManager.debug_run = false")
	scene.call("_set_test_mode", true)
	_check(bool(gm.get("debug_run")), "Toggle 'Test mode' BAT -> GameManager.debug_run = true")

	scene.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# 4. Ván test không ghi tiến trình
# ---------------------------------------------------------------------------
func _section_4_no_progress(gm: Node, dm: Node, today: int, mask_before: int, arch: Node) -> void:
	print("\n--- 4. VAN TEST KHONG GHI TIEN TRINH ---")
	gm.call("prepare_mode_run", "time_attack", "medium", true, 1)
	var game_scene: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game_scene)
	await process_frame
	await process_frame

	var controller: GameController = game_scene.get("game_controller")
	_check(controller != null, "Game scene nap duoc GameController")
	if controller != null:
		_check(bool(controller.call("_is_debug_run")), "Controller nhan biet day la van TEST")
		_check(controller.game_state.mode_id == "time_attack",
			"Van dang choi che do time_attack (dang %s)" % controller.game_state.mode_id)

		# Ván TEST: kể cả khi đang là ván DAILY thì cũng KHÔNG chốt nhiệm vụ ngày
		var mask_before_call := int(dm.call("get_day_mission_mask", today))
		var saved_variant := str(gm.get("daily_variant"))
		var saved_day := int(gm.get("selected_daily_day"))
		gm.set("daily_variant", "special")
		gm.set("selected_daily_day", today)
		controller.call("_complete_daily_missions", [])
		gm.set("daily_variant", saved_variant)
		gm.set("selected_daily_day", saved_day)
		_check(int(dm.call("get_day_mission_mask", today)) == mask_before_call,
			"Van TEST: ngay Daily KHONG bi chot nhiem vu (mask %d)" % mask_before_call)

		if arch != null:
			var seconds_before := int(arch.call("stat_value", "play_seconds"))
			controller.call("_report_to_archivements", true, 12.0)
			_check(int(arch.call("stat_value", "play_seconds")) == seconds_before,
				"Van TEST: khong ghi so lieu vao So tay thanh tuu")
			_check(str(gm.get("current_mode")) == "time_attack", "Mode trong GameManager khong bi doi")

	game_scene.queue_free()
	await process_frame
	_check(mask_before >= 0, "Trang thai Daily truoc test: mask %d (da sao luu)" % mask_before)


# ---------------------------------------------------------------------------
# 5. Ép tầng bắt đầu
# ---------------------------------------------------------------------------
func _section_5_floor_override(gm: Node) -> void:
	print("\n--- 5. EP TANG BAT DAU (minesweeper) ---")
	var sizes := {}
	for floor_number in [1, 3]:
		gm.call("prepare_mode_run", MINESWEEPER, "medium", true, floor_number)
		var game_scene: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
		root.add_child(game_scene)
		await process_frame
		await process_frame

		var controller: GameController = game_scene.get("game_controller")
		var grid: Node = game_scene.get("grid_controller")
		if controller != null and grid != null:
			var maze: MazeData = grid.get("maze")
			_check(controller.game_state.floor_number == floor_number,
				"Van bat dau o tang %d (dang %d)" % [floor_number, controller.game_state.floor_number])
			_check(controller.game_mode.mode_id == MINESWEEPER,
				"Che do dang choi = minesweeper")
			if maze != null:
				sizes[floor_number] = maze.width
				_check(maze.width == maze.height, "Ban vuong (%dx%d)" % [maze.width, maze.height])
		game_scene.queue_free()
		await process_frame

	_check(int(sizes.get(1, 0)) == 3 and int(sizes.get(3, 0)) == 5,
		"Tang 1 -> ban 3x3, tang 3 -> ban 5x5 (dang %s)" % str(sizes))


# ---------------------------------------------------------------------------
# Tiện ích
# ---------------------------------------------------------------------------
func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failed += 1
	print("[%s] %s" % ["CHECK" if condition else "FAIL", label])


func _collect_texts(node: Node) -> Array[String]:
	var out: Array[String] = []
	for child in node.get_children():
		if child is Label:
			out.append((child as Label).text)
		out.append_array(_collect_texts(child))
	return out


func _contains(texts: Array[String], needle: String) -> bool:
	for text in texts:
		if text.contains(needle):
			return true
	return false
