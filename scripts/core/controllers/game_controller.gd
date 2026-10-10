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
@export var mission_controller: MissionController = null
@export var grid_view: BoardView = null

var _pending_bonus := 0
var _floor_finished := false
var _run_active := false

## GIỚI HẠN lượt GỢI Ý / HOÀN TÁC của MỖI MÀN/TẦNG (0 = không giới hạn → HUD ẩn badge PanelLimit).
## Nạp lại ĐẦY ĐỦ mỗi khi vào màn/tầng mới (xem `_start_floor`) — hàng mới của Dungeon cũng
## được cấp lại lượt.
@export var undo_limit := 3
@export var hint_limit := 3
## Số lượt CÒN LẠI của màn hiện tại — HUD hiện trên badge `PanelLimit` của 2 nút (xem ActionBar)
var undo_left := 0
var hint_left := 0
## Chi phí từng bước đã đi (Countdown Cost thu 1..4 bước mỗi ô) — Undo hoàn lại ĐÚNG chi phí
var _move_costs: Array[int] = []
## Đang khoá tương tác vì Countdown Cost hết ngân sách (chỉ mở lại khi VỪA lùi bước để có thêm bước)
var _countdown_locked := false
## CHALLENGE MODE: mốc `floor_elapsed` lúc bắt đầu bước hiện tại (đồng hồ con luật "mỗi bước")
var _ch_step_start := 0.0
## CHALLENGE MODE: số lần QUAY ĐẦU đã dùng của màn (luật "giới hạn quay đầu")
var _ch_backtracks := 0
## Đang ở pha GHI NHỚ (Blind Memory): đồng hồ dừng, tường hiện, popup đếm ngược đang chạy
var _memorize_active := false
## Đang hiện overlay "Hết nước đi" trên bàn (Sum Path / Countdown Cost / Fading Ink)
var _overlay_showing := false
## Dữ liệu đầu vào để chấm Nhiệm vụ (tái dùng, không cấp phát mỗi frame)
var _mission_ctx := MissionContext.new()


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
	_seed_level_run(floor_number)
	var maze := floor_controller.setup_floor(floor_number, mode)
	grid_controller.set_maze(maze)
	if grid_view != null:
		grid_view.setup_maze(maze, mode)

	# Mode cần can thiệp lên board (Blind Memory hiện tường, Fog of War mở sương) phải chạy SAU khi
	# board đã dựng lại theo maze mới — chạy trước sẽ bị setup_maze() ghi đè (lỗi cũ của Blind Memory).
	if mode != null and grid_view != null:
		mode.on_grid_setup(grid_view, maze)

	_floor_finished = false
	_move_costs.clear()
	# Challenge: cấp lại đồng hồ con "mỗi bước" + lượt quay đầu cho màn mới
	_ch_step_start = 0.0
	_ch_backtracks = 0
	# Cấp lại lượt Gợi ý/Hoàn tác cho MÀN mới (Dungeon: mỗi tầng một suất mới)
	undo_left = maxi(undo_limit, 0)
	hint_left = maxi(hint_limit, 0)
	if game_state != null:
		game_state.floor_number = floor_number
	# Chốt ngưỡng 3 nhiệm vụ của màn/tầng mới (số bước thiết kế đã nạp trong setup_floor)
	if mission_controller != null:
		mission_controller.setup_for_floor(
			game_mode_controller.game_mode.initial_steps,
			game_mode_controller.game_mode.current_level_data,
			game_mode_controller.game_mode
		)
	if timer_controller != null:
		timer_controller.start_floor()
	if grid_view != null:
		grid_view.set_interaction_enabled(true)
	_countdown_locked = false
	_overlay_showing = false
	if grid_view != null:
		grid_view.show_no_moves_overlay(false)

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
	if grid_view != null:
		grid_view.reveal_all_walls()
	if ui_controller != null:
		ui_controller.show_memorize_countdown(seconds)
	else:
		_on_memorize_finished()


## Hết đếm ngược ghi nhớ: ẩn tường, mở lại tương tác và cho đồng hồ chạy tiếp
func _on_memorize_finished() -> void:
	if not _memorize_active:
		return
	_memorize_active = false
	if grid_view != null:
		grid_view.hide_all_walls()
	if timer_controller != null:
		timer_controller.resume()
	_update_hud()


func _process(delta: float) -> void:
	if not _run_active or timer_controller == null:
		return
	timer_controller.tick(delta)
	_challenge_tick()


