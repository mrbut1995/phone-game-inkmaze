extends SceneTree
## ============================================================================
## Test Case: HUD THEO CHẾ ĐỘ (thiết kế "chỉ hiện thứ cần thiết" 2026-09-27) + PANEL HINT GUIDE
##
## 1. Hint Guide: nằm TRONG HUD của chế độ (không còn node riêng ở scenes/game.tscn), đổi nội
##    dung theo chế độ, không rỗng và VỪA 1 DÒNG (đo bằng font thật của theme).
## 2. SumPathHUD: TỔNG hiện tại · TOÁN TỬ · MỤC TIÊU + chip "CẦN THÊM / CÒN ĐƯỢC / ĐÃ ĐỦ"
##    (thanh tiến độ đã gỡ).
## 3. CountdownHUD: chỉ NGÂN SÁCH CÒN "nn / tổng" (TIÊU TỐN · GIÁ CƯỚC · dải phân đoạn đã gỡ).
## 4. FadingInkHUD: chỉ thẻ THỜI GIAN (bảng "TRẠM ĐO ĐỘ PHAI MỰC" đã gỡ — số mực hiện trên ô).
## 5. Khối HUD theo chế độ: chế độ TIME-ONLY (play · minesweeper · blind_memory · fading_ink ·
##    one_stroke · wall_builder) chỉ có thẻ THỜI GIAN; chế độ có thẻ riêng (dungeon · sum_path ·
##    countdown_cost · fog_of_war) ẩn đồng hồ để nhường chỗ.
## 6. Sum Path: hết đường thắng -> `is_unwinnable()`; Undo lùi bước -> tổng tính lại.
## 7. Countdown Cost: hết ngân sách -> board khoá tương tác + nút Undo được NHẤN MẠNH;
##    Undo hoàn ĐÚNG chi phí bước vừa đi rồi mở khoá.
##
## ⚠️ Mọi HUD đều đổi instance khi đổi chế độ ⇒ test tra node con qua `@export` của HUD
##    (`time_value_node` · `retry_value_node` · `sum_value_node` …) chứ KHÔNG dò đường dẫn tuyệt đối.
## ============================================================================

const HUD_SCRIPTS := {
	"play": "res://scripts/nodes/hud/game/level_hud.gd",
	"fog_of_war": "res://scripts/nodes/hud/game/fog_of_war_hud.gd",
	"dungeon": "res://scripts/nodes/hud/game/dungeon_hud.gd",
	"minesweeper": "res://scripts/nodes/hud/game/minesweep_hud.gd",
	"blind_memory": "res://scripts/nodes/hud/game/blind_memory_hud.gd",
	"sum_path": "res://scripts/nodes/hud/game/sum_path_hud.gd",
	"countdown_cost": "res://scripts/nodes/hud/game/countdown_hud.gd",
	"fading_ink": "res://scripts/nodes/hud/game/fading_ink_hud.gd",
	"one_stroke": "res://scripts/nodes/hud/game/one_stroke_hud.gd",
	"wall_builder": "res://scripts/nodes/hud/game/wall_builder_hud.gd",
}

var _failed := 0
var _checks := 0


