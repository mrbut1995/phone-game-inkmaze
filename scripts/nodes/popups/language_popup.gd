class_name LanguagePopup
extends BasePopup
## ============================================================================
## Popup: Chọn ngôn ngữ (nodes/popups/language.tscn) - mockup popup_language.svg
## - Danh sách ngôn ngữ dựng động từ LocalizationManager.supported_locales
## - Cờ quốc gia là TextureRect (không dùng emoji)
## - "ÁP DỤNG" mới đổi ngôn ngữ thật, "HỦY BỎ" đóng mà không đổi
## ============================================================================

signal locale_applied(code: String)

const TEX_ROW_NORMAL := preload("res://assets/images/popups/lang_item_normal.svg")
const TEX_ROW_SELECTED := preload("res://assets/images/popups/lang_item_selected.svg")
const TEX_ROW_PRESSED := preload("res://assets/images/popups/lang_item_pressed.svg")
const TEX_ROW_FOCUS := preload("res://assets/images/popups/lang_item_focus.svg")
const TEX_CHECK := preload("res://assets/images/popups/icon_check_red.svg")
const FLAG_FALLBACK := preload("res://assets/images/icons/flags/flag_generic.svg")

const ROW_HEIGHT := 103.0

@onready var _list: VBoxContainer = $Panel/Content/Scroll/List

var _pending_locale := ""
var _rows: Dictionary = {}


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

	var row := TextureButton.new()
	row.name = "Row_" + code
	# Chiều cao chọn theo tỉ lệ texture (616x106) để không méo hình khi kéo giãn ngang
	row.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	row.toggle_mode = true
	row.ignore_texture_size = true
	row.texture_normal = TEX_ROW_NORMAL
	row.texture_pressed = TEX_ROW_SELECTED
	row.texture_hover = TEX_ROW_PRESSED
	row.texture_focused = TEX_ROW_FOCUS
	row.focus_mode = Control.FOCUS_NONE
	row.pressed.connect(_on_row_pressed.bind(code))
	_list.add_child(row)

	# Cờ quốc gia: ảnh svg, thay cho emoji 🇻🇳 trước đây
	var flag := TextureRect.new()
	flag.name = "Flag"
	flag.texture = _flag_texture(str(info.get("flag", "")))
	flag.position = Vector2(26, 26)
	flag.size = Vector2(52, 52)
	flag.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	flag.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(flag)

	var name_lbl := Label.new()
	name_lbl.name = "Name"
	name_lbl.theme_type_variation = &"PopupRowLabel"
	name_lbl.text = str(info.get("name", code))
	name_lbl.position = Vector2(90, 12)
	name_lbl.size = Vector2(400, 40)
	row.add_child(name_lbl)

	var sub_lbl := Label.new()
	sub_lbl.name = "Sub"
	sub_lbl.theme_type_variation = &"LangSub"
	sub_lbl.text = str(info.get("sub", ""))
	sub_lbl.position = Vector2(90, 52)
	sub_lbl.size = Vector2(400, 30)
	row.add_child(sub_lbl)

	# Dấu tích đỏ báo ngôn ngữ đang chọn (ẩn/hiện theo lựa chọn)
	var check := TextureRect.new()
	check.name = "Check"
	check.texture = TEX_CHECK
	check.position = Vector2(520, 32)
	check.size = Vector2(40, 30)
	check.visible = false
	row.add_child(check)

	_rows[code] = {"button": row, "check": check}


func _flag_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return FLAG_FALLBACK
	return load(path) as Texture2D


func _update_selection() -> void:
	for code in _rows:
		var entry: Dictionary = _rows[code]
		var button: TextureButton = entry["button"]
		var check: TextureRect = entry["check"]
		button.button_pressed = (str(code) == _pending_locale)
		check.visible = (str(code) == _pending_locale)


# ---------------------------------------------------------------------------
# Tương tác
# ---------------------------------------------------------------------------
func _on_row_pressed(code: String) -> void:
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
