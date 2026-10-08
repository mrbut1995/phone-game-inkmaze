extends SceneTree
## ============================================================================
## Test Case: ONE STROKE — MỘT NÉT PHỦ KÍN (2026-09-19)
##
## 1. Bàn không có số, tường HIỆN RÕ 100%, mở ván chỉ có ô S là đã đi.
## 2. F bị CHẶN khi vẫn còn ô trống (không thua, không mất bước).
## 3. Đi lại Ô ĐÃ ĐI = hazard "revisit" -> THUA NGAY, popup hiện "ĐI LẠI Ô CŨ!".
## 4. Bám theo nút GỢI Ý (hint_next_cell) là đi hết được bàn -> THẮNG khi phủ kín + chạm F.
## 5. Undo lùi bước -> ô vừa rời được MỞ LẠI (lớp "ĐÃ ĐI" tắt).
## 6. is_dead_end phát hiện ô trống bị CẮT RỜI (bẫy cắt ngang).
## 7. HUD OneStrokeHUD: số ô đã phủ, thanh tiến độ, chip %KÍN, nhãn phụ nút công cụ.
## 8. Sinh bàn 20 lần (5×5): luôn có đường Hamilton S->F tránh tường + tường hiện 100%.
## ============================================================================

var _failed := 0
var _checks := 0


func _init() -> void:
	print("\n========================================================")
	print("  TEST: ONE STROKE - MOT NET PHU KIN")
	print("========================================================\n")
	await process_frame
	root.size = Vector2i(1080, 1920)
	TranslationServer.set_locale("vi")

	var scene: GameScene = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	assert(scene != null, "Phai load duoc scenes/game.tscn")
	root.add_child(scene)
	await process_frame
	await process_frame

	await _check_design(scene.game_controller.game_mode)
	await _run(scene)

	scene.queue_free()
	await process_frame

	print("\n--------------------------------------------------------")
	if _failed == 0:
		print("  KET QUA: %d/%d CHECK PASS" % [_checks, _checks])
	else:
		print("  KET QUA: %d/%d CHECK FAIL" % [_failed, _checks])
	print("--------------------------------------------------------\n")
	quit(1 if _failed > 0 else 0)


# ---------------------------------------------------------------------------
# 8. Kiểm tra bộ sinh bàn (không cần scene)
# ---------------------------------------------------------------------------
func _check_design(_unused: BaseGameMode) -> void:
	var ok_path := true
	var ok_wall_vis := true
	var ok_size := true
	var ok_start := true
	for i in 20:
		var mode := OneStrokeGameMode.new("medium")
		var maze := mode.setup_floor(1)
		if mode.total_cells() != 25 or mode.visited_count() != 1:
			ok_size = false
		if not mode.is_cell_visited(maze.get_start()):
			ok_start = false
		if not _all_walls_visible(maze):
			ok_wall_vis = false
		if not _has_cover_path(maze):
			ok_path = false

	_entry(ok_size, "Ban 5x5: dung 25 o, mo van chi co o S da di")
	_entry(ok_start, "O xuat phat S duoc danh dau DA DI ngay tu dau")
	_entry(ok_wall_vis, "Moi vach ngan noi bo deu HIEN RO (khong co tuong an)")
	_entry(ok_path, "20 lan sinh ban: luon ton tai duong phu kin S -> F tranh tuong")


## Mọi cạnh là tường (trừ viền ngoài) phải đang ở trạng thái HIỆN
func _all_walls_visible(maze: MazeData) -> bool:
	for ix in maze.width:
		for iy in range(1, maze.height):
			if maze.has_h_wall(ix, iy) and not maze.is_h_wall_visible(ix, iy):
				return false
	for ix in range(1, maze.width):
		for iy in maze.height:
			if maze.has_v_wall(ix, iy) and not maze.is_v_wall_visible(ix, iy):
				return false
	return true


## DFS độc lập: có đường đi phủ kín mọi ô từ S tới F (đi qua ô chưa thăm) không?
func _has_cover_path(maze: MazeData) -> bool:
	var start := maze.get_start()
	var end := maze.get_end()
	var all_cells := maze.width * maze.height
	return _dfs_cover(maze, start, { start: true }, 1, all_cells, end)


func _dfs_cover(
	maze: MazeData, cur: Vector2i, seen: Dictionary, count: int, total: int, end: Vector2i
) -> bool:
	if count == total:
		return cur == end
	if cur == end:
		return false      # F chỉ được là ô cuối cùng
	for d: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]:
		var nxt: Vector2i = cur + d
		if not maze.is_in_bounds(nxt) or seen.has(nxt) or maze.has_wall(cur, nxt):
			continue
		seen[nxt] = true
		if _dfs_cover(maze, nxt, seen, count + 1, total, end):
			return true
		seen.erase(nxt)
	return false


