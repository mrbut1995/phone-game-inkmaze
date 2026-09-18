extends SceneTree
## ============================================================================
## Test Case: BẢNG XẾP HẠNG (Ranking) — tính năng 2026-02
##
## 1. API dữ liệu: đủ 3 bảng (dungeon/play/daily), mỗi bảng 24 đối thủ + người chơi.
## 2. Sắp hạng: điểm giảm dần, hạng 1..N duy nhất, podium 3 + rest phần còn lại.
## 3. Người chơi: có mặt ĐÚNG 1 lần mỗi bảng, cờ + kỷ lục lấy từ dữ liệu thật.
## 4. Ổn định: gọi lại cho kết quả y hệt; refresh(force) chỉ đổi đối thủ, không đổi điểm người chơi.
## 5. Làm mới: chỉ dựng lại khi sang khung 10 phút mới; last_refresh_unix <= hiện tại.
## 6. Định dạng: 18250 -> "18,250", chữ kỷ lục theo bảng, điểm kèm "PTS".
## 7. Scene: 3 tab + bục 3 hạng + danh sách cuộn + thanh "hạng của bạn", đổi tab đổi nội dung.
## ============================================================================

const TITLE := "BẢNG XẾP HẠNG"
const RIVAL_COUNT := 24

var _backup := ""
var _failed := 0
var _checks := 0


func _init() -> void:
	print("\n========================================================")
	print("  TEST: %s" % TITLE)
	print("========================================================\n")

	await process_frame
	root.size = Vector2i(1080, 1920)

	# Sao lưu dữ liệu thật (test không được phá tiến trình người chơi)
	if FileAccess.file_exists("user://inkmaze_data.json"):
		var rf := FileAccess.open("user://inkmaze_data.json", FileAccess.READ)
		_backup = rf.get_as_text()

	var manager: Node = root.get_node_or_null("RankingManager")
	assert(manager != null, "Autoload RankingManager phai ton tai")
	assert(manager.has_method("entries"), "RankingManager phai co entries()")

	var arch: Node = root.get_node_or_null("ArchivementManager")
	var stats: Dictionary = arch.call("export_progress") if arch != null else {}

	_section_1_boards(manager)
	_section_2_sorting(manager)
	_section_3_player(manager, arch)
	_section_4_stability(manager)
	_section_5_refresh(manager)
	_section_6_format()
	await _section_7_scene(manager)
	_section_8_wiring()

	# --- Khôi phục dữ liệu người chơi ---
	if arch != null and not stats.is_empty():
		arch.call("import_progress", stats)
	if not _backup.is_empty():
		var wf := FileAccess.open("user://inkmaze_data.json", FileAccess.WRITE)
		wf.store_string(_backup)
	print("[INFO] Da khoi phuc tien trinh nguoi choi.")

	print("\n--------------------------------------------------------")
	if _failed == 0:
		print("  KET QUA: %d/%d CHECK PASS" % [_checks, _checks])
	else:
		print("  KET QUA: %d/%d CHECK FAIL" % [_failed, _checks])
	print("--------------------------------------------------------\n")
	quit(1 if _failed > 0 else 0)


# ---------------------------------------------------------------------------
# 1. API dữ liệu
# ---------------------------------------------------------------------------
func _section_1_boards(manager: Node) -> void:
	print("[1] API du lieu...")
	var boards: Array = manager.call("board_ids")
	_entry(boards.size() == 3, "board_ids() tra ve 3 bang (nhan: %s)" % str(boards))
	for board in ["dungeon", "play", "daily"]:
		_entry(boards.has(board), "Co bang '%s'" % board)
		var all: Array = manager.call("entries", board)
		_entry(all.size() == RIVAL_COUNT + 1,
			"Bang '%s' co %d hang (24 doi thu + nguoi choi)" % [board, RIVAL_COUNT + 1])
		_entry(bool(manager.call("rest", board).size() == RIVAL_COUNT + 1 - 3),
			"Bang '%s': rest() = %d hang sau buc" % [board, RIVAL_COUNT + 1 - 3])


