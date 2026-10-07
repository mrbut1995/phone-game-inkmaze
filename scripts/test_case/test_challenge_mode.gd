extends SceneTree
## ============================================================================
## Test Case: CHALLENGE MODE (2026-10) — 8 luật thử thách cho chế độ chuẩn.
##
## 1. Factory: "challenge" -> ChallengeGameMode; 8 luật, mỗi luật có khoá dịch riêng cho
##    Head/Name/Sub + lý do thua riêng.
## 2. Chuỗi ký tự trên khối THỜI GIAN: countdown "m:ss" + báo đỏ, move_limit "đã đi /N",
##    backtrack "lượt còn lại", luật mới có câu giải thích ở Sub.
## 3. Ván thật (scenes/game.tscn):
##    · move_limit vượt N bước -> popup `game_over_challenge` với lý do "quá bước", ẩn HỒI SINH
##    · no_tool: bấm gợi ý HOẶC hoàn tác -> thua
##    · no_move_overlapped: đi lại đường đã đi -> thua
##    · walk_number_only / walk_empty_only: bước vào SAI LOẠI ô -> thua
##    · countdown hết giờ thật (1 giây) -> thua · đi hết đường -> popup `win_challenge` + con dấu
## 4. HUD: switch_mode("challenge") dùng ChallengeHUD; Head/Value/Sub theo luật; hint guide
##    có câu riêng (STR_HINT_CHALLENGE).
## ============================================================================


var _failed := 0
var _checks := 0


func _init() -> void:
	print("\n========================================================")
	print("  TEST: CHALLENGE MODE (8 luat thu thach)")
	print("========================================================\n")

	await process_frame
	root.size = Vector2i(1080, 1920)

	_section_1_factory()
	_section_2_texts()
	await _section_3_run()
	await _section_4_hud()

	print("\n--------------------------------------------------------")
	if _failed == 0:
		print("  KET QUA: %d/%d CHECK PASS" % [_checks, _checks])
	else:
		print("  KET QUA: %d/%d CHECK FAIL" % [_failed, _checks])
	print("--------------------------------------------------------\n")
	quit(1 if _failed > 0 else 0)


func _entry(ok: bool, label: String) -> void:
	_checks += 1
	if ok:
		print("  [PASS] ", label)
	else:
		_failed += 1
		print("  [FAIL] ", label)


# ---------------------------------------------------------------------------
# 1. Factory + danh sách luật
# ---------------------------------------------------------------------------
func _section_1_factory() -> void:
	print("[1] Factory + 8 luat...")
	var controller := GameModeController.new()
	var mode: BaseGameMode = controller.set_mode_by_name("challenge", "medium")
	_entry(mode is ChallengeGameMode, "set_mode_by_name('challenge') -> ChallengeGameMode")
	var ch := mode as ChallengeGameMode
	if ch == null:
		return
	_entry(ch.mode_id == "challenge", "mode_id = 'challenge' (dang '%s')" % ch.mode_id)
	_entry(not ch.is_active(), "Mac dinh chua gan thu thach (is_active = false)")

	var ids := ChallengeGameMode.CHALLENGE_IDS
	_entry(ids.size() == 8, "Co dung 8 luat thu thach (dang %d)" % ids.size())
	var reasons := {}
	for id in ids:
		ch.set_challenge(str(id), 3)
		_entry(ch.is_active() and ch.challenge_id == str(id), "set_challenge('%s') nhan" % id)
		_entry(not ch.head_key().is_empty() and not ch.name_key().is_empty() and not ch.sub_key().is_empty(),
			"Luat '%s' co du khoa Head/Name/Sub" % id)
		_entry(not tr(ch.head_key()).begins_with("STR_"), "Head cua '%s' co ban dich that ('%s')" % [id, tr(ch.head_key())])
		var reason := ChallengeGameMode.fail_reason_for(str(id))
		_entry(not reasons.has(reason), "Ly do thua cua '%s' khong trung luat khac" % id)
		reasons[reason] = id
		_entry(not ChallengeGameMode.fail_key(reason).is_empty(), "Ly do '%s' co khoa dich" % id)

	ch.set_challenge("khong_ton_tai")
	_entry(not ch.is_active(), "Id la -> tat thu thach")


