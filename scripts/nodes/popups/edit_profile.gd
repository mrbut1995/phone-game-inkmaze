class_name EditProfilePopup
extends BasePopup
## ============================================================================
## Popup DIỆN MẠO HỒ SƠ (nodes/popups/edit_profile.tscn)
## — mockup popup_edit_user_display_avatar.svg & popup_edit_user_display_frame.svg
##
## Gồm: thẻ xem trước (avatar + viền khung + ô sửa tên) · 2 tab (AVATAR / VIỀN KHUNG)
## · lưới mẫu cuộn được (mua bằng Xu mực · khoá theo mốc) · Huỷ bỏ / Lưu thay đổi.
##
## Mọi thay đổi chỉ áp vào PlayerProfileManager khi bấm LƯU; trước đó chỉ là "đang chọn"
## (pending) nên bấm HUỶ là thoát nguyên trạng.
## ============================================================================

const ITEM_SCENE := preload("res://nodes/popups/edit_profile_item.tscn")
const PROFILE_DOT_SCENE := preload("res://nodes/popups/profile_dot.tscn")

const TAB_AVATAR := "avatar"
const TAB_FRAME := "frame"
const ITEMS_PER_PAGE := 6
const SWIPE_DRAG_THRESHOLD := 10.0
const SWIPE_PAGE_THRESHOLD := 60.0

const COLOR_TAB_ON := Color(1, 1, 1, 1)
const COLOR_TAB_OFF := Color(0.3922, 0.4549, 0.5451)   # #64748B
const COLOR_HINT := Color(0.4431, 0.5451, 0.6196)      # #718B9E
const COLOR_WARN := Color(0.8471, 0.2667, 0.2667)      # #D84444

## Phát khi bấm LƯU và có thay đổi thật sự được ghi vào hồ sơ
signal profile_saved

var _tab := TAB_AVATAR
var _page := 0
var _pending_avatar := ""
var _pending_frame := ""
var _pending_name := ""
var _hint_token := 0
var _swipe_down := false
var _swipe_dragged := false
var _swipe_start := Vector2.ZERO
var _swipe_last := Vector2.ZERO

## Node binding: khai `node_paths` + `NodePath` trong `edit_profile.tscn`
@export var preview_avatar: TextureRect = null
@export var preview_frame: TextureRect = null
@export var preview_disc: TextureRect = null
@export var name_edit: LineEdit = null
@export var name_hint: Label = null
@export var item_grid: GridContainer = null
@export var page_bar: Control = null
@export var tab_avatar: Button = null
@export var tab_avatar_bg_off: TextureRect = null
@export var tab_avatar_bg_on: TextureRect = null
@export var tab_avatar_text: Label = null
@export var tab_avatar_icon: TextureRect = null
@export var tab_frame: Button = null
@export var tab_frame_bg_off: TextureRect = null
@export var tab_frame_bg_on: TextureRect = null
@export var tab_frame_text: Label = null
@export var tab_frame_icon: TextureRect = null
@export var btn_prev: TextureButton = null
@export var btn_next: TextureButton = null
@export var dots_box: HBoxContainer = null
@export var btn_close: TextureButton = null
@export var btn_cancel: Button = null
@export var btn_save: Button = null


# ---------------------------------------------------------------------------
# Vòng đời
# ---------------------------------------------------------------------------
func _on_open() -> void:
	_tab = TAB_AVATAR
	_page = 0
	_swipe_down = false
	_swipe_dragged = false
	_pending_avatar = Profile.avatar_id()
	_pending_frame = Profile.frame_id()
	_pending_name = Profile.display_name()
	name_edit.text = _pending_name
	_refresh_tabs()
	_refresh_preview()
	_attach_popup_animations()
	_rebuild_grid()


# ---------------------------------------------------------------------------
# API công khai (test)
# ---------------------------------------------------------------------------
func tab() -> String:
	return _tab


func item_count() -> int:
	return _items().size()


func page_index() -> int:
	return _page


func page_count() -> int:
	return _page_count()


func item_node(ident: String) -> EditProfileItem:
	return item_grid.get_node_or_null("Item_" + ident) as EditProfileItem


## Chọn mẫu đang xem thử (bỏ qua khoá / giá — dùng cho test + luồng mua ở `_on_item_pressed`)
func select_pending(ident: String) -> void:
	if ident.is_empty():
		return
	if _tab == TAB_AVATAR:
		_pending_avatar = ident
	else:
		_pending_frame = ident
	_refresh_preview()
	_refresh_selection()
	_pulse_preview()


func set_tab(tab_id: String) -> void:
	if tab_id == _tab:
		return
	_tab = tab_id
	_page = 0
	_refresh_tabs()
	_refresh_hint_default()
	_rebuild_grid()


# ---------------------------------------------------------------------------
# Nút trong popup (dây khai trong edit_profile.tscn)
# ---------------------------------------------------------------------------
func _on_tab_avatar_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	set_tab(TAB_AVATAR)


func _on_tab_frame_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	set_tab(TAB_FRAME)


