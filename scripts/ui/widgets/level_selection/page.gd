class_name LevelsPage
extends Control
## ============================================================================
## Một TRANG màn chơi của màn Chọn màn (nodes/level_selection/page.tscn)
## Trước đây trang + lưới 3 cột được tạo bằng code (`Control.new()` + `GridContainer.new()`
## + theme_override) — nay là SCENE riêng: số cột / khe / vị trí lưới sửa ngay trong scene.
##
## Màn Chọn màn chỉ việc: page.grid().add_child(thẻ màn).
## ============================================================================


## Lưới 3×3 thẻ màn chơi của trang.
## Bản DỌC (`page.tscn`): `Grid` phủ kín trang (thẻ tự co giãn theo ô).
## Bản NGANG (`page_landscape.tscn`): `Center/Grid` — lưới giữ ĐÚNG cỡ thẻ và canh giữa trang.
func grid() -> GridContainer:
	var direct := get_node_or_null("Grid") as GridContainer
	if direct != null:
		return direct
	return get_node_or_null("Center/Grid") as GridContainer