# ---------------------------------------------------------------------------
# 2. Chuỗi trên khối THỜI GIAN (Head/Value/Sub)
# ---------------------------------------------------------------------------
func _section_2_texts() -> void:
	print("\n[2] Chu tren khoi THOI GIAN theo luat...")
	var ch := ChallengeGameMode.new("medium")

	ch.set_challenge(ChallengeGameMode.COUNTDOWN, 20)
	var state := ch.hud_state(12.0, 0, 0.0, 0)
	_entry(str(state.get("value", "")) == "0:12", "countdown: Value = m:ss (dang '%s')" % state.get("value"))
	_entry(not bool(state.get("low", false)), "countdown 12s chua bao do")
	state = ch.hud_state(9.5, 0, 0.0, 0)
	_entry(bool(state.get("low", false)), "countdown duoi 10s -> bao do")

	ch.set_challenge(ChallengeGameMode.MOVE_LIMIT, 8)
	state = ch.hud_state(0.0, 3, 0.0, 0)
	_entry(str(state.get("value", "")) == "3" and str(state.get("sub", "")).begins_with("/8"),
		"move_limit: Value = so buoc da di, Sub = '/8 ...' (dang '%s' / '%s')" % [state.get("value"), state.get("sub")])

	ch.set_challenge(ChallengeGameMode.BACKTRACK_LIMIT, 3)
	state = ch.hud_state(0.0, 0, 0.0, 1)
	_entry(str(state.get("value", "")) == "1" and bool(state.get("low", false)),
		"backtrack_limit: Value = luot con lai + bao do khi gan het")

	ch.set_challenge(ChallengeGameMode.NO_TOOL, 0)
	state = ch.hud_state(0.0, 0, 0.0, 0)
	_entry(str(state.get("head", "")) == tr("STR_CHALLENGE_HEAD_NO_TOOL"), "no_tool: Head dich that")
	_entry(not str(state.get("sub", "")).is_empty(), "no_tool: Sub co cau giai thich")

	ch.set_challenge(ChallengeGameMode.WALK_NUMBER_ONLY, 0)
	state = ch.hud_state(0.0, 0, 0.0, 0)
	_entry(str(state.get("head", "")) == tr("STR_CHALLENGE_HEAD_WALK_NUMBER"),
		"walk_number_only: Head dich that ('%s')" % state.get("head"))

	ch.set_challenge(ChallengeGameMode.WALK_EMPTY_ONLY, 0)
	state = ch.hud_state(0.0, 0, 0.0, 0)
	_entry(str(state.get("head", "")) == tr("STR_CHALLENGE_HEAD_WALK_EMPTY"),
		"walk_empty_only: Head dich that ('%s')" % state.get("head"))


