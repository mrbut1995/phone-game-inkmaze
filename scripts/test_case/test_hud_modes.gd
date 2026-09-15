extends SceneTree
## ============================================================================
## Test Case: HUD THEO CHẾ ĐỘ (thiết kế mới) + PANEL HINT GUIDE — 2026-02
##
## 1. Hint Guide: có trong scenes/game.tscn, đổi nội dung theo 9 chế độ,
##    không rỗng và VỪA 1 DÒNG (đo bằng font thật của theme).
## 2. SumPathHUD: đủ node mới (Time/Sum/Operator/Target/Bar), thanh tiến độ đúng tỉ lệ,
##    chip "CẦN THÊM / CÒN ĐƯỢC / ĐẠT VƯỢT / ĐÃ ĐỦ" theo toán tử.
## 3. CountdownHUD: ngân sách còn/tổng, đã tiêu, dải phân đoạn = đúng số bước + đổi màu,
##    chip giá cước theo độ khó (easy ẩn chip đắt, hard hiện "3-4").
## 4. FadingInkHUD: bước đã đi, mực đã phai, cảnh báo ô cạn mực hiện/ẩn đúng.
## 5. Kích thước thẻ đúng mockup (Time 250x156 tại (0,3) · thẻ mode 715x156 tại (265,3)).
## ============================================================================

