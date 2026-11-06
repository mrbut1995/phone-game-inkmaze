class_name AchPage
extends Control
## ============================================================================
## Một TRANG danh hiệu của Sổ tay thành tựu (nodes/achievements/page.tscn)
## Là SCENE riêng (không dựng bằng code): khe giữa các thẻ (separation) sửa được ngay
## trong scene.
##
## Màn Sổ tay chỉ việc: page.column().add_child(thẻ).
## ============================================================================


## Cột/lưới chứa các thẻ danh hiệu của trang (GridContainer: bản dọc 1 cột, bản NGANG nhiều cột)
## Scene contract
## Exports:  (none)
## Emits:    (none)
## Handlers wired in scene: (none)
## Subscribes in code (EventBus/Model): (none)

func column() -> Container:
	return $Column
