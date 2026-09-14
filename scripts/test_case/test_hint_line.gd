extends SceneTree
## ============================================================================
## Test Case: HINT LINE — KÉO NỐI 2 ANCHOR ĐỂ TẠO "TƯỜNG NGHI NGỜ" (2026-09)
##
## Mô phỏng đúng thao tác người chơi: NHẤN vào anchor -> KÉO -> THẢ sang anchor kề bên.
##   1. Anchor KHÔNG được "ăn" sự kiện chuột/cảm ứng, nếu không Board sẽ không bao giờ
##      nhận được cú nhấn/kéo => không có hint line (bug báo cáo).
##   2. Vừa nhấn: hint line (đường gợi ý) HIỆN RA, bắt đầu từ tâm anchor nguồn.
##   3. Đang kéo: hint line bám theo ngón tay và SNAP vào tâm anchor đích khi tới gần.
##   4. Thả ra: tạo Tường Nghi Ngờ (toggle) qua AnchorController.
## ============================================================================

const TEST_LEVEL := 3

var _failed := 0
var _checks := 0


func _init() -> void:
	print("\n========================================================")
	print("  TEST: HINT LINE (KEO NOI ANCHOR)")
	print("========================================================\n")

	await process_frame
	root.size = Vector2i(1080, 1920)

	var gm: Node = root.get_node_or_null("GameManager")
	assert(gm != null, "Autoload GameManager phai ton tai")
	gm.set("current_mode", "play")
	gm.set("current_level", TEST_LEVEL)
	gm.set("unlocked_levels", 9)

	var game_scene: GameScene = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game_scene)
	await process_frame
	await process_frame

	var board: Control = game_scene.board_view
	var anchor_ctrl: AnchorController = game_scene.anchor_controller
	_check(board != null and anchor_ctrl != null, "Game scene nap duoc Board + AnchorController")
	if board == null or anchor_ctrl == null:
		_finish()
		return

	# ---------------------------------------------------------------- 1. Anchor nhường sự kiện
	print("--- 1. ANCHOR CO NHUONG SU KIEN CHO BOARD? ---")
	var infos: Array = board.get("_anchor_nodes")
	_check(infos.size() > 0, "Board co %d anchor" % infos.size())
	var blocking := 0
	var button_blocking := 0
	for info in infos:
		var node: Control = info.node
		if node.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			blocking += 1
		var button := node.get_node_or_null("TextureButton") as Control
		if button == null:
			continue
		if button.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			button_blocking += 1
	_check(blocking == 0, "Moi node Anchor deu nhuong su kien (mouse_filter = IGNORE), dang chan: %d" % blocking)
	_check(button_blocking == 0, "Moi TextureButton cua anchor deu nhuong su kien, dang chan: %d" % button_blocking)

	# ---------------------------------------------------------------- 2. Chọn cặp anchor kề nhau
	print("\n--- 2. CHON CAP ANCHOR KE NHAU ---")
	var pair := _find_anchor_pair(board)
	_check(pair.size() == 2, "Tim duoc 1 canh giua 2 anchor ke nhau (tang %d)" % TEST_LEVEL)
	if pair.size() != 2:
		_finish()
		return
	var src_corner: Vector2i = pair[0]
	var dst_corner: Vector2i = pair[1]
	var edge := AnchorController.get_edge_between(src_corner, dst_corner)
	var src_pos := _anchor_screen_pos(board, src_corner)
	var dst_pos := _anchor_screen_pos(board, dst_corner)
	print("[INFO] Canh (is_h=%s, lattice=%s) | anchor %s -> %s"
		% [str(edge[0]), str(edge[1]), str(src_corner), str(dst_corner)])

	# ---------------------------------------------------------------- 3. Nhấn vào anchor
	print("\n--- 3. NHAN VAO ANCHOR ---")
	_touch(src_pos, true)
	await process_frame
	await process_frame
	var guide: Line2D = board.get("_drag_guide_line")
	_check(bool(board.get("_is_dragging_anchor")), "Nhan vao anchor -> Board bat dau keo anchor")
	_check(guide != null, "Board co node hint line")
	if guide != null:
		_check(guide.visible, "Hint line HIEN NGAY khi nhan vao anchor")
		if guide.visible and guide.points.size() == 2:
			_check(guide.points[0].distance_to(guide.points[1]) < 0.5,
				"Hint line xuat phat tu tam anchor nguon")

	# ---------------------------------------------------------------- 4. Kéo (chưa tới đích)
	print("\n--- 4. KEO RA GIUA 2 ANCHOR ---")
	var mid_pos := (src_pos + dst_pos) * 0.5
	_drag(mid_pos)
	await process_frame
	await process_frame
	if guide != null:
		var expect_mid := _board_local(board, mid_pos)
		_check(guide.visible, "Hint line van hien khi dang keo")
		if guide.points.size() == 2:
			_check(guide.points[1].distance_to(expect_mid) < 3.0,
				"Hint line bam theo ngon tay (lech %.1f px)"
				% guide.points[1].distance_to(expect_mid))

	# ---------------------------------------------------------------- 5. Kéo tới anchor đích
	print("\n--- 5. KEO TOI ANCHOR DICH (SNAP) ---")
	_drag(dst_pos)
	await process_frame
	await process_frame
	if guide != null and guide.points.size() == 2:
		var expect_dst := _board_local(board, dst_pos)
		_check(guide.points[1].distance_to(expect_dst) < 3.0,
			"Hint line SNAP vao tam anchor dich (lech %.1f px)"
			% guide.points[1].distance_to(expect_dst))

	# ---------------------------------------------------------------- 6. Thả -> tạo tường nghi ngờ
	print("\n--- 6. THA RA -> TAO TUONG NGHI NGO ---")
	var toggles: Array = []
	anchor_ctrl.connect("suspected_wall_toggled",
		func(is_h: bool, lattice: Vector2i, active: bool) -> void:
			toggles.append([is_h, lattice, active]))
	_touch(dst_pos, false)
	await process_frame
	await process_frame
	_check(toggles.size() == 1, "Tha ra phat tin hieu tao tuong nghi ngo (%d lan)" % toggles.size())
	if toggles.size() >= 1:
		_check(toggles[0][0] == edge[0] and toggles[0][1] == edge[1] and bool(toggles[0][2]),
			"Tin hieu dung canh da keo va dang BAT")
	_check(not bool(board.get("_is_dragging_anchor")), "Ket thuc trang thai keo anchor")
	if guide != null:
		_check(not guide.visible, "Hint line AN sau khi tha")
	_check(bool(anchor_ctrl.is_suspected(edge[0], edge[1])), "AnchorController ghi nhan da danh dau")

	# ---------------------------------------------------------------- 7. Kéo lại -> tắt
	print("\n--- 7. KEO LAI CUNG CANH -> TAT ---")
	_touch(src_pos, true)
	await process_frame
	_drag(dst_pos)
	await process_frame
	_touch(dst_pos, false)
	await process_frame
	await process_frame
	_check(toggles.size() == 2, "Keo lai cung canh phat tin hieu lan 2 (%d lan)" % toggles.size())
	if toggles.size() >= 2:
		_check(not bool(toggles[1][2]), "Lan 2 la TAT danh dau")
	_check(not bool(anchor_ctrl.is_suspected(edge[0], edge[1])), "Trang thai nghi ngo da xoa")

	game_scene.queue_free()
	await process_frame
	_finish()


