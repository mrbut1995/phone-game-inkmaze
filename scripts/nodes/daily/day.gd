class_name DailyDayCell
extends Control
## ============================================================================
## Component: Ô ngày trong Lịch Daily Challenge (nodes/daily/day.tscn)
## Bố cục bám mockup (mockup/daily_challenge.svg), ô chuẩn 130x150 px:
##   - Số ngày (2 chữ số) ở góc trên - trái
##   - Dấu tick đỏ ở góc trên - phải (ngày đã chơi được >= 1 sao)
##   - Viên trạng thái ở đáy ô: "3/3 SAO" / "2/3 XONG" / "CHƯA MỞ"
##   - Nhãn "HÔM NAY" nhô lên khỏi ô khi là ngày hiện tại
## Toàn bộ texture trạng thái được gán từ code theo bảng TEXTURES bên dưới.
## ============================================================================

signal day_selected(day_number: int)

enum State {
	EMPTY,    ## Ngày của tháng trước (số mờ, không chọn được)
	NONE,     ## Ô trống cuối tháng (không có số)
	FUTURE,   ## Ngày sắp tới - chưa mở khoá
	LATER,    ## Ngày còn xa trong tháng - mở mờ, gọn hơn
	MISSED,   ## Ngày đã qua nhưng bỏ lỡ
	PARTIAL,  ## Đã chơi nhưng chưa đủ 3 sao
	DONE,     ## Đã hoàn thành trọn 3 sao
	TODAY,    ## Ngày hôm nay
}

const MAX_STARS := 3
const TEX_DIR := "res://assets/images/calendar/"

## state -> [normal, pressed, focus] ("" = dùng lại texture normal)
const TEXTURES := {
	State.EMPTY: ["day_cell_empty.svg", "", ""],
	State.NONE: ["day_cell_empty.svg", "", ""],
	State.FUTURE: ["day_cell_locked_normal.svg", "", "day_cell_locked_focus.svg"],
	State.LATER: ["day_cell_locked_normal.svg", "", "day_cell_locked_focus.svg"],
	State.MISSED: ["day_cell_locked_normal.svg", "", "day_cell_locked_focus.svg"],
	State.PARTIAL: ["day_cell_completed_normal.svg", "day_cell_completed_pressed.svg", "day_cell_completed_focus.svg"],
	State.DONE: ["day_cell_completed_normal.svg", "day_cell_completed_pressed.svg", "day_cell_completed_focus.svg"],
	State.TODAY: ["day_cell_selected_normal.svg", "day_cell_selected_pressed.svg", "day_cell_selected_focus.svg"],
}

## state -> texture viên trạng thái ("" = ẩn viên)
const PILL_TEXTURES := {
	State.EMPTY: "",
	State.NONE: "",
	State.FUTURE: "tag_progress_locked.svg",
	State.LATER: "",
	State.MISSED: "tag_progress_missed.svg",
	State.PARTIAL: "tag_progress_partial.svg",
	State.DONE: "tag_progress_completed.svg",
	State.TODAY: "tag_progress_today.svg",
}

## state -> theme variation của số ngày
const NUM_VARIATIONS := {
	State.EMPTY: &"DailyDayNumFaded",
	State.NONE: &"DailyDayNumFaded",
	State.FUTURE: &"DailyDayNumLocked",
	State.LATER: &"DailyDayNumFuture",
	State.MISSED: &"DailyDayNumLocked",
	State.PARTIAL: &"DailyDayNum",
	State.DONE: &"DailyDayNum",
	State.TODAY: &"DailyDayNumToday",
}

## state -> theme variation của chữ trong viên trạng thái
const PILL_VARIATIONS := {
	State.EMPTY: &"DailyDayStatusLocked",
	State.NONE: &"DailyDayStatusLocked",
	State.FUTURE: &"DailyDayStatusLocked",
	State.LATER: &"DailyDayStatusLocked",
	State.MISSED: &"DailyDayStatusMissed",
	State.PARTIAL: &"DailyDayStatusPartial",
	State.DONE: &"DailyDayStatusDone",
	State.TODAY: &"DailyDayStatusToday",
}

