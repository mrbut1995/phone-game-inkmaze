class_name BaseGameMode
extends Resource 
## ============================================================================
## Strategy Pattern / Base Class cho tất cả các Chế độ chơi (Game Modes).
## Tuân thủ OCP (Open/Closed Principle) & LSP (Liskov Substitution Principle).
## ============================================================================

var mode_id: String = "dungeon"
var mode_name: String = "Dungeon Mode"
var mode_description: String = "Vượt tháp mê cung tường vô hình bất tận."

var is_endless: bool = true
var instant_game_over_on_hazard: bool = false
## Đạp vào ô nguy hiểm (tường ẩn / mìn...) thì có bị đưa về ô xuất phát không.
## `false` = ở lại ô hiện tại (chỉ trừ bước) — dùng cho Minesweeper.
var respawn_on_hazard: bool = true
## Hệ thống LƯỢT THỬ LẠI (Fog of War): tổng số lượt của một ván. 0 = chế độ không dùng hệ thống này.
var max_retries: int = 0
## Số LƯỢT THỬ LẠI còn lại (chỉ có ý nghĩa khi `max_retries > 0`)
var retries_left: int = 0
## Số giây đếm ngược pha "ghi nhớ" trước khi vào chơi (Blind Memory). 0 = không có pha này.
## Khi > 0: GameController hiện toàn bộ tường + mở popup đếm ngược, đồng hồ đứng yên cho tới khi hết.
var memorize_countdown_seconds: int = 0
var initial_steps: int = 15
var difficulty: String = "medium"  # "easy", "medium", "hard", "normal", "hardcore"

## LevelData nguồn của màn/tầng hiện tại (null nếu mode tự sinh mê cung).
## Dùng để lấy danh sách Thử thách do nhà thiết kế đặt cho màn.
var current_level_data: LevelData = null


## Thử thách của màn hiện tại: [{ type, param }, ...] (rỗng = game dùng 3 thử thách mặc định)
func get_challenges() -> Array[Dictionary]:
	if current_level_data != null:
		return current_level_data.get_challenges()
	return []


## Bộ thử thách MẶC ĐỊNH riêng của chế độ (rỗng = dùng bộ chung no_wall/steps_max/time_max).
## Màn/tầng do nhà thiết kế khai báo thì luôn được ưu tiên hơn bộ này.
func default_challenges() -> Array[String]:
	return []


## Sinh dữ liệu mê cung/bàn cờ cho floor_number.
func setup_floor(_floor_number: int) -> MazeData:
	return null


## Lấy text hiển thị trên Cell (Số tường, điểm số, hoặc rỗng).
func get_cell_text(pos: Vector2i, _maze: MazeData) -> String:
	if _maze == null:
		return ""
	if pos == _maze.get_start():
		return "S"
	if pos == _maze.get_end():
		return "F"
	return ""


## Số bước bị trừ khi di chuyển từ from_pos sang to_pos.
func get_step_cost(_from_pos: Vector2i, _to_pos: Vector2i, _maze: MazeData) -> int:
	return 1


# ---------------------------------------------------------------------------
# LƯỢT THỬ LẠI (chỉ chế độ khai báo `max_retries > 0` mới dùng — VD Fog of War)
# ---------------------------------------------------------------------------
## Chế độ có dùng hệ thống LƯỢT THỬ LẠI không
func uses_retries() -> bool:
	return max_retries > 0


## Đầu ván mới: nạp đầy lượt thử lại
func reset_retries() -> void:
	retries_left = maxi(max_retries, 0)


## Ghi nhận 1 lần đâm chướng ngại vật (tường ẩn/mìn).
## Trả về `true` nếu người chơi ĐÃ HẾT LƯỢT THỬ -> thua luôn (GameController mở popup thua).
func register_hazard() -> bool:
	if not uses_retries():
		return instant_game_over_on_hazard
	retries_left = maxi(retries_left - 1, 0)
	return retries_left <= 0


## Hồi sinh (xem quảng cáo): chế độ có lượt thử thì nhận thêm 1 lượt để đi tiếp.
func on_revive() -> void:
	if uses_retries():
		retries_left = mini(retries_left + 1, max_retries)


## Hook sau khi nhân vật bị đưa về ô xuất phát vì đâm chướng ngại vật (hoặc hồi sinh).
## Chế độ có trạng thái hiển thị theo vị trí (Fog of War: mở sương quanh ô hiện tại) cập nhật ở đây.
func on_respawned(_grid_view: Control, _pos: Vector2i, _maze: MazeData) -> void:
	pass


## Kiểm tra tính hợp lệ của bước di chuyển (from_pos -> to_pos).
## Trả về Dictionary:
##   "allowed": bool       - Có được phép di chuyển sang ô này không
##   "is_hazard": bool     - Có bị đâm chướng ngại vật (tường/mìn) không
##   "hazard_type": String - "wall", "mine", "none"
func evaluate_move(from_pos: Vector2i, to_pos: Vector2i, maze: MazeData) -> Dictionary:
	if maze == null or not maze.is_in_bounds(to_pos):
		return { "allowed": false, "is_hazard": false, "hazard_type": "none" }
	
	var d := (from_pos - to_pos).abs()
	if d.x + d.y != 1:
		return { "allowed": false, "is_hazard": false, "hazard_type": "none" }
	
	return { "allowed": true, "is_hazard": false, "hazard_type": "none" }


