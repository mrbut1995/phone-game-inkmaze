extends SceneTree
## ============================================================================
## Test: POPUP HƯỚNG DẪN theo chế độ chơi (instruction)
##  1. Dữ liệu `Instruction`: 10 chế độ, mỗi chế độ 3 trang, ảnh + khoá dịch đủ
##  2. Popup: mở theo mode_id, đổi trang (nút/dots/vuốt/phím), khoá nút ở 2 đầu
##  3. Màn Game: nút Hướng dẫn cạnh nút Restart + bấm mở đúng chế độ đang chơi
## ============================================================================

var _failed := 0
var _checks := 0
var _gm_mode_backup := ""
var _gm_difficulty_backup := ""
var _gm_debug_backup := false


func _init() -> void:
	print("\n========================================================")
	print("  TEST: POPUP HƯỚNG DẪN (INSTRUCTION) THEO CHẾ ĐỘ")
	print("========================================================\n")

	await process_frame
	root.size = Vector2i(1080, 1920)

	var gm: Node = root.get_node_or_null("GameManager")
	if gm != null:
		_gm_mode_backup = str(gm.get("current_mode"))
		_gm_difficulty_backup = str(gm.get("current_difficulty"))
		_gm_debug_backup = bool(gm.get("debug_run"))

	_section_1_data()
	await _section_2_popup()
	await _section_3_game_screen()

	# Khôi phục trạng thái GameManager
	if gm != null:
		gm.set("current_mode", _gm_mode_backup)
		gm.set("current_difficulty", _gm_difficulty_backup)
		gm.set("debug_run", _gm_debug_backup)

	_finish()


func _finish() -> void:
	print("\n--------------------------------------------------------")
	if _failed == 0:
		print("  KET QUA: %d/%d CHECK PASS" % [_checks, _checks])
	else:
		print("  KET QUA: %d/%d CHECK FAIL" % [_failed, _checks])
	print("--------------------------------------------------------\n")
	quit(1 if _failed > 0 else 0)


# ---------------------------------------------------------------------------
# 1. Dữ liệu hướng dẫn của 10 chế độ
# ---------------------------------------------------------------------------
func _section_1_data() -> void:
	print("--- 1. Du lieu huong dan (Instruction) ---")
	var expected: Array[String] = [
		"blind_memory", "countdown_cost", "daily_classic", "dungeon", "fading_ink",
		"fog_of_war", "minesweeper", "play", "sum_path", "time_attack",
	]
	var ids := Instruction.mode_ids()
	_check(ids.size() == expected.size(), "Co du %d che do (dang %d)" % [expected.size(), ids.size()])
	for mode_id in expected:
		_check(ids.has(mode_id), "Co bo huong dan cho '%s'" % mode_id)

	var pages_ok := true
	var img_ok := true
	var key_ok := true
	var first_bad := ""
	for mode_id in expected:
		var pages := Instruction.pages_for(mode_id)
		if pages.size() != 3:
			pages_ok = false
			first_bad = mode_id
		for page in pages:
			var img := str(page.get("img", ""))
			if img.is_empty() or not ResourceLoader.exists(Instruction.image_path(img)):
				img_ok = false
				first_bad = img
			for field in ["title", "body"]:
				var key := str(page.get(field, ""))
				if key.is_empty() or tr(key) == key:
					key_ok = false
					first_bad = key
	_check(pages_ok, "Moi che do co dung 3 trang (loi dau tien: '%s')" % first_bad)
	_check(img_ok, "Anh minh hoa ton tai (loi dau tien: '%s')" % first_bad)
	_check(key_ok, "Khoa dich title/body deu co ban dich (loi dau tien: '%s')" % first_bad)

	var texture := load(Instruction.image_path("guide_control")) as Texture2D
	_check(texture != null and texture.get_size() == Vector2(780, 460),
		"Anh huong dan 780x460 (dang %s)" % (texture.get_size() if texture != null else "null"))

	# Chế độ lạ -> dùng bộ mặc định của "play"
	var fallback := Instruction.pages_for("khong_ton_tai")
	_check(fallback.size() == 3 and str(fallback[0].get("img", "")) == "guide_control",
		"Mode la -> dung bo huong dan mac dinh")
	_check(Instruction.page_count("minesweeper") == 3, "page_count('minesweeper') = 3")
	_check(Instruction.name_key("dungeon") == "STR_MODE_DUNGEON_NAME",
		"name_key('dungeon') = STR_MODE_DUNGEON_NAME (dang '%s')" % Instruction.name_key("dungeon"))