@export var day_number: int = 1
@export var state: State = State.FUTURE
@export var stars: int = 0
@export var weekend: bool = false

@onready var btn: TextureButton = $Button
@onready var number_label: Label = $Button/Number
@onready var check_icon: TextureRect = $Button/CheckIcon
@onready var star_icon: TextureRect = $Button/StarIcon
@onready var pill: TextureRect = $Button/StatusPill
@onready var status_label: Label = $Button/StatusPill/StatusLabel
@onready var today_tag: TextureRect = $Button/TodayTag
@onready var today_label: Label = $Button/TodayTag/TodayLabel


func _ready() -> void:
	if btn != null:
		btn.pressed.connect(_on_btn_pressed)
	_apply()


func setup(p_day: int, p_state: State, p_stars: int = 0, p_weekend: bool = false) -> void:
	day_number = p_day
	state = p_state
	stars = clampi(p_stars, 0, MAX_STARS)
	weekend = p_weekend
	if is_node_ready():
		_apply()


## Gán texture + theme variation + nội dung chữ theo state hiện tại
func _apply() -> void:
	if btn == null:
		return

	var files: Array = TEXTURES[state]
	btn.texture_normal = _tex(files[0])
	btn.texture_pressed = _tex(files[0] if files[1] == "" else files[1])
	btn.texture_hover = _tex(files[0] if files[1] == "" else files[1])
	btn.texture_focused = _tex(files[0] if files[2] == "" else files[2])
	btn.texture_disabled = _tex(files[0])

	var playable := state == State.PARTIAL or state == State.DONE or state == State.TODAY
	btn.disabled = not playable
	btn.focus_mode = Control.FOCUS_ALL if playable else Control.FOCUS_NONE

	# Ô trống cuối tháng: ẩn hẳn số ngày
	number_label.visible = state != State.NONE
	if not number_label.visible:
		check_icon.visible = false
		star_icon.visible = false
		pill.visible = false
		today_tag.visible = false
		return

	# Số ngày: cuối tuần tô đỏ, ngày bỏ lỡ/chưa tới thì mờ đi
	number_label.text = "%02d" % day_number
	var num_variation: StringName = NUM_VARIATIONS[state]
	var faded_weekend := false
	if weekend and state != State.EMPTY and state != State.TODAY:
		num_variation = &"DailyDayNumSun"
		faded_weekend = state != State.PARTIAL and state != State.DONE
	number_label.theme_type_variation = num_variation
	number_label.modulate = Color(1, 1, 1, 0.62) if faded_weekend else Color(1, 1, 1, 1)

	# Dấu tick đỏ (đã chơi) / ngôi sao nhỏ (ngày hôm nay)
	check_icon.visible = state == State.PARTIAL or state == State.DONE
	star_icon.visible = state == State.TODAY

	# Viên trạng thái
	var pill_file: String = PILL_TEXTURES[state]
	pill.visible = pill_file != ""
	if pill.visible:
		pill.texture = _tex(pill_file)
		status_label.theme_type_variation = PILL_VARIATIONS[state]
		status_label.text = _status_text()

	# Nhãn "HÔM NAY"
	today_tag.visible = state == State.TODAY
	if today_tag.visible:
		today_label.text = tr("STR_TODAY")


func _status_text() -> String:
	match state:
		State.FUTURE:
			return tr("STR_DAILY_LOCKED")
		State.MISSED:
			return tr("STR_DAILY_MISSED")
		State.TODAY:
			return tr("STR_DAILY_DONE_FORMAT").format([stars, MAX_STARS])
		_:
			return tr("STR_DAILY_STARS_FORMAT").format([stars, MAX_STARS])


func _tex(file: String) -> Texture2D:
	if file == "":
		return null
	return load(TEX_DIR + file) as Texture2D


func _on_btn_pressed() -> void:
	# SFX: miết mép giấy khi chọn ngày trong lịch Daily
	Sfx.play(Sfx.DAY_SWITCH)
	day_selected.emit(day_number)
