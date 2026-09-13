extends SceneTree
## ============================================================================
## Test Case: RETRY / CHƠI LẠI (bug 2026-09)
## - Bấm "Thử lại" ở popup Game Over phải chơi lại ĐÚNG màn hiện tại,
##   không được nhảy về màn 1-1.
## - Nút Restart trên HUD và nút "Chơi lại" ở popup thắng màn cũng vậy.
## - Dungeon (endless): chơi lại đúng tầng đang chơi, không về tầng 1.
## - Chơi lại phải reset bước/điểm theo thiết kế của màn (LevelData).
## ============================================================================

const TEST_LEVEL := 3

var _backup := ""


func _init() -> void:
	print("\n========================================================")
	print("  TEST: RETRY PHAI CHOI LAI DUNG MAN HIEN TAI")
	print("========================================================\n")

	await process_frame
	root.size = Vector2i(1080, 1920)

	# Backup dữ liệu thật để không phá tiến trình người chơi
	if FileAccess.file_exists("user://inkmaze_data.json"):
		var rf := FileAccess.open("user://inkmaze_data.json", FileAccess.READ)
		_backup = rf.get_as_text()

	var failures := 0

	var gm: Node = root.get_node_or_null("GameManager")
	assert(gm != null, "Autoload GameManager phai ton tai")
	gm.set("current_mode", "play")
	gm.set("current_level", TEST_LEVEL)
	gm.set("unlocked_levels", 9)

	var level_data: LevelData = (root.get_node("LevelManager") as Node).call("load_level", TEST_LEVEL)
	assert(level_data != null, "Level %d phai nap duoc" % TEST_LEVEL)

	var game_scene: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game_scene)
	await process_frame
	await process_frame

	var controller: GameController = game_scene.get("game_controller")
	var grid_controller: Node = game_scene.get("grid_controller")
	var ui_controller: Node = game_scene.get("ui_controller")

	# --- 1. Ván phải bắt đầu ở màn 3 ---
	failures += _expect_floor(controller, TEST_LEVEL, "Bat dau van")
	failures += _expect_level_data(controller, level_data, TEST_LEVEL, "Bat dau van")

	# --- 2. Thua màn -> popup Game Over -> bấm THỬ LẠI ---
	var blocked_neighbor := _find_blocked_neighbor(grid_controller)
	if blocked_neighbor != Vector2i(-1, -1):
		grid_controller.call("try_move_to", blocked_neighbor)   # đâm tường (Play mode: thua ngay)
		print("[CHECK] Da dam tuong o %s de thua man." % str(blocked_neighbor))
	else:
		# Màn này không có tường kề ô S -> gọi thẳng luồng thua màn
		controller.call("_game_over")
		print("[CHECK] Man khong co tuong ke S -> goi _game_over() truc tiep.")
	await process_frame
	await process_frame
	await create_timer(0.5).timeout

	var popup: Node = Popups.get_popup(Popups.GAME_OVER)
	if popup == null:
		print("[FAIL] Popup Game Over khong mo sau khi thua man")
		failures += 1
	else:
		print("[CHECK] Popup Game Over da mo o man %d" % controller.game_state.floor_number)
		popup.call("_on_retry_pressed")     # = nguoi choi bam nut THU LAI
		await process_frame
		await create_timer(0.5).timeout
		failures += _expect_floor(controller, TEST_LEVEL, "Sau khi bam THU LAI (popup Game Over)")
		failures += _expect_level_data(controller, level_data, TEST_LEVEL, "Sau khi bam THU LAI")

	# --- 3. Nút Restart trên HUD ---
	controller.call("restart_run")
	await process_frame
	failures += _expect_floor(controller, TEST_LEVEL, "Sau khi bam Restart tren HUD")

	# --- 4. Popup thắng màn: nút "Chơi lại" ---
	ui_controller.call("show_floor_complete", {
		"floor": TEST_LEVEL, "grid": "3x3", "time": 12.0, "steps_used": 4,
		"steps_max": level_data.max_steps, "wall_hits": 0, "score": 100,
		"stars": 3, "total_score": 100, "endless": false,
	})
	await process_frame
	await create_timer(0.5).timeout
	var win_popup: Node = Popups.get_popup(Popups.WIN)
	if win_popup == null:
		print("[FAIL] Popup thang man khong mo")
		failures += 1
	else:
		win_popup.call("_on_replay_pressed")
		await process_frame
		await create_timer(0.5).timeout
		failures += _expect_floor(controller, TEST_LEVEL, "Sau khi bam CHOI LAI (popup thang man)")

	# --- 5. Dungeon (endless): chơi lại đúng TẦNG đang chơi ---
	Popups.close_all()
	game_scene.call("switch_mode", "dungeon")
	await process_frame
	await process_frame
	controller.call("_on_continue_requested")   # thắng tang 1 -> tang 2
	await process_frame
	controller.call("_on_continue_requested")   # thang tang 2 -> tang 3
	await process_frame
	failures += _expect_floor(controller, 3, "Dungeon sau 2 tang")
	controller.call("_on_retry_requested")
	await process_frame
	failures += _expect_floor(controller, 3, "Sau khi choi lai o Dungeon")

	# --- Kết luận ---
	Popups.close_all()
	game_scene.queue_free()
	await process_frame

	if not _backup.is_empty():
		var wf := FileAccess.open("user://inkmaze_data.json", FileAccess.WRITE)
		wf.store_string(_backup)

	if failures > 0:
		print("\n[FAILED] %d loi ve nut choi lai.\n" % failures)
		quit(1)
		return

	print("\n[SUCCESS] Retry / Choi lai luon dung man - tang hien tai!\n")
	quit(0)