func _on_time_updated(total_elapsed: float, _floor_elapsed: float) -> void:
	if game_state != null:
		game_state.elapsed_time = total_elapsed
	_update_hud()


func _on_timer_timeout() -> void:
	_game_over()


## Hết đường đi (Fading Ink: mực phai hết lối) -> thua với lý do riêng để popup hiện đúng tiêu đề
func _on_dead_end() -> void:
	if _overlay_showing:
		return	# Overlay "Đã hiện" trong _update_hud() trước đó — không mở popup tûa
	_game_over("dead_end")


## Ván đang nằm trong LUỒNG HỌC LẦN ĐẦU (onboarding) không — cờ do TutorialManager giữ.
## Luồng này dẫn người chơi mới qua từng bài học / màn thực hành nên KHÓA các lối thoát:
## nút "?" (game.gd), "Chơi lại" + "Về Menu" (pause.gd), "Về Menu" (gameover_level.gd).
func _guided_run() -> bool:
	var tm: Node = get_node_or_null("/root/TutorialManager")
	return tm != null and bool(tm.get("flow_active"))


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
	if grid_view != null:
		if countdown_blocked:
			grid_view.set_interaction_enabled(false)
		elif running and _countdown_locked:
			grid_view.set_interaction_enabled(true)
	_countdown_locked = countdown_blocked
	# Sum Path / Countdown Cost / Fading Ink: kiểm overlay "Hết nước đi" trên bàn
	var was_overlay := _overlay_showing
	var cur_pos := grid_controller.current_pos if grid_controller != null else Vector2i.ZERO
	var cur_maze := grid_controller.maze if grid_controller != null else null
	var stuck := running and mode != null \
			and mode.is_stuck(cur_pos, cur_maze, game_state.steps_remaining)
	_overlay_showing = stuck
	if grid_view != null:
		grid_view.show_no_moves_overlay(stuck)
	if stuck and not was_overlay:
		if timer_controller != null:
			timer_controller.pause()
		if grid_view != null:
			grid_view.set_interaction_enabled(false)
	elif not stuck and was_overlay:
		if timer_controller != null:
			timer_controller.resume()
		if grid_view != null and running:
			grid_view.set_interaction_enabled(true)
	# Sum Path: tổng đã vượt mục tiêu (điều kiện "<" hoặc "=") -> nút CHƠI LẠI dưới thanh nút.
	var replay_visible := running and mode != null and mode.is_unwinnable()
	if ui_controller != null:
		ui_controller.set_run_info({
			"floor": game_state.floor_number,
			"steps_left": game_state.steps_remaining,
			"steps_max": game_state.max_steps,
			"mode_name": mode.mode_id if mode != null else "dungeon",
			"undo_highlight": countdown_blocked,
			"replay_visible": replay_visible,
			"undo_left": undo_left,
			"undo_max": maxi(undo_limit, 0),
			"hint_left": hint_left,
			"hint_max": maxi(hint_limit, 0),
			"guided": _guided_run(),
		})
	ui_controller.update_hud(
		title,
		subtitle,
		game_state.steps_remaining,
		game_state.elapsed_time,
		game_state.floor_number,
		extra_info,
		game_mode_controller.game_mode,
		game_state.floor_moves,
		_challenge_hud_ctx()
	)
	# Cập nhật trạng thái sống của các nhiệm vụ (chưa chốt Sao khi đang chơi)
	if mission_controller != null:
		var floor_time: float = timer_controller.floor_elapsed if timer_controller != null else game_state.elapsed_time
		_mission_ctx.set_values(
			game_state,
			game_mode_controller.game_mode,
			grid_controller.maze if grid_controller != null else null,
			grid_controller.path if grid_controller != null else [],
			floor_time,
			false
		)
		mission_controller.refresh(_mission_ctx)