# ---------------------------------------------------------------------------
# 2. Popup: nội dung + chuyển trang
# ---------------------------------------------------------------------------
func _section_2_popup() -> void:
	print("--- 2. Popup huong dan ---")
	_check(_has_popup_registry(), "PopupManager co dang ky popup 'instruction'")
	_check(Popups.INSTRUCTION == "instruction", "Popups.INSTRUCTION = 'instruction'")

	var popup := Popups.open(Popups.INSTRUCTION, {"mode_id": "minesweeper"}) as InstructionPopup
	await process_frame
	await process_frame
	_check(popup != null, "Mo duoc popup huong dan")
	if popup == null:
		return
	_check(popup is InstructionPopup, "Popup dung class InstructionPopup")
	_check(popup.mode_id() == "minesweeper", "mode_id = minesweeper (dang '%s')" % popup.mode_id())
	_check(popup.page_count() == 3, "Co 3 trang (dang %d)" % popup.page_count())
	_check(popup.current_page() == 0, "Mac dinh mo trang dau")

	var lbl_title := popup.get_node_or_null("Panel/Content/Title") as Label
	var lbl_subtitle := popup.get_node_or_null("Panel/Content/Subtitle") as Label
	_check(lbl_title != null and lbl_title.text == tr("STR_INSTRUCTION_TITLE"),
		"Tieu de = 'HUONG DAN' (nhan '%s')" % (lbl_title.text if lbl_title != null else "?"))
	_check(lbl_subtitle != null and lbl_subtitle.text == tr("STR_INSTRUCTION_MODE").format([tr("STR_MODE_MINESWEEPER")]),
		"Phu de = ten che do (nhan '%s')" % (lbl_subtitle.text if lbl_subtitle != null else "?"))

	# Trang 1: CÁCH CHƠI (dùng chung)
	_check(popup.current_page_title() == tr("STR_INSTRUCTION_T_CONTROL"),
		"Trang 1 = 'CACH CHOI' (nhan '%s')" % popup.current_page_title())
	_check(popup.current_page_body() == tr("STR_INSTRUCTION_B_CONTROL"), "Trang 1 co noi dung huong dan")
	var image := popup.get_node_or_null("Panel/Content/PageImage") as TextureRect
	_check(image != null and image.texture == load(Instruction.image_path("guide_control")),
		"Trang 1 hien anh guide_control")

	# Dots + chỉ số trang
	_check(popup.dot_count() == 3, "Co 3 cham trang (dang %d)" % popup.dot_count())
	var lbl_index := popup.get_node_or_null("Panel/Content/PageIndex") as Label
	_check(lbl_index != null and lbl_index.text == tr("STR_INSTRUCTION_PAGE").format([1, 3]),
		"Chi so trang = 'TRANG 1/3' (nhan '%s')" % (lbl_index.text if lbl_index != null else "?"))

	# Nút ở trang đầu/cuối
	var btn_prev := popup.get_node_or_null("Panel/Content/PrevBtn") as TextureButton
	var btn_next := popup.get_node_or_null("Panel/Content/NextBtn") as TextureButton
	_check(btn_prev != null and btn_prev.disabled, "Trang dau: nut TRUOC bi khoa")
	_check(btn_next != null and not btn_next.disabled, "Trang dau: nut SAU bam duoc")

	# Sang trang 2 (nút SAU) -> LUẬT CHẾ ĐỘ
	if btn_next != null:
		btn_next.pressed.emit()
	await process_frame
	_check(popup.current_page() == 1, "Bam SAU -> trang 2")
	_check(popup.current_page_title() == tr("STR_MODE_MINESWEEPER"),
		"Trang 2 = ten che do (nhan '%s')" % popup.current_page_title())
	_check(image != null and image.texture == load(Instruction.image_path("mode_minesweeper")),
		"Trang 2 hien anh mode_minesweeper")
	_check(lbl_index != null and lbl_index.text == tr("STR_INSTRUCTION_PAGE").format([2, 3]),
		"Chi so trang = 2/3")

	# Trang 3 (thưởng) -> hết trang thì nút SAU bị khoá
	popup.next_page()
	await process_frame
	_check(popup.current_page() == 2, "next_page() -> trang 3")
	_check(popup.current_page_title() == tr("STR_INSTRUCTION_T_SCORE"),
		"Trang 3 = 'THU THACH & THUONG' (nhan '%s')" % popup.current_page_title())
	_check(btn_next != null and btn_next.disabled, "Trang cuoi: nut SAU bi khoa")
	_check(btn_prev != null and not btn_prev.disabled, "Trang cuoi: nut TRUOC bam duoc")
	popup.next_page()
	_check(popup.current_page() == 2, "next_page() o trang cuoi khong vuot qua")

	# go_to_page kẹp khoảng hợp lệ
	popup.go_to_page(99)
	_check(popup.current_page() == 2, "go_to_page(99) kep ve trang cuoi")
	popup.go_to_page(-5)
	_check(popup.current_page() == 0, "go_to_page(-5) kep ve trang dau")

	# Vuốt ngang: kéo sang TRÁI = trang kế
	_send_touch(Vector2(600, 400), true)
	_send_drag(Vector2(440, 400))
	_send_touch(Vector2(440, 400), false)
	await process_frame
	_check(popup.current_page() == 1, "Vuot sang trai -> sang trang ke (dang %d)" % popup.current_page())

	# Vuốt ngang: kéo sang PHẢI = trang trước
	_send_touch(Vector2(300, 400), true)
	_send_drag(Vector2(470, 400))
	_send_touch(Vector2(470, 400), false)
	await process_frame
	_check(popup.current_page() == 0, "Vuot sang phai -> ve trang truoc (dang %d)" % popup.current_page())

	# Kéo ngắn (dưới ngưỡng) KHÔNG đổi trang
	_send_touch(Vector2(400, 400), true)
	_send_drag(Vector2(410, 400))
	_send_touch(Vector2(410, 400), false)
	await process_frame
	_check(popup.current_page() == 0, "Keo ngan (< nguong) khong doi trang")

	# Bấm chấm trang = nhảy thẳng tới trang đó
	var dots := popup.get_node_or_null("Panel/Content/Dots") as HBoxContainer
	_check(dots != null and dots.get_child_count() == 3, "Cum dots co 3 cham")
	if dots != null and dots.get_child_count() == 3:
		var third := dots.get_child(2) as TextureButton
		third.pressed.emit()
		await process_frame
		_check(popup.current_page() == 2, "Bam cham thu 3 -> nhay toi trang 3")

	# Nút ĐÓNG đóng popup
	var btn_close := popup.get_node_or_null("Panel/Content/CloseBtn") as TextureButton
	_check(btn_close != null, "Co nut DONG")
	if btn_close != null:
		btn_close.pressed.emit()
	await create_timer(0.3).timeout
	_check(not Popups.has_open(), "Bam DONG -> popup dong han")

	# Mở lại với chế độ khác -> nội dung đổi theo
	var popup2 := Popups.open(Popups.INSTRUCTION, {"mode_id": "fading_ink"}) as InstructionPopup
	await process_frame
	await process_frame
	_check(popup2 != null and popup2.mode_id() == "fading_ink", "Mo lai voi mode fading_ink")
	if popup2 != null:
		popup2.go_to_page(1)
		_check(popup2.current_page_title() == tr("STR_MODE_FADING_INK"),
			"Trang 2 cua fading_ink = 'MUC PHAI' (nhan '%s')" % popup2.current_page_title())
		Popups.close_all()
		await create_timer(0.3).timeout


