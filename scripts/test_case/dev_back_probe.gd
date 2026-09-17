extends SceneTree
## DEV TOOL (tạm): kiểm tra nút Back/Esc có đóng popup Game Over không
##   godot --headless --path . --script res://scripts/test_case/dev_back_probe.gd


func _init() -> void:
	await process_frame
	var scene: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await _frames(12)
	var controller: Node = scene.get("game_controller")
	controller.call("_game_over", "dam_tuong")
	await _frames(40)
	print("[1] sau game over: has_open=%s top=%s" % [str(Popups.has_open()), _top_id()])

	var ev := InputEventKey.new()
	ev.keycode = KEY_ESCAPE
	ev.physical_keycode = KEY_ESCAPE
	ev.pressed = true
	Input.parse_input_event(ev)
	await _frames(20)
	print("[2] sau ESC 1:   has_open=%s top=%s" % [str(Popups.has_open()), _top_id()])

	var ev2 := InputEventKey.new()
	ev2.keycode = KEY_ESCAPE
	ev2.physical_keycode = KEY_ESCAPE
	ev2.pressed = true
	Input.parse_input_event(ev2)
	await _frames(20)
	print("[3] sau ESC 2:   has_open=%s top=%s" % [str(Popups.has_open()), _top_id()])
	print("quit_on_go_back=%s" % str(ProjectSettings.get_setting("application/config/quit_on_go_back", "unset")))
	quit(0)


func _top_id() -> String:
	var pop := Popups.top()
	return pop.popup_id if pop != null else "null"


func _frames(n: int) -> void:
	for i in n:
		await process_frame
