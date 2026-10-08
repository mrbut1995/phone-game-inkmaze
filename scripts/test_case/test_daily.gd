extends SceneTree
## ============================================================================
## Test: DAILY MISSION (mô hình "3 GAME + 1 SPECIAL", 2026-10)
##  1. DailyManager: 4 nhiệm vụ/ngày (3 GAME + 1 maze đặc biệt), thưởng XU
##  1b. Mở khoá ngày bỏ lỡ bằng Xu (unlock_day)
##  1c. Kế hoạch 3 GAME của ngày: deterministic + luật hợp lệ + không trùng luật trong ngày
##  2. GameManager: prepare_daily_run("classic"/"challenge"/"special") + prepare_daily_game
##  3. Màn Daily: 4 hàng, hàng 1..3 = "TRÒ CHƠI n · <tên>", chọn ngày chỉ XEM, footer Xu, CTA mở khoá
##  4. Popup winning_daily: nút "VỀ DAILY", Xu thay Sao, signal đúng
##  5. Chơi thật 1 GAME CHALLENGE + 1 GAME STANDARD của ngày -> đánh dấu ĐÚNG ô (bit) của game
## ============================================================================

var _failed := 0
var _checks := 0
var _backup := ""
var _daily_backup: Dictionary = {}
var _coins_backup := 0


func _init() -> void:
	print("\n========================================================")
	print("  TEST: DAILY MISSION (2 MAZE/NGÀY · THƯỞNG XU)")
	print("========================================================\n")

	if FileAccess.file_exists("user://inkmaze_data.json"):
		var rf := FileAccess.open("user://inkmaze_data.json", FileAccess.READ)
		_backup = rf.get_as_text()

	await process_frame
	root.size = Vector2i(1080, 1920)

	var dm: Node = root.get_node_or_null("DailyManager")
	var gm: Node = root.get_node_or_null("GameManager")
	var arch: Node = root.get_node_or_null("ArchivementManager")
	_check(dm != null, "Autoload DailyManager ton tai")
	_check(gm != null, "Autoload GameManager ton tai")
	if dm == null or gm == null:
		_finish()

	_daily_backup = dm.call("export_progress")
	_coins_backup = int(arch.get("coins")) if arch != null else 0

	_section_1_manager(dm, arch)
	_section_1b_unlock(dm, arch)
	_section_1c_day_games(dm)
	_section_2_game_manager(gm)
	await _section_3_scene(gm, dm, arch)
	await _section_4_popup(dm)
	await _section_5_game_run(gm, dm)

	# Khôi phục dữ liệu người chơi
	dm.call("import_progress", _daily_backup)
	if arch != null:
		arch.set("coins", _coins_backup)
		arch.call("notify_coins_changed")
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