const HUD_SCRIPTS := {
	"play": "res://scripts/nodes/hud/level_hud.gd",
	"time_attack": "res://scripts/nodes/hud/level_hud.gd",
	"fog_of_war": "res://scripts/nodes/hud/level_hud.gd",
	"dungeon": "res://scripts/nodes/hud/dungeon_hud.gd",
	"minesweeper": "res://scripts/nodes/hud/minesweep_hud.gd",
	"blind_memory": "res://scripts/nodes/hud/blind_memory_hud.gd",
	"sum_path": "res://scripts/nodes/hud/sum_path_hud.gd",
	"countdown_cost": "res://scripts/nodes/hud/countdown_hud.gd",
	"fading_ink": "res://scripts/nodes/hud/fading_ink_hud.gd",
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
	await _section_5_card_sizes()

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
	var guide := scene.get_node_or_null("HintGuide") as Control
	_entry(guide != null, "scenes/game.tscn co node HintGuide")
	if guide == null:
		return
	_entry(guide.get_node_or_null("Bg") is TextureRect, "Hint Guide co nen giay (panel_hint_guide.svg)")
	_entry(guide.get_node_or_null("Icon") is TextureRect, "Hint Guide co icon bong den (icon_bulb.svg)")
	var label := guide.get_node_or_null("Text") as Label
	_entry(label != null, "Hint Guide co Label noi dung")
	if label == null:
		return
	# Nằm dưới bàn cờ, trên thanh nút
	var board := scene.get_node_or_null("Board") as Control
	var button := scene.get_node_or_null("Button") as Control
	if board != null and button != null:
		_entry(guide.global_position.y >= board.global_position.y + board.size.y - 20.0
			and guide.global_position.y + guide.size.y <= button.global_position.y,
			"Hint Guide nam giua ban co va thanh nut (y=%.0f)" % guide.global_position.y)

	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	_entry(font != null and font_size > 0, "Hint Guide lay duoc font tu theme (variation HintGuideText)")
	for mode_id in HUD_SCRIPTS.keys():
		scene.switch_mode(str(mode_id), "medium")
		await process_frame
		var expected_hud: GDScript = load(str(HUD_SCRIPTS[mode_id]))
		var hud := scene.ui_controller.hud
		_entry(hud != null and hud.get_script() == expected_hud,
			"Che do '%s' dung dung HUD scene rieng" % mode_id)
		var text := str(guide.call("current_text"))
		_entry(not text.is_empty() and not text.begins_with("STR_"),
			"Che do '%s': goi y hien chu that ('%s')" % [mode_id, text.substr(0, 40)])
		if font != null and font_size > 0:
			var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			_entry(width <= label.size.x,
				"Che do '%s': goi y vua 1 dong (%.0f/%.0f px)" % [mode_id, width, label.size.x])


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
	_entry(hud.get_node_or_null("Sheet") != null, "Co the CAN BANG TONG DIEM (Sheet)")
	_entry(hud.get_node_or_null("Bar/Fill") != null, "Co thanh tien do (Bar/Fill)")
	_entry(hud.get_node_or_null("Sum/Note") != null, "Co dong '(N o)' trong khoi TONG")

	mode.current_sum = 20
	mode.target_val = 50
	mode.operator = "="
	hud.update_hud({"mode": mode, "moves": 4})
	var bar := hud.get_node("Bar") as Control
	var fill := hud.get_node("Bar/Fill") as Control
	_entry(int(round(fill.size.x)) == int(round(bar.size.x * 0.4)),
		"Thanh tien do = 40%% (%.0f/%.0f px)" % [fill.size.x, bar.size.x])
	_entry(str((hud.get_node("Sum/Note") as Label).text).contains("4"),
		"Khoi TONG hien so o da di ('%s')" % (hud.get_node("Sum/Note") as Label).text)
	var chip := hud.get_node("Target/Need") as Label
	_entry(chip.text == tr("STR_HUD_SUM_NEED").format([30]),
		"Toan tu '=': chip bao CAN THEM +30 ('%s')" % chip.text)
	mode.operator = "<"
	hud.update_hud({"mode": mode, "moves": 4})
	_entry(chip.text == tr("STR_HUD_SUM_LEFT").format([29]),
		"Toan tu '<': chip bao CON DUOC +29 ('%s')" % chip.text)
	mode.operator = ">"
	mode.current_sum = 60
	hud.update_hud({"mode": mode, "moves": 4})
	_entry(chip.text == tr("STR_HUD_SUM_OK"),
		"Toan tu '>': da vuot muc tieu -> chip bao DA DU ('%s')" % chip.text)


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
	_entry(str((hud.get_node("Budget/Value") as Label).text) == "%02d" % (total - 6),
		"Khoi NGAN SACH CON hien %02d" % (total - 6))
	_entry(str((hud.get_node("Budget/Max") as Label).text) == "/ %d" % total,
		"Khoi NGAN SACH CON hien tong '/ %d'" % total)
	_entry(str((hud.get_node("Spent/Value") as Label).text) == "-06",
		"Khoi DA TIEU hien -06 ('%s')" % (hud.get_node("Spent/Value") as Label).text)
	var segments := hud.get_node_or_null("Segments") as HBoxContainer
	_entry(segments != null and segments.get_child_count() == total,
		"Dai phan doan co dung %d doan (nhan %d)" % [total, segments.get_child_count() if segments != null else -1])
	if segments != null and segments.get_child_count() == total:
		var off_count := 0
		for i in total:
			var seg := segments.get_child(i) as TextureRect
			if seg != null and seg.texture != null and seg.texture.resource_path.contains("segment_on"):
				off_count = i
				break
		_entry(off_count == 6, "6 doan dau la 'da dung' (mau xam), con lai 'con' (mau cam)")

	# Chip giá cước theo độ khó
	mode.difficulty = "easy"
	hud.update_hud({"mode": mode, "steps_remaining": total - 6, "moves": 4})
	var cheap := hud.get_node("Price/ChipCheap") as Control
	var pricey := hud.get_node("Price/ChipPricey") as Control
	_entry((cheap.get_node("Label") as Label).text == tr("STR_HUD_PRICE_CHEAP").format([1, 2]),
		"Easy: chip re '1-2' ('%s')" % (cheap.get_node("Label") as Label).text)
	_entry(not pricey.visible, "Easy (1-2): an chip gia dat")
	mode.difficulty = "hard"
	hud.update_hud({"mode": mode, "steps_remaining": total - 6, "moves": 4})
	_entry(pricey.visible, "Hard (1-4): hien chip gia dat")
	_entry((pricey.get_node("Label") as Label).text == tr("STR_HUD_PRICE_PRICEY").format([3, 4]),
		"Hard: chip dat '3-4' ('%s')" % (pricey.get_node("Label") as Label).text)
	_entry(str((hud.get_node("Price/Reserve") as Label).text).contains("3"),
		"Hard: du phong +3 buoc ('%s')" % (hud.get_node("Price/Reserve") as Label).text)


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
	_entry(str((hud.get_node("Steps/Value") as Label).text) == "00",
		"Buoc da di hien '00' ('%s')" % (hud.get_node("Steps/Value") as Label).text)
	_entry(str((hud.get_node("Steps/Delta") as Label).text) == tr("STR_HUD_INK_LOST").format([0]),
		"Delta muc phai hien '(-0 MUC)' ('%s')" % (hud.get_node("Steps/Delta") as Label).text)
	var warn := hud.get_node("Warn") as Control
	_entry(not warn.visible, "Chua co o can muc -> an canh bao")

	mode.moves_made = 9          # mực tối đa 9 -> mọi ô đều cạn
	hud.update_hud({"mode": mode})
	_entry(mode.count_exhausted() > 0, "count_exhausted() dem duoc o can (%d o)" % mode.count_exhausted())
	_entry(warn.visible, "Co o can muc -> hien canh bao")
	_entry(str((hud.get_node("Warn/Label") as Label).text).contains(str(mode.count_exhausted())),
		"Canh bao hien dung so o can ('%s')" % (hud.get_node("Warn/Label") as Label).text)


# ---------------------------------------------------------------------------
# 5. Kích thước thẻ + map HUD theo chế độ
# ---------------------------------------------------------------------------
func _section_5_card_sizes() -> void:
	print("[5] Kich thuoc the...")
	var size_checks := {
		"sum_path": "res://nodes/hud/sum_path_hud.tscn",
		"countdown_cost": "res://nodes/hud/countdown_hud.tscn",
		"fading_ink": "res://nodes/hud/fading_ink_hud.tscn",
	}
	for mode_id in size_checks.keys():
		var packed := load(str(size_checks[mode_id])) as PackedScene
		var hud: BaseHUD = packed.instantiate()
		root.add_child(hud)
		await process_frame
		var time_card := hud.get_node_or_null("Time") as Control
		var sheet := hud.get_node_or_null("Sheet") as Control
		_entry(time_card != null and time_card.size == Vector2(250, 156),
			"'%s': the THOI GIAN 250x156 tai (%.0f,%.0f)" % [mode_id, time_card.position.x, time_card.position.y])
		_entry(time_card != null and time_card.position == Vector2(0, 3),
			"'%s': the THOI GIAN dat tai (0,3) nhu mockup" % mode_id)
		_entry(sheet != null and sheet.size == Vector2(715, 156) and sheet.position == Vector2(265, 3),
			"'%s': the che do 715x156 tai (265,3)" % mode_id)
		hud.queue_free()
		await process_frame


# ---------------------------------------------------------------------------
# Helper
# ---------------------------------------------------------------------------
func _entry(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("  [PASS] %s" % label)
	else:
		_failed += 1
		print("  [FAIL] %s" % label)
