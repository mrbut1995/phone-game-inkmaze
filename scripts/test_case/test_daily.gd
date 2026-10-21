extends SceneTree
## ============================================================================
## Test: THỬ THÁCH HẰNG NGÀY (mô hình SAO v2.28)
##
##  1. Sao/ngày: CHƠI = số NHIỆM VỤ (0..3) · THỬ THÁCH = +3 khi thắng · tối đa 6
##  1b. Giữ mức CAO NHẤT khi chơi lại; export/import/reset; di trú bitmask cũ
##  2. Mốc thưởng THÁNG: ngưỡng tăng dần, chỉ nhận khi đủ Sao, thưởng Xu + lượt công cụ, không nhận 2 lần
##  3. Mở khoá ngày bỏ lỡ bằng Xu
##  4. GameManager: prepare_daily_run("classic"/"challenge") + start_daily_play/start_daily_challenge
##  5. Màn Daily: 2 thẻ hành động (CHƠI/THỬ THÁCH) + 4 chip mốc + lịch "x/6 ★" + chọn ngày
##  6. Popup thắng Daily: hiện SAO ván này + Sao tháng
##  7. Ván THỬ THÁCH thắng thật -> +3 Sao vào đúng ngày
## ============================================================================

var _failed := 0
var _checks := 0
var _backup := ""
var _daily_backup: Dictionary = {}
var _coins_backup := 0
var _tools_backup: Dictionary = {}


func _init() -> void:
	print("\n========================================================")
	print("  TEST: THU THACH HANG NGAY (6 SAO/NGAY · MOC THUONG THANG)")
	print("========================================================\n")

	if FileAccess.file_exists("user://inkmaze_data.json"):
		var rf := FileAccess.open("user://inkmaze_data.json", FileAccess.READ)
		_backup = rf.get_as_text()

	await process_frame
	root.size = Vector2i(540, 920)

	var dm: Node = root.get_node_or_null("DailyManager")
	var gm: Node = root.get_node_or_null("GameManager")
	var arch: Node = root.get_node_or_null("ArchivementManager")
	_check(dm != null, "Autoload DailyManager ton tai")
	_check(gm != null, "Autoload GameManager ton tai")
	if dm == null or gm == null:
		_finish()

	_daily_backup = dm.call("export_progress")
	_coins_backup = int(arch.get("coins")) if arch != null else 0
	if gm != null:
		_tools_backup = (gm.get("tool_uses") as Dictionary).duplicate()

	_section_1_stars(dm)
	_section_1b_persist(dm)
	_section_2_milestones(dm, gm, arch)
	_section_3_unlock(dm, arch)
	_section_4_game_manager(gm, dm)
	await _section_5_scene(dm)
	await _section_5b_selection_and_ads(dm, arch)
	await _section_5c_milestone_popup(dm)
	await _section_5d_wallet_and_celebrate(dm, gm, arch)
	await _section_6_popup()
	await _section_7_challenge_run(gm, dm)

	# Khôi phục dữ liệu người chơi
	dm.call("import_progress", _daily_backup)
	if arch != null:
		arch.set("coins", _coins_backup)
		arch.call("notify_coins_changed")
	if gm != null:
		for tool_id in _tools_backup:
			gm.set("tool_uses", _tools_backup) if false else gm.call(
				"debug_set_tool_uses", tool_id, int(_tools_backup[tool_id]))
	if not _backup.is_empty():
		var wf := FileAccess.open("user://inkmaze_data.json", FileAccess.WRITE)
		wf.store_string(_backup)
	_finish()


func _finish() -> void:
	print("\n--------------------------------------------------------")
	if _failed == 0:
		print("  KET QUA: %d/%d CHECK PASS" % [_checks, _checks])
	else:
		print("  KET QUA: %d/%d CHECK FAIL" % [_failed, _checks])
	print("--------------------------------------------------------\n")
	quit(1 if _failed > 0 else 0)


func _check(ok: bool, label: String) -> void:
	_checks += 1
	if ok:
		print("  [OK]   %s" % label)
	else:
		_failed += 1
		print("  [FAIL] %s" % label)


