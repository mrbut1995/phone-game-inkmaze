class_name GameController
extends Node
## ============================================================================
## Master Controller (Facade / Coordinator): Điều phối toàn bộ luồng game.
## ============================================================================

const INITIAL_STEPS := 15

var game_state: GameState = null

@export var floor_controller: FloorController = null
@export var timer_controller: TimerController = null
@export var grid_controller: GridController = null
@export var ui_controller: UIController = null
@export var tool_controller: ToolController = null
@export var game_mode_controller: GameModeController = null
@export var grid_view: BoardView = null

var _pending_bonus := 0
var _floor_finished := false
var _run_active := false


var game_mode: BaseGameMode:
	get:
		return game_mode_controller.game_mode if game_mode_controller != null else null
	set(value):
		if game_mode_controller != null:
			game_mode_controller.game_mode = value


func _init() -> void:
	game_state = GameState.new()


func set_game_mode(p_mode: BaseGameMode) -> void:
	if game_mode_controller != null:
		game_mode_controller.game_mode = p_mode


func start_new_run() -> void:
	game_state = GameState.new()
	var init_steps: int = game_mode_controller.game_mode.initial_steps if game_mode_controller.game_mode != null else INITIAL_STEPS
	game_state.begin_run(init_steps, game_mode_controller.game_mode.mode_id)
	_run_active = true
	_floor_finished = false

	if timer_controller != null:
		if game_mode_controller.game_mode is TimeAttackGameMode:
			var ta := game_mode_controller.game_mode as TimeAttackGameMode
			timer_controller.start_countdown(ta.time_limit)
		else:
			timer_controller.start_new_run()

	if ui_controller != null:
		ui_controller.hide_overlays()

	_start_floor(1)


func _start_floor(floor_number: int) -> void:
	var maze := floor_controller.setup_floor(floor_number, game_mode_controller.game_mode)
	grid_controller.set_maze(maze)
	if grid_view != null and grid_view.has_method("setup_maze"):
		grid_view.call("setup_maze", maze, game_mode_controller.game_mode)

	_floor_finished = false
	if timer_controller != null:
		timer_controller.start_floor()
	if grid_view != null and grid_view.has_method("set_interaction_enabled"):
		grid_view.call("set_interaction_enabled", true)

	_update_hud()


func _process(delta: float) -> void:
	if not _run_active or timer_controller == null:
		return
	timer_controller.tick(delta)


func _on_time_updated(total_elapsed: float, _floor_elapsed: float) -> void:
	if game_state != null:
		game_state.elapsed_time = total_elapsed
	_update_hud()


func _on_timer_timeout() -> void:
	_game_over()


func _update_hud() -> void:
	if ui_controller == null or game_state == null:
		return
	var extra_info := game_mode_controller.game_mode.get_hud_extra_info() if game_mode_controller.game_mode != null else ""
	var title := game_mode_controller.game_mode.get_hud_floor_title(game_state.floor_number) if game_mode_controller.game_mode != null else "TẦNG %d" % game_state.floor_number
	ui_controller.update_hud(
		title,
		game_state.steps_remaining,
		game_state.max_steps,
		game_state.elapsed_time,
		game_state.score,
		extra_info
	)


func _on_step_consumed(cost: int, hit_hazard: bool) -> void:
	if game_state == null:
		return
	game_state.consume_step(cost)
	if hit_hazard:
		game_state.record_wall_hit()
		if game_mode_controller.game_mode != null and game_mode_controller.game_mode.instant_game_over_on_hazard:
			_game_over.call_deferred()
			return

	_update_hud()
	if game_state.is_out_of_moves():
		_check_game_over.call_deferred()


func _on_wall_hit() -> void:
	pass


func _on_reached_end() -> void:
	if _floor_finished:
		return
	_floor_finished = true
	_complete_floor()


