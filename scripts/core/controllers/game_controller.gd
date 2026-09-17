class_name GameController
extends Node
## ============================================================================
## Master Controller (Facade / Coordinator): Điều phối toàn bộ luồng game.
## ============================================================================

const INITIAL_STEPS := 15
## Số bước thưởng khi xem quảng cáo hồi sinh ở Dungeon Mode (chỉnh được trong Inspector).
## Popup thua lấy giá trị này để hiện đúng trong dòng mô tả nút HỒI SINH.
@export var revive_bonus_steps := 3

var game_state: GameState = null

@export var floor_controller: FloorController = null
@export var timer_controller: TimerController = null
@export var grid_controller: GridController = null
@export var ui_controller: UIController = null
@export var tool_controller: ToolController = null
@export var game_mode_controller: GameModeController = null
@export var challenge_controller: ChallengeController = null
@export var grid_view: BoardView = null

var _pending_bonus := 0
var _floor_finished := false
var _run_active := false
## Chi phí từng bước đã đi (Countdown Cost thu 1..4 bước mỗi ô) — Undo hoàn lại ĐÚNG chi phí
var _move_costs: Array[int] = []
## Đang khoá tương tác vì Countdown Cost hết ngân sách (chỉ mở lại khi VỪA lùi bước để có thêm bước)
var _countdown_locked := false
## Đang ở pha GHI NHỚ (Blind Memory): đồng hồ dừng, tường hiện, popup đếm ngược đang chạy
var _memorize_active := false
## Dữ liệu đầu vào để chấm Thử thách (tái dùng, không cấp phát mỗi frame)
var _challenge_ctx := ChallengeContext.new()


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
		# HUD theo chế độ do GameScene quyết định (xem GameScene._apply_hud_for_mode)

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
	var mode := game_mode_controller.game_mode
	var maze := floor_controller.setup_floor(floor_number, mode)
	grid_controller.set_maze(maze)
	if grid_view != null and grid_view.has_method("setup_maze"):
		grid_view.call("setup_maze", maze, mode)

	# Mode cần can thiệp lên board (Blind Memory hiện tường, Fog of War mở sương) phải chạy SAU khi
	# board đã dựng lại theo maze mới — chạy trước sẽ bị setup_maze() ghi đè (lỗi cũ của Blind Memory).
	if mode != null and grid_view != null:
		mode.on_grid_setup(grid_view, maze)

	_floor_finished = false
	_move_costs.clear()
	if game_state != null:
		game_state.floor_number = floor_number
	# Chốt ngưỡng 3 thử thách của màn/tầng mới (số bước thiết kế đã nạp trong setup_floor)
	if challenge_controller != null:
		challenge_controller.setup_for_floor(
			game_mode_controller.game_mode.initial_steps,
			game_mode_controller.game_mode.current_level_data
		)
	if timer_controller != null:
		timer_controller.start_floor()
	if grid_view != null and grid_view.has_method("set_interaction_enabled"):
		grid_view.call("set_interaction_enabled", true)
	_countdown_locked = false

	_update_hud()

	# Blind Memory: pha GHI NHỚ — hiện toàn bộ tường + popup đếm ngược, đồng hồ đứng yên tới khi hết
	if mode != null and mode.memorize_countdown_seconds > 0:
		_start_memorize_phase(mode.memorize_countdown_seconds)


## Pha GHI NHỚ (Blind Memory): dừng đồng hồ, hiện toàn bộ tường, chạy popup đếm ngược trước khi vào chơi.
## Popup không có nền mờ nên mê cung vẫn nhìn rõ để người chơi ghi nhớ.
func _start_memorize_phase(seconds: int) -> void:
	_memorize_active = true
	if timer_controller != null:
		timer_controller.pause()
	if grid_view != null and grid_view.has_method("reveal_all_walls"):
		grid_view.call("reveal_all_walls")
	if ui_controller != null:
		ui_controller.show_memorize_countdown(seconds)
	else:
		_on_memorize_finished()


## Hết đếm ngược ghi nhớ: ẩn tường, mở lại tương tác và cho đồng hồ chạy tiếp
func _on_memorize_finished() -> void:
	if not _memorize_active:
		return
	_memorize_active = false
	if grid_view != null and grid_view.has_method("hide_all_walls"):
		grid_view.call("hide_all_walls")
	if timer_controller != null:
		timer_controller.resume()
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


