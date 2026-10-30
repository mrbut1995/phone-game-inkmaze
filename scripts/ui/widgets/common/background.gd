class_name SceneBackground
extends Control
## ============================================================================
## Nền giấy của mọi màn hình (`scenes/base.tscn` → node `Background`).
##
## Nền gồm 3 LỚP `Parallax2D` xếp theo độ xa — lớp càng "xa" trượt càng ít:
##   · `PaperFar`   — trang giấy ô ly (art `background.png`, ghép bằng NinePatchRect)  scroll_scale 0
##   · `HolesMid`   — cột lỗ bấm giấy (lặp dọc `bg_hole_column.svg` @2×)            scroll_scale 0.14
##   · `DoodleNear` — nét vẽ nguệch ngoạc (pattern lặp `bg_doodle_tile.png`)        scroll_scale 0.28
##
## TRANG GIẤY ĐƯỢC GHÉP, KHÔNG PHÓNG THEO BỀ RỘNG CANVAS: `background.png` (1080×1920) chia thành
##   mảnh TRÁI (gáy sổ + lề đỏ, cố định) · mảnh GIỮA (lưới, LÁT GẠCH) · mảnh PHẢI (viền phải, cố định)
## và vẽ ở tỉ lệ cố định `paper_design_width / bề rộng ảnh` (= 0,5 ⇒ ô lưới 24px, gáy 36px) ở MỌI
## hướng/tỉ lệ. Nhờ vậy: lề trái không phình ở màn ngang, viền phải luôn hiện đủ (không bị cắt ở
## màn cao 9:19.5/9:21), lưới liền mạch cả chiều ngang lẫn chiều dọc.
## ⇒ Nội dung màn nên bắt đầu ở x ≥ `content_left()`.
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
## của chính nó ⇒ quãng trượt thật của lớp = `parallax_range × scroll_scale` (đệm quanh
## canvas cũng lấy đúng số này nên không bao giờ hở mép).
@export_range(0.0, 3000.0, 10.0) var parallax_range := 1400.0
## Đệm thêm quanh canvas để lớp trượt không hở mép
@export_range(0.0, 300.0, 1.0) var edge_pad := 60.0

## TRANG GIẤY — số đo theo hệ ảnh gốc 1080 (khớp `background.svg`)
## Bề rộng canvas-px mà ảnh gốc được vẽ (540 ⇒ tỉ lệ 0,5)
@export var paper_design_width := 540.0
@export var paper_ref_width := 1080.0
## Mảnh TRÁI: 0…96 (gáy 72 + đường chỉ + lề đỏ x=84). Mảnh PHẢI: 816…1080 (viền phải)
@export var paper_patch_left := 96.0
@export var paper_patch_right := 264.0
## Vị trí lề đỏ (hệ 1080) — chỉ dùng cho `content_left()`
@export var paper_margin_x := 84.0
## Số px của art lỗ bấm trên MỖI canvas-px (art vẽ @2× ⇒ 2.0)
@export var hole_density := 2.0

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
	_layout_paper(canvas)
	_layout_holes(canvas)
	_layout_doodles(canvas)
	_layout_sides(canvas, frame)


## Trượt 3 lớp theo ĐỘ DỊCH CUỘN THẬT của màn hình (`delta_y` px so với giữa khoảng cuộn).
## Mỗi lớp dịch `delta_y × scroll_scale` ⇒ tốc độ nền tỉ lệ CỐ ĐỊNH với tay kéo (mượt, đều);
## vượt `parallax_range` thì lớp dừng lại (giữ đúng đệm nên không hở mép nền).
func set_scroll_delta(delta_y: float) -> void:
	var delta := clampf(delta_y, -parallax_range, parallax_range)
	_set_layer_delta(layer_far, delta)
	_set_layer_delta(layer_mid, delta)
	_set_layer_delta(layer_near, delta)


func _set_layer_delta(layer: Parallax2D, delta_y: float) -> void:
	if layer == null:
		return
	# `scroll_scale` = hệ số chiều sâu khai trong .tscn (lớp càng xa càng nhỏ)
	layer.scroll_offset = Vector2(0.0, delta_y * layer.scroll_scale.y)


## X nhỏ nhất (canvas-px) mà nội dung nên bắt đầu để không đè lề đỏ
func content_left() -> float:
	return paper_margin_x * (paper_design_width / paper_ref_width) + 8.0


## Trang giấy: NinePatchRect (mảnh trái cố định · giữa lát gạch · phải cố định), tỉ lệ cố định
func _layout_paper(canvas: Vector2) -> void:
	var np := paper_art as NinePatchRect
	if np == null or np.texture == null:
		return
	var tex_size := np.texture.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return
	# canvas-px trên mỗi px ảnh (ảnh có thể được xuất ở cỡ khác 1080 — mọi số tự quy đổi)
	var s := paper_design_width / tex_size.x
	var k := tex_size.x / paper_ref_width
	var left := roundi(paper_patch_left * k)
	var right := roundi(paper_patch_right * k)
	if np.patch_margin_left != left:
		np.patch_margin_left = left
	if np.patch_margin_right != right:
		np.patch_margin_right = right
	np.patch_margin_top = 0
	np.patch_margin_bottom = 0
	np.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE
	np.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_TILE
	if np.scale != Vector2(s, s):
		np.scale = Vector2(s, s)
	_fit_control(np, Vector2.ZERO, canvas / s)


## Cột lỗ bấm: 1 ô art lặp dọc vô tận bằng Parallax2D; bề rộng cố định = bề rộng art ÷ density.
func _layout_holes(canvas: Vector2) -> void:
	var tex_rect := holes_art as TextureRect
	if tex_rect == null or tex_rect.texture == null:
		return
	var k := 1.0 / maxf(hole_density, 0.01)
	var tex_size := tex_rect.texture.get_size()
	var w := tex_size.x * k
	var h := tex_size.y * k
	if h <= 0.0:
		return
	_fit_control(holes_art, Vector2.ZERO, Vector2(w, h))
	if layer_mid != null:
		layer_mid.repeat_size = Vector2(0.0, h)
		layer_mid.repeat_times = int(ceil((canvas.y + parallax_range) / h)) + 2


## Doodle: lát gạch ở cỡ gốc, phủ canvas + đệm = quãng trượt của lớp + `edge_pad` ở cả 4 phía
## ⇒ trượt tới đâu cũng không hở mép.
func _layout_doodles(canvas: Vector2) -> void:
	if doodles_art == null:
		return
	var m := edge_pad
	if layer_near != null:
		m += parallax_range * layer_near.scroll_scale.y
	_fit_control(doodles_art, Vector2(-m, -m), canvas + Vector2(m, m) * 2.0)


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