# ---------------------------------------------------------------------------
# 1. DailyManager: nhiệm vụ + Xu
# ---------------------------------------------------------------------------
func _section_1_manager(dm: Node, arch: Node) -> void:
	print("--- 1. DailyManager: 4 nhiệm vụ/ngày + thưởng XU ---")
	_check(int(dm.call("mission_count")) == 4, "Mỗi ngày có 4 nhiệm vụ")
	_check(int(dm.call("mission_reward", 0)) == 10 and int(dm.call("mission_reward", 3)) == 15,
		"Xu thưởng từng nhiệm vụ = 10/10/15/15")
	_check(int(dm.call("day_reward_max")) == 50, "Tổng thưởng ngày = 50 Xu")

	var day := 5
	dm.call("set_day_mission_mask", day, 0)
	_check(int(dm.call("get_day_missions", day)) == 0, "Ngày test bắt đầu 0 nhiệm vụ")
	_check(not bool(dm.call("is_completed", day)), "Ngày 0 nhiệm vụ chưa hoàn thành")

	var coins_before := int(arch.get("coins")) if arch != null else 0
	var awarded := int(dm.call("complete_day_missions", day, [true, true, false, false]))
	_check(awarded == 20, "Chốt 2 nhiệm vụ đầu -> thưởng 20 Xu (nhận %d)" % awarded)
	if arch != null:
		_check(int(arch.get("coins")) == coins_before + 20,
			"Ví Xu +20 (truoc %d, sau %d)" % [coins_before, int(arch.get("coins"))])
	_check(int(dm.call("get_day_missions", day)) == 2, "Số nhiệm vụ đã xong = 2")
	_check(int(dm.call("day_coins_earned", day)) == 20, "Xu đã nhận trong ngày = 20")

	var again := int(dm.call("complete_day_missions", day, [true, true, false, false]))
	_check(again == 0, "Chốt lại nhiệm vụ cũ KHÔNG thưởng thêm (0 Xu)")

	var special := int(dm.call("complete_day_mission", day, 3))
	_check(special == 15, "Nhiệm vụ maze đặc biệt (index 3) thưởng 15 Xu")
	_check(int(dm.call("get_day_missions", day)) == 3, "Số nhiệm vụ đã xong = 3")

	var last := int(dm.call("complete_day_mission", day, 2))
	_check(last == 15, "Nhiệm vụ cuối thưởng 15 Xu")
	_check(bool(dm.call("is_completed", day)), "Đủ 4 nhiệm vụ -> ngày HOÀN THÀNH")
	_check(int(dm.call("day_coins_earned", day)) == 50, "Tổng Xu nhận trong ngày = 50")
	var mask := dm.call("get_task_mask", day) as Array
	_check(mask.size() == 4 and bool(mask[0]) and bool(mask[3]), "get_task_mask tra 4 nhiệm vụ")

	var blob: Dictionary = dm.call("export_progress")
	_check((blob.get("day_missions", {}) as Dictionary).has(day), "export_progress co day_missions")
	dm.call("reset_progress")
	_check(int(dm.call("get_day_missions", day)) == 0, "reset_progress xoa tien do ngay")
	dm.call("import_progress", blob)
	_check(int(dm.call("get_day_missions", day)) == 4, "import_progress khoi phuc du 4 nhiem vu")


# ---------------------------------------------------------------------------
# 1b. Mở khoá ngày bỏ lỡ bằng Xu
# ---------------------------------------------------------------------------
func _section_1b_unlock(dm: Node, arch: Node) -> void:
	print("--- 1b. Mo khoa ngay bo lo bang Xu ---")
	_check(int(dm.call("unlock_cost")) == 50, "Gia mo khoa = 50 Xu")
	var today := int(dm.call("get_today"))
	if today < 2:
		print("  [INFO] Hom nay la ngay 01 -> khong co ngay bo lo de test")
		return
	var missed := today - 1
	dm.call("set_day_mission_mask", missed, 0)
	dm.call("set_day_unlocked", missed, false)
	_check(not bool(dm.call("is_day_unlocked", missed)), "Ngay %d chua mo khoa" % missed)
	_check(bool(dm.call("can_unlock_day", missed)), "Ngay bo lo (da qua, 0 nhiem vu) co the mo khoa")
	_check(not bool(dm.call("can_unlock_day", today)), "Hom nay KHONG can mo khoa")
	if today < 28:
		_check(not bool(dm.call("can_unlock_day", today + 1)), "Ngay tuong lai KHONG the mo khoa")

	# Ví không đủ Xu -> không mở được, không bị trừ
	var coins_backup := int(arch.get("coins")) if arch != null else 0
	if arch != null:
		arch.set("coins", 10)
		arch.call("notify_coins_changed")
	_check(not bool(dm.call("unlock_day", missed)), "Vi 10 Xu (< 50) -> unlock_day = false")
	_check(not bool(dm.call("is_day_unlocked", missed)), "Thieu Xu: ngay van bi khoa")
	if arch != null:
		_check(int(arch.get("coins")) == 10, "Thieu Xu: KHONG bi tru Xu")
		arch.set("coins", 120)
		arch.call("notify_coins_changed")
	_check(bool(dm.call("unlock_day", missed)), "Vi 120 Xu -> unlock_day = true")
	if arch != null:
		_check(int(arch.get("coins")) == 70, "Tru dung 50 Xu (con %d)" % int(arch.get("coins")))
	_check(bool(dm.call("is_day_unlocked", missed)), "Ngay %d da mo khoa" % missed)
	_check(not bool(dm.call("can_unlock_day", missed)), "Da mo khoa -> khong con yeu cau tra Xu")
	_check(not bool(dm.call("unlock_day", missed)), "Goi unlock lan 2 = false")
	if arch != null:
		_check(int(arch.get("coins")) == 70, "Khong tru Xu lan thu 2")

	# Blob lưu trạng thái mở khoá
	var blob: Dictionary = dm.call("export_progress")
	_check((blob.get("unlocked_days", []) as Array).has(missed), "export_progress co unlocked_days")
	dm.call("reset_progress")
	_check(not bool(dm.call("is_day_unlocked", missed)), "reset_progress xoa trang thai mo khoa")
	dm.call("import_progress", blob)
	_check(bool(dm.call("is_day_unlocked", missed)), "import_progress khoi phuc ngay da mo khoa")

	if arch != null:
		arch.set("coins", coins_backup)
		arch.call("notify_coins_changed")


