class_name MazeCell
extends Control
## ============================================================================
## View: Một ô trên lưới (Control chứa TextureButton + Label số tường).
## Tự co giãn theo kích thước ô (không có khoảng cách): board.gd đặt `size` cho ô,
## art (mọi trạng thái) đều cùng khung 176x176 và TextureButton ở chế độ stretch
## nên co lại vẫn khớp nhau; số trên ô co theo qua set_font_size().
## ============================================================================

signal cell_pressed(grid_pos: Vector2i)

@export var grid_pos: Vector2i = Vector2i.ZERO

const NORMAL_MODULATE := Color(1.0, 1.0, 1.0, 1.0)
const FOCUS_MODULATE := Color(0.85, 0.95, 1.0, 1.0)

## Số trên ô vẽ ĐÈ LÊN icon Bomb (nền mìn đậm) -> thêm viền màu giấy cho số để vẫn đọc được.
const BOMB_TEXT_OUTLINE_SIZE := 8
const BOMB_TEXT_OUTLINE_COLOR := Color(0.996078, 0.992157, 0.980392, 1.0)   # #FEFDFA

const TEX_NORMAL := preload("res://assets/images/game/cell_normal.svg")
const TEX_START := preload("res://assets/images/game/cell_start.svg")
const TEX_FINISH := preload("res://assets/images/game/cell_finish.svg")

@onready var _button: TextureButton = $Sprite
@onready var _label: Label = $Sprite/Label
@onready var _bomb: TextureRect = $Sprite/Bomb


func _ready() -> void:
	if _button != null:
		_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_text(text: String) -> void:
	if _label == null:
		_label = $Sprite/Label
	if _button == null:
		_button = $Sprite

	if text == "S":
		if _button != null:
			_button.texture_normal = TEX_START
		if _label != null:
			_label.text = ""
			_label.visible = false
	elif text == "F":
		if _button != null:
			_button.texture_normal = TEX_FINISH
		if _label != null:
			_label.text = ""
			_label.visible = false
	else:
		if _button != null:
			_button.texture_normal = TEX_NORMAL
		if _label != null:
			_label.text = text
			_label.visible = not text.is_empty()


func set_font_size(fs: int) -> void:
	if _label == null:
		_label = $Sprite/Label
	if _label == null:
		return
	# LƯU Ý: LabelSettings sẽ đè theme override, nên phải sửa cả LabelSettings.
	# Resource này dùng chung cho mọi ô -> phải duplicate trước khi đổi cỡ chữ.
	if _label.label_settings != null and _label.label_settings.font_size != fs:
		var settings := _label.label_settings.duplicate() as LabelSettings
		settings.font_size = fs
		_label.label_settings = settings
	_label.add_theme_font_size_override("font_size", fs)


func get_text() -> String:
	if _label == null:
		_label = $Sprite/Label
	return _label.text if _label != null else ""


func set_focused(active: bool) -> void:
	if _button == null:
		_button = $Sprite
	if _button != null:
		_button.modulate = FOCUS_MODULATE if active else NORMAL_MODULATE


## Hiện/ẩn biểu tượng Bomb đã nổ (Minesweeper) — icon to giữa ô, số trên ô vẽ ĐÈ LÊN icon.
func set_bomb(active: bool) -> void:
	if _bomb == null:
		_bomb = get_node_or_null("Sprite/Bomb")
	if _bomb != null:
		_bomb.visible = active
	_apply_bomb_text_outline(active)


## Số nằm trên nền mìn đậm nên cần viền sáng; khi ẩn Bomb thì trả lại như cũ.
func _apply_bomb_text_outline(active: bool) -> void:
	if _label == null:
		_label = get_node_or_null("Sprite/Label")
	if _label == null or _label.label_settings == null:
		return
	var settings := _label.label_settings
	var has_outline := settings.outline_size > 0
	if active == has_outline:
		return
	# LabelSettings dùng chung cho mọi ô -> phải duplicate trước khi đổi
	settings = settings.duplicate() as LabelSettings
	settings.outline_size = BOMB_TEXT_OUTLINE_SIZE if active else 0
	settings.outline_color = BOMB_TEXT_OUTLINE_COLOR
	_label.label_settings = settings


func has_bomb() -> bool:
	if _bomb == null:
		_bomb = get_node_or_null("Sprite/Bomb")
	return _bomb != null and _bomb.visible


func pulse() -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.1, 1.1), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
