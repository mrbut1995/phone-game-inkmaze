extends SceneTree
## ============================================================================
## Test Case: THANH TIẾN ĐỘ + RƯƠNG MỐC THƯỞNG CỦA CHƯƠNG (màn CHỌN MÀN)
## — tầng B của "Number Maze — Chiến lược thưởng chế độ Play".
##
## 1. Ngưỡng mốc = 33% / 67% / 100% tổng Sao của chương (chương 27★ -> 9/18/27).
## 2. Định nghĩa thưởng khởi điểm: +50 Xu · Gợi ý ×2 + Hoàn tác ×1 · +150 Xu + 1 lượt chơi.
## 3. Nhận MỘT lần/chương: đủ Sao mới nhận, nhận rồi thì không nhận lại.
## 4. Trao thưởng đúng: Xu vào ví chung, lượt công cụ + lượt chơi qua API có nguồn.
## 5. Lưu/đọc: `chapter_chests` nằm trong blob tiến trình; `reset_progress()` xoá sạch.
## 6. Thanh tiến độ nằm ở màn CHỌN MÀN (dưới banner chương): đầy theo tỉ lệ Sao,
##    3 rương đặt đúng ngưỡng, bấm rương đủ Sao -> nhận thưởng + popup rương + vẽ lại.
## 7. Màn CHỌN CHƯƠNG KHÔNG còn thanh này (đã chuyển sang Chọn màn).
## ============================================================================

const SCENE_PATH := "res://scenes/levels.tscn"

var _backup := ""
var _checks := 0
var _failed := 0
var _saved := {}


func _init() -> void:
	print("\n========================================================")
	print("  TEST: THANH TIEN DO + RUONG MOC THUONG CUA CHUONG")
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

	_section_thresholds()
	_section_defs(gm)
	_section_claim(gm)
	_section_persist(gm)
	await _section_progress(gm, lm)
	await _section_popup_reuse(gm)

	gm.call("import_progress", _saved)
	_finish()


# ---------------------------------------------------------------------------
# 1. Ngưỡng mốc
# ---------------------------------------------------------------------------
func _section_thresholds() -> void:
	print("[1] Nguong moc 33% / 67% / 100%...")
	_check(GameManagerClass.chest_threshold(0.33, 30) == 10, "30 sao: moc 1 = 10 sao")
	_check(GameManagerClass.chest_threshold(0.67, 30) == 20, "30 sao: moc 2 = 20 sao")
	_check(GameManagerClass.chest_threshold(1.0, 30) == 30, "30 sao: moc 3 = 30 sao")
	_check(GameManagerClass.chest_threshold(0.33, 27) == 9, "27 sao: moc 1 = 9 sao")
	_check(GameManagerClass.chest_threshold(0.67, 27) == 18, "27 sao: moc 2 = 18 sao")
	_check(GameManagerClass.chest_threshold(1.0, 27) == 27, "27 sao: moc 3 = 27 sao")
	_check(GameManagerClass.chest_threshold(0.33, 3) == 1, "3 sao: moc 1 = 1 sao (khong ve 0)")
	_check(GameManagerClass.chest_threshold(0.67, 3) == 2, "3 sao: moc 2 = 2 sao")
	_check(GameManagerClass.chest_threshold(0.33, 0) == 0, "Chuong 0 sao -> moc 0")


