extends SceneTree
## ============================================================================
## Test Case: FOG OF WAR — 3 LƯỢT THỬ LẠI + HỒI SINH (2026-09-18)
##
## 1. Mở ván: đủ 3 lượt thử; đâm tường KHÔNG thua ngay.
## 2. Đâm tường -> nhân vật về ô S + TRỪ 1 lượt (sương mở lại quanh S), ván vẫn chạy.
## 3. Đâm đủ 3 lần -> thua: popup thua mở + board khoá tương tác + dòng HỒI SINH nói "+1 LƯỢT THỬ".
## 4. Hồi sinh -> cộng thêm 1 lượt + chơi tiếp; đâm thêm 1 lần nữa lại thua.
## 5. HUD Sương Mù là HUD riêng của chế độ và hiện đúng số lượt còn lại.
## ============================================================================

var _failed := 0
var _checks := 0


func _init() -> void:
	print("\n========================================================")
	print("  TEST: FOG OF WAR - LUOT THU LAI")
	print("========================================================\n")
	await process_frame
	root.size = Vector2i(1080, 1920)
	TranslationServer.set_locale("vi")

	var scene: GameScene = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	assert(scene != null, "Phai load duoc scenes/game.tscn")
	root.add_child(scene)
	await process_frame
	await process_frame

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


func _run(scene: GameScene) -> void:
	# Mê cung sinh ngẫu nhiên: chơi lại tới khi ô S có ít nhất 1 cạnh là tường ẩn
	var mode := await _new_run_with_wall(scene)
	var grid := scene.grid_controller
	var gc := scene.game_controller
	_entry(mode != null, "Lay duoc FogOfWarGameMode")
	if mode == null or grid == null or gc == null:
		return

	_entry(mode.max_retries == 3 and mode.retries_left == 3,
		"Mo van: dung 3 luot thu (%d/%d)" % [mode.retries_left, mode.max_retries])
	_entry(not mode.instant_game_over_on_hazard, "Dam tuong KHONG thua ngay (con luot thu)")
	_entry(mode.respawn_on_hazard, "Dam tuong -> dua nhan vat ve o S")

	var hud := scene.ui_controller.hud as FogOfWarHUD
	_entry(hud != null, "Man choi dung HUD FogOfWarHUD rieng")
	if hud != null:
		hud.update_hud({"mode": mode})
		var value := hud.get_node_or_null("Sheet/Retry/Value") as Label
		_entry(value != null and value.text == "3", "HUD hien 3 luot thu ('%s')"
			% (value.text if value != null else ""))
	# Thanh hanh dong (2026-09-26): 2 nut Tool/Wall cu da BO — nut CHƠI LẠI nam trong thanh nay
	_entry(scene.restart_btn != null and not (scene.restart_btn as BaseButton).disabled,
		"Nut CHOI LAI trong thanh hanh dong (khong bi khoa)")

	var start := grid.maze.get_start()
	var wall_dir := _wall_neighbour(grid.maze, start)

	# --- Lần đâm 1: về S + mất 1 lượt, ván vẫn chạy ---
	grid.try_move_to(start + wall_dir)
	await process_frame
	_entry(mode.retries_left == 2, "Dam tuong lan 1 -> con 2 luot (%d)" % mode.retries_left)
	_entry(grid.current_pos == start, "Nhan vat bi dua ve o S")
	_entry(Vector2i(mode.get("_player_pos")) == start, "Suong mo mo lai quanh o S (khong dung o cu)")
	_entry(gc.get("_run_active") == true and gc.get("_floor_finished") == false, "Van van dang chay")
	_entry(not Popups.is_open(Popups.GAME_OVER_LEVEL), "Chua het luot -> KHONG mo popup thua")
	_entry(not gc.get("_floor_finished"), "Chua tinh la xong man")

	# --- Lần đâm 2 ---
	grid.try_move_to(start + wall_dir)
	await process_frame
	_entry(mode.retries_left == 1, "Dam tuong lan 2 -> con 1 luot (%d)" % mode.retries_left)
	_entry(gc.get("_run_active") == true, "Con 1 luot -> van choi tiep")
	if hud != null:
		hud.update_hud({"mode": mode})
		var note := hud.get_node_or_null("Sheet/Retry/Note") as Label
		_entry(note != null and note.get_theme_color("font_color") == FogOfWarHUD.COLOR_NOTE_DANGER,
			"Con 1 luot -> dong nhac tren HUD chuyen DO")

	# --- Lần đâm 3: HẾT LƯỢT -> thua ---
	grid.try_move_to(start + wall_dir)
	await process_frame
	await process_frame
	_entry(mode.retries_left == 0, "Dam tuong lan 3 -> het luot (%d)" % mode.retries_left)
	_entry(gc.get("_run_active") == false, "Het luot -> van ket thuc (run không còn chạy)")
	_entry(not bool(gc.get("_floor_finished")), "Ket thuc la THUA (khong tinh la thang man)")
	_entry(Popups.is_open(Popups.GAME_OVER_LEVEL), "Mo popup THUA (GAME_OVER_LEVEL)")
	var popup := Popups.get_popup(Popups.GAME_OVER_LEVEL)
	var desc := popup.get_node_or_null("Panel/Content/Banner/Desc") as Label if popup != null else null
	_entry(desc != null and desc.text == tr("STR_REVIVE_DESC_RETRY"),
		"Dong HỒI SINH noi '+1 LUOT THU' ('%s')" % (desc.text if desc != null else ""))

	# --- Hồi sinh: +1 lượt và chơi tiếp được ---
	gc.revive_run()
	await process_frame
	await process_frame
	_entry(mode.retries_left == 1, "Hoi sinh -> cong them 1 luot (%d)" % mode.retries_left)
	_entry(gc.get("_run_active") == true, "Hoi sinh -> choi tiep duoc")
	_entry(await _wait_popup_closed(Popups.GAME_OVER_LEVEL), "Hoi sinh -> dong popup thua")
	_entry(Vector2i(mode.get("_player_pos")) == grid.current_pos,
		"Suong mo o dung vi tri sau khi hoi sinh")

	# --- Đâm thêm 1 lần nữa: lại hết lượt -> thua ---
	var pos_now := grid.current_pos
	var again := _wall_neighbour(grid.maze, pos_now)
	if again != Vector2i.ZERO:
		grid.try_move_to(pos_now + again)
		await process_frame
		await process_frame
		_entry(mode.retries_left == 0, "Dam them 1 lan -> het luot (%d)" % mode.retries_left)
		_entry(Popups.is_open(Popups.GAME_OVER_LEVEL), "Lai mo popup thua")
	else:
		_entry(true, "(bo qua: o hien tai khong co tuong de dam)")