# ---------------------------------------------------------------------------
# 1-7. Chạy thật trên scenes/game.tscn
# ---------------------------------------------------------------------------
func _run(scene: GameScene) -> void:
	var mode := await _new_run(scene, "easy")
	var grid := scene.grid_controller
	var gc := scene.game_controller
	_entry(mode != null, "Lay duoc OneStrokeGameMode")
	if mode == null or grid == null or gc == null or grid.maze == null:
		return

	var maze := grid.maze
	var hud := scene.ui_controller.hud as OneStrokeHUD
	_entry(hud != null, "Man choi dung HUD OneStrokeHUD rieng")

	# --- 1. Bàn không số + tường hiện rõ ---
	_entry(_board_has_no_numbers(scene, maze), "Ban khong hien so tren o (chi S/F)")
	_entry(maze.visible_wall_ratio == 1.0, "Ty le tuong hien = 1.0 (100%)")
	_entry(mode.visited_count() == 1 and mode.is_cell_visited(maze.get_start()),
		"Mo van: chi o S da di (%d o)" % mode.visited_count())

	# --- 2. F bị chặn khi còn ô trống ---
	var end_pos := maze.get_end()
	var near_end := _walkable_neighbour(maze, end_pos)
	if near_end != Vector2i(-1, -1):
		var eval := mode.evaluate_move(near_end, end_pos, maze)
		_entry(not bool(eval.get("allowed", true)) and str(eval.get("reason", "")) == "finish_locked",
			"Cham F khi con o trong -> bi CHAN (reason=%s)" % str(eval.get("reason", "")))
		_entry(not bool(eval.get("is_hazard", false)), "Cham F som KHONG phai hazard (khong thua)")
	else:
		_entry(false, "Tim duoc o ke F de thu chan")

	# --- 7. HUD (2026-09-27: One Stroke CHỈ hiện THỜI GIAN — bảng "TIẾN ĐỘ PHỦ KÍN" đã gỡ) ---
	if hud != null:
		hud.update_hud({"mode": mode})
		# Gia tri dong ho lay qua export cua HUD (`Time/HBoxContainer/Value`) — KHONG do duong dan
		# tuyet doi vi so tang trong the THOI GIAN co the doi ma khong bao.
		var time_card := hud.find_child("Time", true, false) as Control
		var time_val := hud.time_value_node
		_entry(time_card != null and time_card.visible, "HUD: co the THOI GIAN")
		_entry(time_val != null and not time_val.text.is_empty(),
			"HUD: the THOI GIAN hien gia tri ('%s')" % _text_of(time_val))
		_entry(hud.find_child("Sheet", true, false) == null,
			"HUD: da go bang TIEN DO PHU KIN (chi con THOI GIAN)")
	# Thanh hanh dong (2026-09-26): nut Tool/Wall cu da BO — chi con CHƠI LẠI · UNDO · HINT
	_entry(scene.submit_btn != null and not (scene.submit_btn as BaseButton).visible,
		"Che do khac Wall Builder thi nut GUI BAI AN")
	_entry(scene.restart_btn != null and (scene.restart_btn as BaseButton).visible,
		"Nut CHOI LAI nam trong thanh hanh dong")

	# --- 4. Đi theo GỢI Ý tới khi phủ kín ---
	var steps := 0
	while grid.current_pos != maze.get_end() and steps < 40:
		var next := mode.hint_next_cell(maze, grid.current_pos)
		if next == grid.current_pos or next == Vector2i(-1, -1):
			break
		grid.try_move_to(next)
		await process_frame
		steps += 1
	_entry(grid.current_pos == maze.get_end(), "Di theo GOI Y ve duoc F (sau %d buoc)" % steps)
	_entry(mode.visited_count() == mode.total_cells(),
		"Phu kin 100%% ban co (%d/%d o)" % [mode.visited_count(), mode.total_cells()])
	_entry(bool(gc.get("_floor_finished")), "Phu kin + cham F cuoi -> THANG man")
	_entry(not Popups.is_open(Popups.GAME_OVER_LEVEL), "Thang -> KHONG mo popup thua")

	# --- 3. Đi lại ô cũ = thua ngay ---
	mode = await _new_run(scene, "easy")
	grid = scene.grid_controller
	gc = scene.game_controller
	if mode == null or grid == null or grid.maze == null:
		return
	maze = grid.maze
	var start := maze.get_start()
	var first_dir := _walkable_neighbour_dir(maze, start)
	_entry(first_dir != Vector2i.ZERO, "O S co o ke de di buoc dau")
	if first_dir != Vector2i.ZERO:
		grid.try_move_to(start + first_dir)
		await process_frame
		var stepped := grid.current_pos
		_entry(mode.is_cell_visited(stepped), "O vua di duoc danh dau DA DI")
		grid.try_move_to(start)          # quay lai ô cũ S
		await process_frame
		await process_frame
		_entry(not bool(gc.get("_run_active")), "Di lai o cu -> van ket thuc ngay")
		_entry(not bool(gc.get("_floor_finished")), "Ket thuc do di lai o cu la THUA (khong phai thang)")
		_entry(Popups.is_open(Popups.GAME_OVER_LEVEL), "Mo popup THUA (GAME_OVER_LEVEL)")
		var popup := Popups.get_popup(Popups.GAME_OVER_LEVEL) as GameOverLevelPopup
		var title: Label = popup.label_title if popup != null else null
		_entry(title != null and title.text == "STR_GAME_OVER_REVISIT",
			"Popup thua hien tieu de 'DI LAI O CU!' ('%s')" % _text_of(title))

	# --- 5. Undo mở lại ô ---
	mode = await _new_run(scene, "easy")
	grid = scene.grid_controller
	if mode == null or grid == null or grid.maze == null:
		return
	maze = grid.maze
	start = maze.get_start()
	first_dir = _walkable_neighbour_dir(maze, start)
	if first_dir != Vector2i.ZERO:
		grid.try_move_to(start + first_dir)
		await process_frame
		var stepped_undo := grid.current_pos
		var board := grid.board_view
		var cell_before: MazeCell = board._cell_node(stepped_undo) if board != null else null
		_entry(cell_before != null and cell_before.visited_visible(), "O da di hien lop 'DA DI'")
		var undone := grid.undo_last_move()
		await process_frame
		_entry(undone and grid.current_pos == start, "Undo lui 1 buoc ve o truoc")
		_entry(not mode.is_cell_visited(stepped_undo), "Undo -> o vua roi duoc MO LAI")
		var cell_after: MazeCell = board._cell_node(stepped_undo) if board != null else null
		_entry(cell_after != null and not cell_after.visited_visible(), "Lop 'DA DI' tren o da tat")

	# --- 6. Bẫy cắt ngang -> hết đường ---
	var probe := OneStrokeGameMode.new("easy")
	var probe_maze := probe.setup_floor(1)
	_entry(not probe.is_dead_end(probe_maze.get_start(), probe_maze),
		"Dau van, duong con ho nguyen -> is_dead_end = false")
	var probe_visited: Dictionary = probe.get("_visited")
	# Tự đánh dấu một đường cắt dọc giữa bàn 3x3 (bàn bị chia làm 2 phần rời)
	for cut: Vector2i in [Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2)]:
		probe_visited[cut] = true
	_entry(probe.is_dead_end(Vector2i(1, 0), probe_maze),
		"Cat ngang ban co -> is_dead_end = true (HET DUONG DI!)")


