extends SceneTree
## ============================================================================
## Test: HỆ HƯỚNG DẪN CHƠI theo chế độ — kiến trúc TÁCH POPUP ⇄ NỘI DUNG:
##   · `page.tscn`                — Image (label chữ-trên-ảnh PT# là CON của Image) ·
##                                  Title · Section · Instruction (VBoxContainer các hàng luật)
##   · `content_instruction.tscn` — Chip · Tabs/Tab1..3 · Pages · Prev/Next · Dots/Dot1..3 ·
##                                  Index (+ script lật trang)
##   · `instruction/<mode>.tscn`  — KẾ THỪA content_instruction; Page1..3 kế thừa page.tscn
##   · `popup_instruction.tscn`   — popup DÙNG CHUNG, nạp `<mode>.tscn` vào Panel/Content theo mode_id
##   · Mọi chữ trong scene dùng khoá `STR_GI_*` và có bản dịch ở CẢ vi lẫn en.
##   · HUD ngang: khung `InstructionSection` nhúng content (TRÀN kín GuideHost) hoặc hiện nút
##     "XEM HƯỚNG DẪN" khi khung quá nhỏ; status bar ngang KHÔNG còn nút "?".
## ============================================================================

const MODES := ["normal_maze", "dungeon", "minesweeper", "sumpath", "countdowncost",
		"fadingink", "blindmemory", "fog_of_war", "one_stroke", "wall_builder"]
const MODE_IDS := ["play", "daily_classic", "dungeon", "minesweeper",
		"sum_path", "countdown_cost", "blind_memory", "fog_of_war", "fading_ink", "one_stroke",
		"wall_builder"]
const KEYS_PATH := "res://tools/content/_guide_keys.json"
const INSTRUCTION_DIR := "res://nodes/popups/instruction/"

var _failures := 0
var _checks := 0
var _letter_re := RegEx.create_from_string("[\\p{L}]")
var _keymap: Dictionary = {}
var _signal_fired := false


func _init() -> void:
	print("\n========================================================")
	print("  TEST: HE HUONG DAN — PAGE / CONTENT / POPUP / HUD")
	print("========================================================\n")

	await process_frame

	var raw := FileAccess.get_file_as_string(KEYS_PATH)
	_keymap = JSON.parse_string(raw) if not raw.is_empty() else {}

	_check_mapping()
	_check_files_structure()
	_check_keys_locales()

	TranslationServer.set_locale("vi")
	for mode in MODES:
		await _check_content(mode)
	await _check_popup()
	await _check_integration()
	await _check_hud_embed()
	await _check_aspect_invariants()

	if _failures == 0:
		print("\n[SUCCESS] %d check PASS — he huong dan (page/content/popup/HUD) chay dung." % _checks)
	else:
		print("\n[FAILED] %d/%d check loi ve he huong dan." % [_failures, _checks])
	quit(0)


func _fail(msg: String) -> void:
	_failures += 1
	print("  [FAIL] ", msg)


func _ok(msg: String) -> void:
	_checks += 1
	print("  [OK]   ", msg)


func _check(cond: bool, msg: String) -> void:
	if cond:
		_ok(msg)
	else:
		_fail(msg)


func _on_close_requested() -> void:
	_signal_fired = true


# ---------------------------------------------------------------------------
# 1. Bảng chế độ -> scene nội dung + popup dùng chung
# ---------------------------------------------------------------------------
func _check_mapping() -> void:
	print("-- Bang che do -> scene noi dung --")
	for mode_id in MODE_IDS:
		var scene_name: String = GameController.INSTRUCTION_SCENES.get(mode_id, "")
		if scene_name.is_empty():
			_fail("mode '%s' chua co scene huong dan" % mode_id)
			continue
		_check(ResourceLoader.exists(INSTRUCTION_DIR + scene_name + ".tscn"),
				"%s -> %s.tscn" % [mode_id, scene_name])
	_check(ResourceLoader.exists(GameController.INSTRUCTION_POPUP),
			"co popup dung chung (popup_instruction.tscn)")
	_ok("fallback = %s" % GameController.INSTRUCTION_FALLBACK)