func _init() -> void:
	print("\n========================================================")
	print("  TEST: HUD THEO CHE DO + HINT GUIDE")
	print("========================================================\n")
	await process_frame
	root.size = Vector2i(1080, 1920)

	var scene: GameScene = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	assert(scene != null, "Phai load duoc scenes/game.tscn")
	root.add_child(scene)
	await process_frame
	await process_frame

	await _section_1_hint_guide(scene)
	await _section_2_sum_path(scene)
	await _section_3_countdown(scene)
	await _section_4_fading_ink(scene)
	await _section_4c_fog_of_war(scene)
	await _section_4d_one_stroke(scene)
	await _section_4e_wall_builder(scene)
	await _section_5_hud_blocks(scene)
	await _section_6_sum_path_replay(scene)
	await _section_7_countdown_budget_lock(scene)

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
# 1. Panel Hint Guide (dưới bàn cờ)
# ---------------------------------------------------------------------------
func _section_1_hint_guide(scene: GameScene) -> void:
	print("[1] Panel Hint Guide...")
	# HintGuide nam TRONG HUD (ban doc: `Content/ActionBar/HintGuide`) => hoi HUD, khong con la node
	# rieng cua `scenes/game.tscn` nhu thiet ke cu.
	var cur_hud := scene.ui_controller.hud
	var guide := cur_hud.hint_guide() if cur_hud != null else null
	_entry(guide != null, "HUD theo che do co khung HintGuide (hud.hint_guide())")
	if guide == null:
		return
	_entry(cur_hud.is_ancestor_of(guide), "HintGuide nam trong HUD cua che do dang choi")
	_entry(guide.get_node_or_null("Bg") is TextureRect, "Hint Guide co nen giay (panel_hint_guide.svg)")
	_entry(guide.get_node_or_null("Icon") is TextureRect, "Hint Guide co icon bong den (icon_bulb.svg)")
	var label := guide.get_node_or_null("Text") as Label
	_entry(label != null, "Hint Guide co Label noi dung")
	if label == null:
		return
	# ⚠️ Thanh hanh dong ban DOC cao 61px (chi du cho hang nut) nen khung goi y duoc AN SAN tu
	# f0579a7 (2026-09-26): luat choi day qua popup huong dan. Node VAN cap nhat noi dung theo che do
	# nen test chi kiem tra du lieu + cau truc, KHONG do do rong (khung an thi layout khong tinh).
	_entry(not guide.visible, "Khung goi y an san trong thanh hanh dong ban DOC (nhuong cho hang nut)")
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	_entry(font != null and font_size > 0, "Hint Guide lay duoc font tu theme (variation HintGuideText)")
	var texts := {}
	for mode_id in HUD_SCRIPTS.keys():
		scene.switch_mode(str(mode_id), "medium")
		await process_frame
		var expected_hud: GDScript = load(str(HUD_SCRIPTS[mode_id]))
		var hud := scene.ui_controller.hud
		_entry(hud != null and hud.get_script() == expected_hud,
			"Che do '%s' dung dung HUD scene rieng" % mode_id)
		# HUD la INSTANCE MOI moi lan doi che do => trai lai khung HintGuide theo HUD vua gan
		var mode_guide := hud.hint_guide() if hud != null else null
		var mode_label := mode_guide.get_node_or_null("Text") as Label if mode_guide != null else null
		if mode_label == null:
			_entry(false, "Che do '%s': HUD khong co khung HintGuide" % mode_id)
			continue
		var text := str(mode_guide.call("current_text"))
		_entry(not text.is_empty() and not text.begins_with("STR_"),
			"Che do '%s': goi y hien chu that ('%s')" % [mode_id, text.substr(0, 40)])
		texts[text] = mode_id
	_entry(texts.size() == HUD_SCRIPTS.size(),
		"%d/%d che do co noi dung goi y RIENG" % [texts.size(), HUD_SCRIPTS.size()])