## Hết đường đi (Fading Ink: mực phai hết lối) -> thua với lý do riêng để popup hiện đúng tiêu đề
func _on_dead_end() -> void:
	_game_over("dead_end")


func _update_hud() -> void:
	if ui_controller == null or game_state == null:
		return
	var mode: BaseGameMode = game_mode_controller.game_mode if game_mode_controller != null else null
	var extra_info := game_mode_controller.game_mode.get_hud_extra_info() if game_mode_controller.game_mode != null else ""
	var title := game_mode_controller.game_mode.get_hud_floor_title(game_state.floor_number) if game_mode_controller.game_mode != null else "TẦNG %d" % game_state.floor_number
	var subtitle := game_mode_controller.game_mode.get_hud_subtitle(game_state.floor_number) if game_mode_controller.game_mode != null else ""
	var running := _run_active and not _floor_finished
	# Countdown Cost: hết ngân sách -> KHOÁ di chuyển (người chơi phải lùi bước mới đi tiếp được).
	# LƯU Ý: chỉ MỞ LẠI khi vừa hết khoá do ngân sách — KHÔNG bật tuỳ tiện, kẻo ghi đè khoá
	# của hệ thống khác (VD pha GHI NHỚ của Blind Memory đang khoá tương tác).
	var countdown_blocked := running and mode != null and mode.mode_id == "countdown_cost" \
			and game_state.is_out_of_moves()
	if grid_view != null and grid_view.has_method("set_interaction_enabled"):
		if countdown_blocked:
			grid_view.call("set_interaction_enabled", false)
		elif running and _countdown_locked:
			grid_view.call("set_interaction_enabled", true)
	_countdown_locked = countdown_blocked
	# Sum Path: tổng đã vượt mục tiêu (điều kiện "<" hoặc "=") -> nút CHƠI LẠI dưới thanh nút.
	var replay_visible := running and mode != null and mode.has_method("is_unwinnable") \
			and bool(mode.call("is_unwinnable"))
	if ui_controller != null:
		ui_controller.set_run_info({
			"floor": game_state.floor_number,
			"steps_left": game_state.steps_remaining,
			"steps_max": game_state.max_steps,
			"mode_name": mode.mode_id if mode != null else "dungeon",
			"undo_highlight": countdown_blocked,
			"replay_visible": replay_visible,
		})
	ui_controller.update_hud(
		title,
		subtitle,
		game_state.steps_remaining,
		game_state.elapsed_time,
		game_state.floor_number,
		extra_info,
		game_mode_controller.game_mode,
		game_state.floor_moves
	)
	# Cập nhật trạng thái sống của các thử thách (chưa chốt Sao khi đang chơi)
	if challenge_controller != null:
		var floor_time: float = timer_controller.floor_elapsed if timer_controller != null else game_state.elapsed_time
		_challenge_ctx.set_values(
			game_state,
			game_mode_controller.game_mode,
			grid_controller.maze if grid_controller != null else null,
			grid_controller.path if grid_controller != null else [],
			floor_time,
			false
		)
		challenge_controller.refresh(_challenge_ctx)


