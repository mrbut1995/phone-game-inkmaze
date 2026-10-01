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

const TAB_AVATAR := "avatar"
const TAB_FRAME := "frame"

const COLOR_TAB_ON := Color(1, 1, 1, 1)
const COLOR_TAB_OFF := Color(0.3922, 0.4549, 0.5451)   # #64748B
const COLOR_HINT := Color(0.4431, 0.5451, 0.6196)      # #718B9E
const COLOR_WARN := Color(0.8471, 0.2667, 0.2667)      # #D84444

## Phát khi bấm LƯU và có thay đổi thật sự được ghi vào hồ sơ
signal profile_saved

var _tab := TAB_AVATAR
var _pending_avatar := ""
var _pending_frame := ""
var _pending_name := ""
var _hint_token := 0

@onready var _preview_avatar: TextureRect = get_node_or_null("Panel/Content/Preview/Avatar")
@onready var _preview_frame: TextureRect = get_node_or_null("Panel/Content/Preview/Frame")
@onready var _name_edit: LineEdit = get_node_or_null("Panel/Content/Preview/NameEdit")
@onready var _name_hint: Label = get_node_or_null("Panel/Content/Preview/NameHint")
@onready var _grid: GridContainer = get_node_or_null("Panel/Content/Scroll/Grid")
@onready var _tab_avatar: Button = get_node_or_null("Panel/Content/Tabs/TabAvatar")
@onready var _tab_frame: Button = get_node_or_null("Panel/Content/Tabs/TabFrame")


# ---------------------------------------------------------------------------
# Vòng đời
# ---------------------------------------------------------------------------
func _on_open() -> void:
	_tab = TAB_AVATAR
	_pending_avatar = Profile.avatar_id()
	_pending_frame = Profile.frame_id()
	_pending_name = Profile.display_name()
	if _name_edit != null:
		_name_edit.text = _pending_name
	_refresh_tabs()
	_refresh_preview()
	_rebuild_grid()


# ---------------------------------------------------------------------------
# API công khai (test)
# ---------------------------------------------------------------------------
func tab() -> String:
	return _tab


func item_count() -> int:
	return _items().size()


func item_node(ident: String) -> EditProfileItem:
	return _grid.get_node_or_null("Item_" + ident) as EditProfileItem if _grid != null else null


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


func set_tab(tab_id: String) -> void:
	if tab_id == _tab:
		return
	_tab = tab_id
	_refresh_tabs()
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
	_style_tab(_tab_avatar, _tab == TAB_AVATAR)
	_style_tab(_tab_frame, _tab == TAB_FRAME)


func _style_tab(button: Button, active: bool) -> void:
	if button == null:
		return
	var bg_off := button.get_node_or_null("BgOff")
	var bg_on := button.get_node_or_null("BgOn")
	if bg_off != null:
		bg_off.visible = not active
	if bg_on != null:
		bg_on.visible = active
	var label := button.get_node_or_null("Text") as Label
	if label != null:
		_tint(label, COLOR_TAB_ON if active else COLOR_TAB_OFF)


func _refresh_preview() -> void:
	if _preview_avatar != null:
		_preview_avatar.texture = load(Profile.avatar_icon(_pending_avatar)) as Texture2D
	if _preview_frame != null:
		_preview_frame.texture = load(Profile.frame_icon(_pending_frame)) as Texture2D


func _refresh_selection() -> void:
	if _grid == null:
		return
	for child in _grid.get_children():
		if child is EditProfileItem:
			var ident := str(child.name).trim_prefix("Item_")
			child.set_item(_entry_of(ident))


## Dựng lại lưới mẫu của tab đang mở (6 món: 3 cột × 2 hàng)
func _rebuild_grid() -> void:
	if _grid == null:
		return
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	for entry in _catalog():
		var item := ITEM_SCENE.instantiate() as EditProfileItem
		item.name = "Item_" + str(entry.get("id", ""))
		item.set_item(entry)
		item.pressed.connect(_on_item_pressed.bind(str(entry.get("id", ""))))
		_grid.add_child(item)
	_refresh_selection()


func _items() -> Array:
	var out: Array = []
	if _grid == null:
		return out
	for child in _grid.get_children():
		if child is EditProfileItem:
			out.append(child)
	return out


func _catalog() -> Array:
	return Profile.avatars() if _tab == TAB_AVATAR else Profile.frames()


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
	if _name_hint == null:
		return
	_hint_token += 1
	var token := _hint_token
	_name_hint.text = text
	_tint(_name_hint, color)
	await get_tree().create_timer(1.6).timeout
	if token == _hint_token and is_instance_valid(_name_hint):
		_refresh_hint_default()


func _refresh_hint_default() -> void:
	if _name_hint == null:
		return
	_name_hint.text = tr("STR_EDIT_FRAME_HINT") if _tab == TAB_FRAME else tr("STR_EDIT_NAME_HINT")
	_tint(_name_hint, COLOR_HINT)


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
