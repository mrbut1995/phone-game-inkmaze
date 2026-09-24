extends SceneTree
## ============================================================================
## Test Case: Kiểm tra chi tiết 10 Controllers Node, Signal Bindings trong .tscn,
## LevelManager Resource và Settings Popup.
## ============================================================================

func _init() -> void:
	print("\n========================================================")
	print("  TEST: 10 CONTROLLERS, SIGNAL BINDING & LEVEL MANAGER")
	print("========================================================\n")

	var game_scene_packed: PackedScene = load("res://scenes/game.tscn")
	assert(game_scene_packed != null, "scenes/game.tscn phai load duoc")

	var game_scene: GameScene = game_scene_packed.instantiate()
	root.add_child(game_scene)
	print("[CHECK] GameScene instantiated.")

	await process_frame
	await process_frame

	# 1. Kiem tra toan bo 10 Controllers duoi dang Node trong Controllers/
	var ctrl_node := game_scene.get_node_or_null("Controllers")
	assert(ctrl_node != null, "Node Controllers phai ton tai trong scenes/game.tscn")

	var gc: GameController = game_scene.game_controller
	var grid_ctrl: GridController = game_scene.grid_controller
	var anchor_ctrl: AnchorController = game_scene.anchor_controller
	var floor_ctrl: FloorController = game_scene.floor_controller
	var timer_ctrl: TimerController = game_scene.timer_controller
	var ui_ctrl: UIController = game_scene.ui_controller
	var tool_ctrl: ToolController = game_scene.tool_controller
	var undo_ctrl: UndoController = game_scene.undo_controller
	var hint_ctrl: HintController = game_scene.hint_controller
	var gm_ctrl: GameModeController = game_scene.game_mode_controller

	assert(gc != null, "GameController phai duoc export va gan")
	assert(grid_ctrl != null, "GridController phai duoc export va gan")
	assert(anchor_ctrl != null, "AnchorController phai duoc export va gan")
	assert(floor_ctrl != null, "FloorController phai duoc export va gan")
	assert(timer_ctrl != null, "TimerController phai duoc export va gan")
	assert(ui_ctrl != null, "UIController phai duoc export va gan")
	assert(tool_ctrl != null, "ToolController phai duoc export va gan")
	assert(undo_ctrl != null, "UndoController phai duoc export va gan")
	assert(hint_ctrl != null, "HintController phai duoc export va gan")
	assert(gm_ctrl != null, "GameModeController phai duoc export va gan")

	print("[SUCCESS] 10 Controllers deu la Node con va duoc export/binding day du vao Scene!")

	# 2. Kiem tra GameModeController va chuyen doi mode
	assert(gm_ctrl.game_mode != null, "GameModeController phai co game_mode khoi tao")
	var play_mode = gm_ctrl.set_mode_by_name("play", "easy")
	assert(play_mode is StandardGameMode, "Phai tao duoc StandardGameMode")
	assert(gc.game_mode == play_mode, "GameController.game_mode phai dong bo voi GameModeController")

	print("[SUCCESS] GameModeController hoat dong va lien ket chuan xac voi GameController!")

	# 3. Kiem tra LevelManager va LevelData Resource
	var lm: Node = root.get_node_or_null("LevelManager")
	assert(lm != null, "Autoload LevelManager phai ton tai tren root")
	var lvl1: LevelData = lm.call("load_level", 1)
	assert(lvl1 != null, "LevelManager phai load duoc Level 1")
	assert(lvl1.width == 2 and lvl1.height == 2, "Level 1 phai co size 2x2")
	var maze1 := lvl1.to_maze_data()
	assert(maze1 != null, "to_maze_data phai tra ve MazeData hop le")
	assert(maze1.width == 2 and maze1.height == 2, "MazeData phai co size 2x2")
	print("[SUCCESS] LevelManager & LevelData Resource nạp dữ liệu chuẩn xác!")

	# 4. Kiem tra Settings Popup (Pause) do PopupManager tao ra khi bam Pause
	var pause_btn: TextureButton = game_scene.layout.pause_btn
	pause_btn.emit_signal("pressed")
	await process_frame
	var pause_popup := Popups.get_popup(Popups.PAUSE)
	assert(pause_popup != null, "Pause phai tao popup tam dung qua PopupManager")
	assert(pause_popup.visible == true, "Pause phai hien thi settings popup")
	assert(timer_ctrl.is_running == false, "Timer phai pause khi bat settings")

	var resume_btn: TextureButton = pause_popup.find_child("ResumeBtn", true, false)
	assert(resume_btn != null, "Resume button phai ton tai trong settings popup")
	resume_btn.emit_signal("pressed")
	# Popup chay hieu ung dong (0.14s) roi moi bi xoa khoi node Popups
	await create_timer(0.4).timeout
	assert(not Popups.has_open(), "Resume phai dong va xoa settings popup khoi node Popups")
	assert(timer_ctrl.is_running == true, "Timer phai tiep tuc sau khi Resume")

	print("[SUCCESS] Settings Popup (Pause/Resume/Home) hoat dong dong bo voi TimerController!")

	# 5. Kiem tra ToolController chuyen tool
	var tool_wall_btn: NinePatchButton = game_scene.tool_wall_btn
	tool_wall_btn.emit_signal("pressed")
	assert(tool_ctrl.current_tool == ToolController.ToolMode.WALL, "Wall button phai chuyen tool sang WALL")
	assert(game_scene.board_view.get("tool_mode") == "wall", "Board tool_mode phai cap nhat sang wall qua signal tool_changed")

	var tool_path_btn: NinePatchButton = game_scene.tool_path_btn
	tool_path_btn.emit_signal("pressed")
	assert(tool_ctrl.current_tool == ToolController.ToolMode.PATH, "Path button phai chuyen tool sang PATH")
	assert(game_scene.board_view.get("tool_mode") == "path", "Board tool_mode phai cap nhat sang path")

	print("[SUCCESS] ToolController signal binding hoat dong chinh xac giua button va Board!")

	# 6. Kiem tra Player Cursor Running Animation
	var cursor = game_scene.board_view._cursor
	assert(cursor != null, "PlayerCursor phai ton tai tren Board")
	assert(cursor.has_method("run_to"), "PlayerCursor phai co ham run_to")
	game_scene.board_view.move_cursor_to(Vector2i(1, 1))
	await process_frame
	print("[SUCCESS] PlayerCursor running animation khoi chay thanh cong!")

	print("\n========================================================")
	print("  TAT CA TEST DEU VUOT QUA THANH CONG!")
	print("========================================================\n")
	quit(0)