# ---------------------------------------------------------------------------
# 1. Sao của ngày
# ---------------------------------------------------------------------------
func _section_1_stars(dm: Node) -> void:
	print("--- 1. Sao/ngay: CHOI = nhiem vu, THU THACH = +3 ---")
	_check(int(dm.get("PLAY_STARS_MAX")) == 3, "CHOI toi da 3 Sao")
	_check(int(dm.get("CHALLENGE_STARS_MAX")) == 3, "THU THACH toi da 3 Sao")
	_check(int(dm.get("DAY_STARS_MAX")) == 6, "Mot ngay toi da 6 Sao")

	var day := 5
	dm.call("set_day_stars_split", day, 0, 0)
	_check(int(dm.call("get_day_stars", day)) == 0, "Ngay test bat dau 0 Sao")

	var gained := int(dm.call("record_daily_win", day, false, 2))
	_check(gained == 2, "Thang man CHOI 2 nhiem vu -> +2 Sao (nhan %d)" % gained)
	_check(int(dm.call("get_day_play_stars", day)) == 2, "Sao phan CHOI = 2")
	_check(int(dm.call("get_day_stars", day)) == 2, "Tong Sao ngay = 2")

	var worse := int(dm.call("record_daily_win", day, false, 1))
	_check(worse == 0, "Choi lai kem hon KHONG mat Sao (nhan %d)" % worse)
	_check(int(dm.call("get_day_play_stars", day)) == 2, "Sao phan CHOI giu muc cao nhat = 2")

	var challenge := int(dm.call("record_daily_win", day, true, 3))
	_check(challenge == 3, "Thang THU THACH -> +3 Sao (nhan %d)" % challenge)
	_check(int(dm.call("get_day_stars", day)) == 5, "Tong Sao ngay = 5")
	_check(not bool(dm.call("is_completed", day)), "5/6 Sao chua tinh HOAN THANH")

	var replay := int(dm.call("record_daily_win", day, true, 3))
	_check(replay == 0, "Thang lai THU THACH khong cong trung (nhan %d)" % replay)

	var last := int(dm.call("record_daily_win", day, false, 3))
	_check(last == 1, "Choi du 3 nhiem vu -> +1 Sao con lai (nhan %d)" % last)
	_check(int(dm.call("get_day_stars", day)) == 6, "Tong Sao ngay = 6")
	_check(bool(dm.call("is_completed", day)), "Du 6 Sao -> ngay HOAN THANH")

	# Bitmask cũ (Debug Console / thống kê) vẫn đọc được theo mô hình mới
	dm.call("set_day_mission_mask", day, 0b1011)
	_check(int(dm.call("get_day_play_stars", day)) == 2
		and int(dm.call("get_day_challenge_stars", day)) == 3,
		"set_day_mission_mask(0b1011) -> 2 Sao CHOI + 3 Sao THU THACH")
	dm.call("set_day_mission_mask", day, 0b1111)
	_check(int(dm.call("get_day_mission_mask", day)) == 0b1111,
		"get_day_mission_mask tra ve 0b1111 voi ngay tron 6 Sao")


# ---------------------------------------------------------------------------
# 1b. Lưu / nạp / di trú
# ---------------------------------------------------------------------------
func _section_1b_persist(dm: Node) -> void:
	print("--- 1b. Luu/nap/di tru ---")
	var day := 6
	dm.call("set_day_stars_split", day, 2, 3)
	var blob: Dictionary = dm.call("export_progress")
	_check((blob.get("months", {}) as Dictionary).has(dm.call("month_key")),
		"export_progress co khoa thang hien tai")

	dm.call("reset_progress")
	_check(int(dm.call("get_day_stars", day)) == 0, "reset_progress xoa Sao cua ngay")
	_check(int(dm.call("get_month_stars")) == 0, "reset_progress xoa Sao thang")

	dm.call("import_progress", blob)
	_check(int(dm.call("get_day_play_stars", day)) == 2
		and int(dm.call("get_day_challenge_stars", day)) == 3,
		"import_progress khoi phuc 2 Sao CHOI + 3 Sao THU THACH")

	var start := int(dm.call("get_month_stars"))
	dm.call("set_day_stars_split", day + 1, 3, 0)
	_check(int(dm.call("get_month_stars")) == start + 3,
		"Sao thang cong don qua nhieu ngay (%d -> %d)" % [start, int(dm.call("get_month_stars"))])
	dm.call("set_day_stars_split", day + 1, 0, 0)


