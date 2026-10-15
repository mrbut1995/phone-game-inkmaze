extends Node
## ============================================================================
## Autoload: EventManager — Quản lý toàn bộ Event System.
##
## Đăng ký: project.godot [autoload] EventManager = "*res://scripts/manager/EventManager.gd"
##
## THIẾT KẾ:
##  • Quét res://resources/events/*.tres lúc khởi động (data-driven, B12 GDD).
##  • Daily = EventData ảo (không phải file .tres) tạo từ DailyManager.
##  • Lưu tiến độ qua SaveManager (export_progress / import_progress).
##  • Nguồn thời gian: now_utc() — bọc trong 1 hàm duy nhất để dễ thay bằng giờ server.
##  • Chống chỉnh giờ máy: TODO giai đoạn 2 (ghi chú trong code).
## ============================================================================

signal events_changed
signal event_progress_changed(event_id: StringName)
signal event_expired(event_id: StringName)

## Thư mục chứa file .tres event
const EVENTS_DIR := "res://resources/events/"
## Xoá bản ghi event đã hết hạn quá N ngày
const STALE_DAYS := 30

## Cache tất cả EventData đã nạp (kể cả Daily ảo)
var _all_events: Array[EventData] = []

## Tiến độ người chơi: { "<id>": { done_levels: [str], best_floor: int,
##   login_days: [str], claimed: bool } }
var _progress: Dictionary = {}

## Ngày cuối đã ghi đăng nhập (để tránh ghi trùng)
var _last_login_day: String = ""

## Offset thời gian giả (debug): số giây cộng thêm vào now_utc()
var _debug_time_offset: int = 0

## Đã chạy nạp danh mục/event chưa (LoadingManager gọi `initialize()` — xem đầu file)
var _initialized := false

# ---------------------------------------------------------------------------
# LIFECYCLE
# ---------------------------------------------------------------------------

func _ready() -> void:
	# Quét thư mục + nạp toàn bộ EventData là việc NẶNG ⇒ hoãn tới khi màn Splash đã hiện
	# (xem LoadingManager). Headless thì LoadingManager gọi lại NGAY nên hành vi không đổi.
	var boot: Node = get_node_or_null("/root/LoadingManager")
	if boot != null and boot.has_method("add_step"):
		boot.call("add_step", Callable(self, "initialize"), "events")
	else:
		initialize()


## Nạp toàn bộ EventData + ghi nhận ngày đăng nhập (idempotent)
func initialize() -> void:
	if _initialized:
		return
	_initialized = true
	_load_all_events()
	# Gọi on_app_day_started mỗi khi game khởi động (đếm login streak)
	on_app_day_started()


# ---------------------------------------------------------------------------
# NGUỒN THỜI GIAN (bọc để dễ thay bằng giờ server ở giai đoạn 2)
# ---------------------------------------------------------------------------

## Trả thời gian hiện tại dưới dạng unix timestamp (UTC).
## Chống chỉnh giờ máy: TODO giai đoạn 2 — thêm server sync ở đây, không sửa chỗ khác.
func now_utc() -> int:
	return int(Time.get_unix_time_from_system()) + _debug_time_offset


## Trả chuỗi "YYYY-MM-DD" UTC hiện tại (dùng để khử trùng login)
func _today_str() -> String:
	var d := Time.get_datetime_dict_from_unix_time(now_utc())
	return "%04d-%02d-%02d" % [d.get("year", 0), d.get("month", 0), d.get("day", 0)]


# ---------------------------------------------------------------------------
# NẠP EVENT
# ---------------------------------------------------------------------------

