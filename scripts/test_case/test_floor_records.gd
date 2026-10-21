extends SceneTree
## ============================================================================
## Test Case: KỶ LỤC TẦNG CAO NHẤT theo NGÀY / TUẦN / THÁNG
##
## 1. Khoá kỳ: "day" = YYYY-MM-DD · "week" = THỨ HAI của tuần · "month" = YYYY-MM.
## 2. GameManager.record_floor_reached: chỉ nâng kỷ lục, bỏ qua tầng <= 0 và ván Debug.
## 3. Sang kỳ mới (khoá cũ) thì kỷ lục đọc ra 0 — không mang kỷ lục cũ sang ngày/tuần/tháng mới.
## 4. Lưu/đọc: `floor_records` nằm trong blob tiến trình; `reset_progress()` xoá sạch.
## 5. Popup Game Over (Dungeon): hiện tầng cao nhất tuần/tháng, chưa có thì hiện "--".
## ============================================================================

const POPUP_SCENE := "res://nodes/popups/gameover.tscn"

var _backup := ""
var _checks := 0
var _failed := 0
var _saved := {}


func _init() -> void:
	print("\n========================================================")
	print("  TEST: KY LUC TANG CAO NHAT (NGAY / TUAN / THANG)")
	print("========================================================\n")

	await process_frame
	root.size = Vector2i(1080, 1920)

	if FileAccess.file_exists("user://inkmaze_data.json"):
		_backup = FileAccess.get_file_as_string("user://inkmaze_data.json")

	var gm: Node = root.get_node_or_null("GameManager")
	_check(gm != null, "Autoload GameManager ton tai")
	if gm == null:
		_finish()
		return

	_saved = gm.call("export_progress")
	gm.set("floor_record_in_tests", true)

	_section_keys()
	_section_record(gm)
	_section_expiry(gm)
	_section_save(gm)
	await _section_popup(gm)
	await _section_dungeon(gm)

	gm.call("import_progress", _saved)
	gm.set("floor_record_in_tests", false)
	_finish()


# ---------------------------------------------------------------------------
# 1. Khoá kỳ
# ---------------------------------------------------------------------------
func _section_keys() -> void:
	print("[1] Khoa ky (day/week/month)...")
	# 2026-10-21 là THỨ TƯ (Godot: 0 = Chủ nhật) -> thứ Hai của tuần là 2026-10-19
	var wed := {"year": 2026, "month": 10, "day": 21, "weekday": 3}
	_check(GameManagerClass.period_key("day", wed) == "2026-10-21", "Khoa ngay = 2026-10-21")
	_check(GameManagerClass.period_key("week", wed) == "2026-10-19", "Khoa tuan = thu Hai 2026-10-19")
	_check(GameManagerClass.period_key("month", wed) == "2026-10", "Khoa thang = 2026-10")

	# Chủ nhật phải lùi 6 ngày về thứ Hai của CÙNG tuần (2026-10-25 -> 2026-10-19)
	var sun := {"year": 2026, "month": 10, "day": 25, "weekday": 0}
	_check(GameManagerClass.period_key("week", sun) == "2026-10-19",
		"Chu nhat 25/10 cung tuan voi thu Hai 19/10")

	# Thứ Hai đầu tháng lùi sang tháng trước
	var mon := {"year": 2026, "month": 11, "day": 2, "weekday": 1}
	_check(GameManagerClass.period_key("week", mon) == "2026-11-02", "Thu Hai 2/11 giu nguyen")
	var mon2 := {"year": 2026, "month": 11, "day": 1, "weekday": 0}
	_check(GameManagerClass.period_key("week", mon2) == "2026-10-26",
		"Chu nhat 1/11 lui ve thu Hai 26/10 (thang truoc)")

	# Khoá hiện tại phải khác rỗng và đúng định dạng
	var now_day := GameManagerClass.current_period_key("day")
	_check(now_day.length() == 10 and now_day.substr(4, 1) == "-", "Khoa ngay hien tai '%s'" % now_day)


