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
## Tiền tố node SLOT trong scene: `Rows/Slot1..SlotN` — mỗi hàng nhiệm vụ được ĐẶT VÀO đúng slot
## của nó, nên muốn đổi vị trí/kích thước hàng thì kéo slot trong editor (script không tính).
const SLOT_PREFIX := "Slot"

## ============================================================================
## BỐ CỤC = LAYOUT CỦA SCENE (`scenes/daily.tscn` + `nodes/daily/mission_row.tscn`),
## không hard-code số đo trong script. Các biến dưới được `_capture_design()` đọc 1 lần
## lúc mở màn; muốn đổi cỡ/khe thì sửa trực tiếp trong scene.
## ============================================================================
var _row_design_h := 110.0          # chiều cao thiết kế 1 hàng (mission_row.tscn) — chỉ dùng khi scene THIẾU slot
var _panel_design_h := 592.0        # chiều cao art bảng nhiệm vụ (dùng cho màn THẤP hơn thiết kế)
var _rows_top_design := 112.0       # đỉnh vùng hàng nhiệm vụ trong bảng (daily.tscn > Rows)
var _progress_design_y := 528.0     # đỉnh khối tiến độ trong bảng (daily.tscn > ProgressLabel)
var _gap_cal_missions := 24.0       # khe lịch → bảng (đo từ scene)
var _bottom_margin := 60.0          # lề dưới nút CHƠI (đo từ scene + canvas thiết kế)
var _design_captured := false

## Node UI của màn nằm trong BỐ CỤC đang hiển thị (`Portrait` / `Landscape` — 2 hướng dùng
## CÙNG tên node). Các node đã BIND SẴN bằng `@export` trong `scenes/layout/<hướng>/daily.tscn`
## ⇒ code đọc qua `layout.<tên>`, KHÔNG tra đường dẫn; thêm/đổi node chỉ cần sửa scene + export.
var layout: DailyLayout = null

var _rows: Array[DailyMissionRow] = []
var _daily: Node = null
## Ngày đang xem (mặc định hôm nay). Bấm ngày khác trên lịch = xem nhiệm vụ ngày đó.
var _selected_day := 1


func _ready() -> void:
	_daily = get_node_or_null("/root/DailyManager")
	_selected_day = _today()

	_bind_refs()
	_wire_buttons()
	orientation_changed.connect(_on_orientation_changed)

	if layout.streak_badge != null:
		UIAnim.play_pop_in(layout.streak_badge, 0.08, 0.8, 0.25)

	_build_rows()
	_refresh()
	_layout_responsive.call_deferred()
	var vp := get_viewport()
	if vp != null and not vp.size_changed.is_connected(_layout_responsive):
		vp.size_changed.connect(_layout_responsive)


## Gắn node của layout đang hiển thị (bản ngang đổi cấu trúc cột nên tra theo TÊN)
func _bind_refs() -> void:
	layout = active_layout() as DailyLayout
	if layout == null:
		push_warning("daily: bố cục chưa gắn DailyLayout — thiếu binding trong scenes/layout/<hướng>/daily.tscn")


