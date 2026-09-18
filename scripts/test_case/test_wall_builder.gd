extends SceneTree
## ============================================================================
## Test Case: WALL BUILDER — XÂY TƯỜNG (2026-09-19)
##
## 1. Bàn KHÔNG có S/F: MỌI ô hiện số tường (0..4); không có nhân vật, không di chuyển.
## 2. Số đoạn cần dựng = Σ(số trên mọi ô)/2 = số đoạn tường thật của mê cung.
## 3. Kéo nối 2 Anchor = bật/tắt 1 đoạn tường (state "built"); viền ngoài KHÔNG vẽ được.
## 4. GỬI SAI -> mất 1 LƯỢT GỬI + báo số đoạn lệch; GỬI ĐÚNG -> THẮNG màn.
## 5. Hết 3 lượt gửi -> THUA (popup "HẾT LƯỢT GỬI!") + Hồi sinh -> +1 LƯỢT GỬI.
## 6. UNDO xoá đoạn vừa nối (không xoá đoạn đã bị Gợi ý khoá).
## 7. GỢI Ý mở + KHOÁ 1 đoạn tường THẬT (không xoá được nữa).
## 8. HUD WallBuilderHUD + nhãn thanh công cụ (VẼ TƯỜNG · GỬI BÀI).
## ============================================================================

var _failed := 0
var _checks := 0


func _init() -> void:
	print("\n========================================================")
	print("  TEST: WALL BUILDER - XAY TUONG")
	print("========================================================\n")
	await process_frame
	root.size = Vector2i(1080, 1920)
	TranslationServer.set_locale("vi")

	var scene: GameScene = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	assert(scene != null, "Phai load duoc scenes/game.tscn")
	root.add_child(scene)
	await process_frame
	await process_frame

	await _run(scene)

	scene.queue_free()
	await process_frame

	print("\n--------------------------------------------------------")
	if _failed == 0:
		print("  KET QUA: %d/%d CHECK PASS" % [_checks, _checks])
	else:
		print("  KET QUA: %d/%d CHECK FAIL" % [_failed, _checks])
	print("--------------------------------------------------------\n")
	quit(1 if _failed > 0 else 0)


