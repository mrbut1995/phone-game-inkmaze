class_name UIController
extends RefCounted
## ============================================================================
## Controller: Quản lý và điều phối các thành phần giao diện (HUD, Popups).
## ============================================================================

signal continue_requested
signal retry_requested
signal quit_requested
signal home_requested

var level_label: Label = null
var step_val_label: Label = null
var step_max_label: Label = null
var time_val_label: Label = null
var score_val_label: Label = null

var floor_complete_view: Control = null
var game_over_view: Control = null
var settings_view: Control = null


func setup(
	p_level_label: Label,
	p_step_val: Label,
	p_step_max: Label,
	p_time_val: Label,
	p_score_val: Label,
	p_floor_complete: Control = null,
	p_game_over: Control = null,
	p_settings: Control = null
) -> void:
	level_label = p_level_label
	step_val_label = p_step_val
	step_max_label = p_step_max
	time_val_label = p_time_val
	score_val_label = p_score_val
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
		if home_btn is BaseButton:
			home_btn.pressed.connect(func() -> void: home_requested.emit())


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
