class_name WinningDailyPopup
extends BasePopup
## ============================================================================
## Popup: Kết quả ván DAILY (nodes/popups/winning_daily.tscn)
## Bố cục:
##   1. Dải TUẦN (T2..CN) quanh ngày vừa chơi: ngày hoàn thành có dấu ✔, ngày vừa chơi được khoanh
##   2. 3 sao lớn = sao của VÁN NÀY (sao đạt nảy lên lần lượt)
##   3. Thẻ SAO THÁNG: thanh tiến độ tới RƯƠNG kế tiếp + "Còn n★ tới rương"
##   4. Thẻ HÔM NAY: sao của ngày x/6 + 6 sao nhỏ
##   5. Thẻ 3 cột: Thời gian · Bước · Đâm tường
##   6. Nút: Chơi lại · Về Daily
##
## Hiệu ứng mở (cùng bộ với winning.tscn): băng keo rơi → dải tuần hiện + ô ngày vừa chơi nảy →
##   HÀO QUANG sau 3 sao lớn (to/nhiều tia theo số sao) + sao nảy + vòng sóng + lấp lánh + PHÁO HOA rải khắp popup
##   (1★ nhẹ · 2★ vừa · 3★ rực rỡ) → thẻ Sao tháng (thanh chạy; chạm mốc → RƯƠNG mở: rung + pháo vàng) →
##   thẻ Hôm nay (sao nhỏ nảy) → thống kê đếm số → nút. Tween huỷ khi đóng popup.
##
## Khác popup thắng thường (winning.tscn): KHÔNG có "MÀN KẾ TIẾP" — nút chính là "VỀ DAILY".
## Dữ liệu GameController truyền qua open({...}):
##   daily_day, daily_variant, daily_mode_id, daily_mode_name,
##   daily_stars (sao ván này), daily_stars_gained (sao thực sự tăng),
##   daily_day_stars, daily_stars_max, daily_month_stars, daily_month_goal,
##   time, steps_used, steps_max, wall_hits
## Mốc rương + ngày đã hoàn thành đọc thẳng từ DailyManager.
## ============================================================================

signal replay_requested
signal daily_requested

const COUNT := 3
const STAR_DELAY := 0.45
const STAR_STEP := 0.24
const COUNT_TIME := 0.7
const HALO_ALPHA := 0.65
## Màu hào quang vàng ấm (nhân với màu ảnh fx_glow_*.png) — chỉnh tại đây
const GLOW_COLOR := Color(1.0, 0.84, 0.45, 1.0)  # keep-code: màu/art hiệu ứng runtime — không thuộc theme tĩnh
const RING_COLOR := Color(1.0, 0.8, 0.25, 1.0)  # keep-code: màu/art hiệu ứng runtime — không thuộc theme tĩnh
const SPARK_PX := 18.0
const CONFETTI_PX := 12.0
const FW_PX := 22.0
## Vị trí nổ pháo (toạ độ trong Panel 478×562)
const FW_POS: Array[Vector2] = [
	Vector2(239, 190), Vector2(105, 140), Vector2(375, 140), Vector2(62, 290),
	Vector2(416, 290), Vector2(239, 105), Vector2(150, 250), Vector2(330, 250)]
const FW_COLORS: Array[Color] = [
	Color(1.0, 0.82, 0.25), Color(1.0, 0.45, 0.7), Color(0.35, 0.85, 1.0),
	Color(0.55, 0.95, 0.4), Color(1.0, 0.55, 0.2)]
## Kịch bản ăn mừng: [vị trí, trễ(s), màu, số tia, lực nổ]
const PLAN_1: Array = [[1, 0.0, 0, 18, 0.7], [2, 0.25, 4, 18, 0.7]]
const PLAN_2: Array = [[1, 0.0, 0, 26, 0.9], [2, 0.2, 1, 26, 0.9], [0, 0.45, 2, 30, 1.0], [5, 0.7, 3, 26, 0.9]]
const PLAN_3: Array = [
	[0, 0.0, 0, 44, 1.15], [1, 0.2, 1, 36, 1.0], [2, 0.35, 2, 36, 1.0], [3, 0.6, 3, 32, 1.0],
	[4, 0.7, 4, 32, 1.0], [5, 0.95, 0, 40, 1.1], [6, 1.15, 1, 32, 1.0], [7, 1.3, 2, 32, 1.0],
	[0, 1.7, 0, 64, 1.45]]
