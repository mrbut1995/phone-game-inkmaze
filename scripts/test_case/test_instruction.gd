extends SceneTree
## ============================================================================
## Test: 11 popup HƯỚNG DẪN theo từng chế độ (nodes/popups/instruction/*.tscn).
##   - Mỗi chế độ 1 scene riêng: 3 trang, 3 tab, nav/CTA/link hoạt động.
##   - Trang 1: Prev khoá · trang 3: Next khoá (đúng như mockup).
##   - CTA trang cuối đóng popup · link trang cuối quay về trang 1 ·
##     link các trang trước (bỏ qua hướng dẫn) đóng popup.
##   - Mọi chữ trong scene dùng khoá STR_GI_* và có bản dịch ở CẢ vi lẫn en
##     (quét trực tiếp trong file .tscn — không phụ thuộc runtime).
##   - GameController.INSTRUCTION_SCENES phủ hết mode id, trỏ tới file tồn tại.
## ============================================================================

const MODES := ["normal_maze", "dungeon", "minesweeper", "sumpath", "countdowncost",
		"fadingink", "blindmemory", "fog_of_war", "time_attack", "one_stroke", "wall_builder"]
const MODE_IDS := ["play", "daily_classic", "time_attack", "dungeon", "minesweeper",
		"sum_path", "countdown_cost", "blind_memory", "fog_of_war", "fading_ink", "one_stroke",
		"wall_builder"]
const SKIP_TEXT_NODES := ["Index"]

var _failures := 0
var _checks := 0
## Ký tự chữ cái (Unicode) — chuỗi không có chữ cái được phép ghi trực tiếp
var _letter_re := RegEx.create_from_string("[\\p{L}]")


func _init() -> void:
	print("\n========================================================")
	print("  TEST: 11 POPUP HUONG DAN THEO CHE DO")
	print("========================================================\n")

	await process_frame

	_check_mapping()
	_check_keys_locales()

	TranslationServer.set_locale("vi")
	for mode in MODES:
		await _check_scene(mode)
	await _check_integration()

	if _failures == 0:
		print("\n[SUCCESS] %d check PASS — 11 popup huong dan chay dung, du chu 2 ngon ngu." % _checks)
	else:
		print("\n[FAILED] %d/%d check loi ve popup huong dan." % [_failures, _checks])
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


# ---------------------------------------------------------------------------
# 1. Bảng chế độ -> scene trong GameController
# ---------------------------------------------------------------------------
func _check_mapping() -> void:
	print("-- Bang che do -> scene --")
	for mode_id in MODE_IDS:
		var scene_name: String = GameController.INSTRUCTION_SCENES.get(mode_id, "")
		if scene_name.is_empty():
			_fail("mode '%s' chua co scene huong dan" % mode_id)
			continue
		var path := "res://nodes/popups/instruction/%s.tscn" % scene_name
		_check(ResourceLoader.exists(path), "%s -> %s.tscn" % [mode_id, scene_name])
	_ok("fallback = %s" % GameController.INSTRUCTION_FALLBACK)


# ---------------------------------------------------------------------------
# 2. Mọi khoá STR_* trong 9 file scene phải có bản dịch ở vi + en
# ---------------------------------------------------------------------------
func _check_keys_locales() -> void:
	print("-- Khoa dich STR_* trong scene --")
	var keys := {}
	for mode in MODES:
		var text := FileAccess.get_file_as_string(
				"res://nodes/popups/instruction/%s.tscn" % mode)
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
		_ok("%d khoa STR_GI_* deu co ban dich vi + en" % total)
	else:
		_fail("thieu ban dich: %s" % ", ".join(missing.slice(0, 6)))


func _regex(text: String, pattern: String) -> Array:
	var out: Array = []
	var rx := RegEx.new()
	rx.compile(pattern)
	for m in rx.search_all(text):
		out.append(m.get_string(1))
	return out


