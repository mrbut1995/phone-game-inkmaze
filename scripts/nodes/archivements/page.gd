class_name AchPage
extends Control
## ============================================================================
## Một TRANG danh hiệu của Sổ tay thành tựu (nodes/archivements/page.tscn)
## Trước đây trang + cột thẻ được tạo bằng code (`Control.new()` + `VBoxContainer.new()`)
## — nay là SCENE riêng: khe giữa các thẻ (separation) sửa được ngay trong scene.
##
## Màn Sổ tay chỉ việc: page.column().add_child(thẻ).
## ============================================================================


## Cột dọc chứa các thẻ danh hiệu của trang
func column() -> VBoxContainer:
	return $Column
