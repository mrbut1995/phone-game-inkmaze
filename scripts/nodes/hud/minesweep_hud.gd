class_name MinesweepHUD
extends BaseHUD
## HUD Minesweeper Maze: THỜI GIAN + BOMB CÒN LẠI (thay cho thẻ THỬ THÁCH).
## Số bomb còn lại = tổng số bomb chưa nổ; mỗi quả chỉ nổ đúng 1 lần.


func _on_update(ctx: Dictionary) -> void:
	var mode := ctx.get("mode", null) as MinesweeperPathGameMode
	if mode == null:
		return
	set_label_text(get_node_or_null("Content/ModeInformation/Bomb/Value"),
		"%d/%d" % [mode.get_mines_left(), mode.get_total_mines()])
