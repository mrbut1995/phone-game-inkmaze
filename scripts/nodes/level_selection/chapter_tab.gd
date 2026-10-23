class_name ChapterTab
extends Button
## ============================================================================
## Component: 1 TAB CHƯƠNG trên màn Chọn màn (nodes/level_selection/chapter_tab.tscn)
##
## 5 trạng thái (thứ tự ưu tiên khi tính):
##   SELECTED — tab đang xem (rộng hơn, nền giấy đậm, chữ "CHƯƠNG n")
##   OPEN     — chương đã mở, không được chọn
##   READY    — đủ Sao để mở nhưng chưa mở ⇒ huy hiệu đỏ "!" + nhịp thở
##   LOCKED   — chưa đủ Sao
##   COMING   — chương chưa có màn nào (không bấm được)
##
## Art lấy qua `@export` (đổi art không phải sửa code): `tab_selected` (cam) · `tab_normal` (kem) ·
## `tab_locked` (xám nét đứt). Màu chữ theo trạng thái cũng là `@export` (không cần theme variation mới).
## Tab CHỈ hiển thị + phát signal — màn Chọn màn quyết định đổi chương hay mở khung khoá.
## ============================================================================

signal tab_pressed(chapter_id: int)
## Tab LOCKED/READY: màn Chọn màn mở khung "chương đang khoá"
signal locked_pressed(chapter_id: int)

enum State { SELECTED, OPEN, READY, LOCKED, COMING }

## Bề rộng theo trạng thái (px thiết kế): tab chọn rộng hơn để lộ chữ "CHƯƠNG n".
## Bản ngang đặt 92×40 / 52×34 ngay trên instance trong layout.
@export var width_selected := 150.0
@export var width_normal := 70.0
@export var height_selected := 54.0
@export var height_normal := 46.0
@export var font_size_selected := 14
@export var font_size_normal := 15

@export_group("Màu chữ")
@export var color_selected := Color(1, 1, 1, 1)
@export var color_normal := Color(0.0863, 0.2745, 0.3882, 1)
@export var color_locked := Color(0.6039, 0.6824, 0.7412, 1)

@export_group("Art")
## Khung giấy của tab (NinePatch): bản đang chọn / bản thường
@export var art_selected: Texture2D = null
@export var art_normal: Texture2D = null
@export var art_locked: Texture2D = null
@export var icon_lock: Texture2D = null

@export_group("Node binding")
@export var bg: NinePatchRect = null
@export var lbl_title: Label = null
@export var lock_icon: TextureRect = null
## Huy hiệu "!" khi chương ĐỦ SAO nhưng chưa mở
@export var ready_badge: Control = null
@export var pulse_anim: AnimationPlayer = null

var chapter_id: int = 1
var state: State = State.OPEN


func _ready() -> void:
	_connect_locale_signal()


## Đổi ngôn ngữ (hoặc bảng dịch nạp XONG sau `_ready` của màn) ⇒ viết lại nhãn tab
func _connect_locale_signal() -> void:
	var loc: Node = get_node_or_null("/root/LocalizationManager")
	if loc != null and loc.has_signal("locale_changed") \
			and not loc.is_connected("locale_changed", _on_locale_changed):
		loc.connect("locale_changed", _on_locale_changed)


func _on_locale_changed(_locale: String) -> void:
	apply_locale()


## Nhãn theo ngôn ngữ hiện tại: tab đang chọn hiện "CHƯƠNG n", tab khác chỉ hiện số cho gọn
func apply_locale() -> void:
	if lbl_title == null:
		return
	lbl_title.text = str(chapter_id)
	if state == State.SELECTED:
		lbl_title.text = str(TranslationServer.translate("STR_CHAPTER_FORMAT").format([chapter_id]))
	_apply_label_style()


## Màu + cỡ chữ theo trạng thái; chữ nhích sang phải khi có ổ khoá bên trái
func _apply_label_style() -> void:
	if lbl_title == null:
		return
	var color := color_normal
	match state:
		State.SELECTED:
			color = color_selected
		State.LOCKED, State.COMING:
			color = color_locked
	lbl_title.add_theme_color_override("font_color", color)
	lbl_title.add_theme_font_size_override("font_size",
		font_size_selected if state == State.SELECTED else font_size_normal)
	var has_lock := state == State.LOCKED or state == State.COMING
	lbl_title.offset_left = 16.0 if has_lock else 4.0
	lbl_title.offset_right = -4.0


## `info` = { chapter_id, state, star_cost, stars_have }
func setup(info: Dictionary) -> void:
	chapter_id = int(info.get("chapter_id", 1))
	state = int(info.get("state", State.OPEN)) as State
	apply_locale()
	var is_selected := state == State.SELECTED
	custom_minimum_size = Vector2(
		width_selected if is_selected else width_normal,
		height_selected if is_selected else height_normal)
	# Mọi tab ngồi sát ĐÁY hàng (tab chọn cao hơn nhô lên), nối liền thẻ chương bên dưới
	size_flags_vertical = Control.SIZE_SHRINK_END
	if bg != null:
		var art: Texture2D = art_selected if is_selected else art_normal
		if (state == State.LOCKED or state == State.COMING) and art_locked != null:
			art = art_locked
		if art != null:
			bg.texture = art
		bg.modulate = Color(1, 1, 1, 0.6) if state == State.COMING else Color(1, 1, 1, 1)
	if lock_icon != null:
		lock_icon.visible = state == State.LOCKED or state == State.COMING
		if icon_lock != null:
			lock_icon.texture = icon_lock
	if ready_badge != null:
		ready_badge.visible = state == State.READY
	disabled = state == State.COMING
	mouse_default_cursor_shape = Control.CURSOR_ARROW if state == State.COMING \
		else Control.CURSOR_POINTING_HAND
	_update_pulse()


## Tab READY "thở" nhẹ để hút mắt; tab khác đứng yên
func _update_pulse() -> void:
	if pulse_anim == null or not pulse_anim.has_animation(&"ready"):
		return
	if state == State.READY:
		if not pulse_anim.is_playing():
			pulse_anim.play(&"ready")
	elif pulse_anim.is_playing():
		pulse_anim.stop()


## Tab đang chọn (màn Chọn màn dùng để cuộn tab vào giữa tầm nhìn)
func is_selected() -> bool:
	return state == State.SELECTED


func _on_pressed() -> void:
	match state:
		State.SELECTED, State.OPEN:
			tab_pressed.emit(chapter_id)
		State.READY, State.LOCKED:
			locked_pressed.emit(chapter_id)
		_:
			return    # COMING: không bấm được
