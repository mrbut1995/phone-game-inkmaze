class_name DailyScene
extends BaseScene
## ============================================================================
## View Controller: Màn hình Daily Challenge (scenes/daily.tscn)
## - Lịch tháng (nodes/daily/calendar.tscn) để chọn ngày thử thách
## - Bảng nhiệm vụ ngày: 3 nhiệm vụ + tiến độ + thưởng sao
## - Huy hiệu chuỗi ngày (streak) và nút chơi chế độ xoay vòng của hôm nay
## ============================================================================

const UIAnim := preload("res://scripts/utils/ui_anim.gd")
const MISSION_ROW := preload("res://nodes/daily/mission_row.tscn")
## Icon của nút CTA: bút chì (chơi) / đồng Xu (trả Xu mở khoá ngày bỏ lỡ)
const ICON_PLAY := preload("res://assets/images/calendar/pencil_icon.svg")
const ICON_UNLOCK := preload("res://assets/images/shop/icon_coin.svg")
## 3 nhiệm vụ đầu thuộc MAZE THƯỜNG (Game Classic), nhiệm vụ thứ 4 thuộc MAZE ĐẶC BIỆT
const CLASSIC_MISSION_COUNT := 3
## Mức co tối đa của hàng nhiệm vụ khi màn thấp, và mức giãn tối đa khi màn cao
## (CỠ hàng vẫn lấy từ `nodes/daily/mission_row.tscn` — đây chỉ là chính sách co giãn)
const MIN_ROW_FACTOR := 0.7
const MAX_ROW_FACTOR := 1.35

## ============================================================================
## BỐ CỤC = LAYOUT CỦA SCENE (`scenes/daily.tscn` + `nodes/daily/mission_row.tscn`),
## không hard-code số đo trong script. Các biến dưới được `_capture_design()` đọc 1 lần
## lúc mở màn; muốn đổi cỡ/khe thì sửa trực tiếp trong scene.
## ============================================================================
var _row_design_h := 110.0          # chiều cao 1 hàng nhiệm vụ (mission_row.tscn)
var _panel_design_h := 592.0        # chiều cao bảng nhiệm vụ (daily.tscn > Missions)
var _rows_top_design := 112.0       # đầu hàng nhiệm vụ trong bảng (daily.tscn > Rows)
var _progress_design_y := 528.0     # đỉnh hàng tiến độ (daily.tscn > ProgressLabel)
var _gap_cal_missions := 24.0       # khe lịch → bảng (đo từ scene)
var _bottom_margin := 60.0          # lề dưới nút CHƠI (đo từ scene + canvas thiết kế)
var _min_panel_h := 484.0           # bảng tối thiểu = đầu hàng + 4 hàng co + khối tiến độ
var _design_captured := false

## Node UI gắn lại mỗi lần ĐỔI HƯỚNG (2 layout dùng CÙNG tên node)
var btn_back: BaseButton = null
var calendar: DailyCalendar = null
var missions: Control = null
var lbl_streak: Label = null
var lbl_date: Label = null
var lbl_mode: Label = null
var lbl_reward: Label = null
var rows_host: Control = null
var lbl_progress: Label = null
var bar_progress: TextureProgressBar = null
var lbl_claim: Label = null
var btn_play: BaseButton = null
var lbl_play: Label = null
var icon_play: TextureRect = null

var _rows: Array[DailyMissionRow] = []
var _daily: Node = null
## Vị trí THIẾT KẾ của hàng tiến độ (node -> y) — tránh cộng dồn khi relayout nhiều lần
var _progress_base: Dictionary = {}
## Ngày đang xem (mặc định hôm nay). Bấm ngày khác trên lịch = xem nhiệm vụ ngày đó.
var _selected_day := 1


func _ready() -> void:
	_daily = get_node_or_null("/root/DailyManager")
	_selected_day = _today()

	_bind_refs()
	_wire_buttons()
	orientation_changed.connect(_on_orientation_changed)

	var streak_badge := ui("StreakBadge") as Control
	if streak_badge != null:
		UIAnim.play_pop_in(streak_badge, 0.08, 0.8, 0.25)

	_build_rows()
	_refresh()
	_layout_responsive.call_deferred()
	var vp := get_viewport()
	if vp != null and not vp.size_changed.is_connected(_layout_responsive):
		vp.size_changed.connect(_layout_responsive)


