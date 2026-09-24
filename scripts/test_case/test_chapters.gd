extends SceneTree
## ============================================================================
## Test Case: HỆ THỐNG CHƯƠNG (Chapter Selection) — tính năng 2026-02
##
## 1. Dữ liệu: 4 file resources/chapters/chapter_N.tres -> ChapterData hợp lệ.
## 2. LevelManager: quét chương, gom màn theo chương, đếm Sao/màn đã qua.
## 3. GameManager: tổng Sao, điều kiện mở khóa, mở khóa bằng Sao, chương đang chơi.
## 4. Bền vững: export/import/reset giữ đúng unlocked_chapters + current_chapter.
## 4b. Khoá theo chương: xong màn cuối chương KHÔNG mở màn của chương chưa unlock.
## 5. Thẻ chương: đúng cấu trúc node + 5 trạng thái (đang chơi/đã mở/đủ điều kiện/khóa/sắp ra mắt).
## 6. Màn Chọn Chương: dựng thẻ theo dữ liệu thật, ví Sao, nút tiếp tục, nút Back.
## 7. Màn Chọn màn: lọc theo chương, số Sao THEO CHƯƠNG, CTA theo chương, banner focus.
## 8. Popup thắng màn: nút MÀN KẾ TIẾP đổi thành CHỌN CHƯƠNG khi hết chương.
## 9. Nối dây: Nav/SceneManager/Debug Console + nút CHƠI ở Main.
## ============================================================================

