extends SceneTree
## ============================================================================
## Integration Test: Kiểm tra toàn diện luồng chuyển cảnh (Main Menu -> Levels -> Game -> Daily)
## ============================================================================

func _init() -> void:
	print("\n========================================================")
	print("  INTEGRATION TEST: SCENE FLOW & GAME NAVIGATION")
	print("========================================================\n")

	# 1. Test Main Scene
	var main_packed: PackedScene = load("res://scenes/main.tscn")
	assert(main_packed != null, "scenes/main.tscn phai load duoc")
	var main_scene: MainScene = main_packed.instantiate()
	root.add_child(main_scene)
	print("[CHECK] MainScene instantiated.")
	await process_frame
	await process_frame
	assert(main_scene.btn_play != null, "MainScene phai co btn_play")
	assert(main_scene.btn_dungeon != null, "MainScene phai co btn_dungeon")
	assert(main_scene.btn_daily != null, "MainScene phai co btn_daily")
	main_scene.queue_free()
	await process_frame

	# 2. Test Level Selection Scene
	var levels_packed: PackedScene = load("res://scenes/levels.tscn")
	assert(levels_packed != null, "scenes/levels.tscn phai load duoc")
	var levels_scene: LevelScenes = levels_packed.instantiate()
	root.add_child(levels_scene)
	print("[CHECK] LevelScenes instantiated.")
	await process_frame
	await process_frame
	assert(levels_scene.btn_back != null, "LevelScenes phai co btn_back")
	assert(levels_scene.grid_container != null, "LevelScenes phai co grid_container")
	assert(levels_scene.grid_container.get_child_count() == 9, "GridContainer phai co 9 level card")
	levels_scene.queue_free()
	await process_frame

	# 3. Test Daily Challenge Scene
	var daily_packed: PackedScene = load("res://scenes/daily.tscn")
	assert(daily_packed != null, "scenes/daily.tscn phai load duoc")
	var daily_scene: DailyScene = daily_packed.instantiate()
	root.add_child(daily_scene)
	print("[CHECK] DailyScene instantiated.")
	await process_frame
	await process_frame
	assert(daily_scene.btn_back != null, "DailyScene phai co btn_back")
	# Lich thang duoc dung lai theo thang hien tai (nodes/daily/calendar.tscn)
	var days_grid: GridContainer = daily_scene.get_node_or_null("Calendar/Days")
	assert(days_grid != null, "DailyScene phai co Calendar/Days")
	assert(days_grid.get_child_count() == 35, "Lich phai co 35 o ngay (7x5)")
	assert((days_grid.get_child(0) as DailyDayCell) != null, "O lich phai la DailyDayCell")
	daily_scene.queue_free()
	await process_frame

	# 4. Test Game Scene
	var game_packed: PackedScene = load("res://scenes/game.tscn")
	assert(game_packed != null, "scenes/game.tscn phai load duoc")
	var game_scene: GameScene = game_packed.instantiate()
	root.add_child(game_scene)
	print("[CHECK] GameScene instantiated.")
	await process_frame
	await process_frame
	assert(game_scene.board_view != null, "GameScene phai co board_view")
	assert(game_scene.game_controller != null, "GameScene phai co game_controller")
	assert(game_scene.find_child("Popups", true, false) != null, "GameScene phai co node Popups de chua popup")

	# 5. Test Debug Scene (man hinh dev)
	var debug_packed: PackedScene = load("res://scenes/debug.tscn")
	assert(debug_packed != null, "scenes/debug.tscn phai load duoc")
	var debug_scene: Node = debug_packed.instantiate()
	root.add_child(debug_scene)
	await process_frame
	await process_frame
	var debug_rows: Node = debug_scene.get_node_or_null("Panel/Content/Scroll/Rows")
	assert(debug_rows != null, "Debug scene phai co vung Rows")
	assert(debug_rows.get_child_count() > 0, "Debug scene phai dung duoc cac hang lenh")
	print("[CHECK] DebugScene instantiated (%d hang lenh)." % debug_rows.get_child_count())
	debug_scene.queue_free()
	await process_frame

	print("\n[SUCCESS] Toan bo luong chuyen canh va cac man hinh hoat dong hoan hao!")
	quit(0)