# ---------------------------------------------------------------------------
# 1c. Kế hoạch 3 GAME của ngày (DailyManager.get_day_games)
# ---------------------------------------------------------------------------
func _section_1c_day_games(dm: Node) -> void:
	print("--- 1c. Ke hoach 3 GAME cua ngay ---")
	var plan: Array = dm.call("get_day_games", 10)
	_check(plan.size() == 3, "Moi ngay co dung 3 GAME (dang %d)" % plan.size())

	var again: Array = dm.call("get_day_games", 10)
	var same := plan.size() == again.size()
	for i in mini(plan.size(), again.size()):
		if _game_key(plan[i]) != _game_key(again[i]):
			same = false
	_check(same, "Cung ngay -> cung ke hoach (deterministic)")

	var valid_mode := true
	var valid_rule := true
	var used_rules := {}
	var duplicate := false
	for entry in plan:
		var e: Dictionary = entry as Dictionary
		var mode := str(e.get("mode", ""))
		var cid := str(e.get("challenge_id", ""))
		if mode == "standard":
			if not cid.is_empty():
				valid_rule = false
		elif mode == "challenge":
			if not ChallengeGameMode.CHALLENGE_IDS.has(cid):
				valid_rule = false
			if used_rules.has(cid):
				duplicate = true
			used_rules[cid] = true
		else:
			valid_mode = false
	_check(valid_mode, "Mode moi slot = 'standard' hoac 'challenge'")
	_check(valid_rule, "challenge_id hop le (rong voi standard; thuoc CHALLENGE_IDS voi challenge)")
	_check(not duplicate, "Trong 1 ngay cac luat challenge khong trung nhau")

	var changed := false
	for d in range(11, 41):
		var other: Array = dm.call("get_day_games", d)
		for i in mini(plan.size(), other.size()):
			if _game_key(other[i]) != _game_key(plan[i]):
				changed = true
	_check(changed, "Cac ngay khac -> ke hoach doi (khong lap 1 kieu)")


func _game_key(entry: Variant) -> String:
	var e: Dictionary = entry as Dictionary
	return "%s|%s" % [str(e.get("mode", "")), str(e.get("challenge_id", ""))]