## Nối signal + hiệu ứng (mỗi NODE chỉ nối 1 lần)
func _wire_buttons() -> void:
	if layout.btn_back != null and not layout.btn_back.has_meta("wired"):
		layout.btn_back.set_meta("wired", true)
		layout.btn_back.pressed.connect(_on_back_pressed)
		UIAnim.attach_press_bounce(layout.btn_back)
	if layout.btn_play != null and not layout.btn_play.has_meta("wired"):
		layout.btn_play.set_meta("wired", true)
		layout.btn_play.pressed.connect(_on_play_pressed)
		UIAnim.attach_press_bounce(layout.btn_play)
		UIAnim.play_pulse(layout.btn_play, 1.03, 1.8)
	if layout.calendar != null and not layout.calendar.has_meta("wired"):
		layout.calendar.set_meta("wired", true)
		layout.calendar.day_selected.connect(_on_day_selected)
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
##   · Bảng nhiệm vụ nằm GIỮA hai khối trên (không đè lịch)
## Màn CAO BẰNG/HƠN thiết kế: KHÔNG can thiệp — bố cục do SCENE quyết định (anchors + slot).
func _layout_responsive() -> void:
	if layout == null or not is_inside_tree() \
			or layout.calendar == null or layout.missions == null or layout.btn_play == null:
		return
	var canvas := get_viewport_rect().size
	if canvas.y <= 0.0:
		return
	_capture_design()

	# Màn thấp hơn thiết kế (tablet 3:4): lịch vẫn giữ nguyên chiều cao nên phải kéo bảng nhiệm vụ
	# xuống dưới lịch + ghim nút CHƠI vào đáy, nếu không bảng sẽ đè lên lịch.
	var design_h := float(ProjectSettings.get_setting("display/window/size/viewport_height", 1920))
	if canvas.y >= design_h - 0.5:
		return

	# 1. Nút CHƠI: bám đáy
	var play_y := canvas.y - _bottom_margin - layout.btn_play.size.y
	if absf(layout.btn_play.position.y - play_y) > 0.5:
		layout.btn_play.position.y = play_y

	# 2. Bảng nhiệm vụ: nằm giữa lịch và nút CHƠI
	var top := layout.calendar.position.y + layout.calendar.size.y + _gap_cal_missions
	var bottom := layout.btn_play.position.y - _gap_cal_missions
	var panel_h := maxf(_min_panel_height(), bottom - top)
	if absf(layout.missions.position.y - top) > 0.5:
		layout.missions.position.y = top
	if absf(layout.missions.size.y - panel_h) > 0.5:
		layout.missions.size.y = panel_h


## Chiều cao TỐI THIỂU của bảng nhiệm vụ = đáy slot CUỐI (scene khai) + khối tiến độ.
## Dùng cho màn thấp hơn thiết kế để bảng không đè lên lịch và hàng không tràn xuống khối tiến độ.
func _min_panel_height() -> float:
	var slot_bottom := 0.0
	for i in maxi(_mission_total(), 1):
		var slot := _slot_for(i)
		if slot != null:
			slot_bottom = maxf(slot_bottom, slot.position.y + slot.size.y)
	if slot_bottom <= 0.0:
		# Scene chưa khai slot ⇒ lấy theo chiều cao thiết kế của hàng
		slot_bottom = _row_design_h * float(maxi(_mission_total(), 1))
	var progress_block := maxf(_panel_design_h - _progress_design_y, 0.0)
	return _rows_top_design + slot_bottom + progress_block


## Slot thứ i của bảng nhiệm vụ — node `Slot{i+1}` do SCENE khai báo trong `Rows`
func _slot_for(index: int) -> Control:
	if layout.rows_host == null:
		return null
	return layout.rows_host.get_node_or_null("%s%d" % [SLOT_PREFIX, index + 1]) as Control


## Đọc số đo THIẾT KẾ từ scene + art (1 lần) — không hard-code trong script
func _capture_design() -> void:
	if _design_captured:
		return
	_design_captured = true
	var probe := MISSION_ROW.instantiate() as Control
	if probe != null:
		_row_design_h = maxf(probe.size.y, probe.custom_minimum_size.y)
		probe.free()
	if _row_design_h <= 0.0:
		_row_design_h = 110.0
	# Chiều cao THIẾT KẾ của bảng nhiệm vụ: lấy từ ART (không đổi theo layout) — nếu lấy `size.y` thì ở
	# bản NGANG (bảng bị kéo cao hơn art) khối tiến độ sẽ không tụt xuống đúng đáy bảng.
	var panel_art := layout.missions as TextureRect
	var art_h := float(panel_art.texture.get_height()) if panel_art != null and panel_art.texture != null else 0.0
	if art_h > 0.0:
		_panel_design_h = art_h
	elif layout.missions.size.y > 0.0:
		_panel_design_h = layout.missions.size.y
	if layout.rows_host != null:
		_rows_top_design = layout.rows_host.position.y
	if layout.lbl_progress != null:
		_progress_design_y = layout.lbl_progress.position.y
	var gap := layout.missions.position.y - (layout.calendar.position.y + layout.calendar.size.y)
	_gap_cal_missions = gap if gap > 0.0 else _gap_cal_missions
	var design_h := float(ProjectSettings.get_setting("display/window/size/viewport_height", 1920))
	var margin := design_h - (layout.btn_play.position.y + layout.btn_play.size.y)
	_bottom_margin = margin if margin > 0.0 else _bottom_margin


