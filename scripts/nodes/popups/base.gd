class_name BasePopup
extends Control
## ============================================================================
## Popup cơ sở (nodes/popups/base.tscn)
## - Được PopupManager tạo khi mở và tự xoá khi đóng (không instance sẵn).
## - Tự chạy hiệu ứng: nền mờ fade + mảnh giấy phóng nhẹ như dán lên màn hình.
## - Chặn input phía sau, đóng bằng nút Back nếu close_on_back = true.
## - Bấm/chạm vào vùng nền mờ (Dim) NGOÀI thẻ popup cũng đóng nếu close_on_outside = true.
##
## Popup con override _on_open() / _on_close() để nạp dữ liệu và phát signal.
## ============================================================================

signal opened
signal closed

@export_group("Hiệu ứng mở / đóng")
@export_range(0.05, 1.0, 0.01) var dur_in := 0.22
@export_range(0.05, 1.0, 0.01) var dur_out := 0.14
@export_range(0.5, 1.0, 0.01) var scale_from := 0.92

## Id do PopupManager gán khi mở (khoá trong POPUPS hoặc tên file scene)
var popup_id: String = ""
## Dữ liệu truyền vào lúc mở popup
var data: Dictionary = {}
## Có đóng popup khi bấm nút Back / Esc không
@export var close_on_back := true
## Có đóng popup khi bấm/chạm vào NỀN MỜ bên ngoài thẻ popup không.
## (Popup bắt buộc như đếm ngược ghi nhớ cứ để nguyên — nền của nó vốn đang ẩn nên
## không bao giờ nhận được cú bấm.)
@export var close_on_outside := true

var _closing := false
## Tween hiệu ứng đang chạy (mở HOẶC đóng) — phải HUỶ khi bắt đầu hiệu ứng mới,
## nếu không tween đóng cũ vẫn chạy tiếp và `_finish_close()` sẽ xoá popup ngay
## sau khi vừa mở lại (bug: popup Game Over "nháy hiện rồi biến mất").
var _tween: Tween = null

## Node binding: khai `node_paths` + `NodePath` ngay trong scene (.tscn) — mã KHÔNG tự tìm
## node bằng đường dẫn chuỗi nữa (xem `scripts/scenes/layout/chapters_layout.gd`).
@export var dim: ColorRect = null
@export var panel: Control = null
@export var anim_player: AnimationPlayer = null

# --- Bố cục theo tỉ lệ màn hình ---------------------------------------------

func _enter_tree() -> void:
	# Popup con override `_ready()` nên dùng `_enter_tree` + `_notification` (xem base scene).
	var vp := get_viewport()
	if vp != null and not vp.size_changed.is_connected(_apply_canvas_layout):
		vp.size_changed.connect(_apply_canvas_layout)
	_setup_dim()
	_apply_canvas_layout()


func _notification(what: int) -> void:
	if what == NOTIFICATION_READY or what == NOTIFICATION_RESIZED:
		_apply_canvas_layout()


## Nền mờ (Dim) phủ TOÀN màn hình: popup nằm trong CỘT NỘI DUNG 1080px canh giữa
## (xem scripts/scenes/base.gd) nên màn rộng hơn 9:16 sẽ có 2 bên là nền giấy —
## dim phải trùm cả hai bên, còn thẻ popup (Panel) canh GIỮA CẢ HAI CHIỀU của canvas
## (màn cao hơn thiết kế 1920 thì thẻ phải ở giữa màn hình, không dính lên trên).
func _apply_canvas_layout() -> void:
	if not is_inside_tree():
		return
	if dim == null:
		return
	# Dim phải phủ TOÀN canvas: giữ nó ở chế độ POSITION (anchors mép 0) — nếu scene để
	# anchors full-rect thì 2 lệnh gán dưới đây bị hệ anchor GHI ĐÈ (Dim chỉ phủ khung node
	# cha = CỘT nội dung ⇒ hai bên màn rộng không tối — lỗi Dim của popup Hồ sơ).
	if dim.anchor_left != 0.0 or dim.anchor_top != 0.0 \
			or dim.anchor_right != 0.0 or dim.anchor_bottom != 0.0:
		dim.set_anchors_preset(Control.PRESET_TOP_LEFT, true)
	var canvas := get_viewport_rect().size
	var dim_pos := -global_position
	if dim.position != dim_pos:
		dim.position = dim_pos
	if dim.size != canvas:
		dim.size = canvas
	# Thẻ nội dung: canh giữa theo canvas (bỏ qua offset thiết kế của từng popup)
	if panel != null and panel.size.x > 0.0 and panel.size.y > 0.0:
		var target := Vector2(
			floorf((canvas.x - panel.size.x) * 0.5) - global_position.x,
			floorf((canvas.y - panel.size.y) * 0.5) - global_position.y)
		if panel.position != target:
			panel.position = target