func _run(scene: GameScene) -> void:
	var mode := await _new_run(scene, "easy")
	var grid := scene.grid_controller
	var gc := scene.game_controller
	_entry(mode != null, "Lay duoc WallBuilderGameMode")
	if mode == null or grid == null or gc == null or grid.maze == null:
		return
	var maze := grid.maze

	# --- 1. Bàn không có S/F + không nhân vật + không di chuyển ---
	_entry(_all_cells_show_numbers(scene, maze), "MOI o hien so tuong 0..4 (khong co S/F)")
	_entry(not mode.shows_player(), "Che do khong hien nhan vat")
	var board := scene.grid_controller.board_view
	_entry(board != null and bool(board.get("_player_hidden")), "Board da an nhan vat")
	var before_pos := grid.current_pos
	var eval := mode.evaluate_move(before_pos, before_pos + Vector2i(1, 0), maze)
	_entry(not bool(eval.get("allowed", true)), "Moi nuoc 'di chuyen' deu bi tu choi")

	# --- 2. Số đoạn cần dựng ---
	var true_segments := mode.count_true_segments(maze)
	var sum_clues := 0
	for y in maze.height:
		for x in maze.width:
			sum_clues += maze.get_wall_count(Vector2i(x, y))
	_entry(mode.required_segments == true_segments,
		"So doan can dung = so tuong that cua me cung (%d)" % mode.required_segments)
	_entry(sum_clues == true_segments * 2,
		"Tong so tren moi o = 2 x so doan tuong (%d = 2x%d)" % [sum_clues, true_segments])
	_entry(mode.built_count() == 0 and mode.retries_left == 3,
		"Mo van: 0 doan da dung, du 3 LUOT GUI")
	_entry(mode.count_solutions(maze, 2) >= 1,
		"Solver dem duoc nghiem cua ban (%d)" % mode.count_solutions(maze, 2))
	_entry(mode.solution_count >= 1,
		"Bo sinh ban chon ban dang suy luan (nghiem=%d, can %d doan)"
			% [mode.solution_count, mode.required_segments])
	_entry(mode.required_segments >= maze.width,
		"Ban khong qua de: so doan tuong (%d) >= canh ban (%d)" % [mode.required_segments, maze.width])

	# Thử thách MẶC ĐỊNH của chế độ (§5.13): no_wrong_submit · time_max · no_hint
	var cc := scene.challenge_controller
	if cc != null:
		var rows: Array[Dictionary] = cc.rows()
		_entry(rows.size() == 3 and str(rows[0].get("type", "")) == "no_wrong_submit",
			"Thu thach mac dinh cua Wall Builder la 'no_wrong_submit' (%s)"
				% str(rows[0].get("type", "") if rows.size() > 0 else ""))

	# --- 8. HUD + thanh công cụ ---
	var hud := scene.ui_controller.hud as WallBuilderHUD
	_entry(hud != null, "Man choi dung HUD WallBuilderHUD rieng")
	if hud != null:
		hud.update_hud({"mode": mode})
		var max_lbl := hud.get_node_or_null("Sheet/Cover/CoverMax") as Label
		var note := hud.get_node_or_null("Sheet/Cover/CoverNote") as Label
		var submit := hud.get_node_or_null("Sheet/Row1/Submit") as Label
		var chip := hud.get_node_or_null("Sheet/Row1/ChipLabel") as Label
		_entry(max_lbl != null and max_lbl.text == tr("STR_HUD_WB_COVER_MAX").format([true_segments]),
			"HUD: tong so doan ('%s')" % _text_of(max_lbl))
		_entry(note != null and note.text == tr("STR_HUD_WB_COVER_NOTE").format([true_segments]),
			"HUD: con thieu bao nhieu doan ('%s')" % _text_of(note))
		_entry(submit != null and submit.text == tr("STR_HUD_WB_SUBMIT").format([3, 3]),
			"HUD: dong LUOT GUI ('%s')" % _text_of(submit))
		_entry(chip != null and chip.text == tr("STR_HUD_WB_CHIP_BUILDING"),
			"HUD: chip trang thai DANG NOI TUONG ('%s')" % _text_of(chip))
		_entry(hud.challenge_card() == null, "challenge_card() = null (khong co the THU THACH)")
		var sheet := hud.get_node_or_null("Sheet") as Control
		if sheet != null:
			_entry(absf(sheet.size.x - 690.0) <= 1.0 and absf(sheet.size.y - 156.0) <= 1.0,
				"Bang Tuong Da Ve 690x156 (%.0fx%.0f)" % [sheet.size.x, sheet.size.y])
	_entry((scene.tool_path_btn.get_node_or_null("Label") as Label).text == "STR_TOOL_DRAW_WALL",
		"Nut 1 doi thanh VE TUONG")
	_entry((scene.tool_path_btn.get_node_or_null("Sub") as Label).text == "STR_TOOL_DRAW_WALL_DESC",
		"Nhan phu nut VE TUONG ('%s')" % _text_of(scene.tool_path_btn.get_node_or_null("Sub")))
	_entry(scene.tool_wall_btn.visible
			and (scene.tool_wall_btn.get_node_or_null("Label") as Label).text == "STR_TOOL_SUBMIT",
		"Nut 2 doi thanh GUI BAI (khong bi an)")
	var submit_tex := scene.tool_wall_btn.texture_normal
	_entry(submit_tex != null and submit_tex.resource_path.contains("btn_tool_submit"),
		"Nut GUI BAI dung art xanh rieng cua che do (%s)"
			% (submit_tex.resource_path if submit_tex != null else "(null)"))

	# --- 3. Vẽ tường: khe trong bàn OK, viền ngoài bị chặn ---
	var drawn_edge := _first_true_edge(maze)
	_entry(drawn_edge.size() == 2, "Tim duoc 1 doan tuong that de thu")
	if drawn_edge.size() == 2:
		_toggle_edge(grid, bool(drawn_edge[0]), drawn_edge[1])
		await process_frame
		_entry(mode.built_count() == 1, "Keo noi 2 Anchor -> co 1 doan da dung (%d)" % mode.built_count())
		_entry(_segment_state(scene) == "built", "Doan tuong nguoi choi noi hien kieu 'built' (%s)"
			% _segment_state(scene))
		_toggle_edge(grid, bool(drawn_edge[0]), drawn_edge[1])
		await process_frame
		_entry(mode.built_count() == 0, "Keo lai dung doan do -> tat doan tuong (%d)" % mode.built_count())
	# Viền ngoài board: cạnh trái của ô (0,0) -> không được vẽ
	grid.handle_anchor_connected(Vector2i(0, 0), Vector2i(0, 1))
	await process_frame
	_entry(mode.built_count() == 0, "Vien ngoai board KHONG ve duoc (%d)" % mode.built_count())

	# --- 7. Gợi ý: mở + khoá 1 đoạn tường THẬT ---
	gc.hint()
	await process_frame
	_entry(mode.built_count() == 1, "Goi y mo 1 doan tuong (%d)" % mode.built_count())
	var locked_key := str(mode.get("locked").keys()[0]) if not mode.get("locked").is_empty() else ""
	_entry(not locked_key.is_empty(), "Doan goi y duoc KHOА (%s)" % locked_key)
	if not locked_key.is_empty():
		var parts := locked_key.split(",")
		var lk_h := parts[0] == "h"
		var lk_lat := Vector2i(int(parts[1]), int(parts[2]))
		_entry(maze.has_h_wall(lk_lat.x, lk_lat.y) if lk_h else maze.has_v_wall(lk_lat.x, lk_lat.y),
			"Doan goi y dung la tuong THAT cua me cung")
		_toggle_edge(grid, lk_h, lk_lat)
		await process_frame
		_entry(mode.built_count() == 1, "Doan da khoa KHONG xoa duoc (%d)" % mode.built_count())

	# --- 6. UNDO xoá đoạn vừa nối (bỏ qua đoạn bị khoá) ---
	var second := _first_true_edge(maze)
	if second.size() == 2:
		# chọn một đoạn CHƯA dựng để có gì đó cho Undo xoá
		var candidates := _all_true_edges(maze)
		var target := Vector2i(-1, -1)
		var target_h := false
		for cand: Array in candidates:
			var key := ("h,%d,%d" if bool(cand[0]) else "v,%d,%d") % [cand[1].x, cand[1].y]
			if not bool(mode.get("built").has(key)) and not bool(mode.get("locked").has(key)):
				target_h = bool(cand[0])
				target = cand[1]
				break
		if target != Vector2i(-1, -1):
			_toggle_edge(grid, target_h, target)
			await process_frame
			_entry(mode.built_count() == 2, "Ve them 1 doan -> 2 doan (%d)" % mode.built_count())
			gc.undo()
			await process_frame
			_entry(mode.built_count() == 1, "UNDO xoa doan vua noi -> con 1 (%d)" % mode.built_count())
			gc.undo()
			await process_frame
			_entry(mode.built_count() == 1, "UNDO khong xoa duoc doan da khoa (%d)" % mode.built_count())

	# --- 4. GỬI SAI -> mất 1 lượt ---
	var wrong_result: Dictionary = mode.evaluate_submit()
	_entry(int(wrong_result.get("wrong", 0)) > 0, "Ban dang sai -> bao con lech %d doan"
		% int(wrong_result.get("wrong", 0)))
	gc.submit_build()
	await process_frame
	_entry(mode.retries_left == 2, "GUI SAI -> con 2 LUOT GUI (%d)" % mode.retries_left)
	_entry(not bool(gc.get("_floor_finished")), "GUI sai -> chua thang man")
	_entry(not Popups.is_open(Popups.GAME_OVER_LEVEL), "Con luot -> chua mo popup thua")

	# --- 4b. GỬI SAI 2 lần nữa -> HẾT LƯỢT -> THUA ---
	gc.submit_build()
	await process_frame
	_entry(mode.retries_left == 1, "GUI SAI lan 2 -> con 1 LUOT GUI (%d)" % mode.retries_left)
	gc.submit_build()
	await process_frame
	await process_frame
	_entry(mode.retries_left == 0, "GUI SAI lan 3 -> het LUOT GUI (%d)" % mode.retries_left)
	_entry(not bool(gc.get("_run_active")), "Het luot gui -> van ket thuc")
	_entry(Popups.is_open(Popups.GAME_OVER_LEVEL), "Mo popup THUA (GAME_OVER_LEVEL)")
	var popup := Popups.get_popup(Popups.GAME_OVER_LEVEL)
	var title := popup.piece("Title") as Label if popup != null else null
	_entry(title != null and title.text == "STR_GAME_OVER_OUT_OF_SUBMITS",
		"Popup thua hien tieu de 'HET LUOT GUI!' ('%s')" % _text_of(title))
	var desc := popup.piece("Banner/Desc") as Label if popup != null else null
	_entry(desc != null and desc.text == tr("STR_REVIVE_DESC_SUBMIT"),
		"Dong HOI SINH noi '+1 LUOT GUI' ('%s')" % _text_of(desc))

	# --- 5. Hồi sinh -> +1 LƯỢT GỬI ---
	gc.revive_run()
	await process_frame
	await process_frame
	_entry(mode.retries_left == 1, "Hoi sinh -> cong them 1 LUOT GUI (%d)" % mode.retries_left)
	_entry(bool(gc.get("_run_active")), "Hoi sinh -> choi tiep duoc")
	_entry(await _wait_popup_closed(Popups.GAME_OVER_LEVEL), "Hoi sinh -> dong popup thua")

	# --- 4c. Dựng ĐÚNG mê cung rồi GỬI -> THẮNG ---
	_build_exact_solution(mode, grid, maze)
	await process_frame
	_entry(mode.evaluate_submit().get("solved", false),
		"Dung du moi doan tuong that -> cau hinh KHOP moi con so (%d doan)" % mode.built_count())
	_entry(_all_cells_satisfied(scene, mode, maze),
		"Dung du tuong -> MOI o deu bao DA KHOP SO (nen xanh la nhat)")
	if hud != null:
		hud.update_hud({"mode": mode})
		var chip2 := hud.get_node_or_null("Sheet/Row1/ChipLabel") as Label
		_entry(chip2 != null and chip2.text == tr("STR_HUD_WB_CHIP_READY"),
			"Khop het -> chip bao SAN SANG GUI ('%s')" % _text_of(chip2))
	gc.submit_build()
	await process_frame
	_entry(bool(gc.get("_floor_finished")), "GUI DUNG -> THANG man")
	_entry(not Popups.is_open(Popups.GAME_OVER_LEVEL), "Thang -> khong mo popup thua")