## Gắn node của layout đang hiển thị (bản ngang đổi cấu trúc cột nên tra theo TÊN)
func _bind_refs() -> void:
	btn_back = ui_path("TopBar/Back") as BaseButton
	calendar = ui("Calendar") as DailyCalendar
	missions = ui("Missions") as Control
	lbl_streak = ui_child("StreakBadge", "Streak") as Label
	lbl_date = ui_child("DateTag", "Label") as Label
	lbl_mode = ui("Mode") as Label
	lbl_reward = ui_child("Reward", "Label") as Label
	rows_host = ui("Rows") as Control
	lbl_progress = ui("ProgressLabel") as Label
	bar_progress = ui("ProgressBar") as TextureProgressBar
	lbl_claim = ui("Claim") as Label
	btn_play = ui("Play") as BaseButton
	lbl_play = ui_child("Play", "Label") as Label
	icon_play = ui_child("Play", "Icon") as TextureRect


## Nối signal + hiệu ứng (mỗi NODE chỉ nối 1 lần)
func _wire_buttons() -> void:
	if btn_back != null and not btn_back.has_meta("wired"):
		btn_back.set_meta("wired", true)
		btn_back.pressed.connect(_on_back_pressed)
		UIAnim.attach_press_bounce(btn_back)
	if btn_play != null and not btn_play.has_meta("wired"):
		btn_play.set_meta("wired", true)
		btn_play.pressed.connect(_on_play_pressed)
		UIAnim.attach_press_bounce(btn_play)
		UIAnim.play_pulse(btn_play, 1.03, 1.8)
	if calendar != null and not calendar.has_meta("wired"):
		calendar.set_meta("wired", true)
		calendar.day_selected.connect(_on_day_selected)
	if _daily != null and _daily.has_signal("daily_changed") \
			and not _daily.is_connected("daily_changed", _refresh):
		_daily.connect("daily_changed", _refresh)


## Xoay màn hình: số đo "thiết kế" đổi theo layout ⇒ đo lại rồi dàn lại hàng + nạp lại dữ liệu
func _on_orientation_changed(_is_landscape_now: bool) -> void:
	_rebind_after_orientation.call_deferred()


func _rebind_after_orientation() -> void:
	_bind_refs()
	_wire_buttons()
	_design_captured = false
	_progress_base.clear()
	_capture_design()
	_build_rows()
	_refresh()
	_layout_responsive()


func _notification(what: int) -> void:
	super._notification(what)
	if what == NOTIFICATION_READY or what == NOTIFICATION_RESIZED:
		_layout_responsive()


## Bố cục theo chiều cao màn hình (màn 9:19.5/9:20 cao hơn thiết kế 1920):
##   · Lịch giữ đúng chiều cao thiết kế
##   · Nút CHƠI bám đáy màn hình
##   · Bảng nhiệm vụ nằm GIỮA hai khối trên (không đè lịch), hàng tiến độ dồn xuống đáy bảng
func _layout_responsive() -> void:
	if not is_inside_tree() or calendar == null or missions == null or btn_play == null:
		return
	var canvas := get_viewport_rect().size
	if canvas.y <= 0.0:
		return
	_capture_design()

	if is_landscape:
		# Bố cục NGANG: lịch + bảng nhiệm vụ + nút CHƠI do ANCHORS dàn sẵn — chỉ dàn hàng bên trong bảng
		_layout_rows_in_panel()
		return

	# 1. Nút CHƠI: bám đáy
	var play_y := canvas.y - _bottom_margin - btn_play.size.y
	if absf(btn_play.position.y - play_y) > 0.5:
		btn_play.position.y = play_y

	# 2. Bảng nhiệm vụ: nằm giữa lịch và nút CHƠI
	var top := calendar.position.y + calendar.size.y + _gap_cal_missions
	var bottom := btn_play.position.y - _gap_cal_missions
	var panel_h := maxf(_min_panel_h, bottom - top)
	if absf(missions.position.y - top) > 0.5:
		missions.position.y = top
	if absf(missions.size.y - panel_h) > 0.5:
		missions.size.y = panel_h

	_layout_rows_in_panel()


## Dàn 4 hàng nhiệm vụ + khối tiến độ bên trong BẢNG (dùng chung cho cả 2 hướng)
##   · khối tiến độ dồn xuống ĐÁY bảng
##   · hàng co/giãn vừa khoảng trống còn lại (màn thấp/ngang -> co lại để không tràn)
func _layout_rows_in_panel() -> void:
	if missions == null:
		return
	var dy := missions.size.y - _panel_design_h
	if absf(dy) > 0.5:
		for node in _progress_base.keys():
			var c := node as Control
			if c != null and is_instance_valid(c):
				c.position.y = float(_progress_base[node]) + dy

	if rows_host == null:
		return
	var count := maxi(_mission_total(), 1)
	var top_limit := _rows_top_design
	var bottom_limit := _progress_design_y + dy
	var space := maxf(bottom_limit - top_limit, _row_design_h * MIN_ROW_FACTOR)
	# Màn cao -> giãn nhẹ khoảng cách hàng (tối đa MAX_ROW_FACTOR× thiết kế) để lấp khoảng trống;
	# màn thấp/ngang -> co hàng lại để không tràn xuống nút CHƠI.
	var row_h := clampf(space / float(count), 0.0, _row_design_h * MAX_ROW_FACTOR)
	if row_h <= 0.0:
		row_h = _row_design_h
	for i in _rows.size():
		var row := _rows[i]
		if row != null and is_instance_valid(row):
			row.position = Vector2(0, row_h * i)
	rows_host.position.y = top_limit + maxf(0.0, (space - row_h * float(count)) * 0.5)


