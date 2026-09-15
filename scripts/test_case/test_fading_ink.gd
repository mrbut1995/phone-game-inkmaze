extends SceneTree
## ============================================================================
## Test: Fading Ink (Mực Phai) — mode thay cho Area Maze (đã bỏ 2026-11).
##   - Bàn KHÔNG có tường trong; số trên ô là MỰC của ô đó (không phải số tường).
##   - Chỉ đi vào ô CÒN MỰC; mỗi bước đi làm MỌI ô phai 1 điểm; ô về 0 mất số.
##   - Đường ngắn nhất luôn đủ mực để tới F (kiểm tra bằng cách đi đúng đường mẫu).
##   - Undo lùi bước -> mực hồi lại; hết lối đi -> is_dead_end -> popup thua "HẾT ĐƯỜNG ĐI".
## ============================================================================

var _failures := 0

const DIRS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]


func _init() -> void:
	print("\n========================================================")
	print("  TEST: FADING INK — CHI DI TREN O CON MUC + MUC PHAI DAN")
	print("========================================================\n")

	await process_frame
	var gm: Node = root.get_node_or_null("GameManager")
	if gm == null:
		_fail("Khong tim thay autoload GameManager")
		quit(0)
		return

	_check_floor_generation()
	_check_decay_and_rules()
	_check_shortest_path_reachable()
	_check_undo_restores_ink()
	_check_dead_end()
	await _check_scene_integration(gm)

	if _failures == 0:
		print("[SUCCESS] Fading Ink: luat muc phai hoat dong dung!")
	else:
		print("[FAILED] %d loi ve Fading Ink." % _failures)
	quit(0)


func _fail(msg: String) -> void:
	_failures += 1
	print("[FAIL] ", msg)


# ---------------------------------------------------------------------------
# 1. Sinh bàn: không tường trong, mọi ô (trừ S/F) đều có mực ban đầu
# ---------------------------------------------------------------------------
func _check_floor_generation() -> void:
	var mode := FadingInkGameMode.new("medium")
	var maze := mode.setup_floor(1)
	if maze == null:
		_fail("setup_floor tra ve null")
		return

	var with_ink := 0
	var cells := 0
	for y in maze.height:
		for x in maze.width:
			var pos := Vector2i(x, y)
			cells += 1
			if pos == maze.get_start() or pos == maze.get_end():
				continue
			if mode.ink_initial(pos) > 0:
				with_ink += 1
	if with_ink != cells - 2:
		_fail("Moi o (tru S/F) phai co muc ban dau (%d/%d)" % [with_ink, cells - 2])

	# Không có tường bên trong: mọi cạnh giữa 2 ô trong bàn đều mở
	var walls := 0
	for y in maze.height:
		for x in maze.width:
			var pos := Vector2i(x, y)
			if x + 1 < maze.width and maze.has_wall(pos, pos + Vector2i.RIGHT):
				walls += 1
			if y + 1 < maze.height and maze.has_wall(pos, pos + Vector2i.DOWN):
				walls += 1
	if walls != 0:
		_fail("Fading Ink khong co tuong trong ban (%d canh bi chan)" % walls)

	if mode.initial_steps <= mode.design_moves:
		_fail("Nguong thu thach phai rong hon duong ngan nhat (%d buoc / duong %d buoc)" % [
			mode.initial_steps, mode.design_moves])
	print("[CHECK] Sinh ban: %dx%d · %d o co muc · khong tuong trong · duong ngan nhat %d buoc" % [
		maze.width, maze.height, with_ink, mode.design_moves])