func _on_step_consumed(cost: int, hit_hazard: bool) -> void:
	if game_state == null:
		return
	game_state.consume_step(cost)
	# Nhớ chi phí bước ĐI ĐƯỢC để Undo hoàn lại đúng (Countdown Cost: mỗi ô 1..4 bước)
	if not hit_hazard:
		_move_costs.append(cost)
		# Challenge: reset đồng hồ con "mỗi bước" + soi vi phạm (vượt bước · giẫm lại · quay đầu).
		# `grid_controller.path` đã cập nhật vị trí mới TRƯỚC khi signal này bắn ra.
		if _challenge() != null:
			_ch_step_start = timer_controller.floor_elapsed if timer_controller != null else 0.0
			_challenge_after_step()
	if hit_hazard:
		# Challenge: bước vào ô vi phạm luật (hazard "challenge_*") -> thua NGAY,
		# KHÔNG tính là đâm tường (giữ "ván hoàn hảo" + nhiệm vụ không đâm tường).
		var ch := _challenge()
		if ch != null and _is_challenge_hazard():
			_challenge_fail(ch.challenge_id)
			return
		game_state.record_wall_hit()
		# Chế độ thua-ngay (Play / Daily Classic / Minesweeper...) -> mở popup thua.
		# Chế độ có LƯỢT THỬ LẠI (Fog of War): trừ 1 lượt, hết lượt mới thua.
		if game_mode_controller.game_mode != null and game_mode_controller.game_mode.register_hazard():
			_game_over.call_deferred(_hazard_game_over_reason())
			return

	_update_hud()
	# Chỉ Dungeon Mode mới thua vì HẾT BƯỚC; các chế độ khác không giới hạn số bước.
	if game_state.is_out_of_moves():
		var endless := game_mode_controller.game_mode != null and game_mode_controller.game_mode.is_endless
		if endless:
			_check_game_over.call_deferred()


func _on_wall_hit() -> void:
	pass


## Người chơi kéo nối 2 giao điểm để VẼ tường nghi ngờ (active=true) hoặc GỠ tường
## đã vẽ (active=false) — đếm riêng cho số liệu Profiler (Wall Draw / Revert Used).
func _on_wall_toggled_by_player(_is_h: bool, _lattice: Vector2i, active: bool) -> void:
	if game_state == null:
		return
	if active:
		game_state.wall_draws += 1
	else:
		game_state.wall_erases += 1


## Lý do thua khi vừa đâm chướng ngại vật (đi kèm popup thua):
## One Stroke đạp lên Ô ĐÃ ĐI = chất hazard "revisit" -> tiêu đề riêng "ĐI LẠI Ô CŨ!".
func _hazard_game_over_reason() -> String:
	if grid_controller != null and grid_controller.last_hazard_type == "revisit":
		return "revisit"
	return ""


## ---------------------------------------------------------------------------
## CHALLENGE MODE — theo dõi VI PHẠM thử thách (8 luật, xem ChallengeGameMode)
## ---------------------------------------------------------------------------
## Trả về ChallengeGameMode đang bật thử thách (null nếu ván này không phải thử thách)
func _challenge() -> ChallengeGameMode:
	var mode: BaseGameMode = game_mode_controller.game_mode if game_mode_controller != null else null
	var ch := mode as ChallengeGameMode
	if ch != null and ch.is_active():
		return ch
	return null


## VI PHẠM luật thử thách -> thua ngay với `reason` riêng (popup GameOver thử thách).
## Dùng call_deferred vì nhiều nguồn có thể gọi trong cùng khung hình (đi bước + hết giờ)
func _challenge_fail(id: String) -> void:
	_game_over.call_deferred(ChallengeGameMode.fail_reason_for(id))


## Luật "không công cụ": chặn CẢ gợi ý lẫn hoàn tác
func _challenge_blocks_tool() -> bool:
	var ch := _challenge()
	return ch != null and ch.blocks_tool()


## Vừa bước vào ô vi phạm luật thử thách? (hazard_type "challenge_*" do mode phát)
## Dùng để KHÔNG tính đó là "đâm tường" (không phá ván hoàn hảo / nhiệm vụ không đâm tường)
func _is_challenge_hazard() -> bool:
	return grid_controller != null and grid_controller.last_hazard_type.begins_with("challenge_")


## Soi 2 luật có ĐỒNG HỒ mỗi khung hình: đếm ngược tổng + "mỗi bước trong X giây".
## LƯU Ý: KHÔNG dùng TimerController.is_countdown (đổi nghĩa floor_elapsed, phá Nhiệm vụ) —
## chỉ so `floor_elapsed` với hạn mức trong lúc đồng hồ vẫn chạy bình thường.
func _challenge_tick() -> void:
	var ch := _challenge()
	if ch == null or not _run_active or game_state == null or timer_controller == null:
		return
	var elapsed: float = timer_controller.floor_elapsed
	if ch.challenge_id == ChallengeGameMode.COUNTDOWN and elapsed >= float(ch.challenge_param):
		_challenge_fail(ch.challenge_id)
	elif ch.challenge_id == ChallengeGameMode.STEP_TIMER \
			and elapsed - _ch_step_start >= float(ch.challenge_param):
		_challenge_fail(ch.challenge_id)


