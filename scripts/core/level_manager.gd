class_name LevelManagerClass
extends Node
## ============================================================================
## Manager: Quản lý nạp, lưu trữ và cung cấp LevelData Resource
## Thay vì sinh ngẫu nhiên, các màn chơi sẽ được tải từ file Resource (.tres).
## ============================================================================

const LEVELS_DIR := "res://resources/levels/"
const TOTAL_CHAPTER1_LEVELS := 9

var _cache: Dictionary = {}


func _ready() -> void:
	ensure_default_levels()


## Lấy đường dẫn file resource của level
func get_level_path(level_id: int) -> String:
	return "%slevel_%d.tres" % [LEVELS_DIR, level_id]


## Kiểm tra màn chơi có tồn tại file Resource hay không
func has_level(level_id: int) -> bool:
	var path := get_level_path(level_id)
	return ResourceLoader.exists(path)


## Nạp dữ liệu màn chơi từ Resource .tres
func load_level(level_id: int) -> LevelData:
	if _cache.has(level_id):
		return _cache[level_id]

	var path := get_level_path(level_id)
	if ResourceLoader.exists(path):
		var res := ResourceLoader.load(path)
		if res is LevelData:
			_cache[level_id] = res
			return res

	# Nếu chưa tồn tại, tạo tự động và lưu lại
	var new_level := _create_crafted_level(level_id)
	save_level(new_level)
	_cache[level_id] = new_level
	return new_level


## Lưu màn chơi xuống file Resource .tres
func save_level(data: LevelData) -> Error:
	if data == null:
		return ERR_INVALID_DATA

	_ensure_directory(LEVELS_DIR)
	var path := get_level_path(data.level_id)
	var err := ResourceSaver.save(data, path)
	if err == OK:
		_cache[data.level_id] = data
	return err


## Đảm bảo toàn bộ 9 màn chơi của Chương 1 đã có sẵn file Resource .tres
func ensure_default_levels() -> void:
	_ensure_directory(LEVELS_DIR)
	for id in range(1, TOTAL_CHAPTER1_LEVELS + 1):
		if not has_level(id):
			var lvl := _create_crafted_level(id)
			save_level(lvl)


func _ensure_directory(dir_path: String) -> void:
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)


