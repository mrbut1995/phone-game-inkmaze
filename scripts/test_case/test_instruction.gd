extends SceneTree
var _failures := 0
var _checks := 0


func _init() -> void:
	print("\n===== TEST: HE HUONG DAN =====\n")
	await process_frame
	TranslationServer.set_locale("vi")
	await _check_integration()
	await _check_status_bar_portrait()
	if _failures == 0:
		print("\n[SUCCESS] " + str(_checks) + " check PASS")
	else:
		print("\n[FAILED] " + str(_failures) + "/" + str(_checks) + " check loi")
	quit(1 if _failures > 0 else 0)


func _fail(msg: String) -> void:
	_failures += 1
	print("  [FAIL] ", msg)


func _ok(msg: String) -> void:
	_checks += 1
	print("  [OK]   ", msg)


func _check(cond: bool, msg: String) -> void:
	if cond: _ok(msg)
	else: _fail(msg)


# open_instruction() -> mo Tutorial dạng LỚP PHỦ trên màn chơi, KHÔNG mở popup instruction
# (dungeon KHÔNG có nút "?" ⇒ không mở gì)
func _check_integration() -> void:
	print("-- open_instruction -> LOP PHU TUTORIAL --")
	var gm: Node = root.get_node_or_null("GameManager")
	if gm == null:
		_fail("Khong tim thay GameManager")
		return
	for mode_id: String in ["play", "minesweeper", "dungeon"]:
		gm.set("current_mode", mode_id)
		gm.set("current_level", 1)
		gm.set("unlocked_levels", 99)
		gm.set("pending_tutorial", "")
		gm.set("pending_return_to_game", false)
		var scene: GameScene = (load("res://scenes/game.tscn") as PackedScene).instantiate()
		root.add_child(scene)
		await process_frame
		await process_frame
		scene.switch_mode(mode_id)
		await process_frame
		scene.game_controller.open_instruction()
		await process_frame
		var want: String = ",".join(GameController.TUTORIAL_IDS.get(mode_id, []))
		var overlay: Node = scene.get_node_or_null("TutorialOverlay")
		if want.is_empty():
			_check(overlay == null, mode_id + ": open_instruction -> KHONG mo tutorial")
		else:
			# Yêu cầu được lớp phủ đọc NGAY (đồng bộ) — kiểm bài đang chạy thay vì cờ pending
			var first_want := want.split(",")[0]
			var played := ""
			var returning := false
			if overlay != null:
				var ctrl: Node = overlay.get("tutorial_controller")
				played = str(ctrl.get("current_tutorial_id")) if ctrl != null else ""
				returning = bool(overlay.get("_return_to_game"))
			_check(overlay != null and played == first_want and returning,
				mode_id + ": open_instruction -> LOP PHU tutorial '%s' (dang '%s')" % [first_want, played])
		Popups.close_all()
		scene.queue_free()
		await process_frame


# Nut ? tren status bar cua layout doc
func _check_status_bar_portrait() -> void:
	print("-- Layout doc: nut ? tren status bar --")
	var ls: Node = (load("res://scenes/layout/portrait/game.tscn") as PackedScene).instantiate()
	root.add_child(ls)
	await process_frame
	_check(ls.get("instruction_btn") != null, "layout doc: co bind instruction_btn")
	_check(ls.get_node_or_null("Status/Instruction") != null,
			"StatusBar doc: co nut Instruction")
	ls.queue_free()
	await process_frame
