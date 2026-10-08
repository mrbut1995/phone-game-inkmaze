class_name DailyMissionRow
extends Control
## ============================================================================
## Component: 1 hàng nhiệm vụ trong bảng Mission của màn Daily
## (nodes/daily/mission_row.tscn — khớp mockup daily_mission.svg)
##
## Mỗi hàng 980x110 hiển thị ĐÚNG 2 DÒNG chữ:
##   - Dòng 1 (Title): tên Challenge của ngày (hàng challenge) hoặc "TRÒ CHƠI n · MAZE THƯỜNG"
##   - Dòng 2 (Progress): "Tiến độ: x/1"
## Cột trái (Status): ô tick + Xu thưởng.
##   - Nút: chưa xong = "VÀO CHƠI ›" (xanh) · đã xong = "HOÀN THÀNH" (xám, bấm để chơi lại)
##
## MỌI tham số (node · texture · độ mờ khi khoá) chỉnh TRONG `mission_row.tscn` —
## script chỉ export var, KHÔNG hard-code; binding khai trong scene.
## ============================================================================

signal action_pressed(index: int)

## Node binding: khai `node_paths` + NodePath trong `mission_row.tscn`
@export var box: TextureRect = null
@export var reward_label: Label = null
@export var tag: NinePatchRect = null
@export var tag_label: Label = null
@export var title_label: Label = null
@export var progress_label: Label = null
@export var action_button: TextureButton = null
@export var action_label: Label = null
@export var special_section: NinePatchRect = null

## Texture theo trạng thái (gán trong scene) — ô tick + 2 bộ nút Chơi/Hoàn thành
@export var texture_box_done: Texture2D = null
@export var texture_box_todo: Texture2D = null
@export var texture_done_normal: Texture2D = null
@export var texture_done_pressed: Texture2D = null
@export var texture_done_focus: Texture2D = null
@export var texture_play_normal: Texture2D = null
@export var texture_play_pressed: Texture2D = null
@export var texture_play_focus: Texture2D = null
## Độ mờ cả hàng khi ngày chưa mở / bỏ lỡ (không bấm chơi được)
@export_range(0.0, 1.0, 0.05) var disabled_alpha: float = 0.66

## Lề trái của tiêu đề: bản KHÔNG badge đọc từ scene (`Title.offset_left`), bản CÓ badge đọc từ
## metadata `title_left` của node `Tag` — chỉnh trong Inspector, script không hard-code toạ độ.
var _title_left_plain := 0.0
var _title_left_badge := 0.0

## Vị trí nhiệm vụ trong ngày (0..3)
var index: int = 0
var _pending: Dictionary = {}
var _has_pending := false


func _ready() -> void:
	if title_label != null:
		_title_left_plain = title_label.offset_left
	_title_left_badge = _read_badge_title_left()
	# Dây `Item/Action.pressed → _on_action_pressed` khai trong `mission_row.tscn` (cùng scene)
	if _has_pending:
		_has_pending = false
		_apply(_pending)


## Lề trái của tiêu đề khi hàng có badge SPECIAL MODE — lấy từ scene (Inspector > Tag > Metadata)
func _read_badge_title_left() -> float:
	if tag == null:
		return _title_left_plain
	return float(tag.get_meta("title_left", _title_left_plain))


## Nạp nội dung 1 nhiệm vụ.
## info = { title, progress, reward (Xu thưởng), done, special, playable }
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

	# ĐÚNG 2 DÒNG: Title (tên Challenge / "TRÒ CHƠI n · MAZE THƯỜNG") + Tiến độ
	title_label.text = str(info.get("title", ""))
	progress_label.text = str(info.get("progress", ""))
	progress_label.theme_type_variation = &"DailyTaskProgress" if done else &"DailyTaskProgressTodo"
	reward_label.text = tr("STR_DAILY_REWARD_COINS").format([int(info.get("reward", 0))])

	# Ô tick: trạng thái xong/chưa xong thể hiện qua icon + dòng Tiến độ
	box.texture = texture_box_done if done else texture_box_todo

	# Badge SPECIAL MODE (chỉ hàng maze đặc biệt)
	tag.visible = special
	special_section.visible = special
	if special:
		tag_label.text = tr("STR_TAG_SPECIAL_MODE")
	title_label.offset_left = _title_left_badge if special else _title_left_plain

	# Nút hành động: đã xong -> "HOÀN THÀNH" (vẫn bấm để chơi lại), chưa xong -> "VÀO CHƠI"
	if done:
		action_button.texture_normal = texture_done_normal
		action_button.texture_pressed = texture_done_pressed
		action_button.texture_hover = texture_done_pressed
		action_button.texture_focused = texture_done_focus
		action_button.texture_disabled = texture_done_normal
		action_label.theme_type_variation = &"DailyActionIdle"
		action_label.text = tr("STR_BTN_COMPLETE")
	else:
		action_button.texture_normal = texture_play_normal
		action_button.texture_pressed = texture_play_pressed
		action_button.texture_hover = texture_play_pressed
		action_button.texture_focused = texture_play_focus
		action_button.texture_disabled = texture_play_normal
		action_label.theme_type_variation = &"DailyActionPrimary"
		action_label.text = tr("STR_BTN_PLAY_NOW")

	# Ngày chưa mở / bỏ lỡ: chỉ xem, không bấm chơi được
	action_button.disabled = not playable
	action_button.focus_mode = Control.FOCUS_ALL if playable else Control.FOCUS_NONE
	modulate = Color(1, 1, 1, 1.0) if playable else Color(1, 1, 1, disabled_alpha)


func _on_action_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	action_pressed.emit(index)