const CONFETTI_BY_STARS: Array[int] = [0, 0, 24, 80]
const DAY_SECONDS := 86400
const WEEKDAY_KEYS: Array[String] = [
	"STR_DW_WD_MON", "STR_DW_WD_TUE", "STR_DW_WD_WED", "STR_DW_WD_THU",
	"STR_DW_WD_FRI", "STR_DW_WD_SAT", "STR_DW_WD_SUN",
]
const COLOR_DAY := Color(0.086, 0.275, 0.388, 1)  # keep-code: màu/art hiệu ứng runtime — không thuộc theme tĩnh
const COLOR_DAY_ON := Color(0.631, 0.373, 0.106, 1)  # keep-code: màu/art hiệu ứng runtime — không thuộc theme tĩnh
const COLOR_DAY_OFF := Color(0.722, 0.769, 0.8, 1)  # keep-code: màu/art hiệu ứng runtime — không thuộc theme tĩnh

## Art sao + kiểu ô ngày — gán trong `winning_daily.tscn`
@export var star_full: Texture2D = null
@export var star_empty: Texture2D = null
@export var style_cell_on: StyleBox = null
@export var style_cell_off: StyleBox = null

## Node binding: khai `node_paths` + `NodePath` trong `winning_daily.tscn`
@export var label_title: Label = null
@export var days_row: HBoxContainer = null
@export var hero1: TextureRect = null
@export var hero2: TextureRect = null
@export var hero3: TextureRect = null
@export var month_remain: Label = null
@export var month_bar: ProgressBar = null
@export var day_value: Label = null
@export var day_stars_row: HBoxContainer = null
@export var value_time: Label = null
@export var value_steps: Label = null
@export var value_walls: Label = null
@export var label_daily: Label = null
## Node hiệu ứng — khai `node_paths` trong .tscn
@export var fx_tape: Control = null
@export var fx_week: Control = null
@export var fx_month: Control = null
@export var fx_day: Control = null
@export var fx_stats: Control = null
@export var fx_buttons: Control = null
@export var chest: TextureRect = null
@export var fx_rays: Control = null
@export var fx_rays2: Control = null
@export var fx_rays3: Control = null
@export var fx_soft: Control = null
@export var fx_confetti: CPUParticles2D = null
@export var fx_fireworks: Control = null

var _tweens: Array[Tween] = []
var _tape_rest := Vector2.ZERO
var _tape_rot := 0.0
var _tape_saved := false
var _steps_max := 0
var _earned := 0
var _halo_k := 1.0
var _halo_layers: Array[Control] = []
var _bar_from := -1.0
var _bar_to := -1.0
var _chest_reached := false
var _sel_cell: Control = null


func _on_open() -> void:
	if data.is_empty():
		return
	_kill_tweens()
	_hide_for_intro()
	var day := maxi(int(data.get("daily_day", 1)), 1)
	label_title.text = tr("STR_DW_TITLE").format([day])

	var earned := clampi(int(data.get("daily_stars", 0)), 0, COUNT)
	_earned = earned
	_reset_fx()
	_fill_week(day)
	_set_stars(earned)
	_fill_month()
	_fill_day()

	var seconds := maxi(int(round(float(data.get("time", 0.0)))), 0)
	var used := int(data.get("steps_used", 0))
	var maxs := int(data.get("steps_max", 0))
	var walls := int(data.get("wall_hits", 0))
	value_time.text = "%02d:%02d" % [seconds / 60, seconds % 60]
	value_steps.text = "%d/%d" % [used, maxs]
	value_walls.text = str(walls)

	# Gán chữ nút bằng code (test đọc được chuỗi đã dịch)
	label_daily.text = TranslationServer.translate("STR_BTN_BACK_DAILY")

	_play_intro(earned, seconds, used, maxs, walls)


func _on_close() -> void:
	_kill_tweens()


