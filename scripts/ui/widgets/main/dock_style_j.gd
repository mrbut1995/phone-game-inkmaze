extends RefCounted
## ============================================================================
## Dock kiểu "J" — TOÀN BỘ hình ảnh là ASSET (svg → png 2x); script KHÔNG dựng node,
## KHÔNG đặt anchor/offset: cấu trúc + cỡ + màu chữ đã khai trong `.tscn`.
##   · panel giấy lò xo : `dock_panel.png`           9-slice — node `PaperHolder/PaperArt` của `Dock`
##   · tab thường       : `dock_tab_<key>.png`       node `TabArt` của `dock_button.tscn`
##   · tab focus        : `dock_tab_<key>_focus.png` node `TabArtFocus` (ẩn sẵn trong scene)
## `<key>` = shop · rank · daily · badges. Đổi theme = thay file cùng tên (cùng cỡ logic) hoặc `ART_DIR`;
## nguồn SVG ở `assets/images/dock/`, xuất PNG bằng `tools/svg_to_png.py`.
##
## Phần RUNTIME còn lại ở đây (đúng phạm vi "code chỉ xử lý runtime"):
##   · gán texture theo `<key>` — dữ liệu theo tab, không phải bố cục
##   · co giãn `PaperArt` theo cỡ panel thật (phụ thuộc kích thước lúc chạy)
##   · trạng thái focus (nhấn giữ ⇒ thẻ nhô lên) + tween
## Không có `class_name` (tránh trùng class toàn project) — dùng qua `preload`.
## ============================================================================

## Thư mục art (đổi theme: sửa dòng này nếu cần)
const ART_DIR := "res://assets/images-png/dock/"

## Vòng gáy nhô khỏi mép trên panel (logic px)
const PANEL_OVERHANG := 12.0

## Art focus neo theo ĐÁY nút: chưa focus nằm ở `FOCUS_BOTTOM_REST`, khi focus trượt xuống `FOCUS_BOTTOM`
const FOCUS_SIZE := Vector2(96.0, 126.0)
const FOCUS_BOTTOM := 2.0
const FOCUS_BOTTOM_REST := 14.0
const ANIM_SEC := 0.14


## Panel chứa hàng nút: cho `PaperArt` phủ đúng khung, chừa `PANEL_OVERHANG` phía trên cho vòng gáy.
## Art vẽ 2x ⇒ kích thước gấp đôi + `scale = 0.5` (khai sẵn trong scene) để nét dày đúng điểm ảnh.
static func apply_panel(panel: Control) -> void:
	if panel == null:
		return
	var holder := panel.get_node_or_null("PaperHolder") as Control
	if holder == null:
		return
	var art := holder.get_node_or_null("PaperArt") as NinePatchRect
	if art == null:
		return
	var fit := func() -> void:
		art.position = Vector2(0.0, -PANEL_OVERHANG)  # keep-code: pose tính theo cỡ panel thật
		art.size = Vector2(holder.size.x, holder.size.y + PANEL_OVERHANG) * 2.0
	# keep-code: callback phụ thuộc KÍCH THƯỚC lúc chạy (không khai tĩnh trong .tscn được)
	if not bool(holder.get_meta("j_fit_wired", false)):
		holder.set_meta("j_fit_wired", true)
		holder.resized.connect(fit)
	fit.call()


## Gán art theo `<key>` cho 1 nút dock (cấu trúc `TabArt` / `TabArtFocus` đã có trong `dock_button.tscn`)
static func apply(button: Control, key: String) -> void:
	if button == null:
		return
	var art := button.get_node_or_null("TabArt") as TextureRect
	if art != null:
		art.texture = _tex("dock_tab_%s.png" % key)
	var focus := button.get_node_or_null("TabArtFocus") as TextureRect
	if focus != null:
		focus.texture = _tex("dock_tab_%s_focus.png" % key)
	button.set_meta("dock_key", key)
	button.set_meta("j_down", false)
	_set_focus(button, false, false)


## Đang nhấn giữ nút (signal `button_down` / `button_up` / `mouse_exited` của scene gọi vào)
static func set_down(button: Control, down: bool) -> void:
	if button == null:
		return
	button.set_meta("j_down", down)
	_set_focus(button, down, true)


static func _tex(file: String) -> Texture2D:
	var path := ART_DIR + file
	if not ResourceLoader.exists(path):
		push_warning("Dock art thiếu: " + path)
		return null
	return load(path) as Texture2D


## Đổi trạng thái focus: thẻ trắng nhô lên, art thường mờ đi (hoặc ngược lại)
static func _set_focus(button: Control, focused: bool, animate: bool) -> void:
	var normal := button.get_node_or_null("TabArt") as Control
	var focus := button.get_node_or_null("TabArtFocus") as Control
	if focus != null and focused:
		focus.visible = true
	var bottom := FOCUS_BOTTOM if focused else FOCUS_BOTTOM_REST
	if animate and button.is_inside_tree():
		var tween := button.create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if focus != null:
			tween.tween_property(focus, "offset_top", bottom - FOCUS_SIZE.y, ANIM_SEC)
			tween.tween_property(focus, "offset_bottom", bottom, ANIM_SEC)
			tween.tween_property(focus, "modulate:a", 1.0 if focused else 0.0, ANIM_SEC)
		if normal != null:
			tween.tween_property(normal, "modulate:a", 0.0 if focused else 1.0, ANIM_SEC)
		if not focused and focus != null:
			tween.chain().tween_callback(func() -> void:
				focus.visible = bool(button.get_meta("j_down", false)))
		return
	if focus != null:
		focus.offset_top = bottom - FOCUS_SIZE.y
		focus.offset_bottom = bottom
		focus.modulate.a = 1.0 if focused else 0.0
		focus.visible = focused
	if normal != null:
		normal.modulate.a = 0.0 if focused else 1.0