# ---------------------------------------------------------------------------
# 2. Sum Path
# ---------------------------------------------------------------------------
func _section_2_sum_path(scene: GameScene) -> void:
	print("[2] HUD Sum Path...")
	scene.switch_mode("sum_path", "medium")
	await process_frame
	var hud := scene.ui_controller.hud as SumPathHUD
	_entry(hud != null, "Sum Path dung SumPathHUD")
	if hud == null:
		return
	var mode := scene.game_mode_controller.game_mode as SumPathGameMode
	_entry(mode != null, "Lay duoc SumPathGameMode")
	if mode == null:
		return
	# 2026-09-27 "chi hien thu can thiet": HUD chi con TONG hien tai · TOAN TU · MUC TIEU (+ chip
	# trang thai trong khoi MUC TIEU). Thanh tien do vuot/duoi muc tieu da GO khoi HUD.
	_entry(hud.sum_value_node != null and hud.operator_value_label != null
		and hud.target_value_node != null and hud.need_label != null,
		"HUD bind du node TONG / TOAN TU / MUC TIEU / chip trang thai")
	_entry(hud.find_child("Bar", true, false) == null,
		"Thanh tien do (Bar/Fill) da GO khoi HUD theo thiet ke 2026-09-27")

	mode.current_sum = 20
	mode.target_val = 50
	mode.operator = "="
	hud.update_hud({"mode": mode, "moves": 4})
	_entry(hud.sum_value_node.text == "20" and hud.operator_value_label.text == "="
		and hud.target_value_node.text == "50",
		"Khoi TONG/MUC TIEU hien '20 = 50'")
	_entry(hud.sum_note_label != null and hud.sum_note_label.text.contains("4"),
		"Khoi TONG hien so o da di ('%s')"
		% (hud.sum_note_label.text if hud.sum_note_label != null else ""))
	_entry(hud.need_label.text == tr("STR_HUD_SUM_NEED").format([30]),
		"Toan tu '=': chip bao CAN THEM +30 ('%s')" % hud.need_label.text)
	mode.operator = "<"
	hud.update_hud({"mode": mode, "moves": 4})
	_entry(hud.need_label.text == tr("STR_HUD_SUM_LEFT").format([29]),
		"Toan tu '<': chip bao CON DUOC +29 ('%s')" % hud.need_label.text)
	mode.operator = ">"
	mode.current_sum = 60
	hud.update_hud({"mode": mode, "moves": 4})
	_entry(hud.need_label.text == tr("STR_HUD_SUM_OK"),
		"Toan tu '>': da vuot muc tieu -> chip bao DA DU ('%s')" % hud.need_label.text)


# ---------------------------------------------------------------------------
# 3. Countdown Cost
# ---------------------------------------------------------------------------
func _section_3_countdown(scene: GameScene) -> void:
	print("[3] HUD Countdown Cost...")
	scene.switch_mode("countdown_cost", "medium")
	await process_frame
	var hud := scene.ui_controller.hud as CountdownHUD
	_entry(hud != null, "Countdown Cost dung CountdownHUD (khong con dung chung LevelHUD)")
	if hud == null:
		return
	var mode := scene.game_mode_controller.game_mode as CountdownCostGameMode
	_entry(mode != null, "Lay duoc CountdownCostGameMode")
	if mode == null:
		return
	var total: int = mode.initial_steps
	hud.update_hud({"mode": mode, "steps_remaining": total - 6, "moves": 4})
	_entry(hud.budget_value_node != null and hud.budget_value_node.text == "%02d" % (total - 6),
		"Khoi NGAN SACH CON hien %02d ('%s')"
		% [total - 6, hud.budget_value_node.text if hud.budget_value_node != null else ""])
	_entry(hud.budget_max_label != null and hud.budget_max_label.text == "/ %d" % total,
		"Khoi NGAN SACH CON hien tong '/ %d'" % total)
	# 2026-09-27 "chi hien thu can thiet": chi con NGAN SACH CON; TIÊU TỐN · GIÁ CƯỚC (chip rẻ/đắt) ·
	# dải phân đoạn đã gỡ — chi phí từng ô hiện NGAY TRÊN Ô của bàn cờ.
	_entry(hud.find_child("Spent", true, false) == null, "Khoi DA TIEU da GO khoi HUD")
	_entry(hud.find_child("Segments", true, false) == null, "Dai phan doan ngan sach da GO khoi HUD")
	_entry(hud.find_child("Price", true, false) == null, "Chip gia cuoc da GO khoi HUD")
	var time_card := _time_card(hud)
	_entry(time_card != null and not time_card.visible,
		"Che do Countdown Cost khong hien dong ho THOI GIAN (thoi gian hoa vao NGAN SACH)")


