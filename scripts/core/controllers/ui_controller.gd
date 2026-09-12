class_name UIController
extends Node
## ============================================================================
## Controller: Quản lý và điều phối các thành phần giao diện (HUD, Popups).
## ============================================================================

signal continue_requested
signal retry_requested
signal quit_requested
signal home_requested
signal pause_toggled(is_paused: bool)

@export var level_label: Label = null
@export var step_val_label: Label = null
@export var step_max_label: Label = null
@export var time_val_label: Label = null
@export var score_val_label: Label = null

## Popup được instance sẵn trong scenes/game.tscn và gán NodePath qua Inspector.
## Mọi signal button của popup được connect trực tiếp trong .tscn (không connect bằng code).
@export var floor_complete_view: Control = null
@export var game_over_view: Control = null
@export var settings_view: Control = null


# ---------------------------------------------------------------------------
# Handlers cho button của popup (được .tscn gọi trực tiếp)
# ---------------------------------------------------------------------------
func _on_next_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	continue_requested.emit()


func _on_replay_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	retry_requested.emit()


func _on_home_pressed() -> void:
	Sfx.play(Sfx.BTN_WOOD_TAP)
	if settings_view != null:
		settings_view.visible = false
	home_requested.emit()


func _on_resume_pressed() -> void:
	Sfx.play(Sfx.BTN_WOOD_TAP)
	if settings_view != null:
		settings_view.visible = false
	pause_toggled.emit(false)


func toggle_settings() -> void:
	# SFX: gõ thẻ giấy cho nút Pause trên HUD
	Sfx.play(Sfx.BTN_WOOD_TAP)
	if settings_view != null:
		settings_view.visible = not settings_view.visible
		pause_toggled.emit(settings_view.visible)


func update_hud(
	title: String,
	steps_remaining: int,
	max_steps: int,
	elapsed_time: float,
	score: int,
	_extra_info := ""
) -> void:
	if level_label != null:
		level_label.text = title

	if step_val_label != null:
		step_val_label.text = str(steps_remaining)
	if step_max_label != null:
		step_max_label.text = "/%d" % max_steps

	if time_val_label != null:
		var total_sec := int(elapsed_time)
		var mins := total_sec / 60
		var secs := total_sec % 60
		time_val_label.text = "%d:%02d" % [mins, secs]

	if score_val_label != null:
		score_val_label.text = "%05d" % score


func show_floor_complete(
	floor_number: int,
	_moves_used: int,
	_time_sec: float,
	_gained_score: int,
	_bonus_steps: int
) -> void:
	if floor_complete_view != null:
		floor_complete_view.visible = true
		# SFX: con dấu "cộp" lên giấy + 3 ngôi sao reo theo quãng Đồ - Mi - Son
		Sfx.play(Sfx.STAMP_IMPACT)
		_play_star_sequence()
		if floor_complete_view.has_method("show_result"):
			floor_complete_view.call("show_result", floor_number)


func show_game_over(
	floor_reached: int,
	_moves_used: int,
	_elapsed: float
) -> void:
	if game_over_view != null:
		game_over_view.visible = true
		# SFX: tiếng vo tròn tờ giấy nháp ném đi
		Sfx.play(Sfx.GAME_OVER)
		if game_over_view.has_method("show_result"):
			game_over_view.call("show_result", floor_reached)


func hide_overlays() -> void:
	if floor_complete_view != null:
		floor_complete_view.visible = false
	if game_over_view != null:
		game_over_view.visible = false
	if settings_view != null:
		settings_view.visible = false
		pause_toggled.emit(false)

## 3 ngôi sao hiện lần lượt trên popup thắng -> 3 tiếng chuông gỗ cao dần
func _play_star_sequence() -> void:
	for i in 3:
		if not is_inside_tree():
			return
		var tw := create_tween()
		tw.tween_interval(0.45 + i * 0.22)
		tw.tween_callback(func() -> void: Sfx.star_pop(i))