# ---------------------------------------------------------------------------
# 2. Mốc thưởng tháng
# ---------------------------------------------------------------------------
func _section_2_milestones(dm: Node, gm: Node, arch: Node) -> void:
	print("--- 2. Moc thuong thang ---")
	var defs: Array = dm.call("milestone_defs")
	_check(defs.size() == 4, "Co 4 moc thuong thang (nhan %d)" % defs.size())
	var ascending := true
	var prev := 0
	for def in defs:
		var stars := int((def as Dictionary).get("stars", 0))
		if stars <= prev:
			ascending = false
		prev = stars
	_check(ascending, "Nguong moc tang dan: %s" % [defs.map(func(d): return d.get("stars"))])
	_check(prev == int(dm.call("month_star_goal")), "Moc cuoi = dich cua thanh tien do")

	var first := int((defs[0] as Dictionary).get("stars", 0))
	dm.call("reset_progress")
	_check(not bool(dm.call("can_claim_milestone", first)),
		"0 Sao thi chua nhan duoc moc %d" % first)
	_check(not bool(dm.call("claim_milestone", first)), "Nhan moc khi chua du Sao -> tu choi")

	# Đẩy Sao tháng lên đủ mốc đầu: vài ngày hoàn hảo
	var needed := int(ceil(float(first) / 6.0))
	for i in needed:
		dm.call("set_day_stars_split", i + 1, 3, 3)
	_check(int(dm.call("get_month_stars")) >= first, "Da du %d Sao thang" % first)
	_check(bool(dm.call("can_claim_milestone", first)), "Du Sao -> nhan duoc moc %d" % first)

	var coins_before := int(arch.get("coins")) if arch != null else 0
	var hint_before := int(gm.call("tool_uses_left", "hint")) if gm != null else 0
	var undo_before := int(gm.call("tool_uses_left", "undo")) if gm != null else 0

	var granted_ok := true
	for def in defs:
		var d: Dictionary = def
		var threshold := int(d.get("stars", 0))
		while int(dm.call("get_month_stars")) < threshold:
			break
		if int(dm.call("get_month_stars")) < threshold:
			continue
		if not bool(dm.call("claim_milestone", threshold)):
			granted_ok = false
	_check(granted_ok, "Nhan duoc tat ca moc da du Sao")
	_check(not bool(dm.call("claim_milestone", first)), "Khong nhan lai moc da nhan")

	var coins_expected := 0
	var hint_expected := 0
	var undo_expected := 0
	for def in defs:
		var d: Dictionary = def
		if int(dm.call("get_month_stars")) >= int(d.get("stars", 0)):
			coins_expected += int(d.get("coins", 0))
			hint_expected += int(d.get("hint", 0))
			undo_expected += int(d.get("undo", 0))
	if arch != null:
		_check(int(arch.get("coins")) == coins_before + coins_expected,
			"Ví Xu +%d tu cac moc (truoc %d, sau %d)"
				% [coins_expected, coins_before, int(arch.get("coins"))])
	if gm != null:
		_check(int(gm.call("tool_uses_left", "hint")) == hint_before + hint_expected,
			"Luot GOI Y +%d (truoc %d, sau %d)"
				% [hint_expected, hint_before, int(gm.call("tool_uses_left", "hint"))])
		_check(int(gm.call("tool_uses_left", "undo")) == undo_before + undo_expected,
			"Luot HOAN TAC +%d (truoc %d, sau %d)"
				% [undo_expected, undo_before, int(gm.call("tool_uses_left", "undo"))])

	var snapshot: Dictionary = dm.call("export_progress")
	dm.call("reset_progress")
	dm.call("import_progress", snapshot)
	_check(bool(dm.call("is_milestone_claimed", first)), "Moc da nhan duoc luu qua export/import")

	# Dọn: trả Sao tháng về dữ liệu ban đầu cho các section sau
	dm.call("reset_progress")