# ---------------------------------------------------------------------------
# 2. Sắp hạng
# ---------------------------------------------------------------------------
func _section_2_sorting(manager: Node) -> void:
	print("[2] Sap hang...")
	for board in ["dungeon", "play", "daily"]:
		var all: Array = manager.call("entries", board)
		var ok_points := true
		var ok_ranks := true
		var seen := {}
		for i in all.size():
			var e: Dictionary = all[i]
			if int(e.get("points", -1)) < 0:
				ok_points = false
			if i > 0 and int(all[i - 1].get("points", 0)) < int(e.get("points", 0)):
				ok_points = false
			var rank := int(e.get("rank", 0))
			if seen.has(rank):
				ok_ranks = false
			seen[rank] = true
			if rank != i + 1:
				ok_ranks = false
		_entry(ok_points, "Bang '%s': diem giam dan" % board)
		_entry(ok_ranks, "Bang '%s': hang 1..%d duy nhat, dung thu tu" % [board, all.size()])
		var top: Array = manager.call("podium", board)
		_entry(top.size() == 3 and int(top[0].get("rank", 0)) == 1,
			"Bang '%s': podium() = 3 hang dau (top1 = %s)" % [board, str(top[0].get("name", "?"))])


# ---------------------------------------------------------------------------
# 3. Người chơi
# ---------------------------------------------------------------------------
func _section_3_player(manager: Node, arch: Node) -> void:
	print("[3] Nguoi choi...")
	for board in ["dungeon", "play", "daily"]:
		var all: Array = manager.call("entries", board)
		var count := 0
		var player := {}
		for e in all:
			if bool(e.get("is_player", false)):
				count += 1
				player = e
		_entry(count == 1, "Bang '%s': nguoi choi xuat hien dung 1 lan" % board)
		_entry(str(player.get("id", "")) == "player", "Bang '%s': id nguoi choi = 'player'" % board)
		_entry(manager.call("my_rank", board) == int(player.get("rank", 0)),
			"Bang '%s': my_rank() khop hang trong bang (#%d)" % [board, int(player.get("rank", 0))])
		_entry(str(player.get("name", "")) == "STR_RANK_YOU",
			"Bang '%s': ten nguoi choi dung khoa dich STR_RANK_YOU" % board)
		_entry(str(player.get("flag", "")) != "", "Bang '%s': nguoi choi co co quoc gia" % board)

	if arch != null and arch.has_method("set_stat_for_test") and arch.has_method("stat_value"):
		# Giả lập kỷ lục Dungeon: tầng 30 + điểm 40.000 -> phải leo lên top đầu
		var old_floor := int(arch.call("stat_value", "dungeon_best_floor"))
		var old_score := int(arch.call("stat_value", "dungeon_best_score"))
		arch.call("set_stat_for_test", "dungeon_best_floor", 30)
		arch.call("set_stat_for_test", "dungeon_best_score", 40000)
		manager.call("refresh", true)
		var entry: Dictionary = manager.call("my_entry", "dungeon")
		var expect := 30 * 620 + 40000 / 8
		_entry(int(entry.get("primary", 0)) == 30, "Ky luc gia lap: primary = 30 tang (nhan %d)" % int(entry.get("primary", 0)))
		_entry(int(entry.get("points", 0)) == expect,
			"Ky luc gia lap: diem = %d (nhan %d)" % [expect, int(entry.get("points", 0))])
		_entry(manager.call("my_rank", "dungeon") <= 10,
			"Ky luc gia lap: leo len top 10 (hang #%d)" % int(manager.call("my_rank", "dungeon")))
		arch.call("set_stat_for_test", "dungeon_best_floor", old_floor)
		arch.call("set_stat_for_test", "dungeon_best_score", old_score)
		manager.call("refresh", true)


# ---------------------------------------------------------------------------
# 4. Ổn định
# ---------------------------------------------------------------------------
func _section_4_stability(manager: Node) -> void:
	print("[4] On dinh du lieu...")
	var before: Array = manager.call("entries", "dungeon")
	var after: Array = manager.call("entries", "dungeon")
	_entry(str(before) == str(after), "Goi lai entries() cho ket qua y het (seed co dinh)")
	var player_before: Dictionary = manager.call("my_entry", "play")
	manager.call("refresh", true)
	var player_after: Dictionary = manager.call("my_entry", "play")
	_entry(int(player_before.get("points", -1)) == int(player_after.get("points", -1)),
		"refresh(true): diem nguoi choi khong doi (%d)" % int(player_after.get("points", 0)))


