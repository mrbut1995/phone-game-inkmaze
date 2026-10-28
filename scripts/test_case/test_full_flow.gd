extends SceneTree
## ============================================================================
## Integration Test: Kiểm tra toàn diện luồng chuyển cảnh (Main Menu -> Levels -> Game -> Daily)
## ============================================================================

func _init() -> void:
	print("\n========================================================")
	print("  INTEGRATION TEST: SCENE FLOW & GAME NAVIGATION")
	print("========================================================\n")

	# 1. Test Main Scene
	var main_packed: PackedScene = load("res://scenes/main.tscn")
	assert(main_packed != null, "scenes/main.tscn phai load duoc")
	var main_scene: MainScene = main_packed.instantiate()
	root.add_child(main_scene)
	print("[CHECK] MainScene instantiated.")
	# LevelSection d?ng b?n ?? SAU khi b? c?c ?ang hi?n th? c? c? th?t (v?i frame + 1 nh?p
	# `visibility_changed`) ? ch? ?? l?u r?i m?i ki?m tr?ng th?i n?t m?n.
	for i in 20:
		await process_frame
	assert(main_scene.layout.event_carousel != null, "MainScene phai co EventCarousel")
	# Ban GOP: ban do man choi nam NGAY trong Main (man Levels rieng da go)
	var section: LevelSection = main_scene.layout.level_section
	assert(section != null, "MainScene phai co LevelSection (ban do man choi)")
	assert(section.map != null, "LevelSection phai co ban do LevelMap (bind bang @export)")
	assert(section.dungeon_pill != null, "LevelSection phai co nut Dungeon noi")
	# ĐƯỜNG LIỀN: `_line_ids` = màn của MỌI chương (xen CỔNG mã ÂM), nhưng bản đồ chỉ dựng
	# tới CỔNG KHOÁ đầu tiên ⇒ đếm phần đầu đó rồi so với số nút thật.
	var section_line: Array = section.get("_line_ids")
	var gate_info: Dictionary = section.get("_gate_info")
	var built_ids: Array = []
	for id in section_line:
		built_ids.append(int(id))
		if int(id) < 0 and not bool((gate_info.get(id, {}) as Dictionary).get("unlocked", false)):
			break
	var planned_levels := 0
	for id in built_ids:
		if int(id) > 0:
			planned_levels += 1
	assert(section.map.node_count() == planned_levels,
		"So nut tren ban do phai bang so man duoc dung (dang %d nut / %d man)"
			% [section.map.node_count(), planned_levels])
	# Cụm nút màn + cổng + đường nối nằm trong `Tracks/Items`
	var items: Node2D = section.map.items
	var expected_items := built_ids.size() + (1 if built_ids.size() >= 2 else 0)
	assert(items != null and items.get_child_count() == expected_items,
		"Items phai co %d con (nut man + cong + duong noi lien mach)" % expected_items)
	var current_node: LevelMapNode = section.map.node_for(section.chapter_continue_level())
	assert(current_node != null and current_node.state == LevelMapNode.State.CURRENT,
		"Man nen choi tiep phai co nut o trang thai CURRENT")
	assert(section.map.marker != null and section.map.marker.visible,
		"Mui chi 'man tiep theo' phai hien tren ban do")
	print("[CHECK] LevelSection: %d man -> %d nut ban do, mui chi o man %d."
		% [planned_levels, section.map.node_count(), section.chapter_continue_level()])
	main_scene.queue_free()
	await process_frame

	# 3. Test Daily Mission Scene
	var daily_packed: PackedScene = load("res://scenes/daily.tscn")
	assert(daily_packed != null, "scenes/daily.tscn phai load duoc")
	var daily_scene: DailyScene = daily_packed.instantiate()
	root.add_child(daily_scene)
	print("[CHECK] DailyScene instantiated.")
	await process_frame
	await process_frame
	assert(daily_scene.layout.btn_back != null, "DailyScene phai co btn_back")
	# Lich thang duoc dung lai theo thang hien tai (nodes/daily/calendar.tscn)
	var days_grid: GridContainer = daily_scene.layout.calendar.get_node_or_null("Panel/Days")
	assert(days_grid != null, "DailyScene phai co Calendar/Days")
	assert(days_grid.get_child_count() == 35, "Lich phai co 35 o ngay (7x5)")
	assert((days_grid.get_child(0) as DailyDayCell) != null, "O lich phai la DailyDayCell")
	daily_scene.queue_free()
	await process_frame

	# 4. Test Game Scene
	var game_packed: PackedScene = load("res://scenes/game.tscn")
	assert(game_packed != null, "scenes/game.tscn phai load duoc")
	var game_scene: GameScene = game_packed.instantiate()
	root.add_child(game_scene)
	print("[CHECK] GameScene instantiated.")
	await process_frame
	await process_frame
	assert(game_scene.board_view != null, "GameScene phai co board_view")
	assert(game_scene.game_controller != null, "GameScene phai co game_controller")
	assert(game_scene.find_child("Popups", true, false) != null, "GameScene phai co node Popups de chua popup")

	# 5. Test Debug Scene (man hinh dev)
	var debug_packed: PackedScene = load("res://scenes/debug.tscn")
	assert(debug_packed != null, "scenes/debug.tscn phai load duoc")
	var debug_scene: Node = debug_packed.instantiate()
	root.add_child(debug_scene)
	await process_frame
	await process_frame
	var debug_rows: Node = debug_scene.layout.rows_box
	assert(debug_rows != null, "Debug scene phai co vung Rows")
	assert(debug_rows.get_child_count() > 0, "Debug scene phai dung duoc cac hang lenh")
	print("[CHECK] DebugScene instantiated (%d hang lenh)." % debug_rows.get_child_count())
	debug_scene.queue_free()
	await process_frame

	print("\n[SUCCESS] Toan bo luong chuyen canh va cac man hinh hoat dong hoan hao!")
	quit(0)
