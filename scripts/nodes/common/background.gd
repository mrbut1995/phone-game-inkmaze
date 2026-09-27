class_name SceneBackground
extends TextureRect
## ============================================================================
## Nền giấy của mọi màn hình (`scenes/base.tscn` → node `Background`).
##
## Màn rộng hơn tỉ lệ 9:16 (máy tính bảng / màn ngang) thì 2 dải `SideL` · `SideR` (ColorRect con)
## được kéo ra 2 bên để tô tiếp màu giấy — chúng nằm NGOÀI vùng art nên không che lề đỏ;
## canvas hẹp thì rộng 0 (biến mất).
##
## `BaseScene` chỉ gọi `apply_sides(canvas, frame)` — nền tự lo node con của mình.
## ============================================================================


## `canvas` = cỡ canvas hiện tại · `frame` = khung art chính giữa (thường là khung của màn hình)
func apply_sides(canvas: Vector2, frame: Rect2) -> void:
	var left := get_node_or_null("SideL") as Control
	if left != null:
		left.position = Vector2(-frame.position.x, 0.0)
		left.size = Vector2(frame.position.x, canvas.y)
	var right := get_node_or_null("SideR") as Control
	if right != null:
		right.position = Vector2(frame.size.x, 0.0)
		right.size = Vector2(maxf(canvas.x - frame.position.x - frame.size.x, 0.0), canvas.y)