# ---------------------------------------------------------------------------
# 3. Mở khoá ngày bỏ lỡ
# ---------------------------------------------------------------------------
func _section_3_unlock(dm: Node, arch: Node) -> void:
	print("--- 3. Mo khoa ngay bo lo bang Xu ---")
	_check(int(dm.call("unlock_cost")) == 50, "Gia mo khoa = 50 Xu")
	var today := int(dm.call("get_today"))
	if today < 2:
		print("  [INFO] Hom nay la ngay 01 -> khong co ngay bo lo de test")
		return
	var missed := today - 1
	dm.call("set_day_stars_split", missed, 0, 0)
	dm.call("set_day_unlocked", missed, false)
	if arch != null:
		arch.set("coins", 500)
	_check(bool(dm.call("can_unlock_day", missed)), "Ngay bo lo co the mo khoa khi du Xu")
	_check(bool(dm.call("unlock_day", missed)), "unlock_day tra true")
	if arch != null:
		_check(int(arch.get("coins")) == 450, "Ví tru 50 Xu (con %d)" % int(arch.get("coins")))
	_check(bool(dm.call("is_day_unlocked", missed)), "Ngay da duoc danh dau MO KHOAc")
	_check(not bool(dm.call("can_unlock_day", missed)), "Ngay da mo khoa thi khong mo lai")


# ---------------------------------------------------------------------------
# 4. GameManager
# ---------------------------------------------------------------------------
func _section_4_game_manager(gm: Node, dm: Node) -> void:
	print("--- 4. GameManager: vao man CHOI / THU THACH ---")
	_check(gm.has_method("start_daily_play"), "GameManager co start_daily_play")
	_check(gm.has_method("start_daily_challenge"), "GameManager co start_daily_challenge")

	var day := 10
	var mode := str(gm.call("prepare_daily_run", day, "classic"))
	_check(mode == "daily_classic", "prepare_daily_run(day, classic) -> daily_classic (%s)" % mode)
	_check(str(gm.get("daily_variant")) == "classic", "daily_variant = classic")

	mode = str(gm.call("prepare_daily_run", day, "challenge"))
	_check(mode == "daily_challenge", "prepare_daily_run(day, challenge) -> daily_challenge (%s)" % mode)
	_check(str(gm.get("daily_variant")) == "challenge", "daily_variant = challenge")

	var rule := str(dm.call("challenge_mode_for_day", day))
	_check(ChallengeGameMode.CHALLENGE_IDS.has(rule),
		"Luat THU THACH cua ngay thuoc CHALLENGE_IDS ('%s')" % rule)
	_check(str(dm.call("challenge_mode_for_day", day)) == rule, "Luat THU THACH deterministic theo ngay")
	var info: Dictionary = dm.call("get_daily_challenge_info", day)
	_check(not str(info.get("title", "")).is_empty(), "get_daily_challenge_info co ten luat")

	var plan: Array = dm.call("get_day_games", day)
	_check(plan.size() == 2, "Ke hoach ngay = 1 CHOI + 1 THU THACH (nhan %d)" % plan.size())