## Đọc số đo THIẾT KẾ từ scene + art (1 lần) — không hard-code trong script
func _capture_design() -> void:
	if _design_captured:
		return
	_design_captured = true
	# Vị trí THIẾT KẾ của hàng tiến độ (node -> y) — chốt TRƯỚC khi relayout lần đầu
	# để dồn xuống đáy bảng mà không cộng dồn theo số lần relayout.
	for node in [lbl_progress, bar_progress, lbl_claim]:
		if node != null:
			_progress_base[node] = (node as Control).position.y
	var probe := MISSION_ROW.instantiate() as Control
	if probe != null:
		_row_design_h = maxf(probe.size.y, probe.custom_minimum_size.y)
		probe.free()
	if _row_design_h <= 0.0:
		_row_design_h = 110.0
	# Chiều cao THIẾT KẾ của bảng nhiệm vụ: lấy từ ART (không đổi theo layout) — nếu lấy `size.y` thì ở
	# bản NGANG (bảng bị kéo cao hơn art) khối tiến độ sẽ không tụt xuống đúng đáy bảng.
	var panel_art := missions as TextureRect
	var art_h := float(panel_art.texture.get_height()) if panel_art != null and panel_art.texture != null else 0.0
	if art_h > 0.0:
		_panel_design_h = art_h
	elif missions.size.y > 0.0:
		_panel_design_h = missions.size.y
	if rows_host != null:
		_rows_top_design = rows_host.position.y
	if lbl_progress != null:
		_progress_design_y = lbl_progress.position.y
	var gap := missions.position.y - (calendar.position.y + calendar.size.y)
	_gap_cal_missions = gap if gap > 0.0 else _gap_cal_missions
	var design_h := float(ProjectSettings.get_setting("display/window/size/viewport_height", 1920))
	var margin := design_h - (btn_play.position.y + btn_play.size.y)
	_bottom_margin = margin if margin > 0.0 else _bottom_margin
	var progress_block := maxf(_panel_design_h - _progress_design_y, 0.0)
	_min_panel_h = (_rows_top_design
		+ _row_design_h * MIN_ROW_FACTOR * float(maxi(_mission_total(), 1))
		+ progress_block)


## Dựng 4 hàng nhiệm vụ (3 maze thường + 1 maze đặc biệt) trong bảng Mission
func _build_rows() -> void:
	if rows_host == null:
		return
	for child in rows_host.get_children():
		child.queue_free()
	_rows.clear()
	for i in _mission_total():
		var row: DailyMissionRow = MISSION_ROW.instantiate()
		row.name = "Row%d" % (i + 1)
		# Cỡ hàng lấy từ scene (`mission_row.tscn`) — `_layout_responsive()` sẽ dàn lại sau
		row.position = Vector2(0, _row_design_h * i)
		rows_host.add_child(row)
		row.action_pressed.connect(_on_row_action_pressed)
		_rows.append(row)
		UIAnim.play_fade_in(row, 0.04 * i, 0.22)


# --- API cho test -----------------------------------------------------------

## Ngày đang xem trên lịch
func selected_day() -> int:
	return _selected_day


## Đổi ngày đang xem (không nhảy vào màn chơi)
func select_day(day: int) -> void:
	if day <= 0:
		return
	_selected_day = day
	_refresh()


## Số hàng nhiệm vụ đang hiển thị
func row_count() -> int:
	return _rows.size()


func row_at(index: int) -> DailyMissionRow:
	if index < 0 or index >= _rows.size():
		return null
	return _rows[index]


