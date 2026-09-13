class_name LevelData
extends Resource
## ============================================================================
## Resource: Dữ liệu cấu hình cho 1 Màn chơi (Level Data Resource)
## Cho phép lưu trữ và chỉnh sửa trực tiếp dưới dạng file .tres trong Godot.
## ============================================================================

@export var level_id: int = 1
@export var level_title: String = "Level 1-1"
@export var chapter: int = 1
@export var mode_id: String = "play"
@export var difficulty: String = "medium"

@export var width: int = 3
@export var height: int = 3
@export var start_pos: Vector2i = Vector2i(0, 2)
@export var end_pos: Vector2i = Vector2i(2, 0)
@export var max_steps: int = 15
@export var par_time: float = 45.0

## Tường dọc: (width + 1) * height bytes (1 = có tường, 0 = mở)
@export var v_walls: PackedByteArray = PackedByteArray()
## Hiển thị tường dọc: (width + 1) * height bytes (1 = thấy, 0 = tàng hình)
@export var v_walls_visible: PackedByteArray = PackedByteArray()

## Tường ngang: width * (height + 1) bytes (1 = có tường, 0 = mở)
@export var h_walls: PackedByteArray = PackedByteArray()
## Hiển thị tường ngang: width * (height + 1) bytes (1 = thấy, 0 = tàng hình)
@export var h_walls_visible: PackedByteArray = PackedByteArray()

## HÌNH DẠNG BOARD (polyomino): width * height bytes, index = y * width + x
## 1 = ô thuộc board (có hình vuông để chơi), 0 = ô trống (ngoài board, không đi được).
## Để trống = chữ nhật đầy đủ (tương thích với các màn cũ).
@export var cell_mask: PackedByteArray = PackedByteArray()

## Dữ liệu mở rộng cho các mode khác (Minesweeper, Sum Path, ...)
@export var custom_cell_values: Dictionary = {}


## Chuyển đổi Resource LevelData thành đối tượng Runtime MazeData
func to_maze_data() -> MazeData:
	var maze := MazeData.new()
	maze.width = maxi(2, width)
	maze.height = maxi(2, height)
	maze.start = start_pos
	maze.end = end_pos

	maze._init_walls()

	# Nạp tường dọc
	var v_total := (maze.width + 1) * maze.height
	if v_walls.size() == v_total:
		for ix in maze.width + 1:
			for iy in maze.height:
				var idx := ix * maze.height + iy
				maze._v_walls[ix][iy] = v_walls[idx]
				if v_walls_visible.size() == v_total:
					maze._v_visible[ix][iy] = v_walls_visible[idx]

	# Nạp tường ngang
	var h_total := maze.width * (maze.height + 1)
	if h_walls.size() == h_total:
		for ix in maze.width:
			for iy in maze.height + 1:
				var idx := ix * (maze.height + 1) + iy
				maze._h_walls[ix][iy] = h_walls[idx]
				if h_walls_visible.size() == h_total:
					maze._h_visible[ix][iy] = h_walls_visible[idx]

	# Luôn đảm bảo tường biên ngoài là tường kín
	for iy in maze.height:
		maze._v_walls[0][iy] = 1
		maze._v_visible[0][iy] = 1
		maze._v_walls[maze.width][iy] = 1
		maze._v_visible[maze.width][iy] = 1

	for ix in maze.width:
		maze._h_walls[ix][0] = 1
		maze._h_visible[ix][0] = 1
		maze._h_walls[ix][maze.height] = 1
		maze._h_visible[ix][maze.height] = 1

	# Nạp hình dạng board (polyomino) - rỗng = chữ nhật đầy đủ
	# Hàm này tự ép tường bao quanh các ô ngoài board + tính lại số trên ô
	maze.set_cell_mask(cell_mask)
	return maze


## Tạo LevelData Resource từ MazeData hiện có
static func from_maze_data(
	maze: MazeData,
	p_id: int,
	p_title: String,
	p_steps: int = 15,
	p_mode: String = "play",
	p_diff: String = "medium"
) -> LevelData:
	var res := LevelData.new()
	res.level_id = p_id
	res.level_title = p_title
	res.width = maze.width
	res.height = maze.height
	res.start_pos = maze.get_start()
	res.end_pos = maze.get_end()
	res.max_steps = p_steps
	res.mode_id = p_mode
	res.difficulty = p_diff

	var v_bytes := PackedByteArray()
	var v_vis_bytes := PackedByteArray()
	for ix in maze.width + 1:
		for iy in maze.height:
			v_bytes.append(maze._v_walls[ix][iy])
			v_vis_bytes.append(maze._v_visible[ix][iy])
	res.v_walls = v_bytes
	res.v_walls_visible = v_vis_bytes

	var h_bytes := PackedByteArray()
	var h_vis_bytes := PackedByteArray()
	for ix in maze.width:
		for iy in maze.height + 1:
			h_bytes.append(maze._h_walls[ix][iy])
			h_vis_bytes.append(maze._h_visible[ix][iy])
	res.h_walls = h_bytes
	res.h_walls_visible = h_vis_bytes

	return res
