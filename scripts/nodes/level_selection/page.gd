class_name LevelsPage
extends Control
## ============================================================================
## Một TRANG màn chơi của màn Chọn màn (nodes/level_selection/page.tscn)
## Trước đây trang + lưới 3 cột được tạo bằng code (`Control.new()` + `GridContainer.new()`
## + theme_override) — nay là SCENE riêng: số cột / khe / vị trí lưới sửa ngay trong scene.
##
## Màn Chọn màn chỉ việc: page.grid().add_child(thẻ màn).
## ============================================================================


## Lưới 3×3 thẻ màn chơi của trang
func grid() -> GridContainer:
	return $Grid