## Ván mới ở độ khó cho trước
func _new_run(scene: GameScene, difficulty: String) -> WallBuilderGameMode:
	scene.switch_mode("wall_builder", difficulty)
	await process_frame
	await process_frame
	return scene.game_mode_controller.game_mode as WallBuilderGameMode


## Mọi ô (kể cả S/F) phải hiện 1 chữ số 0..4
func _all_cells_show_numbers(scene: GameScene, maze: MazeData) -> bool:
	var board := scene.grid_controller.board_view
	if board == null:
		return false
	for y in maze.height:
		for x in maze.width:
			var cell: MazeCell = board._cell_node(Vector2i(x, y))
			if cell == null:
				return false
			var text: String = cell.get_text()
			if text.length() != 1 or not (text in ["0", "1", "2", "3", "4"]):
				return false
	return true


## Mọi đoạn tường THẬT bên trong mê cung: [[is_h, lattice], ...]
func _all_true_edges(maze: MazeData) -> Array:
	var edges: Array = []
	for ix in maze.width:
		for iy in range(1, maze.height):
			if maze.has_h_wall(ix, iy):
				edges.append([true, Vector2i(ix, iy)])
	for ix in range(1, maze.width):
		for iy in maze.height:
			if maze.has_v_wall(ix, iy):
				edges.append([false, Vector2i(ix, iy)])
	return edges