func _new_run(scene: GameScene, difficulty: String) -> OneStrokeGameMode:
	scene.switch_mode("one_stroke", difficulty)
	await process_frame
	await process_frame
	return scene.game_mode_controller.game_mode as OneStrokeGameMode


func _board_has_no_numbers(scene: GameScene, maze: MazeData) -> bool:
	var board := scene.grid_controller.board_view
	if board == null:
		return false
	for y in maze.height:
		for x in maze.width:
			var pos := Vector2i(x, y)
			var cell: MazeCell = board._cell_node(pos)
			if cell == null:
				continue
			var text: String = cell.get_text()
			var expect_empty := pos != maze.get_start() and pos != maze.get_end()
			if expect_empty and not text.is_empty():
				return false
	return true


func _walkable_neighbour(maze: MazeData, pos: Vector2i) -> Vector2i:
	for d: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
		var to: Vector2i = pos + d
		if maze.is_in_bounds(to) and maze.is_cell_active(to) and not maze.has_wall(pos, to):
			return to
	return Vector2i(-1, -1)


func _walkable_neighbour_dir(maze: MazeData, pos: Vector2i) -> Vector2i:
	for d: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
		var to: Vector2i = pos + d
		if maze.is_in_bounds(to) and maze.is_cell_active(to) and not maze.has_wall(pos, to):
			return d
	return Vector2i.ZERO


func _text_of(node: Node) -> String:
	var label := node as Label
	return label.text if label != null else "(null)"


func _entry(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("  [PASS] %s" % label)
	else:
		_failed += 1
		print("  [FAIL] %s" % label)