# ---------------------------------------------------------------------------
# 5. Làm mới theo khung 10 phút
# ---------------------------------------------------------------------------
func _section_5_refresh(manager: Node) -> void:
	print("[5] Lam moi...")
	_entry(manager.call("refresh") == false, "refresh() trong cung khung 10 phut -> khong dung lai")
	_entry(manager.call("refresh", true) == true, "refresh(true) -> dung lai ngay")
	var stamp := int(manager.call("last_refresh_unix"))
	var now := int(Time.get_unix_time_from_system())
	_entry(stamp <= now and now - stamp < 600,
		"last_refresh_unix() nam trong khung 10 phut hien tai (lech %d giay)" % (now - stamp))


# ---------------------------------------------------------------------------
# 6. Định dạng hiển thị
# ---------------------------------------------------------------------------
func _section_6_format() -> void:
	print("[6] Dinh dang...")
	var RankingScript = load("res://scripts/utils/ranking.gd")
	_entry(RankingScript.thousands(18250) == "18,250",
		"thousands(18250) = '18,250' (nhan '%s')" % RankingScript.thousands(18250))
	_entry(RankingScript.thousands(950) == "950", "thousands(950) = '950'")
	_entry(RankingScript.thousands(1234567) == "1,234,567", "thousands(1234567) = '1,234,567'")
	_entry(RankingScript.rank_text(4) == "#4", "rank_text(4) = '#4'")
	var dungeon_entry := {"primary": 28, "points": 18250, "has_record": true}
	_entry(RankingScript.record_text("dungeon", dungeon_entry).contains("28"),
		"record_text dungeon chua so tang ('%s')" % RankingScript.record_text("dungeon", dungeon_entry))
	_entry(RankingScript.points_text(dungeon_entry).contains("18,250"),
		"points_text chua '18,250' ('%s')" % RankingScript.points_text(dungeon_entry))
	var no_record := {"primary": 0, "points": 0, "has_record": false}
	_entry(RankingScript.record_text("play", no_record) != RankingScript.record_text("play", {"primary": 3, "has_record": true}),
		"Chua co ky luc -> chu ky luc khac voi co ky luc")


