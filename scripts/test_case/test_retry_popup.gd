extends SceneTree
## ============================================================================
## Test Case: RETRY POPUP & GAME OVER FLOW
## ============================================================================

var _failed := 0
var _checks := 0


func _init() -> void:
	print("\n========================================================")
	print("  TEST: RETRY POPUP & GAME OVER FLOW")
	print("========================================================\n")
	root.size = Vector2i(1080, 1920)
	await process_frame

	await _test_scene_and_bindings()
	await _test_retry_actions()
	await _test_flow_integration()
	await _test_revive_unlocks_board()

	print("\n--------------------------------------------------------")
	if _failed == 0:
		print("  KET QUA: %d/%d CHECK PASS" % [_checks, _checks])
	else:
		print("  KET QUA: FAIL %d/%d CHECK" % [_failed, _checks])
	print("--------------------------------------------------------\n")
	quit(1 if _failed > 0 else 0)


func _entry(ok: bool, desc: String) -> void:
	_checks += 1
	if ok:
		print("  [PASS] %s" % desc)
	else:
		_failed += 1
		print("  [FAIL] %s" % desc)


func _test_scene_and_bindings() -> void:
	var packed := load("res://nodes/popups/retry.tscn") as PackedScene
	_entry(packed != null, "Load duoc nodes/popups/retry.tscn")
	if packed == null:
		return

	var scene := packed.instantiate() as RetryPopup
	root.add_child(scene)
	await process_frame

	_entry(scene != null, "Instantiate duoc RetryPopup")
	if scene != null:
		_entry(scene.label_title != null, "label_title da bind")
		_entry(scene.label_subtitle != null, "label_subtitle da bind")
		_entry(scene.btn_ad != null, "btn_ad da bind")
		_entry(scene.btn_gold != null, "btn_gold da bind")
		_entry(scene.btn_skip != null, "btn_skip da bind")
		_entry(scene.label_gold_cost != null, "label_gold_cost da bind")
		_entry(scene.skip_cost != null, "skip_cost da bind")
		_entry(scene.pencils != null, "pencils da bind")
		_entry(scene.label_warning != null, "label_warning da bind")

	scene.queue_free()
	await process_frame


func _test_retry_actions() -> void:
	var packed := load("res://nodes/popups/retry.tscn") as PackedScene
	var popup := packed.instantiate() as RetryPopup
	root.add_child(popup)
	await process_frame

	popup.open({"gold_cost": 50})
	await process_frame

	_entry(popup._gold_cost == 50, "Cai dat gold_cost = 50 tu data")
	_entry(popup.label_gold_cost != null and popup.label_gold_cost.text == "50",
		"label_gold_cost hien thi dung 50 Xu")

	# Test skip (dùng Array: lambda trong GDScript chụp biến cục bộ theo GIÁ TRỊ)
	var skip_hits: Array[int] = []
	popup.skip_requested.connect(func(): skip_hits.append(1))
	popup._on_skip_pressed()
	await process_frame
	_entry(skip_hits.size() == 1, "Bam bo qua -> phat skip_requested")

	# TRẢ XU / XEM QUẢNG CÁO -> phát `revive_requested` (đi đúng đường HỒI SINH của popup Game Over)
	var methods: Array[String] = []
	popup.revive_requested.connect(func(m): methods.append(str(m)))
	popup.open({"gold_cost": 0})     # giá 0 Xu để test được mà không cần số dư
	await process_frame
	popup._on_gold_pressed()
	await process_frame
	_entry(methods == ["gold"], "Bam TRA XU -> phat revive_requested('gold')")

	var ads := root.get_node_or_null("AdsManager")
	var ads_before := false
	if ads != null:
		ads_before = bool(ads.get("enabled"))
		ads.set("enabled", true)
	popup.open({"gold_cost": 0})
	await process_frame
	popup._on_ad_pressed()
	await process_frame
	_entry(methods == ["gold", "ad"], "Bam XEM QUANG CAO -> phat revive_requested('ad')")
	if ads != null:
		ads.set("enabled", ads_before)

	popup.queue_free()
	await process_frame


