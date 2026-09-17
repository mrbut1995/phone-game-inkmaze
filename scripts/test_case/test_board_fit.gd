extends SceneTree
## ============================================================================
## Test Case: BOARD TỰ CO CHO VỪA KHUNG (bug 2026-09: lưới > 5 ô bị tràn ra ngoài)
## - Board nhỏ (<= 5x5) giữ nguyên cỡ ô gốc (không đổi gì so với trước).
## - Board lớn (8x8, 11x11, 15x15, 20x20) phải co lại nằm GỌN trong khung giấy.
## - Cỡ chữ số trên ô + chữ phụ SẮP PHAI/CẠN + bề rộng tường + anchor + cursor đều co theo.
## - Màn mẫu 11x11 (level_14) khi vào game thật cũng phải vừa khung.
## ============================================================================

const SIZES := [3, 5, 8, 11, 15, 20]
const SAMPLE_LEVEL := 14      # Level 2-5 · Bàn cờ lớn 11x11


func _init() -> void:
	print("\n========================================================")
	print("  TEST: BOARD TU CO CHO VUA KHUNG (3x3 -> 20x20)")
	print("========================================================\n")

	await process_frame
	root.size = Vector2i(1080, 1920)

	var failures := 0
	failures += await _check_sample_level()
	failures += await _check_generated_sizes()

	if failures > 0:
		print("\n[FAILED] %d loi ve co board.\n" % failures)
		quit(1)
		return

	print("\n[SUCCESS] Board tu co vua khung o moi co luoi (3x3 -> 20x20)!\n")
	quit(0)


## Màn 11x11 của game thật: mở scenes/game.tscn với level_14
func _check_sample_level() -> int:
	var gm: Node = root.get_node_or_null("GameManager")
	if gm == null:
		print("[FAIL] Khong co GameManager")
		return 1

	var backup_level := int(gm.get("current_level"))
	var backup_mode := str(gm.get("current_mode"))
	gm.set("current_mode", "play")
	gm.set("current_level", SAMPLE_LEVEL)

	var scene: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var board: Node = scene.get("board_view")
	var failures := 0
	if board == null or int(board.get("_width")) != 11:
		print("[FAIL] Khong mo duoc man %d (board 11x11)" % SAMPLE_LEVEL)
		failures += 1
	else:
		failures += _check_fit(board, 11, "level_%d (man mau 11x11)" % SAMPLE_LEVEL)

	scene.queue_free()
	await process_frame
	gm.set("current_level", backup_level)
	gm.set("current_mode", backup_mode)
	return failures


## Sinh maze các cỡ khác nhau rồi nạp trực tiếp vào board
func _check_generated_sizes() -> int:
	var scene: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var board: Node = scene.get("board_view")
	var failures := 0
	for size in SIZES:
		var maze := MazeData.new()
		maze.generate(size, size, 0.4)
		board.call("setup_maze", maze, StandardGameMode.new("medium"))
		await process_frame
		failures += _check_fit(board, size, "luoi %dx%d sinh tu dong" % [size, size])

	scene.queue_free()
	await process_frame
	return failures