## Soi 3 luật theo NƯỚC ĐI (gọi ngay sau khi bước thành công — path đã có vị trí mới):
## vượt số bước · đi lại trên đường đã đi · quay đầu quá số lượt.
func _challenge_after_step() -> void:
	var ch := _challenge()
	if ch == null or not _run_active or game_state == null:
		return
	var path: Array[Vector2i] = grid_controller.path if grid_controller != null else []
	match ch.challenge_id:
		ChallengeGameMode.MOVE_LIMIT:
			if game_state.floor_moves > ch.challenge_param:
				_challenge_fail(ch.challenge_id)
		ChallengeGameMode.NO_MOVE_OVERLAPPED:
			if not path.is_empty() and path.count(path[path.size() - 1]) > 1:
				_challenge_fail(ch.challenge_id)
		ChallengeGameMode.BACKTRACK_LIMIT:
			if path.size() >= 3 and path[path.size() - 1] == path[path.size() - 3]:
				_ch_backtracks += 1
				if _ch_backtracks > ch.challenge_param:
					_challenge_fail(ch.challenge_id)


## Dữ liệu khối THỜI GIAN cho ChallengeHUD (rỗng nếu ván này không có thử thách)
func _challenge_hud_ctx() -> Dictionary:
	var ch := _challenge()
	if ch == null or game_state == null:
		return {}
	var elapsed: float = timer_controller.floor_elapsed if timer_controller != null else 0.0
	return ch.hud_state(
		float(ch.challenge_param) - elapsed,
		game_state.floor_moves,
		float(ch.challenge_param) - (elapsed - _ch_step_start),
		ch.challenge_param - _ch_backtracks
	)


func _on_reached_end() -> void:
	if _floor_finished:
		return
	_floor_finished = true
	_complete_floor()


func _complete_floor() -> void:
	if timer_controller != null:
		timer_controller.pause()
	if grid_view != null:
		grid_view.set_interaction_enabled(false)

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
		_play_sfx_delayed(sfx_timer_achievement, Sfx.ACHIEVEMENT, 1.6)
	if _pending_bonus > 0:
		_play_sfx_delayed(sfx_timer_floor_bonus, Sfx.FLOOR_BONUS, 1.1)

	_report_to_archivements(true, floor_time)

	# Chốt 3 nhiệm vụ của màn/tầng -> số Sao (1 nhiệm vụ hoàn thành = 1 Sao)
	var mission_rows: Array[Dictionary] = []
	var stars := 0
	if mission_controller != null:
		_mission_ctx.final = true
		mission_controller.refresh(_mission_ctx)
		mission_rows = mission_controller.rows()
		stars = mission_controller.stars()

	# Daily: chốt NHIỆM VỤ của ngày (rỗng nếu ván này không phải ván Daily)
	var daily := _complete_daily_missions(mission_rows)

	# Challenge: gửi kèm dữ liệu thử thách để UIController mở popup "hoàn thành thử thách"
	var ch := _challenge()
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
			"challenge_id": ch.challenge_id if ch != null else "",
			"challenge_name_key": ch.name_key() if ch != null else "",
			"next_floor": game_state.floor_number + 1,
			"next_available": next_available,
			"grid": "5×5",
			"time": floor_time,
			"steps_used": game_state.floor_moves,
			"steps_max": game_state.max_steps,
			"wall_hits": game_state.floor_wall_hits,
			"score": game_state.score,
			"stars": stars,
			"missions": mission_rows,
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
	# `_floor_finished` = màn đã THẮNG trong khung hình này (VPN thua hoãn lại không được đè lên)
	if not _run_active or _floor_finished:
		return
	_run_active = false
	if timer_controller != null:
		timer_controller.stop()
	if grid_view != null:
		grid_view.set_interaction_enabled(false)
	# Chốt 3 nhiệm vụ -> popup thua hiển thị trạng thái + số Sao đã đạt
	var mission_rows: Array[Dictionary] = []
	var stars := 0
	var floor_time: float = timer_controller.floor_elapsed if timer_controller != null else 0.0
	if mission_controller != null and game_state != null:
		_mission_ctx.set_values(
			game_state,
			game_mode_controller.game_mode,
			grid_controller.maze if grid_controller != null else null,
			grid_controller.path if grid_controller != null else [],
			floor_time,
			true
		)
		mission_controller.refresh(_mission_ctx)
		mission_rows = mission_controller.rows()
		stars = mission_controller.stars()
	_report_to_archivements(false, floor_time)

	var mode: BaseGameMode = game_mode_controller.game_mode
	var ch := _challenge()
	if ui_controller != null:
		ui_controller.show_game_over({
			"floor": game_state.floor_number,
			"challenge_id": ch.challenge_id if ch != null else "",
			"challenge_name_key": ch.name_key() if ch != null else "",
			"progress": _maze_progress_percent(),
			"wall_hits": game_state.floor_wall_hits,
			"score": game_state.score,
			"steps_left": game_state.steps_remaining,
			"steps_max": game_state.max_steps,
			"revive_steps": revive_bonus_steps,
			"max_retries": mode.max_retries if mode != null else 0,
			"retries_left": mode.retries_left if mode != null else 0,
			"revive_desc": mode.revive_desc_key() if mode != null else "",
			"stars": stars,
			"missions": mission_rows,
			"time": floor_time,
			"reason": reason,
			"endless": game_mode_controller.game_mode != null and game_mode_controller.game_mode.is_endless,
			"guided": _guided_run(),
		})