# ---------------------------------------------------------------------------
# 2. Ghi kỷ lục
# ---------------------------------------------------------------------------
func _section_record(gm: Node) -> void:
	print("[2] record_floor_reached...")
	gm.call("reset_progress")
	gm.set("debug_run", false)

	_check(int(gm.call("best_floor", "day")) == 0, "Chua co ky luc -> 0")
	_check(int(gm.call("best_floor", "week")) == 0, "Chua co ky luc tuan -> 0")
	_check(int(gm.call("best_floor", "month")) == 0, "Chua co ky luc thang -> 0")

	var hits: Array = []
	gm.connect("floor_record_changed", func(kind: String, floor_number: int):
		hits.append("%s:%d" % [kind, floor_number]))

	_check(bool(gm.call("record_floor_reached", 3)), "Dat tang 3 -> lap ky luc")
	_check(int(gm.call("best_floor", "day")) == 3, "Ky luc ngay = 3")
	_check(int(gm.call("best_floor", "week")) == 3, "Ky luc tuan = 3")
	_check(int(gm.call("best_floor", "month")) == 3, "Ky luc thang = 3")
	_check(hits.size() == 3, "Phat floor_record_changed cho ca 3 ky (%d)" % hits.size())

	hits.clear()
	_check(not bool(gm.call("record_floor_reached", 2)), "Tang 2 < 3 -> khong doi ky luc")
	_check(hits.is_empty(), "Khong phat signal khi khong lap ky luc moi")
	_check(int(gm.call("best_floor", "week")) == 3, "Ky luc tuan van = 3")

	_check(bool(gm.call("record_floor_reached", 7)), "Dat tang 7 -> lap ky luc moi")
	_check(int(gm.call("best_floor", "week")) == 7, "Ky luc tuan = 7")
	_check(hits.size() == 3, "Phat signal cho ca 3 ky khi nang len 7")

	_check(not bool(gm.call("record_floor_reached", 0)), "Tang 0 -> bo qua")
	_check(not bool(gm.call("record_floor_reached", -5)), "Tang am -> bo qua")

	gm.set("debug_run", true)
	_check(not bool(gm.call("record_floor_reached", 99)), "Van Debug -> khong ghi ky luc")
	gm.set("debug_run", false)
	_check(int(gm.call("best_floor", "month")) == 7, "Van Debug khong lam ban ky luc")


# ---------------------------------------------------------------------------
# 3. Sang kỳ mới thì kỷ lục bắt đầu lại
# ---------------------------------------------------------------------------
func _section_expiry(gm: Node) -> void:
	print("[3] Ky cu -> ky luc ve 0...")
	gm.set("floor_records", {
		"day": {"key": "2000-01-01", "floor": 12},
		"week": {"key": "2000-01-03", "floor": 12},
		"month": {"key": "2000-01", "floor": 12},
	})
	_check(int(gm.call("best_floor", "day")) == 0, "Ngay cu -> ky luc ngay = 0")
	_check(int(gm.call("best_floor", "week")) == 0, "Tuan cu -> ky luc tuan = 0")
	_check(int(gm.call("best_floor", "month")) == 0, "Thang cu -> ky luc thang = 0")

	_check(bool(gm.call("record_floor_reached", 2)), "Ky moi: dat tang 2 la ky luc")
	_check(int(gm.call("best_floor", "day")) == 2, "Ky moi: ky luc ngay = 2 (khong dinh 12 cu)")
	_check(int(gm.call("best_floor", "month")) == 2, "Ky moi: ky luc thang = 2")

	var day_key := str((gm.get("floor_records") as Dictionary)["day"].get("key", ""))
	_check(day_key == GameManagerClass.current_period_key("day"), "Khoa ngay da cap nhat (%s)" % day_key)


# ---------------------------------------------------------------------------
# 4. Lưu / đọc tiến trình
# ---------------------------------------------------------------------------
func _section_save(gm: Node) -> void:
	print("[4] Luu / doc floor_records...")
	gm.call("reset_progress")
	gm.call("record_floor_reached", 9)
	var blob: Dictionary = gm.call("export_progress")
	_check(blob.has("floor_records"), "Blob tien trinh co 'floor_records'")
	var saved: Dictionary = blob.get("floor_records", {})
	_check(int((saved.get("week", {}) as Dictionary).get("floor", 0)) == 9,
		"Blob luu ky luc tuan = 9")

	gm.call("reset_progress")
	_check(int(gm.call("best_floor", "week")) == 0, "reset_progress() xoa ky luc")
	gm.call("import_progress", blob)
	_check(int(gm.call("best_floor", "day")) == 9, "Doc lai: ky luc ngay = 9")
	_check(int(gm.call("best_floor", "week")) == 9, "Doc lai: ky luc tuan = 9")
	_check(int(gm.call("best_floor", "month")) == 9, "Doc lai: ky luc thang = 9")

	# Blob của kỳ CŨ: nạp vào phải thành 0 (không mang kỷ lục tháng trước sang)
	gm.call("import_progress", {"floor_records": {
		"day": {"key": "2000-01-01", "floor": 30},
		"week": {"key": "2000-01-03", "floor": 30},
		"month": {"key": "2000-01", "floor": 30},
	}})
	_check(int(gm.call("best_floor", "week")) == 0, "Blob ky cu -> ky luc tuan = 0")

	# Save cũ (chưa có floor_records) vẫn nạp được, kỷ lục = 0
	gm.call("import_progress", {"lives": 4})
	_check(int(gm.call("best_floor", "month")) == 0, "Save cu (khong co floor_records) -> 0")


