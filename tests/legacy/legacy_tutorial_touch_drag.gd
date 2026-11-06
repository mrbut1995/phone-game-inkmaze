extends SceneTree

var _failed := 0
var _checks := 0

func _init() -> void:
	var scene: Node = (load("res://scenes/objects/tutorials/how_to_play_move.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var board := scene.get_board_tutorial() as BoardTutorial
	assert(board != null, "Board tutorial should exist")
	# Kéo/vuốt trên bàn cờ phát `cell_step_attempted`; tutorial nghe signal đó (dây nối trong .tscn).
	# Bài "how_to_play_move" chỉ cho tương tác ở bước 1–2 ⇒ mở bước 1 trước.
	scene.call("show_step", 1)
	await process_frame
	var start_cell: Vector2i = board.get("_player_current_cell")
	var next_cell := start_cell + Vector2i(1, 0)

	var before := (scene.get("_visited_cells") as Array).size()
	board.cell_step_attempted.emit(next_cell)
	await process_frame
	var after := (scene.get("_visited_cells") as Array).size()
	_check(after == before + 1, "Screen drag advances to next cell (%d -> %d)" % [before, after])
	_check(board.get("_player_current_cell") == next_cell, "Player cursor follows the drag")

	print("RESULT: %d/%d checks passed" % [_checks - _failed, _checks])
	quit(1 if _failed > 0 else 0)

func _check(cond: bool, label: String) -> void:
	_checks += 1
	if not cond:
		_failed += 1
		print("FAIL: %s" % label)
	else:
		print("PASS: %s" % label)