const TITLE := "HỆ THỐNG CHƯƠNG"
const CARD_SCENE_PATH := "res://nodes/chapters/chapter_card.tscn"
const SCENE_PATH := "res://scenes/chapters.tscn"

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
	await _section_5_card()
	await _section_6_scene(lm)
	await _section_7_levels_screen(gm, lm)
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
	_entry(int(gm.call("next_level_in_chapter", 14)) == -1, "Man 14 la man cuoi chuong 2 -> -1")

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
# 5. Thẻ chương (nodes/chapters/chapter_card.tscn)
# ---------------------------------------------------------------------------
func _section_5_card() -> void:
	print("[5] The chuong...")
	var packed := load(CARD_SCENE_PATH) as PackedScene
	_entry(packed != null, "Load duoc %s" % CARD_SCENE_PATH)
	if packed == null:
		return
	var card: ChapterCard = packed.instantiate()
	root.add_child(card)
	await process_frame

	# Mọi node (trừ Halo) nằm TRONG Panel (nền thẻ); khối doodle + chữ nằm trong Content/Display
	for path in ["Halo", "Panel", "Panel/Content", "Panel/Content/Display",
			"Panel/Content/Display/Doodle", "Panel/Content/Display/Doodle/Lock",
			"Panel/Ribbon", "Panel/Ribbon/RibbonLabel",
			"Panel/Content/Display/Info", "Panel/Content/Display/Info/Chip",
			"Panel/Content/Display/Info/Chip/ChipLabel", "Panel/Content/Display/Info/Title",
			"Panel/Content/Display/Info/Subtitle", "Panel/Content/Display/Info/Bar",
			"Panel/Content/Display/Info/Bar/Fill", "Panel/Content/Display/Info/Stats",
			"Panel/Content/Display/Info/Stats/Stars", "Panel/Content/Display/Info/Stats/StarsSub",
			"Panel/Content/Display/Info/HaveChip", "Panel/Content/Display/Info/HaveChip/HaveLabel",
			"Panel/Content/Action", "Panel/Content/Action/Btn", "Panel/Content/Action/Btn/Title",
			"Panel/Content/Action/Btn/Sub", "Panel/Content/Action/Btn/Icon",
			"Panel/Content/Action/Btn/LockIcon", "Panel/Content/Action/NeedChip",
			"Panel/Content/Action/NeedChip/NeedLabel"]:
		_entry(card.get_node_or_null(path) != null, "The co node '%s'" % path)
	_entry((card.get_node("Panel/Content/Action/Btn") as TextureButton).pressed.get_connections().size() >= 1,
		"Nut hanh dong da noi tin hieu pressed trong .tscn")

	var lm: Node = root.get_node_or_null("LevelManager")
	var chapter: ChapterData = lm.call("get_chapter", 2)
	var info := {
		"state": ChapterCard.State.PLAYING, "stars_own": 7, "stars_total": 15,
		"levels_cleared": 2, "levels_total": 5, "star_cost": 25, "total_stars": 30,
		"next_level": 12, "size_tier": "medium",
	}
	card.setup(chapter, info)
	_entry(card.chapter_id == 2, "setup() luu chapter_id = 2")
	_entry(card.state == ChapterCard.State.PLAYING, "Trang thai DANG CHOI")
	_entry((card.get_node("Panel") as TextureRect).texture != null, "The dang choi co nen rieng")
	_entry(not (card.get_node("Halo") as Control).visible, "Dang choi -> khong co hao quang")
	_entry(not (card.get_node("Panel/Content/Display/Doodle/Lock") as Control).visible, "Dang choi -> khong hien o khoa")
	var title := card.get_node("Panel/Content/Display/Info/Title") as Label
	_entry(title.text == TranslationServer.translate("STR_CHAPTER_TITLE_FORMAT").format(
		[chapter.chapter_id, chapter.title]), "Tieu de theo dinh dang 'CHUONG n: Ten'")
	_entry((card.get_node("Panel/Content/Display/Info/Subtitle") as Label).text == chapter.subtitle, "Mo ta lay tu du lieu chuong")
	_entry((card.get_node("Panel/Ribbon/RibbonLabel") as Label).text
		== TranslationServer.translate("STR_CHAPTER_RIBBON_PLAYING"), "Ruy bang = DANG CHOI")
	# Nút chương MỞ: chỗ trống bên trái nút được đặt ICON PLAY
	var play_icon := card.get_node("Panel/Content/Action/Btn/Icon") as TextureRect
	_entry(play_icon.visible, "Nut VÀO CHƠI co icon play (khong de trong)")
	_entry(play_icon.texture == load("res://assets/images/level_selector/icon_play_triangle.svg"),
		"Icon do dung la hinh tam giac play")
	# Ổ khóa lớn phải canh giữa theo doodle (thân khóa nằm trong art 72x72 tai y 30..64)
	var doodle := card.get_node("Panel/Content/Display/Doodle") as TextureRect
	var lock := card.get_node("Panel/Content/Display/Doodle/Lock") as TextureRect
	_entry(absf(lock.position.x + lock.size.x * 0.5 - doodle.size.x * 0.5) <= 1.0,
		"O khoa canh giua theo chieu ngang")
	_entry(absf(lock.position.y + 23.5 - doodle.size.y * 0.5) <= 6.0,
		"Than o khoa trung tam doodle (lech <= 6px)")
	# Chữ to hơn cho dễ đọc
	_entry(title.get_theme_font_size("font_size") >= 20,
		"Tieu de chuong >= 20px (nhan %d)" % title.get_theme_font_size("font_size"))
	_entry((card.get_node("Panel/Content/Display/Info/Subtitle") as Label).get_theme_font_size("font_size") >= 11,
		"Mo ta chuong >= 11px")
	_entry((card.get_node("Panel/Content/Display/Info/Stats/Stars") as Label).text
		== TranslationServer.translate("STR_CHAPTER_STARS_FORMAT").format([7, 15]),
		"Thanh sao hien 7 / 15")
	var fill := card.get_node("Panel/Content/Display/Info/Bar/Fill") as TextureRect
	var bar := card.get_node("Panel/Content/Display/Info/Bar") as Control
	_entry(is_equal_approx(fill.size.x, bar.size.x * 7.0 / 15.0),
		"Thanh sao do dung ti le 7/15 (%.1f/%d)" % [fill.size.x, bar.size.x])
	_entry((card.get_node("Panel/Content/Action/Btn/Title") as Label).text
		== TranslationServer.translate("STR_CHAPTER_PLAY"), "Nut = VAO CHOI")
	_entry((card.get_node("Panel/Content/Action/Btn/Sub") as Label).text
		== TranslationServer.translate("STR_CHAPTER_PLAY_SUB").format([12]),
		"Nhan phu = 'Man 12 >'")
	_entry(not (card.get_node("Panel/Content/Action/Btn") as TextureButton).disabled, "Nut bam duoc")
	_entry(not (card.get_node("Panel/Content/Display/Info/HaveChip") as Control).visible, "Dang choi -> an chip 'da du'")
	_entry(not (card.get_node("Panel/Content/Action/NeedChip") as Control).visible, "Dang choi -> an chip 'con thieu'")

	# Bấm nút -> phát selected(chapter_id)
	var picked: Array = []
	card.selected.connect(func(id: int) -> void: picked.append(id))
	(card.get_node("Panel/Content/Action/Btn") as TextureButton).pressed.emit()
	_entry(picked.size() == 1 and int(picked[0]) == 2, "Bam nut the DANG CHOI -> selected(2)")

	# --- ĐỦ ĐIỀU KIỆN (chờ bấm mở khóa) ---
	var ready := info.duplicate()
	ready["state"] = ChapterCard.State.READY
	ready["stars_own"] = 0
	ready["total_stars"] = 30
	card.setup(chapter, ready)
	_entry(card.state == ChapterCard.State.READY, "Trang thai DU DIEU KIEN")
	_entry((card.get_node("Halo") as Control).visible, "Du dieu kien -> hien hao quang net dut")
	_entry((card.get_node("Panel/Content/Display/Info/HaveChip") as Control).visible, "Du dieu kien -> hien chip 'DA DU: 30 / 25 SAO'")
	_entry((card.get_node("Panel/Content/Display/Info/HaveChip/HaveLabel") as Label).text
		== TranslationServer.translate("STR_CHAPTER_HAVE_FORMAT").format([30, 25]),
		"Noi dung chip 'da du' dung dinh dang")
	_entry((card.get_node("Panel/Content/Action/Btn/Title") as Label).text
		== TranslationServer.translate("STR_CHAPTER_UNLOCK"), "Nut = MO KHOA")
	_entry((card.get_node("Panel/Content/Action/Btn/Icon") as Control).visible, "Nut mo khoa co icon ngoi sao")
	_entry((card.get_node("Panel/Content/Action/Btn/Icon") as TextureRect).texture
		== load("res://assets/images/chapters/icon_star_white.svg"),
		"Icon nut MO KHOA la ngoi sao TRANG (khong bi chim mau)")
	_entry(not (card.get_node("Panel/Content/Action/Btn/LockIcon") as Control).visible,
		"The du dieu kien khong hien o khoa trong nut")
	_entry(not (card.get_node("Panel/Content/Display/Info/Bar") as Control).visible, "Du dieu kien -> an thanh tien do")
	_entry(not (card.get_node("Panel/Content/Action/Btn") as TextureButton).disabled, "Nut mo khoa bam duoc")
	var unlocks: Array = []
	card.unlock_requested.connect(func(id: int) -> void: unlocks.append(id))
	(card.get_node("Panel/Content/Action/Btn") as TextureButton).pressed.emit()
	_entry(unlocks.size() == 1 and int(unlocks[0]) == 2, "Bam nut the DU DIEU KIEN -> unlock_requested(2)")

	# --- ĐANG KHÓA ---
	var locked := info.duplicate()
	locked["state"] = ChapterCard.State.LOCKED
	locked["total_stars"] = 12
	card.setup(chapter, locked)
	_entry(card.state == ChapterCard.State.LOCKED, "Trang thai DANG KHOA")
	_entry((card.get_node("Panel/Content/Display/Doodle/Lock") as Control).visible, "Dang khoa -> hien o khoa tren doodle")
	_entry((card.get_node("Panel") as TextureRect).texture
		== load("res://assets/images/chapters/card_locked.svg"), "Dang khoa -> nen giay xam")
	_entry((card.get_node("Panel/Content/Action/Btn") as TextureButton).disabled, "Nut bi khoa")
	# Ổ khóa trong nút KHÔNG được đè lên chữ (lỗi cũ: chữ bị cắt "CẦN 45")
	var action_title := card.get_node("Panel/Content/Action/Btn/Title") as Label
	var action_icon := card.get_node("Panel/Content/Action/Btn/LockIcon") as Control
	_entry(action_icon.visible, "Nut bi khoa co icon o khoa ben trai")
	_entry(action_icon.position.x + action_icon.size.x <= action_title.position.x,
		"Icon o khoa khong de len chu nut (icon ket thuc %.0f <= chu bat dau %.0f)" % [
			action_icon.position.x + action_icon.size.x, action_title.position.x])
	_entry((card.get_node("Panel/Content/Action/Btn/Title") as Label).get_theme_font_size("font_size") >= 12,
		"Chu tren nut >= 12px")
	_entry((card.get_node("Panel/Content/Action/NeedChip") as Control).visible, "Hien chip 'con thieu'")
	_entry((card.get_node("Panel/Content/Action/NeedChip/NeedLabel") as Label).text
		== TranslationServer.translate("STR_CHAPTER_NEED_FORMAT").format([13]),
		"Chip bao con thieu 13 sao (25 - 12)")
	_entry((card.get_node("Panel/Content/Display/Info/Stats/Stars") as Label).text
		== TranslationServer.translate("STR_CHAPTER_STARS_FORMAT").format([12, 25]),
		"Thanh tien do mo khoa: 12 / 25 sao")
	_entry((card.get_node("Panel/Ribbon/RibbonLabel") as Label).text
		== TranslationServer.translate("STR_CHAPTER_RIBBON_LOCKED"), "Ruy bang = DANG KHOA")

	# --- SẮP RA MẮT ---
	var coming := info.duplicate()
	coming["state"] = ChapterCard.State.COMING
	coming["levels_total"] = 0
	card.setup(chapter, coming)
	_entry(card.state == ChapterCard.State.COMING, "Trang thai SAP RA MAT")
	_entry((card.get_node("Panel/Content/Action/Btn") as TextureButton).disabled, "Sap ra mat -> nut bi khoa")
	_entry((card.get_node("Panel/Content/Action/Btn/Title") as Label).text
		== TranslationServer.translate("STR_CHAPTER_RIBBON_COMING"), "Nut = SAP RA MAT")
	card.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# 6. Màn Chọn Chương (scenes/chapters.tscn)