func _on_continue_requested() -> void:
	if game_state == null:
		return
	if ui_controller != null:
		ui_controller.hide_overlays()

	if game_mode_controller != null and game_mode_controller.game_mode != null and not game_mode_controller.game_mode.is_endless:
		var gm: Node = get_node_or_null("/root/GameManager")
		if gm != null:
			var stars: int = mission_controller.stars() if mission_controller != null else 0
			var current := int(gm.get("current_level"))
			gm.call("record_level_clear", current, stars, game_state.elapsed_time)
			# LUỒNG HỌC LẦN ĐẦU: màn 1..4 dẫn tiếp sang bài học / màn thực hành kế của luồng
			var tm: Node = get_node_or_null("/root/TutorialManager")
			if tm != null and tm.has_method("on_level_finished") and bool(tm.call("on_level_finished", current)):
				return
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


## Ván MÀN (chơi từ màn Chọn màn): gieo hạt giống RNG theo ID màn để phần "gia vị" mà chế độ
## Special rắc lên bàn thiết kế (mìn · chi phí ô · điểm ô · mực...) GIỐNG HỆT nhau ở mọi lần
## chơi lại — màn đã thiết kế thì kết quả phải cố định (Dungeon/Daily vẫn ngẫu nhiên như cũ).
func _seed_level_run(floor_number: int) -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm == null or not bool(gm.get("level_run")):
		return
	seed(maxi(floor_number, 1) * 7919 + 13)


## Nút SKIP LEVEL (chỉ hiện khi chơi màn): BỎ QUA màn đang chơi — mở khoá màn KẾ TIẾP trong
## cùng chương nhưng **KHÔNG ghi Sao / thời gian**, rồi vào luôn màn đó.
## Hết chương (không còn màn kế) -> mở màn Chọn Chương. Trả về false nếu ván này không phải ván màn.
func skip_current_level() -> bool:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm == null or not bool(gm.get("level_run")):
		return false
	if ui_controller != null:
		ui_controller.hide_overlays()
	if game_state != null:
		game_state.skips_used += 1    # số liệu Profiler "Skip Used"
	var next_id := int(gm.call("skip_level", current_floor()))
	if next_id > 0:
		gm.call("start_level", next_id)
	else:
		gm.call("go_to_chapters")
	return true


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
		if grid_view != null:
			grid_view.set_interaction_enabled(true)
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
	if grid_view != null:
		grid_view.set_interaction_enabled(true)
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


## Popup thắng THỬ THÁCH: người chơi bấm "TRỞ VỀ" — quay lại ĐÚNG màn trước đó.
## Ván Daily -> màn Daily; còn lại -> lùi LỊCH SỬ điều hướng (Chọn màn / Debug / màn đã vào ván).
func _on_back_requested() -> void:
	if ui_controller != null:
		ui_controller.hide_overlays()
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm != null and not str(gm.get("daily_variant")).is_empty():
		gm.call("go_to_daily")
		return
	var screen: Node = get_node_or_null("/root/ScreenManager")
	if screen != null and screen.has_method("go_back") and bool(screen.call("go_back")):
		return
	# Không còn lịch sử để lùi: ván màn -> Chọn màn, còn lại -> Menu chính
	if gm != null and bool(gm.get("level_run")):
		gm.call("go_to_levels")
	elif gm != null:
		gm.call("go_to_main_menu")
	else:
		Nav.goto_main()


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
	_record_profile_run(mode, won, floor_time)


