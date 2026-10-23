extends SceneTree
## ============================================================================
## Test Case: MÀN CHỌN MÀN (bản dọc) THEO `AI_GUIDE_level_screen.md`
##
## 1. Hàng TAB chương: dựng đủ tab từ `LevelManager.get_chapters()`, đúng trạng thái
##    (SELECTED / OPEN / LOCKED / COMING), bấm tab mở ⇒ đổi chương TẠI CHỖ.
## 2. Khung "CHƯƠNG ĐANG KHOÁ": mở khi bấm tab khoá; nút MỞ KHÓA chỉ bật khi đủ Sao;
##    mở khoá xong thì `unlocked_chapters` có chương đó và Sao KHÔNG bị trừ.
## 3. Bản đồ kiểu RẮN: 3 cột, hàng 0 ở đáy, hàng lẻ chạy ngược — kiểm với 9 và 14 màn.
## 4. Rương chương nhận qua màn Chọn màn (widget `reward_bar()`), vẫn phát signal.
## 5. Chương đã xong ⇒ thẻ chân màn đổi sang "HOÀN THÀNH CHƯƠNG" + nút "CHƯƠNG TIẾP ›".
## 6. Đổi hướng màn hình: dữ liệu (chương đang chọn, số Sao, rương) giữ nguyên.
## ============================================================================

const SCENE_PATH := "res://scenes/levels.tscn"

var _backup := ""
var _checks := 0
var _failed := 0
var _saved := {}


func _init() -> void:
	print("\n========================================================")
	print("  TEST: MAN CHON MAN (BAN DOC) — TAB / KHOA / BAN DO RAN")
	print("========================================================\n")

	await process_frame
	root.size = Vector2i(1080, 1920)

	if FileAccess.file_exists("user://inkmaze_data.json"):
		_backup = FileAccess.get_file_as_string("user://inkmaze_data.json")

	var gm: Node = root.get_node_or_null("GameManager")
	var lm: Node = root.get_node_or_null("LevelManager")
	_check(gm != null and lm != null, "Autoload GameManager + LevelManager ton tai")
	if gm == null or lm == null:
		_finish()
		return
	_saved = gm.call("export_progress")

	await _section_tabs(gm, lm)
	await _section_lock_sheet(gm, lm)
	_section_snake(gm, lm)
	await _section_next_card(gm, lm)
	await _section_orientation(gm, lm)

	_finish()