# ---------------------------------------------------------------------------
func _section_6_scene(lm: Node) -> void:
	print("[6] Man CHON CHUONG...")
	# Trạng thái XÁC ĐỊNH để kiểm tra đủ 4 thẻ: chương 1 đang chơi, chương 2 đã mở, 3-4 còn khóa
	var gm: Node = root.get_node_or_null("GameManager")
	gm.call("reset_progress")
	var stars: Dictionary = gm.get("level_stars")
	for level_id in lm.call("levels_in_chapter", 1):
		stars[int(level_id)] = 3
	stars[10] = 3                                   # 30 sao: đủ mở chương 2 (25), chưa đủ chương 3 (45)
	gm.set("current_level", 3)
	gm.call("set_chapter", 1)
	_entry(bool(gm.call("unlock_chapter", 2)), "Mo chuong 2 bang 30 sao (chuan bi kiem tra the)")

	var packed := load(SCENE_PATH) as PackedScene
	_entry(packed != null, "Load duoc %s" % SCENE_PATH)
	if packed == null:
		return
	var scene: ChaptersScene = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	_entry(scene.ui_path("TopBar/Back") is TextureButton, "Co nut Back o TopBar")
	var title := scene.ui_path("TopBar/Title") as Label
	_entry(title != null and title.text == "STR_CHAPTER_SCREEN_TITLE",
		"Tieu de man dung khoa dich STR_CHAPTER_SCREEN_TITLE")
	_entry(scene.layout.wallet_bar is TextureRect, "Co vi Sao goc phai")
	_entry(scene.ui_child("Wallet", "Star") is TextureRect, "Vi Sao co icon ngoi sao")
	_entry(scene.ui_path("Banner/Text") is Label, "Co bang huong dan Banner/Text")
	_entry((scene.ui_path("Banner/Text") as Label).text == "STR_CHAPTER_BANNER",
		"Bang huong dan dung khoa dich STR_CHAPTER_BANNER")
	_entry(scene.ui_path("List/Cards") is VBoxContainer, "Co danh sach the List/Cards")
	_entry(scene.layout.btn_continue is BaseButton, "Co nut CTA chan trang")
	_entry((scene.ui_path("List/Cards") as Node).get_child_count()
		== int(lm.call("chapter_count")),
		"Danh sach co dung %d the chuong" % lm.call("chapter_count"))
	_entry(scene.card_count() == int(lm.call("chapter_count")),
		"card_count() = %d" % scene.card_count())
	_entry(scene.card_for(1) != null, "card_for(1) tra ve the chuong 1")
	_entry(scene.card_for(99) == null, "card_for(99) = null")
	_entry(scene.card_at(0) != null and scene.card_at(0).chapter_id == 1, "The dau tien la chuong 1")
	_entry(scene.card_at(-1) == null, "card_at(-1) an toan -> null")

	var playing: int = scene.playing_chapter_id()
	_entry(playing >= 1, "playing_chapter_id() = %d" % playing)
	var card := scene.card_for(playing)
	_entry(card != null and card.state == ChapterCard.State.PLAYING,
		"The cua chuong dang choi o trang thai DANG CHOI")
	_entry(card != null and (card.get_node("Panel/Ribbon/RibbonLabel") as Label).text
		== TranslationServer.translate("STR_CHAPTER_RIBBON_PLAYING"),
		"Ruy bang chuong dang choi = DANG CHOI")
	var opened := scene.card_for(2)
	_entry(opened != null and opened.state == ChapterCard.State.PLAYING,
		"Chuong 2 da mo -> the van bam duoc")
	# Mỗi chương 1 ICON khác nhau (dễ nhận biết)
	var icon_1 := (scene.card_for(1).get_node("Panel/Content/Display/Doodle") as TextureRect).texture
	var icon_2 := (opened.get_node("Panel/Content/Display/Doodle") as TextureRect).texture
	var icon_3 := (scene.card_for(3).get_node("Panel/Content/Display/Doodle") as TextureRect).texture
	_entry(icon_1 != icon_2 and icon_2 != icon_3 and icon_1 != icon_3,
		"Icon 3 chuong khac nhau")
	_entry(icon_1 == load("res://assets/images/chapters/icon_intro.svg"),
		"Chuong 1 dung icon 'intro'")
	_entry(icon_2 == load("res://assets/images/chapters/icon_logic.svg"),
		"Chuong 2 dung icon 'logic'")
	_entry(opened != null and (opened.get_node("Panel/Ribbon/RibbonLabel") as Label).text
		== TranslationServer.translate("STR_CHAPTER_RIBBON_OPEN"),
		"Ruy bang chuong 2 (da mo, khong phai dang choi) = DA MO")
	_entry(opened != null and (opened.get_node("Panel/Content/Action/Btn/Title") as Label).text
		== TranslationServer.translate("STR_CHAPTER_PLAY"), "Chuong 2 co nut VAO CHOI")
	for locked_id in [3, 4]:
		var locked_card := scene.card_for(locked_id)
		_entry(locked_card != null and locked_card.state == ChapterCard.State.LOCKED,
			"Chuong %d thieu sao -> the DANG KHOA" % locked_id)
		_entry(locked_card != null and (locked_card.get_node("Panel/Content/Action/Btn") as TextureButton).disabled,
			"Chuong %d: nut bi khoa, khong bam duoc" % locked_id)
	var playable := 0
	for index in scene.card_count():
		var each := scene.card_at(index)
		if each != null and each.state == ChapterCard.State.PLAYING:
			playable += 1
	_entry(playable == 2, "Dung 2 the bam duoc (chuong 1 dang choi + chuong 2 da mo) — nhan %d" % playable)

	var wallet_count := scene.ui_child("Wallet", "Count") as Label
	_entry(wallet_count != null and wallet_count.text == str(int(gm.call("total_stars"))),
		"Vi Sao hien tong sao hien co (%s)" % (wallet_count.text if wallet_count != null else "<null>"))
	var cta := scene.ui_child("ContinueButton", "Label") as Label
	_entry(cta != null and cta.text.contains(str(playing)),
		"Nhan CTA nhac toi chuong dang choi (%s)" % (cta.text if cta != null else "<null>"))
	var cta_icon := scene.ui_child("ContinueButton", "Icon") as TextureRect
	_entry(cta_icon != null and cta_icon.texture != null, "CTA co icon tam giac")
	_entry((scene.ui_path("List/Cards") as VBoxContainer).get_theme_constant("separation") == 15,
		"Khoang cach giua cac the = 15px")
	# Mọi thẻ đều nối tín hiệu tới màn
	var connected := true
	for index in scene.card_count():
		var each := scene.card_at(index)
		if each == null or each.selected.get_connections().is_empty() \
				or each.unlock_requested.get_connections().is_empty():
			connected = false
	_entry(connected, "Moi the deu noi selected + unlock_requested toi man")
	scene.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# 7. Màn Chọn màn lọc theo chương
