class_name LanguagePopup
extends BasePopup
## ============================================================================
## Popup: Chọn ngôn ngữ (nodes/popups/language.tscn) - mockup popup_language.svg
## - Danh sách ngôn ngữ dựng động từ LocalizationManager.supported_locales
## - Cờ quốc gia là TextureRect (không dùng emoji)
## - "ÁP DỤNG" mới đổi ngôn ngữ thật, "HỦY BỎ" đóng mà không đổi
## ============================================================================

signal locale_applied(code: String)

const ROW_SCENE := preload("res://nodes/popups/language_row.tscn")
const FLAG_FALLBACK := preload("res://assets/images/icons/flags/flag_generic.svg")

const ROW_HEIGHT := 51.5
## Ngưỡng nhận diện kéo (px) + thời gian khoá bấm hàng sau khi vuốt (giây)
const DRAG_THRESHOLD := 14.0
const CLICK_LOCK_TIME := 0.35

@onready var _list: VBoxContainer = $Panel/Content/Scroll/List
@onready var _scroll: ScrollContainer = $Panel/Content/Scroll

var _pending_locale := ""
var _rows: Dictionary = {}
# Trạng thái kéo/vuốt để cuộn danh sách (xem `_input`)
var _drag_active := false
var _drag_moved := false
var _drag_start_y := 0.0
var _drag_scroll := 0.0
var _click_lock_until := 0.0


func _on_open() -> void:
	_pending_locale = Loc.current()
	_rebuild()
	bind_button("Panel/Content/Buttons/Cancel", _on_cancel_pressed)
	bind_button("Panel/Content/Buttons/Apply", _on_apply_pressed)


# ---------------------------------------------------------------------------
# Dựng danh sách
# ---------------------------------------------------------------------------
func _rebuild() -> void:
	if _list == null:
		return
	for child in _list.get_children():
		child.queue_free()
	_rows.clear()
	for code in Loc.locales():
		_add_row(str(code))
	_update_selection()


func _add_row(code: String) -> void:
	var info := Loc.info(code)

	var row := ROW_SCENE.instantiate() as LanguageRow
	row.name = "Row_" + code
	row.pressed.connect(_on_row_pressed.bind(code))
	_list.add_child(row)
	row.setup(info, _flag_texture(str(info.get("flag", ""))))

	_rows[code] = row


func _flag_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return FLAG_FALLBACK
	return load(path) as Texture2D


func _update_selection() -> void:
	for code in _rows:
		var row: LanguageRow = _rows[code]
		row.set_selected(str(code) == _pending_locale)


# ---------------------------------------------------------------------------
# Tương tác
# ---------------------------------------------------------------------------
# VUỐT DỌC ĐỂ CUỘN DANH SÁCH
# Hàng ngôn ngữ là Button nên "ăn" sự kiện kéo -> ScrollContainer không tự cuộn.
# Tự xử lý ở `_input` (nhận sự kiện trước GUI) rồi `set_input_as_handled()`.
# ---------------------------------------------------------------------------
func _input(event: InputEvent) -> void:
	if _scroll == null or not is_visible_in_tree():
		return
	if event is InputEventScreenTouch and event.index == 0:
		if event.pressed:
			_begin_drag(event.position)
		else:
			_end_drag()
	elif event is InputEventScreenDrag and event.index == 0:
		_update_drag(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_drag(event.position)
		else:
			_end_drag()
	elif event is InputEventMouseMotion:
		if (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			_update_drag(event.position)


func _begin_drag(pos: Vector2) -> void:
	if _scroll == null or not _scroll.get_global_rect().has_point(pos):
		return
	_drag_active = true
	_drag_moved = false
	_drag_start_y = pos.y
	_drag_scroll = float(_scroll.scroll_vertical)


func _update_drag(pos: Vector2) -> void:
	if not _drag_active:
		return
	var delta_y := pos.y - _drag_start_y
	if not _drag_moved:
		if absf(delta_y) < DRAG_THRESHOLD:
			return
		_drag_moved = true          # kéo đủ xa -> coi là VUỐT (không phải bấm)
	_scroll.scroll_vertical = int(_drag_scroll - delta_y)
	_lock_clicks()
	if is_inside_tree():
		get_viewport().set_input_as_handled()


func _end_drag() -> void:
	if not _drag_active:
		return
	_drag_active = false
	if _drag_moved:
		_lock_clicks()


func _clicks_locked() -> bool:
	return _now() < _click_lock_until


func _lock_clicks() -> void:
	_click_lock_until = _now() + CLICK_LOCK_TIME


func _now() -> float:
	return float(Time.get_ticks_msec()) / 1000.0


# ---------------------------------------------------------------------------
func _on_row_pressed(code: String) -> void:
	if _clicks_locked():      # vừa vuốt cuộn -> không tính là bấm chọn
		return
	_pending_locale = code
	_update_selection()
	# SFX: tiếng bút bi vẽ dấu tích
	Sfx.play(Sfx.CHECKBOX)


func _on_apply_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	if _pending_locale != "" and _pending_locale != Loc.current():
		Loc.set_locale(_pending_locale)
	locale_applied.emit(_pending_locale)
	close()


func _on_cancel_pressed() -> void:
	Sfx.play(Sfx.BTN_WOOD_TAP)
	_pending_locale = Loc.current()
	close()