func _on_page_prev_pressed() -> void:
	if _page <= 0:
		return
	Sfx.play(Sfx.BTN_CLICK)
	_go_to_page(_page - 1)


func _on_page_next_pressed() -> void:
	if _page >= _page_count() - 1:
		return
	Sfx.play(Sfx.BTN_CLICK)
	_go_to_page(_page + 1)


func _on_scroll_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_swipe_down = true
			_swipe_dragged = false
			_swipe_start = touch.position
			_swipe_last = touch.position
		else:
			_finish_swipe()
	elif event is InputEventScreenDrag:
		if not _swipe_down:
			return
		var drag := event as InputEventScreenDrag
		_swipe_last = drag.position
		if absf(_swipe_last.x - _swipe_start.x) >= SWIPE_DRAG_THRESHOLD:
			_swipe_dragged = true
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_swipe_down = true
			_swipe_dragged = false
			_swipe_start = mb.position
			_swipe_last = mb.position
		else:
			_finish_swipe()
	elif event is InputEventMouseMotion:
		if not _swipe_down or not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			return
		var motion := event as InputEventMouseMotion
		_swipe_last = motion.position
		if absf(_swipe_last.x - _swipe_start.x) >= SWIPE_DRAG_THRESHOLD:
			_swipe_dragged = true


func _on_name_changed(new_text: String) -> void:
	_pending_name = new_text


func _on_cancel_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	close()


func _on_save_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	var changed := false
	if _pending_name != Profile.display_name():
		changed = Profile.set_display_name(_pending_name) or changed
	if _pending_avatar != Profile.avatar_id():
		changed = Profile.equip_avatar(_pending_avatar) or changed
	if _pending_frame != Profile.frame_id():
		changed = Profile.equip_frame(_pending_frame) or changed
	if changed:
		profile_saved.emit()
	close()


func _on_item_pressed(ident: String) -> void:
	var entry := _entry_of(ident)
	if entry.is_empty():
		return
	if bool(entry.get("locked", false)):
		_flash_hint(_flash_lock_text(entry), COLOR_WARN)
		return
	if not bool(entry.get("owned", false)):
		var bought := Profile.buy_avatar(ident) if _tab == TAB_AVATAR else Profile.buy_frame(ident)
		if not bought:
			_flash_hint(tr("STR_EDIT_NOT_ENOUGH_COINS"), COLOR_WARN)
			return
		Sfx.play(Sfx.BTN_CLICK)
	select_pending(ident)
	_refresh_selection()


# ---------------------------------------------------------------------------
# Vẽ lại từng phần
# ---------------------------------------------------------------------------
func _refresh_tabs() -> void:
	_style_tab(tab_avatar_bg_off, tab_avatar_bg_on, tab_avatar_text, tab_avatar_icon, _tab == TAB_AVATAR)
	_style_tab(tab_frame_bg_off, tab_frame_bg_on, tab_frame_text, tab_frame_icon, _tab == TAB_FRAME)


## Tô sáng 1 tab: nền bật/tắt + màu nhãn/icon (node đã bind sẵn trong `edit_profile.tscn`)
func _style_tab(bg_off: TextureRect, bg_on: TextureRect, label: Label, icon: TextureRect, active: bool) -> void:
	bg_off.visible = not active
	bg_on.visible = active
	_tint(label, COLOR_TAB_ON if active else COLOR_TAB_OFF)
	icon.modulate = COLOR_TAB_ON if active else COLOR_TAB_OFF


func _refresh_preview() -> void:
	preview_avatar.texture = load(Profile.avatar_icon(_pending_avatar)) as Texture2D
	preview_frame.texture = load(Profile.frame_icon(_pending_frame)) as Texture2D


func _refresh_selection() -> void:
	for child in item_grid.get_children():
		if child is EditProfileItem:
			var ident := str(child.name).trim_prefix("Item_")
			child.set_item(_entry_of(ident))


## Dựng lại lưới mẫu của tab đang mở (6 món: 3 cột × 2 hàng)
func _rebuild_grid() -> void:
	for child in item_grid.get_children():
		item_grid.remove_child(child)
		child.queue_free()
	var catalog := _catalog()
	var total_pages := _page_count_from(catalog.size())
	_page = clampi(_page, 0, total_pages - 1)
	var from_idx := _page * ITEMS_PER_PAGE
	var to_idx := mini(from_idx + ITEMS_PER_PAGE, catalog.size())
	for idx in range(from_idx, to_idx):
		var entry: Dictionary = catalog[idx]
		var item := ITEM_SCENE.instantiate() as EditProfileItem
		item.name = "Item_" + str(entry.get("id", ""))
		item.set_item(entry)
		item.pressed.connect(_on_item_pressed.bind(str(entry.get("id", ""))))
		item_grid.add_child(item)
	_refresh_selection()
	_refresh_paging_ui()
	_animate_grid_in()


func _items() -> Array:
	var out: Array = []
	for child in item_grid.get_children():
		if child is EditProfileItem:
			out.append(child)
	return out


func _catalog() -> Array:
	return Profile.avatars() if _tab == TAB_AVATAR else Profile.frames()


