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

var floor_complete_view: Control = null
var game_over_view: Control = null
var settings_view: Control = null


func setup(
	p_floor_complete: Control = null,
	p_game_over: Control = null,
	p_settings: Control = null
) -> void:
	floor_complete_view = p_floor_complete
	game_over_view = p_game_over
	settings_view = p_settings

	_bind_popups()


func _bind_popups() -> void:
	if floor_complete_view != null:
		var next_btn := floor_complete_view.find_child("Next", true, false)
		if next_btn is BaseButton:
			next_btn.pressed.connect(func() -> void: continue_requested.emit())
		var replay_btn := floor_complete_view.find_child("Replay", true, false)
		if replay_btn is BaseButton:
			replay_btn.pressed.connect(func() -> void: retry_requested.emit())

	if game_over_view != null:
		var retry_btn := game_over_view.find_child("Replay", true, false)
		if retry_btn == null:
			retry_btn = game_over_view.find_child("Retry", true, false)
		if retry_btn is BaseButton:
			retry_btn.pressed.connect(func() -> void: retry_requested.emit())
		var home_btn := game_over_view.find_child("Home", true, false)
		if home_btn == null:
			home_btn = game_over_view.find_child("Menu", true, false)
		if home_btn is BaseButton:
			home_btn.pressed.connect(func() -> void: home_requested.emit())

	if settings_view != null:
		var resume_btn := settings_view.find_child("Resume", true, false)
		if resume_btn is BaseButton:
			resume_btn.pressed.connect(func() -> void:
				settings_view.visible = false
				pause_toggled.emit(false)
			)
		var menu_btn := settings_view.find_child("Menu", true, false)
		if menu_btn is BaseButton:
			menu_btn.pressed.connect(func() -> void:
				settings_view.visible = false
				home_requested.emit()
			)


func toggle_settings() -> void:
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
		if floor_complete_view.has_method("show_result"):
			floor_complete_view.call("show_result", floor_number)


func show_game_over(
	floor_reached: int,
	_moves_used: int,
	_elapsed: float
) -> void:
	if game_over_view != null:
		game_over_view.visible = true
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
