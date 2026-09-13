extends SceneTree
## ============================================================================
## Test Case: BOARD DẠNG POLYOMINO (cell_mask) - 2026-09
## - Nạp màn mẫu 10..13 (chữ H / thập tự / vòng có lỗ / chữ U) từ .tres.
## - Ô ngoài board: không đi được, không hiện số, không có cell node.
## - Số trên ô chỉ tính tường giữa 2 ô THUỘC BOARD.
## - Đường đi S->F phải tồn tại và đúng độ dài như tool tính.
## - Board thật: cell node chỉ có ở ô thuộc board, anchor chỉ ở góc dính board.
## ============================================================================

# level_id -> { shape, board_cells, path_length }
const SAMPLES := {
	10: {"name": "Chữ H", "board_cells": 10, "path_length": 5, "empty": [Vector2i(0, 1), Vector2i(3, 1)]},
	11: {"name": "Thập tự", "board_cells": 12, "path_length": 4, "empty": [Vector2i(0, 0), Vector2i(3, 3)]},
	12: {"name": "Vòng có lỗ", "board_cells": 32, "path_length": 14, "empty": [Vector2i(2, 2), Vector2i(3, 3)]},
	13: {"name": "Chữ U 2 ô", "board_cells": 20, "path_length": 10, "empty": [Vector2i(2, 1), Vector2i(3, 2)]},
}


func _init() -> void:
	print("\n========================================================")
	print("  TEST: BOARD DANG POLYOMINO (cell_mask)")
	print("========================================================\n")

	await process_frame
	root.size = Vector2i(1080, 1920)

	var lm: Node = root.get_node_or_null("LevelManager")
	var gm: Node = root.get_node_or_null("GameManager")
	assert(lm != null and gm != null, "Autoload LevelManager + GameManager phai ton tai")

	var backup_level := int(gm.get("current_level"))
	var backup_mode := str(gm.get("current_mode"))
	var failures := 0

	# --- 1. Dữ liệu màn mẫu ---
	for level_id in SAMPLES.keys():
		failures += _check_sample(lm, int(level_id), SAMPLES[level_id])

	# --- 2. Board thật (node) khi chơi màn chữ H ---
	failures += await _check_board_scene(gm, 10, SAMPLES[10])

	gm.set("current_level", backup_level)
	gm.set("current_mode", backup_mode)

	if failures > 0:
		print("\n[FAILED] %d loi o board polyomino.\n" % failures)
		quit(1)
		return

	print("\n[SUCCESS] Board polyomino hoat dong: mask, so tuong, duong di, cell node!\n")
	quit(0)


## Kiểm tra dữ liệu MazeData của 1 màn mẫu
func _check_sample(lm: Node, level_id: int, info: Dictionary) -> int:
	var level: LevelData = lm.call("load_level", level_id)
	if level == null:
		print("[FAIL] Khong nap duoc level_%d" % level_id)
		return 1

	var failures := 0
	var maze: MazeData = level.to_maze_data()
	var board_count := 0
	for y in maze.height:
		for x in maze.width:
			if maze.is_cell_active(Vector2i(x, y)):
				board_count += 1

	if board_count != int(info["board_cells"]):
		print("[FAIL] %s: so o thuoc board phai la %d (dang %d)"
			% [info["name"], info["board_cells"], board_count])
		failures += 1

	# Ô trống: không đi vào được + không hiện số
	for empty_cell in info["empty"]:
		var pos: Vector2i = empty_cell
		if maze.is_cell_active(pos):
			print("[FAIL] %s: o %s phai la o TRONG (ngoai board)" % [info["name"], str(pos)])
			failures += 1
		if maze.get_wall_count(pos) != 0:
			print("[FAIL] %s: o trong %s phai co so 0" % [info["name"], str(pos)])
			failures += 1

	# Đi vào ô trống phải bị chặn (coi như tường)
	var blocked_ok := true
	for y in maze.height:
		for x in maze.width:
			var pos := Vector2i(x, y)
			if maze.is_cell_active(pos):
				continue
			for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var other := pos + step
				if maze.is_cell_active(other) and not maze.has_wall(other, pos):
					blocked_ok = false
	if not blocked_ok:
		print("[FAIL] %s: co the di tu o board vao o trong" % info["name"])
		failures += 1

	# Đường đi S->F: phải tồn tại + đúng độ dài tool đã tính
	var path := maze.get_shortest_path(maze.get_start(), maze.get_end())
	if path.is_empty():
		print("[FAIL] %s: KHONG co duong di tu S den F" % info["name"])
		failures += 1
	elif path.size() - 1 != int(info["path_length"]):
		print("[FAIL] %s: duong ngan nhat phai %d buoc (dang %d)"
			% [info["name"], info["path_length"], path.size() - 1])
		failures += 1

	# Số trên ô: chỉ tính tường giữa 2 ô thuộc board
	var count_ok := true
	for y in maze.height:
		for x in maze.width:
			var pos := Vector2i(x, y)
			if not maze.is_cell_active(pos):
				continue
			var expected := 0
			var probes := [
				[Vector2i(x, y - 1), maze.has_h_wall(x, y)],
				[Vector2i(x, y + 1), maze.has_h_wall(x, y + 1)],
				[Vector2i(x - 1, y), maze.has_v_wall(x, y)],
				[Vector2i(x + 1, y), maze.has_v_wall(x + 1, y)],
			]
			for probe in probes:
				var neighbour: Vector2i = probe[0]
				if maze.is_cell_active(neighbour) and bool(probe[1]):
					expected += 1
			if maze.get_wall_count(pos) != expected:
				count_ok = false
	if not count_ok:
		print("[FAIL] %s: so tuong tren o khong khop quy uoc" % info["name"])
		failures += 1

	if failures == 0:
		print("[CHECK] %s (level %d): %d o board, duong ngan nhat %d buoc, so tuong dung."
			% [info["name"], level_id, board_count, path.size() - 1])
	return failures


