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
func get_hud_floor_title(floor_number: int) -> String:
	if not is_endless:
		return mode_name.to_upper()
	return "TẦNG %02d" % floor_number


func get_hud_extra_info() -> String:
	return ""
