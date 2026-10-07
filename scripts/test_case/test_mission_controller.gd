extends SceneTree
## ============================================================================
## Test Case: Hệ thống 3 Nhiệm vụ & Sao (MissionController) + popup thua.
##   - Mỗi màn có đúng 3 nhiệm vụ; hoàn thành 1 = 1 Sao (không tính theo thời gian còn lại).
##   - Hệ HUD tách theo chế độ: scripts/nodes/hud/*.gd + nodes/hud/*.tscn
##     (Play = LevelHUD thẻ Nhiệm vụ, Dungeon = DungeonHUD bước/tầng, Minesweeper/Sum Path riêng).
##   - Popup thua: Level -> gameover_level.tscn (nhiệm vụ + số Sao), Dungeon -> gameover.tscn (bước).
##   - Hồi sinh: Level = quay lại bước trước đó, Endless = GIỮ NGUYÊN mê cung + cộng thêm bước.
## ============================================================================

var _failures := 0

const DIRS := [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]


func _init() -> void:
	print("\n========================================================")
	print("  TEST: 3 THU THACH & SAO + POPUP THUA THEO CHE DO")
	print("========================================================\n")

	# Autoload chỉ tồn tại sau frame đầu tiên khi chạy bằng --script
	await process_frame
	var gm: Node = root.get_node_or_null("GameManager")
	if gm == null:
		_fail("Khong tim thay autoload GameManager")
		quit(0)
		return
	gm.set("current_mode", "play")
	gm.set("current_level", 3)
	gm.set("unlocked_levels", 30)

	var packed: PackedScene = load("res://scenes/game.tscn")
	assert(packed != null, "scenes/game.tscn phai load duoc")
	var scene: GameScene = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var gc: GameController = scene.game_controller
	var cc: MissionController = gc.mission_controller
	assert(cc != null, "GameController phai duoc gan MissionController tu scene")
	_check_play_hud(scene, gc, cc)

	# 2. Chuyển sang Dungeon -> HUD đổi sang SỐ BƯỚC + TẦNG, ẩn thẻ nhiệm vụ
	scene.switch_mode("dungeon")
	await process_frame
	_check_dungeon_hud(scene, cc)
	await _check_dungeon_hazard(scene)

	# 3. Hồi sinh: Dungeon = cộng thêm bước · Level = quay lại bước trước đó
	scene.switch_mode("play")
	await process_frame
	await _check_revive_level(scene, gc)

	# 4. Logic tính Sao (không phụ thuộc thời gian còn lại)
	_check_star_math(gc, cc)

	# 5. HUD của 2 chế độ đặc biệt + hành vi mìn (Minesweeper) + Hồi sinh Endless
	scene.switch_mode("minesweeper")
	await process_frame
	_check_minesweep_hud(scene)
	await _check_minesweeper_hazards(scene, gc)

	scene.switch_mode("sum_path")
	await process_frame
	_check_sum_path_hud(scene)

	scene.switch_mode("dungeon")
	await process_frame
	await _check_revive_endless(scene, gc)

	if _failures == 0:
		print("[SUCCESS] He thong 3 thu thach & sao hoat dong dung o moi co che!")
	else:
		print("[FAILED] %d loi ve thu thach / sao." % _failures)
	quit(0)


# ---------------------------------------------------------------------------
# HUD
# ---------------------------------------------------------------------------
func _check_play_hud(scene: GameScene, _gc: GameController, cc: MissionController) -> void:
	var hud := scene.ui_controller.hud as LevelHUD
	assert(hud != null, "Play Mode phai dung LevelHUD (nodes/hud/level_mode.tscn)")
	# 2026-09-27 — HUD Play CHỈ hiện THỜI GIAN: thẻ Nhiệm vụ đã gỡ khỏi HUD (kết quả 3 nhiệm vụ +
	# Sao hiện ở POPUP kết thúc ván) nên `mission_card()` phải trả null và controller không giữ thẻ.
	if hud.mission_card() != null:
		_fail("HUD Play da go the THU THACH (chi con THOI GIAN)")
	if cc.card != null:
		_fail("MissionController khong duoc tro vao the thu thach o HUD nua")
	var time_val := hud.get_node_or_null("Content/ModeInformation/Time/Value") as Label
	if time_val == null or time_val.text.is_empty():
		_fail("HUD Play thieu gia tri THOI GIAN")
	if hud.get_node_or_null("Content/ModeInformation/Mission") != null:
		_fail("HUD Play con node Mission (phai go khoi scene)")
	print("[CHECK] Play Mode HUD: CHI THOI GIAN (%s) — the thu thach o popup ket qua"
		% (time_val.text if time_val != null else "-"))


