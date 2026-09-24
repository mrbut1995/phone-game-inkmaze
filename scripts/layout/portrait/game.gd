extends GameSceneLayout
## ============================================================================
## BỐ CỤC DỌC của MÀN CHƠI (root của `scenes/layout/portrait/game.tscn`).
##
## Kế thừa `GameSceneLayout` — các node UI (thanh trạng thái · khung HUD · BoardSlot · nút · nhãn)
## đã BIND SẴN bằng `@export` trong .tscn; GameScene đọc `layout.<tên>`.
##
## Kiến trúc: **Controllers + Board là DÙNG CHUNG** cho cả 2 hướng, nằm NGOÀI layout
## (`scenes/game.tscn`). Bố cục chỉ khai UI: thanh trạng thái · HUD · HintGuide — và 1 Control
## `BoardSlot` = chỗ dành sẵn cho bàn cờ khi bố cục này đang hiển thị.
##
## MỌI KHÁC BIỆT GIỮA 2 HƯỚNG NẰM Ở ĐÂY — GameScene không còn `if is_landscape`:
##   · `is_landscape_layout()`      · `hud_variant()`  — chọn scene HUD của hướng này
##   · `mount_board()`              — gắn bàn cờ dùng chung vào `BoardSlot`
##   · `fit_hud()`                  · `configure_tool_path_button()`
## ============================================================================

func is_landscape_layout() -> bool:
	return false

## Bản DỌC dùng ngay HUD DỌC (tham số bản ngang bỏ qua)
func hud_variant(portrait_scene: PackedScene, _landscape_scene: PackedScene) -> PackedScene:
	return portrait_scene


## Control dành sẵn cho bàn cờ — BIND SẴN trong `scenes/layout/portrait/game.tscn` (`board_holder`)
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


## HUD dọc giữ nguyên cỡ thiết kế (khung 980)
func fit_hud(hud: Control) -> void:
	if hud != null:
		hud.scale = Vector2.ONE


## Bản dọc: ẩn nút GHI NHỚ thì nút VẼ ĐƯỜNG phải GHIM về đầu hàng (icon không bị kéo giãn)
func configure_tool_path_button(btn: Control, hide_wall: bool) -> void:
	if btn != null:
		btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if hide_wall else Control.SIZE_FILL


## Bố cục BÊN TRONG bàn cờ tính theo khung GIẤY: vừa reparent thì khung đó còn là số của bố cục
## cũ ⇒ phải tính lại ở frame kế tiếp. Thiếu bước này thì xoay màn hình xong lưới nằm lệch chỗ,
## phải kéo cửa sổ mới về đúng.
func _rebuild_board(board: Control) -> void:
	if board.has_method("relayout"):
		board.call_deferred("relayout")
