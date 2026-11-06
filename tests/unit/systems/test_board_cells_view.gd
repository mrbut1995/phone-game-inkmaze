extends TestCase
## Tests for BoardCellsView (scripts/systems/BoardCellsView.gd)

var _marker_calls := 0


func _no_cell(_pos: Vector2i) -> MazeCell:
	return null


func _count_marker(_cell: MazeCell, _pos: Vector2i) -> void:
	_marker_calls += 1


func test_null_maze_or_mode_is_ignored() -> void:
	BoardCellsView.refresh_texts(3, 3, _no_cell, null, null, true, _count_marker)
	BoardCellsView.apply_fog(3, 3, _no_cell, null, null, {}, _count_marker)
	assert_eq(_marker_calls, 0, "thiếu dữ liệu thì không đụng vào ô nào")


func test_cells_missing_from_board_are_skipped() -> void:
	var maze := MazeData.new()
	maze.generate(3, 3, 0.5)
	var mode := StandardGameMode.new()
	BoardCellsView.refresh_texts(3, 3, _no_cell, maze, mode, false, _count_marker)
	BoardCellsView.apply_fog(3, 3, _no_cell, maze, mode, {}, _count_marker)
	assert_eq(_marker_calls, 0, "ô chưa có node thì không đồng bộ huy hiệu")