# ---------------------------------------------------------------------------
# 2. Cấu trúc scene nền (page / content / popup) + quan hệ kế thừa của scene chế độ
# ---------------------------------------------------------------------------
func _check_files_structure() -> void:
	print("-- Cau truc scene nen + ke thua --")
	var page_txt := FileAccess.get_file_as_string(INSTRUCTION_DIR + "page.tscn")
	_check(page_txt.contains('name="Image"') and page_txt.contains('name="Title"')
			and page_txt.contains('name="Section"'), "page.tscn co Image + Title + Section")
	_check(page_txt.contains('name="Instruction"') and page_txt.contains('type="VBoxContainer"'),
			"page.tscn: Instruction la VBoxContainer")
	_check(page_txt.contains('name="Body" type="VBoxContainer"')
			and page_txt.contains('name="Top" type="HBoxContainer"'),
			"page.tscn: Body (VBox) chua Top (HBox) — bo cuc CO DINH, khong chia theo ti le khung")
	_check(page_txt.contains('name="Image" type="TextureRect" parent="Body/Top"')
			and page_txt.contains('name="Points" type="Panel" parent="Body/Top"'),
			"page.tscn: ANH + DIEM nam CUNG hang Top (HBox)")
	_check(page_txt.contains('name="Section" type="Label" parent="Body"'),
			"page.tscn: muc LUAT CHOI nam trong Body, ngay duoi hang [ANH|DIEM]")
	_check(page_txt.contains("page.gd"), "page.tscn gan script page.gd")
	_check(page_txt.contains('name="Points"') and page_txt.contains('name="Head"')
			and page_txt.contains('name="List"'), "page.tscn co section DIEM (Points/Head/List)")
	_check(page_txt.contains("STR_GI_POINTS_HEAD"), "page.tscn: tieu de khoi diem dung khoa dich")

	var ct := FileAccess.get_file_as_string(INSTRUCTION_DIR + "content_instruction.tscn")
	var need := ["Chip", "Tabs", "Pages", "Prev", "Next", "Dots", "Index"]
	for node_name in need:
		_check(ct.contains('name="%s"' % node_name), "content_instruction.tscn co node %s" % node_name)
	_check(ct.contains("content_instruction.gd"), "content_instruction.tscn gan script")

	var pop_txt := FileAccess.get_file_as_string("res://nodes/popups/popup_instruction.tscn")
	for node_name in ["Panel", "Washi", "PaperDetail", "Content"]:
		_check(pop_txt.contains('name="%s"' % node_name), "popup_instruction.tscn co node %s" % node_name)
	_check(pop_txt.contains("popup_instruction.gd"), "popup_instruction.tscn gan script")

	for mode in MODES:
		var txt := FileAccess.get_file_as_string(INSTRUCTION_DIR + mode + ".tscn")
		_check(txt.contains("content_instruction.tscn"), "%s: KE THUA content_instruction" % mode)
		_check(txt.contains("page.tscn"), "%s: cac trang dung page.tscn" % mode)
		_check(txt.count("[editable path=") == 3, "%s: 3 trang duoc danh editable" % mode)
		_check(txt.contains('parent="Pages/Page1/Body/Top/Image"'), "%s: label chu-tren-anh nam TRONG Image" % mode)
		_check(txt.contains('parent="Pages/Page1/Body/Instruction"'), "%s: hang luat nam TRONG VBox Instruction" % mode)
		_check(txt.contains('instance=ExtResource("2_page")'), "%s: Page1..3 la INSTANCE cua page.tscn" % mode)
		_check(txt.contains("metadata/point = "), "%s: chu trong khung chu thich -> Label an (metadata/point)" % mode)
		_check(txt.contains('text = "STR_GI_'), "%s: chu diem giu khoa dich trong Label an" % mode)
		_check(txt.contains('[node name="Point1"'), "%s: badge so Point1 tren anh" % mode)
		_check(txt.contains('parent="Pages/Page1/Body/Top/Points/List"'), "%s: hang diem nam trong Points/List" % mode)


