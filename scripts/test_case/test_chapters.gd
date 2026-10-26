extends SceneTree
## ============================================================================
## Test Case: HỆ THỐNG CHƯƠNG (Chapter Selection) — tính năng 2026-02
##
## 1. Dữ liệu: 4 file resources/chapters/chapter_N.tres -> ChapterData hợp lệ.
## 2. LevelManager: quét chương, gom màn theo chương, đếm Sao/màn đã qua.
## 3. GameManager: tổng Sao, điều kiện mở khóa, mở khóa bằng Sao, chương đang chơi.
## 4. Bền vững: export/import/reset giữ đúng unlocked_chapters + current_chapter.
## 4b. Khoá theo chương: xong màn cuối chương KHÔNG mở màn của chương chưa unlock.
## 8. Popup thắng màn: nút MÀN KẾ TIẾP đổi thành CHỌN MÀN khi hết chương.
## 9. Nối dây: Nav/SceneManager + nút CHƠI ở Main trỏ thẳng màn Chọn màn.
##
## ⚠️ Màn "CHỌN CHƯƠNG" đã XOÁ (2026-10-23): thay bằng TAB chương + khung khoá ngay trong
## màn Chọn màn (`ChapterTabs` / `ChapterLockSheet`) ⇒ test không còn mục thẻ chương /
## màn Chọn chương / vòng Back Chọn màn ⇄ Chọn chương.
## ============================================================================

const TITLE := "HỆ THỐNG CHƯƠNG"

var _backup := ""
var _progress: Dictionary = {}
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

	var lm: Node = root.get_node_or_null("LevelManager")
	var gm: Node = root.get_node_or_null("GameManager")
	assert(lm != null, "Autoload LevelManager phai ton tai")
	assert(gm != null, "Autoload GameManager phai ton tai")
	_progress = gm.call("export_progress")

	_section_1_data(lm)
	_section_2_level_manager(lm)
	_section_3_unlock(gm, lm)
	_section_4_persist(gm)
	_section_4b_chapter_gate(gm, lm)
	await _section_8_win_popup(gm)
	_section_9_wiring()

	# --- Khôi phục dữ liệu người chơi ---
	if not _progress.is_empty():
		gm.call("import_progress", _progress)
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
# 1. Dữ liệu chương
# ---------------------------------------------------------------------------
func _section_1_data(lm: Node) -> void:
	print("[1] Du lieu chuong...")
	var chapters: Array = lm.call("get_chapters")
	_entry(chapters.size() >= 4, "Co it nhat 4 chuong (nhan %d)" % chapters.size())
	for index in chapters.size():
		var chapter: ChapterData = chapters[index]
		_entry(chapter.chapter_id == index + 1,
			"Chuong #%d co id = %d" % [index + 1, chapter.chapter_id])
		_entry(chapter.is_valid(), "Chuong %d hop le (co ten)" % chapter.chapter_id)
		_entry(not chapter.title.strip_edges().is_empty(),
			"Chuong %d co tieu de ('%s')" % [chapter.chapter_id, chapter.title])
		_entry(not chapter.subtitle.strip_edges().is_empty(),
			"Chuong %d co mo ta" % chapter.chapter_id)
		_entry(chapter.star_cost >= 0,
			"Chuong %d co phi sao >= 0 (%d)" % [chapter.chapter_id, chapter.star_cost])
	# Mỗi chương có ICON riêng (tên icon ghi trong .tres, UI tra ra texture riêng)
	var expected_icons := ["intro", "logic", "trap", "master"]
	for index in mini(chapters.size(), expected_icons.size()):
		var chapter: ChapterData = chapters[index]
		_entry(chapter.display_icon() == expected_icons[index],
			"Chuong %d co icon rieng '%s' (nhan '%s')" % [
				chapter.chapter_id, expected_icons[index], chapter.display_icon()])
	_entry(lm.call("chapter_count") == chapters.size(),
		"chapter_count() khop get_chapters() (nhan %d)" % lm.call("chapter_count"))
	_entry(lm.call("get_chapter", 1) != null, "get_chapter(1) tra ve du lieu")
	_entry(lm.call("get_chapter", 99) == null, "get_chapter(99) = null (khong ton tai)")
	_entry(bool(lm.call("has_chapter", 4)), "has_chapter(4) = true")
	_entry(not bool(lm.call("has_chapter", 99)), "has_chapter(99) = false")
	_entry(FileAccess.file_exists(str(lm.call("chapter_path", 1))),
		"chapter_path(1) tro toi file that")
	# Chương 1 mở sẵn (0 sao), các chương sau cần Sao tăng dần
	var first: ChapterData = chapters[0]
	_entry(first.star_cost == 0, "Chuong 1 khong can sao (cost = %d)" % first.star_cost)
	var increasing := true
	for index in range(1, chapters.size()):
		if int(chapters[index].star_cost) <= int(chapters[index - 1].star_cost):
			increasing = false
	_entry(increasing, "Phi sao cac chuong tang dan")