func _on_step_consumed(cost: int, hit_hazard: bool) -> void:
	if game_state == null:
		return
	game_state.consume_step(cost)
	# Nhớ chi phí bước ĐI ĐƯỢC để Undo hoàn lại đúng (Countdown Cost: mỗi ô 1..4 bước)
	if not hit_hazard:
		_move_costs.append(cost)
	if hit_hazard:
		game_state.record_wall_hit()
		# Chế độ thua-ngay (Play / Daily Classic / Minesweeper...) -> mở popup thua.
		# Chế độ có LƯỢT THỬ LẠI (Fog of War): trừ 1 lượt, hết lượt mới thua.
		if game_mode_controller.game_mode != null and game_mode_controller.game_mode.register_hazard():
			_game_over.call_deferred()
			return

	_update_hud()
	# Chỉ Dungeon Mode mới thua vì HẾT BƯỚC; các chế độ khác không giới hạn số bước.
	if game_state.is_out_of_moves():
		var endless := game_mode_controller.game_mode != null and game_mode_controller.game_mode.is_endless
		if endless:
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

	_report_to_archivements(true, floor_time)

	# Chốt 3 thử thách của màn/tầng -> số Sao (1 thử thách hoàn thành = 1 Sao)
	var challenge_rows: Array[Dictionary] = []
	var stars := 0
	if challenge_controller != null:
		_challenge_ctx.final = true
		challenge_controller.refresh(_challenge_ctx)
		challenge_rows = challenge_controller.rows()
		stars = challenge_controller.stars()

	# Daily: chốt NHIỆM VỤ của ngày (rỗng nếu ván này không phải ván Daily)
	var daily := _complete_daily_missions(challenge_rows)

	if ui_controller != null:
		var next_available := true
		var gm_node: Node = get_node_or_null("/root/GameManager")
		if gm_node != null and daily.is_empty():
			# Còn màn kế tiếp TRONG CÙNG CHƯƠNG và chương đó đã mở -> nút "MÀN KẾ TIẾP",
			# hết chương (hoặc chương sau chưa mở) -> nút "CHỌN CHƯƠNG" (mở màn Chọn Chương)
			var next_in_chapter := int(gm_node.call(
				"next_level_in_chapter", int(gm_node.get("current_level"))))
			next_available = next_in_chapter > 0 and bool(gm_node.call(
				"is_chapter_unlocked", int(gm_node.call("chapter_of_level", next_in_chapter))))
		ui_controller.show_floor_complete({
			"level": game_state.floor_number,
			"floor": game_state.floor_number,
			"next_floor": game_state.floor_number + 1,
			"next_available": next_available,
			"grid": "5×5",
			"time": floor_time,
			"steps_used": game_state.floor_moves,
			"steps_max": game_state.max_steps,
			"wall_hits": game_state.floor_wall_hits,
			"score": game_state.score,
			"stars": stars,
			"challenges": challenge_rows,
			"bonus_steps": _pending_bonus,
			"steps_bonus": _pending_bonus,
			"base_score": score_data.get("base_score", 0),
			"move_bonus": score_data.get("move_bonus", 0),
			"perfect_bonus": score_data.get("perfect_bonus", 0),
			"total_score": game_state.score,
			"endless": game_mode_controller.game_mode != null and game_mode_controller.game_mode.is_endless,
			"daily": not daily.is_empty(),
			"daily_day": int(daily.get("day", 1)),
			"daily_variant": str(daily.get("variant", "")),
			"daily_mode_id": str(daily.get("mode_id", "")),
			"daily_mode_name": str(daily.get("mode_name", "")),
			"daily_coins": int(daily.get("coins", 0)),
			"daily_missions_done": int(daily.get("missions_done", 0)),
			"daily_missions_total": int(daily.get("missions_total", 4)),
			"daily_day_coins": int(daily.get("day_coins", 0)),
			"daily_day_reward_max": int(daily.get("day_reward_max", 0)),
		})


func _check_game_over() -> void:
	if _floor_finished:
		return
	_game_over()


## Kết thúc ván (thua). `reason` = lý do để popup hiện đúng tiêu đề:
## "" = thua thường (đâm tường/hết bước/hết giờ) · "dead_end" = hết đường đi (Fading Ink).
func _game_over(reason := "") -> void:
	# Nhiều nguồn có thể gọi cùng lúc (hết giờ + đâm tường + hết bước) -> chỉ xử lý 1 lần,
	# nếu không popup thua bị MỞ LẠI giữa lúc đang mở và bị tween đóng cũ xoá mất.
	if not _run_active:
		return
	_run_active = false
	if timer_controller != null:
		timer_controller.stop()
	if grid_view != null and grid_view.has_method("set_interaction_enabled"):
		grid_view.call("set_interaction_enabled", false)
	var utc_time = Time.get_datetime_string_from_system(true)
	print("GAME_OVER because %s time = %s" % [reason,utc_time])
	# Chốt 3 thử thách -> popup thua hiển thị trạng thái + số Sao đã đạt
	var challenge_rows: Array[Dictionary] = []
	var stars := 0
	var floor_time: float = timer_controller.floor_elapsed if timer_controller != null else 0.0
	if challenge_controller != null and game_state != null:
		_challenge_ctx.set_values(
			game_state,
			game_mode_controller.game_mode,
			grid_controller.maze if grid_controller != null else null,
			grid_controller.path if grid_controller != null else [],
			floor_time,
			true
		)
		challenge_controller.refresh(_challenge_ctx)
		challenge_rows = challenge_controller.rows()
		stars = challenge_controller.stars()
	_report_to_archivements(false, floor_time)

	var mode: BaseGameMode = game_mode_controller.game_mode
	if ui_controller != null:
		ui_controller.show_game_over({
			"floor": game_state.floor_number,
			"progress": _maze_progress_percent(),
			"wall_hits": game_state.floor_wall_hits,
			"score": game_state.score,
			"steps_left": game_state.steps_remaining,
			"steps_max": game_state.max_steps,
			"revive_steps": revive_bonus_steps,
			"max_retries": mode.max_retries if mode != null else 0,
			"retries_left": mode.retries_left if mode != null else 0,
			"stars": stars,
			"challenges": challenge_rows,
			"time": floor_time,
			"reason": reason,
			"endless": game_mode_controller.game_mode != null and game_mode_controller.game_mode.is_endless,
		})


