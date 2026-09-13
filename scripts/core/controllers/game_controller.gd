class_name GameController
extends Node
## ============================================================================
## Master Controller (Facade / Coordinator): Điều phối toàn bộ luồng game.
## ============================================================================

const INITIAL_STEPS := 15
## Số bước thưởng khi xem quảng cáo hồi sinh (khớp mockup popup_game_over.svg)
const REVIVE_BONUS_STEPS := 3

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


## Bắt đầu ván mới. `start_floor` là màn/tầng xuất phát (Play mode: id màn đang chọn).
func start_new_run(start_floor := 1) -> void:
	game_state = GameState.new()
	_run_active = true
	_floor_finished = false

	var mode := game_mode_controller.game_mode
	if ui_controller != null:
		ui_controller.hide_overlays()

	if timer_controller != null:
		if mode is TimeAttackGameMode:
			timer_controller.start_countdown((mode as TimeAttackGameMode).time_limit)
		else:
			timer_controller.start_new_run()

	# Nạp màn trước để GameMode cập nhật `initial_steps` theo LevelData
	_start_floor(start_floor)

	# Sau đó mới khởi tạo state: đúng số bước thiết kế và đúng màn xuất phát
	game_state.begin_run(
		mode.initial_steps if mode != null else INITIAL_STEPS,
		mode.mode_id if mode != null else "dungeon",
		start_floor
	)
	_update_hud()


func _start_floor(floor_number: int) -> void:
	var maze := floor_controller.setup_floor(floor_number, game_mode_controller.game_mode)
	grid_controller.set_maze(maze)
	if grid_view != null and grid_view.has_method("setup_maze"):
		grid_view.call("setup_maze", maze, game_mode_controller.game_mode)

	_floor_finished = false
	if game_state != null:
		game_state.floor_number = floor_number
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
	if ui_controller != null:
		ui_controller.set_run_info({
			"floor": game_state.floor_number,
			"steps_left": game_state.steps_remaining,
			"steps_max": game_state.max_steps,
			"mode_name": game_mode_controller.game_mode.mode_id if game_mode_controller.game_mode != null else "dungeon",
		})
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
		ui_controller.show_floor_complete({
			"level": game_state.floor_number,
			"floor": game_state.floor_number,
			"next_floor": game_state.floor_number + 1,
			"grid": "5×5",
			"time": floor_time,
			"steps_used": game_state.floor_moves,
			"steps_max": game_state.max_steps,
			"wall_hits": game_state.floor_wall_hits,
			"score": game_state.score,
			"stars": 3 if game_state.floor_wall_hits == 0 else 2,
			"bonus_steps": _pending_bonus,
			"steps_bonus": _pending_bonus,
			"base_score": score_data.get("base_score", 0),
			"move_bonus": score_data.get("move_bonus", 0),
			"perfect_bonus": score_data.get("perfect_bonus", 0),
			"total_score": game_state.score,
			"endless": game_mode_controller.game_mode != null and game_mode_controller.game_mode.is_endless,
		})


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
		ui_controller.show_game_over({
			"floor": game_state.floor_number,
			"progress": _maze_progress_percent(),
			"wall_hits": game_state.floor_wall_hits,
			"score": game_state.score,
		})


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
			if _level_exists(next_lvl):
				gm.call("start_level", next_lvl)
			else:
				gm.call("go_to_levels")
		else:
			# Không có GameManager: chơi lại đúng màn hiện tại thay vì về màn 1
			start_new_run(current_floor())
		return

	game_state.start_next_floor(_pending_bonus)
	_start_floor(game_state.floor_number)


func _on_retry_requested() -> void:
	if ui_controller != null:
		ui_controller.hide_overlays()
	# Chơi lại ĐÚNG màn đang chơi: trước đây gọi start_new_run() không tham số
	# -> luôn nhảy về màn 1 (bug báo cáo từ người chơi).
	start_new_run(current_floor())


## Màn/tầng hiện tại của ván đang chơi (Retry / Chơi lại luôn dùng giá trị này).
func current_floor() -> int:
	if game_state != null and game_state.floor_number >= 1:
		return game_state.floor_number
	# Chưa có ván nào: mode theo màn (Play) thì lấy màn đang chọn trong GameManager
	if game_mode_controller != null and game_mode_controller.game_mode != null:
		if not game_mode_controller.game_mode.is_endless:
			var gm: Node = get_node_or_null("/root/GameManager")
			if gm != null:
				return maxi(int(gm.get("current_level")), 1)
	return 1


## Màn `level_id` có file .tres thật hay không (danh sách màn có thể > 9)
func _level_exists(level_id: int) -> bool:
	var lm: Node = get_node_or_null("/root/LevelManager")
	if lm != null and lm.has_method("has_level"):
		return bool(lm.call("has_level", level_id))
	return level_id <= 9


## Xem quảng cáo để hồi sinh: thưởng thêm bước và chơi lại tầng hiện tại
func _on_revive_requested() -> void:
	var ads: Node = get_node_or_null("/root/AdsManager")
	var rewarded := true
	if ads != null and ads.has_method("show_rewarded"):
		rewarded = bool(ads.call("show_rewarded", "revive"))
	if not rewarded or game_state == null:
		return

	if ui_controller != null:
		ui_controller.hide_overlays()
	game_state.add_bonus_steps(REVIVE_BONUS_STEPS)
	_run_active = true
	_start_floor(game_state.floor_number)


## % quãng đường đã đi trong mê cung hiện tại (0..100)
func _maze_progress_percent() -> int:
	if game_state == null or game_state.floor_moves <= 0:
		return 0
	var max_steps := maxi(game_state.max_steps, 1)
	return clampi(int(round(100.0 * float(game_state.max_steps - game_state.steps_remaining) / float(max_steps))), 0, 100)


func _on_home_requested() -> void:
	if ui_controller != null:
		ui_controller.hide_overlays()
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm != null:
		gm.call("go_to_main_menu")
	else:
		Nav.goto_main()


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