# ---------------------------------------------------------------------------
# 7. Scene
# ---------------------------------------------------------------------------
func _section_7_scene(manager: Node) -> void:
	print("[7] Scene...")
	var packed := load("res://scenes/ranking.tscn") as PackedScene
	_entry(packed != null, "Load duoc scenes/ranking.tscn")
	if packed == null:
		return
	var scene: RankingScene = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	# --- Cấu trúc tĩnh trong .tscn ---
	_entry(_ui(scene, "TopBar/Back") is TextureButton, "TopBar co nut Back")
	var title := _ui(scene, "TopBar/Title") as Label
	_entry(title != null and title.text == "STR_RANK_TITLE", "Tieu de dung khoa dich STR_RANK_TITLE")
	_entry(_ui(scene, "Chip") is TextureRect, "Co chip pham vi goc phai")
	# To giay la NinePatchRect (co gian 9-slice theo man hinh), truoc day la TextureRect.
	var sheet := _ui(scene, "Sheet")
	_entry(sheet is NinePatchRect or sheet is TextureRect, "Co to giay Sheet")
	_entry(_ui(scene, "Sheet/Tape") is TextureRect, "To giay co bang dinh (tape)")
	_entry(_ui(scene, "Sheet/Scroll/Rows") is VBoxContainer, "Co danh sach cuon Sheet/Scroll/Rows")
	_entry(_ui(scene, "Sheet/MyRank") is TextureRect, "Co thanh 'hang cua ban' Sheet/MyRank")
	_entry(_ui(scene, "Sheet/Footer") is Label, "Co ghi chu chan trang")
	for group_name in ["Gold", "Silver", "Bronze"]:
		_entry(_ui(scene, "Sheet/Podium/" + group_name) != null,
			"Buc vinh quang co nhom %s" % group_name)

	# --- Tab dựng bằng code ---
	_entry(scene.tab_count() == 3, "3 tab duoc dung tu board_ids() (nhan %d)" % scene.tab_count())
	var tabs := _ui(scene, "Sheet/Tabs") as HBoxContainer
	_entry(tabs != null and tabs.get_child_count() == 3, "HBox Tabs co 3 nut")
	var tab_active_art: Texture2D = load("res://assets/images/ranking/tab_active.svg")
	var tab_normal_art: Texture2D = load("res://assets/images/ranking/tab_normal.svg")
	_entry((tabs.get_child(0) as TextureButton).texture_normal == tab_active_art,
		"Tab dau (dungeon) dang chon -> dung art active")

	# --- Bảng mặc định: dungeon ---
	_entry(scene.board() == "dungeon", "Bang mac dinh = dungeon")
	_entry(scene.row_count() == RIVAL_COUNT + 1 - 3,
		"Danh sach cuon co %d hang (hang 4..%d) — nhan %d" % [RIVAL_COUNT - 2, RIVAL_COUNT + 1, scene.row_count()])
	var gold := _ui(scene, "Sheet/Podium/Gold")
	var gold_record := (gold.get_node("Record") as Label).text
	_entry((gold.get_node("Name") as Label).text != "", "Buc hang 1 co ten doi thu")
	_entry(gold_record == Ranking.record_text("dungeon", manager.call("podium", "dungeon")[0]),
		"Chu ky luc buc hang 1 khop du lieu ('%s')" % gold_record)
	_entry((gold.get_node("Block/Rank") as Label).text == "1", "Buc vang hien so hang 1")

	# Hàng đầu danh sách = hạng 4, khớp dữ liệu manager
	var rows_host := _ui(scene, "Sheet/Scroll/Rows") as VBoxContainer
	var rest: Array = manager.call("rest", "dungeon")
	var first_entry: Dictionary = rest[0]
	var first_row := rows_host.get_child(0) as RankRow
	_entry((first_row.get_node("Rank") as Label).text == "#4",
		"Hang dau danh sach = #4 (nhan '%s')" % (first_row.get_node("Rank") as Label).text)
	_entry((first_row.get_node("Name") as Label).text == Ranking.display_name(first_entry),
		"Ten hang #4 khop du lieu ('%s')" % (first_row.get_node("Name") as Label).text)
	_entry((first_row.get_node("Points") as Label).text == Ranking.points_text(first_entry),
		"Diem hang #4 khop du lieu ('%s')" % (first_row.get_node("Points") as Label).text)

	# Hàng của người chơi dùng art riêng
	var player_index := -1
	for i in rest.size():
		if bool(rest[i].get("is_player", false)):
			player_index = i
	if player_index >= 0:
		var player_row := rows_host.get_child(player_index) as RankRow
		_entry((player_row.get_node("Bg") as TextureRect).texture == load("res://assets/images/ranking/rank_row_you.svg"),
			"Hang cua nguoi choi dung art rieng (rank_row_you.svg)")
		_entry((player_row.get_node("Name") as Label).text == Ranking.display_name(rest[player_index]),
			"Hang cua nguoi choi hien dung ten ('%s')" % (player_row.get_node("Name") as Label).text)
	else:
		_entry(false, "Nguoi choi phai co mat trong danh sach cuon")

	# Thanh dán đáy
	var my_rank_label := _ui(scene, "Sheet/MyRank/Rank") as Label
	_entry(my_rank_label.text == Ranking.rank_text(Ranking.my_rank("dungeon")),
		"Thanh dan day hien dung hang cua ban (nhan '%s')" % my_rank_label.text)
	_entry((_ui(scene, "Sheet/MyRank/Name") as Label).text == Ranking.display_name(Ranking.my_entry("dungeon")),
		"Thanh dan day hien dung ten nguoi choi")

	# --- Đổi tab bằng API ---
	scene.select_board("daily")
	await process_frame
	_entry(scene.board() == "daily", "select_board('daily') -> board() = daily")
	_entry((tabs.get_child(2) as TextureButton).texture_normal == tab_active_art, "Tab daily chuyen sang active")
	_entry((tabs.get_child(0) as TextureButton).texture_normal == tab_normal_art, "Tab dungeon tro ve binh thuong")
	_entry((gold.get_node("Record") as Label).text == Ranking.record_text("daily", manager.call("podium", "daily")[0]),
		"Chu ky luc buc vang doi theo bang ('%s')" % (gold.get_node("Record") as Label).text)
	_entry((gold.get_node("Record") as Label).text != gold_record, "Chu ky luc Daily khac Dungeon")

	# --- Đổi tab bằng cách bấm nút ---
	(tabs.get_child(1) as TextureButton).pressed.emit()
	await process_frame
	_entry(scene.board() == "play", "Bam tab thu 2 -> board = play")
	_entry(scene.row_count() == RIVAL_COUNT - 2, "Bang play cung co %d hang" % (RIVAL_COUNT - 2))

	# --- Nút Back đã nối signal (không bấm để tránh đổi scene) ---
	var back := _ui(scene, "TopBar/Back") as TextureButton
	_entry(back.pressed.get_connections().size() > 0, "Nut Back da duoc noi signal")

	# --- Vuốt dọc để cuộn danh sách (hàng là Control "ăn" sự kiện -> tự xử lý ở _input) ---
	var scroll := _ui(scene, "Sheet/Scroll") as ScrollContainer
	_entry(scroll != null, "Co vung cuon Sheet/Scroll")
	if scroll != null:
		var center := scroll.get_global_rect().get_center()
		var max_scroll := scroll.get_v_scroll_bar().max_value - scroll.size.y
		_entry(scroll.scroll_vertical == 0, "Danh sach bat dau o vi tri 0")
		scene.call("_begin_drag", center)
		scene.call("_update_drag", center + Vector2(0, -120))
		scene.call("_end_drag")
		await process_frame
		if max_scroll > 1.0:
			_entry(scroll.scroll_vertical > 0,
				"Vuot doc -> cuon duoc danh sach (scroll_vertical = %d)" % scroll.scroll_vertical)
		else:
			_entry(scroll.scroll_vertical == 0, "Danh sach vua khung -> vuot khong gay loi (scroll = 0)")
		# Kéo chưa qua ngưỡng -> coi như chạm, không cuộn
		var pos_before_drag := scroll.scroll_vertical
		scene.call("_begin_drag", center)
		scene.call("_update_drag", center + Vector2(0, -5))
		scene.call("_end_drag")
		_entry(scroll.scroll_vertical == pos_before_drag, "Keo rat ngan -> khong cuon")
		# Bắt đầu kéo NGOÀI vùng cuộn (ví dụ trên nút Back) -> không cuộn
		scene.call("_begin_drag", Vector2(100, 60))
		scene.call("_update_drag", Vector2(100, 0))
		scene.call("_end_drag")
		_entry(scroll.scroll_vertical == pos_before_drag, "Bat dau keo ngoai vung cuon -> khong cuon")

	scene.queue_free()
	await process_frame