# ---------------------------------------------------------------------------
# 2. LevelManager gom màn theo chương
# ---------------------------------------------------------------------------
func _section_2_level_manager(lm: Node) -> void:
	print("[2] LevelManager gom man theo chuong...")
	var all_ids: Array = lm.call("get_level_ids")
	_entry(all_ids.size() > 0, "Co man trong resources/levels (%d)" % all_ids.size())
	var covered := {}
	for chapter_id in range(1, int(lm.call("chapter_count")) + 1):
		var ids: Array = lm.call("levels_in_chapter", chapter_id)
		for level_id in ids:
			covered[int(level_id)] = true
			_entry(int(lm.call("chapter_of_level", level_id)) == chapter_id,
				"Man %d nam trong chuong %d" % [level_id, chapter_id])
		var total: int = int(lm.call("chapter_star_total", chapter_id))
		_entry(total == ids.size() * 3,
			"Chuong %d: toi da %d sao = %d man x 3" % [chapter_id, total, ids.size()])
	var missing := 0
	for level_id in all_ids:
		if not covered.has(int(level_id)):
			missing += 1
	_entry(missing == 0, "Moi man deu thuoc dung 1 chuong (thieu %d)" % missing)
	_entry(int(lm.call("levels_in_chapter", 1).size()) == 9,
		"Chuong 1 co 9 man (nhan %d)" % lm.call("levels_in_chapter", 1).size())
	_entry(int(lm.call("levels_in_chapter", 2).size()) >= 1,
		"Chuong 2 co man (nhan %d)" % lm.call("levels_in_chapter", 2).size())
	_entry((lm.call("levels_in_chapter", 999) as Array).is_empty(),
		"Chuong khong ton tai -> danh sach man rong")

	# Đếm sao / màn đã qua khớp tính tay
	var gm: Node = root.get_node_or_null("GameManager")
	var stars: Dictionary = gm.get("level_stars")
	var own := 0
	var cleared := 0
	for level_id in lm.call("levels_in_chapter", 1):
		var value := int(stars.get(int(level_id), 0))
		own += value
		if value > 0:
			cleared += 1
	_entry(int(lm.call("chapter_stars", 1)) == own,
		"chapter_stars(1) = %d khop du lieu thuc" % own)
	_entry(int(lm.call("chapter_cleared_count", 1)) == cleared,
		"chapter_cleared_count(1) = %d khop du lieu thuc" % cleared)
	var current: int = int(lm.call("current_chapter_id"))
	_entry(current == int(lm.call("chapter_of_level", int(gm.get("current_level")))),
		"current_chapter_id() = chuong cua man dang choi (%d)" % current)


