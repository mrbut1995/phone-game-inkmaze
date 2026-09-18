class_name AchPage
extends Control
## ============================================================================
## Một TRANG danh hiệu của Sổ tay thành tựu (nodes/archivements/page.tscn)
## Trước đây trang + cột thẻ được tạo bằng code (`Control.new()` + `VBoxContainer.new()`)
## — nay là SCENE riêng: khe giữa các thẻ (separation) sửa được ngay trong scene.
##
## Màn Sổ tay chỉ việc: page.column().add_child(thẻ).
## ============================================================================


## Cột/lưới chứa các thẻ danh hiệu của trang (GridContainer: bản dọc 1 cột, bản NGANG nhiều cột)
func column() -> Container:
	return $Column
