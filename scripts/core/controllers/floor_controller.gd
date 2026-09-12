class_name FloorController
extends RefCounted
## ============================================================================
## Controller: Quản lý vòng đời Floor & Sinh dữ liệu Mê Cung theo GameMode.
## ============================================================================

signal floor_started(floor_number: int, maze: MazeData)

var current_maze: MazeData = null
var current_floor: int = 1


func setup_floor(floor_number: int, mode: BaseGameMode = null) -> MazeData:
	current_floor = floor_number

	if mode != null:
		current_maze = mode.setup_floor(floor_number)
	else:
		var size := FloorConfig.get_grid_size(floor_number)
		var ratio := FloorConfig.get_visible_ratio(floor_number)
		current_maze = MazeData.new()
		current_maze.generate(size, size, ratio)

	floor_started.emit(current_floor, current_maze)
	return current_maze