func _check_fit(board: Node, size: int, label: String) -> int:
	var failures := 0
	var inner: Rect2 = board.call("panel_inner_rect")
	if inner.size.x <= 0.0 or inner.size.y <= 0.0:
		print("[FAIL] %s: khong do duoc vung giay ve that" % label)
		return 1

	var step: float = board.get("_step")
	var cell_size: float = board.get("_cell_size")
	var content_w := step * float(size)
	var content_h := step * float(size)

	if step > cell_size + 0.01:
		print("[FAIL] %s: co o (%.1f) lon hon co goc (%.1f)" % [label, step, cell_size])
		failures += 1

	if size <= 5 and not is_equal_approx(step, cell_size):
		print("[FAIL] %s: luoi nho phai giu nguyen co o goc (%.1f != %.1f)"
			% [label, step, cell_size])
		failures += 1

	# 1. Mọi Ô phải nằm trong vùng giấy vẽ thật
	var rects: Array = board.get("_cell_rects")
	var min_margin := INF
	var min_margin_x := INF
	var min_margin_y := INF
	for rect in rects:
		var r: Rect2 = rect
		if r.size == Vector2.ZERO:
			continue      # ô ngoài board (polyomino)
		if not inner.encloses(r):
			print("[FAIL] %s: co o nam ngoai vung giay tai %s" % [label, str(r.position)])
			failures += 1
			break
		min_margin_x = minf(min_margin_x, minf(r.position.x - inner.position.x, inner.end.x - r.end.x))
		min_margin_y = minf(min_margin_y, minf(r.position.y - inner.position.y, inner.end.y - r.end.y))
		min_margin = minf(min_margin_x, min_margin_y)

	# 2. Tường (vẽ canh tâm mép lưới) + anchor cũng phải nằm trong vùng giấy
	var walls: Dictionary = board.get("_wall_segments")
	for key in walls:
		var seg: Line2D = walls[key]
		var half := seg.width * 0.5
		for point in seg.points:
			var p: Vector2 = seg.position + point
			if not inner.grow(-half + 0.5).has_point(p):
				print("[FAIL] %s: tuong tai %s vuot ra ngoai vung giay" % [label, str(p)])
				failures += 1
				break
		if failures > 0:
			break

	for info in board.get("_anchor_nodes"):
		var anchor: Control = info.node
		if not inner.encloses(Rect2(anchor.position, anchor.size)):
			print("[FAIL] %s: anchor tai %s vuot ra ngoai vung giay"
				% [label, str(anchor.position)])
			failures += 1
			break

	# 3. Phải còn MÉP CHỪA giữa lưới và vùng giấy (yêu cầu: cell nằm bên trong panel 1 khoảng margin)
	if min_margin < 4.0:
		print("[FAIL] %s: luoi chi cach mep giay %.1fpx (can >= 4px)" % [label, min_margin])
		failures += 1

	# 4. Cỡ chữ + bề rộng tường co theo nhưng không nhỏ hơn ngưỡng
	var font_size: int = board.call("_scaled_font_size")
	var wall_width: float = board.call("_scaled_wall_width")
	var base_font: float = board.get("_base_font_size")
	if font_size > int(base_font) or font_size < 12:
		print("[FAIL] %s: co chu %d khong hop le (goc %.0f)" % [label, font_size, base_font])
		failures += 1
	if wall_width < 3.0:
		print("[FAIL] %s: be rong tuong %.1f qua mong" % [label, wall_width])
		failures += 1

	# 5. Ô thật phải được đặt lại size + cỡ chữ (LabelSettings phải được duplicate)
	var applied := true
	for node in board.get("_cell_nodes"):
		if node == null:
			continue
		var cell: MazeCell = node
		if not is_equal_approx(cell.size.x, step):
			applied = false
			break
		var lbl: Label = cell.get_node_or_null("Sprite/Label")
		if lbl == null or lbl.label_settings == null or lbl.label_settings.font_size != font_size:
			applied = false
			break
		# Chữ phụ của lớp mực phai (SẮP PHAI / CẠN) phải co theo nhưng không nhỏ quá ngưỡng
		var warn_lbl: Label = cell.get_node_or_null("Sprite/WarnLabel")
		var faded_lbl: Label = cell.get_node_or_null("Sprite/FadedLabel")
		if warn_lbl == null or warn_lbl.label_settings == null \
				or warn_lbl.label_settings.font_size > font_size \
				or warn_lbl.label_settings.font_size < 8 \
				or faded_lbl == null or faded_lbl.label_settings == null \
				or faded_lbl.label_settings.font_size > font_size \
				or faded_lbl.label_settings.font_size < 10:
			applied = false
			break
	if not applied:
		print("[FAIL] %s: cell chua duoc ap co o / co chu" % label)
		failures += 1

	# 6. Anchor cũng phải co
	for info in board.get("_anchor_nodes"):
		var anchor: Control = info.node
		if anchor.size.x > step + 0.5:
			print("[FAIL] %s: anchor (%.1f) lon hon co o (%.1f)" % [label, anchor.size.x, step])
			failures += 1
			break

	if failures == 0:
		print("[CHECK] %s: o %.0fpx, chu %d, tuong %.1f, con mep %.1fpx trong vung giay %.0fx%.0f"
			% [label, step, font_size, wall_width, min_margin, inner.size.x, inner.size.y])
	return failures
