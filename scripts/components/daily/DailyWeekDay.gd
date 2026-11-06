class_name DailyWeekDay
extends Control
## ============================================================================
## Một ô NGÀY trong dải tuần của màn Daily (nodes/daily/week_day.tscn)
##   · Ô kem viền hổ phách = hôm nay · viền xanh nét đứt = ngày đang chọn
##   · ✓ đỏ = đã chơi · ✗ đỏ = bỏ lỡ · số xám = chưa tới · số rất nhạt = ngoài tháng
## Trạng thái dùng chung enum với `DailyDayCell.State` (cùng quy tắc với lịch tháng).
## ============================================================================

signal day_selected(day_number: int)

const TEX_DIR := "res://assets/images-png/daily/"  # keep-code: hằng dùng cho hiệu ứng/dữ liệu runtime (không phải bố cục tĩnh)
const COLOR_NUM := Color("#164663")  # keep-code: hằng dùng cho hiệu ứng/dữ liệu runtime (không phải bố cục tĩnh)
const COLOR_NUM_FADED := Color("#B8C4CC")  # keep-code: hằng dùng cho hiệu ứng/dữ liệu runtime (không phải bố cục tĩnh)
const COLOR_NUM_SUN := Color("#D84444")  # keep-code: hằng dùng cho hiệu ứng/dữ liệu runtime (không phải bố cục tĩnh)
const COLOR_DOW := Color("#5B6E82")  # keep-code: hằng dùng cho hiệu ứng/dữ liệu runtime (không phải bố cục tĩnh)
const COLOR_TODAY := Color("#A15F1B")  # keep-code: hằng dùng cho hiệu ứng/dữ liệu runtime (không phải bố cục tĩnh)
const COLOR_DOW_TODAY := Color("#8A5A12")  # keep-code: hằng dùng cho hiệu ứng/dữ liệu runtime (không phải bố cục tĩnh)

@export var hit: BaseButton = null
@export var today_bg: Control = null
@export var selected_ring: Control = null
@export var lbl_dow: Label = null
@export var lbl_num: Label = null
@export var mark: TextureRect = null

var day_number := 0
var state: DailyDayCell.State = DailyDayCell.State.FUTURE
var selected := false


## `dow_text` = chữ thứ (T2..CN) · `weekend` = tô đỏ số (chỉ CN)
func setup(p_day: int, dow_text: String, p_state: DailyDayCell.State, p_weekend: bool,
		p_unlocked := false) -> void:
	day_number = p_day
	state = p_state
	var is_today := state == DailyDayCell.State.TODAY
	var faded := state == DailyDayCell.State.EMPTY or state == DailyDayCell.State.NONE
	var future := state == DailyDayCell.State.FUTURE or state == DailyDayCell.State.LATER
	if lbl_dow != null:
		lbl_dow.text = dow_text
		lbl_dow.add_theme_color_override("font_color", COLOR_DOW_TODAY if is_today else COLOR_DOW)
	if lbl_num != null:
		lbl_num.text = str(p_day)
		var color := COLOR_NUM
		if is_today:
			color = COLOR_TODAY
		elif faded or future:
			color = COLOR_NUM_FADED
		elif p_weekend:
			color = COLOR_NUM_SUN
		lbl_num.add_theme_color_override("font_color", color)
	if today_bg != null:
		today_bg.visible = is_today
	if mark != null:
		var file := ""
		if state == DailyDayCell.State.PARTIAL or state == DailyDayCell.State.DONE:
			file = "check_red.png"
		elif state == DailyDayCell.State.MISSED and not p_unlocked:
			file = "cross_red.png"
		mark.visible = file != ""
		if mark.visible:
			mark.texture = load(TEX_DIR + file) as Texture2D
	if hit != null:
		var playable := state == DailyDayCell.State.PARTIAL or state == DailyDayCell.State.DONE \
			or is_today or state == DailyDayCell.State.MISSED
		hit.disabled = not playable
		hit.focus_mode = Control.FOCUS_ALL if playable else Control.FOCUS_NONE
	_apply_selected()


func set_selected(value: bool) -> void:
	selected = value
	_apply_selected()


func _apply_selected() -> void:
	if selected_ring != null:
		selected_ring.visible = selected and state != DailyDayCell.State.TODAY \
			and state != DailyDayCell.State.EMPTY and state != DailyDayCell.State.NONE


func _on_pressed() -> void:
	Sfx.play(Sfx.DAY_SWITCH)
	day_selected.emit(day_number)
