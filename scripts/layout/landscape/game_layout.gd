class_name GameLayout
extends GameSceneLayout
## ============================================================================
## BỐ CỤC NGANG của MÀN CHƠI (root của `scenes/layout/landscape/game.tscn`).
##
## Kế thừa `GameSceneLayout`: node UI (thanh trạng thái · khung HUD · BoardSlot · nút · nhãn)
## BIND SẴN bằng `@export` trong .tscn — GameScene đọc `layout.<tên>`.
##
## Kiến trúc: **Controllers + Board là DÙNG CHUNG** cho cả 2 hướng, nằm NGOÀI layout
## (`scenes/game.tscn`). Bố cục chỉ khai UI: cột `Side` (thanh trạng thái · HUD · HintGuide) — và
## 1 Control `BoardSlot` = chỗ dành sẵn cho bàn cờ khi bố cục này đang hiển thị.
##
## MỌI KHÁC BIỆT GIỮA 2 HƯỚNG NẰM Ở ĐÂY — GameScene không còn `if is_landscape`:
##   · `is_landscape_layout()`      · `hud_variant()`  — chọn scene HUD của hướng này
##   · `mount_board()`              — gắn bàn cờ dùng chung vào `BoardSlot`
##   · `fit_hud()`
## ============================================================================

## Bề rộng HUD thiết kế (bản ngang 810 theo mockup 16:9)
const HUD_DESIGN_WIDTH := 405

func is_landscape_layout() -> bool:
	return true


## Bản NGANG dùng HUD NGANG (bản dọc chỉ để dự phòng khi thiếu)
func hud_variant(_portrait_scene: PackedScene, landscape_scene: PackedScene) -> PackedScene:
	return landscape_scene


## Control dành sẵn cho bàn cờ — BIND SẴN trong `scenes/layout/landscape/game.tscn` (`board_holder`)
func board_slot() -> Control:
	return board_holder


## Gắn bàn cờ DÙNG CHUNG vào chỗ của bố cục này rồi chốt lại kích thước
func mount_board(board: Control) -> void:
	var slot := board_slot()
	if board == null or slot == null:
		return
	if board.get_parent() != slot:
		var old_parent := board.get_parent()
		if old_parent != null:
			old_parent.remove_child(board)
		slot.add_child(board)
	board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rebuild_board(board)


## HUD thiết kế cho khung 980 — sidebar hẹp hơn thì thu nhỏ để không tràn/đè lên bàn cờ
func fit_hud(hud: Control) -> void:
	if hud == null:
		return
	var host := hud.get_parent() as Control
	if host == null or host.size.x <= 0.0:
		return
	var factor := clampf(host.size.x / HUD_DESIGN_WIDTH, 0.5, 1.0)
	hud.pivot_offset = Vector2.ZERO
	if absf(hud.scale.x - factor) > 0.001:
		hud.scale = Vector2(factor, factor)


## Bố cục BÊN TRONG bàn cờ tính theo khung GIẤY: vừa reparent thì khung đó còn là số của bố cục
## cũ ⇒ phải tính lại ở frame kế tiếp. Thiếu bước này thì xoay màn hình xong lưới nằm lệch chỗ,
## phải kéo cửa sổ mới về đúng.
func _rebuild_board(board: Control) -> void:
	if board.has_method("relayout"):
		board.call_deferred("relayout")
