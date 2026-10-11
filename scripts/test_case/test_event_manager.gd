extends SceneTree
## ============================================================================
## Test: EVENT MANAGER — lọc thời gian · sắp xếp · tiến độ · nhận quà · Dungeon ·
## Login streak · dữ liệu lỗi (§B10).
## ============================================================================

var _failed := 0
var _checks := 0
var _em: Node = null
var _saved_events: Array = []
var _saved_progress: Dictionary = {}


func _init() -> void:
	print("\n========================================================")
	print("  TEST: EVENT MANAGER")
	print("========================================================\n")
	await process_frame
	_em = root.get_node_or_null("EventManager")
	_check(_em != null, "Autoload EventManager ton tai")
	if _em == null:
		_finish()
		return

	# Giữ lại trạng thái thật để khôi phục cuối test
	_saved_events = (_em.get("_all_events") as Array).duplicate()
	_saved_progress = (_em.call("export_progress") as Dictionary).duplicate(true)

	_section_load_and_sort()
	_section_time_filter()
	_section_series_progress()
	_section_claim()
	_section_dungeon()
	_section_login_streak()
	_section_invalid()
	_section_persistence()

	# Khôi phục
	_em.set("_all_events", _saved_events)
	_em.call("import_progress", _saved_progress)
	_finish()


func _finish() -> void:
	print("\n--------------------------------------------------------")
	if _failed == 0:
		print("  KET QUA: %d/%d CHECK PASS" % [_checks, _checks])
	else:
		print("  KET QUA: %d/%d CHECK FAIL" % [_failed, _checks])
	print("--------------------------------------------------------\n")
	quit(1 if _failed > 0 else 0)


func _check(cond: bool, label: String) -> void:
	_checks += 1
	if cond:
		print("  [PASS] %s" % label)
	else:
		_failed += 1
		print("  [FAIL] %s" % label)


# ---------------------------------------------------------------------------
func _mk(id: String, type: EventData.Type, sort_order: int, start_off: int, end_off: int,
		enabled := true) -> EventData:
	var e := EventData.new()
	e.id = StringName(id)
	e.type = type
	e.theme = EventTheme.new()
	e.enabled = enabled
	e.sort_order = sort_order
	e.chip_key = &"STR_EVENT_HEADER"
	e.unit_key = &"STR_EVENT_UNIT_LEVELS"
	e.cta_key = &"STR_EVENT_CTA_PLAY"
	var now := int(Time.get_unix_time_from_system())
	if start_off != 0 or end_off != 0:
		e.start_utc = Time.get_datetime_string_from_unix_time(now + start_off, false)
		e.end_utc = Time.get_datetime_string_from_unix_time(now + end_off, false)
	return e


func _set_events(arr: Array) -> void:
	var typed: Array[EventData] = []
	for e in arr:
		if e is EventData:
			typed.append(e as EventData)
	_em.set("_all_events", typed)
	_em.call("reset_progress")


func _mk_level(id: int) -> LevelData:
	var lvl := LevelData.new()
	lvl.level_id = id
	lvl.mode_id = "play"
	lvl.difficulty = "easy"
	return lvl


func _fresh() -> void:
	_em.call("reset_progress")


# ---------------------------------------------------------------------------
# 1. Nạp từ đĩa + Daily ghim đầu + sắp xếp theo sort_order
# ---------------------------------------------------------------------------
func _section_load_and_sort() -> void:
	print("[1] Nap su kien tu dia + sap xep...")
	_em.call("_load_all_events")
	var active: Array = _em.call("get_active_events")
	_check(active.size() > 0, "Co su kien dang hoat dong (%d)" % active.size())
	_check((active[0] as EventData).type == EventData.Type.DAILY,
		"Event DAILY luon dung DAU danh sach")
	var prev := -1
	var sorted_ok := true
	for i in range(1, active.size()):
		var so := int((active[i] as EventData).sort_order)
		if so < prev:
			sorted_ok = false
		prev = so
	_check(sorted_ok, "Cac event con lai xep theo sort_order tang dan")

	var daily_prog: Dictionary = _em.call("get_progress", &"daily")
	_check(int(daily_prog.get("total", 0)) == 3, "Daily co 3 thu thach (dang %d)" % int(daily_prog.get("total", 0)))


