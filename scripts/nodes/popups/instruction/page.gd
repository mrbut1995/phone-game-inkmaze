class_name InstructionPage
extends Control
## ============================================================================
## MỘT TRANG HƯỚNG DẪN — scene nền `nodes/popups/instruction/page.tscn`.
##
## CÂY NODE (mọi trang trong các scene chế độ đều kế thừa scene này — bố cục CỐ ĐỊNH
## bằng HBox/VBox nên MỌI tỉ lệ khung đều xếp đúng):
##   Page
##     ├─ Title       (Label)            — tiêu đề trang (ẨN khi nhúng vào HUD)
##     ├─ Body        (VBoxContainer)
##     │    ├─ Top    (HBoxContainer)    — HÀNG: [ẢNH | CHI TIẾT CHỈ DẪN TRÊN ẢNH]
##     │    │    ├─ Image  (TextureRect) — ảnh minh hoạ; Label chữ-trên-ảnh (PT#) + BADGE SỐ
##     │    │    │                           (`Point#`) là CON của node này, neo theo TỈ LỆ ảnh
##     │    │    └─ Points (Panel)       — “CHI TIẾT CHỈ DẪN TRÊN ẢNH”: Head + List (PointRow#)
##     │    ├─ Section     (Label)       — mục khối LUẬT CHƠI (khi nhúng = hàng có điều hướng)
##     │    └─ Instruction (VBoxContainer) — các HÀNG LUẬT Row# (generator thêm)
##     ├─ Cta         (Button, generator thêm — CHỈ dùng khi mở bằng POPUP)
##     └─ Link        (Button, generator thêm — CHỈ dùng khi mở bằng POPUP)
##
## Nhờ cấu trúc này: ẢNH và ĐIỂM LUÔN nằm CẠNH NHAU, QUY TẮC luôn nằm DƯỚI —
## không còn trường hợp “điểm tụt xuống dưới ảnh” làm tràn khung / lệch phân trang.
##
## `page.gd` chỉ lo phần KHÔNG thể khai tĩnh được:
##   · CỠ ẢNH theo TỈ LỆ (`custom_minimum_size`) — hàng `Top` cao theo ẢNH (hoặc theo khối
##     ĐIỂM nếu khối đó cần nhiều chỗ hơn), `Points` nở lấp phần bề ngang còn lại;
##   · ẩn Title khi nhúng + cỡ chữ mục LUẬT CHƠI; dàn Cta/Link đáy; co chữ-trên-ảnh/badge
##     theo cỡ ảnh thật (metadata/base_* do generator ghi);
##   · cấp chỗ cho điều hướng qua `nav_slot_rect()` — bám vị trí THẬT của Section.
## ============================================================================

const IMG_RATIO_DEFAULT := 785.0 / 535.0
const PAD := 14.0            ## lề trong khối khi NHÚNG (khung Hướng dẫn của HUD)
const PAD_POPUP := 8.0       ## lề trong khối khi mở bằng POPUP
const TITLE_H := 30.0
const SECTION_SIZE_EMBED := 10
const CTA_H := 50.0
const LINK_H := 28.0
## Bề ngang ẢNH lúc thiết kế (khớp cỡ node Image trong page.tscn)
const IMG_DESIGN_W := 420.0
## Bề cao hàng [ẢNH | ĐIỂM] = ROW_FACTOR × bề cao khối nội dung (kẹp ROW_MIN..ROW_MAX);
## bề ngang ẢNH ≤ IMG_MAX_FRAC × bề ngang khối (phần còn lại dành cho khối ĐIỂM).
const ROW_FACTOR := 0.48
const ROW_MIN_H := 120.0
const ROW_MAX_H := 340.0
const IMG_MAX_FRAC := 0.52
## Lề trong khối ĐIỂM (Panel không tự gom min của con — phải tự cộng khi tính min)
const POINTS_TOP := 26.0
const POINTS_BOTTOM := 8.0

## Bản nhúng trong HUD — ẩn Title (Chip/Tabs/Cta/Link do content_instruction.gd lo)
var embedded := false

## Cỡ cuối cùng đã phát tín hiệu `resized` — chống lặp vô hạn khi tự emit (xem `_notification`)
var _last_size := Vector2.ZERO


# ---------------------------------------------------------------------------
# Truy cập node
# ---------------------------------------------------------------------------
func image() -> TextureRect:
	return get_node_or_null("Body/Top/Image") as TextureRect


