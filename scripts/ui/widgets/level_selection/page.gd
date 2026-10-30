class_name LevelsPage
extends Control
## ============================================================================
## Một TRANG màn chơi của màn Chọn màn (nodes/level_selection/page.tscn)
## Là SCENE riêng (không dựng bằng code): số cột / khe / vị trí lưới sửa ngay trong scene.
##
## Màn Chọn màn chỉ việc: page.grid().add_child(thẻ màn).
## ============================================================================


## Lưới 3×3 thẻ màn chơi của trang: node `Grid` phủ kín trang (thẻ tự co giãn theo ô).
func grid() -> GridContainer:
	return get_node_or_null("Grid") as GridContainer