func _on_continue_requested() -> void:
	if game_state == null:
		return
	if ui_controller != null:
		ui_controller.hide_overlays()

	if game_mode_controller != null and game_mode_controller.game_mode != null and not game_mode_controller.game_mode.is_endless:
		var gm: Node = get_node_or_null("/root/GameManager")
		if gm != null:
			var stars: int = challenge_controller.stars() if challenge_controller != null else 0
			var current := int(gm.get("current_level"))
			gm.call("record_level_clear", current, stars, game_state.elapsed_time)
			# CHỈ đi tiếp trong cùng chương (và chương đó phải đã mở); hết chương -> màn Chọn Chương
			var next_lvl := int(gm.call("next_level_in_chapter", current))
			if next_lvl > 0 and bool(gm.call("can_play_level", next_lvl)):
				gm.call("start_level", next_lvl)
			else:
				gm.call("go_to_chapters")
		else:
			# Không có GameManager: chơi lại đúng màn hiện tại thay vì về màn 1
			start_new_run(current_floor())
		return

	game_state.start_next_floor(_pending_bonus)
	_start_floor(game_state.floor_number)


func _on_retry_requested() -> void:
	if ui_controller != null:
		ui_controller.hide_overlays()
	start_new_run(retry_start_floor())


## Tầng/màn bắt đầu khi người chơi bấm "Chơi lại" (popup thua · popup thắng · nút Restart HUD):
## - Dungeon (endless): **TẦNG 1** — chơi lại là mở ván mới hoàn toàn (không giữ tầng hiện tại).
## - Play/Level và các mode khác: chơi lại **ĐÚNG màn đang chơi** (bug cũ: luôn nhảy về màn 1).
func retry_start_floor() -> int:
	if game_mode_controller != null and game_mode_controller.game_mode != null \
			and game_mode_controller.game_mode.is_endless:
		return 1
	return current_floor()


## Màn/tầng hiện tại của ván đang chơi (các mode KHÔNG endless dùng giá trị này khi chơi lại).
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


## Xem quảng cáo để hồi sinh.
## - Dungeon Mode: thua vì hết bước -> cộng thêm bước rồi chơi tiếp Tầng hiện tại.
## - Play/Level Mode: thua vì đâm tường -> QUAY LẠI BƯỚC TRƯỚC ĐÓ (undo bước vừa đi),
##   không cộng thêm bước vì chế độ này không giới hạn bước (xem Design.md 5.10).
func _on_revive_requested() -> void:
	var ads: Node = get_node_or_null("/root/AdsManager")
	var rewarded := true
	if ads != null and ads.has_method("show_rewarded"):
		rewarded = bool(ads.call("show_rewarded", "revive"))
	if not rewarded or game_state == null:
		return
	revive_run()


