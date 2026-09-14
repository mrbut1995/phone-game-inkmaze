class_name BaseHUD
extends Control
## ============================================================================
## Base: HUD thẻ thông tin của màn chơi — khung "Information" trong scenes/game.tscn
## được thay bằng scene HUD ứng với từng chế độ (GameScene._apply_hud_for_mode).
##
## Mỗi chế độ có 1 HUD riêng (nodes/hud/*.tscn) — GameScene tự đổi HUD theo mode:
##   level_mode.tscn    (LevelHUD)     : THỜI GIAN + THỬ THÁCH   — Play + mọi mode không có HUD riêng
##   dungeon_mode.tscn  (DungeonHUD)   : THỜI GIAN + SỐ BƯỚC + TẦNG — Dungeon (endless)
##   minesweep_hud.tscn (MinesweepHUD) : THỜI GIAN + BOMB CÒN LẠI — Minesweeper Maze
##   sum_path_hud.tscn  (SumPathHUD)   : THỜI GIAN + TỔNG HIỆN TẠI + MỤC TIÊU — Sum Path
##
## UIController KHÔNG tự biết từng thẻ: nó chỉ gọi `update_hud(ctx)`, HUD con tự vẽ.
## Mọi HUD đều có thẻ THỜI GIAN tên node "Time/Value" (xem set_time()).
## ============================================================================


## Gọi mỗi khi HUD cần vẽ lại (GameController._update_hud). ctx gồm:
##   title:String · subtitle:String · steps_remaining:int · elapsed_time:float
##   floor_number:int · extra:String · mode:BaseGameMode
func update_hud(ctx: Dictionary) -> void:
	set_time(float(ctx.get("elapsed_time", 0.0)))
	_on_update(ctx)


## HUD con override để vẽ các thẻ riêng của chế độ mình
func _on_update(_ctx: Dictionary) -> void:
	pass


## Thẻ THỬ THÁCH nếu HUD có (chỉ HUD của các chế độ dùng hệ thống Thử thách).
## ChallengeController gọi hàm này để biết thẻ cần vẽ 3 dải thử thách.
func challenge_card() -> Control:
	return null


## Đồng hồ của ván: giây -> "m:ss"
func set_time(seconds: float) -> void:
	set_label_text(get_node_or_null("Time/Value"), format_time(seconds))


## Gán text cho Label (bỏ qua nếu trùng -> không redraw mỗi frame)
func set_label_text(node: Node, text: String) -> void:
	var label := node as Label
	if label != null and label.text != text:
		label.text = text


static func format_time(seconds: float) -> String:
	var total := maxi(int(seconds), 0)
	return "%d:%02d" % [total / 60, total % 60]