# ---------------------------------------------------------------------------
# 1. Dải tuần (thứ Hai -> Chủ nhật) chứa ngày vừa chơi
# ---------------------------------------------------------------------------
func _fill_week(day: int) -> void:
	_sel_cell = null
	var now := Time.get_date_dict_from_system()
	var month := int(now.get("month", 1))
	var noon := Time.get_unix_time_from_datetime_dict({
		"year": int(now.get("year", 2026)), "month": month, "day": day,
		"hour": 12, "minute": 0, "second": 0,
	})
	var weekday := int(Time.get_date_dict_from_unix_time(noon).get("weekday", 1))
	var monday_index := (weekday + 6) % 7	# 0 = T2 ... 6 = CN
	var start := noon - monday_index * DAY_SECONDS
	var today := int(DailyManager.get_today())
	var cells := days_row.get_children()
	for i in mini(cells.size(), 7):
		var cell := cells[i] as PanelContainer
		var d := Time.get_date_dict_from_unix_time(start + i * DAY_SECONDS)
		var in_month := int(d.get("month", 0)) == month
		var number := int(d.get("day", 1))
		var selected := in_month and number == day
		var done := in_month and DailyManager.is_completed(number)
		var reachable := in_month and number <= today
		var box := cell.get_child(0)
		(box.get_child(0) as Label).text = tr(WEEKDAY_KEYS[i])
		var num_label := box.get_child(1) as Label
		num_label.text = str(number)
		num_label.add_theme_color_override(&"font_color",
			COLOR_DAY_ON if selected else (COLOR_DAY if reachable else COLOR_DAY_OFF))
		(box.get_child(2) as Label).text = "✔" if done else ""
		cell.add_theme_stylebox_override(&"panel", style_cell_on if selected else style_cell_off)
		if selected:
			_sel_cell = cell


