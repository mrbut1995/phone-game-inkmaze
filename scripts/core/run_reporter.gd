class_name RunReporter
extends RefCounted
## ============================================================================
## BÁO KẾT QUẢ VÁN CHƠI cho các hệ thống theo dõi tiến trình — tách khỏi `GameController`.
##
## Hai nơi nhận:
##   · Sổ tay thành tựu (`Achievement.notify_run_result`) — thắng/thua, tầng, điểm, số lần gợi ý/hoàn tác.
##   · Hồ sơ người chơi (`Profile.record_run`) — dòng "HOẠT ĐỘNG GẦN ĐÂY" ở màn Profiler.
##
## Chỉ nhận dữ liệu RUNTIME (không câu chữ/màu); ván test từ Debug Console do bên gọi tự bỏ qua.
## Ai gọi: `GameController._report_to_achievements()`.
## ============================================================================


## `stars` = số Sao đạt được của màn · `maze` = bàn vừa chơi (null nếu không có)
static func report(state: GameState, mode: BaseGameMode, won: bool,
		floor_time: float, stars: int, maze: MazeData) -> void:
	if state == null or mode == null:
		return
	var gm := Svc.game()
	var daily := gm != null and not str(gm.get("daily_variant")).is_empty()

	Achievement.notify_run_result({
		"mode_id": mode.mode_id,
		"won": won,
		"endless": mode.is_endless,
		"floor": state.floor_number,
		"score": state.score,
		"elapsed": floor_time,
		"wall_hits": state.floor_wall_hits,
		"hints_used": state.hints_used,
		"undos_used": state.undos_used,
		"hardcore": str(mode.difficulty).to_lower() == "hardcore",
	})

	Profile.record_run({
		"mode_id": mode.mode_id,
		"won": won,
		"endless": mode.is_endless,
		"daily": daily,
		"floor": state.floor_number,
		"score": state.score,
		"elapsed": floor_time,
		"moves": state.floor_moves,
		"wall_hits": state.floor_wall_hits,
		"width": maze.width if maze != null else 0,
		"height": maze.height if maze != null else 0,
		"stars": stars,
		# --- Số liệu mở rộng cho bản Hồ sơ mới (Profiler stats) ---
		"level_run": gm != null and bool(gm.get("level_run")),
		"level_id": int(gm.get("current_level")) if gm != null else 0,
		"undos": state.undos_used,
		"hints": state.hints_used,
		"wall_draws": state.wall_draws,
		"wall_erases": state.wall_erases,
		"skips": state.skips_used,
	})