func _load_all_events() -> void:
	_all_events.clear()
	# 1. Event Daily ảo
	var daily := _make_daily_event()
	if daily != null:
		_all_events.append(daily)
	# 2. Quét thư mục resources/events/*.tres
	var dir := DirAccess.open(EVENTS_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with(".tres"):
			var path := EVENTS_DIR + fname
			var res := ResourceLoader.load(path, "EventData", ResourceLoader.CACHE_MODE_REUSE)
			if res is EventData:
				var ev: EventData = res
				if ev.type == EventData.Type.DAILY:
					fname = dir.get_next()
					continue # Daily chỉ tạo 1 lần ảo ở trên
				if not ev.is_valid():
					push_warning("[EventManager] Event lỗi dữ liệu, bỏ qua: %s" % path)
					fname = dir.get_next()
					continue
				_all_events.append(ev)
			else:
				push_warning("[EventManager] Không nạp được EventData từ: %s" % path)
		fname = dir.get_next()
	dir.list_dir_end()
	events_changed.emit()


## Tạo EventData ảo cho Daily từ DailyManager
func _make_daily_event() -> EventData:
	var ev := EventData.new()
	ev.id = &"daily"
	ev.type = EventData.Type.DAILY
	ev.enabled = true
	ev.sort_order = -9999 # luôn đứng đầu
	ev.chip_key = &"STR_EVENT_DAILY_CHIP"
	ev.title_key_1 = &"STR_EVENT_DAILY_TITLE_1"
	ev.title_key_2 = &"STR_EVENT_DAILY_TITLE_2"
	ev.sub_key_1 = &"STR_EVENT_DAILY_SUB_1"
	ev.sub_key_2 = &"STR_EVENT_DAILY_SUB_2"
	ev.unit_key = &"STR_EVENT_UNIT_CHALLENGES"
	ev.cta_key = &"STR_EVENT_DAILY_CTA"
	var r1 := EventReward.new()
	r1.kind = EventReward.Kind.COIN
	r1.amount = 120
	r1.label_key = &"STR_EVENT_DAILY_REWARD_1"
	var r2 := EventReward.new()
	r2.kind = EventReward.Kind.COIN_MULTIPLIER
	r2.amount = 7
	r2.label_key = &"STR_EVENT_DAILY_REWARD_2"
	ev.rewards = [r1, r2]
	# Nạp theme daily từ resources/events/themes/daily.tres nếu có
	var theme_path := EVENTS_DIR + "themes/daily.tres"
	if ResourceLoader.exists(theme_path):
		ev.theme = load(theme_path) as EventTheme
	if ev.theme == null:
		# Tạo theme mặc định cho daily nếu chưa có file
		ev.theme = _make_default_daily_theme()
	return ev



func _make_default_daily_theme() -> EventTheme:
	var t := EventTheme.new()
	t.id = &"daily"
	t.bg_stops = PackedColorArray([Color("#FFFDF8"), Color("#FFF3EE")])
	t.grid_overlay = &"dark"
	t.art_offset_y = -22.0
	t.accent = Color("#D84444")
	t.accent2 = Color("#F59E0B")
	t.title_color = Color("#163A58")
	t.title_outline = Color("#FFFDF8")
	t.sub_color = Color("#718B9E")
	t.label_color = Color("#163A58")
	t.panel_color = Color(0.996, 0.886, 0.886, 0.6)
	t.panel_stroke = Color(0.847, 0.267, 0.267, 0.25)
	t.cta_fill = Color("#D84444")
	t.cta_stroke = Color("#A12B2B")
	t.cta_text = Color("#FFFFFF")
	t.chip_fill = Color(0.847, 0.267, 0.267, 0.85)
	t.chip_text = Color("#FFFFFF")
	return t


# ---------------------------------------------------------------------------
# API CÔNG KHAI
# ---------------------------------------------------------------------------

## Trả event đang hoạt động, Daily đứng đầu, sắp xếp theo sort_order rồi hạn.
func get_active_events() -> Array[EventData]:
	var now := now_utc()
	var active: Array[EventData] = []
	for ev in _all_events:
		if ev.enabled and ev.is_active_now(now):
			active.append(ev)
	return _sort_events(active)


## Danh sách phục vụ xem thử EventData trên Main, không lọc enabled hoặc thời hạn.
## Không dùng API này cho luồng gameplay.
func get_all_events_for_preview() -> Array[EventData]:
	var events: Array[EventData] = []
	events.append_array(_all_events)
	return _sort_events(events)


func _sort_events(events: Array[EventData]) -> Array[EventData]:
	# Daily luôn đầu, còn lại theo sort_order rồi end_utc gần nhất.
	events.sort_custom(func(a: EventData, b: EventData) -> bool:
		if a.type == EventData.Type.DAILY:
			return true
		if b.type == EventData.Type.DAILY:
			return false
		if a.sort_order != b.sort_order:
			return a.sort_order < b.sort_order
		var ea := EventData._parse_utc(a.end_utc)
		var eb := EventData._parse_utc(b.end_utc)
		if ea == 0: ea = 0x7FFFFFFF
		if eb == 0: eb = 0x7FFFFFFF
		return ea < eb
	)
	return events


## Lấy EventData theo id (null nếu không có)
func get_event(id: StringName) -> EventData:
	for ev in _all_events:
		if ev.id == id:
			return ev
	return null


## Tiến độ của event: { done:int, total:int, unit_key:StringName, completed:bool, claimed:bool }
func get_progress(id: StringName) -> Dictionary:
	var ev := get_event(id)
	if ev == null:
		return {}
	var p := _ensure_progress(id)
	var done := 0
	match ev.type:
		EventData.Type.SPECIAL_SERIES, EventData.Type.STANDARD_SERIES:
			done = (p.get("done_levels", []) as Array).size()
		EventData.Type.DUNGEON:
			done = mini(int(p.get("best_floor", 0)), ev.dungeon_milestones.size())
		EventData.Type.LOGIN_STREAK:
			done = (p.get("login_days", []) as Array).size()
		EventData.Type.DAILY:
			# Daily dùng 3 nhiệm vụ maze thường (bit 0..2) — khớp thẻ "x/3 thử thách" (§B1)
			var dm := _get_daily_manager()
			if dm != null and dm.has_method("get_today") and dm.has_method("get_day_mission_mask"):
				var today: int = int(dm.call("get_today"))
				var mask: int = int(dm.call("get_day_mission_mask", today))
				for bit in range(3):
					if (mask & (1 << bit)) != 0:
						done += 1
	var total := ev.total_progress()
	return {
		"done": done,
		"total": total,
		"unit_key": ev.unit_key,
		"completed": done >= total,
		"claimed": bool(p.get("claimed", false)),
	}


## Số giây còn lại đến hết hạn
func seconds_left(id: StringName) -> int:
	var ev := get_event(id)
	if ev == null:
		return 0
	return ev.seconds_remaining(now_utc())


## Gọi khi hoàn thành 1 màn trong event series
func on_level_won(event_id: StringName, level: LevelData, _stars: int) -> void:
	var ev := get_event(event_id)
	if ev == null or ev.type not in [EventData.Type.SPECIAL_SERIES, EventData.Type.STANDARD_SERIES]:
		return
	var p := _ensure_progress(event_id)
	var done_list: Array = p.get("done_levels", [])
	var lid := str(level.level_id)
	if not done_list.has(lid):
		done_list.append(lid)
		p["done_levels"] = done_list
		_progress[event_id] = p
		event_progress_changed.emit(event_id)
		_queue_save()


## Gọi khi qua tầng Dungeon (floor_idx = index tầng, 1-based)
func on_dungeon_floor_cleared(floor_idx: int) -> void:
	var now := now_utc()
	for ev in _all_events:
		if ev.type != EventData.Type.DUNGEON:
			continue
		if not ev.is_active_now(now):
			continue
		var p := _ensure_progress(ev.id)
		var best: int = p.get("best_floor", 0)
		if floor_idx > best:
			p["best_floor"] = floor_idx
			_progress[ev.id] = p
			event_progress_changed.emit(ev.id)
			_queue_save()


## Gọi khi app mở trong ngày mới (đánh dấu ngày cho LOGIN_STREAK)
func on_app_day_started() -> void:
	var today := _today_str()
	if today == _last_login_day:
		return
	_last_login_day = today
	var now := now_utc()
	for ev in _all_events:
		if ev.type != EventData.Type.LOGIN_STREAK:
			continue
		if not ev.is_active_now(now):
			continue
		var p := _ensure_progress(ev.id)
		var days: Array = p.get("login_days", [])
		if not days.has(today):
			days.append(today)
			p["login_days"] = days
			_progress[ev.id] = p
			event_progress_changed.emit(ev.id)
			_queue_save()


## Kiểm tra có thể nhận quà không
func can_claim(id: StringName) -> bool:
	var prog := get_progress(id)
	if prog.is_empty():
		return false
	return bool(prog.get("completed", false)) and not bool(prog.get("claimed", false))


## Phát quà (idempotent — gọi 2 lần chỉ phát 1 lần)
func claim_reward(id: StringName) -> bool:
	if not can_claim(id):
		return false
	var ev := get_event(id)
	if ev == null:
		return false
	var p := _ensure_progress(id)
	p["claimed"] = true
	_progress[id] = p
	# Phát quà
	for reward in ev.rewards:
		_grant_reward(reward)
	event_progress_changed.emit(id)
	_queue_save()
	return true


# ---------------------------------------------------------------------------
# PHÁT QUÀ
# ---------------------------------------------------------------------------

func _grant_reward(reward: EventReward) -> void:
	if reward == null:
		return
	match reward.kind:
		EventReward.Kind.COIN:
			var sm := _get_shop_manager()
			if sm != null and sm.has_method("add_coins"):
				sm.call("add_coins", reward.amount, "event")
			elif sm != null and sm.has_method("add_ink_coin"):
				sm.call("add_ink_coin", reward.amount)
		EventReward.Kind.COIN_MULTIPLIER:
			# Hệ số nhân xu áp cho Dungeon event đang chạy (xem get_dungeon_coin_multiplier)
			pass
		EventReward.Kind.PEN_SKIN, EventReward.Kind.AVATAR_FRAME:
			# TODO: unlock item trong ShopManager/PlayerProfileManager
			push_warning("[EventManager] Item reward '%s' chưa implement" % str(reward.item_id))


# ---------------------------------------------------------------------------
# DUNGEON COIN MULTIPLIER (gọi từ GameManager/Dungeon HUD)
# ---------------------------------------------------------------------------

## Trả hệ số nhân xu cho Dungeon event đang chạy (1.0 nếu không có)
func get_dungeon_coin_multiplier() -> float:
	var now := now_utc()
	for ev in _all_events:
		if ev.type != EventData.Type.DUNGEON:
			continue
		if ev.is_active_now(now):
			return ev.dungeon_coin_multiplier
	return 1.0


# ---------------------------------------------------------------------------
# LƯU / LOAD (SaveManager provider)
# ---------------------------------------------------------------------------

func export_progress() -> Dictionary:
	_cleanup_stale()
	return _progress.duplicate(true)


func import_progress(data: Dictionary) -> void:
	if data.is_empty():
		return
	_progress = data.duplicate(true)


func reset_progress() -> void:
	_progress.clear()


# ---------------------------------------------------------------------------
# HELPERS NỘI BỘ
# ---------------------------------------------------------------------------

func _ensure_progress(id: StringName) -> Dictionary:
	if not _progress.has(id):
		_progress[id] = {}
	return _progress[id] as Dictionary


func _cleanup_stale() -> void:
	var now := now_utc()
	var stale_sec := STALE_DAYS * 86400
	var to_remove: Array[StringName] = []
	for id in _progress.keys():
		# Daily không xoá
		if id == &"daily":
			continue
		var ev := get_event(id as StringName)
		if ev == null:
			to_remove.append(id)
			continue
		var end := EventData._parse_utc(ev.end_utc)
		if end > 0 and (now - end) > stale_sec:
			to_remove.append(id)
	for id in to_remove:
		_progress.erase(id)


func _queue_save() -> void:
	var sm := get_node_or_null("/root/SaveManager")
	if sm != null and sm.has_method("queue_save"):
		sm.call("queue_save")


func _get_shop_manager() -> Node:
	return get_node_or_null("/root/ShopManager")


func _get_daily_manager() -> Node:
	return get_node_or_null("/root/DailyManager")


# ---------------------------------------------------------------------------
# DEBUG (F9 Debug Console — chỉ bản dev)
# ---------------------------------------------------------------------------

## Dịch chuyển thời gian giả về trước/sau (chỉ debug)
func debug_shift_time(delta_seconds: int) -> void:
	_debug_time_offset += delta_seconds
	events_changed.emit()


## Reset tiến độ của một event (debug)
func debug_reset_event(id: StringName) -> void:
	_progress.erase(id)
	event_progress_changed.emit(id)


## [DEBUG] Ép thời hạn của event quanh hiện tại (start_off/end_off = giây so với now_utc()).
## DAILY không đổi (luôn hoạt động). Dùng cho Debug Console (F9) "Bắt đầu/Kết thúc ngay".
func debug_set_window(id: StringName, start_off: int, end_off: int) -> void:
	var ev := get_event(id)
	if ev == null or ev.type == EventData.Type.DAILY:
		return
	var now := now_utc()
	ev.start_utc = Time.get_datetime_string_from_unix_time(now + start_off, false)
	ev.end_utc = Time.get_datetime_string_from_unix_time(now + end_off, false)
	events_changed.emit()


## [DEBUG] Đánh dấu xong MÀN KẾ TIẾP chưa xong của event series.
func debug_complete_next_level(id: StringName) -> void:
	var ev := get_event(id)
	if ev == null:
		return
	var done_list: Array = _ensure_progress(id).get("done_levels", [])
	for level in ev.levels:
		if not done_list.has(str(level.level_id)):
			on_level_won(id, level, 3)
			return


## Đặt tiến độ cụ thể (debug)
func debug_set_progress(id: StringName, done: int) -> void:
	var ev := get_event(id)
	if ev == null:
		return
	var p := _ensure_progress(id)
	match ev.type:
		EventData.Type.SPECIAL_SERIES, EventData.Type.STANDARD_SERIES:
			var list: Array = []
			for i in mini(done, ev.levels.size()):
				list.append(str(ev.levels[i].level_id))
			p["done_levels"] = list
		EventData.Type.DUNGEON:
			p["best_floor"] = done
		EventData.Type.LOGIN_STREAK:
			var days: Array = []
			for i in done:
				days.append("debug_day_%d" % i)
			p["login_days"] = days
	p["claimed"] = false
	_progress[id] = p
	event_progress_changed.emit(id)
