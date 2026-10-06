class_name SceneBackground
extends Control
## ============================================================================
## Nền giấy của mọi màn hình (`scenes/base.tscn` → node `Background`).
##
## Nền gồm 3 LỚP `Parallax2D` xếp theo độ xa — lớp càng "xa" trượt càng ít:
##   · `PaperFar`   — trang giấy ô ly (art `background.png`)                  scroll_scale 0.05
##   · `HolesMid`   — cột lỗ bấm giấy (pattern lặp `bg_hole_column.png`)      scroll_scale 0.14
##   · `DoodleNear` — nét vẽ nguệch ngoạc (pattern lặp `bg_doodle_tile.png`)  scroll_scale 0.28
##
## KHÔNG dùng Camera2D (màn UI phải đứng yên theo canvas) nên script TỰ đẩy `scroll_offset`
## của từng lớp theo ĐỘ DỊCH CUỘN THẬT của màn gọi nó — xem `set_scroll_delta()`. Màn nào
## không gọi thì cả 3 lớp đứng yên ở offset 0 (giống hệt nền tĩnh cũ).
##
## · `apply_sides()`: `BaseScene` gọi mỗi lần canvas đổi cỡ — nền tự canh lại từng lớp
##   (rộng hơn canvas một khoảng ĐỆM đúng bằng quãng trượt để không hở mép), đồng thời
##   2 dải `SideL`/`SideR` tô tiếp màu giấy ra 2 bên cột nội dung (màn rộng hơn 9:16).
## ============================================================================

## Quãng cuộn TỐI ĐA của MÀN HÌNH (px) mà nền còn trượt theo. Lớp nhân thêm `scroll_scale`
## của chính nó ⇒ quãng trượt thật của lớp = `PARALLAX_RANGE × scroll_scale` (đệm quanh
## canvas cũng lấy đúng số này nên không bao giờ hở mép).
const PARALLAX_RANGE := 1400.0
## Đệm thêm quanh canvas để lớp trượt không hở mép
const EDGE_PAD := 60.0

## 3 lớp parallax + nội dung từng lớp (khai trong `nodes/common/parallax_background.tscn`).
## Script chỉ CANH vị trí/kích thước node có sẵn — không tạo node lúc chạy.
@export var layer_far: Parallax2D = null
@export var layer_mid: Parallax2D = null
@export var layer_near: Parallax2D = null
@export var paper_art: Control = null
@export var holes_art: Control = null
@export var doodles_art: Control = null


## `canvas` = cỡ canvas hiện tại · `frame` = khung art chính giữa (thường là khung của màn hình)
func apply_sides(canvas: Vector2, frame: Rect2) -> void:
	if canvas.x <= 0.0 or canvas.y <= 0.0:
		return
	if size != canvas:
		size = canvas
	_layout_layer(layer_far, paper_art, canvas)
	_layout_layer(layer_mid, holes_art, canvas)
	_layout_layer(layer_near, doodles_art, canvas)
	_layout_sides(canvas, frame)


## Trượt 3 lớp theo ĐỘ DỊCH CUỘN THẬT của màn hình (`delta_y` px so với giữa khoảng cuộn).
## Mỗi lớp dịch `delta_y × scroll_scale` ⇒ tốc độ nền tỉ lệ CỐ ĐỊNH với tay kéo (mượt, đều);
## vượt `PARALLAX_RANGE` thì lớp dừng lại (giữ đúng đệm nên không hở mép nền).
func set_scroll_delta(delta_y: float) -> void:
	var delta := clampf(delta_y, -PARALLAX_RANGE, PARALLAX_RANGE)
	_set_layer_delta(layer_far, delta)
	_set_layer_delta(layer_mid, delta)
	_set_layer_delta(layer_near, delta)


func _set_layer_delta(layer: Parallax2D, delta_y: float) -> void:
	if layer == null:
		return
	# `scroll_scale` = hệ số chiều sâu khai trong .tscn (lớp càng xa càng nhỏ)
	layer.scroll_offset = Vector2(0.0, delta_y * layer.scroll_scale.y)


## Canh 1 lớp phủ kín canvas, chừa đệm `EDGE_PAD` + quãng trượt của chính lớp đó ở CẢ 4 phía
## (nền luôn tràn ra ngoài khung nên trượt tới đâu cũng không hở mép).
func _layout_layer(layer: Parallax2D, art: Control, canvas: Vector2) -> void:
	if art == null:
		return
	var max_shift := PARALLAX_RANGE * (layer.scroll_scale.y if layer != null else 0.0)
	var pad := max_shift + EDGE_PAD
	_fit_control(art, Vector2(-pad, -pad), _cover_size(art, canvas + Vector2(pad, pad) * 2.0))


## Cỡ để art phủ kín khung `target` mà KHÔNG kéo méo (scale đều, neo góc trên-trái)
func _cover_size(art: Control, target: Vector2) -> Vector2:
	var texture_rect := art as TextureRect
	if texture_rect == null or texture_rect.texture == null:
		return target
	var art_size := texture_rect.texture.get_size()
	if art_size.x <= 0.0 or art_size.y <= 0.0:
		return target
	var factor: float = maxf(target.x / art_size.x, target.y / art_size.y)
	return Vector2(ceilf(art_size.x * factor), ceilf(art_size.y * factor))


func _fit_control(control: Control, pos: Vector2, target: Vector2) -> void:
	if control.position != pos:
		control.position = pos
	if control.size != target:
		control.size = target


## 2 dải `SideL`/`SideR` (ColorRect con) tô tiếp màu giấy ra 2 bên khung nội dung.
func _layout_sides(canvas: Vector2, frame: Rect2) -> void:
	var left := get_node_or_null("SideL") as Control
	if left != null:
		left.position = Vector2(-frame.position.x, 0.0)
		left.size = Vector2(frame.position.x, canvas.y)
	var right := get_node_or_null("SideR") as Control
	if right != null:
		right.position = Vector2(frame.size.x, 0.0)
		right.size = Vector2(maxf(canvas.x - frame.position.x - frame.size.x, 0.0), canvas.y)