## Kiểm tra board node khi vào game thật với màn chữ H
func _check_board_scene(gm: Node, level_id: int, info: Dictionary) -> int:
	gm.set("current_mode", "play")
	gm.set("current_level", level_id)

	var game_scene: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game_scene)
	await process_frame
	await process_frame

	var failures := 0
	var board: Node = game_scene.get("board_view")
	var controller: GameController = game_scene.get("game_controller")
	var maze: MazeData = board.get("maze")

	if maze == null or not board.get("_width") == maze.width:
		print("[FAIL] Board chua nap duoc maze cua level %d" % level_id)
		game_scene.queue_free()
		return 1

	# 1. Cell node: chỉ có ở ô thuộc board
	var cell_nodes: Array = board.get("_cell_nodes")
	var node_count := 0
	for node in cell_nodes:
		if node != null:
			node_count += 1
	if node_count != int(info["board_cells"]):
		print("[FAIL] So cell node phai la %d (dang %d)" % [info["board_cells"], node_count])
		failures += 1

	var width: int = int(board.get("_width"))
	for cell in info["empty"]:
		var pos: Vector2i = cell
		var idx := pos.x + pos.y * width
		if idx < cell_nodes.size() and cell_nodes[idx] != null:
			print("[FAIL] O trong %s khong duoc co cell node" % str(pos))
			failures += 1

	# 2. Anchor: chỉ ở góc dính ít nhất 1 ô thuộc board
	for anchor_info in board.get("_anchor_nodes"):
		var corner: Vector2i = anchor_info["corner"]
		var touches := false
		for dy in [-1, 0]:
			for dx in [-1, 0]:
				if maze.is_cell_active(Vector2i(corner.x + dx, corner.y + dy)):
					touches = true
		if not touches:
			print("[FAIL] Anchor o goc %s khong dinh o nao thuoc board" % str(corner))
			failures += 1

	# 3. Di chuyển vào ô trống: không đổi vị trí, không hazard
	var grid: Node = game_scene.get("grid_controller")
	var empty_cell: Vector2i = info["empty"][0]
	var approach := _find_approach_cell(maze, empty_cell)
	grid.set("current_pos", approach)
	grid.call("try_move_to", empty_cell)
	var after := Vector2i(grid.get("current_pos"))
	if after != approach:
		print("[FAIL] Di vao o trong %s khong duoc phep (vi tri %s -> %s)"
			% [str(empty_cell), str(approach), str(after)])
		failures += 1

	# 4. Đường đi ngắn nhất của game khớp tool
	var path := maze.get_shortest_path(maze.get_start(), maze.get_end())
	if path.size() - 1 != int(info["path_length"]):
		print("[FAIL] Game tinh duong ngan nhat %d buoc (tool tinh %d)"
			% [path.size() - 1, info["path_length"]])
		failures += 1

	if failures == 0:
		print("[CHECK] Board scene: %d cell node (khong co o trong), anchor dung, chan di vao o trong."
			% node_count)

	game_scene.queue_free()
	await process_frame
	return failures


## Tìm ô thuộc board kề cạnh ô trống để thử đi vào ô trống đó
func _find_approach_cell(maze: MazeData, empty_cell: Vector2i) -> Vector2i:
	for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var candidate := empty_cell + step
		if maze.is_cell_active(candidate):
			return candidate
	return maze.get_start()