## Dungeon Mode (endless) vẫn phải đưa nhân vật về điểm S khi đâm tường — khác Level Mode
func _check_dungeon_hazard(scene: GameScene) -> void:
	var grid: GridController = scene.grid_controller
	var maze: MazeData = grid.maze
	var start_pos: Vector2i = grid.current_pos
	var wall_cell := Vector2i(-1, -1)
	for dir in DIRS:
		var t: Vector2i = start_pos + dir
		if maze.is_in_bounds(t) and maze.is_cell_active(t) and maze.has_wall(start_pos, t):
			wall_cell = t
			break
	if wall_cell == Vector2i(-1, -1):
		print("[CHECK] Dungeon: diem S khong co tuong canh ben, bo qua kiem tra hazard")
		return
	grid.try_move_to(wall_cell)
	await process_frame
	if grid.current_pos != start_pos:
		_fail("Dungeon Mode dam tuong phai dua nhan vat ve diem S, dang o %s" % str(grid.current_pos))
	print("[CHECK] Dungeon: dam tuong van dua nhan vat ve diem S (khong doi hanh vi)")


func _check_dungeon_hud(scene: GameScene, cc: MissionController) -> void:
	var hud := scene.ui_controller.hud as DungeonHUD
	assert(hud != null, "Dungeon Mode phai dung DungeonHUD (nodes/hud/dungeon_mode.tscn)")
	# 2026-09-27: Dungeon CHỈ hiện SỐ BƯỚC + TẦNG (đồng hồ đã gỡ/ẩn)
	var step_card := hud.get_node_or_null("Content/ModeInformation/Step")
	var floor_card := hud.get_node_or_null("Content/ModeInformation/Floor")
	var step_val := hud.get_node_or_null("Content/ModeInformation/Step/Value") as Label
	var floor_val := hud.get_node_or_null("Content/ModeInformation/Floor/Value") as Label
	if step_card == null or not step_card.visible:
		_fail("Dungeon Mode phai hien the SO BUOC")
	if floor_card == null or not floor_card.visible:
		_fail("Dungeon Mode phai hien the TANG")
	var time_card := hud.get_node_or_null("Content/ModeInformation/Time") as Control
	if time_card != null and time_card.visible:
		_fail("Dungeon HUD khong hien THOI GIAN nua (chi SO BUOC + TANG)")
	if hud.mission_card() != null:
		_fail("Dungeon HUD khong duoc co the THU THACH")
	if cc.card != null:
		_fail("MissionController khong duoc tro vao the thu thach o Dungeon Mode")
	if step_val == null or step_val.text.is_empty():
		_fail("Dungeon HUD thieu gia tri SO BUOC CON LAI")
	if floor_val == null or floor_val.text.length() < 2:
		_fail("Dungeon HUD thieu gia tri TANG dang '%02d'")
	print("[CHECK] Dungeon Mode HUD: SO BUOC (%s) + TANG (%s), khong dong ho" % [
		step_val.text if step_val != null else "-", floor_val.text if floor_val != null else "-"])


## Minesweeper: HUD CHỈ hiện THỜI GIAN (thẻ BOMB đã gỡ 2026-09-27)
func _check_minesweep_hud(scene: GameScene) -> void:
	var hud := scene.ui_controller.hud as MinesweepHUD
	assert(hud != null, "Minesweeper phai dung MinesweepHUD (nodes/hud/minesweep_hud.tscn)")
	var time_val := hud.get_node_or_null("Content/ModeInformation/Time/Value") as Label
	if time_val == null or time_val.text.is_empty():
		_fail("HUD Minesweeper thieu gia tri THOI GIAN")
	if hud.get_node_or_null("Content/ModeInformation/Bomb") != null:
		_fail("HUD Minesweeper da go the BOMB (chi con THOI GIAN)")
	if hud.mission_card() != null:
		_fail("HUD Minesweeper khong duoc co the THU THACH")
	print("[CHECK] Minesweeper HUD: CHI THOI GIAN (%s)" % (time_val.text if time_val != null else "-"))


