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
## Dùng để lấy danh sách Nhiệm vụ do nhà thiết kế đặt cho màn.
var current_level_data: LevelData = null


## Nhiệm vụ của màn hiện tại: [{ type, param }, ...] (rỗng = game dùng 3 nhiệm vụ mặc định)
func get_missions() -> Array[Dictionary]:
	if current_level_data != null:
		return current_level_data.get_missions()
	return []


## Bộ nhiệm vụ MẶC ĐỊNH riêng của chế độ (rỗng = dùng bộ chung no_wall/steps_max/time_max).
## Màn/tầng do nhà thiết kế khai báo thì luôn được ưu tiên hơn bộ này.
func default_missions() -> Array[String]:
	return []


# ---------------------------------------------------------------------------
# MÀN DO NHÀ THIẾT KẾ VẼ (chơi từ màn Chọn màn) — nguồn bàn cờ cho các chế độ SPECIAL
# (từ 2026-09-26: ngoài Daily, một MÀN trong campaign có thể khai `mode_id` để chạy chế độ Special.
#  Lúc đó bàn cờ KHÔNG tự sinh nữa mà dùng đúng bàn nhà thiết kế vẽ trong tool level_designer.)
# ---------------------------------------------------------------------------
## LevelData của MÀN đang chơi khi ván này là ván màn; null với Daily / Dungeon / Debug Console.
## Tự nạp 1 lần rồi nhớ lại (LevelManager có cache nên gọi lại cũng rẻ).
func designed_level() -> LevelData:
	if current_level_data != null:
		return current_level_data
	var gm := _autoload("GameManager")
	if gm == null or not bool(gm.get("level_run")):
		return null
	current_level_data = gm.call("level_data_of", int(gm.get("current_level"))) as LevelData
	return current_level_data


## BÀN CỜ của màn (tường + hình dạng board do nhà thiết kế vẽ) — null khi ván không phải ván màn.
## Chế độ Special gọi hàm này ở đầu `setup_floor`: CÓ bàn => dùng bàn của màn rồi mới rắc
## "gia vị" của chế độ (mìn · điểm ô · mực ...); null => tự sinh bàn như khi chơi Daily.
func designed_maze() -> MazeData:
	var lvl := designed_level()
	return lvl.to_maze_data() if lvl != null else null


## Ô cờ VÁN CHƠI MÀN — HUD/GameScene dùng để hiện nút SKIP và hiện tiêu đề "MÀN nn".
func is_level_run() -> bool:
	return designed_level() != null


## Ngân sách bước cho BÀN THIẾT KẾ khi chạy chế độ Special: tôn trọng `max_steps` của màn
## nhưng KHÔNG BAO GIỜ thấp hơn ngân sách mặc định của chế độ (bàn to mà thiếu bước thì màn
## thành không thắng được). Ván không phải ván màn -> trả về đúng ngân sách mặc định cũ.
func designed_steps(default_steps: int) -> int:
	var lvl := designed_level()
	if lvl == null:
		return default_steps
	return maxi(int(lvl.max_steps), default_steps)


## Autoload theo tên (null khi chạy ngoài cây scene — VD unit test thuần)
static func _autoload(node_name: String) -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null(node_name)


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


## Người chơi không còn nước đi hợp lệ nào (board overlay "Hết nước đi" sẽ hiện).
## Sum Path: tổng vượt target · Countdown Cost: ngân sách < chi phí tối thiểu ô lân cận · Fading Ink: mọi ô lân cận cạn mực.
func is_stuck(_pos: Vector2i, _maze: MazeData, _steps_remaining: int) -> bool:
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
## Tiêu đề trên HUD. MÀN trong màn Chọn màn (ở BẤT KỲ chế độ nào) dùng ĐÚNG cách gọi của
## Play Mode ("MÀN 03") để người chơi biết mình đang ở màn số mấy; các ván khác (Dungeon ·
## Daily) vẫn hiện TÊN CHẾ ĐỘ như trước.
func get_hud_floor_title(floor_number: int) -> String:
	if is_level_run():
		return tr("STR_LEVEL_TITLE_FORMAT").format(["%02d" % maxi(floor_number, 1)])
	return mode_name.to_upper()