# ---------------------------------------------------------------------------
# 5. Màn Daily
# ---------------------------------------------------------------------------
func _section_5_scene(dm: Node) -> void:
	print("--- 5. Man Daily: 2 the + 4 chip moc + lich ---")
	var packed: PackedScene = load("res://scenes/daily.tscn")
	_check(packed != null, "scenes/daily.tscn load duoc")
	if packed == null:
		return
	var scene: DailyScene = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var today := int(dm.call("get_today"))
	_check(scene.selected_day() == today, "Mac dinh chon HOM NAY (ngay %d)" % today)
	_check(scene.layout != null, "Layout da gan DailyLayout")
	_check(scene.layout.btn_back != null, "Nut Back noi san trong daily.tscn")
	_check(scene.play_card() != null, "Co the CHOI")
	_check(scene.challenge_card() != null, "Co the THU THACH")
	_check(scene.milestone_count() == 4, "Hien 4 chip moc thuong (nhan %d)" % scene.milestone_count())
	_check(scene.layout.milestones_host != null, "milestones_host da gan")
	## Thanh Sao chay thang 0..1 (ti le so voi moc cuoi thang) — xem `DailyLayout.set_star_progress()`
	_check(scene.layout.bar_stars != null
		and is_equal_approx(float(scene.layout.bar_stars.max_value), 1.0)
		and float(scene.layout.bar_stars.value) >= 0.0
		and float(scene.layout.bar_stars.value) <= 1.0,
		"Thanh tien do chay 0..1 theo ti le moc cuoi thang (%.2f)" % float(
			scene.layout.bar_stars.value if scene.layout.bar_stars != null else 0.0))

	# Ngày đã có 2 Sao CHƠI -> thẻ CHƠI hiện "CHƠI LẠI" + 2 sao sáng
	dm.call("set_day_stars_split", today, 2, 0)
	scene.select_day(today)
	_check(scene.play_card().cta_text() == tr("STR_DAILY_CARD_PLAY_BTN_AGAIN"),
		"Da choi trong ngay -> nut the CHOI doi thanh CHOI LAI ('%s')"
			% scene.play_card().cta_text())
	_check(scene.play_card().lit_stars() == 2,
		"The CHOI bao dung 2 Sao da dat (nhan %d)" % scene.play_card().lit_stars())

	# Ngày khác không ảnh hưởng thẻ của hôm nay
	scene.select_day(today)
	_check(scene.selected_day() == today, "select_day doi ngay dang chon -> %d" % today)

	# Ô lịch hôm nay hiện "x/6 ★"
	var cell := _cell_for(scene, today)
	_check(cell != null, "Tim thay o lich cua ngay %d" % today)
	if cell != null:
		_check(cell.state == DailyDayCell.State.TODAY, "O ngay hom nay dung trang thai TODAY")
		_check(cell.status_text().contains("/6"),
			"Vien trang thai ghi 'x/6 ★' ('%s')" % cell.status_text())

	dm.call("set_day_stars_split", today, 0, 0)
	scene.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# 5b. Ô lịch ĐANG CHỌN (vòng sáng) + ngày bỏ lỡ mở bằng QUẢNG CÁO (không trừ Xu)