# ---------------------------------------------------------------------------
# 3. Mở khóa chương bằng Sao
# ---------------------------------------------------------------------------
func _section_3_unlock(gm: Node, lm: Node) -> void:
	print("[3] Mo khoa chuong bang sao...")
	gm.call("reset_progress")
	_entry(bool(gm.call("is_chapter_unlocked", 1)), "Chuong 1 luon mo")
	_entry(not bool(gm.call("is_chapter_unlocked", 2)), "Chuong 2 khoa khi moi choi")
	_entry(int(gm.call("total_stars")) == 0, "Tong sao ban dau = 0")
	var cost_2: int = int(gm.call("chapter_star_cost", 2))
	var cost_3: int = int(gm.call("chapter_star_cost", 3))
	_entry(cost_2 == int(lm.call("get_chapter", 2).star_cost),
		"chapter_star_cost(2) = %d khop du lieu chuong" % cost_2)
	_entry(not bool(gm.call("can_unlock_chapter", 2)), "Chua du sao -> khong the mo chuong 2")
	_entry(not bool(gm.call("unlock_chapter", 2)), "unlock_chapter(2) tra ve false khi thieu sao")
	_entry(not bool(gm.call("is_chapter_unlocked", 2)), "Chuong 2 van khoa")

	# Cấp 3 sao cho từng màn chương 1 -> tổng 27 sao
	var stars: Dictionary = gm.get("level_stars")
	for level_id in lm.call("levels_in_chapter", 1):
		stars[int(level_id)] = 3
	_entry(int(gm.call("total_stars")) == 27, "Tong sao = 27 sau khi dat 3 sao/man chuong 1")
	_entry(bool(gm.call("can_unlock_chapter", 2)), "Du %d sao -> mo duoc chuong 2" % cost_2)
	_entry(not bool(gm.call("can_unlock_chapter", 3)), "27 sao < %d -> chua mo duoc chuong 3" % cost_3)
	_entry(bool(gm.call("unlock_chapter", 2)), "unlock_chapter(2) thanh cong")
	_entry(bool(gm.call("is_chapter_unlocked", 2)), "Chuong 2 da mo")
	_entry(not bool(gm.call("unlock_chapter", 2)), "Mo lai chuong da mo -> false (khong trung)")

	var unlocked: Array = gm.get("unlocked_chapters")
	_entry(unlocked.size() == 2 and unlocked.has(1) and unlocked.has(2),
		"unlocked_chapters = [1, 2] (nhan %s)" % str(unlocked))
	gm.call("set_chapter", 2)
	_entry(int(gm.get("current_chapter")) == 2, "set_chapter(2) -> current_chapter = 2")
	gm.call("set_chapter", 0)
	_entry(int(gm.get("current_chapter")) == 1, "set_chapter(0) bi kep ve 1")


# ---------------------------------------------------------------------------
# 4. Bền vững dữ liệu (export/import/reset)
# ---------------------------------------------------------------------------
func _section_4_persist(gm: Node) -> void:
	print("[4] Luu/tai tien do chuong...")
	gm.call("reset_progress")
	_entry(not bool(gm.call("is_chapter_unlocked", 2)), "reset xoa chuong da mo")
	gm.call("set_chapter", 3)
	var data: Dictionary = gm.call("export_progress")
	_entry(data.has("unlocked_chapters"), "export_progress co unlocked_chapters")
	_entry(data.has("current_chapter"), "export_progress co current_chapter")
	_entry(int(data.get("current_chapter", -1)) == 3, "export giu current_chapter = 3")
	var list: Array = data.get("unlocked_chapters", [])
	_entry(list.has(1), "export luon co chuong 1")
	gm.call("reset_progress")
	gm.call("import_progress", data)
	_entry(int(gm.get("current_chapter")) == 3, "import khoi phuc current_chapter = 3")
	_entry((gm.get("unlocked_chapters") as Array).has(1), "import khoi phuc chuong 1")
	var forced: Dictionary = {"unlocked_chapters": [5], "current_chapter": 0}
	gm.call("import_progress", forced)
	_entry((gm.get("unlocked_chapters") as Array).has(1), "du lieu thieu chuong 1 -> tu bo sung")
	_entry(int(gm.get("current_chapter")) == 1, "current_chapter <= 0 -> dua ve 1")


