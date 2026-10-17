class_name DailyDayCell
extends Control
## ============================================================================
## Component: Ô ngày trong Lịch Daily (nodes/daily/day.tscn)
##
## Bám ĐÚNG mockup/daily_challenge.svg (ô 114×115 trong khung 1080×1920, scene
## dùng nửa kích thước 57×57,5):
##   · Ô trắng + ✓ đỏ  = ngày đã chơi (được ≥ 1 Sao)
##   · Ô hồng + ✗ đỏ   = ngày đã qua mà bỏ lỡ
##   · Ô nét đứt       = ngày còn xa (Sắp tới)
##   · Số trơn (không ô)= hôm qua/mai hoặc ngày tháng trước
##   · Ô kem viền hổ phách + nhãn "HÔM NAY" + viên "x/6 ★" = hôm nay
## Toàn bộ art trạng thái lấy từ bảng TEXTURES bên dưới.
## ============================================================================

signal day_selected(day_number: int)

enum State {
	EMPTY,    ## Ngày của tháng trước (số mờ, không chọn được)
	NONE,     ## Ô trống cuối tháng (không có số)
	FUTURE,   ## Ngày sắp tới gần - chỉ hiện số, chưa có ô
	LATER,    ## Ngày còn xa - ô nét đứt
	MISSED,   ## Ngày đã qua nhưng bỏ lỡ (ô hồng + ✗)
	PARTIAL,  ## Đã chơi nhưng chưa đủ 6 Sao (ô trắng + ✓)
	DONE,     ## Đã hoàn thành trọn 6 Sao (ô trắng + ✓)
	TODAY,    ## Ngày hôm nay (ô kem + nhãn + viên Sao)
}

## Tổng Sao tối đa của một ngày (khớp `DailyManager.DAY_STARS_MAX`)
const MAX_STARS := 6
const TEX_DIR := "res://assets/images-png/daily/"

## state -> texture nền ô ("" = không vẽ ô)
const TEXTURES := {
	State.EMPTY: "",
	State.NONE: "",
	State.FUTURE: "",
	State.LATER: "cell_future.png",
	State.MISSED: "cell_missed.png",
	State.PARTIAL: "cell_done.png",
	State.DONE: "cell_done.png",
	State.TODAY: "cell_today.png",
}

const COLOR_NUM := Color("#163A58")
const COLOR_NUM_FADED := Color("#B8C4CC")
const COLOR_NUM_SUN := Color("#D84444")

@export var day_number: int = 1
@export var state: State = State.FUTURE
## Số Sao đã đạt của ngày (0..6)
@export var stars: int = 0
@export var weekend: bool = false
## Ngày bỏ lỡ đã trả Xu MỞ KHOÁ
@export var unlocked: bool = false

## Node binding: khai `node_paths` + NodePath trong `day.tscn`
@export var hit: BaseButton = null
@export var bg: TextureRect = null
@export var number_label: Label = null
@export var number_big: Label = null
@export var state_icon: TextureRect = null
@export var pill: TextureRect = null
@export var pill_label: Label = null
@export var today_ribbon: TextureRect = null
@export var today_label: Label = null


func _ready() -> void:
	# Dây `pressed → _on_pressed` khai trong `day.tscn` (cùng scene)
	_apply()


func setup(p_day: int, p_state: State, p_stars: int = 0, p_weekend: bool = false,
		p_unlocked: bool = false) -> void:
	day_number = p_day
	state = p_state
	stars = clampi(p_stars, 0, MAX_STARS)
	weekend = p_weekend
	unlocked = p_unlocked
	if is_node_ready():
		_apply()


func _apply() -> void:
	if hit == null:
		return

	if bg != null:
		bg.texture = _tex(str(TEXTURES[state]))

	# Bấm vào ô = CHỌN ngày đó (màn Daily tự xử lý); ngày tương lai / tháng khác thì khoá
	var playable := state == State.PARTIAL or state == State.DONE \
		or state == State.TODAY or state == State.MISSED
	hit.disabled = not playable
	hit.focus_mode = Control.FOCUS_ALL if playable else Control.FOCUS_NONE

	number_label.visible = state != State.NONE and state != State.TODAY
	if number_big != null:
		number_big.visible = state == State.TODAY
		if number_big.visible:
			number_big.text = "%02d" % day_number
			number_big.add_theme_color_override("font_color",
				COLOR_NUM_SUN if weekend else Color("#A15F1B"))
	if not number_label.visible and state != State.TODAY:
		_hide_extras()
		return

	number_label.text = "%02d" % day_number
	var color := COLOR_NUM
	if state == State.EMPTY:
		color = COLOR_NUM_FADED
	elif weekend:
		color = COLOR_NUM_SUN
		if state == State.EMPTY:
			color = COLOR_NUM_FADED
	number_label.add_theme_color_override("font_color", color)

	# ✓ đỏ (đã chơi) / ✗ đỏ (bỏ lỡ)
	if state_icon != null:
		var icon_file := ""
		if state == State.PARTIAL or state == State.DONE:
			icon_file = "check_red.png"
		elif state == State.MISSED and not unlocked:
			icon_file = "cross_red.png"
		state_icon.visible = icon_file != ""
		if state_icon.visible:
			state_icon.texture = _tex(icon_file)

	# Viên "x/6 ★" chỉ có ở ô HÔM NAY (giống mockup)
	if pill != null:
		pill.visible = state == State.TODAY
		if pill.visible and pill_label != null:
			pill_label.text = tr("STR_DAILY_STARS_BADGE").format([stars, MAX_STARS])

	if today_ribbon != null:
		today_ribbon.visible = state == State.TODAY
		if today_ribbon.visible and today_label != null:
			today_label.text = tr("STR_TODAY")


## Chữ trong viên Sao của ô hôm nay (test đọc)
func status_text() -> String:
	if pill_label == null:
		return ""
	return pill_label.text


func _hide_extras() -> void:
	if state_icon != null:
		state_icon.visible = false
	if pill != null:
		pill.visible = false
	if today_ribbon != null:
		today_ribbon.visible = false


func _tex(file: String) -> Texture2D:
	if file == "":
		return null
	return load(TEX_DIR + file) as Texture2D


func _on_pressed() -> void:
	# SFX: miết mép giấy khi chọn ngày trong lịch Daily
	Sfx.play(Sfx.DAY_SWITCH)
	day_selected.emit(day_number)