## Sum Path: HUD CHỈ hiện TỔNG hiện tại · TOÁN TỬ (<, >, =) nằm GIỮA · MỤC TIÊU (con số)
func _check_sum_path_hud(scene: GameScene) -> void:
	var hud := scene.ui_controller.hud as SumPathHUD
	assert(hud != null, "Sum Path phai dung SumPathHUD (nodes/hud/sum_path_hud.tscn)")
	# Bố cục DỌC bọc 3 khối trong `HBoxContainer`, bản NGANG để trực tiếp trong `Sheet`
	# ⇒ tra theo TÊN (find_child) để test đúng cho cả 2 hướng.
	var sum_card := hud.find_child("BlockCurrent", true, false) as Control
	var op_card := hud.find_child("Emblem", true, false) as Control
	var target_card := hud.find_child("BlockTarget", true, false) as Control
	var sum_val := hud.sum_value_node
	var op_val := hud.operator_value_label
	var target_val := hud.target_value_node
	if sum_val == null or sum_val.text.is_empty():
		_fail("HUD Sum Path thieu gia tri TONG hien tai")
	if target_val == null or target_val.text.strip_edges().is_empty():
		_fail("HUD Sum Path thieu gia tri MUC TIEU")
	if op_card == null or op_val == null:
		_fail("HUD Sum Path thieu panel TOAN TU (giua TONG va MUC TIEU)")
	# 2026-09-27: thẻ chỉ còn 3 khối này — dòng tiêu đề + thanh tiến độ đã gỡ khỏi scene
	if hud.find_child("Bar", true, false) != null:
		_fail("HUD Sum Path da go thanh tien do (Bar)")
	if hud.find_child("Title", true, false) != null:
		_fail("HUD Sum Path da go dong tieu de the (Title)")
	# Panel TOÁN TỬ phải nằm giữa panel TỔNG và panel MỤC TIÊU
	if sum_card != null and op_card != null and target_card != null:
		var sum_cx := sum_card.position.x + sum_card.size.x * 0.5
		var op_cx := op_card.position.x + op_card.size.x * 0.5
		var target_cx := target_card.position.x + target_card.size.x * 0.5
		if not (sum_cx < op_cx and op_cx < target_cx):
			_fail("Panel TOAN TU phai nam GIUA TONG va MUC TIEU (%.0f / %.0f / %.0f)" % [sum_cx, op_cx, target_cx])
		if op_card.size.x < 40.0 or op_card.size.x > 200.0:
			_fail("Panel TOAN TU phai la the nho (dang rong %.0fpx)" % op_card.size.x)
	var mode := scene.game_mode_controller.game_mode as SumPathGameMode
	if mode != null:
		if op_val != null and op_val.text != mode.operator:
			_fail("Panel TOAN TU phai hien '%s', dang la '%s'" % [mode.operator, op_val.text])
		if target_val != null and target_val.text != str(mode.target_val):
			_fail("Gia tri MUC TIEU phai la '%d', dang la '%s'" % [mode.target_val, target_val.text])
		if target_val != null and target_val.text.contains(mode.operator):
			_fail("MUC TIEU chi hien con so, toan tu da co panel rieng")
	print("[CHECK] Sum Path HUD: TONG %s %s MUC TIEU %s (panel toan tu o giua)" % [
		sum_val.text if sum_val != null else "-",
		op_val.text if op_val != null else "-",
		target_val.text if target_val != null else "-"])