# ---------------------------------------------------------------------------
# 4b. Khoá theo CHƯƠNG: xong màn cuối chương KHÔNG nhảy sang chương chưa mở
# ---------------------------------------------------------------------------
func _section_4b_chapter_gate(gm: Node, lm: Node) -> void:
	print("[4b] Khoa theo chuong...")
	gm.call("reset_progress")
	var stars: Dictionary = gm.get("level_stars")
	for level_id in lm.call("levels_in_chapter", 1):
		stars[int(level_id)] = 3
	gm.set("unlocked_levels", 9)

	_entry(int(gm.call("next_level_in_chapter", 1)) == 2, "Man 1 -> man 2 (cung chuong 1)")
	_entry(int(gm.call("next_level_in_chapter", 9)) == -1,
		"Man 9 la man CUOI chuong 1 -> -1 (khong co man ke tiep trong chuong)")
	_entry(int(gm.call("next_level_in_chapter", 10)) == 11, "Man 10 -> man 11 (cung chuong 2)")
	var chapter2_ids: Array = lm.call("levels_in_chapter", 2)
	var last_chapter2 := int(chapter2_ids[chapter2_ids.size() - 1]) if not chapter2_ids.is_empty() else -1
	_entry(int(gm.call("next_level_in_chapter", last_chapter2)) == -1,
		"Man %d la man cuoi chuong 2 -> -1" % last_chapter2)

	gm.call("record_level_clear", 9, 3, 12.0)
	_entry(int(gm.get("unlocked_levels")) == 9,
		"Xong man cuoi chuong 1 KHONG tu mo man 10 (chuong 2 chua mo)")
	_entry(not bool(gm.call("can_play_level", 10)), "Man 10 chua choi duoc khi chuong 2 khoa")
	_entry(bool(gm.call("can_play_level", 9)), "Man 9 (chuong 1) van choi duoc")
	_entry(bool(gm.call("has_unlockable_chapter")),
		"27 sao: co chuong du dieu kien mo (chuong 2 can 25)")

	_entry(bool(gm.call("unlock_chapter", 2)), "Mo chuong 2 bang 27 sao")
	gm.call("record_level_clear", 9, 3, 12.0)
	_entry(int(gm.get("unlocked_levels")) >= 10,
		"Sau khi mo chuong 2: xong man 9 moi mo duoc man 10")
	_entry(bool(gm.call("can_play_level", 10)), "Man 10 choi duoc sau khi mo chuong 2")
	_entry(not bool(gm.call("has_unlockable_chapter")),
		"Mo xong chuong 2 (27 < 45) -> khong con chuong nao du dieu kien")


# ---------------------------------------------------------------------------
# 8. Popup thắng màn: nút "MÀN KẾ TIẾP" đổi thành "CHỌN MÀN" khi hết chương
# ---------------------------------------------------------------------------
func _section_8_win_popup(gm: Node) -> void:
	print("[8] Popup thang man...")
	var packed := load("res://nodes/popups/winning.tscn") as PackedScene
	_entry(packed != null, "Load duoc popup winning.tscn")
	if packed == null:
		return
	var base_data := {
		"level": 9, "floor": 9, "grid": "5×5", "time": 12.0, "steps_used": 5, "steps_max": 12,
		"wall_hits": 0, "score": 100, "stars": 3,
	}

	# Hết chương -> nút ghi "CHỌN CHƯƠNG"
	var popup_end: WinningPopup = packed.instantiate()
	root.add_child(popup_end)
	await process_frame
	var end_data := base_data.duplicate()
	end_data["next_available"] = false
	popup_end.open(end_data)
	await process_frame
	var end_label := popup_end.get_node("Panel/Content/Information/Buttons/NextBtn/H/Label") as Label
	_entry(end_label.text == TranslationServer.translate("STR_CHAPTER_SCREEN_TITLE"),
		"Het chuong: nut doi thanh CHON MAN ('%s')" % end_label.text)
	popup_end.queue_free()
	await process_frame

	# Còn màn trong chương -> nút vẫn là "MÀN KẾ TIẾP"
	var popup_mid: WinningPopup = packed.instantiate()
	root.add_child(popup_mid)
	await process_frame
	var mid_data := base_data.duplicate()
	mid_data["next_available"] = true
	popup_mid.open(mid_data)
	await process_frame
	var mid_label := popup_mid.get_node("Panel/Content/Information/Buttons/NextBtn/H/Label") as Label
	_entry(mid_label.text == TranslationServer.translate("STR_BTN_NEXT_LEVEL"),
		"Con man trong chuong: nut van la MAN KE TIEP ('%s')" % mid_label.text)
	var gc_src := FileAccess.get_file_as_string("res://scripts/core/controllers/game_controller.gd")
	_entry(gc_src.contains("next_level_in_chapter"),
		"GameController di tiep trong CUNG CHUONG (khong nhay chuong khac)")
	_entry(gc_src.contains("go_to_levels") or gc_src.contains("return_to_levels"),
		"Het chuong -> quay ve man CHON MAN")
	_entry(gc_src.contains("return_to_levels"),
		"Het chuong -> ve Chon man bang `return_to_levels()` (KHONG day man choi vao lich su)")
	popup_mid.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# 9. Nối dây điều hướng — màn CHỌN CHƯƠNG đã xoá (2026-10-23): Tab chương + khung khoá
