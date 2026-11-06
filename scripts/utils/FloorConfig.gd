class_name FloorConfig
extends RefCounted
## ============================================================================
## Helper: Cấu hình độ khó theo floor (kích thước grid + tỉ lệ tường hiển thị).
## Tham chiếu từ Number_Maze_Game_Design.md:
##   Floor 1–3   : 2x2 → 3x3  , ~70–100% tường hiển thị
##   Floor 4–8   : 4x4 → 5x5  , ~30–60%
##   Floor 9–12  : 5x5        , ~10–20%
##   Floor 13+   : 5x5        , 0% (toàn bộ ẩn)
## ============================================================================


static func get_grid_size(floor_number: int) -> int:
	match floor_number:
		1:
			return 2
		2, 3:
			return 3
		4, 5:
			return 4
		_:
			return 5


static func get_visible_ratio(floor_number: int) -> float:
	match floor_number:
		1:
			return 1.0
		2:
			return 0.85
		3:
			return 0.7
		4:
			return 0.6
		5:
			return 0.5
		6:
			return 0.45
		7:
			return 0.4
		8:
			return 0.3
		9:
			return 0.2
		10:
			return 0.17
		11:
			return 0.14
		12:
			return 0.1
		_:
			return 0.0