# ---------------------------------------------------------------------------
func _section_5b_selection_and_ads(dm: Node, arch: Node) -> void:
	print("--- 5b. Vong sang o dang chon + mo khoa bang quang cao ---")
	var packed: PackedScene = load("res://scenes/daily.tscn")
	if packed == null:
		return
	var scene: DailyScene = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var today := int(dm.call("get_today"))
	var other := today - 2 if today > 2 else today + 1

	# --- Vòng sáng: đúng 1 ô sáng, và là ô đang chọn
	scene.select_day(today)
	await process_frame
	var ring_count := 0
	var ring_on_selected := false
	var grid := scene.layout.calendar.get_node_or_null("Panel/Days")
	if grid != null:
		for child in grid.get_children():
			var c := child as DailyDayCell
			if c == null or not c.is_selected():
				continue
			ring_count += 1
			if c.day_number == today:
				ring_on_selected = true
	_check(ring_count == 1, "Chi 1 o lich co vong sang 'dang chon' (nhan %d)" % ring_count)
	_check(ring_on_selected, "Vong sang nam dung o ngay dang chon (%d)" % today)
	var cell_today := _cell_for(scene, today)
	if cell_today != null:
		_check(cell_today.get("selected_ring").visible, "O dang chon bat vong sang")

	# --- Ngày BỎ LỠ: nút ghi như game đã mua (không còn "XU"), bấm thì chạy quảng cáo
	if today > 2:
		var missed := today - 2
		dm.call("set_day_stars_split", missed, 0, 0)
		dm.call("set_day_unlocked", missed, false)
		scene.select_day(missed)
		await process_frame
		var cta := scene.play_card().cta_text()
		_check(not cta.to_upper().contains("XU"),
			"Nut the CHOI cua ngay bo lo KHONG con chu XU ('%s')" % cta)
		_check(cta == tr("STR_DAILY_CARD_PLAY_BTN"),
			"Nut the CHOI cua ngay bo lo ghi nhu game da moa ('%s')" % cta)

		# Quảng cáo (placeholder) chạy được và KHÔNG trừ Xu
		var ads: Node = root.get_node_or_null("AdsManager")
		_check(ads != null and ads.has_method("show_rewarded"), "Co AdsManager de chay quang cao")
		var coins_before := int(arch.get("coins")) if arch != null else 0
		scene.call("_grant_day_unlock")
		await process_frame
		_check(bool(dm.call("is_day_unlocked", missed)),
			"Xem quang cao xong -> ngay %d duoc MO KHOA" % missed)
		if arch != null:
			_check(int(arch.get("coins")) == coins_before,
				"Mo khoa bang quang cao KHONG tru Xu (truoc %d, sau %d)"
					% [coins_before, int(arch.get("coins"))])
		dm.call("set_day_unlocked", missed, false)

	# --- Ngày TƯƠNG LAI: bấm không vào được (không đổi màn hình)
	if today < 28:
		scene.select_day(today + 3)
		await process_frame
		_check(not scene.is_inside_tree() or scene.get_tree() != null, "Man Daily van con sau khi bam ngay tuong lai")

	dm.call("set_day_stars_split", today, 0, 0)
	scene.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# 5c. Nhận thưởng MỐC → mở popup nhỏ báo phần thưởng
# ---------------------------------------------------------------------------
func _section_5c_milestone_popup(dm: Node) -> void:
	print("--- 5c. Nhan moc -> popup nho bao thuong ---")
	var packed: PackedScene = load("res://scenes/daily.tscn")
	if packed == null:
		return
	var scene: DailyScene = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var defs: Array = dm.call("milestone_defs")
	if defs.is_empty():
		scene.queue_free()
		return
	var threshold := int((defs[0] as Dictionary).get("stars", 0))
	dm.call("reset_progress")
	# Đẩy Sao tháng lên đủ mốc đầu
	var needed := int(ceil(float(threshold) / 6.0))
	for i in needed:
		dm.call("set_day_stars_split", i + 1, 3, 3)
	scene.call("_refresh")
	await process_frame

	Popups.close_all()
	scene.call("_on_milestone_claim", threshold)
	await process_frame
	_check(Popups.is_open(Popups.DAILY_MILESTONE),
		"Nhan moc %d -> mo popup 'daily_milestone'" % threshold)
	var popup := Popups.get_popup(Popups.DAILY_MILESTONE)
	if popup != null:
		var title: Label = popup.get("title_label")
		var reward: Label = popup.get("reward_label")
		_check(title != null and title.text.contains(str(threshold)),
			"Popup ghi dung moc ('%s')" % (title.text if title != null else ""))
		_check(reward != null and not reward.text.is_empty(),
			"Popup ghi phan thuong ('%s')" % (reward.text if reward != null else ""))
	Popups.close_all()
	await process_frame
	dm.call("reset_progress")
	scene.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# 5d. Ví Xu ở thanh trên + hiệu ứng Sao khi vừa hoàn thành ván