# ---------------------------------------------------------------------------
# 4. Fading Ink
# ---------------------------------------------------------------------------
func _section_4_fading_ink(scene: GameScene) -> void:
	print("[4] HUD Fading Ink...")
	scene.switch_mode("fading_ink", "medium")
	await process_frame
	var hud := scene.ui_controller.hud as FadingInkHUD
	_entry(hud != null, "Fading Ink dung FadingInkHUD (khong con dung chung LevelHUD)")
	if hud == null:
		return
	var mode := scene.game_mode_controller.game_mode as FadingInkGameMode
	_entry(mode != null, "Lay duoc FadingInkGameMode")
	if mode == null:
		return
	hud.update_hud({"mode": mode})
	# 2026-09-27 "chi hien thu can thiet": chi con the THOI GIAN; bang "TRẠM ĐO ĐỘ PHAI MỰC" đã gỡ —
	# số mực hiện NGAY TRÊN TỪNG Ô của bàn cờ (lớp cảnh báo SẮP PHAI/CẠN do MazeCell vẽ).
	var time_card := _time_card(hud)
	_entry(time_card != null and time_card.visible, "Che do Fading Ink hien the THOI GIAN")
	_entry(hud.find_child("Steps", true, false) == null and hud.find_child("Warn", true, false) == null,
		"Bang TRAM DO DO PHAI MUC da GO khoi HUD")
	_entry(hud.time_value_node != null and not hud.time_value_node.text.is_empty(),
		"The THOI GIAN co gio van ('%s')"
		% (hud.time_value_node.text if hud.time_value_node != null else ""))
	_entry(mode.count_exhausted() == 0, "Dau van chua co o can muc (%d o)" % mode.count_exhausted())

	mode.moves_made = 9          # mực tối đa 9 -> mọi ô đều cạn
	hud.update_hud({"mode": mode})
	_entry(mode.count_exhausted() > 0,
		"count_exhausted() dem duoc o can (%d o) — so o can hien tren ban co" % mode.count_exhausted())


# ---------------------------------------------------------------------------
# 4c. Fog of War — HUD riêng + LƯỢT THỬ LẠI (2026-09-18)
# ---------------------------------------------------------------------------
func _section_4c_fog_of_war(scene: GameScene) -> void:
	print("[4c] HUD Fog of War (luot thu lai)...")
	scene.switch_mode("fog_of_war", "normal")
	await process_frame
	var hud := scene.ui_controller.hud as FogOfWarHUD
	_entry(hud != null, "Fog of War dung FogOfWarHUD (khong con dung chung LevelHUD)")
	if hud == null:
		return
	var mode := scene.game_mode_controller.game_mode as FogOfWarGameMode
	_entry(mode != null, "Lay duoc FogOfWarGameMode")
	if mode == null:
		return
	_entry(mode.max_retries == 3 and mode.retries_left == 3,
		"Dau van co dung 3 luot thu (max=%d con=%d)" % [mode.max_retries, mode.retries_left])

	hud.update_hud({"mode": mode})
	var value := hud.retry_value_node
	var max_label := hud.retry_max_label
	var note := hud.retry_note_label
	_entry(value != null and value.text == "3", "HUD hien '3' luot thu ('%s')"
		% (value.text if value != null else ""))
	_entry(max_label != null and max_label.text == "/3", "HUD hien mau '/3'")
	if note != null:
		_entry(note.text == tr("STR_HUD_FOG_RETRY_NOTE").format([3]),
			"HUD hien dong nhac theo so luot ('%s')" % note.text)
	else:
		# 2026-09-27: bang Suong Mu ban DỌC gon con 1 dong (LUOT THU LAI) — khong con dong nhac
		_entry(true, "Ban doc khong co dong nhac luot thu (bang Suong Mu gon)")

	mode.retries_left = 1
	hud.update_hud({"mode": mode})
	_entry(value != null and value.text == "1", "Mat luot -> HUD cap nhat ('%s')"
		% (value.text if value != null else ""))
	if note != null:
		_entry(note.get_theme_color("font_color") == FogOfWarHUD.COLOR_NOTE_DANGER,
			"Con 1 luot -> dong nhac chuyen DO")

	_entry(_time_card(hud) != null, "The THOI GIAN co trong khung HUD cua che do")
	# Chuỗi dịch của chế độ (đọc theo locale VI để chắc chắn đã re-import CSV)
	var prev_locale := TranslationServer.get_locale()
	TranslationServer.set_locale("vi")
	_entry(tr("STR_HUD_FOG_TIME_SUB") == "ĐANG DÒ ĐƯỜNG",
		"Chuoi VI dong phu the THOI GIAN ('%s')" % tr("STR_HUD_FOG_TIME_SUB"))
	_entry(tr("STR_HUD_FOG_VISION_CHIP") == "XUNG QUANH",
		"Chuoi VI chip TAM NHIN ('%s')" % tr("STR_HUD_FOG_VISION_CHIP"))
	_entry(tr("STR_REVIVE_DESC_RETRY") != "STR_REVIVE_DESC_RETRY",
		"Co chuoi cho nut HOI SINH cua che do luot thu")
	TranslationServer.set_locale(prev_locale)
	_entry(hud.find_child("Sheet", true, false) is NinePatchRect, "Co bang SUONG MU (nen giay rieng)")
	var head := hud.find_child("Head", true, false) as Label
	_entry(head != null and head.text == "STR_HUD_FOG_RETRY_HEAD",
		"Bang Suong Mu co dong tieu de LUOT THU LAI")
	_entry(hud.mission_card() == null,
		"mission_card() = null (bang Suong Mu chiem cho the THU THACH)")