## Ghi ván vừa chơi vào LỊCH SỬ HỒ SƠ (màn Profiler — "HOẠT ĐỘNG GẦN ĐÂY").
## Chỉ nhận dữ liệu RUNTIME; câu chữ/màu do màn Profiler dựng lại từ dict này.
func _record_profile_run(mode: BaseGameMode, won: bool, floor_time: float) -> void:
	if game_state == null or mode == null:
		return
	var gm: Node = get_node_or_null("/root/GameManager")
	var daily := gm != null and not str(gm.get("daily_variant")).is_empty()
	var stars := 0
	if mission_controller != null:
		stars = mission_controller.stars()
	var maze: MazeData = grid_controller.maze if grid_controller != null else null
	Profile.record_run({
		"mode_id": mode.mode_id,
		"won": won,
		"endless": mode.is_endless,
		"daily": daily,
		"floor": game_state.floor_number,
		"score": game_state.score,
		"elapsed": floor_time,
		"moves": game_state.floor_moves,
		"wall_hits": game_state.floor_wall_hits,
		"width": maze.width if maze != null else 0,
		"height": maze.height if maze != null else 0,
		"stars": stars,
		# --- Số liệu mở rộng cho bản Hồ sơ mới (Profiler stats) ---
		"level_run": gm != null and bool(gm.get("level_run")),
		"level_id": int(gm.get("current_level")) if gm != null else 0,
		"undos": game_state.undos_used,
		"hints": game_state.hints_used,
		"wall_draws": game_state.wall_draws,
		"wall_erases": game_state.wall_erases,
		"skips": game_state.skips_used,
	})


# ---------------------------------------------------------------------------
# Public Actions từ Game Screen Buttons
# ---------------------------------------------------------------------------
func restart_run() -> void:
	# SFX: gõ thẻ giấy cho nút phụ (Restart trên HUD)
	Sfx.play(Sfx.BTN_WOOD_TAP)
	_on_retry_requested()


## Nút Retry trên board overlay "Hết nước đi" — không phát SFX riêng (đã có trong restart_run)
func _on_no_moves_retry_pressed() -> void:
	Sfx.play(Sfx.BTN_WOOD_TAP)
	_on_retry_requested()


## Tutorial ID tương ứng với mỗi chế độ chơi — thay thế popup Instruction cũ.
const TUTORIAL_IDS := {
	"play":           ["how_to_play_move", "how_to_play_checking_wall", "how_to_use_tool"],
	"standard":       ["how_to_play_move", "how_to_play_checking_wall", "how_to_use_tool"],
	"challenge":      ["how_to_play_move", "how_to_play_checking_wall", "how_to_use_tool"],
	"daily_classic":  ["how_to_play_move", "how_to_play_checking_wall", "how_to_use_tool"],
	"daily_challenge": ["how_to_play_move", "how_to_play_checking_wall", "how_to_use_tool"],
	"minesweeper":    ["how_to_play_minesweeper"],
	"sum_path":       ["how_to_play_sum_path"],
	"countdown_cost": ["how_to_play_countdown_cost"],
	"blind_memory":   ["how_to_play_blind_memory"],
	"fog_of_war":     ["how_to_play_fog_of_war"],
	"fading_ink":     ["how_to_play_fading_ink"],
	"one_stroke":     ["how_to_play_one_stroke"],
	"wall_builder":   ["how_to_play_wall_builder"],
}
## Chế độ không có nút "?" (dungeon)
const MODES_WITHOUT_TUTORIAL := ["dungeon"]


