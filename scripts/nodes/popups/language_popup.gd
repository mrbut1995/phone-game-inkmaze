class_name LanguagePopup
extends Control
## ============================================================================
## Popup chọn ngôn ngữ (mockup popup_language.svg)
## - Danh sách ngôn ngữ dựng động từ LocalizationManager.SUPPORTED_LOCALES.
## - "ÁP DỤNG" mới đổi ngôn ngữ thật, "HỦY BỎ" đóng mà không đổi.
## ============================================================================

signal locale_applied(code: String)
signal closed

const TEX_ROW_NORMAL := preload("res://assets/images/popups/lang_item_normal.svg")
const TEX_ROW_SELECTED := preload("res://assets/images/popups/lang_item_selected.svg")
const TEX_ROW_FOCUS := preload("res://assets/images/popups/lang_item_focus.svg")
const TEX_CHECK := preload("res://assets/images/popups/icon_check_red.svg")

const STYLE_FLAG := preload("res://resources/settings/text/text_settings_title.tres")
const STYLE_NAME := preload("res://resources/settings/text/text_settings_row.tres")
const STYLE_SUB := preload("res://resources/settings/text/text_settings_desc.tres")

const ROW_HEIGHT := 103.0

@onready var _list: VBoxContainer = $Panel/Content/Scroll/List
@onready var _btn_cancel: TextureButton = $Panel/Content/Buttons/Cancel
@onready var _btn_apply: TextureButton = $Panel/Content/Buttons/Apply

var _pending_locale := ""
var _rows: Dictionary = {}


func _ready() -> void:
	hide()
	if _btn_cancel != null:
		_btn_cancel.pressed.connect(_on_cancel_pressed)
	if _btn_apply != null:
		_btn_apply.pressed.connect(_on_apply_pressed)


## Mở popup, dựng lại danh sách theo ngôn ngữ đang dùng
func open() -> void:
	_pending_locale = Loc.current()
	_rebuild()
	show()


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
	# Chieu cao chon theo ti le texture (616x106) de khong meo hinh khi keo gian ngang
	row.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	row.toggle_mode = true
	row.ignore_texture_size = true
	row.texture_normal = TEX_ROW_NORMAL
	row.texture_pressed = TEX_ROW_SELECTED
	row.texture_hover = TEX_ROW_NORMAL
	row.focus_mode = Control.FOCUS_NONE
	row.pressed.connect(_on_row_pressed.bind(code))
	_list.add_child(row)

	var flag := Label.new()
	flag.label_settings = STYLE_FLAG
	flag.text = str(info.get("flag", ""))
	flag.position = Vector2(30, 24)
	flag.size = Vector2(50, 44)
	row.add_child(flag)

	var name_lbl := Label.new()
	name_lbl.label_settings = STYLE_NAME
	name_lbl.text = str(info.get("name", code))
	name_lbl.position = Vector2(80, 12)
	name_lbl.size = Vector2(400, 40)
	row.add_child(name_lbl)

	var sub_lbl := Label.new()
	sub_lbl.label_settings = STYLE_SUB
	sub_lbl.text = str(info.get("sub", ""))
	sub_lbl.position = Vector2(80, 46)
	sub_lbl.size = Vector2(400, 30)
	row.add_child(sub_lbl)

	# Dấu tích đỏ báo ngôn ngữ đang chọn (ẩn/hiện theo lựa chọn)
	var check := TextureRect.new()
	check.texture = TEX_CHECK
	check.position = Vector2(520, 32)
	check.size = Vector2(40, 30)
	check.visible = false
	row.add_child(check)

	_rows[code] = {"button": row, "check": check}


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
	_close()


func _on_cancel_pressed() -> void:
	Sfx.play(Sfx.BTN_WOOD_TAP)
	_pending_locale = Loc.current()
	_close()


func _close() -> void:
	hide()
	closed.emit()