## Áp dụng phần thưởng hồi sinh (tách riêng để test được khi AdsManager còn là stub).
func revive_run() -> void:
	if game_state == null:
		return
	if ui_controller != null:
		ui_controller.hide_overlays()

	var endless := game_mode_controller.game_mode != null and game_mode_controller.game_mode.is_endless
	if endless:
		# Endless (Dungeon): hồi sinh GIỮ NGUYÊN mê cung + vị trí + đường đã đi,
		# chỉ cộng thêm bước và cho chơi tiếp (trước đây tạo lại tầng mới).
		game_state.add_bonus_steps(revive_bonus_steps)
		if timer_controller != null:
			timer_controller.resume()
		if grid_view != null and grid_view.has_method("set_interaction_enabled"):
			grid_view.call("set_interaction_enabled", true)
		_run_active = true
		_floor_finished = false
		_update_hud()
		return

	# Level Mode: lùi nhân vật về ô ngay trước bước vừa rồi
	# Chế độ có LƯỢT THỬ LẠI (Fog of War): hồi sinh cộng thêm 1 lượt thử để đi tiếp
	if game_mode_controller.game_mode != null:
		game_mode_controller.game_mode.on_revive()
	if grid_controller != null and grid_controller.undo_last_move():
		game_state.refund_step(1)
	# Đồng bộ hiển thị của mode theo vị trí vừa hồi sinh (Fog of War: mở sương quanh ô hiện tại)
	if grid_controller != null and grid_view != null and game_mode_controller.game_mode != null:
		game_mode_controller.game_mode.on_respawned(
			grid_view, grid_controller.current_pos, grid_controller.maze)
	# Hoàn lại luôn bước đã mất cho lần đâm tường (sau khi hồi sinh nước đi đó coi như chưa xảy ra)
	game_state.refund_step(1)
	# Hiện lại đúng đoạn tường vừa đâm để người chơi thấy rõ chỗ vừa va vào
	if grid_controller != null:
		grid_controller.reveal_last_hazard_wall()
	if timer_controller != null:
		timer_controller.resume()
	if grid_view != null and grid_view.has_method("set_interaction_enabled"):
		grid_view.call("set_interaction_enabled", true)
	_run_active = true
	_floor_finished = false
	_update_hud()


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


## Popup thắng Daily: người chơi bấm "VỀ DAILY" -> quay lại màn Daily
## (chọn ngày để chinh phục maze còn lại / xem lại nhiệm vụ)
func _on_daily_requested() -> void:
	if ui_controller != null:
		ui_controller.hide_overlays()
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm != null:
		gm.call("go_to_daily")
	else:
		Nav.goto_daily()


## Báo kết quả màn/tầng cho Sổ tay thành tựu (Archivement) — thắng hoặc thua.
## Số liệu tích luỹ (tầng sâu nhất, số ván thắng, gợi ý/hoàn tác...) do ArchivementManager ghi nhận.
func _report_to_archivements(won: bool, floor_time: float) -> void:
	if game_state == null or game_mode_controller.game_mode == null:
		return
	if _is_debug_run():
		return                      # ván test từ Debug Console không tính vào danh hiệu
	var mode := game_mode_controller.game_mode
	Archivement.notify_run_result({
		"mode_id": mode.mode_id,
		"won": won,
		"endless": mode.is_endless,
		"floor": game_state.floor_number,
		"score": game_state.score,
		"elapsed": floor_time,
		"wall_hits": game_state.floor_wall_hits,
		"hints_used": game_state.hints_used,
		"undos_used": game_state.undos_used,
		"hardcore": str(mode.difficulty).to_lower() == "hardcore",
	})


# ---------------------------------------------------------------------------
# Public Actions từ Game Screen Buttons
# ---------------------------------------------------------------------------
func restart_run() -> void:
	# SFX: gõ thẻ giấy cho nút phụ (Restart trên HUD)
	Sfx.play(Sfx.BTN_WOOD_TAP)
	_on_retry_requested()


## Mở popup HƯỚNG DẪN của chế độ đang chơi (nút "?" cạnh nút Restart trên HUD).
## Mỗi chế độ có scene hướng dẫn riêng trong nodes/popups/instruction/ (3 trang).
## Đồng hồ đứng trong lúc xem hướng dẫn để không mất thời gian oan — đóng popup thì chạy lại.
const INSTRUCTION_SCENES := {
	"play": "normal_maze",
	"daily_classic": "normal_maze",
	"time_attack": "time_attack",
	"dungeon": "dungeon",
	"minesweeper": "minesweeper",
	"sum_path": "sumpath",
	"countdown_cost": "countdowncost",
	"blind_memory": "blindmemory",
	"fog_of_war": "fog_of_war",
	"fading_ink": "fadingink",
}
const INSTRUCTION_FALLBACK := "normal_maze"