# ---------------------------------------------------------------------------
# 2. GameManager: chuẩn bị ván daily (classic / challenge / special)
# ---------------------------------------------------------------------------
func _section_2_game_manager(gm: Node) -> void:
	print("--- 2. GameManager: daily variant ---")
	var saved_mode := str(gm.get("current_mode"))
	var saved_variant := str(gm.get("daily_variant"))
	var saved_day := int(gm.get("selected_daily_day"))

	var classic_mode := str(gm.call("prepare_daily_run", 10, "classic"))
	_check(classic_mode == "daily_classic", "Maze thường -> mode 'daily_classic' (nhan '%s')" % classic_mode)
	_check(str(gm.get("daily_variant")) == "classic", "daily_variant = classic")
	_check(int(gm.get("selected_daily_day")) == 10, "selected_daily_day = 10")

	var special_mode := str(gm.call("prepare_daily_run", 10, "special"))
	var expected: String = GameManagerClass.DAILY_MODES[posmod(9, GameManagerClass.DAILY_MODES.size())]
	_check(special_mode == expected, "Maze đặc biệt -> mode xoay vòng '%s'" % expected)
	_check(str(gm.get("daily_variant")) == "special", "daily_variant = special")

	# GAME 0..2 của ngày: prepare_daily_game -> mode theo kế hoạch (standard/challenge)
	var plan: Array = []
	var dm_node: Node = root.get_node_or_null("DailyManager")
	if dm_node != null:
		var raw: Variant = dm_node.call("get_day_games", 10)
		if raw is Array:
			plan = raw as Array
	for i in mini(plan.size(), 3):
		var entry: Dictionary = plan[i] as Dictionary
		var mode_id := str(gm.call("prepare_daily_game", 10, i))
		var want := "daily_challenge" if str(entry.get("mode", "")) == "challenge" else "daily_classic"
		_check(mode_id == want, "prepare_daily_game(10, %d) -> '%s' (nhan '%s')" % [i, want, mode_id])
		_check(int(gm.get("daily_game")) == i, "daily_game = %d" % i)
		var cid := str(gm.get("daily_challenge_id"))
		if want == "daily_challenge":
			_check(cid == str(entry.get("challenge_id", "")),
				"daily_challenge_id = '%s' (theo ke hoach)" % cid)
		else:
			_check(cid.is_empty(), "Game standard: daily_challenge_id rong")

	var challenge_mode := str(gm.call("prepare_daily_run", 10, "challenge"))
	_check(challenge_mode == "daily_challenge", "prepare_daily_run('challenge') -> 'daily_challenge'")
	_check(str(gm.get("daily_variant")) == "challenge", "daily_variant = challenge")
	_check(int(gm.get("daily_game")) == -1, "prepare_daily_run dat daily_game = -1 (khong thuoc game nao)")

	# Chơi màn thường / dungeon phải xoá cờ Daily
	gm.call("prepare_mode_run", "play", "medium", true, 0)
	_check(str(gm.get("daily_variant")) == "", "prepare_mode_run xoa daily_variant")
	_check(int(gm.get("daily_game")) == -1 and str(gm.get("daily_challenge_id")).is_empty(),
		"prepare_mode_run xoa daily_game + daily_challenge_id")

	gm.set("current_mode", saved_mode)
	gm.set("daily_variant", saved_variant)
	gm.set("selected_daily_day", saved_day)
	gm.set("daily_game", -1)
	gm.set("daily_challenge_id", "")