# ---------------------------------------------------------------------------
# Dữ liệu
# ---------------------------------------------------------------------------
## Cập nhật toàn bộ nội dung theo ngày đang chọn
func _refresh() -> void:
	if _daily == null:
		return
	var day := _selected_day
	var mode_name := _mode_name(day)
	var done := _missions_done(day)
	var total := _mission_total()

	lbl_streak.text = tr("STR_DAILY_STREAK_UNIT").format([_streak()])
	lbl_mode.text = tr("STR_DAILY_SPECIAL_LABEL").format([mode_name])
	lbl_date.text = tr("STR_DAILY_DATE_BADGE").format([
		day,
		DailyCalendar.days_in_month(_current_year(), _current_month()),
	])
	lbl_reward.text = tr("STR_DAILY_REWARD_STARS").format([_day_reward_max()])

	# Nút CTA: ngày bỏ lỡ đang khoá -> hiện yêu cầu trả Xu để mở khoá
	var unlockable := _can_unlock_day(day)
	if unlockable:
		lbl_play.text = tr("STR_DAILY_UNLOCK_COST").format([_unlock_cost()])
	else:
		lbl_play.text = tr("STR_DAILY_PLAY_MODE").format([mode_name])
	if icon_play != null:
		icon_play.texture = ICON_UNLOCK if unlockable else ICON_PLAY
	if btn_play != null:
		# Ngày tương lai (chưa mở) thì nút khoá hẳn; ngày bỏ lỡ vẫn bấm được để MỞ KHOÁ
		btn_play.disabled = not _is_day_playable(day) and not unlockable

	_refresh_rows(day, mode_name)
	_refresh_footer(day, done, total)

	# Ô ngày trên lịch đổi viện trạng thái ("ĐÃ MỞ") sau khi trả Xu mở khoá
	if calendar != null:
		calendar.rebuild()


## 4 hàng nhiệm vụ: 3 nhiệm vụ maze thường (0..2) + 1 nhiệm vụ maze đặc biệt (3)
func _refresh_rows(day: int, mode_name: String) -> void:
	var playable := _is_day_playable(day)
	for i in _rows.size():
		var done := false
		if _daily.has_method("is_mission_done"):
			done = bool(_daily.call("is_mission_done", day, i))
		_rows[i].setup(i, {
			"title": _mission_title(i, mode_name),
			"desc": _mission_desc(i),
			"progress": tr("STR_DAILY_MISSION_PROGRESS_DONE" if done else "STR_DAILY_MISSION_PROGRESS_TODO"),
			"reward": _mission_reward(i),
			"done": done,
			"special": i >= CLASSIC_MISSION_COUNT,
			"playable": playable,
		})


func _mission_title(index: int, mode_name: String) -> String:
	match index:
		0:
			return tr("STR_DAILY_MISSION_NO_WALL_TITLE")
		1:
			return tr("STR_DAILY_MISSION_STEPS_TITLE").format([_classic_steps()])
		2:
			return tr("STR_DAILY_MISSION_TIME_TITLE").format([_classic_time()])
		_:
			return tr("STR_DAILY_MISSION_SPECIAL_TITLE").format([mode_name])


func _mission_desc(index: int) -> String:
	match index:
		0:
			return tr("STR_DAILY_MISSION_NO_WALL_DESC")
		1:
			return tr("STR_DAILY_MISSION_STEPS_DESC")
		2:
			return tr("STR_DAILY_MISSION_TIME_DESC")
		_:
			return tr("STR_DAILY_MISSION_SPECIAL_DESC")


## Thanh tiến độ ngày (x/4 nhiệm vụ) + Xu đã nhận trong ngày
func _refresh_footer(day: int, done: int, total: int) -> void:
	var percent := int(round(100.0 * float(done) / float(maxi(total, 1))))
	lbl_progress.text = tr("STR_DAILY_TOTAL_PROGRESS").format([percent, "%d/%d" % [done, total]])
	if bar_progress != null:
		bar_progress.value = percent
	if lbl_claim != null:
		lbl_claim.text = tr("STR_DAILY_CLAIMED_REWARD").format([
			_day_coins_earned(day),
			_day_reward_max(),
		])


# --- Tiện ích đọc dữ liệu DailyManager --------------------------------------

func _today() -> int:
	return int(_daily.call("get_today")) if _daily != null else 1


func _mission_total() -> int:
	if _daily != null and _daily.has_method("mission_count"):
		return int(_daily.call("mission_count"))
	return CLASSIC_MISSION_COUNT + 1


func _missions_done(day: int) -> int:
	if _daily != null and _daily.has_method("get_day_missions"):
		return int(_daily.call("get_day_missions", day))
	return 0


func _mission_reward(index: int) -> int:
	if _daily != null and _daily.has_method("mission_reward"):
		return int(_daily.call("mission_reward", index))
	return 0


func _day_reward_max() -> int:
	if _daily != null and _daily.has_method("day_reward_max"):
		return int(_daily.call("day_reward_max"))
	return 0


