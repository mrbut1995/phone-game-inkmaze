class_name TutorialCell
extends Control
## ============================================================================
## Ô của BÀN MINI trong tutorial — scene `nodes/tutorials/tutorial_cell.tscn`.
##
## Cấu trúc giống `cell.tscn` của game thật: Control > TextureButton (Sprite) + Label + Highlight.
## S → cell_start.svg, F → cell_finish.svg, số → cell_normal.svg + Label hiển thị số.
## Mỗi tutorial scene INSTANCE ô này rồi ghi đè cell_text/text_color/text_size + grid_pos.
## ============================================================================

const TEX_NORMAL  := preload("res://assets/images/game/cell_normal.svg")
const TEX_START   := preload("res://assets/images/game/cell_start.svg")
const TEX_FINISH  := preload("res://assets/images/game/cell_finish.svg")
const TEX_FINISH_CLOSED := preload("res://assets/images/game/cell_finish_closed.svg")

## Toạ độ ô trong bàn mini (tutorial tra ô theo `grid_pos`, không theo thứ tự con)
@export var grid_pos: Vector2i = Vector2i.ZERO
## Chữ hiện trên ô ("S", "F", con số…) — ghi đè trong .tscn của từng bài
@export var cell_text: String = ""
## Màu chữ — ghi đè trong .tscn
@export var text_color: Color = Color(0.18, 0.22, 0.26, 1)
## Cỡ chữ — ghi đè trong .tscn
@export var text_size: int = 0  # 0 = dùng font size từ LabelSettings gốc

var _fx: Tween = null
var _home_pos := Vector2.ZERO

@onready var _sprite: TextureButton = $Sprite
@onready var _label: Label = $Sprite/Label
@onready var _highlight: Panel = $Highlight


func _ready() -> void:
	_home_pos = position
	_apply_cell_text(cell_text)


func _apply_cell_text(text: String) -> void:
	if _sprite == null or _label == null:
		return
	match text:
		"S":
			_sprite.texture_normal = TEX_START
			_sprite.texture_hover  = TEX_START
			_sprite.texture_focused = TEX_START
			_label.text    = ""
			_label.visible = false
		"F":
			_sprite.texture_normal = TEX_FINISH
			_sprite.texture_hover  = TEX_FINISH
			_sprite.texture_focused = TEX_FINISH
			_label.text    = ""
			_label.visible = false
		"F_CLOSED":
			_sprite.texture_normal = TEX_FINISH_CLOSED
			_sprite.texture_hover  = TEX_FINISH_CLOSED
			_sprite.texture_focused = TEX_FINISH_CLOSED
			_label.text    = ""
			_label.visible = false
		_:
			_sprite.texture_normal = TEX_NORMAL
			_sprite.texture_hover  = TEX_NORMAL
			_sprite.texture_focused = TEX_NORMAL
			_label.text    = text
			_label.visible = not text.is_empty()
			# Áp màu chữ và cỡ chữ tùy chỉnh nếu có
			_label.add_theme_color_override("font_color", text_color)
			if text_size > 0:
				_label.add_theme_font_size_override("font_size", text_size)


func set_text(text: String) -> void:
	cell_text = text
	_apply_cell_text(text)


func text() -> String:
	return _label.text if _label != null else cell_text


func set_text_color(color: Color) -> void:
	text_color = color
	if _label != null:
		_label.add_theme_color_override("font_color", color)


func set_text_size(px: int) -> void:
	text_size = px
	if _label != null:
		_label.add_theme_font_size_override("font_size", px)


## Tô sáng ô (dùng cho Minesweeper / SumPath spotlight trên ô cụ thể)
func set_highlight(on: bool) -> void:
	if _highlight != null:
		_highlight.visible = on


## Đánh dấu đã đi qua (One Stroke): dùng overlay Highlight màu xanh nhạt
func set_visited(on: bool) -> void:
	if _highlight == null:
		return
	if on:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.5, 0.82, 0.95, 0.38)
		style.corner_radius_top_left    = 14
		style.corner_radius_top_right   = 14
		style.corner_radius_bottom_right = 14
		style.corner_radius_bottom_left  = 14
		_highlight.add_theme_stylebox_override("panel", style)
		_highlight.visible = true
	else:
		_highlight.visible = false


## Nhún nhẹ khi thao tác đúng ("pháo giấy nhỏ" của tutorial)
func pulse() -> void:
	_kill_fx()
	pivot_offset = size * 0.5
	scale = Vector2(0.85, 0.85)
	_fx = create_tween()
	_fx.tween_property(self, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Ô bay vào khi mở bài (so le theo `delay` — gọi từ `BaseTutorial.play_entrance()`)
func play_entrance(delay: float = 0.0) -> void:
	UIAnim.play_pop_in(self, delay, 0.86, 0.26)


## Ô vừa được đi qua: nhún + nháy sáng nhẹ
func play_step() -> void:
	pulse()
	var flash := create_tween()
	modulate = Color(1.18, 1.18, 1.12, 1.0)
	flash.tween_property(self, "modulate", Color.WHITE, 0.3)


## Thao tác SAI (đạp mìn / đi đè ô cũ / đâm tường): nháy đỏ + rung ngang
func play_fail() -> void:
	_kill_fx()
	modulate = Color(1.0, 0.45, 0.42, 1.0)
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.45)
	_fx = create_tween()
	for i in 3:
		_fx.tween_property(self, "position", _home_pos + Vector2(6, 0), 0.045)
		_fx.tween_property(self, "position", _home_pos - Vector2(6, 0), 0.045)
		_fx.tween_property(self, "position", _home_pos, 0.05)


## Pháo giấy nhỏ khi thắng (nở ra + nháy vàng nhạt), so le theo `delay`
func play_win(delay: float = 0.0) -> void:
	_kill_fx()
	pivot_offset = size * 0.5
	modulate = Color(1.25, 1.15, 0.75, 1.0)
	scale = Vector2(0.8, 0.8)
	_fx = create_tween()
	if delay > 0.0:
		_fx.tween_interval(delay)
	_fx.set_parallel(true)
	_fx.tween_property(self, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_fx.tween_property(self, "modulate", Color.WHITE, 0.4)


func _kill_fx() -> void:
	if _fx != null and _fx.is_valid():
		_fx.kill()
	_fx = null