# ---------------------------------------------------------------------------
# 2. Lọc theo thời gian + enabled
# ---------------------------------------------------------------------------
func _section_time_filter() -> void:
	print("[2] Loc theo thoi gian...")
	var now := int(Time.get_unix_time_from_system())
	var before := _mk("t_before", EventData.Type.SPECIAL_SERIES, 10, 3600, 7200)
	var inside := _mk("t_inside", EventData.Type.SPECIAL_SERIES, 20, -3600, 3600)
	var after := _mk("t_after", EventData.Type.SPECIAL_SERIES, 30, -7200, -3600)
	var off := _mk("t_off", EventData.Type.SPECIAL_SERIES, 40, -3600, 3600, false)
	_check(not before.is_active_now(now), "Truoc start -> an")
	_check(inside.is_active_now(now), "Trong khoang -> hien")
	_check(not after.is_active_now(now), "Sau end -> an")
	_check(not off.is_active_now(now), "enabled=false -> an")
	_check(inside.seconds_remaining(now) > 0, "seconds_remaining > 0 khi con han")

	_set_events([_mk("daily", EventData.Type.DAILY, -9999, 0, 0), before, inside, after, off])
	var active: Array = _em.call("get_active_events")
	var ids: Array[String] = []
	for e in active:
		ids.append(str((e as EventData).id))
	_check(ids == ["daily", "t_inside"], "get_active_events chi tra Daily + event trong han (%s)" % str(ids))


# ---------------------------------------------------------------------------
# 3. Tiến độ chuỗi màn
# ---------------------------------------------------------------------------
func _section_series_progress() -> void:
	print("[3] Tien do chuoi man...")
	var ev := _mk("ev_series", EventData.Type.STANDARD_SERIES, 10, -3600, 3600)
	var lv: Array[LevelData] = [_mk_level(1001), _mk_level(1002)]
	ev.levels = lv
	_set_events([ev])

	_em.call("on_level_won", &"ev_series", lv[0], 3)
	var p1: Dictionary = _em.call("get_progress", &"ev_series")
	_check(int(p1.get("done", -1)) == 1, "Thang 1 man -> done = 1 (dang %d)" % int(p1.get("done", -1)))
	_check(not bool(p1.get("completed", true)), "Chua du man -> completed = false")

	_em.call("on_level_won", &"ev_series", lv[0], 3)
	var p2: Dictionary = _em.call("get_progress", &"ev_series")
	_check(int(p2.get("done", -1)) == 1, "Thang LAI man cu -> done khong tang (dang %d)" % int(p2.get("done", -1)))

	_em.call("on_level_won", &"ev_series", lv[1], 2)
	var p3: Dictionary = _em.call("get_progress", &"ev_series")
	_check(int(p3.get("done", -1)) == 2 and bool(p3.get("completed", false)),
		"Du man -> completed = true (done %d)" % int(p3.get("done", -1)))


# ---------------------------------------------------------------------------
# 4. Nhận quà (idempotent)
# ---------------------------------------------------------------------------
func _section_claim() -> void:
	print("[4] Nhan qua (idempotent)...")
	var ev := _mk("ev_claim", EventData.Type.STANDARD_SERIES, 10, -3600, 3600)
	var lv: Array[LevelData] = [_mk_level(2001)]
	ev.levels = lv
	var r := EventReward.new()
	r.kind = EventReward.Kind.COIN
	r.amount = 250
	var rewards: Array[EventReward] = [r]
	ev.rewards = rewards
	_set_events([ev])

	_check(not bool(_em.call("can_claim", &"ev_claim")), "Chua hoan thanh -> khong the nhan")
	_check(not bool(_em.call("claim_reward", &"ev_claim")), "Chua hoan thanh -> claim_reward = false")

	var shop := root.get_node_or_null("ShopManager")
	var before := int(shop.call("coins")) if shop != null else 0
	_em.call("on_level_won", &"ev_claim", lv[0], 3)
	_check(bool(_em.call("can_claim", &"ev_claim")), "Hoan thanh -> co the nhan")
	_check(bool(_em.call("claim_reward", &"ev_claim")), "claim_reward lan 1 = true")
	var after := int(shop.call("coins")) if shop != null else 0
	_check(after == before + 250, "Xu cong dung 250 (%d -> %d)" % [before, after])
	_check(not bool(_em.call("claim_reward", &"ev_claim")), "claim_reward lan 2 = false (idempotent)")
	var after2 := int(shop.call("coins")) if shop != null else 0
	_check(after2 == after, "Goi 2 lan chi phat qua 1 lan (%d)" % after2)


