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
		_entry(scene.label_ad_title != null, "label_ad_title da bind")
		_entry(scene.label_ad_desc != null, "label_ad_desc da bind")
		_entry(scene.label_gold_title != null, "label_gold_title da bind")
		_entry(scene.label_gold_desc != null, "label_gold_desc da bind")
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
	_entry(popup.label_gold_title != null and popup.label_gold_title.text.contains("50"), "label_gold_title hien thi dung 50 Xu")

	# Test skip
	var skip_called := false
	popup.skip_requested.connect(func(): skip_called = true)
	popup._on_skip_pressed()
	await process_frame
	_entry(skip_called, "Bam bo qua -> phat skip_requested")

	popup.queue_free()
	await process_frame


func _test_flow_integration() -> void:
	var ui: UIController = UIController.new()
	root.add_child(ui)
	await process_frame

	# Gia lap game over voi force_retry_popup = true
	var retry_emitted := false
	ui.retry_requested.connect(func(): retry_emitted = true)

	ui.show_game_over({"force_retry_popup": true, "endless": false})
	await process_frame
	await process_frame

	_entry(Popups.is_open(Popups.RETRY), "Game over mo popup RETRY truoc tien")
	_entry(not Popups.is_open(Popups.GAME_OVER_LEVEL), "Chua mo popup GAME_OVER_LEVEL")

	# Khi bo qua retry popup:
	var retry_p := Popups.get_popup(Popups.RETRY) as RetryPopup
	if retry_p != null:
		retry_p._on_skip_pressed()
		await process_frame
		await process_frame
		_entry(not Popups.is_open(Popups.RETRY), "Popup RETRY da dong")
		_entry(Popups.is_open(Popups.GAME_OVER_LEVEL), "Sau khi bo qua -> mo popup GAME_OVER_LEVEL")
		Popups.close_all()
		await process_frame

	ui.queue_free()
	await process_frame