func _day_coins_earned(day: int) -> int:
	if _daily != null and _daily.has_method("day_coins_earned"):
		return int(_daily.call("day_coins_earned", day))
	return 0


## Ngày chơi được: hôm nay, ngày đã có tiến độ, hoặc ngày bỏ lỡ đã trả Xu mở khoá.
## Ngày khác chỉ để XEM nhiệm vụ.
func _is_day_playable(day: int) -> bool:
	return day == _today() or _missions_done(day) > 0 or _is_day_unlocked(day)


## Ngày đã được trả Xu mở khoá
func _is_day_unlocked(day: int) -> bool:
	if _daily != null and _daily.has_method("is_day_unlocked"):
		return bool(_daily.call("is_day_unlocked", day))
	return false


## Ngày bỏ lỡ có thể trả Xu mở khoá (ngày đã qua, chưa chơi gì, chưa mở khoá)
func _can_unlock_day(day: int) -> bool:
	if _daily != null and _daily.has_method("can_unlock_day"):
		return bool(_daily.call("can_unlock_day", day))
	return false


## Giá mở khoá một ngày bỏ lỡ (Xu)
func _unlock_cost() -> int:
	if _daily != null and _daily.has_method("unlock_cost"):
		return int(_daily.call("unlock_cost"))
	return 0


func _streak() -> int:
	return int(_daily.call("get_streak")) if _daily != null else 0


func _mode_name(day: int) -> String:
	if _daily == null:
		return ""
	var mode_id := str(_daily.call("get_mode_for_day", day))
	return tr("STR_MODE_%s" % mode_id.to_upper())


## Số bước / giới hạn thời gian của maze thường trong ngày (khớp DailyClassicGameMode)
func _classic_steps() -> int:
	return DailyClassicGameMode.DESIGN_STEPS


func _classic_time() -> int:
	return DailyClassicGameMode.TIME_LIMIT_SEC


func _current_year() -> int:
	return int(Time.get_date_dict_from_system().get("year", 2026))


func _current_month() -> int:
	return int(Time.get_date_dict_from_system().get("month", 1))


# --- Sự kiện ----------------------------------------------------------------

## Bấm 1 ngày trên lịch: CHỈ đổi ngày đang xem (không nhảy thẳng vào màn chơi)
func _on_day_selected(day: int) -> void:
	select_day(day)


## Nút CTA dưới cùng: chơi MAZE ĐẶC BIỆT của ngày đang chọn
## (ngày bỏ lỡ đang khoá -> nút đổi thành trả Xu MỞ KHOÁ)
func _on_play_pressed() -> void:
	if _can_unlock_day(_selected_day):
		_unlock_selected_day()
		return
	_play_special()


## Ngày đang xem bị BỎ LỠ: trả Xu để mở khoá, sau đó ngày chơi được như bình thường
func _unlock_selected_day() -> void:
	if _daily == null or not _daily.has_method("unlock_day"):
		return
	if bool(_daily.call("unlock_day", _selected_day)):
		# "Cộp" con dấu khi mở khoá thành công
		Sfx.play(Sfx.STAMP_IMPACT)
		return
	# Ví không đủ Xu: gãy ngòi chì báo không mở được
	Sfx.play(Sfx.WALL_HIT)


## Nút trên hàng nhiệm vụ: 3 hàng đầu -> MAZE THƯỜNG, hàng 4 -> MAZE ĐẶC BIỆT
func _on_row_action_pressed(index: int) -> void:
	if index < CLASSIC_MISSION_COUNT:
		_play_classic()
	else:
		_play_special()


func _play_classic() -> void:
	if not _is_day_playable(_selected_day):
		return
	Sfx.play(Sfx.BTN_CLICK)
	_start_daily(_selected_day, true)


func _play_special() -> void:
	if not _is_day_playable(_selected_day):
		return
	Sfx.play(Sfx.BTN_CLICK)
	_start_daily(_selected_day, false)


## `classic = true` -> Game Classic (maze thường), false -> maze đặc biệt của ngày
func _start_daily(day: int, classic: bool) -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm == null:
		Nav.goto_game()
		return
	if classic and gm.has_method("start_daily_classic"):
		gm.call("start_daily_classic", day)
	elif gm.has_method("start_daily"):
		gm.call("start_daily", day)
	else:
		Nav.goto_game()


func _on_back_pressed() -> void:
	# SFX: gõ thẻ giấy cho nút phụ (Back)
	Sfx.play(Sfx.BTN_WOOD_TAP)
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm != null:
		gm.go_to_main_menu()
	else:
		Nav.goto_main()
