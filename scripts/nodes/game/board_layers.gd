class_name BoardLayers
extends Control
## ============================================================================
## Các LỚP VẼ của bàn mê cung (nodes/game/board_layers.tscn)
##
## 5 lớp xếp theo thứ tự VẼ: Cells → Lines → Walls → Anchors → Markers
##   · mọi lớp đều `mouse_filter = IGNORE` (không chặn input của bàn)
##   · node CỐ ĐỊNH của bàn cờ khai SẴN Ở ĐÂY (không instantiate lúc chạy):
##     Lines/MovingLine (nét mực đang vẽ) · Lines/DragGuide (đường kẻ chỉ dẫn kéo neo)
##     · Markers/Cursor (con trỏ người chơi)
##   · node MẪU (template) của các node ĐỘNG cũng khai SẴN Ở ĐÂY — board chỉ `duplicate()`
##     từng cái thay vì `instantiate()` scene: Cells/CellTemplate (ô) ·
##     Walls/WallTemplate (đoạn tường) · Anchors/AnchorTemplate (điểm neo) ·
##     Lines/HistoryTemplate (vệt mực đã đi). Muốn đổi art/cỡ thì sửa scene GỐC
##     (cell.tscn · wall_segment.tscn · anchor.tscn · history_line.tscn) — board ăn ngay.
##     Các node này LUÔN ẩn; board bật lại cho bản nhân bản (xem `BoardView._spawn_template`).
## Bàn chỉ việc: layers.cells() / layers.walls() / … rồi thả node vào lớp.
## ============================================================================


## Node KHAI SẴN trong scene — board KHÔNG được xoá khi dọn tầng (nét mực · chỉ dẫn · con trỏ · mẫu)
func fixed_nodes() -> Array:
	return [
		moving_line(), drag_guide_line(), cursor(),
		cell_template(), wall_template(), anchor_template(), history_template(),
	]


## Node MẪU 1 ô mê cung (bản nhân bản được thả vào lớp Cells)
func cell_template() -> MazeCell:
	return $Cells/CellTemplate as MazeCell


## Node MẪU 1 đoạn tường (bản nhân bản được thả vào lớp Walls)
func wall_template() -> WallSegment:
	return $Walls/WallTemplate as WallSegment


## Node MẪU 1 điểm neo (bản nhân bản được thả vào lớp Anchors)
func anchor_template() -> MazeAnchor:
	return $Anchors/AnchorTemplate as MazeAnchor


## Node MẪU 1 vệt mực đã đi (bản nhân bản được thả vào lớp Lines)
func history_template() -> Line2D:
	return $Lines/HistoryTemplate as Line2D


## Lớp ô mê cung (nền từng ô)
func cells() -> Control:
	return $Cells


## Lớp vệt bút (đường đã đi, vệt mờ lịch sử)
func lines() -> Control:
	return $Lines


## Nét mực đang vẽ (InkStroke khai sẵn trong scene)
func moving_line() -> InkStroke:
	return $Lines/MovingLine as InkStroke


## Đường kẻ chỉ dẫn khi kéo neo (mặc định ẩn — board bật lên theo layout)
func drag_guide_line() -> InkStroke:
	return $Lines/DragGuide as InkStroke


## Con trỏ người chơi (khai sẵn trong Markers)
func cursor() -> PlayerCursor:
	return $Markers/Cursor as PlayerCursor


## Lớp tường (đoạn tường vẽ đè lên vệt bút)
func walls() -> Control:
	return $Walls


## Lớp điểm neo (neo, chốt)
func anchors() -> Control:
	return $Anchors


## Lớp trang trí + nhân vật (con trỏ, vệt mực, hiệu ứng, chữ nổi)
func markers() -> Control:
	return $Markers


## Hiện/ẩn toàn bộ lớp trang trí + nhân vật
func set_markers_visible(on: bool) -> void:
	$Markers.visible = on


## Hiện/ẩn riêng con trỏ
func set_cursor_visible(on: bool) -> void:
	var cur := cursor()
	if cur != null:
		cur.set_cursor_visible(on)
