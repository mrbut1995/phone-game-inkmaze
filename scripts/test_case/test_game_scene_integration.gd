extends SceneTree
## ============================================================================
## Integration Test: Kiểm tra toàn diện GameScene và vòng đời tương tác UI/Board.
## ============================================================================

func _init() -> void:
	print("\n========================================================")
	print("  INTEGRATION TEST: GAME SCENE & BOARD RUNTIME FLOW")
	print("========================================================\n")

	var game_scene_packed: PackedScene = load("res://scenes/game.tscn")
	assert(game_scene_packed != null, "scenes/game.tscn phai load duoc")

	var game_scene: GameScene = game_scene_packed.instantiate()
	root.add_child(game_scene)
	print("[CHECK] GameScene instantiated and added to root.")

	# Cho frame chay de _ready() cua GameScene duoc kich hoat
	await process_frame
	await process_frame

	assert(game_scene.board_view != null, "BoardView phai ton tai")
	assert(game_scene.game_controller != null, "GameController phai ton tai")
	assert(game_scene.grid_controller != null, "GridController phai ton tai")
	assert(game_scene.ui_controller != null, "UIController phai ton tai")

	print("[CHECK] GameController run active: %s" % game_scene.game_controller._run_active)
	assert(game_scene.game_controller._run_active, "Game phai bat dau o trang thai run active")
	assert(game_scene.board_view._cell_nodes.size() > 0, "BoardView phai tao ra cac Cell nodes")
	assert(game_scene.board_view._anchor_nodes.size() > 0, "BoardView phai tao ra cac Anchor nodes")

	var initial_steps: int = game_scene.game_controller.game_state.steps_remaining
	print("[CHECK] Initial steps remaining: %d" % initial_steps)
	assert(initial_steps > 0, "Initial steps phai > 0")

	# Test Switch Modes qua GameScene API
	var test_modes := ["play", "time_attack", "minesweeper", "sum_path", "countdown_cost", "blind_memory", "fog_of_war", "fading_ink", "dungeon"]
	for mode_name in test_modes:
		game_scene.switch_mode(mode_name)
		await process_frame
		assert(game_scene.game_controller.game_mode.mode_id == mode_name or (mode_name == "play" and game_scene.game_controller.game_mode.mode_id == "play"), "Phai chuyen sang mode %s thanh cong" % mode_name)
		print("  -> Switched mode successfully: %s" % mode_name)

	# Test Undo and Hint buttons
	game_scene._on_hint_pressed()
	game_scene._on_undo_pressed()

	print("\n[SUCCESS] Integration test GameScene chay hoan hao khong loi!")
	quit(0)