#    nằm ngay trong màn Chọn màn, nên KHÔNG còn route `chapters` ở bất kỳ đâu.
# ---------------------------------------------------------------------------
func _section_9_wiring() -> void:
	print("[9] Noi day dieu huong...")
	var nav_src := FileAccess.get_file_as_string("res://scripts/utils/nav.gd")
	_entry(nav_src.contains("const SCENE_LEVELS"), "Nav co route toi man Chon man")
	_entry(not nav_src.contains("goto_chapters") and not nav_src.contains("SCENE_CHAPTERS"),
		"Nav KHONG con route Chon chuong (man da xoa)")
	var sm: Node = root.get_node_or_null("SceneManager")
	_entry(sm != null, "Autoload SceneManager ton tai")
	if sm != null:
		_entry(not sm.get_script().get_script_constant_map().has("SCENE_CHAPTERS"),
			"SceneManager khong con SCENE_CHAPTERS")
		_entry(not sm.has_method("goto_chapters"), "SceneManager khong con goto_chapters()")
	var main_src := FileAccess.get_file_as_string("res://scripts/scenes/main.gd")
	# Ban GOP: khong con nut "CHOI" mo man khac ? bam thang nut man tren ban do
	_entry(main_src.contains("level_section"),
		"Main nhung thang khoi ban do (LevelSection) thay vi mo man Chon man rieng")
	# Ban GOP: ban do nam trong Main ? logic chuyen chuong o `LevelSection`
	var section_src := FileAccess.get_file_as_string("res://scripts/nodes/main/level_section.gd")
	_entry(not section_src.is_empty(), "Co component LevelSection (ban do trong Main)")
	_entry(not section_src.contains("goto_chapters()"),
		"LevelSection KHONG con loi tat sang man Chon chuong")
	_entry(section_src.contains("lock_sheet"),
		"LevelSection doi chuong bang chip + khung khoa (ChapterLockSheet)")
	_entry(section_src.contains("current_chapter"), "LevelSection doc current_chapter")
	_entry(not ResourceLoader.exists("res://scenes/levels.tscn"),
		"Man Chon man rieng (scenes/levels.tscn) da bi xoa")
	_entry(not ResourceLoader.exists("res://scenes/chapters.tscn"),
		"File scenes/chapters.tscn da bi xoa")
	var debug_src := FileAccess.get_file_as_string("res://scripts/scenes/debug.gd")
	_entry(not debug_src.contains("scenes/chapters.tscn"), "Debug Console bo muc chon chuong")
	var gm_src := FileAccess.get_file_as_string("res://scripts/core/game_manager.gd")
	_entry(gm_src.contains("\"unlocked_chapters\""), "GameManager luu unlocked_chapters")
	_entry(not gm_src.contains("func go_to_chapters"), "GameManager khong con go_to_chapters()")
	_entry(gm_src.contains("func go_to_levels"), "GameManager co go_to_levels() (nay ve Main)")
	_entry(gm_src.contains("res://scenes/main.tscn"), "go_to_levels() tro ve Main (Levels da gop)")


func _entry(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("  [PASS] %s" % label)
	else:
		_failed += 1
		print("  [FAIL] %s" % label)
