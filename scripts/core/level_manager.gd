class_name LevelManagerClass
extends Node
## ============================================================================
## Manager: Quản lý nạp, lưu trữ và cung cấp LevelData Resource
## Thay vì sinh ngẫu nhiên, các màn chơi sẽ được tải từ file Resource (.tres).
## ============================================================================

const LEVELS_DIR := "res://resources/levels/"
const TOTAL_CHAPTER1_LEVELS := 9
## Quét tối đa tới id này khi dò danh sách màn (đủ rộng cho nhiều chương)
const MAX_LEVEL_ID := 999
## Dừng quét khi gặp bao nhiêu id liên tiếp không có file (chịu được vài khoảng trống)
const SCAN_MISS_LIMIT := 3

var _cache: Dictionary = {}
var _levels_dir := LEVELS_DIR
var _id_cache: Array[int] = []
var _ids_ready := false


func _ready() -> void:
	ensure_default_levels()


# ---------------------------------------------------------------------------
# Danh sách màn (dùng cho màn Chọn Màn để phân trang khi > 9 màn)
# ---------------------------------------------------------------------------
func get_levels_dir() -> String:
	return _levels_dir


## Đổi thư mục chứa level (dùng cho test) - nhớ gọi refresh_levels() sau đó
func set_levels_dir(dir_path: String) -> void:
	_levels_dir = dir_path if dir_path.ends_with("/") else dir_path + "/"
	refresh_levels()


## Xoá cache danh sách màn + cache dữ liệu màn -> lần gọi kế tiếp sẽ tự dò lại.
## (Phải xoá cả `_cache` vì dữ liệu trong đó thuộc thư mục CŨ — lẫn `chapter`,
##  nếu không màn Chọn màn sẽ gom màn sai chương sau khi đổi thư mục level.)
func refresh_levels() -> void:
	_id_cache.clear()
	_ids_ready = false
	_cache.clear()


## Danh sách level_id có file .tres thật, tăng dần (bỏ qua id trống)
func get_level_ids() -> Array[int]:
	if not _ids_ready:
		_refresh_level_ids()
	return _id_cache.duplicate()


func get_level_count() -> int:
	return get_level_ids().size()


func _refresh_level_ids() -> void:
	_id_cache.clear()
	var level_id := 1
	var misses := 0
	while level_id <= MAX_LEVEL_ID and misses < SCAN_MISS_LIMIT:
		if has_level(level_id):
			_id_cache.append(level_id)
			misses = 0
		else:
			misses += 1
		level_id += 1
	_ids_ready = true


## Lấy đường dẫn file resource của level
func get_level_path(level_id: int) -> String:
	return "%slevel_%d.tres" % [_levels_dir, level_id]


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

	_ensure_directory(_levels_dir)
	var path := get_level_path(data.level_id)
	var err := ResourceSaver.save(data, path)
	if err == OK:
		_cache[data.level_id] = data
		refresh_levels()
	return err


# ---------------------------------------------------------------------------
# CHƯƠNG (màn "CHỌN CHƯƠNG" — mockup/chapter_selection.svg)
# Chương gom các màn theo `LevelData.chapter`; file hiển thị/điều kiện sao nằm ở
# resources/chapters/chapter_<id>.tres (ChapterData).
# ---------------------------------------------------------------------------
const CHAPTERS_DIR := "res://resources/chapters/"
const MAX_CHAPTER_ID := 99

var _chapters_dir := CHAPTERS_DIR
var _chapter_cache: Dictionary = {}


func get_chapters_dir() -> String:
	return _chapters_dir


## Đổi thư mục chứa chapter (dùng cho test)
func set_chapters_dir(dir_path: String) -> void:
	_chapters_dir = dir_path if dir_path.ends_with("/") else dir_path + "/"
	refresh_chapters()


func refresh_chapters() -> void:
	_chapter_cache.clear()


func chapter_path(chapter_id: int) -> String:
	return "%schapter_%d.tres" % [_chapters_dir, chapter_id]


func has_chapter(chapter_id: int) -> bool:
	return ResourceLoader.exists(chapter_path(chapter_id))


## Danh sách chương có file .tres thật, tăng dần theo chapter_id
func get_chapters() -> Array[ChapterData]:
	var out: Array[ChapterData] = []
	for chapter_id in range(1, MAX_CHAPTER_ID + 1):
		var data := get_chapter(chapter_id)
		if data != null:
			out.append(data)
	return out


func get_chapter(chapter_id: int) -> ChapterData:
	if _chapter_cache.has(chapter_id):
		return _chapter_cache[chapter_id]
	var path := chapter_path(chapter_id)
	if not ResourceLoader.exists(path):
		return null
	var res := ResourceLoader.load(path)
	if res is ChapterData:
		_chapter_cache[chapter_id] = res
		return res
	return null


func chapter_count() -> int:
	return get_chapters().size()


## Chương chứa màn này (LevelData.chapter)
func chapter_of_level(level_id: int) -> int:
	var data := load_level(level_id)
	return maxi(data.chapter, 1) if data != null else 1


## Danh sách màn của 1 chương (theo thứ tự tăng dần)
func levels_in_chapter(chapter_id: int) -> Array[int]:
	var out: Array[int] = []
	for level_id in get_level_ids():
		if chapter_of_level(level_id) == chapter_id:
			out.append(level_id)
	return out


## Tổng số Sao tối đa của chương (= số màn x 3)
func chapter_star_total(chapter_id: int) -> int:
	return levels_in_chapter(chapter_id).size() * 3


## Số màn đã hoàn thành của chương (>= 1 Sao)
func chapter_cleared_count(chapter_id: int) -> int:
	var stars := _level_stars()
	var count := 0
	for level_id in levels_in_chapter(chapter_id):
		if int(stars.get(level_id, 0)) > 0:
			count += 1
	return count


## Số Sao đã đạt TRONG chương này
func chapter_stars(chapter_id: int) -> int:
	var stars := _level_stars()
	var total := 0
	for level_id in levels_in_chapter(chapter_id):
		total += int(stars.get(level_id, 0))
	return total


## Chương đang chứa màn chơi hiện tại (GameManager.current_level)
func current_chapter_id() -> int:
	var gm := get_node_or_null("/root/GameManager")
	if gm == null:
		return 1
	return chapter_of_level(maxi(int(gm.get("current_level")), 1))


func _level_stars() -> Dictionary:
	var gm := get_node_or_null("/root/GameManager")
	var stars: Variant = gm.get("level_stars") if gm != null else null
	return stars if stars is Dictionary else {}


## Đảm bảo toàn bộ 9 màn chơi của Chương 1 đã có sẵn file Resource .tres
func ensure_default_levels() -> void:
	_ensure_directory(_levels_dir)
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
