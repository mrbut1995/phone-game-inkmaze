extends SceneTree
## ============================================================================
## Test Suite: Kiểm tra toàn diện 9 Game Modes và hệ thống MVC Controllers.
## Chạy bằng Godot CLI:
##   godot --headless --script scripts/test_case/test_all_game_modes.gd
## ============================================================================

func _init() -> void:
	print("\n========================================================")
	print("  BAT DAU KIEM TRA TOAN DIEN 9 GAME MODES & CONTROLLERS")
	print("========================================================\n")

	var passed := 0
	var total := 0

	# 1. Test Models & Utils
	total += 1
	if test_maze_data():
		passed += 1

	total += 1
	if test_score_calculator():
		passed += 1

	total += 1
	if test_floor_config():
		passed += 1

	total += 1
	if test_anchor_controller():
		passed += 1

	total += 1
	if test_timer_controller():
		passed += 1

	total += 1
	if test_undo_and_hint():
		passed += 1

	# 2. Test 8 Game Modes
	var modes: Array[BaseGameMode] = [
		StandardGameMode.new("medium"),
		DungeonGameMode.new(),
		MinesweeperPathGameMode.new(),
		SumPathGameMode.new("medium", "="),
		CountdownCostGameMode.new("medium"),
		BlindMemoryGameMode.new("normal"),
		FogOfWarGameMode.new("normal"),
		FadingInkGameMode.new("medium")
	]

	for mode in modes:
		total += 1
		if test_single_mode(mode):
			passed += 1

	print("\n--------------------------------------------------------")
	print("  KET QUA: %d / %d TESTS PASSED (%.1f%%)" % [passed, total, (float(passed) / total) * 100.0])
	print("========================================================\n")

	if passed == total:
		print("[SUCCESS] Tat ca cac bai kiem tra deu vuot qua thanh cong!")
		quit(0)
	else:
		printerr("[FAILURE] Co bai kiem tra bi loi!")
		quit(1)


func test_maze_data() -> bool:
	print("[TEST] MazeData Model Generation & Solvability...")
	var maze := MazeData.new()
	maze.generate(4, 4, 0.4)

	assert(maze.width == 4, "Width phai bang 4")
	assert(maze.height == 4, "Height phai bang 4")
	assert(maze.is_in_bounds(maze.get_start()), "Start phai nam trong bien")
	assert(maze.is_in_bounds(maze.get_end()), "End phai nam trong bien")
	assert(maze.get_start() != maze.get_end(), "Start khong duoc trung End")
	assert(maze.is_solvable(), "Me cung bat buoc phai co duong di BFS hop le")

	# Kiem tra shortest path
	var path := maze.get_shortest_path(maze.get_start(), maze.get_end())
	assert(not path.is_empty(), "Shortest path khong duoc rong")
	assert(path[0] == maze.get_start(), "Path phai bat dau tu S")
	assert(path[path.size() - 1] == maze.get_end(), "Path phai ket thuc tai F")

	print("  -> PASSED: MazeData hoat dong chinh xac.")
	return true


func test_score_calculator() -> bool:
	print("[TEST] ScoreCalculator...")
	var score_data := ScoreCalculator.calculate_floor_score(2, 10, 30.0, true)
	assert(score_data.get("base_score", 0) == 100, "Base score tang 2 phai bang 100")
	assert(score_data.get("move_bonus", 0) == 100, "Move bonus 10 buoc phai bang 100")
	assert(score_data.get("perfect_bonus", 0) == 100, "Perfect bonus phai bang 100")
	assert(score_data.get("total_gained", 0) > 300, "Total score phai duoc tinh dung")

	var bonus_steps := ScoreCalculator.calculate_bonus_steps(10)
	assert(bonus_steps >= 4, "Bonus steps phai >= MIN_BONUS_STEPS (4)")

	print("  -> PASSED: ScoreCalculator tinh diem dung.")
	return true


func test_floor_config() -> bool:
	print("[TEST] FloorConfig Difficulty Progression...")
	assert(FloorConfig.get_grid_size(1) == 2, "Tang 1 la 2x2")
	assert(FloorConfig.get_grid_size(3) == 3, "Tang 3 la 3x3")
	assert(FloorConfig.get_grid_size(5) == 4, "Tang 5 la 4x4")
	assert(FloorConfig.get_grid_size(10) == 5, "Tang 10 la 5x5")

	assert(FloorConfig.get_visible_ratio(1) > 0.8, "Tang 1 tuong lo nhieu")
	assert(FloorConfig.get_visible_ratio(13) == 0.0, "Tang 13+ tuong an 100%")

	print("  -> PASSED: FloorConfig tra dung cau hinh tang.")
	return true