# ---------------------------------------------------------------------------
# 3. Ván thật: vi phạm -> popup thua riêng · hoàn thành -> popup thắng riêng
# ---------------------------------------------------------------------------
func _section_3_run() -> void:
	print("\n[3] Van thu thach (vi pham / hoan thanh)...")
	var scene: GameScene = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	assert(scene != null, "Phai load duoc scenes/game.tscn")
	root.add_child(scene)
	await process_frame
	await process_frame

	# --- move_limit: đi vượt 2 bước -> thua ---
	await _start_challenge_run(scene, ChallengeGameMode.MOVE_LIMIT, 2)
	var grid := scene.game_controller.grid_controller
	var start := grid.current_pos
	var neighbor := _open_neighbor(grid.maze, start)
	_entry(neighbor != start, "Man 1 co o ke khong tuong de di thu")
	grid.try_move_to(neighbor)
	grid.try_move_to(start)
	grid.try_move_to(neighbor)
	await process_frame
	await process_frame
	_entry(Popups.is_open(Popups.GAME_OVER_CHALLENGE), "Vuot buoc -> mo popup 'game_over_challenge'")
	var popup: BasePopup = Popups.get_popup(Popups.GAME_OVER_CHALLENGE)
	if popup != null:
		var title := popup.get("label_title") as Label
		_entry(title != null and title.text == tr("STR_CHALLENGE_FAIL_TITLE"),
			"Tieu de = 'THU THACH THAT BAI' (dang '%s')" % (title.text if title != null else "?"))
		var subtitle := popup.get("label_subtitle") as Label
		_entry(subtitle != null and subtitle.text.contains(tr("STR_CHALLENGE_FAIL_MOVES")),
			"Phu de neu dung ly do 'qua buoc' (dang '%s')" % (subtitle.text if subtitle != null else "?"))
		var revive := popup.get("btn_revive") as BaseButton
		_entry(revive != null and not revive.visible, "Nut HOI SINH bi an")
	Popups.close_all()
	await process_frame

	# --- no_tool: bấm gợi ý HOẶC hoàn tác -> thua ---
	await _start_challenge_run(scene, ChallengeGameMode.NO_TOOL, 0)
	scene.game_controller.hint()
	await process_frame
	await process_frame
	_entry(Popups.is_open(Popups.GAME_OVER_CHALLENGE), "No_tool: dung GOI Y -> mo popup thua thu thach")
	Popups.close_all()
	await process_frame

	await _start_challenge_run(scene, ChallengeGameMode.NO_TOOL, 0)
	scene.game_controller.undo()
	await process_frame
	await process_frame
	_entry(Popups.is_open(Popups.GAME_OVER_CHALLENGE), "No_tool: dung HOAN TAC -> mo popup thua thu thach")
	Popups.close_all()
	await process_frame

	# --- countdown: hết giờ thật (1 giây) -> thua ---
	await _start_challenge_run(scene, ChallengeGameMode.COUNTDOWN, 1)
	var waited := 0.0
	while waited < 3.0 and not Popups.is_open(Popups.GAME_OVER_CHALLENGE):
		await create_timer(0.1).timeout
		waited += 0.1
	_entry(Popups.is_open(Popups.GAME_OVER_CHALLENGE), "Het gio dem nguoc -> mo popup thua")
	Popups.close_all()
	await process_frame

	# --- no_move_overlapped: đi lại trên đường đã đi -> thua ---
	await _start_challenge_run(scene, ChallengeGameMode.NO_MOVE_OVERLAPPED, 0)
	grid = scene.game_controller.grid_controller
	start = grid.current_pos
	neighbor = _open_neighbor(grid.maze, start)
	grid.try_move_to(neighbor)
	grid.try_move_to(start)
	await process_frame
	await process_frame
	_entry(Popups.is_open(Popups.GAME_OVER_CHALLENGE), "Di lai duong da di -> mo popup thua thu thach")
	Popups.close_all()
	await process_frame

	# --- backtrack_limit: quay đầu quá 1 lần -> thua ---
	await _start_challenge_run(scene, ChallengeGameMode.BACKTRACK_LIMIT, 1)
	grid = scene.game_controller.grid_controller
	start = grid.current_pos
	neighbor = _open_neighbor(grid.maze, start)
	grid.try_move_to(neighbor)   # đi tới (không quay đầu)
	grid.try_move_to(start)      # quay đầu lần 1 (còn 0 lượt)
	grid.try_move_to(neighbor)   # đi tới
	grid.try_move_to(start)      # quay đầu lần 2 -> vượt 1 -> thua
	await process_frame
	await process_frame
	_entry(Popups.is_open(Popups.GAME_OVER_CHALLENGE), "Quay dau qua so lan -> mo popup thua thu thach")
	Popups.close_all()
	await process_frame

	# --- walk rule: bước vào SAI LOẠI ô -> thua (chọn luật mà ô kề CHẮC CHẮN vi phạm) ---
	await _start_challenge_run(scene, ChallengeGameMode.WALK_NUMBER_ONLY, 0)
	grid = scene.game_controller.grid_controller
	start = grid.current_pos
	neighbor = _open_neighbor(grid.maze, start)
	_entry(neighbor != start, "Man 1 co o ke de thu luat walk")
	var ch_run := scene.game_mode_controller.game_mode as ChallengeGameMode
	var walk_rule := ChallengeGameMode.WALK_NUMBER_ONLY \
			if ch_run.get_cell_text(neighbor, grid.maze).is_empty() else ChallengeGameMode.WALK_EMPTY_ONLY
	if walk_rule != ch_run.challenge_id:
		ch_run.set_challenge(walk_rule, 0)
		scene.game_controller.start_new_run(1)
		await process_frame
		await process_frame
		grid = scene.game_controller.grid_controller
		neighbor = _open_neighbor(grid.maze, grid.current_pos)
	grid.try_move_to(neighbor)
	await process_frame
	await process_frame
	_entry(Popups.is_open(Popups.GAME_OVER_CHALLENGE),
		"Walk '%s': buoc vao o sai loai -> mo popup thua" % walk_rule)
	Popups.close_all()
	await process_frame

	# --- step_timer: đứng yên quá X giây -> thua ---
	await _start_challenge_run(scene, ChallengeGameMode.STEP_TIMER, 1)
	waited = 0.0
	while waited < 3.0 and not Popups.is_open(Popups.GAME_OVER_CHALLENGE):
		await create_timer(0.1).timeout
		waited += 0.1
	_entry(Popups.is_open(Popups.GAME_OVER_CHALLENGE), "Dung yen qua lau (luat moi buoc) -> mo popup thua")
	Popups.close_all()
	await process_frame

	# --- hoàn thành: đi hết đường tới F -> popup thắng riêng ---
	await _start_challenge_run(scene, ChallengeGameMode.COUNTDOWN, 999)
	grid = scene.game_controller.grid_controller
	var path := _bfs_path(grid.maze, grid.current_pos, grid.maze.get_end())
	_entry(not path.is_empty(), "Man 1 co duong toi F (%d buoc)" % path.size())
	for pos: Vector2i in path:
		grid.try_move_to(pos)
	await process_frame
	await process_frame
	_entry(Popups.is_open(Popups.WIN_CHALLENGE), "Hoan thanh man -> mo popup 'win_challenge'")
	var win: BasePopup = Popups.get_popup(Popups.WIN_CHALLENGE)
	if win != null:
		var stamp := win.get("stamp_title") as Label
		_entry(stamp != null and stamp.text == tr("STR_CHALLENGE_STAMP_TITLE"),
			"Con dau ghi 'THU THACH' (dang '%s')" % (stamp.text if stamp != null else "?"))
	Popups.close_all()
	await process_frame

	scene.queue_free()
	await process_frame