## Minesweeper: đạp mìn = THUA NGAY — đứng nguyên tại chỗ, không ghi đè số, số Bomb giảm
func _check_minesweeper_hazards(scene: GameScene, gc: GameController) -> void:
	var mode := scene.game_mode_controller.game_mode as MinesweeperPathGameMode
	var grid: GridController = scene.grid_controller
	if mode == null or grid == null or grid.maze == null:
		_fail("Khong lay duoc MinesweeperPathGameMode / GridController")
		return
	var maze: MazeData = grid.maze
	var start_pos: Vector2i = grid.current_pos
	var mine_pos := Vector2i(-1, -1)
	for dir in DIRS:
		var t: Vector2i = start_pos + dir
		if maze.is_in_bounds(t) and maze.is_cell_active(t) and mode.is_mine(t):
			mine_pos = t
			break
	if mine_pos == Vector2i(-1, -1):
		print("[CHECK] Minesweeper: diem S khong co min canh ben, bo qua kiem tra no min")
		return

	var mines_before := mode.get_mines_left()
	grid.try_move_to(mine_pos)
	await process_frame
	if grid.current_pos != start_pos:
		_fail("Minesweeper: dap min KHONG duoc doi vi tri nhan vat (%s -> %s)" % [str(start_pos), str(grid.current_pos)])
	if mode.get_mines_left() != mines_before - 1:
		_fail("So min con lai phai giam dung 1 (%d -> %d)" % [mines_before, mode.get_mines_left()])
	if not mode.has_bomb_marker(mine_pos):
		_fail("O da no min phai duoc danh dau Bomb")
	if mode.get_cell_text(mine_pos, maze) == "X":
		_fail("O da no min KHONG duoc ghi de bang chu X")

	# Đạp mìn phải KẾT THÚC ván chơi (thua ngay) + mở popup thua
	await process_frame
	if gc._run_active:
		_fail("Minesweeper: dap min phai KET THUC van choi (game over ngay)")
	if not Popups.has_open():
		_fail("Minesweeper: dap min phai mo popup thua")
	print("[CHECK] Minesweeper: dap min = THUA NGAY (dung nguyen tai cho, con %d/%d min, popup thua da mo)" % [
		mode.get_mines_left(), mode.get_total_mines()])


## Endless (Dungeon) hồi sinh: GIỮ NGUYÊN mê cung + vị trí + đường đã đi, chỉ cộng thêm bước
func _check_revive_endless(scene: GameScene, gc: GameController) -> void:
	var grid: GridController = scene.grid_controller
	var maze_before: MazeData = grid.maze
	var pos_before: Vector2i = grid.current_pos
	var steps_before: int = gc.game_state.steps_remaining
	gc.revive_run()
	await process_frame
	if grid.maze != maze_before:
		_fail("Hoi sinh Endless KHONG duoc tao lai me cung")
	if grid.current_pos != pos_before:
		_fail("Hoi sinh Endless phai giu nguyen vi tri nhan vat, dang %s" % str(grid.current_pos))
	if gc.game_state.steps_remaining <= steps_before:
		_fail("Hoi sinh Endless phai cong them buoc (%d -> %d)" % [steps_before, gc.game_state.steps_remaining])
	print("[CHECK] Endless hoi sinh: giu nguyen me cung + vi tri %s, cong buoc %d -> %d" % [
		str(pos_before), steps_before, gc.game_state.steps_remaining])


# ---------------------------------------------------------------------------
# Logic
# ---------------------------------------------------------------------------
func _check_star_math(gc: GameController, cc: MissionController) -> void:
	cc.setup_for_floor(15)
	if cc.step_limit != 15:
		_fail("Nguong so buoc phai la 15, dang la %d" % cc.step_limit)
	if absf(cc.time_limit - 45.0) > 0.01:
		_fail("Nguong thoi gian phai la 45s (15 buoc x 3), dang la %.1f" % cc.time_limit)

	var rows := cc.rows()
	if rows.size() != MissionTypes.MAX_PER_LEVEL:
		_fail("Man khong khai bao thu thach phai dung 3 thu thach mac dinh, dang co %d" % rows.size())
	var steps_title := str(rows[1].get("title", ""))
	var time_title := str(rows[2].get("title", ""))
	if not steps_title.contains("15"):
		_fail("Ten thu thach so buoc phai neu nguong 15, dang la '%s'" % steps_title)
	if not time_title.contains("45"):
		_fail("Ten thu thach thoi gian phai neu nguong 45, dang la '%s'" % time_title)

	# Khi đang chơi: chỉ nhiệm vụ 1 có thể "đạt" ngay, 2 nhiệm vụ kia còn chờ
	var state := GameState.new()
	state.begin_run(15, "play", 1)
	cc.refresh(_ctx(gc, state, [], 0.0, false))
	if cc.stars() != 1:
		_fail("Dang choi: chi thu thach 'khong dam tuong' duoc tinh, dang co %d sao" % cc.stars())

	# Kết thúc màn hoàn hảo: 0 va chạm, 10 bước, 30s -> 3 Sao
	cc.refresh(_ctx(gc, state, [], 30.0, true))
	if cc.stars() != 3:
		_fail("Man hoan hao (0 dam tuong, 10/15 buoc, 30/45s) phai duoc 3 Sao, dang co %d" % cc.stars())

	# Có đâm tường -> mất sao 1, vẫn kịp bước + thời gian -> 2 Sao
	var hurt := GameState.new()
	hurt.begin_run(15, "play", 1)
	hurt.record_wall_hit()
	hurt.consume_step(1)
	cc.refresh(_ctx(gc, hurt, [], 30.0, true))
	if cc.stars() != 2:
		_fail("Dam tuong 1 lan (van kip buoc + thoi gian) phai duoc 2 Sao, dang co %d" % cc.stars())

	# Đi quá bước + quá giờ -> 0 Sao (không còn dựa vào thời gian còn lại)
	var slow := GameState.new()
	slow.begin_run(15, "play", 1)
	slow.record_wall_hit()
	for i in 20:
		slow.consume_step(1)
	cc.refresh(_ctx(gc, slow, [], 300.0, true))
	if cc.stars() != 0:
		_fail("Vuot nguong buoc + thoi gian (con dam tuong) phai la 0 Sao, dang co %d" % cc.stars())


