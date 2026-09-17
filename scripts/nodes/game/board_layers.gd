class_name BoardLayers
extends Control
## ============================================================================
## Các LỚP VẼ của bàn mê cung (nodes/game/board_layers.tscn)
##
## Trước đây bàn tự dựng 5 lớp bằng `Control.new()` — nay là SCENE riêng:
##   · mọi lớp đều `mouse_filter = IGNORE` (không chặn input của bàn)
##   · thứ tự node con = thứ tự VẼ: Cells → Lines → Walls → Anchors → Markers
## Bàn chỉ việc: layers.cells() / layers.walls() / … rồi thả node vào lớp.
## ============================================================================


## Lớp ô mê cung (nền từng ô)
func cells() -> Control:
	return $Cells


## Lớp vệt bút (đường đã đi, vệt mờ lịch sử)
func lines() -> Control:
	return $Lines


## Lớp tường (đoạn tường vẽ đè lên vệt bút)
func walls() -> Control:
	return $Walls


## Lớp điểm neo (neo, chốt)
func anchors() -> Control:
	return $Anchors


## Lớp trang trí + nhân vật (con trỏ, vệt mực, hiệu ứng, chữ nổi)
func markers() -> Control:
	return $Markers