func open_instruction() -> void:
	# SFX: gõ thẻ giấy cho nút phụ (Hướng dẫn trên HUD)
	Sfx.play(Sfx.BTN_WOOD_TAP)
	var mode: BaseGameMode = game_mode
	var mode_id := mode.mode_id if mode != null else ""
	var scene_name: String = INSTRUCTION_SCENES.get(mode_id, INSTRUCTION_FALLBACK)
	var popup := Popups.open_path("res://nodes/popups/instruction/%s.tscn" % scene_name,
			{"mode_id": mode_id})
	if popup == null:
		return
	if not popup.closed.is_connected(_on_instruction_closed):
		popup.closed.connect(_on_instruction_closed)
	if timer_controller != null:
		timer_controller.pause()


## Đóng popup HƯỚNG DẪN: chạy đồng hồ lại (nếu vẫn trong ván và không còn popup nào khác)
func _on_instruction_closed() -> void:
	if timer_controller == null or not _run_active:
		return
	if Popups.has_open():
		return
	timer_controller.resume()


func undo() -> void:
	if grid_controller != null and grid_controller.undo_last_move():
		# SFX: tiếng gôm tẩy quẹt trên giấy
		Sfx.play(Sfx.UNDO)
		if game_state != null:
			# Hoàn lại ĐÚNG chi phí bước vừa đi (Countdown Cost thu 1..4 bước mỗi ô,
			# các chế độ khác luôn là 1 -> giống hành vi cũ)
			var refund := 1
			if not _move_costs.is_empty():
				refund = _move_costs.pop_back()
			game_state.refund_step(refund)
			game_state.undos_used += 1     # thử thách "không dùng hoàn tác"
			_update_hud()


func hint() -> void:
	if grid_controller != null:
		# SFX: chuông gió khi bấm Gợi ý
		Sfx.play(Sfx.HINT)
		grid_controller.give_hint()
		if game_state != null:
			game_state.hints_used += 1     # thử thách "không dùng gợi ý"


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


## Chốt NHIỆM VỤ Daily sau khi thắng ván:
## - Maze THƯỜNG ("classic"): 3 thử thách của ván chính là nhiệm vụ 0..2 của ngày.
## - Maze ĐẶC BIỆT ("special"): hoàn thành ván = nhiệm vụ 3 của ngày.
## Trả về Dictionary mô tả kết quả (RỖNG nếu ván này không phải ván Daily).
func _complete_daily_missions(challenge_rows: Array) -> Dictionary:
	var gm: Variant = get_node_or_null("/root/GameManager")
	var dm: Variant = get_node_or_null("/root/DailyManager")
	if gm == null or dm == null or _is_debug_run():
		return {}
	var variant := str(gm.get("daily_variant"))
	if variant.is_empty():
		return {}

	var day := maxi(int(gm.get("selected_daily_day")), 1)
	var coins := 0
	if variant == "classic":
		var flags: Array[bool] = []
		for i in 3:
			var done := false
			if i < challenge_rows.size() and challenge_rows[i] is Dictionary:
				done = bool((challenge_rows[i] as Dictionary).get("done", false))
			flags.append(done)
		coins = int(dm.call("complete_day_missions", day, flags))
	else:
		# Nhiệm vụ cuối cùng trong ngày = nhiệm vụ của maze đặc biệt
		var special_index := maxi(int(dm.call("mission_count")) - 1, 0)
		coins = int(dm.call("complete_day_mission", day, special_index))

	var mode_id := ""
	var mode_name := ""
	if game_mode_controller != null and game_mode_controller.game_mode != null:
		mode_id = game_mode_controller.game_mode.mode_id
		mode_name = game_mode_controller.game_mode.mode_name
	return {
		"day": day,
		"variant": variant,
		"mode_id": mode_id,
		"mode_name": mode_name,
		"coins": coins,
		"missions_done": int(dm.call("get_day_missions", day)),
		"missions_total": int(dm.call("mission_count")),
		"day_coins": int(dm.call("day_coins_earned", day)),
		"day_reward_max": int(dm.call("day_reward_max")),
		"completed_day": bool(dm.call("is_completed", day)),
	}


## Ván hiện tại có phải ván TEST mở từ Debug Console? (không ghi tiến trình)
func _is_debug_run() -> bool:
	var gm: Variant = get_node_or_null("/root/GameManager")
	return gm != null and bool(gm.get("debug_run"))
