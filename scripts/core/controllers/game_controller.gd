class_name GameController
extends Node
## ============================================================================
## Master Controller (Facade / Coordinator): Điều phối toàn bộ luồng game.
## ============================================================================

const INITIAL_STEPS := 15

var game_state: GameState = null
var game_mode: BaseGameMode = null

var floor_controller: FloorController = null
var timer_controller: TimerController = null
var grid_controller: GridController = null
var ui_controller: UIController = null
var tool_controller: ToolController = null
var grid_view: Control = null

var _pending_bonus := 0
var _floor_finished := false
var _run_active := false


func setup(
	p_grid_controller: GridController,
	p_grid_view: Control,
	p_ui_controller: UIController,
	p_floor_controller: FloorController = null,
	p_timer_controller: TimerController = null,
	p_tool_controller: ToolController = null,
	p_mode: BaseGameMode = null
) -> void:
	grid_controller = p_grid_controller
	grid_view = p_grid_view
	ui_controller = p_ui_controller
	tool_controller = p_tool_controller
	
	game_mode = p_mode if p_mode != null else DungeonGameMode.new()
	floor_controller = p_floor_controller if p_floor_controller != null else FloorController.new()
	timer_controller = p_timer_controller if p_timer_controller != null else TimerController.new()
	game_state = GameState.new()

	if grid_controller != null:
		grid_controller.set_game_mode(game_mode)
		grid_controller.step_consumed.connect(_on_step_consumed)
		grid_controller.wall_hit.connect(_on_wall_hit)
		grid_controller.reached_end.connect(_on_reached_end)

	if timer_controller != null:
		timer_controller.time_updated.connect(_on_time_updated)
		timer_controller.timeout.connect(_on_timer_timeout)

	if ui_controller != null:
		ui_controller.continue_requested.connect(_on_continue_requested)
		ui_controller.retry_requested.connect(_on_retry_requested)
		ui_controller.home_requested.connect(_on_home_requested)


func set_game_mode(p_mode: BaseGameMode) -> void:
	game_mode = p_mode
	if grid_controller != null:
		grid_controller.set_game_mode(game_mode)


func start_new_run() -> void:
	game_state = GameState.new()
	var init_steps: int = game_mode.initial_steps if game_mode != null else INITIAL_STEPS
	game_state.begin_run(init_steps, game_mode.mode_id)
	_run_active = true
	_floor_finished = false

	if timer_controller != null:
		if game_mode is TimeAttackGameMode:
			var ta := game_mode as TimeAttackGameMode
			timer_controller.start_countdown(ta.time_limit)
		else:
			timer_controller.start_new_run()

	if ui_controller != null:
		ui_controller.hide_overlays()

	_start_floor(1)


func _start_floor(floor_number: int) -> void:
	var maze := floor_controller.setup_floor(floor_number, game_mode)
	grid_controller.set_maze(maze)
	if grid_view != null and grid_view.has_method("setup_maze"):
		grid_view.call("setup_maze", maze, game_mode)

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
	var extra_info := game_mode.get_hud_extra_info() if game_mode != null else ""
	var title := game_mode.get_hud_floor_title(game_state.floor_number) if game_mode != null else "TẦNG %d" % game_state.floor_number
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
		if game_mode != null and game_mode.instant_game_over_on_hazard:
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
	var score_data := game_mode.calculate_score(
		game_state.floor_number,
		game_state.steps_remaining,
		floor_time,
		game_state.perfect_floor
	)
	var gained: int = score_data.get("total_gained", 0)
	game_state.add_score(gained)

	_pending_bonus = ScoreCalculator.calculate_bonus_steps(game_state.steps_remaining)

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
	if game_mode != null and not game_mode.is_endless:
		if ui_controller != null:
			ui_controller.hide_overlays()
		start_new_run()
		return

	if ui_controller != null:
		ui_controller.hide_overlays()
	game_state.start_next_floor(_pending_bonus)
	_start_floor(game_state.floor_number)


func _on_retry_requested() -> void:
	if ui_controller != null:
		ui_controller.hide_overlays()
	start_new_run()


func _on_home_requested() -> void:
	if ui_controller != null:
		ui_controller.hide_overlays()
	start_new_run()


# ---------------------------------------------------------------------------
# Public Actions từ Game Screen Buttons
# ---------------------------------------------------------------------------
func restart_run() -> void:
	_on_retry_requested()


func undo() -> void:
	if grid_controller != null and grid_controller.undo_last_move():
		if game_state != null:
			game_state.refund_step(1)
			_update_hud()


func hint() -> void:
	if grid_controller != null:
		grid_controller.give_hint()