# --- Helper ---
func _expect_floor(controller: GameController, expected: int, label: String) -> int:
	var actual: int = controller.game_state.floor_number
	if actual != expected:
		print("[FAIL] %s: man/tang phai la %d (dang la %d)" % [label, expected, actual])
		return 1
	print("[CHECK] %s: dung man/tang %d." % [label, actual])
	return 0


func _expect_level_data(controller: GameController, level_data: LevelData, level_id: int,
		label: String) -> int:
	var failures := 0
	var maze: MazeData = controller.grid_controller.get("maze")
	if maze == null:
		print("[FAIL] %s: khong co MazeData" % label)
		return 1
	if maze.width != level_data.width or maze.height != level_data.height:
		print("[FAIL] %s: luoi %dx%d, mong doi %dx%d"
			% [label, maze.width, maze.height, level_data.width, level_data.height])
		failures += 1
	if controller.game_state.max_steps != level_data.max_steps:
		print("[FAIL] %s: max_steps %d, mong doi %d (theo LevelData man %d)"
			% [label, controller.game_state.max_steps, level_data.max_steps, level_id])
		failures += 1
	if controller.game_state.steps_remaining != level_data.max_steps:
		print("[FAIL] %s: buoc con lai %d, phai duoc reset ve %d"
			% [label, controller.game_state.steps_remaining, level_data.max_steps])
		failures += 1
	if controller.game_state.score != 0:
		print("[FAIL] %s: diem phai reset ve 0 (dang %d)" % [label, controller.game_state.score])
		failures += 1
	if failures == 0:
		print("[CHECK] %s: luoi %dx%d, %d buoc theo LevelData, diem = 0."
			% [label, maze.width, maze.height, controller.game_state.max_steps])
	return failures


## Tìm 1 ô kề cạnh S mà bị tường chặn (để test đâm tường)
func _find_blocked_neighbor(grid_controller: Node) -> Vector2i:
	var maze: MazeData = grid_controller.get("maze")
	if maze == null:
		return Vector2i(-1, -1)
	var from_pos: Vector2i = maze.get_start()
	for step: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT]:
		var nxt := from_pos + step
		if maze.is_in_bounds(nxt) and maze.has_wall(from_pos, nxt):
			return nxt
	return Vector2i(-1, -1)