# ---------------------------------------------------------------------------
# 3. Từng scene popup
# ---------------------------------------------------------------------------
func _check_scene(mode: String) -> void:
	print("-- Scene %s --" % mode)
	var pop := await _open(mode)
	if pop == null:
		return

	# --- cấu trúc ---
	_check(pop.page_count() == 3, "%s: co 3 trang" % mode)
	if pop.page_count() != 3:
		pop.queue_free()
		await process_frame
		return

	# --- mọi chữ là khoá dịch hoặc số/ký hiệu ghi trực tiếp ---
	var untranslated := 0
	var missing := 0
	var literal := 0
	for node in _walk(pop.get_node("Panel/Guide")):
		var text := ""
		if node is Label:
			text = (node as Label).text
		elif node is Button:
			text = (node as Button).text
		if text.is_empty() or String(node.name) in SKIP_TEXT_NODES:
			continue
		if _is_literal(text):
			literal += 1
			continue
		if not text.begins_with("STR_"):
			untranslated += 1
			if untranslated <= 3:
				_fail("%s: chu chua dich '%s' (%s)" % [mode, text, node.get_path()])
			continue
		var value := tr(text)
		if value == text or value.strip_edges().is_empty():
			missing += 1
			if missing <= 3:
				_fail("%s: thieu ban dich cho '%s'" % [mode, text])
	_check(untranslated == 0, "%s: moi chu deu la khoa dich" % mode)
	_check(missing == 0, "%s: khoa dich deu co ban tieng Viet" % mode)
	_check(literal > 0, "%s: %d chu so/ky hieu ghi truc tiep" % [mode, literal])

	# --- chrome dùng chung: tab/nav/dots chỉ có 1 bộ ngoài Pages ---
	for shared in ["Tabs/Tab1", "Tabs/Tab2", "Tabs/Tab3", "Prev", "Next", "Dots/Dot1", "Index"]:
		_check(pop.get_node_or_null("Panel/Guide/%s" % shared) != null,
				"%s: co node dung chung %s" % [mode, shared])
	var p1_node := pop.get_node_or_null("Panel/Guide/Pages/Page1")
	if p1_node != null:
		var leaked := []
		for shared in ["Tabs", "Prev", "Next", "Dots", "Index"]:
			if p1_node.get_node_or_null(shared) != null:
				leaked.append(shared)
		_check(leaked.is_empty(), "%s: Page1 khong lap lai %s" % [mode, leaked])

	# --- trang 1 ---
	_check(pop.tab_count() == 3, "%s: co 3 tab" % mode)
	_check(not pop.tab_label(0).is_empty() and not pop.tab_label(0).begins_with("STR_"),
			"%s: tab 1 = '%s'" % [mode, pop.tab_label(0)])
	_check(pop.is_prev_locked(), "%s: trang 1 khoa nut Prev" % mode)
	_check(not pop.is_next_locked(), "%s: trang 1 mo nut Next" % mode)
	_check(not pop.cta_text().is_empty() and not pop.cta_text().begins_with("STR_"),
			"%s: CTA trang 1 = '%s'" % [mode, pop.cta_text()])
	_check(not pop.link_text().is_empty() and not pop.link_text().begins_with("STR_"),
			"%s: link trang 1 = '%s'" % [mode, pop.link_text()])
	_check(pop.page_index_text() != "", "%s: nhan trang = '%s'" % [mode, pop.page_index_text()])

	# --- bấm tab 2 -> sang trang 2 ---
	var tab2 := pop.get_node_or_null("Panel/Guide/Tabs/Tab2") as Button
	if tab2 == null:
		_fail("%s: khong tim thay Tab2" % mode)
	else:
		tab2.pressed.emit()
		_check(pop.current_page() == 1, "%s: bam Tab2 -> trang 2" % mode)
	_check(pop.current_page() == 1 and not pop.is_prev_locked() and not pop.is_next_locked(),
			"%s: trang 2 mo ca Prev lan Next" % mode)

	# --- bấm dot 3 -> sang trang 3 ---
	var dot3 := pop.get_node_or_null("Panel/Guide/Dots/Dot3") as Button
	if dot3 == null:
		_fail("%s: khong tim thay Dot3" % mode)
	else:
		dot3.pressed.emit()
		_check(pop.current_page() == 2, "%s: bam Dot3 -> trang 3" % mode)

	# --- bấm Prev -> về trang 2 ---
	var prev_btn := pop.get_node_or_null("Panel/Guide/Prev") as Button
	if prev_btn != null and not prev_btn.disabled:
		prev_btn.pressed.emit()
		_check(pop.current_page() == 1, "%s: Prev -> trang 2" % mode)

	# --- bấm Next (trang 2) -> trang 3 ---
	var next_btn := pop.get_node_or_null("Panel/Guide/Next") as Button
	if next_btn == null or next_btn.disabled:
		_fail("%s: nut Next trang 2 phai bam duoc" % mode)
	else:
		next_btn.pressed.emit()
		_check(pop.current_page() == 2, "%s: Next -> trang 3" % mode)
	_check(pop.is_next_locked(), "%s: trang 3 khoa nut Next" % mode)

	# --- link trang cuối: quay về trang 1 (không đóng) ---
	pop.link_button().pressed.emit()
	_check(pop.current_page() == 0 and not pop.is_closing(),
			"%s: link trang cuoi quay ve trang 1" % mode)

	# --- CTA các trang trước: sang trang kế ---
	pop.cta_button().pressed.emit()
	_check(pop.current_page() == 1, "%s: CTA trang 1 -> trang 2" % mode)
	pop.cta_button().pressed.emit()
	_check(pop.current_page() == 2, "%s: CTA trang 2 -> trang 3" % mode)

	pop.queue_free()
	await process_frame

	# --- CTA trang cuối: đóng popup (instance riêng) ---
	var pop2 := await _open(mode)
	if pop2 != null:
		pop2.go_to_page(2)
		pop2.cta_button().pressed.emit()
		_check(pop2.is_closing(), "%s: CTA trang cuoi dong popup" % mode)
		pop2.queue_free()
		await process_frame

	# --- link trang 1: bỏ qua hướng dẫn -> đóng popup (instance riêng) ---
	var pop3 := await _open(mode)
	if pop3 != null:
		pop3.link_button().pressed.emit()
		_check(pop3.is_closing(), "%s: link trang 1 dong popup" % mode)
		pop3.queue_free()
		await process_frame

	# --- nút X (Close): bấm là ĐÓNG popup (instance riêng) ---
	var pop4 := await _open(mode)
	if pop4 != null:
		var close_btn := pop4.close_button()
		if close_btn == null:
			_fail("%s: khong tim thay nut Close (X) — kiem tra cast BaseButton" % mode)
		else:
			close_btn.pressed.emit()
			_check(pop4.is_closing(), "%s: bam nut X dong popup" % mode)
		pop4.queue_free()
		await process_frame