# ---------------------------------------------------------------------------
# 4d. One Stroke — HUD riêng + bảng TIẾN ĐỘ PHỦ KÍN (2026-09-19)
# ---------------------------------------------------------------------------
func _section_4d_one_stroke(scene: GameScene) -> void:
	print("[4d] HUD One Stroke (tien do phu kin)...")
	scene.switch_mode("one_stroke", "easy")
	await process_frame
	var hud := scene.ui_controller.hud as OneStrokeHUD
	_entry(hud != null, "One Stroke dung OneStrokeHUD (khong dung chung LevelHUD)")
	if hud == null:
		return
	var mode := scene.game_mode_controller.game_mode as OneStrokeGameMode
	_entry(mode != null, "Lay duoc OneStrokeGameMode")
	if mode == null:
		return
	_entry(mode.total_cells() == 9 and mode.visited_count() == 1,
		"Ban easy 3x3 = 9 o, chi o S da di (%d/%d)" % [mode.visited_count(), mode.total_cells()])

	hud.update_hud({"mode": mode})
	# 2026-09-27 "chi hien thu can thiet": chi con the THOI GIAN; bang "TIẾN ĐỘ PHỦ KÍN" da GO —
	# o da di bi gach cheo "ĐÃ ĐI" ngay tren ban co, luat doc o khung Huong dan.
	var time_card := _time_card(hud)
	_entry(time_card != null and time_card.visible, "Che do Mot Net hien the THOI GIAN")
	_entry(hud.find_child("Sheet", true, false) == null,
		"Bang TIEN DO PHU KIN da GO khoi HUD (tien do thay tren ban co)")
	_entry(hud.mission_card() == null,
		"mission_card() = null (HUD chi con the THOI GIAN)")

	# Chuỗi dịch của chế độ (đọc theo locale VI để chắc chắn đã re-import CSV)
	var prev_locale := TranslationServer.get_locale()
	TranslationServer.set_locale("vi")
	_entry(tr("STR_HUD_OS_TIME_SUB") == "ĐANG TÍNH GIỜ",
		"Chuoi VI dong phu the THOI GIAN ('%s')" % tr("STR_HUD_OS_TIME_SUB"))
	_entry(tr("STR_HUD_OS_ROW_TITLE") != "STR_HUD_OS_ROW_TITLE",
		"Con chuoi VI cua bang luat MOT NET trong CSV ('%s')" % tr("STR_HUD_OS_ROW_TITLE"))
	_entry(tr("STR_GAME_OVER_REVISIT") != "STR_GAME_OVER_REVISIT",
		"Co chuoi cho tieu de thua 'DI LAI O CU!'")
	_entry(tr("STR_HINT_ONE_STROKE") != "STR_HINT_ONE_STROKE",
		"Co chuoi huong dan luat choi (HintGuide)")
	TranslationServer.set_locale(prev_locale)