# ---------------------------------------------------------------------------
func _section_7_levels_screen(gm: Node, lm: Node) -> void:
	print("[7] Man Chon man loc theo chuong...")
	var packed := load("res://scenes/levels.tscn") as PackedScene
	_entry(packed != null, "Load duoc scenes/levels.tscn")
	if packed == null:
		return
	gm.call("set_chapter", 2)
	var scene: LevelScenes = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var ids: Array = scene.level_ids()
	_entry(ids.size() == int(lm.call("levels_in_chapter", 2).size()),
		"Man chuong 2 hien %d man (tong %d)" % [ids.size(), lm.call("levels_in_chapter", 2).size()])
	var all_in_chapter := true
	for level_id in ids:
		if int(lm.call("chapter_of_level", level_id)) != 2:
			all_in_chapter = false
	_entry(all_in_chapter, "Moi the man deu thuoc chuong 2")
	_entry(scene.chapter_title().contains(lm.call("get_chapter", 2).title),
		"Banner man hinh hien ten chuong ('%s')" % scene.chapter_title())
	_entry(scene.page_count() >= 1, "So trang >= 1 (%d)" % scene.page_count())
	_entry(scene.chapter_continue_level() == 11,
		"Man tiep theo TRONG chuong 2 = man chua dat sao dau tien (11) — nhan %d"
			% scene.chapter_continue_level())
	_entry(not scene.chapter_cleared(), "Chuong 2 chua hoan thanh het")
	_entry(scene.layout.lbl_change_chapter is Label,
		"Banner co dong 'DOI CHUONG'")
	var banner_node := scene.layout.banner
	_entry(banner_node != null and banner_node.gui_input.get_connections().size() >= 1,
		"Bam CA PANEL banner -> sang man Chon Chuong (co noi gui_input)")
	_entry(scene.layout.btn_back is BaseButton, "Man chon man co nut Back")

	# --- Số Sao hiển thị phải là CỦA CHƯƠNG đang xem (không cộng Sao chương khác) ---
	gm.call("reset_progress")
	var chapter_stars: Dictionary = gm.get("level_stars")
	for level_id in lm.call("levels_in_chapter", 1):
		chapter_stars[int(level_id)] = 3
	chapter_stars[3] = 0                        # màn 3 CHƯA đạt sao -> xong chương = false
	for level_id in lm.call("levels_in_chapter", 2):
		chapter_stars[int(level_id)] = 1        # 5 sao thuộc chương 2 (không được cộng vào ô đếm)
	gm.call("set_chapter", 1)
	var scene2: LevelScenes = packed.instantiate()
	root.add_child(scene2)
	await process_frame
	await process_frame
	var count := scene2.ui("Count") as Label
	_entry(count.text == "24/27",
		"So Sao theo CHUONG 1 = 24/27 (loi cu: cong ca chuong khac) — nhan '%s'" % count.text)
	_entry(scene2.chapter_continue_level() == 3,
		"Man tiep theo TRONG chuong 1 = man CHUA dat sao dau tien (3) — nhan %d"
			% scene2.chapter_continue_level())
	_entry(not scene2.chapter_cleared(), "Chuong 1 chua hoan thanh (con man 3)")
	_entry(_banner_texture(scene2)
		== load("res://assets/images/level_selector/chapter_banner_focus.svg"),
		"Banner doi sang art FOCUS khi co chuong du Sao de mo")
	_entry(scene2.layout.lbl_change_chapter.text
		== TranslationServer.translate("STR_CHAPTER_UNLOCKABLE"),
		"Dong tren banner bao 'co Chuong moi co the mo khoa'")
	_entry(scene2.layout.banner.modulate == Color.WHITE,
		"Banner focus giu nguyen mau (chi doi art + nhap nhay)")
	scene2.queue_free()
	await process_frame

	# --- Xong HẾT chương 1 -> nút chân trang đổi thành CHỌN CHƯƠNG ---
	for level_id in lm.call("levels_in_chapter", 1):
		chapter_stars[int(level_id)] = 3
	var scene3: LevelScenes = packed.instantiate()
	root.add_child(scene3)
	await process_frame
	await process_frame
	_entry(scene3.chapter_cleared(), "Chuong 1 da hoan thanh het man")
	_entry((scene3.ui("Count") as Label).text == "27/27",
		"Chuong 1 xong: 27/27 Sao")
	var cta3 := scene3.ui_child("ContinueButton", "Label") as Label
	_entry(cta3 != null and cta3.text == TranslationServer.translate("STR_CHAPTER_SCREEN_TITLE"),
		"Nut chan trang doi thanh CHON CHUONG khi xong het chuong")
	scene3.queue_free()
	await process_frame

	# --- Mở chương 2 rồi -> banner trở về art thường ---
	gm.call("unlock_chapter", 2)
	var scene4: LevelScenes = packed.instantiate()
	root.add_child(scene4)
	await process_frame
	await process_frame
	_entry(_banner_texture(scene4)
		== load("res://assets/images/level_selector/chapter_banner.svg"),
		"Mo chuong roi -> banner ve art thuong")
	_entry((scene4.ui_path("ChapterBanner/TitleContainer/ChangeChapter") as Label).text
		== TranslationServer.translate("STR_CHANGE_CHAPTER"), "Dong banner ve 'DOI CHUONG'")
	scene4.queue_free()
	await process_frame

	scene.queue_free()
	await process_frame
	gm.call("set_chapter", 1)