func _test_flow_integration() -> void:
	var ui: UIController = UIController.new()
	root.add_child(ui)
	await process_frame

	var ads := root.get_node_or_null("AdsManager")
	var ads_before := false
	if ads != null:
		ads_before = bool(ads.get("enabled"))
		ads.set("enabled", true)

	# Gia lap game over voi force_retry_popup = true
	# (dùng Array để lambda ghi vào biến NGOÀI — GDScript chụp biến cục bộ theo giá trị)
	var retry_hits: Array[int] = []
	var revive_hits: Array[int] = []
	ui.retry_requested.connect(func(): retry_hits.append(1))
	ui.revive_confirmed.connect(func(): revive_hits.append(1))

	ui.show_game_over({"force_retry_popup": true, "endless": false})
	await process_frame
	await process_frame

	_entry(Popups.is_open(Popups.RETRY), "Game over mo popup RETRY truoc tien")
	_entry(not Popups.is_open(Popups.GAME_OVER_LEVEL), "Chua mo popup GAME_OVER_LEVEL")

	# THỬ LẠI bằng quảng cáo trong popup Retry = HỒI SINH (KHÔNG phải mở ván mới)
	var retry_p := Popups.get_popup(Popups.RETRY) as RetryPopup
	if retry_p != null:
		retry_p._on_ad_pressed()
		await process_frame
		await process_frame
		_entry(revive_hits.size() == 1, "Bam XEM QUANG CAO o popup RETRY -> phat revive_confirmed")
		_entry(retry_hits.is_empty(), "Thu lai KHONG phai mo van moi (khong phat retry_requested)")
		await create_timer(0.6).timeout     # chờ hiệu ứng đóng popup chạy xong
		_entry(not Popups.is_open(Popups.RETRY), "Popup RETRY da dong sau khi thu lai")
		_entry(not Popups.is_open(Popups.GAME_OVER_LEVEL), "Thu lai KHONG mo popup GAME_OVER_LEVEL")
	Popups.close_all()
	await create_timer(0.6).timeout

	# Khi bo qua retry popup:
	ui.show_game_over({"force_retry_popup": true, "endless": false})
	await process_frame
	await process_frame
	var retry_skip := Popups.get_popup(Popups.RETRY) as RetryPopup
	if retry_skip != null:
		retry_skip._on_skip_pressed()
		await process_frame
		await create_timer(0.6).timeout
		_entry(not Popups.is_open(Popups.RETRY), "Popup RETRY da dong sau khi bo qua")
		_entry(Popups.is_open(Popups.GAME_OVER_LEVEL), "Sau khi bo qua -> mo popup GAME_OVER_LEVEL")
		Popups.close_all()
		await create_timer(0.6).timeout

	if ads != null:
		ads.set("enabled", ads_before)

	ui.queue_free()
	await process_frame