func _first_true_edge(maze: MazeData) -> Array:
	var edges := _all_true_edges(maze)
	return edges[0] if not edges.is_empty() else []


## Kéo nối 2 Anchor để bật/tắt 1 đoạn tường (corner_a/corner_b là toạ độ NEO)
func _toggle_edge(grid: GridController, is_h: bool, lattice: Vector2i) -> void:
	if is_h:
		grid.handle_anchor_connected(lattice, lattice + Vector2i(1, 0))
	else:
		grid.handle_anchor_connected(lattice, lattice + Vector2i(0, 1))


## Dựng ĐÚNG bằng cấu hình tường của mê cung gốc (một nghiệm hợp lệ)
func _build_exact_solution(mode: WallBuilderGameMode, grid: GridController, maze: MazeData) -> void:
	var wanted := {}
	for edge: Array in _all_true_edges(maze):
		var key := ("h,%d,%d" if bool(edge[0]) else "v,%d,%d") % [edge[1].x, edge[1].y]
		wanted[key] = edge
	# Tắt các đoạn đang dựng mà mê cung không có
	for key: String in (mode.get("built") as Dictionary).keys():
		if not wanted.has(key) and not bool(mode.get("locked").has(key)):
			var parts := key.split(",")
			_toggle_edge(grid, parts[0] == "h", Vector2i(int(parts[1]), int(parts[2])))
	# Bật các đoạn còn thiếu
	for key: String in wanted.keys():
		if not bool(mode.get("built").has(key)):
			var edge: Array = wanted[key]
			_toggle_edge(grid, bool(edge[0]), edge[1])