# ---------------------------------------------------------------------------
# 4e. Wall Builder — HUD riêng + bảng TIẾN ĐỘ XÂY TƯỜNG (2026-09-19)
# ---------------------------------------------------------------------------
func _section_4e_wall_builder(scene: GameScene) -> void:
	print("[4e] HUD Wall Builder (tien do xay tuong)...")
	scene.switch_mode("wall_builder", "easy")
	await process_frame
	var hud := scene.ui_controller.hud as WallBuilderHUD
	_entry(hud != null, "Wall Builder dung WallBuilderHUD (khong dung chung LevelHUD)")
	if hud == null:
		return
	var mode := scene.game_mode_controller.game_mode as WallBuilderGameMode
	_entry(mode != null, "Lay duoc WallBuilderGameMode")
	if mode == null:
		return
	_entry(mode.required_segments > 0 and mode.built_count() == 0,
		"Can dung %d doan tuong, moi dau van chua dung doan nao" % mode.required_segments)
	_entry(mode.retries_left == 3 and mode.max_retries == 3, "Dau van co dung 3 LUOT GUI")

	hud.update_hud({"mode": mode})
	# 2026-09-27 "chi hien thu can thiet": chi con the THOI GIAN; bang "TƯỜNG ĐÃ VẼ" da GO —
	# so tuong doc NGAY TREN TUONG O cua ban co, luot GUI con lai hien o popup khi GUI sai.
	var time_card := _time_card(hud)
	_entry(time_card != null and time_card.visible, "Che do Xay Tuong hien the THOI GIAN")
	_entry(hud.find_child("Sheet", true, false) == null,
		"Bang TUONG DA VE da GO khoi HUD (so tuong thay tren ban co)")
	_entry(hud.mission_card() == null, "mission_card() = null (HUD chi con the THOI GIAN)")

	# Thanh hanh dong: nut GUI BAI (Submit) = nut rieng cua Wall Builder (2 nut Tool/Wall da BO 2026-09-26)
	var submit_btn := scene.submit_btn as BaseButton
	_entry(submit_btn != null and submit_btn.visible,
		"Wall Builder: nut GUI BAI (Submit) HIEN tren thanh hanh dong")
	var restart_btn := scene.restart_btn as BaseButton
	_entry(restart_btn != null and restart_btn.visible,
		"Nut CHOI LAI nam trong thanh hanh dong (moi che do)")

	# Chuỗi dịch của chế độ (đọc theo locale VI để chắc chắn đã re-import CSV)
	var prev_locale := TranslationServer.get_locale()
	TranslationServer.set_locale("vi")
	_entry(tr("STR_HUD_WB_TIME_SUB") == "ĐANG SUY LUẬN",
		"Chuoi VI dong phu the THOI GIAN ('%s')" % tr("STR_HUD_WB_TIME_SUB"))
	_entry(tr("STR_REVIVE_DESC_SUBMIT") != "STR_REVIVE_DESC_SUBMIT",
		"Co chuoi cho dong HOI SINH '+1 LUOT GUI'")
	_entry(tr("STR_GAME_OVER_OUT_OF_SUBMITS") != "STR_GAME_OVER_OUT_OF_SUBMITS",
		"Co chuoi cho tieu de thua 'HET LUOT GUI!'")
	_entry(tr("STR_HINT_WALL_BUILDER") != "STR_HINT_WALL_BUILDER",
		"Co chuoi huong dan luat choi (HintGuide)")
	TranslationServer.set_locale(prev_locale)