# ---------------------------------------------------------------------------
# 1. Hàng tab chương
# ---------------------------------------------------------------------------
func _section_tabs(gm: Node, lm: Node) -> void:
	print("[1] Hang tab chuong...")
	gm.call("reset_progress")
	gm.set("current_chapter", 1)
	gm.set("current_level", 1)
	gm.set("unlocked_levels", 9)
	var chapters: Array = lm.call("get_chapters")
	_check(chapters.size() > 0, "LevelManager co chuong (%d)" % chapters.size())

	var scene: Node = (load(SCENE_PATH) as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var layout = scene.get("layout")
	_check(layout != null and layout.tabs != null, "Bo cuc doc co hang tab chuong")
	var tabs: ChapterTabs = layout.tabs
	_check(tabs != null and tabs.tab_count() == chapters.size(),
		"So tab = so chuong (%d)" % (tabs.tab_count() if tabs != null else -1))

	# Chương 1 luôn mở và đang chọn
	var tab1: ChapterTab = tabs.tab_for(1)
	_check(tab1 != null and tab1.state == ChapterTab.State.SELECTED, "Chuong 1 = SELECTED")
	_check(tabs.selected_id() == 1, "Tab dang chon = chuong 1")

	# Chương chưa đủ Sao ⇒ LOCKED (hoặc COMING nếu không có màn)
	var tab2: ChapterTab = tabs.tab_for(2)
	_check(tab2 != null, "Co tab chuong 2")
	if tab2 != null:
		var expect_locked := tab2.state == ChapterTab.State.LOCKED \
			or tab2.state == ChapterTab.State.COMING
		_check(expect_locked, "Chuong 2 chua mo -> LOCKED/COMING (dang %s)" % tab2.state)
		_check(not tab2.is_selected(), "Tab 2 khong phai tab dang chon")

	# COMING: chương không có màn nào ⇒ không bấm được
	var coming_found := false
	for chapter_v in chapters:
		var chapter := chapter_v as ChapterData
		var tab := tabs.tab_for(chapter.chapter_id)
		if tab != null and tab.state == ChapterTab.State.COMING:
			coming_found = true
			_check(tab.disabled, "Tab COMING (chuong %d) bi vo hieu" % chapter.chapter_id)
	_check(true, "Kiem tra trang thai COMING (co %s)" % ("co" if coming_found else "khong"))

	# Bấm tab ĐÃ MỞ (mở chương 2 bằng API) ⇒ đổi chương TẠI CHỖ, không đổi scene
	var unlock_stars: Dictionary = {}
	for level_id in lm.call("get_level_ids"):
		unlock_stars[int(level_id)] = 3
	gm.set("level_stars", unlock_stars)
	var unlocked_ok := bool(gm.call("unlock_chapter", 2))
	_check(unlocked_ok, "Mo khoa duoc chuong 2 de test tab OPEN")
	tabs.setup(chapters, 1)
	await process_frame
	var tab2b: ChapterTab = tabs.tab_for(2)
	if tab2b != null and tab2b.state != ChapterTab.State.COMING:
		_check(tab2b.state == ChapterTab.State.OPEN, "Chuong 2 da mo -> tab OPEN")
		var scene_before = current_scene
		tab2b.pressed.emit()
		await process_frame
		await process_frame
		_check(int(gm.get("current_chapter")) == 2, "Bam tab 2 -> current_chapter = 2")
		_check(current_scene == scene_before, "Doi tab KHONG doi scene")

	# Bấm tab KHOÁ ⇒ phát `locked_chapter_requested` (không đổi chương)
	var locked_id := 0
	for chapter_v in chapters:
		var chapter := chapter_v as ChapterData
		var tab := tabs.tab_for(chapter.chapter_id)
		if tab != null and tab.state == ChapterTab.State.LOCKED:
			locked_id = chapter.chapter_id
			break
	if locked_id > 0:
		var received: Array[int] = []
		tabs.locked_chapter_requested.connect(func(id: int): received.append(id))
		tabs.tab_for(locked_id).pressed.emit()
		await process_frame
		_check(received == [locked_id], "Bam tab khoa -> locked_chapter_requested(%d)" % locked_id)
		_check(int(gm.get("current_chapter")) == 2, "Bam tab khoa KHONG doi current_chapter")

	scene.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# 2. Khung "chương đang khoá"
# ---------------------------------------------------------------------------
func _section_lock_sheet(gm: Node, lm: Node) -> void:
	print("[2] Khung chuong dang khoa...")
	gm.call("reset_progress")
	gm.set("current_chapter", 1)
	gm.set("current_level", 1)
	gm.set("unlocked_levels", 9)
	gm.set("unlocked_chapters", [1])
	gm.set("level_stars", {1: 3})
	var chapter2 := lm.call("get_chapter", 2) as ChapterData
	_check(chapter2 != null, "Co du lieu chuong 2")
	if chapter2 == null:
		return

	var scene: Node = (load(SCENE_PATH) as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var layout = scene.get("layout")
	var sheet: ChapterLockSheet = layout.lock_sheet
	_check(sheet != null, "Man Chon man co khung chuong khoa")
	if sheet == null:
		scene.queue_free()
		await process_frame
		return

	# Thiếu Sao: nút MỞ KHÓA bị vô hiệu, nhãn "Chưa đủ sao"
	sheet.open_chapter(2)
	await process_frame
	_check(sheet.is_open(), "Mo duoc khung chuong 2")
	_check(sheet.btn_unlock != null and sheet.btn_unlock.disabled,
		"Thieu Sao -> nut MO KHOA vo hieu")
	_check(sheet.lbl_unlock != null
		and sheet.lbl_unlock.text == tr("STR_CHAPTER_NOT_ENOUGH"),
		"Nhan nut = 'Chua du sao' ('%s')" % (sheet.lbl_unlock.text if sheet.lbl_unlock else ""))
	_check(sheet.lbl_require != null and sheet.lbl_require.text.contains(str(chapter2.star_cost)),
		"Dong 'CAN n SAO' dung (%s)" % (sheet.lbl_require.text if sheet.lbl_require else ""))
	# Bấm MỞ KHÓA khi thiếu ⇒ không mở
	var unlocked_flag: Array[int] = []
	sheet.unlock_requested.connect(func(id: int): unlocked_flag.append(id))
	sheet.btn_unlock.pressed.emit()
	await process_frame
	_check(not bool(gm.call("is_chapter_unlocked", 2)), "Thieu Sao -> bam MO KHOA khong mo duoc")

	# Đủ Sao: bật nút, mở khoá được, Sao KHÔNG bị trừ
	var stars_needed := chapter2.star_cost
	var stars: Dictionary = {}
	var level_ids: Array = lm.call("get_level_ids")
	var per_level := 3
	var need_levels := ceili(float(stars_needed) / float(per_level))
	var i := 0
	for level_id in level_ids:
		if i >= need_levels:
			break
		stars[int(level_id)] = 3
		i += 1
	gm.set("level_stars", stars)
	var total_before := int(gm.call("total_stars"))
	_check(total_before >= stars_needed,
		"Da chuan bi %d sao (can %d)" % [total_before, stars_needed])
	sheet.open_chapter(2)
	await process_frame
	_check(sheet.btn_unlock != null and not sheet.btn_unlock.disabled,
		"Du Sao -> nut MO KHOA bat")
	_check(sheet.lbl_unlock != null and sheet.lbl_unlock.text == tr("STR_CHAPTER_UNLOCK"),
		"Nhan nut = 'Mo khoa'")
	unlocked_flag.clear()
	sheet.btn_unlock.pressed.emit()
	await process_frame
	await process_frame
	_check(bool(gm.call("is_chapter_unlocked", 2)), "Du Sao -> mo khoa duoc chuong 2")
	_check(int(gm.call("total_stars")) == total_before,
		"Sao KHONG bi tru khi mo khoa (%d -> %d)" % [total_before, int(gm.call("total_stars"))])
	_check(int(gm.get("current_chapter")) == 2, "Mo khoa xong chuyen sang chuong 2")
	_check(not sheet.is_open(), "Mo khoa xong khung tu dong")

	scene.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# 3. Bản đồ kiểu RẮN
# ---------------------------------------------------------------------------
func _section_snake(gm: Node, lm: Node) -> void:
	print("[3] Ban do kieu RAN (3 cot)...")
	var scene: Node = (load(SCENE_PATH) as PackedScene).instantiate()
	root.add_child(scene)
	var map: LevelMap = scene.get("map")
	_check(map != null, "Man Chon man co LevelMap")
	if map == null:
		scene.queue_free()
		return
	_check(map.effective_columns() == 3, "Ban doc dung 3 cot (%d)" % map.effective_columns())

	# 9 màn: 3 hàng × 3 cột, hàng 0 ở ĐÁY, hàng lẻ chạy ngược
	var ids9: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8, 9]
	map.build(ids9, {}, 9, 5)
	var expected9 := [
		Vector2(0, 0), Vector2(1, 0), Vector2(2, 0),
		Vector2(2, -1), Vector2(1, -1), Vector2(0, -1),
		Vector2(0, -2), Vector2(1, -2), Vector2(2, -2),
	]
	var ok9 := true
	var base_x := map.node_for(1).position.x
	var base_y := map.node_for(1).position.y
	for index in ids9.size():
		var node := map.node_for(ids9[index])
		var rel := Vector2(
			roundf((node.position.x - base_x) / map.column_spacing),
			roundf((node.position.y - base_y) / map.row_spacing))
		if rel != expected9[index]:
			ok9 = false
			print("    lech o man %d: %s (muon %s)" % [ids9[index], str(rel), str(expected9[index])])
	_check(ok9, "9 man: xep 3 cot kieu ran dung (hang 0 duoi, hang le chay nguoc)")

	# 14 màn: hàng 4 có 2 màn, vẫn giữ kiểu rắn
	var ids14: Array[int] = []
	for i in range(1, 15):
		ids14.append(i)
	map.build(ids14, {}, 14, 12)
	_check(map.node_count() == 14, "Nap 14 man (%d)" % map.node_count())
	var n13 := map.node_for(13)
	var n14 := map.node_for(14)
	_check(n13 != null and n14 != null, "Co nut man 13 va 14")
	if n13 != null and n14 != null:
		_check(roundf((n13.position.y - base_y) / map.row_spacing) == -4.0,
			"Man 13 nam o hang thu 5 (y lech %d)" % int(n13.position.y - base_y))
		_check(roundf((n14.position.x - n13.position.x) / map.column_spacing) == 1.0,
			"Man 14 nam CANH man 13 (hang 4 chan => chay xuoi)")
	# Cuộn được tới màn hiện tại
	map.scroll_to(14, false)
	_check(map.node_for(14) != null, "Cuon toi man 14 khong loi")

	scene.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# 4 + 5. Rương qua màn Chọn màn + thẻ chân màn
# ---------------------------------------------------------------------------
func _section_next_card(gm: Node, lm: Node) -> void:
	print("[4] Ruong + the chan man...")
	gm.call("reset_progress")
	gm.set("current_chapter", 1)
	gm.set("current_level", 1)
	gm.set("unlocked_levels", 9)
	gm.set("unlocked_chapters", [1])
	var level_ids: Array = lm.call("levels_in_chapter", 1)
	# 10 sao: đủ rương 1 (9★), chưa đủ rương 2 (18★); còn màn chưa xong ⇒ thẻ "màn tiếp theo"
	var stars: Dictionary = {}
	for id in level_ids:
		stars[int(id)] = 1
	stars[int(level_ids[0])] = 2
	stars[int(level_ids[level_ids.size() - 1])] = 0
	gm.set("level_stars", stars)

	var scene: Node = (load(SCENE_PATH) as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var layout = scene.get("layout")
	var bar: ChapterProgress = scene.call("progress_widget")
	_check(bar != null, "Man Chon man co thanh thuong chuong")
	if bar != null:
		_check(bar.vertical, "Ban doc dung thanh thuong DOC (%s)" % bar.vertical)
		var chips := bar.chip_list()
		_check(chips.size() == 3, "Co 3 ruong tren thanh doc")
		if chips.size() == 3:
			_check(chips[0].threshold == 9 and chips[1].threshold == 18 and chips[2].threshold == 27,
				"Nguong ruong 9 / 18 / 27")
			_check(chips[0].position.y > chips[2].position.y,
				"Ruong 9* nam DUOI ruong 27* (thanh doc: 0* o day)")
			_check(chips[0].is_claimable(), "Du 9 sao -> ruong 1 bam duoc")
			var coins_before: int = Archivement.coins()
			chips[0].pressed.emit()
			await process_frame
			await process_frame
			_check(Archivement.coins() == coins_before + 50, "Bam ruong 1 o man Chon man -> +50 Xu")
			_check(bool(gm.call("is_chapter_chest_claimed", 1, 0)), "GameManager ghi nhan ruong 1")
			await create_timer(0.4).timeout
			Popups.close_all()
			await create_timer(0.4).timeout

	var card: NextLevelCard = layout.next_card
	_check(card != null, "Man Chon man co the chan man")
	if card != null:
		_check(not card.cleared, "Chuong chua xong -> the 'MAN TIEP THEO'")
		_check(card.title_label != null and card.title_label.text == tr("STR_LEVEL_NEXT_CARD_TITLE"),
			"Tieu de the = 'MAN TIEP THEO' ('%s')" % (card.title_label.text if card.title_label else ""))
		_check(card.lbl_play != null and card.lbl_play.text == tr("STR_LEVEL_PLAY"),
			"Nhan nut = 'CHOI'")
		_check(card.level_id == int(scene.call("chapter_continue_level")),
			"The tro dung man tiep theo (%d)" % card.level_id)

	# Chương đã xong ⇒ thẻ đổi trạng thái
	var all_stars: Dictionary = {}
	for id in level_ids:
		all_stars[int(id)] = 3
	gm.set("level_stars", all_stars)
	scene.call("_refresh_chapter_ui")
	await process_frame
	_check(card != null and card.cleared, "Chuong da xong -> the doi sang 'HOAN THANH CHUONG'")
	_check(card != null and card.title_label != null
		and card.title_label.text == tr("STR_CHAPTER_DONE_TITLE"), "Tieu de the = 'HOAN THANH CHUONG'")
	_check(card != null and card.lbl_play != null
		and card.lbl_play.text == tr("STR_CHAPTER_GO_NEXT"), "Nhan nut = 'CHUONG TIEP'")

	scene.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# 6. Đổi hướng màn hình
# ---------------------------------------------------------------------------
func _section_orientation(gm: Node, lm: Node) -> void:
	print("[5] Doi huong man hinh...")
	gm.call("reset_progress")
	gm.set("current_chapter", 1)
	gm.set("current_level", 1)
	gm.set("unlocked_levels", 9)
	var level_ids: Array = lm.call("levels_in_chapter", 1)
	var stars: Dictionary = {}
	for id in level_ids:
		stars[int(id)] = 2
	gm.set("level_stars", stars)

	var scene: Node = (load(SCENE_PATH) as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var stars_before := int(lm.call("chapter_stars", 1))
	var bar_before: ChapterProgress = scene.call("progress_widget")
	var fraction_before := bar_before.fraction() if bar_before != null else -1.0

	# Đổi sang NGANG (layout ngang vẫn dùng thanh NGANG cũ)
	root.size = Vector2i(1920, 1080)
	scene.emit_signal("orientation_changed", true)
	await process_frame
	await process_frame
	await process_frame
	var layout_land = scene.get("layout")
	_check(layout_land != null, "Sau khi doi huong van co bo cuc")
	_check(int(lm.call("chapter_stars", 1)) == stars_before,
		"Doi huong KHONG doi so Sao (%d)" % int(lm.call("chapter_stars", 1)))
	var bar_land: ChapterProgress = scene.call("progress_widget")
	_check(bar_land != null, "Bo cuc ngang co thanh thuong (thanh NGANG cu)")
	if bar_land != null:
		_check(not bar_land.vertical, "Bo cuc ngang dung thanh NGANG")
		_check(absf(bar_land.fraction() - fraction_before) < 0.001,
			"Do day thanh giu nguyen sau khi doi huong (%.3f / %.3f)"
				% [bar_land.fraction(), fraction_before])

	root.size = Vector2i(1080, 1920)
	scene.queue_free()
	await process_frame


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("  [PASS] %s" % message)
	else:
		_failed += 1
		print("  [FAIL] %s" % message)


func _finish() -> void:
	var gm: Node = root.get_node_or_null("GameManager")
	if gm != null and not _saved.is_empty():
		gm.call("import_progress", _saved)
	var save_mgr: Node = root.get_node_or_null("SaveManager")
	if save_mgr != null and save_mgr.has_method("flush"):
		save_mgr.call("flush")
	if not _backup.is_empty():
		var wf := FileAccess.open("user://inkmaze_data.json", FileAccess.WRITE)
		wf.store_string(_backup)
		wf.flush()
	print("\n--------------------------------------------------------")
	if _failed == 0:
		print("  KET QUA: %d/%d CHECK PASS" % [_checks, _checks])
	else:
		print("  KET QUA: FAIL %d/%d CHECK" % [_failed, _checks])
	print("--------------------------------------------------------\n")
	quit(1 if _failed > 0 else 0)