func open_instruction() -> void:
	Sfx.play(Sfx.BTN_WOOD_TAP)
	var mode: BaseGameMode = game_mode
	var mode_id := mode.mode_id if mode != null else ""
	if mode_id in MODES_WITHOUT_TUTORIAL:
		return
	var ids: Array = TUTORIAL_IDS.get(mode_id, [])
	# Trong LUỒNG HỌC LẦN ĐẦU: màn thực hành (1·2·3) chỉ mở ĐÚNG bài học của màn đó,
	# không mở cả 3 bài cơ bản (xem TutorialManager.PRACTICE_TUTORIALS)
	var tm: Node = Engine.get_main_loop().root.get_node_or_null("TutorialManager") if Engine.get_main_loop() != null else null
	if tm != null and tm.has_method("practice_tutorial_for_level"):
		var only := str(tm.call("practice_tutorial_for_level", current_floor()))
		if not only.is_empty():
			ids = [only]
	if ids.is_empty():
		return
	var gm: Node = Engine.get_main_loop().root.get_node_or_null("GameManager") if Engine.get_main_loop() != null else null
	if gm == null:
		return
	if timer_controller != null:
		timer_controller.pause()
	gm.set("pending_return_to_game", true)
	# pending_tutorial được đọc bởi tutorial.gd; nhiều bài nối bằng dấu phẩy → chạy theo chuỗi
	gm.set("pending_tutorial", ",".join(ids))
	var nav := preload("res://scripts/utils/nav.gd")
	nav.goto_tutorial()


func undo() -> void:
	# Challenge "không công cụ": bấm Hoàn tác = vi phạm -> thua ngay (popup thua thử thách)
	if _challenge_blocks_tool():
		_challenge_fail(ChallengeGameMode.NO_TOOL)
		return
	# Hết lượt hoàn tác của màn (nút đã bị khoá ở HUD) → không làm gì
	if undo_limit > 0 and undo_left <= 0:
		return
	# Wall Builder: Undo xoá ĐOẠN TƯỜNG vừa nối (chế độ không có nước đi để lùi)
	if grid_controller != null and game_mode_controller != null \
			and game_mode_controller.game_mode != null \
			and game_mode_controller.game_mode.undo_drawn_wall(grid_controller.anchor_controller):
		Sfx.play(Sfx.UNDO)
		if game_state != null:
			game_state.undos_used += 1     # nhiệm vụ "không dùng hoàn tác"
		undo_left = maxi(undo_left - 1, 0)
		_update_hud()
		return
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
			game_state.undos_used += 1     # nhiệm vụ "không dùng hoàn tác"
		undo_left = maxi(undo_left - 1, 0)
		_update_hud()


func hint() -> void:
	if grid_controller == null:
		return
	# Challenge "không công cụ": bấm Gợi ý = vi phạm -> thua ngay (popup thua thử thách)
	if _challenge_blocks_tool():
		_challenge_fail(ChallengeGameMode.NO_TOOL)
		return
	# Hết lượt gợi ý của màn (nút đã bị khoá ở HUD) → không làm gì
	if hint_limit > 0 and hint_left <= 0:
		return
	# SFX: chuông gió khi bấm Gợi ý
	Sfx.play(Sfx.HINT)
	# Wall Builder: Gợi ý mở + KHOÁ 1 ĐOẠN TƯỜNG thật (không phải ô để đi)
	if game_mode_controller != null and game_mode_controller.game_mode != null \
			and game_mode_controller.game_mode.hint_wall(grid_controller.anchor_controller, grid_controller.maze):
		if game_state != null:
			game_state.hints_used += 1     # nhiệm vụ "không dùng gợi ý"
		hint_left = maxi(hint_left - 1, 0)
		_update_hud()
		return
	grid_controller.give_hint()
	if game_state != null:
		game_state.hints_used += 1     # nhiệm vụ "không dùng gợi ý"
	hint_left = maxi(hint_left - 1, 0)
	_update_hud()


## Wall Builder: người chơi bấm GỬI — đối chiếu bản dựng với MỌI con số trên bàn.
## Đúng ⇒ THẮNG. Sai ⇒ mất 1 LƯỢT GỬI (rung bàn + báo số đoạn còn lệch); hết lượt ⇒ THUA.
func submit_build() -> void:
	if not _run_active or game_mode_controller == null or game_mode_controller.game_mode == null:
		return
	var mode := game_mode_controller.game_mode
	var result: Dictionary = mode.evaluate_submit()
	if result.is_empty():
		return      # chế độ không có hệ thống GỬI -> không có gì để chấm
	if bool(result.get("solved", false)):
		mode.mark_solved()
		_on_reached_end()
		return

	var wrong := int(result.get("wrong", 0))
	mode.register_submit_miss()
	if mode.register_failed_submit():
		_game_over("out_of_submits")
		return

	# Còn lượt: rung bàn cờ + chữ nổi báo SỐ ĐOẠN CÒN LỆCH (chỉ số lượng, không chỉ vị trí)
	Sfx.play(Sfx.WALL_HIT)
	if grid_view != null:
		grid_view.shake_board()
		grid_view.spawn_floating_popup(
			tr("STR_WB_WRONG_COUNT").format([wrong]),
			_board_center_cell(), Color(0.847, 0.267, 0.267, 1.0))
	_update_hud()