## Bắt đầu ván Challenge với luật cho trước (đặt luật SAU switch_mode để không bị thay mode mới)
func _start_challenge_run(scene: GameScene, id: String, param: int) -> void:
	Popups.close_all()
	scene.switch_mode("challenge", "medium")
	await process_frame
	var ch := scene.game_mode_controller.game_mode as ChallengeGameMode
	ch.set_challenge(id, param)
	scene.game_controller.start_new_run(1)
	await process_frame
	await process_frame


# ---------------------------------------------------------------------------
# 4. HUD theo chế độ + hint guide
# ---------------------------------------------------------------------------
func _section_4_hud() -> void:
	print("\n[4] HUD thu thach + hint guide...")
	var scene: GameScene = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	scene.switch_mode("challenge", "medium")
	await process_frame
	var hud := scene.ui_controller.hud
	_entry(hud is ChallengeHUD, "Che do 'challenge' dung scene HUD ChallengeHUD")
	var chud := hud as ChallengeHUD
	if chud == null:
		scene.queue_free()
		return

	var ch := scene.game_mode_controller.game_mode as ChallengeGameMode
	ch.set_challenge(ChallengeGameMode.STEP_TIMER, 12)
	scene.game_controller.start_new_run(1)
	await process_frame
	_entry(chud.head_node != null and chud.head_node.text == tr("STR_CHALLENGE_HEAD_STEP_TIMER"),
		"Head = ten luat 'moi buoc' (dang '%s')" % (chud.head_node.text if chud.head_node != null else "?"))
	_entry(chud.time_value_node != null and not chud.time_value_node.text.is_empty() \
			and not chud.time_value_node.text.begins_with("STR_"),
		"Value = so chinh cua luat (dang '%s')" % (chud.time_value_node.text if chud.time_value_node != null else "?"))
	_entry(chud.sub_value_node != null and chud.sub_value_node.visible \
			and not chud.sub_value_node.text.is_empty(),
		"Sub = chu thich luat (dang '%s')" % (chud.sub_value_node.text if chud.sub_value_node != null else "?"))
	var guide := chud.hint_guide()
	_entry(guide != null and str(guide.call("current_text")) == tr("STR_HINT_CHALLENGE"),
		"Hint guide co cau rieng cho challenge")

	Popups.close_all()
	scene.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# Tiện ích: ô kề không tường · đường ngắn nhất (BFS)
# ---------------------------------------------------------------------------
func _open_neighbor(maze: MazeData, pos: Vector2i) -> Vector2i:
	for dir: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
		var next: Vector2i = pos + dir
		if next.x < 0 or next.y < 0 or next.x >= maze.width or next.y >= maze.height:
			continue
		if not maze.has_wall(pos, next):
			return next
	return pos


func _bfs_path(maze: MazeData, from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var queue: Array[Vector2i] = [from]
	var came := {from: from}
	while not queue.is_empty():
		var cur: Vector2i = queue.pop_front()
		if cur == to:
			break
		for dir: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cur + dir
			if next.x < 0 or next.y < 0 or next.x >= maze.width or next.y >= maze.height:
				continue
			if came.has(next) or maze.has_wall(cur, next):
				continue
			came[next] = cur
			queue.append(next)
	var path: Array[Vector2i] = []
	if not came.has(to):
		return path
	var walk := to
	while walk != from:
		path.push_front(walk)
		walk = came[walk]
	return path