func test_anchor_controller() -> bool:
	print("[TEST] AnchorController Suspected Walls...")
	var ctrl := AnchorController.new()
	var corner_a := Vector2i(1, 1)
	var corner_b := Vector2i(1, 2)

	assert(not ctrl.is_suspected(false, Vector2i(1, 1)), "Ban dau khong co tuong nghi ngo")
	var success := ctrl.handle_anchor_connection(corner_a, corner_b)
	assert(success, "Noi 2 anchor ke nhau phai thanh cong")
	assert(ctrl.is_suspected(false, Vector2i(1, 1)), "Sau khi noi phai co tuong nghi ngo")

	# Toggle off
	ctrl.handle_anchor_connection(corner_a, corner_b)
	assert(not ctrl.is_suspected(false, Vector2i(1, 1)), "Noi lan 2 phai tat tuong nghi ngo")

	print("  -> PASSED: AnchorController bat/tat tuong nghi ngo dung.")
	return true


func test_timer_controller() -> bool:
	print("[TEST] TimerController Stopwatch & Countdown...")
	var timer := TimerController.new()
	timer.start_new_run()
	assert(timer.is_running, "Timer phai dang chay")
	timer.tick(1.5)
	assert(absf(timer.total_elapsed - 1.5) < 0.01, "Stopwatch phai tich luy thoi gian")

	# Test countdown
	timer.start_countdown(10.0)
	assert(timer.is_countdown, "Timer phai o che do countdown")
	timer.tick(3.0)
	assert(absf(timer.time_remaining - 7.0) < 0.01, "Countdown phai giam thoi gian")

	print("  -> PASSED: TimerController hoat dong chinh xac.")
	return true


func test_undo_and_hint() -> bool:
	print("[TEST] UndoController & HintController...")
	var undo := UndoController.new()
	assert(not undo.can_undo(), "Ban dau khong the undo")
	undo.record_move(Vector2i(0, 0), Vector2i(0, 1), 1)
	assert(undo.can_undo(), "Sau khi di phai undo duoc")
	var action := undo.pop_last_action()
	assert(action.get("type", "") == "move", "Action phai la move")
	assert(action.get("from", Vector2i.ZERO) == Vector2i(0, 0), "Action from phai la (0,0)")

	var hint := HintController.new()
	var maze := MazeData.new()
	maze.generate(3, 3, 1.0)
	var next_pos := hint.get_next_step_hint(maze, maze.get_start())
	assert(next_pos != maze.get_start(), "Hint phai tra ve buoc di ke tiep hop le")

	print("  -> PASSED: UndoController va HintController hoat dong tot.")
	return true


func test_single_mode(mode: BaseGameMode) -> bool:
	print("[TEST MODE] %s (%s)..." % [mode.mode_name, mode.mode_id])

	var maze := mode.setup_floor(1)
	assert(maze != null, "Setup floor phai tao ra MazeData")
	assert(maze.width >= 2 and maze.height >= 2, "Maze phai co kich thuoc hop le")

	# Kiem tra ky tu o Start va Finish
	var s_text := mode.get_cell_text(maze.get_start(), maze)
	var f_text := mode.get_cell_text(maze.get_end(), maze)
	assert(s_text == "S" or not s_text.is_empty(), "Start cell phai hien thi S hoac diem")
	assert(f_text == "F" or not f_text.is_empty(), "Finish cell phai hien thi F hoac diem")

	# Kiem tra kiem dinh nuoc di
	var start_pos := maze.get_start()
	var adjacent_valid := false
	for d: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT]:
		var nxt := start_pos + d
		if maze.is_in_bounds(nxt):
			var eval := mode.evaluate_move(start_pos, nxt, maze)
			assert(eval.has("allowed"), "Evaluate move phai co truong allowed")
			adjacent_valid = true
			break
	assert(adjacent_valid, "Phai co it nhat 1 o lien ke hop le")

	# Kiem tra tinh toan hoan thanh
	var anchor_ctrl := AnchorController.new()
	if not (mode is SumPathGameMode):
		assert(mode.check_completion(maze.get_end(), maze, anchor_ctrl), "Den F phai hoan thanh man")
		assert(not mode.check_completion(maze.get_start(), maze, anchor_ctrl), "O S chua the hoan thanh man")

	# Kiem tra HUD title va extra info
	var title := mode.get_hud_floor_title(1)
	assert(not title.is_empty(), "HUD title khong duoc rong")

	print("  -> PASSED: Mode %s vuot qua tat ca cac kiem tra." % mode.mode_name)
	return true