# ---------------------------------------------------------------------------
# 3. Mọi khoá STR_* trong các scene phải có bản dịch ở vi + en
# ---------------------------------------------------------------------------
func _check_keys_locales() -> void:
	print("-- Khoa dich STR_* trong scene --")
	var files: Array = []
	for mode in MODES:
		files.append(INSTRUCTION_DIR + mode + ".tscn")
	files.append(INSTRUCTION_DIR + "page.tscn")
	files.append(INSTRUCTION_DIR + "content_instruction.tscn")
	files.append("res://nodes/popups/popup_instruction.tscn")
	var keys := {}
	for path in files:
		var text := FileAccess.get_file_as_string(path)
		for key in _regex(text, '"((STR_[A-Z0-9_]+))"'):
			keys[key] = true
	var total := keys.size()
	var missing := []
	for locale in ["vi", "en"]:
		TranslationServer.set_locale(locale)
		for key in keys:
			var value := tr(str(key))
			if value == key or value.strip_edges().is_empty():
				missing.append("%s/%s" % [locale, key])
	TranslationServer.set_locale("vi")
	if missing.is_empty():
		_ok("%d khoa STR_* deu co ban dich vi + en" % total)
	else:
		for m in missing.slice(0, 8):
			_fail("thieu ban dich: %s" % m)


# ---------------------------------------------------------------------------
# 4. Nội dung từng chế độ — chạy thật: trang, tab, dots, lật trang, CTA/link
# ---------------------------------------------------------------------------
func _check_content(mode: String) -> void:
	print("-- Noi dung che do: %s --" % mode)
	var ps := load(INSTRUCTION_DIR + mode + ".tscn") as PackedScene
	if ps == null:
		_fail("%s: khong load duoc scene" % mode)
		return
	var inst := ps.instantiate()
	root.add_child(inst)
	await process_frame
	var c := inst as InstructionContent
	if c == null:
		_fail("%s: scene khong gan InstructionContent" % mode)
		inst.queue_free()
		return

	var want_chip: String = _keymap.get("modes", {}).get(mode, {}).get("chip", ["", ""])[0]
	var chip := c.get_node_or_null("Chip/ChipText") as Label
	_check(chip != null and chip.text == want_chip, "%s: chip dung ('%s')" % [mode, chip.text if chip != null else "?"])
	_check(c.page_count() == 3, "%s: co 3 trang" % mode)
	_check(c.tab_count() == 3, "%s: 3 tab dung chung" % mode)
	var dots := c.get_node_or_null("Dots")
	_check(dots != null and dots.get_child_count() == 3, "%s: 3 dot dieu huong" % mode)
	_check(c.is_prev_locked() and not c.is_next_locked(), "%s: trang 1 — Prev khoa, Next mo" % mode)

	var pages := c.get_node_or_null("Pages")
	var p1: Node = pages.get_child(0) if pages != null and pages.get_child_count() > 0 else null
	var img: Node = p1.get_node_or_null("Body/Top/Image") if p1 != null else null
	_check(img != null and img.texture != null, "%s: Image co anh minh hoa" % mode)
	var shown := 0
	var hidden_points := 0
	var badges := 0
	if img != null:
		for child in img.get_children():
			if child is Label:
				if child.has_meta("point"):
					hidden_points += 1
				elif child.visible:
					shown += 1
			elif child is Panel and child.has_meta("base_size"):
				badges += 1
	_check(shown > 0, "%s: %d nhan minh hoa van hien tren anh" % [mode, shown])
	_check(hidden_points > 0, "%s: %d nhan chu thich -> Label an (diem)" % [mode, hidden_points])
	# ĐIỂM: badge số trên ảnh + hàng trong section (chữ do script đổ từ PT# ẩn)
	_check(c.point_count() >= 1, "%s: co %d diem" % [mode, c.point_count()])
	_check(badges == c.point_count(), "%s: %d badge so = so diem" % [mode, badges])
	var pts := c.point_texts()
	var pts_ok := pts.size() == c.point_count()
	for s in pts:
		if s.strip_edges().is_empty():
			pts_ok = false
	_check(pts_ok and not pts.is_empty(), "%s: chu giai thich diem doc tu PT# an" % mode)
	var pbox: Node = p1.get_node_or_null("Body/Top/Points") if p1 != null else null
	var plist: Node = p1.get_node_or_null("Body/Top/Points/List") if p1 != null else null
	_check(pbox != null and pbox.visible, "%s: khoi DIEM hien" % mode)
	_check(plist != null and plist.get_child_count() == c.point_count(),
			"%s: %d hang diem trong Points/List" % [mode, c.point_count()])
	if plist != null and plist.get_child_count() > 0:
		var prow := plist.get_child(0)
		var ptitle := prow.get_node_or_null("Body/Title") as Label
		_check(ptitle != null and not ptitle.text.is_empty(),
				"%s: hang diem 1 duoc do chu" % mode)
	var vbox: Node = p1.get_node_or_null("Body/Instruction") if p1 != null else null
	_check(vbox is VBoxContainer and vbox.get_child_count() == 3, "%s: 3 hang luat trong VBox" % mode)
	var row1: Node = vbox.get_child(0) if vbox != null and vbox.get_child_count() > 0 else null
	_check(row1 != null and row1.get_node_or_null("NumCircle") != null
			and row1.get_node_or_null("Title") != null and row1.get_node_or_null("Desc") != null,
			"%s: hang 1 du NumCircle/Title/Desc" % mode)
	_check(p1 != null and p1.get_node_or_null("Cta") is Button and p1.get_node_or_null("Link") is Button,
			"%s: trang 1 du Cta + Link" % mode)
	_check(not c.page_title().is_empty() and not c.page_index_text().is_empty(),
			"%s: Title + Index co chu" % mode)
	_check(not c.tab_label(0).is_empty() and not c.cta_text().is_empty() and not c.link_text().is_empty(),
			"%s: tab/CTA/link co chu" % mode)

	# lật trang + khoá điều hướng
	c.go_to_page(1)
	await process_frame
	_check(c.current_page() == 1, "%s: go_to_page(1)" % mode)
	c.next_page()
	await process_frame
	_check(c.current_page() == 2 and c.is_next_locked(), "%s: toi trang cuoi — Next khoa" % mode)
	c.prev_page()
	c.prev_page()
	await process_frame
	_check(c.current_page() == 0 and c.is_prev_locked(), "%s: ve trang dau — Prev khoa" % mode)

	# CTA trang cuối + link "bỏ qua" (chế độ thường, KHÔNG nhúng) -> close_requested
	c.close_requested.connect(_on_close_requested)
	c.go_to_page(2)
	await process_frame
	_signal_fired = false
	var cta := c.cta_button()
	if cta != null:
		cta.pressed.emit()
	_check(_signal_fired, "%s: CTA trang cuoi phat close_requested" % mode)
	c.go_to_page(0)
	await process_frame
	_signal_fired = false
	var link := c.link_button()
	if link != null:
		link.pressed.emit()
	_check(_signal_fired, "%s: link 'bo qua' phat close_requested" % mode)

	inst.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# 5. Popup dùng chung — nạp content theo mode, lật trang, CTA/nút X đóng