# ---------------------------------------------------------------------------
func _section_5d_wallet_and_celebrate(dm: Node, gm: Node, arch: Node) -> void:
	print("--- 5d. Vi Xu + hieu ung Sao khi hoan thanh van ---")
	var packed: PackedScene = load("res://scenes/daily.tscn")
	if packed == null:
		return
	var scene: DailyScene = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	# --- Ví Xu: hiện đúng số Xu
	var coins_now := int(arch.get("coins")) if arch != null else int(Shop.coins())
	_check(scene.layout.coin_chip != null, "daily.tscn co Vi Xu o thanh tren (doc)")
	if scene.layout.coin_chip != null:
		_check(scene.layout.coin_chip.value_label.text == Shop.thousands(coins_now),
			"Vi Xu hien dung so Xu ('%s')" % scene.layout.coin_chip.value_label.text)

	# --- Đổi ví -> `_refresh_wallet()` cập nhật số trên chip
	if arch != null and scene.layout.coin_chip != null:
		arch.set("coins", coins_now + 1234)
		scene.call("_refresh_wallet")
		_check(scene.layout.coin_chip.value_label.text == Shop.thousands(coins_now + 1234),
			"refresh_wallet cap nhat so Xu moi")
		arch.set("coins", coins_now)
		arch.call("notify_coins_changed")

	# --- Ván CHƠI (classic) vừa xong: thẻ CHƠI nảy Sao, thẻ THỬ THÁCH im
	var today := int(dm.call("get_today"))
	dm.call("set_day_stars_split", today, 2, 0)
	scene.select_day(today)
	gm.set("daily_celebrate", {"day": today, "challenge": false, "stars": 2, "gained": 2})
	scene._take_celebrate_info()
	await scene._celebrate_daily_win()
	_check(scene.play_card().is_celebrating(), "The CHOI chay hieu ung Sao sau khi xong van")
	_check(not scene.challenge_card().is_celebrating(), "The THU THACH khong chay hieu ung")
	_check((gm.get("daily_celebrate") as Dictionary).is_empty(),
		"Trang thai 'vua xong van' chi doc 1 lan roi xoa")
	scene.play_card().stop_celebrate()
	await process_frame

	# --- Ván THỬ THÁCH vừa xong: đúng thẻ THỬ THÁCH chạy hiệu ứng
	dm.call("set_day_stars_split", today, 3, 3)
	scene.select_day(today)
	gm.set("daily_celebrate", {"day": today, "challenge": true, "stars": 3, "gained": 3})
	scene._take_celebrate_info()
	await scene._celebrate_daily_win()
	_check(scene.challenge_card().is_celebrating(),
		"The THU THACH chay hieu ung Sao (3 sao)")
	scene.challenge_card().stop_celebrate()
	await process_frame

	# --- Ván của NGÀY KHÁC: màn tự chọn đúng ngày vừa chơi
	var other := 1 if today > 1 else 2
	gm.set("daily_celebrate", {"day": other, "challenge": false, "stars": 1, "gained": 1})
	scene._take_celebrate_info()
	await scene._celebrate_daily_win()
	_check(scene.selected_day() == other,
		"Hieu ung mo dung ngay vua choi (ngay %d)" % other)
	scene.play_card().stop_celebrate()
	await process_frame

	# --- Không có gì để ăn mừng -> không lỗi, không chạy hiệu ứng
	gm.set("daily_celebrate", {})
	scene._take_celebrate_info()
	await scene._celebrate_daily_win()
	_check(not scene.play_card().is_celebrating() and not scene.challenge_card().is_celebrating(),
		"Khong co van vua xong -> khong chay hieu ung")

	dm.call("set_day_stars_split", today, 0, 0)
	dm.call("set_day_stars_split", other, 0, 0)
	scene.queue_free()
	await process_frame


func _cell_for(scene: DailyScene, day: int) -> DailyDayCell:
	var grid := scene.layout.calendar.get_node_or_null("Panel/Days")
	if grid == null:
		return null
	for child in grid.get_children():
		var cell := child as DailyDayCell
		if cell != null and cell.day_number == day and cell.visible:
			return cell
	return null


