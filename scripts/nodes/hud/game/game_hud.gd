class_name GameHUD
extends BaseHUD
## ============================================================================
## Base: HUD thẻ thông tin của màn chơi — khung "Information" trong scenes/game.tscn
## được thay bằng scene HUD ứng với từng chế độ (GameScene._apply_hud_for_mode).
##
## Mỗi chế độ có 1 HUD riêng (nodes/hud/*.tscn) — GameScene tự đổi HUD theo mode:
##   level_mode.tscn    (LevelHUD)     : THỜI GIAN + THỬ THÁCH   — Play + mọi mode không có HUD riêng
##   dungeon_mode.tscn  (DungeonHUD)   : THỜI GIAN + SỐ BƯỚC + TẦNG — Dungeon (endless)
##   minesweep_hud.tscn (MinesweepHUD) : THỜI GIAN + BOMB CÒN LẠI — Minesweeper Maze
##   sum_path_hud.tscn  (SumPathHUD)   : THỜI GIAN + TỔNG HIỆN TẠI + MỤC TIÊU — Sum Path
##   fog_of_war_hud.tscn (FogOfWarHUD) : THỜI GIAN + BẢNG SƯƠNG MÙ (lượt thử lại · tầm nhìn) — Fog of War
##
## UIController KHÔNG tự biết từng thẻ: nó chỉ gọi `update_hud(ctx)`, HUD con tự vẽ.
## Mọi HUD đều có thẻ THỜI GIAN tên node "Time/Value" (xem set_time()).
## ============================================================================

@export var time_value_node : Label = get_node_or_null("Time/Value")

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
	set_label_text(get_time_node().get_node_or_null("Value"), format_time(seconds))

func get_time_node() -> Control :
	return get_node_or_null("Content/ModeInformation/Time")

## Gán text cho Label (bỏ qua nếu trùng -> không redraw mỗi frame)
func set_label_text(node: Node, text: String) -> void:
	var label := node as Label
	if label != null and label.text != text:
		label.text = text


static func format_time(seconds: float) -> String:
	var total := maxi(int(seconds), 0)
	return "%d:%02d" % [total / 60, total % 60]


## ---------------------------------------------------------------------------
## THANH NÚT HÀNH ĐỘNG (phương án A): mỗi HUD đều instance `nodes/hud/action_bar.tscn`
## ngay trong scene của mình ⇒ nút VẼ ĐƯỜNG/GHI NHỚ/UNDO/HINT/REPLAY nằm TRONG HUD,
## màn chơi chỉ việc lấy ra để nối tín hiệu (không còn nút nào trong game.tscn).
## ---------------------------------------------------------------------------
func action_bar() -> ActionBar:
	return get_node_or_null("Content/ActionBar") as ActionBar


## Bật bố cục NGANG cho thanh nút (hàng trên: Vẽ đường · Ghi nhớ — hàng dưới: Undo · Hint)
func set_landscape(on: bool) -> void:
	var bar := action_bar()
	if bar != null:
		bar.set_landscape(on)


func tool_path_btn() -> BaseButton:
	var bar := action_bar()
	return bar.tool_path_btn() if bar != null else null


func tool_wall_btn() -> BaseButton:
	var bar := action_bar()
	return bar.tool_wall_btn() if bar != null else null


func undo_btn() -> BaseButton:
	var bar := action_bar()
	return bar.undo_btn() if bar != null else null


func hint_btn() -> BaseButton:
	var bar := action_bar()
	return bar.hint_btn() if bar != null else null


func replay_btn() -> BaseButton:
	var bar := action_bar()
	return bar.replay_btn() if bar != null else null