func _go_to_page(new_page: int) -> void:
	var target := clampi(new_page, 0, _page_count() - 1)
	if target == _page:
		return
	_page = target
	_rebuild_grid()


func _page_count() -> int:
	return _page_count_from(_catalog().size())


func _page_count_from(total_items: int) -> int:
	return maxi(1, int(ceil(float(total_items) / float(ITEMS_PER_PAGE))))


func _refresh_paging_ui() -> void:
	var pages := _page_count()
	page_bar.visible = pages > 1
	btn_prev.disabled = _page <= 0
	btn_prev.modulate = Color(1, 1, 1, 0.45) if btn_prev.disabled else Color(1, 1, 1, 1)
	btn_next.disabled = _page >= pages - 1
	btn_next.modulate = Color(1, 1, 1, 0.45) if btn_next.disabled else Color(1, 1, 1, 1)
	for child in dots_box.get_children():
		dots_box.remove_child(child)
		child.queue_free()
	for idx in range(pages):
		var dot := PROFILE_DOT_SCENE.instantiate() as EditProfileDot
		dot.set_current(idx == _page)
		dot.pressed.connect(_on_dot_pressed.bind(idx))
		dots_box.add_child(dot)


func _on_dot_pressed(index: int) -> void:
	if index == _page:
		return
	Sfx.play(Sfx.BTN_CLICK)
	_go_to_page(index)


func _finish_swipe() -> void:
	if not _swipe_down:
		return
	if _swipe_dragged:
		var dx := _swipe_last.x - _swipe_start.x
		if absf(dx) >= SWIPE_PAGE_THRESHOLD:
			if dx < 0.0 and _page < _page_count() - 1:
				Sfx.play(Sfx.BTN_CLICK)
				_go_to_page(_page + 1)
				get_viewport().set_input_as_handled()
			elif dx > 0.0 and _page > 0:
				Sfx.play(Sfx.BTN_CLICK)
				_go_to_page(_page - 1)
				get_viewport().set_input_as_handled()
	_swipe_down = false
	_swipe_dragged = false


# ---------------------------------------------------------------------------
# Hiệu ứng (animation)
# ---------------------------------------------------------------------------
## Gắn hiệu ứng nhấn nảy cho nút của popup (guard: mỗi node chỉ gắn 1 lần)
func _attach_popup_animations() -> void:
	var buttons: Array[BaseButton] = [btn_close, btn_cancel, btn_save, tab_avatar, tab_frame, btn_prev, btn_next]
	for btn in buttons:
		if btn.has_meta("bounce_attached"):
			continue
		btn.set_meta("bounce_attached", true)
		UIAnim.attach_press_bounce(btn)


## (GIỮ tween) Hiệu ứng xuất hiện so le của các ô — phụ thuộc DỮ LIỆU lúc chạy (thứ tự ô)
func _animate_grid_in() -> void:
	var idx := 0
	for child in item_grid.get_children():
		if child is EditProfileItem:
			var item := child as EditProfileItem
			item.play_entrance(0.028 * idx)
			idx += 1


## (GIỮ tween) Nhịp "nảy" xác nhận khi người chơi chọn mẫu mới (thao tác lúc chạy)
func _pulse_preview() -> void:
	if preview_disc.size.length_squared() > 0.0:
		preview_disc.pivot_offset = preview_disc.size * 0.5
	var tw := preview_disc.create_tween()
	tw.tween_property(preview_disc, "scale", Vector2(1.07, 1.07), 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(preview_disc, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Entry (kèm trạng thái) của 1 món trong tab đang mở
func _entry_of(ident: String) -> Dictionary:
	for entry in _catalog():
		if str(entry.get("id", "")) == ident:
			return entry
	return {}


# ---------------------------------------------------------------------------
# Nhãn gợi ý dưới ô tên (nháy thông báo lỗi rồi trả về như cũ)
# ---------------------------------------------------------------------------
func _flash_hint(text: String, color: Color) -> void:
	_hint_token += 1
	var token := _hint_token
	name_hint.text = text
	_tint(name_hint, color)
	await get_tree().create_timer(1.6).timeout
	if token == _hint_token and is_instance_valid(name_hint):
		_refresh_hint_default()


func _refresh_hint_default() -> void:
	name_hint.text = tr("STR_EDIT_FRAME_HINT") if _tab == TAB_FRAME else tr("STR_EDIT_NAME_HINT")
	_tint(name_hint, COLOR_HINT)


func _flash_lock_text(entry: Dictionary) -> String:
	var value := int(entry.get("lock_value", 0))
	match str(entry.get("lock_stat", "")):
		"daily_streak":
			return tr("STR_LOCK_STREAK").format([value])
		"points":
			return tr("STR_LOCK_POINTS").format([value])
		_:
			return tr("STR_LOCK_DUNGEON").format([value])


func _tint(label: Label, color: Color) -> void:
	if label.label_settings == null:
		label.add_theme_color_override("font_color", color)
		return
	var settings := label.label_settings.duplicate() as LabelSettings
	settings.font_color = color
	label.label_settings = settings