# ---------------------------------------------------------------------------
func _check_popup() -> void:
	print("-- Popup dung chung --")
	var ps := load(GameController.INSTRUCTION_POPUP) as PackedScene
	_check(ps != null, "popup_instruction.tscn load duoc")
	if ps == null:
		return

	var pop := ps.instantiate() as PopupInstruction
	root.add_child(pop)
	await process_frame
	_check(pop is BasePopup, "popup ke thua BasePopup")
	pop.open({"mode_id": "dungeon"})
	await process_frame
	var content := pop.content_node()
	_check(content != null, "popup nap content theo mode_id")
	if content != null:
		var chip := content.get_node_or_null("Chip/ChipText") as Label
		_check(chip != null and chip.text == "STR_GI_DUNGEON_CHIP", "popup: content dung che do dungeon")
		var chip_box := content.get_node_or_null("Chip") as Control
		var tabs_box := content.get_node_or_null("Tabs") as Control
		var title1 := content.get_node_or_null("Pages/Page1/Title") as Control
		var cta1 := content.get_node_or_null("Pages/Page1/Cta") as Control
		var link1 := content.get_node_or_null("Pages/Page1/Link") as Control
		var pbox := content.get_node_or_null("Pages/Page1/Body/Top/Points") as Control
		_check(chip_box != null and chip_box.visible and tabs_box != null and tabs_box.visible,
				"popup: hien Chip + Tabs")
		_check(title1 != null and title1.visible, "popup: hien Title cua trang")
		_check(cta1 != null and cta1.visible and link1 != null and link1.visible,
				"popup: Cta + Link hien (chi popup moi co)")
		_check(pbox != null and pbox.visible, "popup: khoi DIEM hien")
		_check(content.point_count() >= 1 and content.point_texts().size() == content.point_count(),
				"popup: diem duoc do chu")
	_check(pop.page_count() == 3 and pop.tab_count() == 3, "popup: 3 trang / 3 tab")
	var paper := pop.get_node_or_null("Panel/Paper") as Panel
	_check(paper != null and paper.get_theme_stylebox("panel") != null, "popup: to giay duoc to theo che do")
	pop.go_to_page(2)
	await process_frame
	_check(pop.current_page() == 2 and pop.is_next_locked(), "popup: lat trang + khoa Next")
	var cta := pop.cta_button()
	_check(cta != null and cta.visible, "popup (khong nhung): CTA trang cuoi HIEN")
	if cta != null:
		cta.pressed.emit()
	_check(pop.is_closing(), "popup: CTA trang cuoi dong popup")
	pop.queue_free()
	await process_frame

	var pop2 := ps.instantiate() as PopupInstruction
	root.add_child(pop2)
	await process_frame
	pop2.open({"mode_id": "minesweeper"})
	await process_frame
	var content2 := pop2.content_node()
	var chip2: Label = content2.get_node_or_null("Chip/ChipText") if content2 != null else null
	_check(chip2 != null and chip2.text == "STR_GI_MINESWEEPER_CHIP", "popup: doi mode -> doi content")
	var close_btn := pop2.get_node_or_null("Panel/Close") as BaseButton
	if close_btn != null:
		close_btn.pressed.emit()
	_check(pop2.is_closing(), "popup: nut X dong popup")
	pop2.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# 6. Tích hợp: GameController.open_instruction -> popup chung đúng chế độ