# ---------------------------------------------------------------------------
# 2. Định nghĩa thưởng
# ---------------------------------------------------------------------------
func _section_defs(gm: Node) -> void:
	print("[2] Dinh nghia 3 ruong...")
	var defs: Array = gm.call("chapter_chest_defs", 30)
	_check(defs.size() == 3, "Co dung 3 ruong (dang %d)" % defs.size())
	if defs.size() != 3:
		return
	_check(int(defs[0].get("stars", 0)) == 10 and int(defs[1].get("stars", 0)) == 20
		and int(defs[2].get("stars", 0)) == 30, "Nguong 10 / 20 / 30 sao")
	_check(int(defs[0].get("coins", 0)) == 50, "Ruong 1: +50 Xu")
	_check(int(defs[1].get("hint", 0)) == 2 and int(defs[1].get("undo", 0)) == 1,
		"Ruong 2: Goi y x2 + Hoan tac x1")
	_check(int(defs[2].get("coins", 0)) == 150 and int(defs[2].get("life", 0)) == 1,
		"Ruong 3: +150 Xu + 1 luot choi")
	_check(int(defs[0].get("index", -1)) == 0 and int(defs[2].get("index", -1)) == 2,
		"Index 0..2 dung thu tu")
	var text: String = gm.call("chapter_chest_reward_text", defs[1])
	_check(not text.is_empty() and text.contains("2"), "Chuoi phan thuong ruong 2 = '%s'" % text)
	var life_text: String = gm.call("chapter_chest_reward_text", defs[2])
	_check(life_text.contains("150"), "Chuoi phan thuong ruong 3 co Xu ('%s')" % life_text)


# ---------------------------------------------------------------------------
# 3. Nhận thưởng (một lần)
# ---------------------------------------------------------------------------
func _section_claim(gm: Node) -> void:
	print("[3] Nhan thuong (mot lan/chuong)...")
	gm.call("reset_progress")

	_check(not bool(gm.call("can_claim_chapter_chest", 1, 0, 9, 30)),
		"9/30 sao -> CHUA nhan duoc ruong 1 (can 10)")
	_check(bool(gm.call("can_claim_chapter_chest", 1, 0, 10, 30)),
		"10/30 sao -> nhan duoc ruong 1")
	_check(not bool(gm.call("can_claim_chapter_chest", 1, 1, 10, 30)),
		"10/30 sao -> CHUA nhan duoc ruong 2 (can 20)")
	_check(not bool(gm.call("can_claim_chapter_chest", 1, 5, 30, 30)),
		"Index ngoai pham vi -> khong nhan duoc")

	var coins_before: int = Archivement.coins()
	var def: Dictionary = gm.call("claim_chapter_chest", 1, 0, 12, 30)
	_check(not def.is_empty(), "Nhan ruong 1 thanh cong")
	_check(int(def.get("coins", 0)) == 50, "Ruong 1 tra ve +50 Xu")
	_check(Archivement.coins() == coins_before + 50,
		"Vi Xu +50 (dang %d)" % (Archivement.coins() - coins_before))
	_check(bool(gm.call("is_chapter_chest_claimed", 1, 0)), "Ruong 1 da danh dau DA NHAN")
	_check(gm.call("claim_chapter_chest", 1, 0, 30, 30).is_empty(),
		"Nhan lai ruong 1 -> tu choi (khong nhan 2 lan)")
	_check(Archivement.coins() == coins_before + 50, "Vi Xu KHONG doi khi nhan lai")

	# Rương 2: lượt công cụ
	var hint_before: int = int(gm.call("tool_uses_left", GameManagerClass.TOOL_HINT))
	var undo_before: int = int(gm.call("tool_uses_left", GameManagerClass.TOOL_UNDO))
	_check(not gm.call("claim_chapter_chest", 1, 1, 20, 30).is_empty(), "Nhan ruong 2 thanh cong")
	_check(int(gm.call("tool_uses_left", GameManagerClass.TOOL_HINT)) == hint_before + 2,
		"Goi y +2 (%d -> %d)" % [hint_before, int(gm.call("tool_uses_left", GameManagerClass.TOOL_HINT))])
	_check(int(gm.call("tool_uses_left", GameManagerClass.TOOL_UNDO)) == undo_before + 1,
		"Hoan tac +1 (%d -> %d)" % [undo_before, int(gm.call("tool_uses_left", GameManagerClass.TOOL_UNDO))])

	# Rương 3: Xu + 1 lượt chơi
	gm.call("debug_set_lives", 3)
	var coins3: int = Archivement.coins()
	_check(not gm.call("claim_chapter_chest", 1, 2, 30, 30).is_empty(), "Nhan ruong 3 thanh cong")
	_check(Archivement.coins() == coins3 + 150, "Ruong 3 +150 Xu")
	_check(int(gm.call("lives_left")) == 4, "Ruong 3 +1 luot choi (3 -> 4)")
	gm.call("debug_set_lives", 5)

	# Chương KHÁC có bộ rương riêng
	_check(not bool(gm.call("is_chapter_chest_claimed", 2, 0)), "Chuong 2 chua nhan ruong nao")
	_check(not gm.call("claim_chapter_chest", 2, 0, 12, 30).is_empty(),
		"Chuong 2 nhan ruong 1 doc lap voi chuong 1")
	_check(not bool(gm.call("can_claim_chapter_chest", 0, 0, 30, 30)),
		"chapter_id = 0 -> khong nhan duoc")

	# Nguồn cấp hợp lệ
	_check(bool(gm.call("grant_tool_uses", GameManagerClass.TOOL_HINT, 1, "chapter_chest")),
		"grant_tool_uses nhan nguon 'chapter_chest'")
	gm.call("debug_set_lives", 4)
	_check(bool(gm.call("grant_lives", 1, "chapter_chest")), "grant_lives nhan nguon 'chapter_chest'")
	gm.call("debug_set_lives", 5)


