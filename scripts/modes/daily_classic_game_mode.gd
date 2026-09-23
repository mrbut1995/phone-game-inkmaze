class_name DailyClassicGameMode
extends StandardGameMode
## ============================================================================
## Mode: DAILY — MAZE THƯỜNG (classic maze của ngày Daily Challenge)
##
## - Sinh mê cung 5×5 ngẫu nhiên tại chỗ (không nạp LevelData của màn thường).
## - Luật giống Play Mode: đâm vào tường vô hình = thua ngay.
## - 3 thử thách mặc định (không đâm tường · đủ bước · đủ thời gian)
##   chính là 3 nhiệm vụ đầu của ngày Daily (xem DailyManager).
## ============================================================================

const MAZE_SIZE := 2.5
const WALL_VISIBLE_RATIO := 0.5
## Số bước thiết kế / giới hạn thời gian của maze thường (màn Daily hiển thị trước 2 số này)
const DESIGN_STEPS := 20
const TIME_LIMIT_SEC := 60


func _init(p_difficulty := "medium") -> void:
	super(p_difficulty)
	mode_id = "daily_classic"
	mode_name = "Classic Maze"
	mode_description = "Maze thường của ngày — vẽ đường tới ô F mà không chạm tường ẩn."
	is_endless = false
	instant_game_over_on_hazard = true


## Mê cung thường của ngày: sinh mới mỗi ván, không dùng LevelData
func setup_floor(_floor_number: int) -> MazeData:
	var maze := MazeData.new()
	maze.generate(MAZE_SIZE, MAZE_SIZE, WALL_VISIBLE_RATIO)
	initial_steps = DESIGN_STEPS
	current_level_data = null      # -> ChallengeController dùng 3 thử thách mặc định
	return maze


## HUD: tiêu đề "MAZE THƯỜNG" + dòng phụ là tên màn Daily
func get_hud_floor_title(_floor_number: int) -> String:
	return tr("STR_DAILY_WIN_CLASSIC")


func get_hud_subtitle(_floor_number: int) -> String:
	return tr("STR_DAILY_CHALLENGE_TITLE")