## Thiết kế thủ công từng màn chơi chuẩn mực từ Level 1 đến Level 9
func _create_crafted_level(level_id: int) -> LevelData:
	var lvl := LevelData.new()
	lvl.level_id = level_id
	lvl.chapter = 1
	lvl.mode_id = "play"

	match level_id:
		1:
			lvl.level_title = "Level 1-1 · Bước Khởi Đầu"
			lvl.difficulty = "easy"
			lvl.width = 2
			lvl.height = 2
			lvl.start_pos = Vector2i(0, 1)
			lvl.end_pos = Vector2i(1, 0)
			lvl.max_steps = 8
			lvl.par_time = 20.0
			_setup_level_walls(lvl, [
				{"is_h": true, "x": 0, "y": 1, "vis": true}
			])
		2:
			lvl.level_title = "Level 1-2 · Bức Tường Ẩn"
			lvl.difficulty = "easy"
			lvl.width = 2
			lvl.height = 2
			lvl.start_pos = Vector2i(0, 1)
			lvl.end_pos = Vector2i(1, 0)
			lvl.max_steps = 10
			lvl.par_time = 25.0
			_setup_level_walls(lvl, [
				{"is_h": false, "x": 1, "y": 1, "vis": false}
			])
		3:
			lvl.level_title = "Level 1-3 · Mê Cung 3x3"
			lvl.difficulty = "easy"
			lvl.width = 3
			lvl.height = 3
			lvl.start_pos = Vector2i(0, 2)
			lvl.end_pos = Vector2i(2, 0)
			lvl.max_steps = 14
			lvl.par_time = 35.0
			_setup_level_walls(lvl, [
				{"is_h": true, "x": 0, "y": 1, "vis": true},
				{"is_h": true, "x": 1, "y": 2, "vis": true},
				{"is_h": false, "x": 1, "y": 0, "vis": false}
			])
		4:
			lvl.level_title = "Level 1-4 · Lối Rẽ Vô Hình"
			lvl.difficulty = "medium"
			lvl.width = 3
			lvl.height = 3
			lvl.start_pos = Vector2i(0, 2)
			lvl.end_pos = Vector2i(2, 0)
			lvl.max_steps = 15
			lvl.par_time = 40.0
			_setup_level_walls(lvl, [
				{"is_h": true, "x": 1, "y": 1, "vis": true},
				{"is_h": false, "x": 1, "y": 1, "vis": false},
				{"is_h": false, "x": 2, "y": 2, "vis": false}
			])
		5:
			lvl.level_title = "Level 1-5 · Đường Vòng Hiểm"
			lvl.difficulty = "medium"
			lvl.width = 3
			lvl.height = 3
			lvl.start_pos = Vector2i(0, 2)
			lvl.end_pos = Vector2i(2, 0)
			lvl.max_steps = 16
			lvl.par_time = 45.0
			_setup_level_walls(lvl, [
				{"is_h": true, "x": 0, "y": 1, "vis": false},
				{"is_h": true, "x": 1, "y": 2, "vis": false},
				{"is_h": false, "x": 2, "y": 1, "vis": true},
				{"is_h": false, "x": 1, "y": 2, "vis": false}
			])
		6:
			lvl.level_title = "Level 1-6 · Mở Rộng 4x4"
			lvl.difficulty = "medium"
			lvl.width = 4
			lvl.height = 4
			lvl.start_pos = Vector2i(0, 3)
			lvl.end_pos = Vector2i(3, 0)
			lvl.max_steps = 20
			lvl.par_time = 50.0
			_setup_level_walls(lvl, [
				{"is_h": true, "x": 0, "y": 2, "vis": true},
				{"is_h": true, "x": 1, "y": 1, "vis": true},
				{"is_h": false, "x": 1, "y": 2, "vis": false},
				{"is_h": false, "x": 2, "y": 1, "vis": false},
				{"is_h": true, "x": 2, "y": 3, "vis": true}
			])
		7:
			lvl.level_title = "Level 1-7 · Ngõ Cụt Nguy Cấp"
			lvl.difficulty = "hard"
			lvl.width = 4
			lvl.height = 4
			lvl.start_pos = Vector2i(0, 3)
			lvl.end_pos = Vector2i(3, 0)
			lvl.max_steps = 22
			lvl.par_time = 55.0
			_setup_level_walls(lvl, [
				{"is_h": true, "x": 0, "y": 1, "vis": false},
				{"is_h": true, "x": 1, "y": 2, "vis": true},
				{"is_h": false, "x": 2, "y": 2, "vis": false},
				{"is_h": false, "x": 2, "y": 3, "vis": false},
				{"is_h": true, "x": 2, "y": 1, "vis": false},
				{"is_h": false, "x": 3, "y": 2, "vis": true}
			])
		8:
			lvl.level_title = "Level 1-8 · Bóng Đêm Mực Nước"
			lvl.difficulty = "hard"
			lvl.width = 4
			lvl.height = 4
			lvl.start_pos = Vector2i(0, 3)
			lvl.end_pos = Vector2i(3, 0)
			lvl.max_steps = 24
			lvl.par_time = 60.0
			_setup_level_walls(lvl, [
				{"is_h": true, "x": 1, "y": 1, "vis": false},
				{"is_h": true, "x": 2, "y": 2, "vis": false},
				{"is_h": true, "x": 3, "y": 1, "vis": false},
				{"is_h": false, "x": 1, "y": 3, "vis": false},
				{"is_h": false, "x": 2, "y": 1, "vis": true},
				{"is_h": false, "x": 3, "y": 2, "vis": false}
			])
		9:
			lvl.level_title = "Level 1-9 · Bậc Thầy Mê Cung (5x5)"
			lvl.difficulty = "hard"
			lvl.width = 5
			lvl.height = 5
			lvl.start_pos = Vector2i(0, 4)
			lvl.end_pos = Vector2i(4, 0)
			lvl.max_steps = 30
			lvl.par_time = 75.0
			_setup_level_walls(lvl, [
				{"is_h": true, "x": 0, "y": 2, "vis": true},
				{"is_h": true, "x": 1, "y": 3, "vis": false},
				{"is_h": true, "x": 2, "y": 2, "vis": false},
				{"is_h": true, "x": 3, "y": 4, "vis": true},
				{"is_h": true, "x": 4, "y": 1, "vis": false},
				{"is_h": false, "x": 1, "y": 1, "vis": false},
				{"is_h": false, "x": 2, "y": 3, "vis": false},
				{"is_h": false, "x": 3, "y": 2, "vis": false},
				{"is_h": false, "x": 4, "y": 3, "vis": false},
				{"is_h": false, "x": 2, "y": 0, "vis": true}
			])
		_:
			lvl.level_title = "Level %d" % level_id
			lvl.width = 3
			lvl.height = 3
			lvl.start_pos = Vector2i(0, 2)
			lvl.end_pos = Vector2i(2, 0)
			lvl.max_steps = 15
			_setup_level_walls(lvl, [])

	return lvl


## Khởi tạo mảng bytes tường dọc và ngang theo danh sách cấu hình
func _setup_level_walls(lvl: LevelData, walls: Array) -> void:
	var w := lvl.width
	var h := lvl.height

	var v_bytes := PackedByteArray()
	var v_vis := PackedByteArray()
	v_bytes.resize((w + 1) * h)
	v_bytes.fill(0)
	v_vis.resize((w + 1) * h)
	v_vis.fill(0)

	# Biên trái & phải là tường nhìn thấy
	for iy in h:
		v_bytes[0 * h + iy] = 1
		v_vis[0 * h + iy] = 1
		v_bytes[w * h + iy] = 1
		v_vis[w * h + iy] = 1

	var h_bytes := PackedByteArray()
	var h_vis := PackedByteArray()
	h_bytes.resize(w * (h + 1))
	h_bytes.fill(0)
	h_vis.resize(w * (h + 1))
	h_vis.fill(0)

	# Biên trên & dưới là tường nhìn thấy
	for ix in w:
		h_bytes[ix * (h + 1) + 0] = 1
		h_vis[ix * (h + 1) + 0] = 1
		h_bytes[ix * (h + 1) + h] = 1
		h_vis[ix * (h + 1) + h] = 1

	# Thiết lập các bức tường cụ thể
	for entry: Dictionary in walls:
		var is_h: bool = entry.get("is_h", false)
		var x: int = entry.get("x", 0)
		var y: int = entry.get("y", 0)
		var vis: bool = entry.get("vis", false)

		if is_h:
			if x >= 0 and x < w and y >= 0 and y <= h:
				var idx := x * (h + 1) + y
				h_bytes[idx] = 1
				h_vis[idx] = 1 if vis else 0
		else:
			if x >= 0 and x <= w and y >= 0 and y < h:
				var idx := x * h + y
				v_bytes[idx] = 1
				v_vis[idx] = 1 if vis else 0

	lvl.v_walls = v_bytes
	lvl.v_walls_visible = v_vis
	lvl.h_walls = h_bytes
	lvl.h_walls_visible = h_vis