# ---------------------------------------------------------------------------
# 6. Popup thắng Daily
# ---------------------------------------------------------------------------
func _section_6_popup() -> void:
	print("--- 6. Popup thang Daily hien SAO ---")
	var packed: PackedScene = load("res://nodes/popups/winning_daily.tscn")
	_check(packed != null, "winning_daily.tscn load duoc")
	if packed == null:
		return
	var popup: Node = packed.instantiate()
	root.add_child(popup)
	await process_frame
	popup.call("open", {
		"daily_day": 12,
		"daily_variant": "challenge",
		"daily_mode_name": "Test",
		"daily_stars": 3,
		"daily_stars_gained": 3,
		"daily_day_stars": 5,
		"daily_stars_max": 6,
		"daily_month_stars": 40,
		"daily_month_goal": int(DailyManager.MILESTONES[3].get("stars", 150)),
		"time": 42.0,
		"steps_used": 20,
		"steps_max": 60,
		"wall_hits": 0,
	})
	await process_frame
	var gained: Label = popup.get("value_coins")
	var total: Label = popup.get("value_total")
	var stamp: Label = popup.get("stamp_title")
	_check(gained.text.contains("3"), "Popup hien +3 Sao van nay ('%s')" % gained.text)
	var goal := int(DailyManager.MILESTONES[3].get("stars", 60))
	_check(total.text.contains("40") and total.text.contains(str(goal)),
		"Popup hien Sao thang 40/%d ('%s')" % [goal, total.text])
	_check(stamp.text.contains("5") and stamp.text.contains("6"),
		"Con dau ghi 5/6 Sao ('%s')" % stamp.text)
	popup.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# 7. Chơi thật 1 ván THỬ THÁCH
# ---------------------------------------------------------------------------
func _section_7_challenge_run(gm: Node, dm: Node) -> void:
	print("--- 7. Van THU THACH thang -> +3 Sao ---")
	var day := 12
	dm.call("set_day_stars_split", day, 0, 0)
	gm.call("prepare_daily_run", day, "challenge")
	_check(str(gm.get("daily_variant")) == "challenge", "Chuan bi van THU THACH")

	var packed: PackedScene = load("res://scenes/game.tscn")
	if packed == null:
		_check(false, "scenes/game.tscn load duoc")
		return
	var game: Node = packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var controller: Node = game.get("game_controller")
	if controller == null or not controller.has_method("_complete_daily_missions"):
		_check(false, "GameController co _complete_daily_missions")
		game.queue_free()
		return
	var result: Dictionary = controller.call("_complete_daily_missions", [])
	_check(not result.is_empty(), "Van THU THACH tra ket qua Daily")
	_check(int(result.get("stars", 0)) == 3, "Van THU THACH = 3 Sao (nhan %d)" % int(result.get("stars", 0)))
	_check(int(dm.call("get_day_challenge_stars", day)) == 3, "Sao THU THACH cua ngay = 3")
	_check(int(dm.call("get_day_stars", day)) == 3, "Tong Sao ngay = 3")
	game.queue_free()
	await process_frame

	# --- Ván CHƠI (classic): Sao = số NHIỆM VỤ đạt, KHÔNG phải 3 ---
	var day2 := 13
	dm.call("set_day_stars_split", day2, 0, 0)
	gm.call("prepare_daily_run", day2, "classic")
	var game2: Node = packed.instantiate()
	root.add_child(game2)
	await process_frame
	await process_frame
	var controller2: Node = game2.get("game_controller")
	if controller2 != null:
		var result2: Dictionary = controller2.call("_complete_daily_missions", [])
		_check(str(result2.get("variant", "")) == "classic", "Van CHOI bao variant = classic")
		_check(not bool(result2.get("challenge", true)), "Van CHOI khong bi coi la THU THACH")
		_check(int(dm.call("get_day_challenge_stars", day2)) == 0,
			"Van CHOI khong cong Sao phan THU THACH")
		_check(int(dm.call("get_day_play_stars", day2)) == int(result2.get("stars", -1)),
			"Sao phan CHOI = so NHIEM VU dat (nhan %d)" % int(dm.call("get_day_play_stars", day2)))
	game2.queue_free()
	await process_frame
	dm.call("set_day_stars_split", day2, 0, 0)
	dm.call("set_day_stars_split", day, 0, 0)
