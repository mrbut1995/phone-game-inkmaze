class_name ChallengeContext
extends RefCounted
## ============================================================================
## Dữ liệu đầu vào để ChallengeController chấm 3 Thử thách của màn/tầng.
## GameController cập nhật rồi gọi ChallengeController.refresh(ctx) mỗi khi HUD đổi.
## ============================================================================

var state: GameState = null
var mode: BaseGameMode = null
var maze: MazeData = null
## Các ô đã đi qua (có thể trùng nếu người chơi quay lại ô cũ)
var path: Array[Vector2i] = []
## Thời gian đã chơi trong màn/tầng này (giây)
var elapsed := 0.0
## true khi màn/tầng đã kết thúc (thắng hoặc thua) -> chốt ĐẠT/CHƯA ĐẠT
var final := false


func set_values(
	p_state: GameState,
	p_mode: BaseGameMode,
	p_maze: MazeData,
	p_path: Array[Vector2i],
	p_elapsed: float,
	p_final: bool
) -> void:
	state = p_state
	mode = p_mode
	maze = p_maze
	path = p_path
	elapsed = p_elapsed
	final = p_final