func _section_8_wiring() -> void:
	print("[8] Noi dieu huong...")
	var nav_consts: Dictionary = load("res://scripts/utils/nav.gd").get_script_constant_map()
	_entry(str(nav_consts.get("SCENE_RANKING", "")) == "res://scenes/ranking.tscn",
		"Nav.SCENE_RANKING tro dung scenes/ranking.tscn")
	_entry(FileAccess.get_file_as_string("res://scripts/utils/nav.gd").contains("func goto_ranking"),
		"Nav co ham goto_ranking()")
	var scene_manager: Node = root.get_node_or_null("SceneManager")
	_entry(scene_manager != null, "Autoload SceneManager ton tai")
	if scene_manager != null:
		var sm_consts: Dictionary = scene_manager.get_script().get_script_constant_map()
		_entry(str(sm_consts.get("SCENE_RANKING", "")) == "res://scenes/ranking.tscn",
			"SceneManager.SCENE_RANKING tro dung scenes/ranking.tscn")
		_entry(scene_manager.has_method("goto_ranking"), "SceneManager co goto_ranking()")
	var main_src := FileAccess.get_file_as_string("res://scripts/scenes/main.gd")
	_entry(main_src.contains("_on_leaderboard_pressed") and main_src.contains("Nav.goto_ranking()"),
		"Nut XEP HANG o Main da noi toi Nav.goto_ranking()")


# ---------------------------------------------------------------------------
# Helper
# ---------------------------------------------------------------------------
## Màn đã tách 2 layout ⇒ node nằm trong layout đang hiển thị (dọc/ngang)
func _ui(scene: Node, path: String) -> Node:
	return scene.call("ui_path", path)


func _entry(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("  [PASS] %s" % label)
	else:
		_failed += 1
		print("  [FAIL] %s" % label)