## Ô giữa bàn (để đặt chữ nổi/ cảnh báo khi chế độ không có nhân vật)
func _board_center_cell() -> Vector2i:
	var maze: MazeData = grid_controller.maze if grid_controller != null else null
	if maze == null:
		return Vector2i.ZERO
	return Vector2i(maze.width / 2, maze.height / 2)


func _on_pause_toggled(is_paused: bool) -> void:
	if timer_controller == null:
		return
	if is_paused:
		timer_controller.pause()
	elif not _memorize_active:
		# Pha GHI NHỚ giữ đồng hồ đứng yên tới khi hết đếm ngược — đóng popup pause KHÔNG resume.
		timer_controller.resume()


# ---------------------------------------------------------------------------
# Helpers SFX & Daily
# ---------------------------------------------------------------------------
## Tiếng thưởng phát SAU khi hiệu ứng ván thắng chạy xong — Timer khai trong `scenes/game.tscn`
## (AchievementSfxTimer 1.6s · FloorBonusSfxTimer 1.1s + dây `timeout` khai ở đó).
## Node binding: khai `node_paths` + NodePath trên node `Controllers/GameController` trong `scenes/game.tscn`
@export var sfx_timer_achievement: Timer = null
@export var sfx_timer_floor_bonus: Timer = null


func _play_sfx_delayed(timer: Timer, sfx_name: String, delay: float) -> void:
	if not is_inside_tree():
		return
	if timer != null:
		timer.start()   # wait_time khai trong scenes/game.tscn
		return
	# Fallback khi scene thiếu Timer (dây + thời gian thật khai trong scenes/game.tscn)
	get_tree().create_timer(delay).timeout.connect(_play_sfx_now.bind(sfx_name))


func _play_sfx_now(sfx_name: String) -> void:
	Sfx.play(sfx_name)


## Hết AchievementSfxTimer → tiếng thành tích (dây khai trong scenes/game.tscn)
func _on_achievement_sfx_timeout() -> void:
	_play_sfx_now(Sfx.ACHIEVEMENT)


## Hết FloorBonusSfxTimer → tiếng thưởng bước (dây khai trong scenes/game.tscn)
func _on_floor_bonus_sfx_timeout() -> void:
	_play_sfx_now(Sfx.FLOOR_BONUS)


## Chốt TIẾN TRÌNH Daily sau khi thắng ván (2026-10 — "3 GAME + 1 SPECIAL"):
## - Game 0..2 của ngày ("classic"/"challenge"): thắng game thứ `daily_game` = đánh dấu XONG game đó.
## - Maze ĐẶC BIỆT ("special"): hoàn thành ván = nhiệm vụ cuối (3) của ngày.
## Trả về Dictionary mô tả kết quả (RỖNG nếu ván này không phải ván Daily).
func _complete_daily_missions(_mission_rows: Array) -> Dictionary:
	var gm: Variant = get_node_or_null("/root/GameManager")
	var dm: Variant = get_node_or_null("/root/DailyManager")
	if gm == null or dm == null or _is_debug_run():
		return {}
	var variant := str(gm.get("daily_variant"))
	if variant.is_empty():
		return {}

	var day := maxi(int(gm.get("selected_daily_day")), 1)
	var coins := 0
	if variant == "special":
		# Nhiệm vụ cuối cùng trong ngày = nhiệm vụ của maze đặc biệt
		var special_index := maxi(int(dm.call("mission_count")) - 1, 0)
		coins = int(dm.call("complete_day_mission", day, special_index))
	else:
		# 3 GAME của ngày: thắng game thứ `daily_game` -> đánh dấu xong CHÍNH game đó.
		# Ván "classic" chơi tự do (daily_game = -1, VD Debug Console) -> không đánh dấu gì.
		var game_index := int(gm.get("daily_game"))
		if game_index >= 0:
			coins = int(dm.call("complete_day_mission", day, clampi(game_index, 0, 2)))

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
