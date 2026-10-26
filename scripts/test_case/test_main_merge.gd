extends SceneTree
## ============================================================================
## Test: MÀN MAIN BẢN GỘP (nhánh `portrait_landscape_feature`)
##   · Màn Levels riêng đã bị GỠ; bản đồ màn chơi nằm ngay trong Main (`LevelSection`).
##   · Chip chương ‹ CHƯƠNG n › · rương mốc `ChapterChestWidget` · nút Dungeon nổi.
##   · Điều hướng: `Nav.goto_levels()` / `GameManager.go_to_levels()` về Main.
##   · Khung "chương đang khoá" phủ cả màn (`ChapterLockSheet`) + Back chỉ đóng khung.
## ============================================================================

const MAIN := "res://scenes/main.tscn"

var _checks := 0
var _failed := 0


func _init() -> void:
	print("\n========================================================")
	print("  TEST: MAIN BAN GOP (ban do nam trong Main)")
	print("========================================================\n")
	await process_frame
	root.size = Vector2i(1080, 1920)
	await process_frame

	var gm: Node = root.get_node_or_null("GameManager")
	var lm: Node = root.get_node_or_null("LevelManager")
	_check(gm != null and lm != null, "Autoload GameManager + LevelManager ton tai")

	_section_files()
	_section_navigation()

	var scene: MainScene = (load(MAIN) as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	for i in 25:
		await process_frame

	_section_layout(scene)
	await _section_chip(scene, gm, lm)
	await _section_chest(scene, gm)
	_section_dungeon(scene, gm)
	await _section_lock_sheet(scene, gm, lm)
	await _section_orientation(scene)

	scene.queue_free()
	await process_frame

	print("\n--------------------------------------------------------")
	if _failed == 0:
		print("  KET QUA: %d/%d CHECK PASS" % [_checks, _checks])
	else:
		print("  KET QUA: %d/%d CHECK FAIL" % [_failed, _checks])
	print("--------------------------------------------------------\n")
	quit(1 if _failed > 0 else 0)


# ---------------------------------------------------------------------------
# 1. File của màn Levels cũ đã bị gỡ
# ---------------------------------------------------------------------------
func _section_files() -> void:
	print("[1] Man Levels rieng da go...")
	for path in [
		"res://scenes/levels.tscn",
		"res://scenes/layout/portrait/levels.tscn",
		"res://scenes/layout/landscape/levels.tscn",
		"res://scripts/scenes/levels.gd",
		"res://scripts/scenes/layout/levels_layout.gd",
		"res://nodes/main/mode_card.tscn",
		"res://scripts/nodes/mode_card.gd",
	]:
		_check(not ResourceLoader.exists(path), "Da xoa %s" % path.get_file())
	for path in [
		"res://nodes/main/level_section.tscn",
		"res://nodes/main/chapter_chip.tscn",
		"res://nodes/main/chest_widget.tscn",
		"res://nodes/main/dungeon_pill.tscn",
	]:
		_check(ResourceLoader.exists(path), "Co component %s" % path.get_file())


# ---------------------------------------------------------------------------
# 2. Điều hướng: mọi đường vào "màn Chọn màn" nay về Main
# ---------------------------------------------------------------------------
func _section_navigation() -> void:
	print("[2] Dieu huong ve Main...")
	var nav_src := FileAccess.get_file_as_string("res://scripts/utils/nav.gd")
	_check(nav_src.contains("static func goto_levels"), "Nav van giu goto_levels() (deprecated)")
	_check(not nav_src.contains("scenes/levels.tscn"), "Nav KHONG con tro toi scenes/levels.tscn")
	var gm_src := FileAccess.get_file_as_string("res://scripts/core/game_manager.gd")
	_check(gm_src.contains("func go_to_levels"), "GameManager van giu go_to_levels() (deprecated)")
	_check(not gm_src.contains("scenes/levels.tscn"), "GameManager KHONG con tro toi scenes/levels.tscn")
	var loading_src := FileAccess.get_file_as_string("res://scripts/manager/LoadingManager.gd")
	_check(not loading_src.contains("scenes/levels.tscn"), "LoadingManager khong nap san man Levels da xoa")

	var sm: Node = root.get_node("SceneManager")
	var gm: Node = root.get_node("GameManager")
	sm.call("change_scene", "res://scenes/daily.tscn")
	await process_frame
	await process_frame
	gm.call("go_to_levels")
	await process_frame
	await process_frame
	var current := current_scene.scene_file_path if current_scene != null else ""
	_check(current == MAIN, "go_to_levels() phai mo Main (dang o '%s')" % current.get_file())


# ---------------------------------------------------------------------------
# 3. Bố cục: Main bind `level_section` thay cho 2 thẻ chế độ
# ---------------------------------------------------------------------------
func _section_layout(scene: MainScene) -> void:
	print("[3] Bo cuc Main (ban GOP)...")
	var layout: MainLayout = scene.layout
	_check(layout != null, "Main co bo cuc MainLayout")
	if layout == null:
		return
	_check(layout.level_section != null, "Bo cuc bind `level_section`")
	_check(layout.event_carousel != null, "Bo cuc giu `event_carousel`")
	_check(layout.dock_shop != null and layout.dock_badges != null, "Dock 4 nut van bind")
	var section: LevelSection = layout.level_section
	if section == null:
		return
	_check(section.map != null, "LevelSection bind `map`")
	_check(section.chapter_chip != null, "LevelSection bind `chapter_chip`")
	_check(section.chest != null, "LevelSection bind `chest`")
	_check(section.dungeon_pill != null, "LevelSection bind `dungeon_pill`")
	_check(section.map.node_count() > 0, "Ban do co nut man (%d)" % section.map.node_count())
	_check(section.map.effective_columns() == 3,
		"Ban doc dung 3 cot (%d)" % section.map.effective_columns())
	var area := section.map.get_parent() as Control
	_check(area != null and area.clip_contents, "Ban do nam trong khung clip_contents (MapArea)")
	# Chấm phân trang DỜI vào EventHeader.DotsSlot (thay vì nằm dưới carousel)
	var slot: Node = layout.event_header.get_node_or_null("DotsSlot")
	var dots_in_slot := false
	if slot != null:
		for child in slot.get_children():
			if child is EventDots:
				dots_in_slot = true
				break
	_check(dots_in_slot, "Cham phan trang nam trong EventHeader.DotsSlot")


# ---------------------------------------------------------------------------
# 4. Chip chương
# ---------------------------------------------------------------------------
func _section_chip(scene: MainScene, _gm: Node, lm: Node) -> void:
	print("[4] Chip chuong...")
	var chip: ChapterChip = scene.layout.level_section.chapter_chip
	if chip == null:
		return
	var chapters: Array = lm.call("get_chapters")
	_check(chapters.size() > 0, "LevelManager co chuong (%d)" % chapters.size())
	var chapter_now := int(root.get_node("GameManager").get("current_chapter"))
	_check(chip.lbl_title != null and chip.lbl_title.text.contains(str(chapter_now)),
		"Nhan chip hien dung chuong %d ('%s')" % [chapter_now, chip.lbl_title.text if chip.lbl_title else ""])
	_check(chip.btn_prev != null and chip.btn_next != null, "Chip co 2 mui ten ‹ ›")
	# Chương 1 ⇒ không còn chương trước ⇒ mũi tên ‹ bị vô hiệu
	if chapter_now <= 1:
		_check(chip.btn_prev.disabled, "Chuong 1 -> mui ten ‹ bi vo hieu")
	# Bấm › khi KHÔNG có chương kế ⇒ không đổi chương, không mở khung
	if chip.btn_next.disabled:
		var before := int(root.get_node("GameManager").get("current_chapter"))
		chip.next_requested.emit()
		await process_frame
		_check(int(root.get_node("GameManager").get("current_chapter")) == before,
			"Khong co chuong ke -> bam › khong doi chuong")


# ---------------------------------------------------------------------------
# 5. Rương mốc thưởng của chương
# ---------------------------------------------------------------------------
func _section_chest(scene: MainScene, gm: Node) -> void:
	print("[5] Ruong moc thuong...")
	var chest: ChapterChestWidget = scene.layout.level_section.chest
	if chest == null:
		return
	var defs: Array = gm.call("chapter_chest_defs", 27)
	_check(defs.size() == 3, "Co 3 moc ruong (%d)" % defs.size())
	if defs.is_empty():
		return
	var total := 27
	chest.setup(defs, 0, total, [false, false, false])
	await process_frame
	_check(chest.visible, "Chua nhan ruong -> ruong hien")
	_check(not chest.is_claimable(), "0 sao < nguong -> ruong CHUA nhan duoc")
	_check(chest.lbl_stars != null and chest.lbl_stars.text == "0/%d" % int(defs[0].get("stars", 0)),
		"Nhan ruong hien 'sao hien co/nguong' ('%s')" % (chest.lbl_stars.text if chest.lbl_stars else ""))
	var reached := int(defs[0].get("stars", 0))
	chest.setup(defs, reached, total, [false, false, false])
	await process_frame
	_check(chest.is_claimable(), "Du sao moc 1 -> ruong NHAN duoc")
	# Nhận hết 3 mốc -> rương mở + ✓, không nhận được nữa
	chest.setup(defs, total, total, [true, true, true])
	await process_frame
	_check(not chest.is_claimable(), "Da nhan het -> ruong khong nhan duoc nua")
	_check(chest.badge_done != null and chest.badge_done.visible, "Da nhan het -> hien dau ✓")


# ---------------------------------------------------------------------------
# 6. Nút Dungeon nổi
# ---------------------------------------------------------------------------
func _section_dungeon(scene: MainScene, _gm: Node) -> void:
	print("[6] Nut Dungeon noi...")
	var pill: DungeonPill = scene.layout.level_section.dungeon_pill
	if pill == null:
		return
	pill.setup(7)
	_check(pill.lbl_floor != null and pill.lbl_floor.text.contains("7"),
		"Pill hien tang ky luc ('%s')" % (pill.lbl_floor.text if pill.lbl_floor else ""))
	_check(pill.lbl_title != null and not pill.lbl_title.text.is_empty(),
		"Pill co nhan DUNGEON ('%s')" % (pill.lbl_title.text if pill.lbl_title else ""))
	_check(pill.pressed.get_connections().size() > 0, "Pill noi toi Main (_on_dungeon_pressed)")


# ---------------------------------------------------------------------------
# 7. Khung "chương đang khoá" phủ cả màn
# ---------------------------------------------------------------------------
func _section_lock_sheet(scene: MainScene, gm: Node, lm: Node) -> void:
	print("[7] Khung chuong dang khoa...")
	var section: LevelSection = scene.layout.level_section
	var sheet := section.lock_sheet
	_check(sheet != null, "LevelSection bind `lock_sheet`")
	if sheet == null:
		return
	var chapters: Array = lm.call("get_chapters")
	var locked_id := 0
	for chapter_v in chapters:
		var chapter := chapter_v as ChapterData
		if chapter != null and not bool(gm.call("is_chapter_unlocked", chapter.chapter_id)):
			locked_id = chapter.chapter_id
			break
	sheet.open_chapter(locked_id if locked_id > 0 else 2)
	await process_frame
	_check(section.is_sheet_open(), "Mo duoc khung chuong khoa")
	# Back (Esc/ui_cancel) khi khung mo ⇒ chỉ đóng khung, KHÔNG đổi màn
	var before := current_scene
	var ev := InputEventAction.new()
	ev.action = &"ui_cancel"
	ev.pressed = true
	Input.parse_input_event(ev)
	await process_frame
	await process_frame
	_check(not section.is_sheet_open(), "Back dong khung chuong khoa")
	_check(current_scene == before, "Back khi khung mo KHONG doi man hinh")


# ---------------------------------------------------------------------------
# 8. Xoay màn: cả 2 bố cục đều có LevelSection dựng được
# ---------------------------------------------------------------------------
func _section_orientation(scene: MainScene) -> void:
	print("[8] Xoay man...")
	root.size = Vector2i(1920, 1080)
	for i in 20:
		await process_frame
	var layout: MainLayout = scene.layout
	_check(layout != null, "Sau khi xoay van co MainLayout")
	if layout != null:
		var section: LevelSection = layout.level_section
		_check(section != null and section.map != null, "Bo cuc NGANG co LevelSection + LevelMap")
		if section != null:
			_check(section.map.node_count() > 0, "Ban do ngang dung duoc (%d nut)" % section.map.node_count())
	root.size = Vector2i(1080, 1920)
	for i in 10:
		await process_frame


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("  [PASS] %s" % label)
	else:
		_failed += 1
		print("  [FAIL] %s" % label)