# ---------------------------------------------------------------------------
# 5. Dungeon: hệ số xu + mốc tầng
# ---------------------------------------------------------------------------
func _section_dungeon() -> void:
	print("[5] Dungeon event...")
	var ev := _mk("ev_dungeon", EventData.Type.DUNGEON, 10, -3600, 3600)
	ev.dungeon_coin_multiplier = 2.0
	ev.dungeon_milestones = PackedInt32Array([5, 10, 15])
	_set_events([ev])

	_check(is_equal_approx(float(_em.call("get_dungeon_coin_multiplier")), 2.0),
		"Trong han -> he so xu = 2.0")
	_em.call("on_dungeon_floor_cleared", 7)
	var p: Dictionary = _em.call("get_progress", &"ev_dungeon")
	_check(int(p.get("done", 0)) == 3, "best_floor 7 -> done = 3 moc (dang %d)" % int(p.get("done", 0)))
	_check(bool(p.get("completed", false)), "Dat moc cuoi -> completed = true")

	var outside := _mk("ev_dungeon_off", EventData.Type.DUNGEON, 10, -7200, -3600)
	outside.dungeon_coin_multiplier = 3.0
	_set_events([outside])
	_check(is_equal_approx(float(_em.call("get_dungeon_coin_multiplier")), 1.0),
		"Ngoai han -> he so xu = 1.0")


# ---------------------------------------------------------------------------
# 6. Login streak: 1 lần/ngày
# ---------------------------------------------------------------------------
func _section_login_streak() -> void:
	print("[6] Chuoi dang nhap...")
	var ev := _mk("ev_login", EventData.Type.LOGIN_STREAK, 10, -3600, 86400 * 30)
	ev.login_days_required = 7
	_set_events([ev])
	_em.set("_last_login_day", "")

	_em.call("on_app_day_started")
	var p1: Dictionary = _em.call("get_progress", &"ev_login")
	_check(int(p1.get("done", 0)) == 1, "Ngay moi -> cong 1 ngay (dang %d)" % int(p1.get("done", 0)))
	_em.call("on_app_day_started")
	_em.call("on_app_day_started")
	var p2: Dictionary = _em.call("get_progress", &"ev_login")
	_check(int(p2.get("done", 0)) == 1, "Mo app nhieu lan trong ngay -> khong cong them (%d)" % int(p2.get("done", 0)))


# ---------------------------------------------------------------------------
# 7. Dữ liệu lỗi bị bỏ qua, không crash
# ---------------------------------------------------------------------------
func _section_invalid() -> void:
	print("[7] Du lieu loi bi bo qua...")
	var bad := EventData.new()
	bad.id = &""
	bad.theme = null
	_check(not bad.is_valid(), "Event thieu id + theme -> is_valid = false")

	var bad2 := _mk("ev_bad_range", EventData.Type.STANDARD_SERIES, 10, 7200, 3600)
	var lv: Array[LevelData] = [_mk_level(3001)]
	bad2.levels = lv
	_check(not bad2.is_valid(), "end < start -> is_valid = false")

	var bad3 := _mk("ev_empty_levels", EventData.Type.STANDARD_SERIES, 10, -3600, 3600)
	_check(not bad3.is_valid(), "Series khong co man -> is_valid = false")


# ---------------------------------------------------------------------------
# 8. Lưu / nạp lại tiến độ
# ---------------------------------------------------------------------------
func _section_persistence() -> void:
	print("[8] Luu / nap tien do...")
	var ev := _mk("ev_save", EventData.Type.STANDARD_SERIES, 10, -3600, 3600)
	var lv: Array[LevelData] = [_mk_level(4001), _mk_level(4002)]
	ev.levels = lv
	_set_events([ev])
	_em.call("on_level_won", &"ev_save", lv[0], 3)
	var snapshot: Dictionary = _em.call("export_progress")
	_em.call("reset_progress")
	_check((_em.call("get_progress", &"ev_save") as Dictionary).get("done", 0) == 0,
		"Sau reset -> tien do ve 0")
	_em.call("import_progress", snapshot)
	var restored: Dictionary = _em.call("get_progress", &"ev_save")
	_check(int(restored.get("done", 0)) == 1, "Nap lai -> tien do giu nguyen (done %d)" % int(restored.get("done", 0)))