# ---------------------------------------------------------------------------
# 4. Tích hợp: nút "?" trên HUD mở đúng scene hướng dẫn của chế độ
# ---------------------------------------------------------------------------
func _check_integration() -> void:
	print("-- Tich hop: nut ? mo dung scene theo che do --")
	var gm: Node = root.get_node_or_null("GameManager")
	if gm == null:
		_fail("Khong tim thay autoload GameManager")
		return
	var cases := [["dungeon", "STR_GI_DUNGEON_CHIP"],
			["play", "STR_GI_NORMAL_MAZE_CHIP"],
			["time_attack", "STR_GI_TIME_ATTACK_CHIP"]]
	for c in cases:
		gm.set("current_mode", c[0])
		gm.set("current_level", 1)
		gm.set("unlocked_levels", 99)
		var packed: PackedScene = load("res://scenes/game.tscn")
		var scene: GameScene = packed.instantiate()
		root.add_child(scene)
		await process_frame
		await process_frame
		var gc: GameController = scene.game_controller
		gc.open_instruction()
		await process_frame
		var pop := Popups.top()
		var chip := pop.get_node_or_null("Panel/Guide/ChipText") as Label if pop != null else null
		var ok: bool = pop is InstructionPopup and pop.page_count() == 3 \
				and chip != null and chip.text == c[1]
		_check(ok, "%s: nut ? -> '%s' (chip %s)" % [
				c[0], pop.popup_id if pop != null else "<null>",
				chip.text if chip != null else "?"])
		Popups.close_all()
		await process_frame
		await process_frame
		scene.queue_free()
		await process_frame


## Mở 1 popup đã ở trong cây scene (đủ frame để _ready chạy xong)
func _open(mode: String) -> InstructionPopup:
	var ps: PackedScene = load("res://nodes/popups/instruction/%s.tscn" % mode)
	if ps == null:
		_fail("%s: khong load duoc scene" % mode)
		return null
	var pop: InstructionPopup = ps.instantiate() as InstructionPopup
	if pop == null:
		_fail("%s: scene khong gan InstructionPopup" % mode)
		return null
	root.add_child(pop)
	await process_frame
	return pop


# ---------------------------------------------------------------------------
# Duyệt node
# ---------------------------------------------------------------------------
func _walk(node: Node) -> Array:
	var out: Array = []
	for child in node.get_children():
		out.append(child)
		out.append_array(_walk(child))
	return out


## Số/ký hiệu trên grid (1 · 15 · 01:24 · = · ? · S · F…) được ghi TRỰC TIẾP
func _is_literal(text: String) -> bool:
	if text == "S" or text == "F":
		return true
	return _letter_re.search(text) == null