# ---------------------------------------------------------------------------
# 3. Màn Daily: 4 hàng + chọn ngày chỉ để XEM
# ---------------------------------------------------------------------------
func _section_3_scene(gm: Node, dm: Node, arch: Node) -> void:
	print("--- 3. Man Daily: 4 hang nhiem vu + chon ngay ---")
	var scene: DailyScene = (load("res://scenes/daily.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var today := int(dm.call("get_today"))
	_check(scene.row_count() == 4, "Bang Mission co 4 hang (nhan %d)" % scene.row_count())
	_check(scene.selected_day() == today, "Mac dinh chon HOM NAY (ngay %d)" % today)

	var row0 := scene.row_at(0)
	var row3 := scene.row_at(3)
	_check(row0 != null and row3 != null, "Lay duoc hang 0 va hang 3")
	# Dây NÚT khai trong `scenes/daily.tscn` (nối xuyên instance cho CẢ 2 bố cục) — code chỉ giữ guard
	_check(scene.layout.btn_back.pressed.is_connected(Callable(scene, "_on_back_pressed")),
		"Nut Back noi san trong daily.tscn")
	_check(scene.layout.btn_play.pressed.is_connected(Callable(scene, "_on_play_pressed")),
		"Nut CTA noi san trong daily.tscn")
	_check((scene.layout.calendar as Object).is_connected("day_selected", Callable(scene, "_on_day_selected")),
		"Lich noi san day_selected trong daily.tscn")
	if row0 != null and row3 != null:
		# Node binding của hàng khai bằng @export trong `mission_row.tscn` (script KHÔNG tự dò node)
		_check(row0.box != null and row0.title_label != null and row0.progress_label != null
			and row0.action_button != null and row0.special_section != null,
			"Hang nhiem vu: export node binding du (box/title/progress/nut/nen)")
		_check(row0.texture_play_normal != null and row0.texture_play_pressed != null
			and row0.texture_done_normal != null and row0.texture_box_done != null,
			"Hang nhiem vu: texture trang thai binding trong scene")
		# Hàng chỉ còn ĐÚNG 2 DÒNG: Title + Tiến độ (bỏ hẳn node Desc/Status)
		_check(row0.get_node_or_null("Item/Text/Desc") == null
			and row0.get_node_or_null("Item/Centering/Check/Text/Status") == null,
			"Hang nhiem vu chi con 2 dong (khong con Desc/Status)")
		_check(row0.tag.visible == false, "Hang maze thuong KHONG co badge SPECIAL MODE")
		_check(row3.tag.visible == true, "Hang 4 (maze dac biet) CO badge SPECIAL MODE")
		# Hàng 1..3 = GAME của ngày: CHALLENGE -> title CHÍNH LÀ tên luật; maze thường -> "TRÒ CHƠI n · MAZE THƯỜNG"
		var plan: Array = dm.call("get_day_games", today)
		var entry0: Dictionary = {}
		if plan.size() > 0 and plan[0] is Dictionary:
			entry0 = plan[0] as Dictionary
		var name0 := tr("STR_DAILY_WIN_CLASSIC")
		var key0 := str(ChallengeGameMode.NAME_KEYS.get(str(entry0.get("challenge_id", "")), ""))
		if str(entry0.get("mode", "")) == "challenge" and not key0.is_empty():
			name0 = tr(key0)
			_check(row0.title_label.text == name0,
				"Hang challenge: title CHI hien ten luat (nhan '%s')" % row0.title_label.text)
		else:
			_check(row0.title_label.text == tr("STR_DAILY_GAME_TITLE").format([1, name0]),
				"Hang maze thuong = 'TRO CHOI 1 · MAZE THUONG' (nhan '%s')" % row0.title_label.text)
		_check(int(row3.index) == 3, "Hang 4 index = 3")

	# Chọn ngày khác: chỉ đổi ngày đang xem, KHÔNG nhảy vào màn chơi
	var mode_before := str(gm.get("current_mode"))
	var other := today + 1 if today < 28 else today - 2
	var now := Time.get_date_dict_from_system()
	var days := DailyCalendar.days_in_month(int(now.get("year", 2026)), int(now.get("month", 1)))
	scene.select_day(other)
	await process_frame
	_check(scene.selected_day() == other, "select_day doi ngay dang xem -> %d" % other)
	_check(str(gm.get("current_mode")) == mode_before, "Chon ngay KHONG doi mode GameManager (khong nhay man)")
	var date_label := scene.layout.lbl_date as Label
	_check(date_label.text == tr("STR_DAILY_DATE_BADGE").format([other, days]),
		"Nhan ngay tren bang doi theo ngay chon (nhan '%s')" % date_label.text)

	# Ngày tương lai (chưa mở) -> nút hành động bị khoá
	if today < 28 and row0 != null:
		_check(row0.action_button.disabled == true, "Ngay chua mo: nut hanh dong bi khoa")
	scene.select_day(today)
	await process_frame

	# Đánh dấu 2 nhiệm vụ đầu (CÓ thưởng Xu) -> nút đổi thành "HOÀN THÀNH"
	# (Xu đã nhận của hôm nay có thể khác 0 nếu người chơi đã chơi trước đó)
	var coins_today_before := int(dm.call("day_coins_earned", today))
	dm.call("set_day_mission_mask", today, 0)
	await process_frame
	var awarded_today := int(dm.call("complete_day_missions", today, [true, true, false, false]))
	await process_frame
	_check(awarded_today == 20, "Chot 2 nhiem vu hom nay -> thuong 20 Xu (nhan %d)" % awarded_today)
	if row0 != null:
		_check(row0.action_label.text == tr("STR_BTN_COMPLETE"),
			"Nut nhiem vu da xong = 'HOAN THANH' (nhan '%s')" % row0.action_label.text)
		_check(row0.action_button.disabled == false, "Hom nay: nut van bam duoc (choi lai)")
	if row3 != null:
		_check(row3.action_label.text == tr("STR_BTN_PLAY_NOW"),
			"Nut nhiem vu chua xong = 'VAO CHOI' (nhan '%s')" % row3.action_label.text)

	# Footer: tien do 2/4 + Xu da nhan
	var progress := scene.layout.lbl_progress as Label
	_check(progress.text == tr("STR_DAILY_TOTAL_PROGRESS").format([50, "2/4"]),
		"Footer tien do = 50%% (2/4) (nhan '%s')" % progress.text)
	var claim := scene.layout.lbl_claim as Label
	var expect_today_coins := coins_today_before + awarded_today
	_check(claim.text == tr("STR_DAILY_CLAIMED_REWARD").format([expect_today_coins, 50]),
		"Footer Xu = +%d/50 (nhan '%s')" % [expect_today_coins, claim.text])
	var reward := scene.layout.lbl_reward as Label
	_check(reward.text == "+50", "Tag thuong ngay = +50 Xu (nhan '%s')" % reward.text)

	# Header: ngày đang xem = hôm nay
	_check((scene.layout.lbl_date as Label).text
		== tr("STR_DAILY_DATE_BADGE").format([today, days]),
		"Header hien dung ngay dang chon")

	# Ngày bỏ lỡ đang khoá: nút CTA đổi thành "MỞ KHOÁ: 50 XU"
	if today >= 2:
		var missed := today - 1
		dm.call("set_day_mission_mask", missed, 0)
		dm.call("set_day_unlocked", missed, false)
		scene.select_day(missed)
		await process_frame
		var play_btn := scene.layout.btn_play as TextureButton
		var play_label := scene.layout.lbl_play as Label
		var cost := int(dm.call("unlock_cost"))
		_check(play_label.text == tr("STR_DAILY_UNLOCK_COST").format([cost]),
			"Ngay bo lo: CTA = 'MO KHOA: 50 XU' (nhan '%s')" % play_label.text)
		_check(play_btn.disabled == false, "Ngay bo lo: CTA van bam duoc (de mo khoa)")
		_check(row0 != null and row0.action_button.disabled == true,
			"Ngay bo lo chua mo khoa: hang nhiem vu bi khoa")

		# Ví không đủ Xu -> bấm CTA không mở được
		var coins_before := int(arch.get("coins")) if arch != null else 0
		if arch != null:
			arch.set("coins", 5)
			arch.call("notify_coins_changed")
		play_btn.pressed.emit()
		await process_frame
		_check(not bool(dm.call("is_day_unlocked", missed)), "Thieu Xu: bam CTA khong mo khoa")
		if arch != null:
			_check(int(arch.get("coins")) == 5, "Thieu Xu: khong bi tru Xu")
		_check(play_label.text == tr("STR_DAILY_UNLOCK_COST").format([cost]),
			"Thieu Xu: nhan CTA van la yeu cau mo khoa")

		# Đủ Xu -> mở khoá, ngày chơi được như bình thường
		if arch != null:
			arch.set("coins", coins_before)
			arch.call("notify_coins_changed")
		play_btn.pressed.emit()
		await process_frame
		_check(bool(dm.call("is_day_unlocked", missed)), "Du Xu: bam CTA mo khoa ngay %d" % missed)
		if arch != null:
			_check(int(arch.get("coins")) == coins_before - cost,
				"Mo khoa tru dung %d Xu" % cost)
		_check(play_label.text == tr("STR_DAILY_PLAY_MODE").format([_mode_label(dm, missed)]),
			"Mo khoa xong: CTA = 'CHOI <mode>' (nhan '%s')" % play_label.text)
		_check(row0 != null and row0.action_button.disabled == false,
			"Mo khoa xong: hang nhiem vu bam duoc")

		# Ô ngày trên lịch đổi viên trạng thái sang "ĐÃ MỞ"
		var cell := _cell_for(scene, missed)
		_check(cell != null and cell.status_label.text == tr("STR_DAILY_UNLOCKED"),
			"O ngay tren lich hien 'DA MO' (nhan '%s')"
			% (cell.status_label.text if cell != null else "?"))

		# Ngày tương lai: CTA vẫn là "CHƠI <mode>" nhưng bị khoá
		if today < 28:
			scene.select_day(today + 1)
			await process_frame
			_check(play_label.text == tr("STR_DAILY_PLAY_MODE").format([_mode_label(dm, today + 1)]),
				"Ngay tuong lai: CTA van la 'CHOI <mode>'")
			_check(play_btn.disabled == true, "Ngay tuong lai: CTA bi khoa")

		# Dọn trạng thái test
		dm.call("set_day_unlocked", missed, false)
		scene.select_day(today)
		await process_frame

	scene.queue_free()
	await process_frame


## Nhãn mode của một ngày (khớp cách màn Daily gọi tr())
func _mode_label(dm: Node, day: int) -> String:
	return tr("STR_MODE_%s" % str(dm.call("get_mode_for_day", day)).to_upper())


## Ô ngày trên lịch theo số ngày (chỉ tính ô của tháng đang xem, bỏ ô đệm/tháng trước)
func _cell_for(scene: DailyScene, day: int) -> DailyDayCell:
	var grid := scene.layout.calendar.get_node_or_null("Panel/Content/Days")
	if grid == null:
		return null
	for child in grid.get_children():
		var cell := child as DailyDayCell
		if cell != null and cell.day_number == day and cell.state == DailyDayCell.State.MISSED:
			return cell
	return null


# ---------------------------------------------------------------------------
# 4. Popup thắng Daily
# ---------------------------------------------------------------------------
func _section_4_popup(dm: Node) -> void:
	print("--- 4. Popup winning_daily ---")
	var scene: DailyScene = (load("res://scenes/daily.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var day := int(dm.call("get_today"))
	dm.call("set_day_mission_mask", day, 0b0111)

	var popup := Popups.open(Popups.WIN_DAILY, {
		"daily_day": day,
		"daily_variant": "classic",
		"daily_mode_id": "daily_classic",
		"daily_coins": 20,
		"daily_day_coins": 35,
		"daily_day_reward_max": 50,
		"daily_missions_done": 3,
		"daily_missions_total": 4,
		"time": 65.0,
		"steps_used": 12,
		"steps_max": 20,
		"wall_hits": 0,
	})
	await process_frame
	_check(popup != null, "Mo duoc popup win_daily")
	if popup != null:
		_check(popup is WinningDailyPopup, "Popup dung class WinningDailyPopup")
		var daily_btn := popup.get_node_or_null("Panel/Content/Information/Buttons/DailyBtn") as BaseButton
		var next_btn := popup.get_node_or_null("Panel/Content/Information/Buttons/NextBtn")
		_check(daily_btn != null, "Popup co nut 'VE DAILY'")
		_check(next_btn == null, "Popup KHONG con nut 'MAN KE TIEP'")
		if daily_btn != null:
			_check((daily_btn.get_node("Label") as Label).text == tr("STR_BTN_BACK_DAILY"),
				"Nut phai = 'VE DAILY' (nhan '%s')" % (daily_btn.get_node("Label") as Label).text)
		var coin_value := popup.get_node_or_null("Panel/Content/CoinArea/CoinValue") as Label
		_check(coin_value != null and coin_value.text == tr("STR_DAILY_REWARD_COINS").format([20]),
			"Hien Xu van nay '+20 XU' (nhan '%s')" % (coin_value.text if coin_value != null else "?"))
		var stamp := popup.get_node_or_null("Panel/Content/Stamp/StampTitle") as Label
		_check(stamp != null and stamp.text == tr("STR_DAILY_WIN_STAMP_TITLE").format([3, 4]),
			"Con dau = '3 / 4 NHIEM VU' (nhan '%s')" % (stamp.text if stamp != null else "?"))
		var subtitle := popup.get_node_or_null("Panel/Content/Subtitle") as Label
		_check(subtitle != null and subtitle.text.contains(tr("STR_DAILY_WIN_CLASSIC")),
			"Subtitle ghi ro maze thuong (nhan '%s')" % (subtitle.text if subtitle != null else "?"))

		# Signal bấm nút
		var got_daily := [false]
		var got_replay := [false]
		popup.connect("daily_requested", func() -> void: got_daily[0] = true)
		popup.connect("replay_requested", func() -> void: got_replay[0] = true)
		popup.call("_on_daily_pressed")
		_check(got_daily[0], "Bam 'VE DAILY' phat signal daily_requested")
		popup.call("_on_replay_pressed")
		_check(got_replay[0], "Bam 'CHOI LAI' phat signal replay_requested")

	# Kết nối UIController: ván daily -> chọn popup win_daily
	var ui_script: GDScript = load("res://scripts/core/controllers/ui_controller.gd")
	var ui: Node = ui_script.new()
	root.add_child(ui)
	await process_frame
	ui.call("show_floor_complete", {"daily": true, "endless": false, "daily_day": day})
	await process_frame
	_check(Popups.is_open(Popups.WIN_DAILY), "UIController mo popup WIN_DAILY khi ván la Daily")
	Popups.close_all()
	ui.queue_free()

	scene.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# 5. Chơi thật 1 GAME của ngày -> đánh dấu ĐÚNG ô (bit) của game đó
# ---------------------------------------------------------------------------
func _section_5_game_run(gm: Node, dm: Node) -> void:
	print("--- 5. Thang 1 GAME cua ngay -> danh dau dung game ---")
	var game_day := 1
	var game_index := -1
	var std_day := 1
	var std_index := -1
	for d in range(1, 61):
		var plan: Array = dm.call("get_day_games", d)
		for i in mini(plan.size(), 3):
			var e: Dictionary = plan[i] as Dictionary
			var mode := str(e.get("mode", ""))
			if game_index < 0 and mode == "challenge":
				game_day = d
				game_index = i
			if std_index < 0 and mode == "standard":
				std_day = d
				std_index = i
	_check(game_index >= 0, "Co ngay chua GAME CHALLENGE trong 60 ngay dau")
	_check(std_index >= 0, "Co ngay chua GAME STANDARD trong 60 ngay dau")

	var scene: GameScene = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	# --- GAME CHALLENGE: mode daily_challenge + ĐÚNG luật của ngày ---
	if game_index >= 0:
		dm.call("set_day_mission_mask", game_day, 0)
		gm.call("prepare_daily_game", game_day, game_index)
		scene.switch_mode("daily_challenge", "medium")
		await process_frame
		await process_frame
		var plan: Array = dm.call("get_day_games", game_day)
		var want_rule := str((plan[game_index] as Dictionary).get("challenge_id", ""))
		var mode := scene.game_mode_controller.game_mode as ChallengeGameMode
		_check(mode is DailyChallengeGameMode, "Mode 'daily_challenge' -> DailyChallengeGameMode")
		if mode != null:
			_check(mode.challenge_id == want_rule,
				"Luat cua ngay '%s' duoc gan (nhan '%s')" % [want_rule, mode.challenge_id])
			var grid := scene.game_controller.grid_controller
			var path := _rule_path(grid.maze, mode)
			_check(not path.is_empty(), "Maze trong ngay CO duong thang theo luat '%s'" % want_rule)
			for pos: Vector2i in path:
				grid.try_move_to(pos)
			await process_frame
			await process_frame
			_check(int(dm.call("is_mission_done", game_day, game_index)) == 1,
				"Thang game %d cua ngay %d -> danh dau dung o game do" % [game_index, game_day])
		Popups.close_all()
		await process_frame

	# --- GAME STANDARD: mode daily_classic -> thắng -> đánh dấu ô của game ---
	if std_index >= 0:
		dm.call("set_day_mission_mask", std_day, 0)
		gm.call("prepare_daily_game", std_day, std_index)
		scene.switch_mode("daily_classic", "medium")
		await process_frame
		await process_frame
		var mode2 := scene.game_mode_controller.game_mode
		_check(mode2 != null and mode2.mode_id == "daily_classic", "Game standard -> mode 'daily_classic'")
		var grid2 := scene.game_controller.grid_controller
		var path2 := _rule_path(grid2.maze, null)
		for pos2: Vector2i in path2:
			grid2.try_move_to(pos2)
		await process_frame
		await process_frame
		_check(int(dm.call("is_mission_done", std_day, std_index)) == 1,
			"Thang game standard %d cua ngay %d -> danh dau dung o game do" % [std_index, std_day])
		Popups.close_all()
		await process_frame

	scene.queue_free()
	await process_frame


## BFS tới F, chỉ qua ô hợp luật walk_* (mode = null -> đường thường)
func _rule_path(maze: MazeData, mode: ChallengeGameMode) -> Array[Vector2i]:
	var start := maze.get_start()
	var queue: Array[Vector2i] = [start]
	var came := {start: start}
	while not queue.is_empty():
		var cur: Vector2i = queue.pop_front()
		if cur == maze.get_end():
			break
		for dir: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cur + dir
			if next.x < 0 or next.y < 0 or next.x >= maze.width or next.y >= maze.height:
				continue
			if came.has(next) or maze.has_wall(cur, next):
				continue
			if mode != null and mode.is_walk_rule() and not mode.cell_allowed_by_rule(next, maze):
				continue
			came[next] = cur
			queue.append(next)
	var path: Array[Vector2i] = []
	if not came.has(maze.get_end()):
		return path
	var walk := maze.get_end()
	while walk != start:
		path.push_front(walk)
		walk = came[walk]
	return path


# ---------------------------------------------------------------------------
func _check(ok: bool, message: String) -> void:
	_checks += 1
	if ok:
		print("  [PASS] " + message)
	else:
		_failed += 1
		print("  [FAIL] " + message)