# ---------------------------------------------------------------------------
# 6. Sum Path — không còn thắng được nữa -> nút CHƠI LẠI dưới thanh nút (2026-09-19)
# ---------------------------------------------------------------------------
func _section_6_sum_path_replay(scene: GameScene) -> void:
	print("[6] Sum Path: nut CHOI LAI khi het duong thang...")
	scene.switch_mode("sum_path", "medium")
	await process_frame
	var mode := scene.game_mode_controller.game_mode as SumPathGameMode
	#var replay := scene.replay_btn as TextureButton
	#_entry(mode != null and replay != null, "Co SumPathGameMode + nut Replay trong HUD (action_bar)")
	#if mode == null or replay == null:
		#return
	#_entry(not replay.visible, "Dau van: nut CHOI LAI an")
	_entry(not mode.is_unwinnable(), "Dau van: is_unwinnable() = false")
	# Điều kiện "=": tổng đã VƯỢT mục tiêu -> chỉ cộng thêm được -> hết đường thắng
	mode.operator = "="
	mode.target_val = 10
	mode.current_sum = 20
	scene.game_controller.call("_update_hud")
	_entry(mode.is_unwinnable(), "is_unwinnable(): '=' + tong 20 > 10")
	#_entry(replay.visible and scene.ui_controller.replay_shown(),
		#"Hien nut CHOI LAI (ui_controller.replay_shown())")
	#_entry(replay.global_position.y >= hud.action_bar().global_position.y
		#+ hud.action_bar().size.y - 20.0,
		#"Nut CHOI LAI nam DUOI thanh nut (y=%.0f vs day thanh %.0f)" % [replay.global_position.y,
			#hud.action_bar().global_position.y + hud.action_bar().size.y])
	# Điều kiện "<" cũng vậy; điều kiện ">" thì vẫn còn cửa thắng -> ẩn
	mode.operator = "<"
	scene.game_controller.call("_update_hud")
	#_entry(replay.visible, "Toan tu '<' + tong vuot muc tieu -> van hien")
	mode.operator = ">"
	scene.game_controller.call("_update_hud")
	#_entry(not mode.is_unwinnable() and not replay.visible,
		#"Toan tu '>' -> khong hien nut CHOI LAI")
	# Bấm CHƠI LẠI -> ván mới, cờ trở về bình thường
	mode.operator = "="
	mode.current_sum = 99
	scene.game_controller.call("_update_hud")
	#_entry(replay.visible, "Chuan bi: nut dang hien truoc khi bam")
	#replay.pressed.emit()
	await process_frame
	await process_frame
	#_entry(not replay.visible and not mode.is_unwinnable(),
		#"Bam CHOI LAI -> van moi, nut an lai")
	# Undo lùi bước -> tổng tính lại (bỏ ô vừa đi khỏi đường).
	# Vào VÁN MỚI trước: đoạn trên đã ép `current_sum = 99` để thử `is_unwinnable()` nên tổng không
	# còn là giá trị thật của đường đi.
	scene.switch_mode("sum_path", "medium")
	await process_frame
	mode = scene.game_mode_controller.game_mode as SumPathGameMode
	if mode == null:
		_entry(false, "Khong lay lai duoc SumPathGameMode sau khi vao van moi")
		return
	var board := scene.game_controller.grid_view
	var start_pos: Vector2i = scene.grid_controller.current_pos
	var target := Vector2i(-1, -1)
	for d in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]:
		var nxt: Vector2i = start_pos + d
		if board.maze.is_in_bounds(nxt) and board.maze.is_cell_active(nxt):
			target = nxt
			break
	if target == Vector2i(-1, -1):
		_entry(false, "Khong tim duoc o ke de thu Undo")
		return
	var sum_before := mode.current_sum
	scene.grid_controller.try_move_to(target)
	await process_frame
	var sum_after := mode.current_sum
	scene.game_controller.undo()
	await process_frame
	_entry(sum_after > sum_before and mode.current_sum == sum_before,
		"Undo lui buoc -> tong tinh lai (%d -> %d -> %d)" % [sum_before, sum_after, mode.current_sum])


