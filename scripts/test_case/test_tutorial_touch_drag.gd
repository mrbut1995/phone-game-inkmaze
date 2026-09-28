extends SceneTree

var _failed := 0
var _checks := 0

func _init() -> void:
	var scene: Node = (load("res://nodes/tutorials/how_to_play_move.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var board := scene.get_board_tutorial() as BoardTutorial
	assert(board != null, "Board tutorial should exist")
	var start_cell: Vector2 = board.get_global_transform_with_canvas() * board.get_cell_center(Vector2i(0, 0))
	var next_cell: Vector2 = board.get_global_transform_with_canvas() * board.get_cell_center(Vector2i(1, 0))

	var touch_down := InputEventScreenTouch.new()
	touch_down.pressed = true
	touch_down.position = start_cell
	scene._gui_input(touch_down)
	_check(scene.get("_is_dragging") == true, "Touch down starts drag")

	var drag := InputEventScreenDrag.new()
	drag.position = next_cell
	scene._gui_input(drag)
	_check(scene.get("_visited_cells").size() == 2, "Screen drag advances to next cell")

	print("RESULT: %d/%d checks passed" % [_checks - _failed, _checks])
	quit(1 if _failed > 0 else 0)

func _check(cond: bool, label: String) -> void:
	_checks += 1
	if not cond:
		_failed += 1
		print("FAIL: %s" % label)
	else:
		print("PASS: %s" % label)