## HỒI QUY (bug 2026-10): thua màn -> popup RETRY -> XEM QUẢNG CÁO phải MỞ KHOÁ bàn cờ
## và cho đi tiếp, y như nút HỒI SINH của popup Game Over. Trước đây popup chỉ đóng lại
## còn bàn cờ giữ nguyên trạng thái khoá (`_interaction_enabled = false`) nên không di chuyển được.
func _test_revive_unlocks_board() -> void:
	var gm := root.get_node_or_null("GameManager")
	if gm == null:
		_entry(false, "Autoload GameManager ton tai")
		return

	var backup := ""
	if FileAccess.file_exists("user://inkmaze_data.json"):
		backup = FileAccess.get_file_as_string("user://inkmaze_data.json")

	gm.set("current_mode", "play")
	gm.set("current_level", 3)
	gm.set("unlocked_levels", 9)

	var ads := root.get_node_or_null("AdsManager")
	var ads_before := false
	if ads != null:
		ads_before = bool(ads.get("enabled"))
		ads.set("enabled", true)

	var scene := (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var controller: GameController = scene.get("game_controller")
	var grid_controller: Node = scene.get("grid_controller")
	var board: Node = controller.get("grid_view")

	# Thua màn: đâm tường (Play mode thua ngay) hoặc gọi thẳng luồng thua
	var blocked := _find_blocked_neighbor(grid_controller)
	if blocked != Vector2i(-1, -1):
		grid_controller.call("try_move_to", blocked)
	else:
		controller.call("_game_over")
	await process_frame
	await process_frame
	await create_timer(0.6).timeout

	_entry(Popups.is_open(Popups.RETRY), "Thua man -> mo popup RETRY")
	_entry(board != null and not bool(board.get("_interaction_enabled")),
		"Ban co dang KHOA ngay sau khi thua")

	var retry_p := Popups.get_popup(Popups.RETRY) as RetryPopup
	if retry_p != null:
		retry_p._on_ad_pressed()             # = nguoi choi bam XEM QUANG CAO
		await process_frame
		await process_frame
		await create_timer(0.6).timeout

		_entry(bool(controller.get("_run_active")), "Sau khi THU LAI: van choi dang chay")
		_entry(not bool(controller.get("_floor_finished")), "Sau khi THU LAI: man khong con ket thuc")
		_entry(board != null and bool(board.get("_interaction_enabled")),
			"Ban co duoc MO KHOA sau khi THU LAI (o khoa = bug cu)")
		var timer: Node = controller.get("timer_controller")
		_entry(timer != null and bool(timer.get("is_running")), "Dong ho chay lai sau khi THU LAI")
		_entry(not Popups.is_open(Popups.RETRY), "Popup RETRY da dong")

		# Đi thử 1 bước thật để chắc chắn bàn cờ nhận input
		var pos_before: Vector2i = grid_controller.get("current_pos")
		var free := _find_free_neighbor(grid_controller)
		var moved := false
		if free != Vector2i(-1, -1):
			grid_controller.call("try_move_to", free)
			await process_frame
			moved = Vector2i(grid_controller.get("current_pos")) != pos_before
		_entry(free == Vector2i(-1, -1) or moved, "Sau khi THU LAI: di chuyen duoc that su")

	Popups.close_all()
	await create_timer(0.6).timeout
	scene.queue_free()
	await process_frame

	if ads != null:
		ads.set("enabled", ads_before)
	if not backup.is_empty():
		var wf := FileAccess.open("user://inkmaze_data.json", FileAccess.WRITE)
		wf.store_string(backup)
		wf.flush()


## Ô kề cạnh vị trí hiện tại mà KHÔNG bị tường chặn (để test đi được thật)
func _find_free_neighbor(grid_controller: Node) -> Vector2i:
	var maze: MazeData = grid_controller.get("maze")
	if maze == null:
		return Vector2i(-1, -1)
	var from_pos: Vector2i = grid_controller.get("current_pos")
	for step: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT]:
		var nxt := from_pos + step
		if maze.is_in_bounds(nxt) and maze.is_cell_active(nxt) and not maze.has_wall(from_pos, nxt):
			return nxt
	return Vector2i(-1, -1)


## Ô kề cạnh bị tường chặn (để đâm tường -> thua màn)
func _find_blocked_neighbor(grid_controller: Node) -> Vector2i:
	var maze: MazeData = grid_controller.get("maze")
	if maze == null:
		return Vector2i(-1, -1)
	var from_pos: Vector2i = maze.get_start()
	for step: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT]:
		var nxt := from_pos + step
		if maze.is_in_bounds(nxt) and maze.has_wall(from_pos, nxt):
			return nxt
	return Vector2i(-1, -1)