# ---------------------------------------------------------------------------
# 2. Luật đi + mực phai dần
# ---------------------------------------------------------------------------
func _check_decay_and_rules() -> void:
	var mode := FadingInkGameMode.new("easy")
	var maze := mode.setup_floor(1)
	var start := maze.get_start()

	var target := _first_walkable_neighbor(mode, maze, start)
	if target == Vector2i(-1, -1):
		_fail("Khong tim duoc o ke ben co muc de test")
		return
	var ink_before := mode.ink_left(target)
	var eval_before := mode.evaluate_move(start, target, maze)
	if not eval_before.get("allowed", false):
		_fail("O con muc phai di vao duoc")

	mode.on_player_moved(null, target, maze)      # đi 1 bước
	if mode.ink_left(target) != ink_before - 1:
		_fail("Sau 1 buoc, muc cua o phai giam 1 (%d -> %d)" % [ink_before, mode.ink_left(target)])

	# Mọi ô đều phai theo cùng nhịp
	var other := _first_walkable_neighbor(mode, maze, start + Vector2i(0, 0))
	if other != Vector2i(-1, -1) and mode.ink_initial(other) > 0:
		if mode.ink_left(other) != mode.ink_initial(other) - 1:
			_fail("MOI o phai cung phai 1 diem muc moi buoc")

	# Ô hết mực: mất số và không đi vào được
	mode.moves_made = mode.ink_initial(target) + 5
	if not mode.get_cell_text(target, maze).is_empty():
		_fail("O het muc phai mat so (tra ve chuoi rong)")
	if mode.is_walkable(target):
		_fail("O het muc khong duoc di vao")
	var eval_after := mode.evaluate_move(start, target, maze)
	if eval_after.get("allowed", true):
		_fail("Nuoc di vao o het muc phai bi chan (allowed = false)")
	if eval_after.get("is_hazard", false):
		_fail("O het muc chi bi CHAN, khong phai hazard (khong mat buoc)")
	# S và F luôn đi được dù mực có phai hết
	if not mode.is_walkable(maze.get_start()) or not mode.is_walkable(maze.get_end()):
		_fail("S/F luon phai di duoc")
	print("[CHECK] Luat: chi di tren o con muc · moi buoc phai 1 diem · o het muc mat so va bi chan")


func _first_walkable_neighbor(mode: FadingInkGameMode, maze: MazeData, pos: Vector2i) -> Vector2i:
	for d in DIRS:
		var nxt: Vector2i = pos + d
		if maze.is_in_bounds(nxt) and maze.is_cell_active(nxt) and mode.is_walkable(nxt):
			return nxt
	return Vector2i(-1, -1)


# ---------------------------------------------------------------------------
# 3. Đường ngắn nhất LUÔN đi được tới F (mực ban đầu được cấp đủ)
# ---------------------------------------------------------------------------
func _check_shortest_path_reachable() -> void:
	for difficulty in ["easy", "medium", "hard"]:
		for attempt in 5:
			var mode := FadingInkGameMode.new(difficulty)
			var maze := mode.setup_floor(1)
			var path := maze.get_shortest_path(maze.get_start(), maze.get_end())
			if path.size() < 2:
				_fail("Khong co duong ngan nhat (%s)" % difficulty)
				break
			var pos: Vector2i = path[0]
			var ok := true
			for i in range(1, path.size()):
				var nxt: Vector2i = path[i]
				var eval := mode.evaluate_move(pos, nxt, maze)
				if not eval.get("allowed", false):
					_fail("Duong ngan nhat bi chan o buoc %d (%s): o %s het muc" % [i, difficulty, str(nxt)])
					ok = false
					break
				pos = nxt
				mode.on_player_moved(null, pos, maze)
			if ok and not mode.check_completion(pos, maze, null):
				_fail("Di het duong ngan nhat phai toi duoc F (%s)" % difficulty)
				ok = false
			if not ok:
				break
	print("[CHECK] Duong ngan nhat luon du muc de toi F (easy/medium/hard x 5 lan sinh ban)")