func _complete_floor() -> void:
	if timer_controller != null:
		timer_controller.pause()
	if grid_view != null and grid_view.has_method("set_interaction_enabled"):
		grid_view.call("set_interaction_enabled", false)

	var floor_time: float = timer_controller.floor_elapsed if timer_controller != null else 0.0
	var score_data := game_mode_controller.game_mode.calculate_score(
		game_state.floor_number,
		game_state.steps_remaining,
		floor_time,
		game_state.perfect_floor
	)
	var gained: int = score_data.get("total_gained", 0)
	game_state.add_score(gained)

	_pending_bonus = ScoreCalculator.calculate_bonus_steps(game_state.steps_remaining)

	# SFX: jingle thắng màn; floor hoàn hảo -> thành tích; có thưởng bước -> tiếng đếm hạt gỗ
	Sfx.play(Sfx.LEVEL_WIN)
	if game_state.floor_wall_hits == 0:
		_play_sfx_delayed(Sfx.ACHIEVEMENT, 1.6)
	if _pending_bonus > 0:
		_play_sfx_delayed(Sfx.FLOOR_BONUS, 1.1)

	_mark_daily_completed_if_needed()

	if ui_controller != null:
		ui_controller.show_floor_complete(
			game_state.floor_number,
			game_state.floor_moves,
			floor_time,
			gained,
			_pending_bonus
		)


func _check_game_over() -> void:
	if _floor_finished:
		return
	_game_over()


func _game_over() -> void:
	_run_active = false
	if timer_controller != null:
		timer_controller.stop()
	if grid_view != null and grid_view.has_method("set_interaction_enabled"):
		grid_view.call("set_interaction_enabled", false)

	if ui_controller != null:
		ui_controller.show_game_over(
			game_state.floor_number,
			game_state.total_moves,
			game_state.elapsed_time
		)


func _on_continue_requested() -> void:
	if game_state == null:
		return
	if ui_controller != null:
		ui_controller.hide_overlays()

	if game_mode_controller != null and game_mode_controller.game_mode != null and not game_mode_controller.game_mode.is_endless:
		var gm: Node = get_node_or_null("/root/GameManager")
		if gm != null:
			var stars: int = 3 if game_state.floor_wall_hits == 0 else 2
			gm.call("record_level_clear", int(gm.get("current_level")), stars, game_state.elapsed_time)
			var next_lvl := int(gm.get("current_level")) + 1
			if next_lvl <= 9:
				gm.call("start_level", next_lvl)
			else:
				gm.call("go_to_levels")
		else:
			start_new_run()
		return

	game_state.start_next_floor(_pending_bonus)
	_start_floor(game_state.floor_number)


func _on_retry_requested() -> void:
	if ui_controller != null:
		ui_controller.hide_overlays()
	start_new_run()


func _on_home_requested() -> void:
	if ui_controller != null:
		ui_controller.hide_overlays()
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm != null:
		gm.call("go_to_main_menu")
	else:
		get_tree().change_scene_to_file("res://scenes/main.tscn")


# ---------------------------------------------------------------------------
# Public Actions từ Game Screen Buttons
# ---------------------------------------------------------------------------
func restart_run() -> void:
	# SFX: gõ thẻ giấy cho nút phụ (Restart trên HUD)
	Sfx.play(Sfx.BTN_WOOD_TAP)
	_on_retry_requested()


func undo() -> void:
	if grid_controller != null and grid_controller.undo_last_move():
		# SFX: tiếng gôm tẩy quẹt trên giấy
		Sfx.play(Sfx.UNDO)
		if game_state != null:
			game_state.refund_step(1)
			_update_hud()


func hint() -> void:
	if grid_controller != null:
		# SFX: chuông gió khi bấm Gợi ý
		Sfx.play(Sfx.HINT)
		grid_controller.give_hint()


func _on_pause_toggled(is_paused: bool) -> void:
	if timer_controller != null:
		if is_paused:
			timer_controller.pause()
		else:
			timer_controller.resume()


# ---------------------------------------------------------------------------
# Helpers SFX & Daily
# ---------------------------------------------------------------------------
func _play_sfx_delayed(sfx_name: String, delay: float) -> void:
	if not is_inside_tree():
		return
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.tween_callback(func() -> void: Sfx.play(sfx_name))


## Đánh dấu ngày Daily đã hoàn thành (nếu ván đang chơi là 1 Daily Challenge Mode)
func _mark_daily_completed_if_needed() -> void:
	if game_state == null or not GameManagerClass.DAILY_MODES.has(game_state.mode_id):
		return
	var gm: Variant = get_node_or_null("/root/GameManager")
	var dm: Variant = get_node_or_null("/root/DailyManager")
	if gm == null or dm == null:
		return
	dm.call("mark_completed", int(gm.get("selected_daily_day")))
