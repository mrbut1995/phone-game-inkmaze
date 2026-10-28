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
	await _section_compact_cards(scene)
	await _section_chip(scene, gm, lm)
	await _section_chest(scene, gm)
	_section_dungeon(scene, gm)
	await _section_tap(scene)
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
## 3b. Th? s? ki?n G?N (package_event_compact) ? carousel th?p 150 px v?n kh?ng c?t ch?
func _section_compact_cards(scene: MainScene) -> void:
	print("[3b] The su kien GON...")
	var carousel: EventCarousel = scene.layout.event_carousel
	if carousel == null:
		return
	var ec_path := carousel.event_card_scene.resource_path if carousel.event_card_scene != null else ""
	var dc_path := carousel.daily_card_scene.resource_path if carousel.daily_card_scene != null else ""
	_check(ec_path.get_file() == "event_card_compact.tscn",
		"Carousel dung the GON cho su kien ('%s')" % ec_path.get_file())
	_check(dc_path.get_file() == "daily_card_compact.tscn",
		"Carousel dung the GON cho Daily ('%s')" % dc_path.get_file())

	var daily: Node = null
	var event: Node = null
	for child in carousel.get_node("ScrollContainer/HBox").get_children():
		if child is DailyCardCompact and daily == null:
			daily = child
		elif child is EventCardCompact and event == null:
			event = child
	_check(daily != null, "Co the DailyCardCompact trong carousel")
	_check(event != null, "Co the EventCardCompact trong carousel")
	if daily == null or event == null:
		return
	_check(daily.size.y <= 165.0, "The Daily gon thap <= 165 px (%.0f)" % daily.size.y)
	_check(event.size.y <= 165.0, "The su kien gon thap <= 165 px (%.0f)" % event.size.y)

	var chips: Control = daily.get_node("Content/Chips") as Control
	var leaf: Control = daily.get_node("Content/Background/Mask/Leaf") as Control
	var date: Control = daily.get_node("Content/Text/DailyDate") as Control
	var title: Control = daily.get_node("Content/Text/Title") as Control
	var cta: Control = daily.get_node("Content/CtaButton") as Control
	_check(chips != null and leaf != null and date != null and title != null and cta != null,
		"The Daily gon du node (chips ? la lich ? nhan ngay ? tieu de ? CTA)")
	if chips != null and date != null:
		_check(chips.get_global_rect().end.y <= date.get_global_rect().position.y + 2.0,
			"Dai CHIP nam TREN la lich (khong de len nhau)")
	if date != null and title != null:
		_check(date.get_global_rect().end.y <= title.get_global_rect().position.y + 2.0,
			"Nhan ngay nam TREN dai tieu de")
	if title != null and cta != null:
		_check(title.get_global_rect().end.x <= cta.get_global_rect().position.x + 2.0,
			"Tieu de va CTA khong de nhau")
	var cta_label: Label = daily.get_node_or_null("Content/CtaButton/CtaLabel") as Label
	if cta_label != null and cta != null:
		var font: Font = cta_label.get_theme_font("font")
		var fs: int = cta_label.get_theme_font_size("font_size")
		var need := font.get_string_size(cta_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		_check(need <= cta.size.x + 1.0, "Nhan CTA '%s' vua nut (%.0f <= %.0f)"
			% [cta_label.text, need, cta.size.x])
	var progress: Control = event.get_node_or_null("Content/Information/ProgressPanel") as Control
	_check(progress == null or not progress.visible,
		"The su kien gon an panel tien do/qua (dai duoi da chat)")


func _section_chip(scene: MainScene, gm: Node, lm: Node) -> void:
	print("[4] Duong lien + cong chuong...")
	var section := scene.layout.level_section
	var chip: ChapterChip = section.chapter_chip
	var map: LevelMap = section.map
	_check(section.continuous, "LevelSection.continuous == true (duong lien)")
	_check(chip != null and not chip.visible, "Duong lien -> KHONG con chip 'CHUONG n' noi")
	var chapters: Array = lm.call("get_chapters")
	_check(chapters.size() > 0, "LevelManager co chuong (%d)" % chapters.size())
	if map == null:
		return
	var line: Array = section.get("_line_ids")
	var gates: Dictionary = section.get("_gate_info")
	# Chương cần Sao (star_cost > 0) và ĐÃ MỞ ⇒ chắc chắn có cổng trong danh sách đường liền
	var opened_gates := 0
	var first_locked := 0
	for chapter in chapters:
		var cid := int(chapter.get("chapter_id"))
		if cid <= 1 or int(gm.call("chapter_star_cost", cid)) <= 0:
			continue
		if bool(gm.call("is_chapter_unlocked", cid)):
			opened_gates += 1
			_check(line.has(-cid), "Chuong %d can %d sao + da mo -> co cong (%d)"
				% [cid, int(gm.call("chapter_star_cost", cid)), -cid])
		elif first_locked == 0:
			first_locked = cid
			_check(line.has(-cid), "Chuong %d con khoa -> co cong chan (%d)" % [cid, -cid])
	_check(gates.size() == line.filter(func(id): return int(id) < 0).size(),
		"Danh sach cong khop danh sach duong (%d cong)" % gates.size())
	# Chương còn KHOÁ ⇒ KHÔNG dựng màn nào của chương đó (đường cắt ở cổng)
	if first_locked > 0:
		var hidden_ok := true
		for level_id in lm.call("levels_in_chapter", first_locked):
			if map.node_for(int(level_id)) != null:
				hidden_ok = false
		_check(hidden_ok, "Chuong %d con khoa -> khong dung man nao cua chuong do" % first_locked)
		_check(map.get("_truncated_at_gate"), "Duong CAT o cong khoa (khong cuon qua duoc)")
		var gate_y: float = map.call("_node_y", -first_locked)
		if not is_nan(gate_y):
			_check(float(map.get("_max_scroll_y")) <= float(map.call("_focus_y")) - gate_y + 1.0,
				"Cuon len dinh dung o cong (%.1f <= %.1f)"
					% [float(map.get("_max_scroll_y")), float(map.call("_focus_y")) - gate_y])


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


## Bấm THẬT vào nút màn phải chọn được màn.
## Nút màn là `TextureButton2D` (Node2D) ⇒ chỉ nhận cú bấm ở `_unhandled_input`, nên nếu có
## một `Control` phủ kín với `mouse_filter = STOP` nằm trên (vd. node gốc của bố cục Main) thì
## GUI nuốt mất sự kiện và nút **không bao giờ** được bấm (lỗi 2026-10-28).
func _section_tap(scene: MainScene) -> void:
	print("[6b] Bam THAT vao nut man...")
	var section: LevelSection = scene.layout.level_section
	var map: LevelMap = section.map
	var root_control: Control = section.get_parent().get_parent() as Control
	_check(root_control != null and root_control.mouse_filter != Control.MOUSE_FILTER_STOP,
		"Nut goc bo cuc Main KHONG nuot cu bam (mouse_filter = %d)"
			% (root_control.mouse_filter if root_control != null else -1))
	var level_id := int(section.chapter_continue_level())
	map.call("scroll_to", level_id, false)
	for i in 4:
		await process_frame
	var node: LevelMapNode = map.node_for(level_id)
	if node == null or node.button == null:
		_check(false, "Man %d phai co nut de bam" % level_id)
		return
	var picked := [-1]
	var on_pick := func(id: int) -> void: picked[0] = id
	map.level_selected.connect(on_pick)
	await _tap(node.button.get_global_transform_with_canvas().origin)
	_check(picked[0] == level_id,
		"Bam vao man %d -> chon duoc man do (nhan %d)" % [level_id, picked[0]])
	picked[0] = -1
	# Bấm ra NGOÀI mọi nút (góc trên trái khung bản đồ) ⇒ không chọn màn nào
	var area: Control = map.get_parent() as Control
	await _tap(area.get_global_rect().position + Vector2(4, 4))
	_check(picked[0] == -1, "Bam vao cho trong -> khong chon man (%d)" % picked[0])
	map.level_selected.disconnect(on_pick)


## Đẩy 1 cú nhấn + nhả chuột trái (toạ độ CANVAS) rồi chờ vài frame
func _tap(canvas_pos: Vector2) -> void:
	var pos: Vector2 = root.get_final_transform() * canvas_pos
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = pressed
		ev.position = pos
		ev.global_position = pos
		root.push_input(ev)
		await process_frame
	for i in 3:
		await process_frame


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