# ---------------------------------------------------------------------------
func _check_integration() -> void:
	print("-- Tich hop: open_instruction -> popup dung che do --")
	var gm: Node = root.get_node_or_null("GameManager")
	if gm == null:
		_fail("Khong tim thay autoload GameManager")
		return
	var cases := [["dungeon", "STR_GI_DUNGEON_CHIP"],
			["play", "STR_GI_NORMAL_MAZE_CHIP"],
			["minesweeper", "STR_GI_MINESWEEPER_CHIP"]]
	for c in cases:
		gm.set("current_mode", c[0])
		gm.set("current_level", 1)
		gm.set("unlocked_levels", 99)
		var scene: GameScene = (load("res://scenes/game.tscn") as PackedScene).instantiate()
		root.add_child(scene)
		await process_frame
		await process_frame
		scene.game_controller.open_instruction()
		await process_frame
		var pop := Popups.top()
		var content: InstructionContent = pop.content_node() if pop is PopupInstruction else null
		var chip: Label = content.get_node_or_null("Chip/ChipText") if content != null else null
		var ok: bool = pop is PopupInstruction and pop.page_count() == 3 \
				and chip != null and chip.text == c[1]
		_check(ok, "%s: open_instruction -> '%s' (chip %s)" % [
				c[0], pop.popup_id if pop != null else "<null>",
				chip.text if chip != null else "?"])
		Popups.close_all()
		await process_frame
		await process_frame
		scene.queue_free()
		await process_frame


