extends SceneTree
## ============================================================================
## Test: Blind Memory Maze — pha GHI NHỚ (đếm ngược trước khi tường biến mất).
##   - HUD riêng (BlindMemoryHUD): KHÔNG có thẻ THỬ THÁCH.
##   - Vào màn: hiện TOÀN BỘ tường + khoá tương tác + ĐỒNG HỒ DỪNG + popup đếm ngược mở.
##   - Hết đếm ngược: tường ẩn lại + mở tương tác + đồng hồ chạy (giờ chơi không tính lúc ghi nhớ).
##   - Pha ghi nhớ KHÔNG vẽ label trong board nữa (label cũ bị setup_maze xoá -> crash Null).
## ============================================================================

var _failures := 0


func _init() -> void:
	print("\n========================================================")
	print("  TEST: BLIND MEMORY — PHA GHI NHO + POPUP DEM NGUOC")
	print("========================================================\n")

	# Autoload chỉ tồn tại sau frame đầu tiên khi chạy bằng --script
	await process_frame
	var gm: Node = root.get_node_or_null("GameManager")
	if gm == null:
		_fail("Khong tim thay autoload GameManager")
		quit(0)
		return
	gm.set("current_mode", "blind_memory")
	gm.set("current_level", 1)
	gm.set("unlocked_levels", 99)

	var packed: PackedScene = load("res://scenes/game.tscn")
	assert(packed != null, "scenes/game.tscn phai load duoc")
	var scene: GameScene = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var gc: GameController = scene.game_controller
	var board := gc.grid_view
	var mode := scene.game_mode_controller.game_mode as BlindMemoryGameMode
	if gc == null or board == null or mode == null:
		_fail("Khong lay duoc GameController / Board / BlindMemoryGameMode")
		quit(0)
		return

	_check_hud(scene, gc)
	_check_memorize_phase(scene, gc, board, mode)
	await _check_after_countdown(gc, board)

	if _failures == 0:
		print("[SUCCESS] Blind Memory: pha ghi nho + popup dem nguoc hoat dong dung!")
	else:
		print("[FAILED] %d loi ve Blind Memory." % _failures)
	quit(0)


func _fail(msg: String) -> void:
	_failures += 1
	print("[FAIL] ", msg)


# ---------------------------------------------------------------------------
# 1. HUD riêng, KHÔNG có thẻ Thử thách
# ---------------------------------------------------------------------------
func _check_hud(scene: GameScene, gc: GameController) -> void:
	var hud := scene.ui_controller.hud
	if not (hud is BlindMemoryHUD):
		_fail("Blind Memory phai dung BlindMemoryHUD (dang la '%s')" % (
			hud.get_script().resource_path.get_file() if hud != null and hud.get_script() != null else "<null>"))
		return
	if hud.challenge_card() != null:
		_fail("HUD Blind Memory KHONG duoc co the THU THACH")
	if gc.challenge_controller != null and gc.challenge_controller.card != null:
		_fail("ChallengeController khong duoc tro vao the thu thach o Blind Memory")
	var note := hud.get_node_or_null("Note/Title") as Label
	if note == null or note.text.is_empty():
		_fail("HUD Blind Memory thieu dong nhac GHI NHO")
	var time_val := hud.get_node_or_null("Time/Value") as Label
	if time_val == null or time_val.text.is_empty():
		_fail("HUD Blind Memory thieu gia tri THOI GIAN")
	print("[CHECK] HUD Blind Memory: khong co the Thử thách, co the GHI NHỚ + THỜI GIAN")


# ---------------------------------------------------------------------------
# 2. Pha ghi nhớ: tường hiện hết, khoá tương tác, đồng hồ dừng, popup mở
# ---------------------------------------------------------------------------
func _check_memorize_phase(scene: GameScene, gc: GameController, board: BoardView, mode: BlindMemoryGameMode) -> void:
	if mode.memorize_countdown_seconds <= 0:
		_fail("BlindMemoryGameMode phai bat memorize_countdown_seconds (> 0)")
		return
	if not gc._memorize_active:
		_fail("Vua vao man phai dang o pha GHI NHO (_memorize_active)")

	var total := board._wall_segments.size()
	var visible := 0
	for key in board._wall_segments:
		var seg: WallSegment = board._wall_segments[key]
		if seg.visible:
			visible += 1
	if total <= 0:
		_fail("Man Blind Memory phai co tuong")
	elif visible != total:
		_fail("Pha ghi nho phai hien TOAN BO tuong (%d/%d dang hien)" % [visible, total])

	if board._interaction_enabled:
		_fail("Pha ghi nho phai KHOÁ tuong tac (khong cho di khi chua ghi nho xong)")
	if gc.timer_controller.is_running:
		_fail("Pha ghi nho phai DUNG dong ho (thoi gian ghi nho khong tinh vao gio choi)")
	if not Popups.is_open(Popups.MEMORIZE):
		_fail("Pha ghi nho phai mo popup dem nguoc (Popups.MEMORIZE)")

	# Popup cũ nằm trong board (label vẽ bằng code) -> bị setup_maze xoá gây crash. Nay không còn.
	if board._markers_layer != null:
		var stray_labels := 0
		for child in board._markers_layer.get_children():
			if child is Label:
				stray_labels += 1
		if stray_labels > 0:
			_fail("Pha ghi nho khong duoc tu ve label trong board (%d label trong Markers)" % stray_labels)

	var popup := Popups.get_popup(Popups.MEMORIZE)
	var number := popup.get_node_or_null("Panel/Content/Number") as Label if popup != null else null
	if number == null or number.text.is_empty():
		_fail("Popup dem nguoc thieu so hien thi")
	print("[CHECK] Pha GHINHO: %d/%d tuong hien · tuong_tac=khoa · dong_ho=dung · popup dem nguoc mo" % [visible, total])


# ---------------------------------------------------------------------------
# 3. Hết đếm ngược: tường ẩn, mở tương tác, đồng hồ chạy từ 0
# ---------------------------------------------------------------------------
func _check_after_countdown(gc: GameController, board: BoardView) -> void:
	var popup := Popups.get_popup(Popups.MEMORIZE)
	if popup == null:
		_fail("Khong tim thay popup dem nguoc de ket thuc")
		return
	popup.call("_finish")          # giả lập đếm ngược chạy xong
	await process_frame
	await process_frame

	var visible := 0
	for key in board._wall_segments:
		var seg: WallSegment = board._wall_segments[key]
		if seg.visible:
			visible += 1
	if visible != 0:
		_fail("Het dem nguoc phai AN het tuong (%d dang hien)" % visible)
	if not board._interaction_enabled:
		_fail("Het dem nguoc phai MO LAI tuong tac")
	if not gc.timer_controller.is_running:
		_fail("Het dem nguoc phai cho dong ho chay")
	if gc._memorize_active:
		_fail("Het dem nguoc phai tat co _memorize_active")
	if gc.timer_controller.floor_elapsed > 1.0:
		_fail("Gio choi phai bat dau tu 0 sau khi ghi nho (dang %.1fs)" % gc.timer_controller.floor_elapsed)
	print("[CHECK] Het dem nguoc: tuong da an · tuong_tac=mo · dong_ho chay tu %.2fs" % gc.timer_controller.floor_elapsed)