# ---------------------------------------------------------------------------
# 2. Sao lớn của VÁN NÀY
# ---------------------------------------------------------------------------
func _set_stars(earned_stars: int) -> void:
	var earned := clampi(earned_stars, 0, COUNT)
	var heroes: Array[TextureRect] = [hero1, hero2, hero3]
	for i in COUNT:
		var h := heroes[i]
		var on := i < earned
		h.texture = star_full if on else star_empty
		h.modulate = Color(1, 1, 1, 1) if on else Color(1, 1, 1, 0.75)
		h.pivot_offset = h.size * 0.5
		h.rotation = 0.0  # keep-code: pose hoạt cảnh runtime (tween)
		if on:
			h.scale = Vector2.ONE * 0.3  # keep-code: pose hoạt cảnh runtime (tween)
			h.rotation_degrees = -30.0  # keep-code: pose hoạt cảnh runtime (tween)
			h.modulate.a = 0.0
			_pop_star(h, i, i == earned - 1 and earned == COUNT)
		else:
			h.scale = Vector2.ONE * 0.85  # keep-code: pose hoạt cảnh runtime (tween)
			h.modulate.a = 0.0
			var tw := _track(create_tween())
			tw.tween_interval(STAR_DELAY)
			tw.tween_property(h, "modulate:a", 0.75, 0.25)
			tw.parallel().tween_property(h, "scale", Vector2.ONE, 0.25) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _pop_star(star: TextureRect, index: int, is_last_of_three: bool) -> void:
	var tw := _track(create_tween())
	tw.tween_interval(STAR_DELAY + STAR_STEP * float(index))
	tw.tween_callback(func() -> void:
		star.modulate.a = 1.0
		_star_pop(index)
		_ring(star)
		_burst(star, 16 if is_last_of_three else 9)
		if index == 0:
			_start_halo()
		if index == _earned - 1:
			_celebrate())
	tw.tween_property(star, "scale", Vector2(1.25, 1.25), 0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(star, "rotation_degrees", 0.0, 0.3) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(star, "scale", Vector2.ONE, 0.14)
	if is_last_of_three:
		tw.tween_callback(_start_idle)



# ---------------------------------------------------------------------------
# 3. Sao tháng -> rương kế tiếp
# ---------------------------------------------------------------------------
func _fill_month() -> void:
	var month_stars := int(data.get("daily_month_stars", 0))
	var gained := maxi(int(data.get("daily_stars_gained", 0)), 0)
	var prev := maxi(month_stars - gained, 0)
	_bar_from = -1.0
	_bar_to = -1.0
	_chest_reached = false
	var target := 0
	for def in DailyManager.milestone_defs():
		var need := int((def as Dictionary).get("stars", 0))
		if need > prev and need <= month_stars:
			_chest_reached = true	# ván này vừa chạm mốc rương
		if target <= 0 and need > month_stars:
			target = need
	if target <= 0:
		# Đã vượt mọi mốc -> thanh đầy, báo đã mở hết rương
		month_bar.max_value = maxf(float(int(data.get("daily_month_goal", month_stars))), 1.0)
		month_bar.value = month_bar.max_value
		month_remain.text = tr("STR_DW_ALL_CHESTS")  # keep-code: chữ theo dữ liệu ván chơi (runtime)
		return
	month_bar.max_value = float(target)
	month_remain.text = tr("STR_DW_REMAIN").format([target - month_stars])
	# Thanh chạy từ mốc TRƯỚC ván này tới mốc hiện tại (animation: xem `_play_intro`)
	month_bar.value = float(prev)
	_bar_from = float(prev)
	_bar_to = float(month_stars)
	if DisplayServer.get_name() == "headless" or gained <= 0:
		month_bar.value = _bar_to
		_bar_from = -1.0


# ---------------------------------------------------------------------------
# 4. Sao của ngày (x/6)
# ---------------------------------------------------------------------------
func _fill_day() -> void:
	var day_stars := int(data.get("daily_day_stars", 0))
	var day_max := maxi(int(data.get("daily_stars_max", 6)), 1)
	day_value.text = tr("STR_DW_DAY_STARS").format([day_stars, day_max])
	var minis := day_stars_row.get_children()
	for i in minis.size():
		(minis[i] as TextureRect).texture = star_full if i < day_stars else star_empty


# ---------------------------------------------------------------------------
# Hiệu ứng mở
# ---------------------------------------------------------------------------
## Ẩn sẵn các phần sẽ hiện dần (gọi đồng bộ trong `_on_open` để không bị nháy 1 khung)
func _hide_for_intro() -> void:
	for n: Control in [fx_tape, fx_week, fx_month, fx_day, fx_stats, fx_buttons]:
		if n != null:
			n.modulate.a = 0.0


func _play_intro(earned: int, secs: int, used: int, maxs: int, walls: int) -> void:
	# chờ 1 khung để layout xong (size/pivot chính xác)
	await get_tree().process_frame
	if not is_inside_tree():
		return
	_intro_tape()

	# dải tuần hiện trước; ô ngày vừa chơi nảy lên
	_fade_in(fx_week, 0.15, 0.95)
	if _sel_cell != null:
		_sel_cell.pivot_offset = _sel_cell.size * 0.5
		var tp := _track(create_tween())
		tp.tween_interval(0.55)
		tp.tween_property(_sel_cell, "scale", Vector2(1.22, 1.22), 0.16) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tp.tween_property(_sel_cell, "scale", Vector2.ONE, 0.14)

	# (sao lớn + hào quang + pháo hoa: xem `_set_stars` / `_pop_star` / `_celebrate`)
	var t0 := STAR_DELAY + STAR_STEP * float(maxi(earned, 1)) + 0.3

	# thẻ Sao tháng: hiện -> thanh chạy -> (chạm mốc) rương mở
	_fade_in(fx_month, t0, 0.95)
	if _bar_from >= 0.0 and _bar_to > _bar_from:
		var tb := _track(create_tween())
		tb.tween_interval(t0 + 0.3)
		tb.tween_property(month_bar, "value", _bar_to, 0.7) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if _chest_reached:
			tb.tween_callback(_chest_unlock)
	elif _chest_reached:
		var tc0 := _track(create_tween())
		tc0.tween_interval(t0 + 0.4)
		tc0.tween_callback(_chest_unlock)

	# thẻ Hôm nay: sao nhỏ đạt nảy lần lượt
	_fade_in(fx_day, t0 + 0.15, 0.95)
	var minis := day_stars_row.get_children()
	for i in minis.size():
		var s := minis[i] as TextureRect
		if s == null or s.texture != star_full:
			continue
		s.pivot_offset = s.size * 0.5
		s.scale = Vector2.ONE * 0.2  # keep-code: pose hoạt cảnh runtime (tween)
		var ts := _track(create_tween())
		ts.tween_interval(t0 + 0.35 + 0.07 * float(i))
		ts.tween_property(s, "scale", Vector2(1.3, 1.3), 0.14) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		ts.tween_property(s, "scale", Vector2.ONE, 0.1)

	# thống kê: thẻ hiện + số đếm lên
	var t1 := t0 + 0.35
	_fade_in(fx_stats, t1, 0.95)
	value_time.text = "00:00"  # keep-code: chữ theo dữ liệu ván chơi (runtime)
	value_steps.text = "0/%d" % maxs
	value_walls.text = "0"  # keep-code: chữ theo dữ liệu ván chơi (runtime)
	_steps_max = maxs
	var tc := _track(create_tween())
	tc.tween_interval(t1 + 0.1)
	tc.tween_method(_count_time, 0.0, float(secs), COUNT_TIME) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tc.parallel().tween_method(_count_steps, 0.0, float(used), COUNT_TIME) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tc.parallel().tween_method(_count_walls, 0.0, float(walls), COUNT_TIME) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# nút
	_fade_in(fx_buttons, t1 + 0.3, 0.9)


## Chạm mốc rương: rương phóng to + rung, lấp lánh + 3 quả pháo vàng quanh rương
func _chest_unlock() -> void:
	if chest == null:
		return
	Sfx.play(Sfx.STAR_POP)
	Sfx.star_pop(2)
	chest.pivot_offset = chest.size * 0.5
	var tw := _track(create_tween())
	tw.tween_property(chest, "scale", Vector2(1.6, 1.6), 0.15) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for a in [-0.3, 0.3, -0.2, 0.2, 0.0]:
		tw.tween_property(chest, "rotation", float(a), 0.07)
	tw.tween_property(chest, "scale", Vector2.ONE, 0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_burst(chest, 24)
	if fx_fireworks != null and fx_fireworks.get_child_count() >= 8:
		var gold := FW_COLORS[0]
		_firework(5, Vector2(404, 238), gold, 40, 1.1)
		var t2 := _track(create_tween())
		t2.tween_interval(0.25)
		t2.tween_callback(_firework.bind(6, Vector2(340, 214), FW_COLORS[1], 32, 1.0))
		t2.tween_interval(0.2)
		t2.tween_callback(_firework.bind(7, Vector2(420, 190), FW_COLORS[4], 32, 1.0))


## Tiếng "pop" + chuông cao dần mỗi khi một ngôi sao nảy lên
func _star_pop(index: int) -> void:
	Sfx.play(Sfx.STAR_POP)
	Sfx.star_pop(index)


## Toé lấp lánh quanh sao (node `Burst` con của mỗi sao lớn, texture = fx_sparkle.png)
func _burst(star: Control, amount: int) -> void:
	var b := star.get_node_or_null("Burst") as CPUParticles2D
	if b == null:
		return
	b.position = star.size * 0.5
	b.amount = amount
	if b.texture != null:
		var k := SPARK_PX / float(maxi(b.texture.get_width(), 1))
		b.scale_amount_min = k * 0.6
		b.scale_amount_max = k * 1.4
	b.restart()
	b.emitting = true


## Vòng sóng toả ra từ sao (node `Ring` con của mỗi sao lớn, texture = fx_ring.png)
func _ring(star: Control) -> void:
	var r := star.get_node_or_null("Ring") as Control
	if r == null:
		return
	r.pivot_offset = r.size * 0.5
	r.scale = Vector2.ONE * 0.7  # keep-code: pose hoạt cảnh runtime (tween)
	r.modulate = Color(RING_COLOR.r, RING_COLOR.g, RING_COLOR.b, 0.9)
	var tw := _track(create_tween().set_parallel(true))
	tw.tween_property(r, "scale", Vector2.ONE * 2.6, 0.55) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(r, "modulate:a", 0.0, 0.55)


## Ẩn hào quang + dừng pháo giấy trước mỗi lần mở
func _reset_fx() -> void:
	_halo_layers.clear()
	for n: Control in [fx_rays, fx_rays2, fx_rays3, fx_soft]:
		if n != null:
			n.modulate.a = 0.0
	if fx_confetti != null:
		fx_confetti.emitting = false


## HÀO QUANG theo số sao — càng nhiều sao càng TO, SÁNG và NHIỀU TIA:
##   1★: 1 lớp tia nhỏ · 2★: 2 lớp (xoay ngược, lệch góc) · 3★: 3 lớp, lớp thứ 3 to hơn + quầng mềm lớn
const HALO_K: Array[float] = [0.0, 0.6, 0.85, 1.1]
## [node, nhân kích thước, chu kỳ xoay (s, âm = ngược chiều), góc lệch ban đầu (độ), nhân độ sáng]
func _halo_plan() -> Array:
	var p: Array = [[fx_rays, 1.0, 20.0, 0.0, 1.0]]
	if _earned >= 2:
		p.append([fx_rays2, 0.88, -28.0, 11.0, 0.85])
	if _earned >= 3:
		p.append([fx_rays3, 1.3, 44.0, 22.0, 0.7])
	return p


func _start_halo() -> void:
	if fx_rays == null or fx_soft == null or _earned <= 0:
		return
	var k: float = HALO_K[clampi(_earned, 0, COUNT)]
	_halo_k = k
	_halo_layers.clear()
	for n: Control in [fx_rays, fx_rays2, fx_rays3, fx_soft]:
		if n != null:
			n.pivot_offset = n.size * 0.5
			n.modulate = Color(GLOW_COLOR.r, GLOW_COLOR.g, GLOW_COLOR.b, 0.0)
			n.scale = Vector2.ONE * 0.3  # keep-code: pose hoạt cảnh runtime (tween)

	for entry: Array in _halo_plan():
		var n := entry[0] as Control
		if n == null:
			continue
		var mult: float = entry[1]
		var period: float = entry[2]
		var a0: float = entry[4]
		_halo_layers.append(n)
		n.rotation = deg_to_rad(float(entry[3]))
		var tin := _track(create_tween().set_parallel(true))
		tin.tween_property(n, "modulate:a", HALO_ALPHA * a0, 0.5)
		tin.tween_property(n, "scale", Vector2.ONE * k * mult, 0.65) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		# xoay liên tục (âm = ngược chiều)
		var rot := _track(create_tween().set_loops())
		rot.tween_property(n, "rotation", n.rotation + signf(period) * TAU, absf(period))
		# nhấp nháy nhẹ
		var flick := _track(create_tween().set_loops())
		flick.tween_interval(0.7)
		flick.tween_property(n, "modulate:a", HALO_ALPHA * 0.7 * a0, 1.1 + 0.2 * float(_halo_layers.size())) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		flick.tween_property(n, "modulate:a", HALO_ALPHA * a0, 1.1 + 0.2 * float(_halo_layers.size())) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# quầng mềm: to dần theo sao + "thở"
	var ks := k * (1.0 + 0.1 * float(_earned - 1))
	var ts := _track(create_tween().set_parallel(true))
	ts.tween_property(fx_soft, "modulate:a", 0.8, 0.4)
	ts.tween_property(fx_soft, "scale", Vector2.ONE * ks, 0.5) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var breathe := _track(create_tween().set_loops())
	breathe.tween_interval(0.6)
	breathe.tween_property(fx_soft, "scale", Vector2.ONE * ks * 1.12, 0.9) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	breathe.tween_property(fx_soft, "scale", Vector2.ONE * ks, 0.9) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## ĂN MỪNG theo số sao: 1★ nhẹ · 2★ vừa · 3★ rực rỡ
func _celebrate() -> void:
	if _earned <= 0 or fx_fireworks == null:
		return
	var plan: Array = PLAN_1 if _earned == 1 else (PLAN_2 if _earned == 2 else PLAN_3)
	var slots := fx_fireworks.get_child_count()
	if slots <= 0:
		return
	var tw := _track(create_tween().set_parallel(true))
	for i in plan.size():
		var e: Array = plan[i]
		tw.tween_callback(_firework.bind(i % slots, FW_POS[e[0]], FW_COLORS[e[2]], e[3], e[4])) \
			.set_delay(float(e[1]))
	var conf: int = CONFETTI_BY_STARS[_earned]
	if conf > 0:
		tw.tween_callback(_confetti.bind(conf)).set_delay(0.0)
		if _earned == COUNT:
			tw.tween_callback(_confetti.bind(conf)).set_delay(1.1)
			tw.tween_callback(_halo_pulse).set_delay(1.7)


## Một quả pháo: quầng sáng chớp + tia lấp lánh toả tròn, chậm dần rồi rơi xuống (gravity)
func _firework(slot: int, pos: Vector2, color: Color, amount: int, power: float) -> void:
	var fw := fx_fireworks.get_child(slot) as Control
	if fw == null:
		return
	fw.position = pos
	var b := fw.get_node_or_null("Spark") as CPUParticles2D
	if b != null:
		b.color = color
		b.amount = amount
		b.initial_velocity_min = 130.0 * power
		b.initial_velocity_max = 250.0 * power
		if b.texture != null:
			var k := FW_PX * power / float(maxi(b.texture.get_width(), 1))
			b.scale_amount_min = k * 0.6
			b.scale_amount_max = k * 1.3
		b.restart()
		b.emitting = true
	var f := fw.get_node_or_null("Flash") as Control
	if f != null:
		f.pivot_offset = f.size * 0.5
		f.scale = Vector2.ONE * 0.3  # keep-code: pose hoạt cảnh runtime (tween)
		f.modulate = Color(color.r, color.g, color.b, 0.9)
		var tw := _track(create_tween().set_parallel(true))
		tw.tween_property(f, "scale", Vector2.ONE * (1.2 * power), 0.4) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(f, "modulate:a", 0.0, 0.4)


## Quả chốt (3★): mọi lớp tia bùng to rồi dịu lại
func _halo_pulse() -> void:
	if fx_soft == null or _halo_layers.is_empty():
		return
	for entry: Array in _halo_plan():
		var n := entry[0] as Control
		if n == null:
			continue
		var base := Vector2.ONE * _halo_k * float(entry[1])
		var tw := _track(create_tween())
		tw.tween_property(n, "scale", base * 1.3, 0.25) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(n, "scale", base, 0.8) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Pháo giấy rơi từ trên xuống
func _confetti(amount: int) -> void:
	if fx_confetti == null:
		return
	fx_confetti.amount = amount
	if fx_confetti.texture != null:
		var k := CONFETTI_PX / float(maxi(fx_confetti.texture.get_width(), 1))
		fx_confetti.scale_amount_min = k * 0.7
		fx_confetti.scale_amount_max = k * 1.3
	var parent := fx_confetti.get_parent() as Control
	if parent != null:
		fx_confetti.position = Vector2(parent.size.x * 0.5, -24.0)
	fx_confetti.restart()
	fx_confetti.emitting = true


## Đủ 3 sao: 3 sao lớn "thở" nhẹ liên tục (lệch pha nhau)
func _start_idle() -> void:
	var heroes: Array[TextureRect] = [hero1, hero2, hero3]
	for i in COUNT:
		var tw := _track(create_tween().set_loops())
		tw.tween_interval(0.15 * float(i))
		tw.tween_property(heroes[i], "scale", Vector2(1.07, 1.07), 0.7) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(heroes[i], "scale", Vector2.ONE, 0.7) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _count_time(v: float) -> void:
	var s := int(round(v))
	value_time.text = "%02d:%02d" % [s / 60, s % 60]


func _count_steps(v: float) -> void:
	value_steps.text = "%d/%d" % [int(round(v)), _steps_max]


func _count_walls(v: float) -> void:
	value_walls.text = str(int(round(v)))


## Băng keo tiêu đề rơi xuống + lắc nhẹ rồi đứng yên
func _intro_tape() -> void:
	if fx_tape == null:
		return
	if not _tape_saved:
		_tape_rest = fx_tape.position
		_tape_rot = fx_tape.rotation
		_tape_saved = true
	fx_tape.position = _tape_rest + Vector2(0, -70)
	fx_tape.rotation = _tape_rot - 0.14
	fx_tape.modulate.a = 0.0
	var tw := _track(create_tween().set_parallel(true))
	tw.tween_property(fx_tape, "position", _tape_rest, 0.42) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_property(fx_tape, "modulate:a", 1.0, 0.15)
	tw.tween_property(fx_tape, "rotation", _tape_rot, 0.6) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _fade_in(node: Control, delay: float, from_scale: float) -> void:
	if node == null:
		return
	node.pivot_offset = node.size * 0.5
	node.modulate.a = 0.0
	node.scale = Vector2.ONE * from_scale
	var tw := _track(create_tween())
	tw.tween_interval(delay)
	tw.tween_property(node, "modulate:a", 1.0, 0.2)
	tw.parallel().tween_property(node, "scale", Vector2.ONE, 0.26) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _track(tw: Tween) -> Tween:
	_tweens.append(tw)
	return tw


func _kill_tweens() -> void:
	for t in _tweens:
		if t != null and t.is_valid():
			t.kill()
	_tweens.clear()


func _on_replay_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	replay_requested.emit()
	close()


func _on_daily_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	daily_requested.emit()
	close()