# ---------------------------------------------------------------------------
# 7. HUD NGANG: khung InstructionSection nhúng content TRÀN GuideHost / nút dự phòng
# ---------------------------------------------------------------------------
func _check_hud_embed() -> void:
	print("-- HUD ngang: khung huong dan (InstructionSection) --")

	# (a) Layout ngang: bỏ nút "?" trên thanh trạng thái (hướng dẫn nằm trong khung HUD)
	var layout_scene: Node = (load("res://scenes/layout/landscape/game.tscn") as PackedScene).instantiate()
	root.add_child(layout_scene)
	await process_frame
	_check(layout_scene.get("instruction_btn") == null, "layout ngang: khong con bind instruction_btn")
	_check(layout_scene.get_node_or_null("Content/Side/Status/Bar/Instruction") == null,
			"StatusBar ngang: khong con nut Instruction")
	layout_scene.queue_free()
	await process_frame

	# (b) HUD ngang đủ chỗ -> nhúng CONTENT (kế thừa content_instruction) TRÀN kín GuideHost
	var host := Control.new()
	host.size = Vector2(994, 800)
	root.add_child(host)
	var hud := (load("res://nodes/hud/landscape/game/level_mode.tscn") as PackedScene).instantiate() as GameHUD
	host.add_child(hud)
	await process_frame
	await process_frame
	hud.instruction_requested.connect(_on_close_requested)
	hud.show_instruction_for("minesweeper")
	await process_frame
	await process_frame
	var view := hud.instruction_view()
	var fb := hud.instruction_fallback()
	_check(fb != null, "co nut du phong trong Panel")
	_check(view is InstructionContent and view.visible, "khung du cho -> nhung content huong dan")
	if view != null:
		var chip := view.get_node_or_null("Chip/ChipText") as Label
		_check(chip != null and chip.text == "STR_GI_MINESWEEPER_CHIP", "nhung dung scene cua che do")
		var section := hud.instruction_section()
		# Khung chứa THẬT là `Panel/GuideHost` (section có thể còn lề/aspect-fit bên ngoài)
		var guide_host := section.get_node_or_null("Panel/GuideHost") as Control
		_check(guide_host != null and absf(view.size.x - guide_host.size.x) < 1.0
				and absf(view.size.y - guide_host.size.y) < 1.0, "content TRAN kin GuideHost")
		_check(view.page_count() == 3, "content nhung co 3 trang")
		var chip_box := view.get_node_or_null("Chip") as Control
		var tabs_box := view.get_node_or_null("Tabs") as Control
		var title1 := view.get_node_or_null("Pages/Page1/Title") as Control
		var cta1 := view.get_node_or_null("Pages/Page1/Cta") as Control
		var link := view.get_node_or_null("Pages/Page1/Link") as Control
		_check(chip_box != null and not chip_box.visible, "ban nhung: an Chip")
		_check(tabs_box != null and not tabs_box.visible, "ban nhung: an Tabs")
		_check(title1 != null and not title1.visible, "ban nhung: an Title")
		_check(cta1 != null and not cta1.visible, "ban nhung: an Cta (chi popup moi co)")
		_check(link != null and not link.visible, "ban nhung: an link 'bo qua'")
		# điều hướng dời lên hàng tiêu đề “LUẬT CHƠI” (theo mockup landscape)
		var sec := view.get_node_or_null("Pages/Page1/Body/Section") as Control
		var prev_btn := view.get_node_or_null("Prev") as Control
		var idx := view.get_node_or_null("Index") as Control
		_check(sec != null and prev_btn != null and idx != null
				and absf(prev_btn.global_position.y - sec.global_position.y) < 24.0
				and absf(idx.global_position.y - sec.global_position.y) < 24.0,
				"ban nhung: dieu huong nam trong hang tieu de LUAT CHOI")
		# khối ĐIỂM vẫn hiện trong bản nhúng
		var pbox := view.get_node_or_null("Pages/Page1/Body/Top/Points") as Control
		var img1 := view.get_node_or_null("Pages/Page1/Body/Top/Image") as Control
		_check(pbox != null and pbox.visible, "ban nhung: khoi DIEM hien")
		_check(view.point_count() >= 1, "ban nhung: diem co chu")
		_check(img1 != null and pbox != null
				and pbox.global_position.x >= img1.global_position.x + img1.size.x - 1.0
				and img1.global_position.y < pbox.global_position.y + pbox.size.y
				and pbox.global_position.y < img1.global_position.y + img1.size.y,
				"ban nhung: ANH va DIEM nam CANH NHAU (cung hang HBox)")
		_check(img1 != null and sec != null
				and sec.global_position.y >= img1.global_position.y + img1.size.y - 1.0,
				"ban nhung: LUAT CHOI nam DUOI hang [ANH|DIEM]")

	# (c) Thu nhỏ khung -> chuyển sang NÚT dự phòng
	host.size = Vector2(300, 300)
	await process_frame
	await process_frame
	_check(fb != null and fb.visible, "khung qua nho -> hien nut du phong")
	_check(view == null or not view.visible, "khung qua nho -> an content nhung")

	# (d) Bấm nút dự phòng -> phát signal để GameScene mở popup
	_signal_fired = false
	if fb != null:
		fb.pressed.emit()
	_check(_signal_fired, "bam nut du phong -> phat instruction_requested")

	# (e) Khung to lại -> content nhúng hiện lại
	host.size = Vector2(994, 800)
	await process_frame
	await process_frame
	_check(view != null and view.visible and fb != null and not fb.visible, "khung to lai -> nhung hien lai")

	host.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# 8. MỌI TỈ LỆ KHUNG: [ẢNH|ĐIỂM] luôn CÙNG HÀNG, LUẬT CHƠI luôn ở DƯỚI, khối