# ---------------------------------------------------------------------------
# 8. Popup thắng màn: nút "MÀN KẾ TIẾP" đổi thành "CHỌN CHƯƠNG" khi hết chương
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
	var end_label := popup_end.get_node("Panel/Content/NextBtn/Label") as Label
	_entry(end_label.text == TranslationServer.translate("STR_CHAPTER_SCREEN_TITLE"),
		"Het chuong: nut doi thanh CHON CHUONG ('%s')" % end_label.text)
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
	var mid_label := popup_mid.get_node("Panel/Content/NextBtn/Label") as Label
	_entry(mid_label.text == TranslationServer.translate("STR_BTN_NEXT_LEVEL"),
		"Con man trong chuong: nut van la MAN KE TIEP ('%s')" % mid_label.text)
	var gc_src := FileAccess.get_file_as_string("res://scripts/core/controllers/game_controller.gd")
	_entry(gc_src.contains("next_level_in_chapter"),
		"GameController di tiep trong CUNG CHUONG (khong nhay chuong khac)")
	_entry(gc_src.contains("go_to_chapters"), "Het chuong -> chuyen sang man Chon Chuong")
	popup_mid.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# 9. Nối dây điều hướng
# ---------------------------------------------------------------------------
func _section_9_wiring() -> void:
	print("[9] Noi day dieu huong...")
	_entry(Nav.SCENE_CHAPTERS == SCENE_PATH, "Nav.SCENE_CHAPTERS tro dung scenes/chapters.tscn")
	var nav_src := FileAccess.get_file_as_string("res://scripts/utils/nav.gd")
	_entry(nav_src.contains("func goto_chapters"), "Nav co ham goto_chapters()")
	var sm: Node = root.get_node_or_null("SceneManager")
	_entry(sm != null, "Autoload SceneManager ton tai")
	if sm != null:
		_entry(sm.get_script().get_script_constant_map().get("SCENE_CHAPTERS", "") == SCENE_PATH,
			"SceneManager.SCENE_CHAPTERS tro dung scenes/chapters.tscn")
		_entry(sm.has_method("goto_chapters"), "SceneManager co goto_chapters()")
	var main_src := FileAccess.get_file_as_string("res://scripts/scenes/main.gd")
	_entry(main_src.contains("go_to_levels") or main_src.contains("goto_levels"),
		"Nut CHOI o Main vao thang man Chon man (khong qua Chon Chuong)")
	var levels_src := FileAccess.get_file_as_string("res://scripts/scenes/levels.gd")
	_entry(levels_src.contains("_on_banner_input") and levels_src.contains("Nav.goto_chapters()"),
		"Bam banner o man Chon man -> man Chon Chuong")
	_entry(levels_src.contains("go_to_main") or levels_src.contains("goto_main"),
		"Back o man Chon man -> Main")
	var chapters_src := FileAccess.get_file_as_string("res://scripts/scenes/chapters.gd")
	_entry(chapters_src.contains("Nav.goto_levels()"),
		"Back o man Chon Chuong -> man Chon man")
	_entry(levels_src.contains("current_chapter"), "Man Chon man doc current_chapter")
	var debug_src := FileAccess.get_file_as_string("res://scripts/scenes/debug.gd")
	_entry(debug_src.contains("scenes/chapters.tscn"), "Debug Console co muc chon chuong")
	var gm_src := FileAccess.get_file_as_string("res://scripts/core/game_manager.gd")
	_entry(gm_src.contains("\"unlocked_chapters\""), "GameManager luu unlocked_chapters")
	_entry(gm_src.contains("func go_to_chapters"), "GameManager co go_to_chapters()")


# ---------------------------------------------------------------------------
# Harness
# ---------------------------------------------------------------------------
## Banner chương là TextureRect (bản dọc) hoặc NinePatchRect (bản ngang đã 9-slice)
## ⇒ đọc texture qua `get()` thay vì ép kiểu, để test chạy được ở CẢ 2 layout.
func _banner_texture(scene: Node) -> Texture2D:
	var layout: Node = scene.get("layout")
	var banner: Control = layout.banner as Control if layout != null else null
	if banner == null:
		return null
	return banner.get("texture") as Texture2D


func _entry(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("  [PASS] %s" % label)
	else:
		_failed += 1
		print("  [FAIL] %s" % label)
