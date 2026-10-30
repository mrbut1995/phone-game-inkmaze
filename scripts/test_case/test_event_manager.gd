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
## ☠️ Phải sao lưu cả FILE SAVE: mọi thay đổi tiến độ phát tín hiệu "changed" ⇒ SaveManager
## ghi ngay ra `user://inkmaze_data.json`; chỉ khôi phục RAM là file vẫn giữ số liệu của test.
const SAVE_PATH := "user://inkmaze_data.json"
var _save_backup := ""

const NEW_THEME_IDS := [
	&"anniversary", &"autumn", &"easter", &"new_year",
	&"spring", &"summer", &"thanksgiving", &"valentine",
]
const NEW_EVENT_IDS := NEW_THEME_IDS


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
	_save_backup = FileAccess.get_file_as_string(SAVE_PATH) if FileAccess.file_exists(SAVE_PATH) else ""

	_section_load_and_sort()
	_section_theme_art()
	_section_new_event_data()
	_section_time_filter()
	await _section_all_active_events_and_dots()
	_section_series_progress()
	_section_claim()
	_section_dungeon()
	_section_login_streak()
	_section_invalid()
	_section_persistence()

	# Khôi phục
	_em.set("_all_events", _saved_events)
	_em.call("import_progress", _saved_progress)
	if not _save_backup.is_empty():
		var wf := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		if wf != null:
			wf.store_string(_save_backup)
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
## Độ tương phản WCAG giữa 2 màu (dùng để bắt theme có tiêu đề bị chìm)
func _contrast_ratio(a: Color, b: Color) -> float:
	var la := _relative_luminance(a)
	var lb := _relative_luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


func _relative_luminance(c: Color) -> float:
	var channels := [c.r, c.g, c.b]
	var weights := [0.2126, 0.7152, 0.0722]
	var total := 0.0
	for i in 3:
		var v: float = channels[i]
		v = v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4)
		total += float(weights[i]) * v
	return total


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
	var preview_events: Array = _em.call("get_all_events_for_preview")
	_check(preview_events.size() == (_em.get("_all_events") as Array).size(),
		"API xem thu giu ca event ngoai lich/disabled")
	var mansion := _em.call("get_event", &"mansion") as EventData
	_check(mansion != null, "EventData mansion duoc nap tu resources/events")
	if mansion != null and mansion.is_active_now(int(_em.call("now_utc"))):
		_check(mansion in active, "Mansion dang trong han duoc dua vao danh sach hien thi")
	var prev := -1
	var sorted_ok := true
	for i in range(1, active.size()):
		var so := int((active[i] as EventData).sort_order)
		if so < prev:
			sorted_ok = false
		prev = so
	_check(sorted_ok, "Cac event con lai xep theo sort_order tang dan")

	var daily_prog: Dictionary = _em.call("get_progress", &"daily")
	_check(int(daily_prog.get("total", 0)) == EventData.DAILY_STARS_TOTAL,
		"Daily co %d Sao/ngay (dang %d)" % [EventData.DAILY_STARS_TOTAL, int(daily_prog.get("total", 0))])


func _section_theme_art() -> void:
	print("Kiem tra art theme...")
	var dir := DirAccess.open("res://resources/events/themes")
	_check(dir != null, "Thu muc EventTheme ton tai")
	if dir == null:
		return

	var loaded_ids: Array[StringName] = []
	var title_pairs := {}
	dir.list_dir_begin()
	var filename := dir.get_next()
	while not filename.is_empty():
		if not dir.current_is_dir() and filename.ends_with(".tres"):
			var path := "res://resources/events/themes/" + filename
			var theme := ResourceLoader.load(path, "EventTheme") as EventTheme
			_check(theme != null, "%s load thanh EventTheme" % filename)
			if theme != null:
				loaded_ids.append(theme.id)
				# Bộ NÚT event v2 (§13.31): mọi theme (trừ `daily` — Daily ở dock) phải có art NÚT.
				# Art THẺ đã bỏ khỏi EventTheme (chi con art NUT).
				_check(theme.title_color.a == 1.0 and theme.title_outline.a == 1.0,
					"%s dung title color/outline khong trong suot" % theme.id)
				_check(theme.title_color != theme.title_outline,
					"%s phan biet title fill va outline" % theme.id)
				var pair := "%s/%s" % [
					theme.title_color.to_html(false), theme.title_outline.to_html(false)]
				_check(not title_pairs.has(pair),
					"%s dung cap mau tieu de rieng (khong trung theme khac)" % theme.id)
				title_pairs[pair] = theme.id
				var title_contrast := _contrast_ratio(theme.title_color, theme.title_outline)
				_check(title_contrast >= 4.5,
					"%s chu tieu de tuong phan voi vien (%.2f)" % [theme.id, title_contrast])
				if theme.id not in [&"daily"]:
					_check(theme.button_normal != null, "%s co art NUT (button_normal)" % theme.id)
					_check(theme.button_pressed != null, "%s co button_pressed" % theme.id)
					_check(theme.button_disabled != null, "%s co button_disabled" % theme.id)
					if theme.button_normal != null and theme.button_disabled != null:
						var n_size := theme.button_normal.get_size()
						var d_size := theme.button_disabled.get_size()
						_check(n_size == d_size,
							"%s 3 trang thai nut cung co (%s vs %s)" % [theme.id, n_size, d_size])
		filename = dir.get_next()
	dir.list_dir_end()

	for theme_id in NEW_THEME_IDS:
		_check(theme_id in loaded_ids, "Theme moi %s da duoc dang ky" % theme_id)