## Mở ván Fog of War mới cho tới khi ô S có tường ẩn kề bên (mê cung sinh ngẫu nhiên)
func _new_run_with_wall(scene: GameScene) -> FogOfWarGameMode:
	for attempt in 30:
		scene.switch_mode("fog_of_war", "normal")
		await process_frame
		await process_frame
		var mode := scene.game_mode_controller.game_mode as FogOfWarGameMode
		var grid := scene.grid_controller
		if mode == null or grid == null or grid.maze == null:
			continue
		var dir := _wall_neighbour(grid.maze, grid.maze.get_start())
		if dir != Vector2i.ZERO:
			return mode
	_entry(false, "Tim duoc me cung co tuong ke o S (sau 30 lan sinh)")
	return null


## Hướng của một cạnh là TƯỜNG ẨN quanh ô (Vector2i.ZERO nếu không có)
func _wall_neighbour(maze: MazeData, pos: Vector2i) -> Vector2i:
	for dir in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
		var to: Vector2i = pos + dir
		if maze.is_in_bounds(to) and maze.is_cell_active(to) and maze.has_wall(pos, to):
			return dir
	return Vector2i.ZERO


## Chờ popup đóng hằn (popup đóng bằng hiệu ứng nên cần vài frame)
func _wait_popup_closed(id: String) -> bool:
	for i in 60:
		await process_frame
		if not Popups.is_open(id):
			return true
	return false


func _entry(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("  [PASS] %s" % label)
	else:
		_failed += 1
		print("  [FAIL] %s" % label)
