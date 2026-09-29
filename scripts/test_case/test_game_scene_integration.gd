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
	var test_modes := ["play", "minesweeper", "sum_path", "countdown_cost", "blind_memory", "fog_of_war", "fading_ink", "one_stroke", "wall_builder", "dungeon"]
	for mode_name in test_modes:
		game_scene.switch_mode(mode_name)
		await process_frame
		assert(game_scene.game_controller.game_mode.mode_id == mode_name or (mode_name == "play" and game_scene.game_controller.game_mode.mode_id == "play"), "Phai chuyen sang mode %s thanh cong" % mode_name)
		print("  -> Switched mode successfully: %s" % mode_name)

	# Test Undo and Hint buttons
	game_scene._on_hint_pressed()
	game_scene._on_undo_pressed()

	# Vẽ đường rồi ĐỔI CỠ (kéo cửa sổ) — đường đã vẽ phải đi theo lưới mới (bug 2026-09-30)
	await _check_drawn_path_follows_resize(game_scene)

	print("\n[SUCCESS] Integration test GameScene chay hoan hao khong loi!")
	quit(0)


## Bug 2026-09-30 ("vẽ đường xong, kéo cửa sổ → đường hiển thị sai vị trí"): nét mực đã vẽ lưu
## TOẠ ĐỘ PIXEL, còn lưới ô thì tính lại theo khung mới ⇒ nếu không vẽ lại, đường nằm lệch
## khỏi các ô. Kiểm tra: đổi cỡ bàn cờ → VỆT MỰC CŨ + NÉT ĐANG ĐI đều phải bám tâm ô MỚI.
func _check_drawn_path_follows_resize(scene: GameScene) -> void:
	print("\n[CHECK] Duong da ve di theo luoi khi doi co cua so...")
	var board: BoardView = scene.board_view
	var a: Vector2i = board.maze.get_start()
	var b := a + Vector2i(1, 0)
	if not board.maze.is_cell_active(b):
		b = a + Vector2i(0, 1)
	board.show_history_edge(a, b)
	var path: Array[Vector2i] = [a, b]
	board.set_moving_path(path)
	await process_frame

	var history: Line2D = (board.get("_history_lines") as Dictionary).values()[0]
	var moving: Line2D = board.get("_moving_line") as Line2D
	var center_before: Vector2 = board.call("_cell_center", a)

	board.size = board.size * 0.7      # thu nhỏ bàn cờ = kéo cửa sổ nhỏ lại
	await process_frame
	await process_frame

	var center_a: Vector2 = board.call("_cell_center", a)
	var center_b: Vector2 = board.call("_cell_center", b)
	assert(center_before.distance_to(center_a) > 1.0,
		"Doi co phai lam luoi xe dich (neu khong thi check vo nghia)")
	assert(history.points[0].distance_to(center_a) < 0.5, "Vet muc cu phai bam tam o moi (dau 1)")
	assert(history.points[1].distance_to(center_b) < 0.5, "Vet muc cu phai bam tam o moi (dau 2)")
	assert(moving.points[0].distance_to(center_a) < 0.5, "Net dang di phai bam tam o moi (dau 1)")
	assert(moving.points[1].distance_to(center_b) < 0.5, "Net dang di phai bam tam o moi (dau 2)")
	print("  -> Vet muc cu + net dang di deu bam dung tam o moi.")
