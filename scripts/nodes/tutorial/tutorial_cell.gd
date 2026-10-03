class_name TutorialCell
extends Control
## ============================================================================
## Ô của BÀN MINI trong tutorial — scene `nodes/tutorials/tutorial_cell.tscn`.
##
## Cấu trúc giống `cell.tscn` của game thật: Control > TextureButton (Sprite) + Label + Highlight.
## S → cell_start.svg, F → cell_finish.svg, số → cell_normal.svg + Label hiển thị số.
## Mỗi tutorial scene INSTANCE ô này rồi ghi đè cell_text/text_color/text_size + grid_pos.
## ============================================================================

const TEX_NORMAL  := preload("res://assets/images-png/game/cell_normal.png")
const TEX_START   := preload("res://assets/images-png/game/cell_start.png")
const TEX_FINISH  := preload("res://assets/images-png/game/cell_finish.png")
const TEX_FINISH_CLOSED := preload("res://assets/images-png/game/cell_finish_closed.png")

## Toạ độ ô trong bàn mini (tutorial tra ô theo `grid_pos`, không theo thứ tự con)
@export var grid_pos: Vector2i = Vector2i.ZERO
## Chữ hiện trên ô ("S", "F", con số…) — ghi đè trong .tscn của từng bài
@export var cell_text: String = ""
## Màu chữ — ghi đè trong .tscn
@export var text_color: Color = Color(0.18, 0.22, 0.26, 1)
## Cỡ chữ — ghi đè trong .tscn
@export var text_size: int = 0  # 0 = dùng font size từ LabelSettings gốc

@onready var _sprite: TextureButton = $Sprite
@onready var _label: Label = $Sprite/Label
## AnimationPlayer của chính `tutorial_cell.tscn` — hiệu ứng nảy/nháy/rung khai trong scene;
## code chỉ set pose ban đầu (scale/màu) + gọi play (kèm fallback tween nếu scene thiếu).
var _anim: AnimationPlayer = null
## Hẹn giờ SO LE (ô bay vào / nảy mừng) — Timer khai trong `tutorial_cell.tscn` (dây `timeout` ở đó);
## code chỉ đặt `wait_time` rồi `start()`.
var _entrance_timer: Timer = null
var _win_timer: Timer = null


func _ready() -> void:
	_anim = get_node_or_null("AnimationPlayer") as AnimationPlayer
	_entrance_timer = get_node_or_null("EntranceTimer") as Timer
	_win_timer = get_node_or_null("WinTimer") as Timer
	_apply_cell_text(cell_text)


func _play_anim(anim_name: StringName) -> bool:
	if _anim == null or not _anim.has_animation(anim_name):
		return false
	_anim.play(anim_name)
	return true


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


## Nhún nhẹ khi thao tác đúng ("pháo giấy nhỏ" của tutorial) — animation "pulse" trong scene
func pulse() -> void:
	pivot_offset = size * 0.5
	if _play_anim(&"pulse"):
		return
	scale = Vector2(0.85, 0.85)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Ô bay vào khi mở bài (so le theo `delay` — gọi từ `BaseTutorial.play_entrance()`)
func play_entrance(delay: float = 0.0) -> void:
	pivot_offset = size * 0.5
	scale = Vector2(0.86, 0.86)
	modulate.a = 0.0
	if _anim != null and _anim.has_animation(&"entrance"):
		if delay > 0.0:
			if _entrance_timer != null:
				_entrance_timer.wait_time = delay
				_entrance_timer.start()
			else:
				# Fallback khi scene thiếu EntranceTimer (dây thật khai trong tutorial_cell.tscn)
				get_tree().create_timer(delay).timeout.connect(_play_entrance_now)
		else:
			_play_entrance_now()
		return
	# Fallback khi scene thiếu AnimationPlayer
	UIAnim.play_pop_in(self, delay, 0.86, 0.26)


func _play_entrance_now() -> void:
	_play_anim(&"entrance")


## Ô vừa được đi qua: nhún + nháy sáng nhẹ — animation "step" trong scene
func play_step() -> void:
	pivot_offset = size * 0.5
	if _play_anim(&"step"):
		return
	pulse()
	modulate = Color(1.18, 1.18, 1.12, 1.0)
	var flash := create_tween()
	flash.tween_property(self, "modulate", Color.WHITE, 0.3)


## Thao tác SAI (đạp mìn / đi đè ô cũ / đâm tường): nháy đỏ + rung ngang — animation "fail"
func play_fail() -> void:
	if _play_anim(&"fail"):
		return
	modulate = Color(1.0, 0.45, 0.42, 1.0)
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.45)
	var home := position
	var tw := create_tween()
	for i in 3:
		tw.tween_property(self, "position", home + Vector2(6, 0), 0.045)
		tw.tween_property(self, "position", home - Vector2(6, 0), 0.045)
		tw.tween_property(self, "position", home, 0.05)


## Pháo giấy nhỏ khi thắng (nở ra + nháy vàng nhạt) — animation "win" trong scene, so le `delay`
func play_win(delay: float = 0.0) -> void:
	pivot_offset = size * 0.5
	modulate = Color(1.25, 1.15, 0.75, 1.0)
	scale = Vector2(0.8, 0.8)
	if _anim != null and _anim.has_animation(&"win"):
		if delay > 0.0:
			if _win_timer != null:
				_win_timer.wait_time = delay
				_win_timer.start()
			else:
				# Fallback khi scene thiếu WinTimer (dây thật khai trong tutorial_cell.tscn)
				get_tree().create_timer(delay).timeout.connect(_play_win_now)
		else:
			_play_win_now()
		return
	# Fallback khi scene thiếu AnimationPlayer
	var tw := create_tween()
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate", Color.WHITE, 0.4)


func _play_win_now() -> void:
	_play_anim(&"win")