# --- Bấm nền mờ để đóng ------------------------------------------------------

## Canh nền mờ (Dim) HỨNG chuột khi cho phép bấm ra ngoài. DÂY `gui_input` khai
## bằng `[connection]` trong `base.tscn` (vá 2 popup tự dựng Dim riêng:
## `edit_profile.tscn` + `language.tscn`).
func _setup_dim() -> void:
	if dim == null:
		return
	if close_on_outside:
		# Nền phải HỨNG chuột (STOP) mới nhận được cú bấm ra ngoài;
		# để IGNORE thì cú bấm xuyên thẳng xuống màn hình phía sau.
		dim.mouse_filter = Control.MOUSE_FILTER_STOP


## Bấm/chạm vào NỀN MỜ ngoài thẻ popup ⇒ đóng popup (giống bấm Back).
## Cú bấm TRONG thẻ do node thẻ/nút hứng trước nên không bao giờ tới nền.
func _on_dim_gui_input(event: InputEvent) -> void:
	if not close_on_outside or _closing:
		return
	var mouse := event as InputEventMouseButton
	if mouse != null and mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed:
		close()
		return
	var touch := event as InputEventScreenTouch
	if touch != null and touch.pressed:
		close()


# --- Vòng đời ---------------------------------------------------------------

## Mở popup với dữ liệu kèm theo (được gọi bởi PopupManager)
func open(p_data: Dictionary = {}) -> void:
	data = p_data
	# Mở lại trong lúc đang đóng (mở trùng id, mở nhanh liên tiếp): huỷ tween đóng cũ
	_kill_tween()
	_closing = false
	visible = true

	_on_open()

	if anim_player != null and anim_player.has_animation("open"):
		if panel != null:
			panel.pivot_offset = panel.size * 0.5
		# Dây `animation_finished → _on_animation_finished` khai trong `base.tscn` (cùng scene,
		# popup con kế thừa dây này nên KHÔNG nối lại trong code)
		anim_player.play("open")
	else:
		# Fallback khi scene thiếu animation "open" (các popup đã khai "open" trong .tscn)
		if dim != null:
			dim.modulate = Color(1, 1, 1, 0)
		if panel != null:
			panel.pivot_offset = panel.size * 0.5
			panel.scale = Vector2.ONE * scale_from
			panel.modulate = Color(1, 1, 1, 0)

		var tw := create_tween()
		_tween = tw
		tw.set_parallel(true)
		if dim != null:
			tw.tween_property(dim, "modulate:a", 1.0, dur_in)
		if panel != null:
			tw.tween_property(panel, "modulate:a", 1.0, dur_in)
			tw.tween_property(panel, "scale", Vector2.ONE, dur_in).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.chain().tween_callback(_on_opened_anim_done)

	opened.emit()


## Đóng popup: chạy hiệu ứng rồi tự xoá khỏi cây scene
func close() -> void:
	# Nếu đã đang đóng thì bỏ qua (tránh chạy 2 tween đóng chồng nhau)
	if _closing:
		return
	_closing = true
	_on_close()

	_kill_tween()
	if anim_player != null and anim_player.has_animation("close"):
		# Dây `animation_finished → _on_animation_finished` khai trong `base.tscn` (cùng scene)
		anim_player.play("close")
	else:
		# Fallback khi scene thiếu animation "close"
		var tw := create_tween()
		_tween = tw
		tw.set_parallel(true)
		if dim != null:
			tw.tween_property(dim, "modulate:a", 0.0, dur_out)
		if panel != null:
			tw.tween_property(panel, "modulate:a", 0.0, dur_out)
			tw.tween_property(panel, "scale", Vector2.ONE * scale_from, dur_out)
		tw.chain().tween_callback(_finish_close)

## Cuối animation mở/đóng popup (dây `animation_finished` khai trong `base.tscn`)
func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == &"open":
		_on_opened_anim_done()
	elif anim_name == &"close":
		_finish_close()


func is_closing() -> bool:
	return _closing


# --- Hook cho popup con -----------------------------------------------------

## Nạp dữ liệu / dựng nội dung trước khi hiệu ứng mở chạy
func _on_open() -> void:
	pass


## Dọn dẹp (ngắt kết nối, dừng tween...) trước khi hiệu ứng đóng chạy
func _on_close() -> void:
	pass


## Hiệu ứng mở kết thúc
func _on_opened_anim_done() -> void:
	pass


# --- Hiệu ứng đóng -----------------------------------------------------------

func _finish_close() -> void:
	# Trong lúc tween đóng chạy, popup có thể được MỞ LẠI (open) -> không xoá nữa.
	if not _closing:
		return
	closed.emit()
	queue_free()


## Huỷ tween hiệu ứng đang chạy (nếu có) để không chồng hiệu ứng lên nhau
func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
