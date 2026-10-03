class_name SceneBackground
extends TextureRect
## ============================================================================
## Nền giấy của mọi màn hình (`scenes/base.tscn` → node `Background`).
##
## · `_fit_to_canvas()`: scale ĐỀU art phủ kín canvas, neo GÓC TRÊN-TRÁI (art tràn phải/dưới
##   nằm ngoài màn hình) ⇒ ô ly luôn VUÔNG, lề đỏ luôn trong màn; KHÔNG kéo méo art.
## · Màn rộng hơn tỉ lệ 9:16 (máy tính bảng) thì 2 dải `SideL` · `SideR` (ColorRect con)
##   được kéo ra 2 bên để tô tiếp màu giấy — chúng nằm NGOÀI vùng art nên không che lề đỏ;
##   canvas hẹp thì rộng 0 (biến mất).
##
## `BaseScene` chỉ gọi `apply_sides(canvas, frame)` — nền tự lo node con của mình.
## ============================================================================


## `canvas` = cỡ canvas hiện tại · `frame` = khung art chính giữa (thường là khung của màn hình)
func apply_sides(canvas: Vector2, frame: Rect2) -> void:
	_fit_to_canvas(canvas)
	var left := get_node_or_null("SideL") as Control
	if left != null:
		left.position = Vector2(-frame.position.x, 0.0)
		left.size = Vector2(frame.position.x, canvas.y)
	var right := get_node_or_null("SideR") as Control
	if right != null:
		right.position = Vector2(frame.size.x, 0.0)
		right.size = Vector2(maxf(canvas.x - frame.position.x - frame.size.x, 0.0), canvas.y)


## Scale ĐỀU để phủ kín canvas mà KHÔNG kéo méo art (ô ly giữ vuông, lề đỏ luôn trong màn).
## Neo góc TRÊN-TRÁI; phần art tràn phải/dưới nằm ngoài màn hình (bị cắt tự nhiên).
## Ví dụ: art 540×960 → màn 540×1212: scale ×1.263 (nếu để SCALE kéo theo node thì ô ly méo ×1.263 dọc).
func _fit_to_canvas(canvas: Vector2) -> void:
	if texture == null or canvas.x <= 0.0 or canvas.y <= 0.0:
		return
	var art := texture.get_size()
	if art.x <= 0.0 or art.y <= 0.0:
		return
	var factor: float = maxf(canvas.x / art.x, canvas.y / art.y)
	var target := Vector2(ceilf(art.x * factor), ceilf(art.y * factor))
	if position != Vector2.ZERO:
		position = Vector2.ZERO
	if size != target:
		size = target