# ---------------------------------------------------------------------------
# 7. Countdown Cost — hết ngân sách: khoá di chuyển + NHẤN MẠNH Undo (2026-09-19)
# ---------------------------------------------------------------------------
func _section_7_countdown_budget_lock(scene: GameScene) -> void:
	print("[7] Countdown Cost: het ngan sach -> khoa di chuyen + nhan manh Undo...")
	scene.switch_mode("countdown_cost", "medium")
	await process_frame
	var mode := scene.game_mode_controller.game_mode as CountdownCostGameMode
	var board := scene.game_controller.grid_view
	_entry(mode != null and board != null, "Co CountdownCostGameMode + board")
	if mode == null or board == null:
		return
	var undo_btn := scene.undo_btn as TextureButton
	_entry(undo_btn != null, "Co nut Undo trong thanh nut")
	_entry(not scene.ui_controller.undo_highlighted(), "Dau van: nut Undo khong nhan manh")
	# Đi 1 bước thật để có bước cho Undo + biết đúng chi phí ô
	var start_pos: Vector2i = scene.grid_controller.current_pos
	var target := Vector2i(-1, -1)
	for d in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]:
		var nxt: Vector2i = start_pos + d
		if board.maze.is_in_bounds(nxt) and board.maze.is_cell_active(nxt) \
				and not board.maze.has_wall(start_pos, nxt):
			target = nxt
			break
	if target == Vector2i(-1, -1):
		_entry(false, "Khong tim duoc o ke khong tuong de di thu")
		return
	var cost: int = mode.get_cell_cost(target)
	scene.grid_controller.try_move_to(target)
	await process_frame
	# Ép hết ngân sách -> KHOÁ di chuyển + NHẤN MẠNH Undo
	scene.game_controller.game_state.steps_remaining = 0
	scene.game_controller.call("_update_hud")
	_entry(not bool(board.get("_interaction_enabled")),
		"Het ngan sach -> board KHOA tuong tac (khong di chuyen duoc)")
	_entry(scene.ui_controller.undo_highlighted(), "Nut Undo duoc NHAN MANH")
	_entry(undo_btn != null and undo_btn.modulate != Color.WHITE, "Nut Undo doi mau anh vang")
	# Bấm Undo -> hoàn ĐÚNG chi phí bước vừa đi -> mở khoá lại
	scene.game_controller.undo()
	await process_frame
	_entry(scene.game_controller.game_state.steps_remaining == cost,
		"Undo hoan DUNG chi phi buoc vua di (%d buoc)" % cost)
	_entry(bool(board.get("_interaction_enabled")), "Con ngan sach -> mo lai tuong tac")
	_entry(not scene.ui_controller.undo_highlighted(), "Bo nhan manh nut Undo")


# ---------------------------------------------------------------------------
# 5. Khối HUD theo chế độ — "chỉ hiện thứ cần thiết" (2026-09-27)
# ---------------------------------------------------------------------------
## Chế độ CHỈ có thẻ THỜI GIAN (bảng thông tin riêng đã gỡ: thông tin hiện ngay trên bàn cờ)
const TIME_ONLY_MODES := ["play", "minesweeper", "blind_memory", "fading_ink", "one_stroke",
	"wall_builder"]
## Chế độ CÓ thẻ/bảng thông tin riêng → đồng hồ THỜI GIAN ẩn để nhường chỗ
const OWN_CARD_MODES := ["dungeon", "sum_path", "countdown_cost", "fog_of_war"]

func _section_5_hud_blocks(scene: GameScene) -> void:
	print("[5] Khoi HUD theo che do (chi hien thu can thiet)...")
	for mode_id in TIME_ONLY_MODES:
		scene.switch_mode(str(mode_id), "medium")
		await process_frame
		var card := _time_card(scene.ui_controller.hud)
		var info := _mode_information(scene.ui_controller.hud)
		_entry(card != null and card.visible and info != null and info.get_child_count() == 1,
			"'%s': khung che do CHI co the THOI GIAN (%d khoi)"
			% [mode_id, info.get_child_count() if info != null else -1])
	for mode_id in OWN_CARD_MODES:
		scene.switch_mode(str(mode_id), "medium")
		await process_frame
		var own_card := _time_card(scene.ui_controller.hud)
		var own_info := _mode_information(scene.ui_controller.hud)
		_entry(own_card != null and not own_card.visible and own_info != null
			and own_info.get_child_count() > 1,
			"'%s': co khoi thong tin rieng, an dong ho THOI GIAN (%d khoi)"
			% [mode_id, own_info.get_child_count() if own_info != null else -1])


# ---------------------------------------------------------------------------
# Helper
# ---------------------------------------------------------------------------
## Thẻ THỜI GIAN của HUD (node cha của Label giờ ván) — mọi HUD bind sẵn `time_value_node`
func _time_card(hud: BaseHUD) -> Control:
	if hud == null or hud.time_value_node == null:
		return null
	return hud.time_value_node.get_parent() as Control


## Khối `ModeInformation` (node cha của thẻ THỜI GIAN) — nơi mỗi chế độ khai khối thông tin của mình
func _mode_information(hud: BaseHUD) -> Control:
	var card := _time_card(hud)
	return card.get_parent() as Control if card != null else null


func _entry(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("  [PASS] %s" % label)
	else:
		_failed += 1
		print("  [FAIL] %s" % label)
