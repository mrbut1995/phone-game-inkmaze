class_name RankTabButton
extends NinePatchButton
## ============================================================================
## Tab gáy sổ DỌC của bảng xếp hạng (nodes/ranking/tab_button.tscn)
## Xếp trong VBoxContainer ở mép phải tờ giấy (`Sheet/Tabs`, size_flags_horizontal = SHRINK_BEGIN).
## Tab đang chọn: đổi sang art `tab_active` + NỞ RA bề rộng (WIDTH_NORMAL → WIDTH_ACTIVE) bằng tween.
## Nhãn là Label xoay 90° (khai trong scene) — vẫn dịch bằng `label_key`.
## ============================================================================

const UIAnim := preload("res://scripts/utils/ui_anim.gd")

signal tab_pressed(board_id: String)

@export var art_active: Texture2D = null
@export var art_normal: Texture2D = null

@export var LABEL_ACTIVE_COLOR := Color(1, 1, 1)
@export var LABEL_IDLE_COLOR := Color(0.18, 0.37, 0.51)

## Kích thước tab (khớp tab_normal.svg 38x108 · tab_active.svg 46x108)
@export var WIDTH_NORMAL := 38.0
@export var WIDTH_ACTIVE := 46.0
@export var TAB_HEIGHT := 108.0
## Thời gian tab nở/co khi đổi trạng thái
@export var SLIDE_TIME := 0.18

## Mã bảng của tab (dungeon / play / daily) và khoá dịch — KHAI TRONG SCENE
@export var board_id := ""
@export var label_key := ""

@export var label: Label = null

var active := false

var _applied := false
var _width_tween: Tween = null


func _ready() -> void:
	custom_minimum_size = Vector2(WIDTH_NORMAL, TAB_HEIGHT)
	set_label_text(TranslationServer.translate(label_key))
	UIAnim.attach_press_down(self)


func set_label_text(text: String) -> void:
	if label != null and not text.is_empty():
		label.text = text


func _emit_tab_pressed() -> void:
	tab_pressed.emit(board_id)


## Đổi trạng thái chọn: art + màu nhãn đổi NGAY (contract đồng bộ), bề rộng nở/co có tween
func set_active(on: bool) -> void:
	if _applied and on == active:
		return
	var first := not _applied
	_applied = true
	active = on
	var art: Texture2D = art_active if on else art_normal
	texture_normal = art
	texture_pressed = art
	texture_hover = art
	texture_focus = art
	texture_disabled = art
	if label != null:
		label.add_theme_color_override("font_color", LABEL_ACTIVE_COLOR if on else LABEL_IDLE_COLOR)
	var target := WIDTH_ACTIVE if on else WIDTH_NORMAL
	if _width_tween != null and _width_tween.is_valid():
		_width_tween.kill()
	if first or Engine.is_editor_hint() or not is_inside_tree():
		custom_minimum_size.x = target
		return
	_width_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_width_tween.tween_property(self, "custom_minimum_size:x", target, SLIDE_TIME)
