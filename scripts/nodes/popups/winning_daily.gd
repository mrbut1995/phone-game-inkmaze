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

const STAR_COUNT := 3
const STAR_DELAY := 0.25
const STAR_STEP := 0.22
const DAY_SECONDS := 86400
const WEEKDAY_KEYS: Array[String] = [
	"STR_DW_WD_MON", "STR_DW_WD_TUE", "STR_DW_WD_WED", "STR_DW_WD_THU",
	"STR_DW_WD_FRI", "STR_DW_WD_SAT", "STR_DW_WD_SUN",
]
const COLOR_DAY := Color(0.086, 0.275, 0.388, 1)
const COLOR_DAY_ON := Color(0.631, 0.373, 0.106, 1)
const COLOR_DAY_OFF := Color(0.722, 0.769, 0.8, 1)

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


func _on_open() -> void:
	if data.is_empty():
		return
	var day := maxi(int(data.get("daily_day", 1)), 1)
	label_title.text = tr("STR_DW_TITLE").format([day])

	_fill_week(day)
	_set_stars(int(data.get("daily_stars", 0)))
	_fill_month()
	_fill_day()

	var seconds := maxi(int(round(float(data.get("time", 0.0)))), 0)
	value_time.text = "%02d:%02d" % [seconds / 60, seconds % 60]
	value_steps.text = "%d/%d" % [int(data.get("steps_used", 0)), int(data.get("steps_max", 0))]
	value_walls.text = str(int(data.get("wall_hits", 0)))

	# Gán chữ nút bằng code (test đọc được chuỗi đã dịch)
	label_daily.text = TranslationServer.translate("STR_BTN_BACK_DAILY")


# ---------------------------------------------------------------------------
# 1. Dải tuần (thứ Hai -> Chủ nhật) chứa ngày vừa chơi
# ---------------------------------------------------------------------------
func _fill_week(day: int) -> void:
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


# ---------------------------------------------------------------------------
# 2. Sao lớn của VÁN NÀY
# ---------------------------------------------------------------------------
func _set_stars(earned_stars: int) -> void:
	var earned := clampi(earned_stars, 0, STAR_COUNT)
	var heroes: Array[TextureRect] = [hero1, hero2, hero3]
	for i in STAR_COUNT:
		var h := heroes[i]
		var on := i < earned
		h.texture = star_full if on else star_empty
		h.modulate = Color(1, 1, 1, 1) if on else Color(1, 1, 1, 0.75)
		h.pivot_offset = h.size * 0.5
		if on:
			h.scale = Vector2.ONE * 0.4
			h.modulate.a = 0.0
			_pop_star(h, i)


func _pop_star(star: TextureRect, index: int) -> void:
	var tw := create_tween()
	tw.tween_interval(STAR_DELAY + STAR_STEP * float(index))
	tw.tween_callback(func() -> void:
		star.modulate.a = 1.0
		Sfx.play(Sfx.STAR_POP)
		Sfx.star_pop(index))
	tw.tween_property(star, "scale", Vector2(1.15, 1.15), 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(star, "scale", Vector2.ONE, 0.12)


# ---------------------------------------------------------------------------
# 3. Sao tháng -> rương kế tiếp
# ---------------------------------------------------------------------------
func _fill_month() -> void:
	var month_stars := int(data.get("daily_month_stars", 0))
	var gained := maxi(int(data.get("daily_stars_gained", 0)), 0)
	var target := 0
	for def in DailyManager.milestone_defs():
		var need := int((def as Dictionary).get("stars", 0))
		if need > month_stars:
			target = need
			break
	if target <= 0:
		# Đã vượt mọi mốc -> thanh đầy, báo đã mở hết rương
		month_bar.max_value = maxf(float(int(data.get("daily_month_goal", month_stars))), 1.0)
		month_bar.value = month_bar.max_value
		month_remain.text = tr("STR_DW_ALL_CHESTS")
		return
	month_bar.max_value = float(target)
	month_remain.text = tr("STR_DW_REMAIN").format([target - month_stars])
	# Thanh chạy từ mốc TRƯỚC ván này tới mốc hiện tại
	month_bar.value = float(maxi(month_stars - gained, 0))
	if DisplayServer.get_name() == "headless" or gained <= 0:
		month_bar.value = float(month_stars)
		return
	create_tween().tween_property(month_bar, "value", float(month_stars), 0.6) \
		.set_delay(0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


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


func _on_replay_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	replay_requested.emit()
	close()


func _on_daily_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	daily_requested.emit()
	close()