# ---------------------------------------------------------------------------
# Tiện ích
# ---------------------------------------------------------------------------
func _finish() -> void:
	print("\n--------------------------------------------------------")
	if _failed == 0:
		print("  KET QUA: %d/%d CHECK PASS" % [_checks, _checks])
	else:
		print("  KET QUA: %d/%d CHECK FAIL" % [_failed, _checks])
	print("--------------------------------------------------------\n")
	quit(1 if _failed > 0 else 0)


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failed += 1
	print("[%s] %s" % ["CHECK" if condition else "FAIL", label])


## Cặp anchor kề nhau đầu tiên có cạnh thuộc board và CHƯA có tường
## (đúng loại cạnh người chơi đánh dấu "tường nghi ngờ"; cạnh viền luôn có tường nên bỏ qua)
func _find_anchor_pair(board: Control) -> Array:
	var maze: MazeData = board.get("maze")
	var infos: Array = board.get("_anchor_nodes")
	var lookup := {}
	for info in infos:
		lookup[info.corner] = true
	for info in infos:
		var corner: Vector2i = info.corner
		var right := corner + Vector2i(1, 0)
		if lookup.has(right) and bool(board.call("_edge_touches_board", true, corner)) \
				and not _wall_exists(maze, true, corner):
			return [corner, right]
	for info in infos:
		var corner: Vector2i = info.corner
		var below := corner + Vector2i(0, 1)
		if lookup.has(below) and bool(board.call("_edge_touches_board", false, corner)) \
				and not _wall_exists(maze, false, corner):
			return [corner, below]
	return []


func _wall_exists(maze: MazeData, is_h: bool, lattice: Vector2i) -> bool:
	if maze == null:
		return false
	if is_h:
		return bool(maze.call("has_h_wall", lattice.x, lattice.y))
	return bool(maze.call("has_v_wall", lattice.x, lattice.y))


## Tâm anchor (toạ độ MÀN HÌNH) - dùng để gửi sự kiện cảm ứng
func _anchor_screen_pos(board: Control, corner: Vector2i) -> Vector2:
	for info in (board.get("_anchor_nodes") as Array):
		if info.corner == corner:
			var node: Control = info.node
			return root.get_canvas_transform() * node.get_global_rect().get_center()
	return Vector2.ZERO


## Đổi toạ độ màn hình -> toạ độ local của Board (để so với điểm của hint line)
func _board_local(board: Control, screen_pos: Vector2) -> Vector2:
	return board.call("_to_local", board.call("_screen_to_canvas", screen_pos))


func _touch(pos: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = pos
	event.pressed = pressed
	Input.parse_input_event(event)


func _drag(pos: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = 0
	event.position = pos
	Input.parse_input_event(event)