func _section_new_event_data() -> void:
	print("Kiem tra EventData moi...")
	for event_id in NEW_EVENT_IDS:
		var event := _em.call("get_event", event_id) as EventData
		_check(event != null, "EventData %s da duoc nap" % event_id)
		if event == null:
			continue
		_check(event.is_valid(), "EventData %s hop le" % event_id)
		_check(event.theme != null and event.theme.id == event_id,
			"EventData %s dung theme tuong ung" % event_id)
		_check(event.type in [EventData.Type.SPECIAL_SERIES, EventData.Type.STANDARD_SERIES],
			"EventData %s dung luong CTA da ho tro" % event_id)
		_check(event.levels.size() == 3, "EventData %s co 3 man" % event_id)
		_check(event.rewards.size() == 2, "EventData %s co du 2 phan thuong" % event_id)


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


func _section_all_active_events_and_dots() -> void:
	print("Kiem tra hien thi tat ca EventData trong che do xem thu...")
	var many_events: Array = [_mk("daily", EventData.Type.DAILY, -9999, 0, 0)]
	for i in 10:
		var event := _mk("t_many_%d" % i, EventData.Type.STANDARD_SERIES, i, -3600, 3600)
		if i % 2 == 0:
			event.start_utc = Time.get_datetime_string_from_unix_time(
				int(Time.get_unix_time_from_system()) + 3600, false)
		elif i == 9:
			event.enabled = false
		many_events.append(event)
	_set_events(many_events)
	var active: Array = _em.call("get_active_events")
	var preview_events: Array = _em.call("get_all_events_for_preview")
	_check(active.size() < many_events.size(),
		"Gameplay van loc event chua toi lich/disabled (%d/%d)" % [active.size(), many_events.size()])
	_check(preview_events.size() == many_events.size(),
		"Che do xem thu tra ve tat ca EventData, ke ca chua toi lich/disabled (%d)" % preview_events.size())
	_check((preview_events[0] as EventData).type == EventData.Type.DAILY,
		"Daily van dung dau danh sach xem thu")

	var packed := load("res://nodes/main/event_dots.tscn") as PackedScene
	var event_dots: EventDots = null
	if packed != null:
		event_dots = packed.instantiate() as EventDots
	_check(event_dots != null, "EventDots scene instantiate thanh cong")
	if event_dots == null:
		return
	root.add_child(event_dots)
	await process_frame
	event_dots.set_pages(preview_events.size(), preview_events.size() - 1)
	_check(event_dots.get_node("Dots").get_child_count() == preview_events.size(),
		"Co mot cham trang cho moi EventData")
	var last_dot := event_dots.get_node("Dots").get_child(preview_events.size() - 1) as Panel
	_check(last_dot.visible, "Cham trang cuoi hien thi khi danh sach vuot 8 event")
	event_dots.queue_free()

	var carousel_packed := load("res://nodes/main/event_carousel.tscn") as PackedScene
	var carousel: EventCarousel = null
	if carousel_packed != null:
		carousel = carousel_packed.instantiate() as EventCarousel
	_check(carousel != null, "EventCarousel scene instantiate thanh cong")
	if carousel == null:
		await process_frame
		return
	root.add_child(carousel)
	await process_frame
	carousel.refresh()
	await process_frame
	_check(carousel.get_node("ScrollContainer/HBox").get_child_count() == preview_events.size(),
		"EventCarousel hien thi tat ca EventData, ke ca event inactive")
	carousel.queue_free()
	await process_frame


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