# ---------------------------------------------------------------------------
# 4. Lưu / đọc
# ---------------------------------------------------------------------------
func _section_persist(gm: Node) -> void:
	print("[4] Luu / doc chapter_chests...")
	gm.call("reset_progress")
	gm.call("claim_chapter_chest", 1, 0, 30, 30)
	gm.call("claim_chapter_chest", 3, 2, 30, 30)
	var blob: Dictionary = gm.call("export_progress")
	_check(blob.has("chapter_chests"), "Blob tien trinh co 'chapter_chests'")

	gm.call("reset_progress")
	_check(not bool(gm.call("is_chapter_chest_claimed", 1, 0)), "reset_progress() xoa trang thai cu")

	gm.call("import_progress", blob)
	_check(bool(gm.call("is_chapter_chest_claimed", 1, 0)), "Doc lai: chuong 1 ruong 1 da nhan")
	_check(bool(gm.call("is_chapter_chest_claimed", 3, 2)), "Doc lai: chuong 3 ruong 3 da nhan")
	_check(not bool(gm.call("is_chapter_chest_claimed", 1, 1)), "Doc lai: chuong 1 ruong 2 chua nhan")

	# JSON đổi khoá số thành CHUỖI + phần tử thành float -> vẫn đọc đúng
	gm.call("import_progress", {"chapter_chests": {"2": [0.0, 2.0]}})
	_check(bool(gm.call("is_chapter_chest_claimed", 2, 0))
		and bool(gm.call("is_chapter_chest_claimed", 2, 2)), "Doc duoc khoa chuoi '2' + so thuc")
	_check(not bool(gm.call("is_chapter_chest_claimed", 2, 1)), "Khoa chuoi: ruong 1 chua nhan")

	# Save cũ (chưa có chapter_chests) vẫn nạp được
	gm.call("import_progress", {"lives": 5})
	_check(gm.call("claimed_chapter_chests", 1).is_empty(), "Save cu -> khong co ruong da nhan")


