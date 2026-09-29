extends SceneTree
var _failures := 0
var _checks := 0


func _init() -> void:
	print("\n===== TEST: HE HUONG DAN =====\n")
	await process_frame
	TranslationServer.set_locale("vi")
	await _check_integration()
	await _check_status_bar_landscape()
	if _failures == 0:
		print("\n[SUCCESS] " + str(_checks) + " check PASS")
	else:
		print("\n[FAILED] " + str(_failures) + "/" + str(_checks) + " check loi")
	quit(0)


func _fail(msg: String) -> void:
	_failures += 1
	print("  [FAIL] ", msg)


func _ok(msg: String) -> void:
	_checks += 1
	print("  [OK]   ", msg)


func _check(cond: bool, msg: String) -> void:
	if cond: _ok(msg)
	else: _fail(msg)


# open_instruction() -> dat co tutorial, KHONG mo popup instruction
func _check_integration() -> void:
	print("-- open_instruction -> TUTORIAL --")
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
		var request: String = str(gm.get("pending_tutorial"))
		var return_to_game: bool = bool(gm.get("pending_return_to_game"))
		await process_frame
		var want: String = ",".join(GameController.TUTORIAL_IDS.get(mode_id, []))
		_check(request == want and return_to_game == not want.is_empty(),
			mode_id + ": open_instruction -> tutorial")
		if current_scene != null and current_scene != scene:
			var loaded: Node = current_scene
			current_scene = null
			loaded.queue_free()
		Popups.close_all()
		scene.queue_free()
		await process_frame


# Layout ngang: nut ? tren status bar
func _check_status_bar_landscape() -> void:
	print("-- Layout ngang: nut ? tren status bar --")
	var ls: Node = (load("res://scenes/layout/landscape/game.tscn") as PackedScene).instantiate()
	root.add_child(ls)
	await process_frame
	_check(ls.get("instruction_btn") != null, "layout ngang: co bind instruction_btn")
	_check(ls.get_node_or_null("Content/LeftCol/Status/Bar/Instruction") != null,
			"StatusBar ngang: co nut Instruction")
	ls.queue_free()
	await process_frame