#    ĐIỂM không tràn khung — nhờ bố cục CỐ ĐỊNH Body (VBox) / Top (HBox), không
#    còn trường hợp “điểm tụt xuống dưới ảnh” / điều hướng lệch theo tỉ lệ khung.
# ---------------------------------------------------------------------------
func _check_aspect_invariants() -> void:
	print("-- Bo cuc theo MOI ti le khung (Body VBox / Top HBox co dinh) --")
	var host := Control.new()
	host.size = Vector2(994, 800)
	root.add_child(host)
	var view := (load(INSTRUCTION_DIR + "minesweeper.tscn") as PackedScene).instantiate() as InstructionContent
	host.add_child(view)
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.set_embedded(true)
	await process_frame
	await process_frame
	for host_size in [Vector2(994, 800), Vector2(560, 560), Vector2(620, 700),
			Vector2(700, 620), Vector2(500, 640)]:
		host.size = host_size
		await process_frame
		await process_frame
		var img := view.get_node_or_null("Pages/Page1/Body/Top/Image") as Control
		var box := view.get_node_or_null("Pages/Page1/Body/Top/Points") as Control
		var sec := view.get_node_or_null("Pages/Page1/Body/Section") as Control
		var row_ok: bool = img != null and box != null and box.visible \
				and box.global_position.x >= img.global_position.x + img.size.x - 1.0 \
				and img.global_position.y < box.global_position.y + box.size.y \
				and box.global_position.y < img.global_position.y + img.size.y
		var inside_ok: bool = box != null \
				and box.global_position.y + box.size.y <= view.global_position.y + view.size.y + 1.0 \
				and box.global_position.x + box.size.x <= view.global_position.x + view.size.x + 1.0
		var below_ok: bool = box != null and sec != null \
				and sec.global_position.y >= box.global_position.y + box.size.y - 1.0 \
				and sec.global_position.x >= view.global_position.x - 1.0
		_check(row_ok and inside_ok and below_ok,
				"khung %s: [ANH|DIEM] cung hang + gon trong khung + LUAT CHOI o duoi" % str(host_size))
		# điều hướng luôn nằm trong hàng tiêu đề LUẬT CHƠI và không tràn mép phải
		var prev_btn := view.get_node_or_null("Prev") as Control
		var idx := view.get_node_or_null("Index") as Control
		var nav_ok: bool = sec != null and prev_btn != null and idx != null \
				and absf(prev_btn.global_position.y - sec.global_position.y) < 24.0 \
				and absf(idx.global_position.y - sec.global_position.y) < 24.0 \
				and idx.global_position.x + idx.size.x <= view.global_position.x + view.size.x + 1.0
		_check(nav_ok, "khung %s: dieu huong nam trong hang LUAT CHOI, khong tran mep" % str(host_size))
	host.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# Duyệt node / regex
# ---------------------------------------------------------------------------
func _walk(node: Node) -> Array:
	var out: Array = []
	for child in node.get_children():
		out.append(child)
		out.append_array(_walk(child))
	return out


func _regex(text: String, pattern: String) -> Array:
	var out: Array = []
	var re := RegEx.create_from_string(pattern)
	for m in re.search_all(text):
		out.append(m.get_string(1))
	return out


## Số/ký hiệu trên grid (1 · 15 · 01:24 · = · ? · S · F…) được ghi TRỰC TIẾP
func _is_literal(text: String) -> bool:
	if text == "S" or text == "F":
		return true
	return _letter_re.search(text) == null