# ---------------------------------------------------------------------------
# 6. Thanh tiến độ ở màn CHỌN MÀN
# ---------------------------------------------------------------------------
func _section_progress(gm: Node, lm: Node) -> void:
	print("[6] Thanh tien do + 3 ruong o man CHON MAN...")
	gm.call("reset_progress")
	gm.set("current_chapter", 1)
	gm.set("current_level", 1)
	gm.set("unlocked_levels", 9)
	# Chương 1 có 9 màn (27 sao) -> mốc 9 / 18 / 27. Cho 10 sao: đủ rương 1
	var level_ids: Array = lm.call("levels_in_chapter", 1)
	var stars: Dictionary = gm.get("level_stars")
	for id in level_ids:
		stars[int(id)] = 1
	stars[int(level_ids[0])] = 2      # 9 + 1 = 10 sao
	gm.set("level_stars", stars)
	var chapter_stars := int(lm.call("chapter_stars", 1))
	var chapter_total := int(lm.call("chapter_star_total", 1))
	_check(chapter_stars == 10 and chapter_total == 27,
		"Chuong 1 co 10/27 sao (%d/%d)" % [chapter_stars, chapter_total])

	var scene: Node = (load(SCENE_PATH) as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var widget: ChapterProgress = scene.call("progress_widget")
	_check(widget != null, "Man CHON MAN co thanh tien do chuong")
	if widget == null:
		scene.queue_free()
		await process_frame
		return

	# Bố cục: bản NGANG thanh nằm ngay DƯỚI banner chương + TRÊN bản đồ; bản DỌC thanh là
	# RAIL dọc ở lề TRÁI (giữa thẻ chương phía trên và thẻ "Màn tiếp theo" phía dưới).
	var layout_ok := true
	var vertical := widget.vertical
	var widget_rect: Rect2 = widget.get_global_rect()
	var map_area := scene.get_node_or_null("MapArea") as Control
	if vertical:
		var card: Control = scene.layout.banner if scene.layout != null else null
		var next_card: Control = scene.layout.next_card if scene.layout != null else null
		if card != null:
			layout_ok = widget_rect.position.y >= card.get_global_rect().end.y - 1.0
		if next_card != null:
			layout_ok = layout_ok and widget_rect.end.y <= next_card.get_global_rect().position.y + 1.0
		if map_area != null:
			layout_ok = layout_ok and widget_rect.get_center().x < map_area.get_global_rect().get_center().x
	elif scene.layout != null and scene.layout.banner != null:
		var banner_rect: Rect2 = scene.layout.banner.get_global_rect()
		layout_ok = widget_rect.position.y >= banner_rect.end.y - 1.0
		if map_area != null:
			layout_ok = layout_ok and widget_rect.end.y <= map_area.get_global_rect().position.y + 1.0
	_check(layout_ok, "Thanh tien do nam dung cho (%s)"
		% ("rail doc ben trai" if vertical else "giua banner chuong va ban do"))
	if vertical:
		# Rail dọc KHÔNG có nhãn "x / y SAO" riêng — số Sao hiện trên thẻ chương
		# (`card_stars` của màn Chọn màn) ⇒ chỉ kiểm thanh + rương.
		_check(scene.layout != null and scene.layout.card_stars != null
			and scene.layout.card_stars.text.contains("10"),
			"The chuong hien so Sao '%s'"
				% (scene.layout.card_stars.text if scene.layout != null
					and scene.layout.card_stars != null else "<null>"))
	else:
		_check(widget.count_label != null and widget.count_label.text.contains("10")
			and widget.count_label.text.contains("27"),
			"Nhan Sao '%s'" % (widget.count_label.text if widget.count_label != null else "<null>"))
	_check(absf(widget.fraction() - 10.0 / 27.0) < 0.001,
		"Do day cua thanh = 10/27 (%.3f)" % widget.fraction())
	_check(widget.bar != null and absf(widget.bar.value - 10.0) < 0.01,
		"Thanh hien dung 10 Sao (%.0f)" % (widget.bar.value if widget.bar != null else -1.0))

	# 3 rương đặt đúng ngưỡng 9 / 18 / 27
	var chips := widget.chip_list()
	_check(chips.size() == 3, "Co 3 ruong tren thanh (dang %d)" % chips.size())
	if chips.size() == 3:
		_check(chips[0].threshold == 9 and chips[1].threshold == 18 and chips[2].threshold == 27,
			"Nguong ruong 9 / 18 / 27")
		if vertical:
			_check(chips[0].position.y > chips[1].position.y and chips[1].position.y > chips[2].position.y,
				"Ruong xep tang dan tu DAY len DINH (rail doc)")
		else:
			_check(chips[0].position.x < chips[1].position.x and chips[1].position.x < chips[2].position.x,
				"Ruong xep tang dan theo be ngang")
		var bar_rect := widget.bar.get_global_rect()
		_check(bar_rect.has_point(chips[0].get_global_rect().get_center())
			and bar_rect.has_point(chips[2].get_global_rect().get_center()),
			"Ruong 1 va ruong 3 nam TRONG pham vi thanh")
		# 10 sao >= 9 -> rương 1 bấm được; chưa đủ 18 -> rương 2 khoá
		_check(chips[0].is_claimable(), "Du 9 sao -> ruong 1 bam duoc")
		_check(not chips[1].is_claimable(), "Chua du 18 sao -> ruong 2 chua bam duoc")
		_check(not chips[0].is_claimed(), "Ruong 1 chua nhan -> chua co dau ✓")

		# Bấm rương 1 -> nhận thưởng + popup rương + thanh vẽ lại
		var coins_before: int = Archivement.coins()
		chips[0].pressed.emit()
		await process_frame
		await process_frame
		_check(Archivement.coins() == coins_before + 50, "Bam ruong 1 -> +50 Xu")
		_check(Popups.is_open(Popups.DAILY_MILESTONE), "Mo popup ruong (dung popup moc cua Daily)")
		var popup := Popups.get_popup(Popups.DAILY_MILESTONE) as DailyMilestonePopup
		if popup != null:
			var title: Label = popup.get("title_label")
			_check(title != null and title.text.contains("1") and title.text.contains("9"),
				"Tieu de popup neu CHUONG + moc sao ('%s')" % (title.text if title != null else ""))
			var reward: Label = popup.get("reward_label")
			_check(reward != null and reward.text.contains("50"),
				"Popup ghi phan thuong ('%s')" % (reward.text if reward != null else ""))
		await create_timer(0.4).timeout
		Popups.close_all()
		await create_timer(0.4).timeout

		var chips_after := widget.chip_list()
		_check(chips_after.size() == 3 and chips_after[0].is_claimed(),
			"Sau khi nhan: ruong 1 hien dau ✓")
		_check(chips_after.size() == 3 and not chips_after[0].is_claimable(),
			"Sau khi nhan: ruong 1 khong bam duoc nua")
		if chips_after.size() == 3:
			var chest := chips_after[0].get_node_or_null("Ring/Chest") as TextureRect
			_check(chest != null and chest.texture != null
				and str(chest.texture.resource_path).contains("chest.png"),
				"Sau khi nhan: ruong MO (chest.png)")
		_check(int(gm.call("claimed_chapter_chests", 1).size()) == 1,
			"GameManager ghi nhan 1 ruong da nhan")

	scene.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# 6. Popup rương dùng chung vẫn chạy đúng cho Daily (không bị đổi hành vi)
# ---------------------------------------------------------------------------
func _section_popup_reuse(gm: Node) -> void:
	print("[7] Popup ruong dung chung (Daily) van dung mac dinh...")
	var popup := (load("res://nodes/popups/daily_milestone.tscn") as PackedScene).instantiate() as DailyMilestonePopup
	root.add_child(popup)
	await process_frame
	popup.call("open", {"stars": 15, "reward": {"stars": 15, "coins": 100}})
	await process_frame
	var title: Label = popup.get("title_label")
	var sub: Label = popup.get("sub_label")
	_check(title != null and title.text.contains("15"),
		"Khong truyen title_text -> dung tieu de moc Daily ('%s')" % (title.text if title != null else ""))
	_check(sub != null and sub.text == tr("STR_DAILY_MILESTONE_POPUP_SUB"),
		"Khong truyen sub_text -> dung phu de Daily")

	popup.call("open", {"stars": 9, "title_text": "CHUONG 1 - 9 SAO", "sub_text": "Sub rieng",
		"reward_text": "+50 XU"})
	await process_frame
	_check(title != null and title.text == "CHUONG 1 - 9 SAO", "title_text duoc uu tien")
	_check(sub != null and sub.text == "Sub rieng", "sub_text duoc uu tien")
	var reward: Label = popup.get("reward_label")
	_check(reward != null and reward.text == "+50 XU", "reward_text duoc uu tien")
	popup.queue_free()
	await process_frame
	gm.set("current_level", 1)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("  [PASS] %s" % message)
	else:
		_failed += 1
		print("  [FAIL] %s" % message)


func _finish() -> void:
	# Trả trạng thái trong RAM về như lúc bắt đầu RỒI mới ghi file: nếu chỉ ghi file mà còn
	# `Save.queue_save()` đang chờ, autosave sẽ ghi đè bằng trạng thái bẩn của test.
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