func title_label() -> Label:
	return get_node_or_null("Title") as Label


func body() -> VBoxContainer:
	return get_node_or_null("Body") as VBoxContainer


func top_row() -> HBoxContainer:
	return get_node_or_null("Body/Top") as HBoxContainer


func section_label() -> Label:
	return get_node_or_null("Body/Section") as Label


func points_box() -> Panel:
	return get_node_or_null("Body/Top/Points") as Panel


func points_head() -> Label:
	return get_node_or_null("Body/Top/Points/Head") as Label


func points_list() -> VBoxContainer:
	return get_node_or_null("Body/Top/Points/List") as VBoxContainer


func instruction_box() -> VBoxContainer:
	return get_node_or_null("Body/Instruction") as VBoxContainer


func cta_button() -> BaseButton:
	return get_node_or_null("Cta") as BaseButton


func link_button() -> BaseButton:
	return get_node_or_null("Link") as BaseButton


## Các hàng luật của trang (con của `Body/Instruction`)
func rows() -> Array:
	var box := instruction_box()
	return box.get_children() if box != null else []


## Các hàng “chi tiết điểm” của trang (con của `Body/Top/Points/List`)
func point_rows() -> Array:
	var list := points_list()
	return list.get_children() if list != null else []


## Tỉ lệ ảnh minh hoạ (mặc định bằng cỡ ảnh guideline 785×535 nếu chưa gán texture)
func image_ratio() -> float:
	var img := image()
	if img != null and img.texture != null:
		var tex_size := img.texture.get_size()
		if tex_size.x > 0.0 and tex_size.y > 0.0:
			return tex_size.x / tex_size.y
	return IMG_RATIO_DEFAULT


# ---------------------------------------------------------------------------
# API cho content_instruction.gd
# ---------------------------------------------------------------------------
## Bản NHÚNG (khung Hướng dẫn trong HUD): ẩn Title — theo mockup landscape
func set_embedded(on: bool) -> void:
	embedded = on
	var title := title_label()
	if title != null:
		title.visible = not on
	_apply_layout()


## content_instruction.gd gọi SAU khi đổ chữ vào các hàng điểm (khối ĐIỂM có thể cao lên)
func refresh_points() -> void:
	_apply_layout()
	# Container xếp lại con ở frame sau -> báo để content đặt lại điều hướng (nav bám Section thật)
	_announce.call_deferred()


func _announce() -> void:
	resized.emit()


## Vùng dành cho [‹ · dots · › · TRANG x/3] khi NHÚNG — theo vị trí THẬT của hàng
## tiêu đề “LUẬT CHƠI” (Section). Toạ độ LOCAL của trang.
func nav_slot_rect() -> Rect2:
	var sec := section_label()
	if sec == null or not is_inside_tree():
		return Rect2()
	var y := sec.global_position.y - global_position.y
	return Rect2(size.x * 0.46, y, maxf(size.x - PAD - size.x * 0.46, 1.0),
			maxf(sec.size.y, 16.0))


# ---------------------------------------------------------------------------
# Vòng đời + dàn trang (chỉ phần không khai tĩnh được — HBox/VBox lo phần còn lại)
# ---------------------------------------------------------------------------
func _ready() -> void:
	var img := image()
	if img != null and not img.resized.is_connected(_scale_image_nodes):
		img.resized.connect(_scale_image_nodes)


func _notification(what: int) -> void:
	if what == NOTIFICATION_READY or what == NOTIFICATION_RESIZED:
		_apply_layout()
		# Cỡ ĐỔI -> báo lại ở frame sau (container đã xếp xong) để content đặt lại điều
		# hướng theo vị trí THẬT của Section. Chỉ báo khi cỡ THỰC SỰ đổi (tránh lặp).
		if size != _last_size:
			_last_size = size
			_announce.call_deferred()


func _apply_layout() -> void:
	var w := size.x
	var h := size.y
	if w <= 1.0 or h <= 1.0:
		return
	_sync_points_visibility()
	var pad := PAD if embedded else PAD_POPUP
	var usable := w - pad * 2.0
	var top := pad
	# Title (chỉ popup hiện)
	var title := title_label()
	if title != null and title.visible:
		_set_rect(title, pad, top, usable, TITLE_H)
		top += TITLE_H + 4.0
	# Đáy khối Body: bản POPUP chừa chỗ cho Cta/Link ở đáy; bản NHÚNG 2 nút này bị
	# content_instruction.gd ẩn (dùng cờ `embedded` — không dò `visible` vì lúc dàn trang
	# đầu tiên, các nút có thể CHƯA kịp bị ẩn ⇒ chừa chỗ thừa làm ảnh/khối tính sai).
	var bottom := h - pad
	if not embedded:
		bottom = _layout_actions(pad, usable, h) - 6.0
	_set_rect(body(), pad, top, usable, maxf(bottom - top, 1.0))
	_set_section_size()
	_layout_image(usable, maxf(bottom - top, 1.0))
	_scale_image_nodes()