## Kiểu hiển thị của đoạn tường vừa nối trên board (Wall Builder: "built").
## LƯU Ý: đoạn trùng TƯỜNG ẨN có sẵn thì nằm trong `_wall_segments`, đoạn mới thì ở
## `_suspected_lines` -> phải tìm ở CẢ HAI.
func _segment_state(scene: GameScene) -> String:
	var board := scene.grid_controller.board_view
	if board == null:
		return ""
	for dict_name in ["_suspected_lines", "_wall_segments"]:
		var lines: Dictionary = board.get(dict_name)
		for key: String in lines.keys():
			var seg: WallSegment = lines[key]
			if seg != null and seg.visible and seg.get_state() != "invisible":
				return seg.get_state()
	return ""


## Mọi ô đều báo "đã khớp số" (lớp nền xanh lá nhạt) — dùng cho bước dựng đủ tường
func _all_cells_satisfied(scene: GameScene, mode: WallBuilderGameMode, maze: MazeData) -> bool:
	var board := scene.grid_controller.board_view
	if board == null:
		return false
	for y in maze.height:
		for x in maze.width:
			var pos := Vector2i(x, y)
			var cell: MazeCell = board._cell_node(pos)
			if cell == null or not cell.satisfied_visible():
				return false
			if not mode.is_cell_satisfied(pos):
				return false
	return true


func _text_of(node: Node) -> String:
	var label := node as Label
	return label.text if label != null else "(null)"


## Chờ popup đóng hẳn (popup đóng bằng hiệu ứng nên cần vài frame)
func _wait_popup_closed(id: String) -> bool:
	for i in 60:
		await process_frame
		if not Popups.is_open(id):
			return true
	return false


func _entry(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("  [PASS] %s" % label)
	else:
		_failed += 1
		print("  [FAIL] %s" % label)