## Tạo MissionContext từ scene đang chơi (để chấm nhiệm vụ trong test)
func _ctx(gc: GameController, state: GameState, path: Array[Vector2i], elapsed: float, is_final: bool) -> MissionContext:
	var ctx := MissionContext.new()
	ctx.set_values(
		state,
		gc.game_mode,
		gc.grid_controller.maze if gc.grid_controller != null else null,
		path,
		elapsed,
		is_final
	)
	return ctx

	print("[CHECK] Tinh Sao: dang choi=1 · hoan hao=3 · dam tuong=2 · cham&lau=0; nguong 15 buoc/45s")


## Tìm đường đi NGẮN NHẤT (BFS, không qua ô ĐÍCH) từ `from_pos` tới 1 ô có tường để đâm.
## Trả về `{"path": Array[Vector2i], "blocked": Vector2i}` hoặc `{}` nếu không có.
func _find_wall_hit_target(maze: MazeData, from_pos: Vector2i) -> Dictionary:
	var end_pos: Vector2i = maze.get_end()
	var prev := {from_pos: from_pos}
	var queue: Array[Vector2i] = [from_pos]
	var visited: Array[Vector2i] = []
	while not queue.is_empty():
		var cur: Vector2i = queue.pop_front()
		visited.append(cur)
		for dir in DIRS:
			var nxt: Vector2i = cur + dir
			if nxt == end_pos or not maze.is_in_bounds(nxt) or not maze.is_cell_active(nxt):
				continue
			if maze.has_wall(cur, nxt) or prev.has(nxt):
				continue
			prev[nxt] = cur
			queue.append(nxt)
	for cell in visited:
		if cell == from_pos or cell == end_pos:
			continue
		for dir in DIRS:
			var blocked: Vector2i = cell + dir
			if not maze.is_in_bounds(blocked) or not maze.is_cell_active(blocked):
				continue
			if not maze.has_wall(cell, blocked):
				continue
			var path: Array[Vector2i] = []
			var node: Vector2i = cell
			while node != from_pos:
				path.push_front(node)
				node = prev[node]
			return {"path": path, "blocked": blocked}
	return {}


