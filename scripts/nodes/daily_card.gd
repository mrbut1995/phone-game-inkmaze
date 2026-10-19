class_name DailyCard
extends EventCardBase
## ============================================================================
## Node: DailyCard — Thẻ THỬ THÁCH HẰNG NGÀY trên carousel Main Screen
## (nodes/main/daily_card.tscn). Tách riêng khỏi `EventCard`:
##   · EventCard = sự kiện THẬT (có file .tres, có hạn, có 2 phần thưởng)
##   · DailyCard = event ẢO của `DailyManager` (làm mới 00:00 mỗi ngày)
##
## Thẻ gồm: art nền theme daily + chip "HẰNG NGÀY" + chip giờ còn lại tới 00:00 +
## LÁ LỊCH (tháng / ngày / thứ) + tiêu đề 2 dòng + khung **Sao hôm nay x/6** + CTA.
##
## Cách dùng:
##   var card = preload("res://nodes/main/daily_card.tscn").instantiate()
##   add_child(card)
##   card.setup(daily_event_data)
## ============================================================================

## Khoá dịch thứ trong tuần (Time.weekday: 0 = Chủ nhật … 6 = Thứ Bảy)
const _WEEKDAY_KEYS := [
	"STR_WEEKDAY_SUN", "STR_WEEKDAY_MON", "STR_WEEKDAY_TUE", "STR_WEEKDAY_WED",
	"STR_WEEKDAY_THU", "STR_WEEKDAY_FRI", "STR_WEEKDAY_SAT",
]

@onready var card_lip: Panel = $Content/Background/Lip
@onready var bg_gradient: ColorRect = $Content/Background/BgGradient
@onready var back_art: TextureRect = $Content/Background/BackArt
#@onready var front_art: NinePatchRect = $Content/Background/FrontArt
@onready var theme_chip: PanelContainer = $Content/Chips/ThemeChip
@onready var chip_label: Label = $Content/Chips/ThemeChip/Content/ChipLabel
@onready var chip_dot: ColorRect = $Content/Chips/ThemeChip/Content/ChipDot
@onready var timer_chip: PanelContainer = $Content/Chips/TimerChip
@onready var timer_label: Label = $Content/Chips/TimerChip/Content/TimerLabel
@onready var cal_month: Label = $Content/Text/DailyDate/Month
@onready var cal_day: Label = $Content/Text/DailyDate/Day
@onready var cal_weekday: Label = $Content/Text/DailyDate/Weekday
@onready var title_1: Label = $Content/Text/Title/Title1
@onready var title_2: Label = $Content/Text/Title/Title2
@onready var stars_panel: Panel = $Content/Stars
@onready var stars_label: Label = $Content/Stars/Row/Value
@onready var cta_button: Button = $Content/CtaButton
@onready var cta_label: Label = $Content/CtaButton/CtaLabel
@onready var timer_node: Timer = $Content/CountdownTimer


func _cta_node() -> BaseButton:
	return cta_button


func _timer_node() -> Timer:
	return timer_node


func _refresh_live() -> void:
	_refresh_countdown()
	_refresh_stars()


# ---------------------------------------------------------------------------
# NỘI DUNG
# ---------------------------------------------------------------------------

func _apply_card(data: EventData) -> void:
	_apply_theme(data.theme)
	_apply_texts(data)
	_apply_calendar_leaf()
	_refresh_stars()
	_refresh_countdown()


func _apply_theme(t: EventTheme) -> void:
	if t == null:
		return
	#_paint_background(t, bg_gradient, back_art, front_art)
	# Daily: viền đỏ nằm sẵn trong ảnh nền → chỉ đổi màu gờ đáy (không có node Frame)
	_paint_card_edges(card_lip, null, t)
	_paint_chip(theme_chip, chip_dot, chip_label, t)
	_paint_chip(timer_chip, null, timer_label, t)
	_paint_title(title_1, t)
	_paint_title(title_2, t)
	_paint_panel(stars_panel, t)
	if stars_label != null:
		stars_label.add_theme_color_override("font_color", t.label_color)
	_paint_cta(cta_button, cta_label, t)


func _apply_texts(data: EventData) -> void:
	if chip_label != null:
		chip_label.text = tr(str(data.chip_key))
	if title_1 != null:
		title_1.text = tr(str(data.title_key_1))
	if title_2 != null:
		title_2.text = tr(str(data.title_key_2))
	if cta_label != null:
		cta_label.text = tr(str(data.cta_key))


## Lá lịch: NGÀY / THÁNG / THỨ lấy từ giờ máy (Label động — không nhúng vào art)
func _apply_calendar_leaf() -> void:
	var now := Time.get_datetime_dict_from_system()
	if cal_month != null:
		cal_month.text = tr("STR_MONTH_%02d" % int(now.get("month", 1)))
	if cal_day != null:
		cal_day.text = str(int(now.get("day", 1)))
	if cal_weekday != null:
		cal_weekday.text = tr(_WEEKDAY_KEYS[clampi(int(now.get("weekday", 0)), 0, 6)])


## Khung "Sao hôm nay": x/6 (3 Sao CHƠI theo nhiệm vụ + 3 Sao THỬ THÁCH)
func _refresh_stars() -> void:
	if stars_label == null:
		return
	var dm := _get_daily_manager()
	if dm == null or not dm.has_method("get_today"):
		return
	var day := int(dm.call("get_today"))
	var stars := int(dm.call("get_day_stars", day)) if dm.has_method("get_day_stars") else 0
	var total := int(dm.get("DAY_STARS_MAX"))
	stars_label.text = tr("STR_DAILY_STARS_BADGE").format([stars, total])


## Đếm ngược tới 00:00 (mốc làm mới ngày) — < 1h hiện phút, còn lại hiện giờ
func _refresh_countdown() -> void:
	if timer_label == null:
		return
	var now := Time.get_datetime_dict_from_system()
	var h: int = 23 - int(now.get("hour", 0))
	var m: int = 59 - int(now.get("minute", 0))
	var remaining_secs := h * 3600 + m * 60
	if remaining_secs < 3600:
		timer_label.text = tr("STR_EVENT_TIMER_MINUTES").format([ceili(float(remaining_secs) / 60.0)])
	else:
		timer_label.text = tr("STR_EVENT_TIMER_HOURS").format([h + 1])