# ---------------------------------------------------------------------------
# 4. Undo lùi bước -> mực hồi lại
# ---------------------------------------------------------------------------
func _check_undo_restores_ink() -> void:
	var mode := FadingInkGameMode.new("medium")
	var maze := mode.setup_floor(1)
	var pos := maze.get_start()
	var before: Array[int] = []
	for d in DIRS:
		var nxt: Vector2i = pos + d
		if maze.is_in_bounds(nxt) and mode.is_walkable(nxt):
			before.append(mode.ink_left(nxt))

	mode.on_player_moved(null, pos, maze)
	mode.on_move_undone(null, pos, pos, maze)
	var after: Array[int] = []
	for d in DIRS:
		var nxt: Vector2i = pos + d
		if maze.is_in_bounds(nxt) and mode.is_walkable(nxt):
			after.append(mode.ink_left(nxt))

	if before != after:
		_fail("Undo phai hoi lai muc da phai (%s -> %s)" % [str(before), str(after)])
	if mode.moves_made != 0:
		_fail("Undo phai giam so buoc da di (dang %d)" % mode.moves_made)
	print("[CHECK] Undo: lui buoc thi muc hoi lai dung nhu truoc")


# ---------------------------------------------------------------------------
# 5. Hết lối đi -> dead end
# ---------------------------------------------------------------------------
func _check_dead_end() -> void:
	var mode := FadingInkGameMode.new("medium")
	var maze := mode.setup_floor(1)
	if mode.is_dead_end(maze.get_end(), maze):
		_fail("Dung tai F khong duoc coi la het duong")
	if mode.is_dead_end(maze.get_start(), maze):
		_fail("Vua vao ban (con day muc) khong the het duong")

	mode.moves_made = 999          # mực phai sạch: mọi ô mất số
	if not mode.is_dead_end(maze.get_start(), maze):
		_fail("Muc phai het -> khong con o nao di duoc => phai la dead end")
	print("[CHECK] Het muc = het duong di (is_dead_end = true, tru khi dang o F)")


# ---------------------------------------------------------------------------
# 6. Tích hợp scene: mode chạy được + bàn cờ hiện đúng mực + nút Undo thật
# ---------------------------------------------------------------------------
func _check_scene_integration(gm: Node) -> void:
	gm.set("current_mode", "fading_ink")
	gm.set("current_level", 1)
	gm.set("unlocked_levels", 99)

	var packed: PackedScene = load("res://scenes/game.tscn")
	var scene: GameScene = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var mode := scene.game_mode_controller.game_mode as FadingInkGameMode
	var grid: GridController = scene.grid_controller
	var board: BoardView = scene.game_controller.grid_view
	if mode == null or board == null:
		_fail("Khong lay duoc FadingInkGameMode / Board trong scene")
		return

	# Bàn cờ phải hiện đúng mực của mode
	var target := _first_walkable_neighbor(mode, board.maze, grid.current_pos)
	if target != Vector2i(-1, -1):
		var cell := board.call("_cell_node", target) as MazeCell
		if cell != null and cell.get_text() != mode.get_cell_text(target, board.maze):
			_fail("So tren o phai khop muc cua mode ('%s' vs '%s')" % [
				cell.get_text(), mode.get_cell_text(target, board.maze)])

	# Ô hết mực thì không đi vào được
	mode.moves_made = 999
	board.call("refresh_cell_texts", true)
	var pos_before: Vector2i = grid.current_pos
	if target != Vector2i(-1, -1):
		grid.try_move_to(target)
		if grid.current_pos != pos_before:
			_fail("Khong duoc di vao o da het muc")
	var cell_dim := board.call("_cell_node", target) as MazeCell
	if cell_dim != null:
		if cell_dim.get_text() != "":
			_fail("O het muc phai khong con so tren ban co")
		if cell_dim.modulate.a > 0.9:
			_fail("O het muc phai MO di de nguoi choi thay khong di vao duoc (alpha %.2f)" % cell_dim.modulate.a)

	# Hết đường -> GameController._on_dead_end() mở popup thua
	scene.game_controller._on_dead_end()
	await process_frame
	if not Popups.has_open():
		_fail("Het duong phai mo popup thua")
	print("[CHECK] Scene: mode Fading Ink chay duoc · ban co hien muc · het duong mo popup thua")