func _check_revive_level(scene: GameScene, gc: GameController) -> void:
	var grid: GridController = scene.grid_controller
	var board: Node = scene.board_view
	var maze: MazeData = grid.maze
	var start_pos: Vector2i = grid.current_pos

	# Tìm đường đi NGẮN NHẤT từ điểm S tới 1 ô có tường để đâm (mê cung nhỏ có thể phải đi vài bước
	# mới tới được tường; KHÔNG đi qua ô ĐÍCH kẻo thắng màn).
	var target := _find_wall_hit_target(maze, start_pos)
	if target.is_empty():
		_fail("Khong tim duoc duong toi tuong de test hoi sinh")
		return
	var path: Array[Vector2i] = target["path"]
	var wall_cell: Vector2i = target["blocked"]
	var step_cell: Vector2i = path[path.size() - 1]
	var back_cell: Vector2i = path[path.size() - 2] if path.size() >= 2 else start_pos

	# Đi hết đường (mỗi bước 1 ô) — số bước phải ĐẾM ĐỦ
	for cell in path:
		grid.try_move_to(cell)
		await process_frame
	if grid.current_pos != step_cell:
		_fail("Phai di toi duoc o %s truoc khi dam tuong, dang o %s" % [str(step_cell), str(grid.current_pos)])
	if gc.game_state.floor_moves != path.size():
		_fail("Sau %d buoc, floor_moves phai = %d, dang la %d"
			% [path.size(), path.size(), gc.game_state.floor_moves])

	# Đâm tường = thua ngay (Play Mode) -> popup thua bản LEVEL (3 nhiệm vụ + số Sao)
	grid.try_move_to(wall_cell)
	await process_frame
	await process_frame
	if not Popups.is_open(Popups.GAME_OVER_LEVEL):
		_fail("Play Mode thua phai mo popup game_over_level")
	if grid.current_pos != step_cell:
		_fail("Play Mode thua khong duoc keo nhan vat ve diem S; dang o %s" % str(grid.current_pos))

	var walls: Dictionary = board.get("_wall_segments")
	var wall_key := _lattice_key(step_cell, wall_cell)
	if not walls.has(wall_key) or not (walls[wall_key] as Line2D).visible:
		_fail("Doan tuong vua dam phai duoc hien ngay sau khi dam")

	var popup := Popups.get_popup(Popups.GAME_OVER_LEVEL)
	if popup != null:
		var stamp := popup.find_child("StampCount", true, false) as Label
		# Số nhiệm vụ hiển thị ở panel "MissionHead/Value" của popup (không phải node tên MissionCount)
		var header_node := popup.find_child("MissionHead", true, false) as Control
		var header: Label = null
		if header_node != null:
			header = header_node.get_node_or_null("Value") as Label
		if stamp == null or header == null:
			_fail("Popup level thieu con dau / so thu thach")
		elif stamp.text != header.text:
			_fail("So thu thach tren con dau ('%s') phai khop tieu de bang ('%s')" % [stamp.text, header.text])
		elif not stamp.text.contains("/"):
			_fail("So thu thach tren con dau phai dang 'x / 3', dang la '%s'" % stamp.text)

	# --- Người chơi bấm HỒI SINH trên popup (đúng luồng thật, qua AdsManager) ---
	if popup != null:
		popup.call("_on_revive_pressed")
	await process_frame
	await create_timer(0.35).timeout

	if grid.current_pos != back_cell:
		_fail("Hoi sinh Level phai quay ve o truoc do (%s), dang o %s" % [str(back_cell), str(grid.current_pos)])
	if gc.game_state.floor_moves != path.size() - 1:
		_fail("Hoi sinh Level khong cong buoc: floor_moves phai ve %d, dang la %d"
			% [path.size() - 1, gc.game_state.floor_moves])
	if Popups.has_open():
		_fail("Sau hoi sinh phai dong popup thua")
	if not scene.timer_controller.is_running:
		_fail("Sau hoi sinh dong ho phai chay lai")
	if not bool(board.get("_interaction_enabled")):
		_fail("Sau hoi sinh ban co phai nhan lai input (truoc day bi dung yen)")
	if not bool(gc.get("_run_active")):
		_fail("Sau hoi sinh van choi phai tiep tuc chay")

	# Tường vừa đâm vẫn hiển thị sau khi hồi sinh
	if not walls.has(wall_key) or not (walls[wall_key] as Line2D).visible:
		_fail("Sau hoi sinh, doan tuong vua dam phai van hien")

	# Và phải đi tiếp được
	var moved_again := false
	for dir in DIRS:
		var t: Vector2i = grid.current_pos + dir
		if maze.is_in_bounds(t) and maze.is_cell_active(t) and not maze.has_wall(grid.current_pos, t):
			grid.try_move_to(t)
			moved_again = grid.current_pos == t
			break
	if not moved_again:
		_fail("Sau hoi sinh nguoi choi phai di chuyen duoc tiep")
	print("[CHECK] Hoi sinh Level: quay ve o truoc do, tuong vua dam hien, di chuyen lai duoc")


## Khoá tường theo đúng định dạng của board.gd ("h,x,y" / "v,x,y")
func _lattice_key(a: Vector2i, b: Vector2i) -> String:
	var is_h := a.x == b.x
	var lattice := Vector2i(a.x, maxi(a.y, b.y)) if is_h else Vector2i(maxi(a.x, b.x), a.y)
	return ("h,%d,%d" if is_h else "v,%d,%d") % [lattice.x, lattice.y]


# ---------------------------------------------------------------------------
func _fail(message: String) -> void:
	_failures += 1
	print("[FAIL] %s" % message)