## Cỡ ẢNH theo TỈ LỆ — `Top` (HBox) cao theo ẢNH (hoặc theo khối ĐIỂM nếu khối đó cao hơn),
## khối `Points` nở lấp phần bề ngang còn lại của hàng.
## `body_h` TRUYỀN VÀO (bề cao khối nội dung vừa đặt) — không đọc `body.size` vì lúc này
## container có thể chưa xếp xong, đọc vào sẽ ra cỡ cũ.
func _layout_image(usable: float, body_h: float) -> void:
	var img := image()
	if img == null:
		return
	if body_h <= 1.0:
		body_h = size.y
	var ratio := image_ratio()
	var row_h := clampf(body_h * ROW_FACTOR, ROW_MIN_H, ROW_MAX_H)
	var img_w := minf(row_h * ratio, usable * IMG_MAX_FRAC)
	var img_h := img_w / ratio
	img.custom_minimum_size = Vector2(roundf(img_w), roundf(img_h))


func _set_section_size() -> void:
	var sec := section_label()
	if sec == null:
		return
	if embedded:
		sec.add_theme_font_size_override("font_size", SECTION_SIZE_EMBED)
	else:
		sec.remove_theme_font_size_override("font_size")


## Khối ĐIỂM: ẩn khi trang không có điểm; cấp bề cao tối thiểu để `Top` không cắt hàng điểm
## (Panel không tự gom min của con như container).
func _sync_points_visibility() -> void:
	var box := points_box()
	if box == null:
		return
	var list := points_list()
	var any := list != null and list.get_child_count() > 0
	box.visible = any
	if any and list != null:
		box.custom_minimum_size = Vector2(0.0,
				POINTS_TOP + list.get_combined_minimum_size().y + POINTS_BOTTOM)


## Dàn Cta/Link ở ĐÁY (bỏ qua node đang ẩn — bản nhúng ẩn cả 2); trả mép trên khối hành động
func _layout_actions(x: float, w: float, h: float) -> float:
	var top := h
	var link := link_button()
	if link != null and link.visible:
		top -= LINK_H
		link.position = Vector2(x, top)
		link.size = Vector2(w, LINK_H)
		top -= 4.0
	var cta := cta_button()
	if cta != null and cta.visible:
		top -= CTA_H
		cta.position = Vector2(x, top)
		cta.size = Vector2(w, CTA_H)
		top -= 6.0
	return top


## Co cỡ CHỮ-TRÊN-ẢNH + BADGE SỐ theo cỡ ẢNH THẬT (metadata/base_* do generator ghi)
## ⇒ ảnh nhỏ hơn cỡ thiết kế mà chữ không bị tràn khung.
func _scale_image_nodes() -> void:
	var img := image()
	if img == null or img.size.x <= 1.0:
		return
	var scale := img.size.x / IMG_DESIGN_W
	for child in img.get_children():
		if child.has_meta("base_size"):
			var base_size := float(child.get_meta("base_size"))
			var d := maxf(base_size * scale, 4.0)
			var center: Vector2 = child.position + child.size * 0.5
			child.size = Vector2(d, d)
			child.position = center - Vector2(d, d) * 0.5
			var num := child.get_node_or_null("Num") as Label
			if num != null and child.has_meta("base_font"):
				var base_font := float(child.get_meta("base_font"))
				num.add_theme_font_size_override("font_size",
						int(maxf(round(base_font * scale), 6.0)))
		elif child is Label and child.has_meta("base_font"):
			var font_base := float(child.get_meta("base_font"))
			child.add_theme_font_size_override("font_size",
					int(maxf(round(font_base * scale), 6.0)))


func _set_rect(node: Control, x: float, y: float, w: float, h: float) -> void:
	if node == null:
		return
	node.position = Vector2(x, y)
	node.size = Vector2(maxf(w, 1.0), maxf(h, 1.0))