func _has_popup_registry() -> bool:
	# PopupManager là autoload: đọc POPUPS qua script của node (không tham chiếu identifier)
	var mgr: Node = root.get_node_or_null("PopupManager")
	if mgr == null:
		return false
	var script: GDScript = mgr.get_script() as GDScript
	if script == null:
		return false
	return (script.get_script_constant_map().get("POPUPS", {}) as Dictionary).has("instruction")


## Gửi sự kiện chạm vào popup đang mở (mô phỏng ngón tay)
func _send_touch(pos: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = pos
	event.pressed = pressed
	var popup := Popups.get_popup(Popups.INSTRUCTION)
	if popup != null:
		popup.call("_input", event)


## Gửi sự kiện kéo ngang vào popup đang mở
func _send_drag(pos: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = 0
	event.position = pos
	var popup := Popups.get_popup(Popups.INSTRUCTION)
	if popup != null:
		popup.call("_input", event)


# ---------------------------------------------------------------------------
# 3. Màn Game: nút Hướng dẫn cạnh Restart
# ---------------------------------------------------------------------------
func _section_3_game_screen() -> void:
	print("--- 3. Man Game: nut Huong dan canh nut Restart ---")
	var scene: GameScene = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var status := scene.get_node_or_null("Status")
	var help_btn := scene.get_node_or_null("Status/Instruction") as TextureButton
	var restart_btn := scene.get_node_or_null("Status/Restart") as TextureButton
	_check(help_btn != null, "Man Game co nut Huong dan (Status/Instruction)")
	_check(restart_btn != null, "Nut Restart van con")
	_check(help_btn != null and help_btn.texture_normal != null, "Nut Huong dan co art rieng")
	if status != null and help_btn != null and restart_btn != null:
		var help_index := help_btn.get_index()
		var restart_index := restart_btn.get_index()
		_check(restart_index == help_index + 1,
			"Nut Huong dan nam NGAY CANH nut Restart (index %d / %d)" % [help_index, restart_index])

	var controller: GameController = scene.get("game_controller")
	_check(controller != null and controller.has_method("open_instruction"),
		"GameController co open_instruction()")
	if help_btn != null and controller != null:
		_check(help_btn.pressed.is_connected(Callable(controller, "open_instruction")),
			"Nut Huong dan noi san toi GameController.open_instruction")

	# Bấm nút -> mở popup đúng chế độ đang chơi
	if help_btn != null:
		help_btn.pressed.emit()
	await process_frame
	await process_frame
	var popup := Popups.get_popup(Popups.INSTRUCTION) as InstructionPopup
	_check(popup != null, "Bam nut Huong dan -> mo popup")
	if popup != null and controller != null and controller.game_mode != null:
		_check(popup.mode_id() == controller.game_mode.mode_id,
			"Popup mo dung che do dang choi ('%s' vs '%s')" % [popup.mode_id(), controller.game_mode.mode_id])

	# Đóng popup rồi dọn scene
	Popups.close_all()
	await create_timer(0.3).timeout
	scene.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
func _check(ok: bool, message: String) -> void:
	_checks += 1
	if ok:
		print("  [PASS] " + message)
	else:
		_failed += 1
		print("  [FAIL] " + message)
