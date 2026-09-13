extends SceneTree
## ============================================================================
## Test Case: Quy ước "SỐ TƯỜNG TRONG Ô" (update 2026-09)
## - Tường VIỀN NGOÀI bao quanh board KHÔNG được tính vào ô.
## - Viền vẫn là tường: chặn đường đi + luôn hiển thị.
## - Tường BÊN TRONG (kể cả tường ẩn/vô hình) vẫn được tính như cũ.
## - Ô có số 0 thì get_cell_text() trả về chuỗi rỗng (không hiện số).
## ============================================================================


func _init() -> void:
	print("\n========================================================")
	print("  TEST: WALL COUNT RULE (bo tuong vien ngoai board)")
	print("========================================================\n")

	await process_frame

	var failures := 0
	failures += _test_empty_maze()
	failures += _test_interior_walls()
	failures += _test_level_data_path()
	failures += _test_cell_text()

	if failures > 0:
		print("\n[FAILED] %d truong hop sai quy uoc so tuong.\n" % failures)
		quit(1)
		return

	print("\n[SUCCESS] So tuong trong o da dung quy uoc moi!\n")
	quit(0)


## Màn trống: mọi ô phải là 0 dù ô nào cũng sát viền
func _test_empty_maze() -> int:
	var maze := MazeData.new()
	maze.create_empty(4, 4)

	var failures := 0
	for y in maze.height:
		for x in maze.width:
			var pos := Vector2i(x, y)
			var count := maze.get_wall_count(pos)
			if count != 0:
				print("[FAIL] Man trong: o %s phai la 0 (dang %d)" % [str(pos), count])
				failures += 1

	# Viền vẫn chặn đường đi
	if not maze.has_wall(Vector2i(0, 0), Vector2i(-1, 0)):
		print("[FAIL] Di ra ngoai board ben trai phai bi chan")
		failures += 1
	if not maze.has_wall(Vector2i(0, 0), Vector2i(0, -1)):
		print("[FAIL] Di ra ngoai board phia tren phai bi chan")
		failures += 1
	if maze.has_wall(Vector2i(0, 0), Vector2i(1, 0)):
		print("[FAIL] O lien ke trong board phai di duoc")
		failures += 1

	if failures == 0:
		print("[CHECK] Man trong 4x4: moi o = 0, vien van chan duong.")
	return failures


## Tường bên trong (hiện + ẩn) vẫn được tính
func _test_interior_walls() -> int:
	var maze := MazeData.new()
	maze.create_empty(4, 4)
	maze.set_v_wall(2, 2, true)   # dọc, giữa ô (1,2) và (2,2)
	maze.set_h_wall(1, 2, true)   # ngang, phía trên ô (1,2)

	var failures := 0
	var cases := [
		[Vector2i(1, 2), 2, "o (1,2) ke tuong phai + tuong tren"],
		[Vector2i(2, 2), 1, "o (2,2) chi ke tuong trai"],
		[Vector2i(1, 1), 1, "o (1,1) ke tuong duoi (h[1][2])"],
		[Vector2i(3, 3), 0, "o goc (3,3) chi co vien -> 0"],
		[Vector2i(0, 0), 0, "o goc (0,0) chi co vien -> 0"],
	]
	for item in cases:
		var pos: Vector2i = item[0]
		var expected: int = item[1]
		var actual := maze.get_wall_count(pos)
		if actual != expected:
			print("[FAIL] %s: mong %d, dang %d" % [item[2], expected, actual])
			failures += 1

	# Tường ẩn cũng phải được tính (ẩn/hiện không đổi số)
	maze.set_v_wall(1, 0, true)
	maze._v_visible[1][0] = 0
	if maze.get_wall_count(Vector2i(0, 0)) != 1:
		print("[FAIL] Tuong AN ben phai o (0,0) phai duoc tinh (dang %d)"
			% maze.get_wall_count(Vector2i(0, 0)))
		failures += 1

	if failures == 0:
		print("[CHECK] Tuong ben trong (ke ca tuong an) van duoc tinh dung.")
	return failures


## Đi qua đường LevelData -> MazeData cũng phải theo quy ước mới
func _test_level_data_path() -> int:
	var data := LevelData.new()
	data.width = 3
	data.height = 3
	data.start_pos = Vector2i(0, 2)
	data.end_pos = Vector2i(2, 0)

	# Lưới 3x3: chỉ có viền là tường, thêm 1 tường ngang bên trong h(1,2)
	var v := PackedByteArray()
	v.resize(12)
	v.fill(0)
	v[0 * 3 + 0] = 1
	v[0 * 3 + 1] = 1
	v[0 * 3 + 2] = 1
	v[3 * 3 + 0] = 1
	v[3 * 3 + 1] = 1
	v[3 * 3 + 2] = 1
	var h := PackedByteArray()
	h.resize(12)
	h.fill(0)
	for ix in 3:
		h[ix * 4 + 0] = 1
		h[ix * 4 + 3] = 1
	h[1 * 4 + 2] = 1
	data.v_walls = v
	data.v_walls_visible = v
	data.h_walls = h
	data.h_walls_visible = h

	var maze: MazeData = data.to_maze_data()
	var failures := 0
	var cases := [
		[Vector2i(1, 1), 1, "o (1,1) ke tuong trong h(1,2)"],
		[Vector2i(1, 2), 1, "o (1,2) ke tuong trong h(1,2)"],
		[Vector2i(0, 0), 0, "o goc (0,0) chi co vien -> 0"],
		[Vector2i(2, 2), 0, "o goc (2,2) chi co vien -> 0"],
	]
	for item in cases:
		var pos: Vector2i = item[0]
		var expected: int = item[1]
		var actual := maze.get_wall_count(pos)
		if actual != expected:
			print("[FAIL] LevelData 3x3 · %s: mong %d, dang %d" % [item[2], expected, actual])
			failures += 1

	# Viền ngoài vẫn kín (LevelData.to_maze_data luôn ép viền)
	if not maze.has_wall(Vector2i(0, 0), Vector2i(0, -1)):
		print("[FAIL] Vien ngoai phai luon la tuong")
		failures += 1

	if failures == 0:
		print("[CHECK] LevelData 3x3 -> MazeData: chi tuong trong duoc tinh.")
	return failures


## Ô có số 0 thì không hiện số (đúng như game đang làm)
func _test_cell_text() -> int:
	var maze := MazeData.new()
	maze.create_empty(3, 3)
	maze.set_v_wall(1, 1, true)

	var mode := StandardGameMode.new()
	var failures := 0
	var empty_text := mode.get_cell_text(Vector2i(1, 0), maze)   # chi co vien -> 0
	if empty_text != "":
		print("[FAIL] O 0 tuong phai hien chuoi rong (dang '%s')" % empty_text)
		failures += 1
	var wall_text := mode.get_cell_text(Vector2i(0, 1), maze)    # kề tường trong -> '1'
	if wall_text != "1":
		print("[FAIL] O ke 1 tuong trong phai hien '1' (dang '%s')" % wall_text)
		failures += 1
	if mode.get_cell_text(maze.get_start(), maze) != "S":
		print("[FAIL] O xuat phat phai hien 'S'")
		failures += 1
	if mode.get_cell_text(maze.get_end(), maze) != "F":
		print("[FAIL] O dich phai hien 'F'")
		failures += 1

	if failures == 0:
		print("[CHECK] get_cell_text: o 0 khong hien so, o ke tuong trong hien dung.")
	return failures
