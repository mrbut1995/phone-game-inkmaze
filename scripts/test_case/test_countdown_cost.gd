extends SceneTree
## ============================================================================
## Test Case: Countdown Cost (update 2026-09)
## - Số trên ô = CHI PHÍ bước, KHÔNG liên quan tới số tường quanh ô.
## - Mọi ô (trừ S/F) đều có chi phí >= 1 và nằm trong khoảng của độ khó.
## - get_step_cost(ô đích) == số hiển thị trên ô đó.
## - Ngân sách bước >= chi phí đường đi RẺ NHẤT + dự phòng => luôn thắng được.
## ============================================================================


func _init() -> void:
	print("\n========================================================")
	print("  TEST: COUNTDOWN COST (so tren o = chi phi buoc)")
	print("========================================================\n")

	await process_frame

	var failures := 0
	failures += _test_difficulty("easy")
	failures += _test_difficulty("medium")
	failures += _test_difficulty("hard")
	failures += _test_not_related_to_walls()

	if failures > 0:
		print("\n[FAILED] %d truong hop sai o Countdown Cost.\n" % failures)
		quit(1)
		return

	print("\n[SUCCESS] Countdown Cost: so tren o la chi phi, khong lien quan tuong!\n")
	quit(0)


func _test_difficulty(difficulty: String) -> int:
	var mode := CountdownCostGameMode.new(difficulty)
	var failures := 0
	# Chạy 5 màn ngẫu nhiên cho mỗi độ khó
	for _attempt in 5:
		var maze := mode.setup_floor(1)
		var cost_range: Vector2i = mode.COST_RANGE[difficulty]

		# 1. Mọi ô trừ S/F đều có chi phí trong khoảng của độ khó
		for y in maze.height:
			for x in maze.width:
				var pos := Vector2i(x, y)
				if pos == maze.get_start() or pos == maze.get_end():
					continue
				var cost := mode.get_cell_cost(pos)
				if cost < cost_range.x or cost > cost_range.y:
					print("[FAIL] %s: o %s co chi phi %d ngoai khoang %d..%d"
						% [difficulty, str(pos), cost, cost_range.x, cost_range.y])
					failures += 1
				if mode.get_cell_text(pos, maze) != str(cost):
					print("[FAIL] %s: so hien tren o %s ('%s') khac chi phi (%d)"
						% [difficulty, str(pos), mode.get_cell_text(pos, maze), cost])
					failures += 1
				if mode.get_step_cost(maze.get_start(), pos, maze) != cost:
					print("[FAIL] %s: get_step_cost(%s) khac chi phi hien thi" % [difficulty, str(pos)])
					failures += 1

		# 2. S/F không phải số chi phí
		if mode.get_cell_text(maze.get_start(), maze) != "S":
			print("[FAIL] %s: o xuat phat phai hien 'S'" % difficulty)
			failures += 1
		if mode.get_cell_text(maze.get_end(), maze) != "F":
			print("[FAIL] %s: o dich phai hien 'F'" % difficulty)
			failures += 1

		# 3. Màn phải đi được và ngân sách đủ cho đường rẻ nhất + dự phòng
		if not maze.is_solvable():
			print("[FAIL] %s: man khong co duong di" % difficulty)
			failures += 1
		var cheapest: int = mode.cheapest_path_cost(maze)
		var slack: int = mode.BUDGET_SLACK[difficulty]
		if mode.initial_steps < cheapest + slack:
			print("[FAIL] %s: ngan sach %d < duong re nhat %d + du phong %d"
				% [difficulty, mode.initial_steps, cheapest, slack])
			failures += 1
		if mode.initial_steps < mode.BUDGET_FLOOR[difficulty]:
			print("[FAIL] %s: ngan sach %d nho hon muc toi thieu %d"
				% [difficulty, mode.initial_steps, mode.BUDGET_FLOOR[difficulty]])
			failures += 1

		# 4. Bước vào F tốn chi phí (nếu F nằm trong bảng chi phí thì phải = 0)
		if mode.get_cell_cost(maze.get_end()) != 0:
			print("[FAIL] %s: o dich F khong duoc tinh chi phi" % difficulty)
			failures += 1

	if failures == 0:
		print("[CHECK] %s: chi phi trong khoang %d..%d, ngan sach du cho duong re nhat."
			% [difficulty, mode.COST_RANGE[difficulty].x, mode.COST_RANGE[difficulty].y])
	return failures


## Số trên ô KHÔNG còn là số tường quanh ô
func _test_not_related_to_walls() -> int:
	var mode := CountdownCostGameMode.new("medium")
	var maze := mode.setup_floor(1)

	var failures := 0
	var different := 0
	var total := 0
	for y in maze.height:
		for x in maze.width:
			var pos := Vector2i(x, y)
			if pos == maze.get_start() or pos == maze.get_end():
				continue
			total += 1
			if mode.get_cell_cost(pos) != maze.get_wall_count(pos):
				different += 1

	if different < 3:
		print("[FAIL] Chi phi gan nhu trung so tuong (%d/%d o khac nhau) -> chua tach roi"
			% [different, total])
		failures += 1

	# Ô sát viền: trước đây luôn >= 1 vì tường viền, giờ phải theo chi phí sinh ra
	var border_cell := Vector2i(0, 0)
	if border_cell == maze.get_start() or border_cell == maze.get_end():
		border_cell = Vector2i(1, 0)
	var cost := mode.get_cell_cost(border_cell)
	var range_medium: Vector2i = mode.COST_RANGE["medium"]
	if cost < range_medium.x or cost > range_medium.y:
		print("[FAIL] O sat vien %s co chi phi %d khong theo bang chi phi"
			% [str(border_cell), cost])
		failures += 1

	if failures == 0:
		print("[CHECK] Chi phi doc lap voi tuong: %d/%d o co so khac so tuong." % [different, total])
	return failures
