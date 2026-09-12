class_name MazeCell
extends Control
## ============================================================================
## View: Một ô trên lưới (Control chứa TextureButton + Label số tường).
## Tự co giãn theo kích thước ô (không có khoảng cách).
## ============================================================================

signal cell_pressed(grid_pos: Vector2i)

@export var grid_pos: Vector2i = Vector2i.ZERO

const NORMAL_MODULATE := Color(1.0, 1.0, 1.0, 1.0)
const FOCUS_MODULATE := Color(0.85, 0.95, 1.0, 1.0)

const TEX_NORMAL := preload("res://assets/images/game/cell_normal.svg")
const TEX_START := preload("res://assets/images/game/cell_start.svg")
const TEX_FINISH := preload("res://assets/images/game/cell_finish.svg")

@onready var _button: TextureButton = $Sprite
@onready var _label: Label = $Sprite/Label


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
	if _label != null:
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


func pulse() -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.1, 1.1), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