## Kiểm tra điều kiện hoàn thành màn chơi / floor.
func check_completion(current_pos: Vector2i, maze: MazeData, _anchor_controller: Node) -> bool:
	if maze == null:
		return false
	return current_pos == maze.get_end()


## Hook được gọi khi Grid View vừa dựng xong layout & walls.
func on_grid_setup(_grid_view: Control, _maze: MazeData) -> void:
	pass


## Hook được gọi khi Player vừa di chuyển sang ô mới.
func on_player_moved(_grid_view: Control, _new_pos: Vector2i, _maze: MazeData) -> void:
	pass


## Người chơi vừa LÙI 1 bước (Undo). Mode nào có trạng thái riêng thì lùi theo
## (VD Fading Ink hồi lại mực đã phai). `from_pos` = ô vừa rời, `to_pos` = ô quay về.
func on_move_undone(_grid_view: Control, _from_pos: Vector2i, _to_pos: Vector2i, _maze: MazeData) -> void:
	pass


## Hết lối đi mà chưa tới F (mode tự quyết định, mặc định = không bao giờ kẹt).
## GridController phát signal `dead_end` -> GameController._on_dead_end() -> popup thua.
func is_dead_end(_current_pos: Vector2i, _maze: MazeData) -> bool:
	return false


## Nước đi bị CHẶN (evaluate_move trả allowed = false, không phải hazard — VD Fading Ink
## hết mực, One Stroke còn ô trống nên chưa được chạm F). Mode có phản hồi riêng thì vẽ ở đây.
func on_move_blocked(_grid_view: Control, _from_pos: Vector2i, _to_pos: Vector2i, _reason: String) -> void:
	pass


## Ô ĐÚNG kế tiếp mà mode muốn gợi ý (Hint). Trả `Vector2i(-1, -1)` = "mode không có ý kiến"
## -> GridController dùng gợi ý mặc định (đường ngắn nhất tới F).
## One Stroke override: gợi ý phải là bước đi hợp lệ của MỘT lời giải phủ kín.
func hint_next_cell(_maze: MazeData, _current_pos: Vector2i) -> Vector2i:
	return Vector2i(-1, -1)


# ---------------------------------------------------------------------------
# LƯỢT GỬI + DỰNG TƯỜNG (chỉ Wall Builder dùng — mặc định là no-op)
# ---------------------------------------------------------------------------
## Khoá dịch dòng mô tả nút HỒI SINH trên popup thua ("" = dùng mặc định theo chế độ).
func revive_desc_key() -> String:
	return ""


## Ghi nhận 1 lần GỬI SAI (Wall Builder). Trả về `true` nếu ĐÃ HẾT LƯỢT GỬI -> thua.
func register_failed_submit() -> bool:
	if not uses_retries():
		return false
	retries_left = maxi(retries_left - 1, 0)
	return retries_left <= 0


## Trạng thái hiển thị của đoạn tường người chơi nối ("" = giữ mặc định "suspected").
func wall_draw_state() -> String:
	return ""


## Đoạn tường này đã bị KHOÁ (không xoá được — VD đoạn do Gợi ý mở ở Wall Builder).
func is_wall_locked(_is_h: bool, _lattice: Vector2i) -> bool:
	return false


## Chế độ có cho phép vẽ tường ở khe này không (mặc định: có).
## Wall Builder: chỉ cho vẽ khe GIỮA 2 Ô THUỘC BOARD — viền ngoài là tường cố định.
func can_draw_wall(_is_h: bool, _lattice: Vector2i, _maze: MazeData) -> bool:
	return true


## Người chơi vừa BẬT/TẮT 1 đoạn tường ở khe giữa 2 ô (kéo nối 2 Anchor).
func on_wall_toggled(_is_h: bool, _lattice: Vector2i, _active: bool) -> void:
	pass


## Lùi 1 đoạn tường đã nối (Undo riêng của Wall Builder). `true` = đã xoá 1 đoạn.
func undo_drawn_wall(_anchor_controller: AnchorController) -> bool:
	return false


## Gợi ý kiểu "mở 1 đoạn tường" (Wall Builder). `true` = đã mở/khoá 1 đoạn.
func hint_wall(_anchor_controller: AnchorController, _maze: MazeData) -> bool:
	return false


## Bàn chơi có hiện nhân vật không (Wall Builder: KHÔNG có nhân vật, không di chuyển)
func shows_player() -> bool:
	return true


## Tính toán điểm số khi kết thúc floor/màn chơi.
func calculate_score(
	floor_number: int,
	steps_remaining: int,
	floor_elapsed: float,
	is_perfect_floor: bool
) -> Dictionary:
	return ScoreCalculator.calculate_floor_score(
		floor_number,
		steps_remaining,
		floor_elapsed,
		is_perfect_floor
	)


## Tiêu đề và thông tin phụ hiển thị trên HUD.
## Dungeon (endless) không hiện số tầng ở tiêu đề nữa — tầng nằm ở thẻ "TẦNG" trong HUD
## (mockup matchup_dungeon.svg), nên tiêu đề chỉ còn tên chế độ.
func get_hud_floor_title(_floor_number: int) -> String:
	return mode_name.to_upper()


## Dòng phụ nhỏ dưới tiêu đề HUD (VD "PLAY MODE · CHƯƠNG 1"). Rỗng = ẩn dòng phụ.
func get_hud_subtitle(_floor_number: int) -> String:
	return ""


func get_hud_extra_info() -> String:
	return ""