# ---------------------------------------------------------------------------
# 5. Popup Game Over hiện kỷ lục tuần/tháng
# ---------------------------------------------------------------------------
func _section_popup(gm: Node) -> void:
	print("[5] Popup Game Over hien ky luc tuan/thang...")
	gm.call("reset_progress")

	var packed := load(POPUP_SCENE) as PackedScene
	_check(packed != null, "Nap duoc gameover.tscn")
	if packed == null:
		return
	var popup := packed.instantiate() as GameOverPopup
	root.add_child(popup)
	await process_frame
	var week_label: Label = popup.get("value_best_week")
	var month_label: Label = popup.get("value_best_month")
	_check(week_label != null, "Bind value_best_week")
	_check(month_label != null, "Bind value_best_month")

	popup.call("open", {"floor": 4, "progress": 40, "wall_hits": 1, "score": 120,
		"steps_left": 0, "steps_max": 15})
	await process_frame
	_check(week_label != null and week_label.text.contains("--"),
		"Chua co ky luc -> tuan hien '--' ('%s')" % (week_label.text if week_label != null else ""))
	_check(month_label != null and month_label.text.contains("--"),
		"Chua co ky luc -> thang hien '--' ('%s')" % (month_label.text if month_label != null else ""))
	_check(week_label != null and week_label.text != "STR_GAMEOVER_BEST_WEEK",
		"Nhan tuan da dich")

	gm.call("record_floor_reached", 6)
	gm.call("record_floor_reached", 11)
	popup.call("open", {"floor": 4, "progress": 40, "wall_hits": 1, "score": 120})
	await process_frame
	_check(week_label != null and week_label.text.contains("11"),
		"Co ky luc -> tuan hien 11 ('%s')" % (week_label.text if week_label != null else ""))
	_check(month_label != null and month_label.text.contains("11"),
		"Co ky luc -> thang hien 11 ('%s')" % (month_label.text if month_label != null else ""))

	# `data` được ưu tiên (GameController có thể truyền sẵn số)
	popup.call("open", {"best_floor_week": 42, "best_floor_month": 77})
	await process_frame
	_check(week_label != null and week_label.text.contains("42"), "data.best_floor_week duoc uu tien")
	_check(month_label != null and month_label.text.contains("77"), "data.best_floor_month duoc uu tien")

	# Bố cục: hàng kỷ lục nằm giữa 3 chỉ số và Banner, không đè lên nhau
	var info := popup.get_node_or_null("Panel/Content/Information") as Control
	var records := popup.get_node_or_null("Panel/Content/Information/Records") as Control
	var stat3 := popup.get_node_or_null("Panel/Content/Information/Stat3") as Control
	var banner := popup.get_node_or_null("Panel/Content/Information/Banner") as Control
	var quote := popup.get_node_or_null("Panel/Content/Information/Quote") as Control
	_check(info != null and records != null and stat3 != null and banner != null and quote != null,
		"Du node bo cuc (Information/Records/Stat3/Banner/Quote)")
	if info != null and records != null and stat3 != null and banner != null and quote != null:
		_check(records.size.y >= 20.0, "Hang ky luc co chieu cao (%d px)" % int(records.size.y))
		_check(records.position.y >= stat3.position.y + stat3.size.y - 1.0,
			"Hang ky luc nam DUOI 3 chi so")
		_check(banner.position.y >= records.position.y + records.size.y - 1.0,
			"Banner nam DUOI hang ky luc")
		_check(quote.get_global_rect().end.y <= info.get_global_rect().end.y + 1.0,
			"Toan bo noi dung popup nam trong khung (khong tran)")

	popup.queue_free()
	await process_frame


## Ván Dungeon (vô tận) ghi kỷ lục theo tầng; ván theo MÀN (Play) thì KHÔNG ghi
func _section_dungeon(gm: Node) -> void:
	print("[6] Van choi ghi ky luc dung che do...")
	var prev_mode := str(gm.get("current_mode"))
	gm.call("reset_progress")
	gm.set("current_mode", "dungeon")

	var scene := (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var controller: GameController = scene.get("game_controller")
	_check(controller != null and controller.game_mode != null and controller.game_mode.is_endless,
		"Mo duoc van Dungeon (vo tan)")
	_check(int(gm.call("best_floor", "day")) == 1, "Vao tang 1 -> ky luc ngay = 1")
	controller.call("_on_continue_requested")      # tang 1 -> tang 2
	await process_frame
	_check(controller.game_state.floor_number == 2, "Qua tang 2")
	_check(int(gm.call("best_floor", "day")) == 2, "Tang 2 -> ky luc ngay = 2")
	_check(int(gm.call("best_floor", "week")) == 2, "Tang 2 -> ky luc tuan = 2")
	_check(int(gm.call("best_floor", "month")) == 2, "Tang 2 -> ky luc thang = 2")
	scene.queue_free()
	await process_frame

	# Ván theo MÀN (Play Mode): số "tầng" chỉ là ID màn nên KHÔNG ghi kỷ lục tầng
	gm.call("reset_progress")
	gm.set("current_mode", "play")
	gm.set("current_level", 3)
	gm.set("unlocked_levels", 9)
	var level_scene := (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(level_scene)
	await process_frame
	await process_frame
	var level_controller: GameController = level_scene.get("game_controller")
	_check(level_controller != null and level_controller.game_state.floor_number == 3,
		"Van MAN bat dau o man 3")
	_check(int(gm.call("best_floor", "day")) == 0,
		"Van MAN (Play) KHONG ghi ky luc tang (dang %d)" % int(gm.call("best_floor", "day")))
	level_scene.queue_free()
	await process_frame

	gm.set("current_mode", prev_mode)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("  [PASS] %s" % message)
	else:
		_failed += 1
		print("  [FAIL] %s" % message)


func _finish() -> void:
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