## Dựng 4 hàng nhiệm vụ (3 maze thường + 1 maze đặc biệt), mỗi hàng đặt vào SLOT của scene
func _build_rows() -> void:
	if layout.rows_host == null:
		return
	_clear_rows()
	for i in _mission_total():
		var row: DailyMissionRow = MISSION_ROW.instantiate()
		row.name = "Row%d" % (i + 1)
		# ĐẶT HÀNG VÀO SLOT: slot quyết định vị trí + kích thước (kéo slot trong editor là hàng theo ngay)
		var slot := _slot_for(i)
		var host: Control = slot if slot != null else layout.rows_host
		host.add_child(row)
		if slot != null:
			row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		else:
			# Dự phòng khi scene chưa khai slot: xếp dọc theo chiều cao thiết kế của hàng
			row.position = Vector2(0, _row_design_h * float(i))
		row.action_pressed.connect(_on_row_action_pressed)
		_rows.append(row)
		UIAnim.play_fade_in(row, 0.04 * i, 0.22)


## Xoá các hàng nhiệm vụ đã dựng (GIỮ LẠI node Slot của scene)
func _clear_rows() -> void:
	for row in _rows:
		if row != null and is_instance_valid(row):
			row.queue_free()
	_rows.clear()


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

	layout.lbl_streak.text = tr("STR_DAILY_STREAK_UNIT").format([_streak()])
	layout.lbl_mode.text = tr("STR_DAILY_SPECIAL_LABEL").format([mode_name])
	layout.lbl_date.text = tr("STR_DAILY_DATE_BADGE").format([
		day,
		DailyCalendar.days_in_month(_current_year(), _current_month()),
	])
	layout.lbl_reward.text = tr("STR_DAILY_REWARD_STARS").format([_day_reward_max()])

	# Nút CTA: ngày bỏ lỡ đang khoá -> hiện yêu cầu trả Xu để mở khoá
	var unlockable := _can_unlock_day(day)
	if unlockable:
		layout.lbl_play.text = tr("STR_DAILY_UNLOCK_COST").format([_unlock_cost()])
	else:
		layout.lbl_play.text = tr("STR_DAILY_PLAY_MODE").format([mode_name])
	if layout.icon_play != null:
		layout.icon_play.texture = ICON_UNLOCK if unlockable else ICON_PLAY
	if layout.btn_play != null:
		# Ngày tương lai (chưa mở) thì nút khoá hẳn; ngày bỏ lỡ vẫn bấm được để MỞ KHOÁ
		layout.btn_play.disabled = not _is_day_playable(day) and not unlockable

	_refresh_rows(day, mode_name)
	_refresh_footer(day, done, total)

	# Ô ngày trên lịch đổi viện trạng thái ("ĐÃ MỞ") sau khi trả Xu mở khoá
	if layout.calendar != null:
		layout.calendar.rebuild()


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
	layout.lbl_progress.text = tr("STR_DAILY_TOTAL_PROGRESS").format([percent, "%d/%d" % [done, total]])
	if layout.bar_progress != null:
		layout.bar_progress.value = percent
	if layout.lbl_claim != null:
		layout.lbl_claim.text = tr("STR_DAILY_CLAIMED_REWARD").format([
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