## Dòng phụ nhỏ dưới tiêu đề HUD (VD "PLAY MODE · CHƯƠNG 1"). Rỗng = ẩn dòng phụ.
func get_hud_subtitle(_floor_number: int) -> String:
	var lvl := designed_level()
	if lvl == null:
		return ""
	return "%s · %s" % [mode_name.to_upper(), tr("STR_CHAPTER_FORMAT").format([maxi(lvl.chapter, 1)])]


func get_hud_extra_info() -> String:
	return ""


# ---------------------------------------------------------------------------
# NĂNG LỰC TUỲ CHỌN của từng chế độ (board/HUD hỏi bằng CỜ rồi gọi hàm — không duck-typing)
# Mode nào có thì override cả cặp: CỜ trả `true` + hàm mô tả giá trị.
# ---------------------------------------------------------------------------
## Ô trên bàn hiện SỐ MỰC còn lại (Fading Ink). Bật thì phải override `ink_left()`.
func shows_ink_left() -> bool:
	return false


## Số mực còn lại ở ô `pos` (chỉ gọi khi `shows_ink_left()` = true).
func ink_left(_pos: Vector2i) -> int:
	return 0


## Ô ĐÃ ĐI QUA bị khoá, tô mực xanh + gạch chéo "ĐÃ ĐI" (One Stroke).
## Bật thì phải override `is_cell_visited()`.
func tracks_visited_cells() -> bool:
	return false


## Ô `pos` đã đi qua chưa (chỉ gọi khi `tracks_visited_cells()` = true).
func is_cell_visited(_pos: Vector2i) -> bool:
	return false


## Ô đã KHỚP SỐ (đủ tường quanh ô) thì sáng nền xanh lá (Wall Builder).
## Bật thì phải override `is_cell_satisfied()`.
func tracks_satisfied_cells() -> bool:
	return false


## Ô `pos` đã đủ tường quanh ô chưa (chỉ gọi khi `tracks_satisfied_cells()` = true).
func is_cell_satisfied(_pos: Vector2i) -> bool:
	return false


## Ô `pos` còn ĐI VÀO ĐƯỢC không (Fading Ink: hết mực = cạn). Mặc định: đi được.
func is_walkable(_pos: Vector2i) -> bool:
	return true


## Ô `pos` có gắn huy hiệu MÌN đã nổ (Minesweeper Path). Mặc định: không.
func has_bomb_marker(_pos: Vector2i) -> bool:
	return false


## Ván đã CHẮC CHẮN THUA dù chưa đi hết (Sum Path: tổng vượt mục tiêu) — UI hiện nút CHƠI LẠI.
func is_unwinnable() -> bool:
	return false


# ---------------------------------------------------------------------------
# Hệ thống GỬI BÀI (Wall Builder) — chế độ khác để nguyên mặc định "không có gì để gửi"
# ---------------------------------------------------------------------------
## Đối chiếu bản dựng với bàn. Rỗng = chế độ KHÔNG có hệ thống GỬI.
## Chế độ có thì trả { "solved": bool, "wrong": int }.
func evaluate_submit() -> Dictionary:
	return {}


## Ghi nhận 1 lần GỬI SAI (chế độ có hệ thống GỬI mới override).
func register_submit_miss() -> void:
	pass


## Số lần GỬI SAI trong ván (0 = chế độ không có hệ thống GỬI).
func submit_miss_count() -> int:
	return 0


## Bản dựng đã ĐÚNG hoàn toàn — GameController gọi ngay sau khi GỬI thành công.
func mark_solved() -> void:
	pass
