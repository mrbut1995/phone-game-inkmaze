class_name DailyMissionRow
extends Control
## ============================================================================
## Component: 1 hàng nhiệm vụ trong bảng Mission của màn Daily
## (nodes/daily/mission_row.tscn — khớp mockup daily_challenge.svg)
##
## Mỗi hàng 980x110:
##   - Cột trái (Status): ô tick + chữ trạng thái + Xu thưởng
##   - Cột phải: (badge SPECIAL MODE) + Tiêu đề + mô tả + tiến độ + nút hành động
##   - Nút: chưa xong = "VÀO CHƠI ›" (xanh) · đã xong = "HOÀN THÀNH" (xám, bấm để chơi lại)
## ============================================================================

signal action_pressed(index: int)

const BOX_DONE := preload("res://assets/images/calendar/box_task_done.svg")
const BOX_TODO := preload("res://assets/images/calendar/box_task_todo.svg")
const BTN_DONE_NORMAL := preload("res://assets/images/calendar/btn_completed_normal.svg")
const BTN_DONE_PRESSED := preload("res://assets/images/calendar/btn_completed_pressed.svg")
const BTN_DONE_FOCUS := preload("res://assets/images/calendar/btn_completed_focus.svg")
const BTN_PLAY_NORMAL := preload("res://assets/images/calendar/btn_primary_normal.svg")
const BTN_PLAY_PRESSED := preload("res://assets/images/calendar/btn_primary_pressed.svg")
const BTN_PLAY_FOCUS := preload("res://assets/images/calendar/btn_primary_focus.svg")

## Lề trái của tiêu đề: bản KHÔNG badge đọc từ scene (`Title.offset_left`), bản CÓ badge đọc từ
## metadata `title_left` của node `Tag` — chỉnh trong Inspector, script không hard-code toạ độ.
var _title_left_plain := 0.0
var _title_left_badge := 0.0

@onready var box: TextureRect = $Item/Check/Box
@onready var status_label: Label = $Item/Check/Status
@onready var reward_label: Label = $Item/Check/Reward
@onready var tag: TextureRect = $Item/Text/TitleContainer/Tag
@onready var tag_label: Label = $Item/Text/TitleContainer/Tag/Label
@onready var title_label: Label = $Item/Text/TitleContainer/Title
@onready var desc_label: Label = $Item/Text/Desc
@onready var progress_label: Label = $Item/Text/Progress
@onready var action_button: TextureButton = $Item/Action
@onready var action_label: Label = $Item/Action/Label

## Vị trí nhiệm vụ trong ngày (0..3)
var index: int = 0
var _pending: Dictionary = {}
var _has_pending := false


func _ready() -> void:
	if title_label != null:
		_title_left_plain = title_label.offset_left
	_title_left_badge = _read_badge_title_left()
	if action_button != null:
		action_button.pressed.connect(_on_action_pressed)
	if _has_pending:
		_has_pending = false
		_apply(_pending)


## Lề trái của tiêu đề khi hàng có badge SPECIAL MODE — lấy từ scene (Inspector > Tag > Metadata)
func _read_badge_title_left() -> float:
	if tag == null:
		return _title_left_plain
	return float(tag.get_meta("title_left", _title_left_plain))


## Nạp nội dung 1 nhiệm vụ.
## info = { title, desc, progress, reward (Xu thưởng), done, special, playable }
func setup(p_index: int, info: Dictionary) -> void:
	index = p_index
	if not is_node_ready():
		_pending = info
		_has_pending = true
		return
	_apply(info)


func _apply(info: Dictionary) -> void:
	if info.is_empty() or action_button == null:
		return
	var done := bool(info.get("done", false))
	var special := bool(info.get("special", false))
	var playable := bool(info.get("playable", true))

	title_label.text = str(info.get("title", ""))
	desc_label.text = str(info.get("desc", ""))
	progress_label.text = str(info.get("progress", ""))
	progress_label.theme_type_variation = &"DailyTaskProgress" if done else &"DailyTaskProgressTodo"
	reward_label.text = tr("STR_DAILY_REWARD_COINS").format([int(info.get("reward", 0))])

	# Ô tick + trạng thái (đã xong / chưa xong)
	box.texture = BOX_DONE if done else BOX_TODO
	status_label.text = tr("STR_STATUS_DONE_SHORT") if done else tr("STR_DAILY_TODO_FORMAT").format([0, 1])
	status_label.theme_type_variation = &"DailyTaskStatusDone" if done else &"DailyTaskStatusTodo"

	# Badge SPECIAL MODE (chỉ hàng nhiệm vụ của maze đặc biệt)
	tag.visible = special
	if special:
		tag_label.text = tr("STR_TAG_SPECIAL_MODE")
	title_label.offset_left = _title_left_badge if special else _title_left_plain

	# Nút hành động: đã xong -> "HOÀN THÀNH" (vẫn bấm để chơi lại), chưa xong -> "VÀO CHƠI"
	if done:
		action_button.texture_normal = BTN_DONE_NORMAL
		action_button.texture_pressed = BTN_DONE_PRESSED
		action_button.texture_hover = BTN_DONE_PRESSED
		action_button.texture_focused = BTN_DONE_FOCUS
		action_button.texture_disabled = BTN_DONE_NORMAL
		action_label.theme_type_variation = &"DailyActionIdle"
		action_label.text = tr("STR_BTN_COMPLETE")
	else:
		action_button.texture_normal = BTN_PLAY_NORMAL
		action_button.texture_pressed = BTN_PLAY_PRESSED
		action_button.texture_hover = BTN_PLAY_PRESSED
		action_button.texture_focused = BTN_PLAY_FOCUS
		action_button.texture_disabled = BTN_PLAY_NORMAL
		action_label.theme_type_variation = &"DailyActionPrimary"
		action_label.text = tr("STR_BTN_PLAY_NOW")

	# Ngày chưa mở / bỏ lỡ: chỉ xem, không bấm chơi được
	action_button.disabled = not playable
	action_button.focus_mode = Control.FOCUS_ALL if playable else Control.FOCUS_NONE
	modulate = Color(1, 1, 1, 1.0) if playable else Color(1, 1, 1, 0.66)


func _on_action_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	action_pressed.emit(index)
