class_name TutorialCell
extends PanelContainer
## ============================================================================
## Ô của BÀN MINI trong tutorial — scene `nodes/tutorials/tutorial_cell.tscn`.
##
## Toàn bộ HÌNH DÁNG nằm trong scene (2 StyleBox nền + Label con); script chỉ giữ API để
## tutorial điều khiển. Mỗi tutorial scene INSTANCE ô này rồi ghi đè chữ/màu/cỡ + `grid_pos`
## NGAY TRONG `.tscn` — không còn `PanelContainer.new()` / `StyleBoxFlat.new()` trong code.
## ============================================================================

## Toạ độ ô trong bàn mini (tutorial tra ô theo `grid_pos`, không theo thứ tự con)
@export var grid_pos: Vector2i = Vector2i.ZERO
## Nền "đã đi qua" (One Stroke) — bind trong chính scene của ô
@export var style_visited: StyleBox = null
## Chữ hiện trên ô ("S", "F", con số…) — ghi đè trong .tscn của từng bài
@export var cell_text: String = ""
## Màu chữ — ghi đè trong .tscn
@export var text_color: Color = Color(0.18, 0.22, 0.26, 1)
## Cỡ chữ — ghi đè trong .tscn
@export var text_size: int = 24

var _style_normal: StyleBox = null
var _fx: Tween = null
var _home_pos := Vector2.ZERO

@onready var _label: Label = $Label


func _ready() -> void:
	_style_normal = get_theme_stylebox("panel")
	_home_pos = position
	_apply_label()


func _apply_label() -> void:
	if _label == null:
		return
	_label.text = cell_text
	_label.add_theme_color_override("font_color", text_color)
	_label.add_theme_font_size_override("font_size", text_size)


func set_text(text: String) -> void:
	cell_text = text
	if _label != null:
		_label.text = text


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


## Ô đã đi qua (One Stroke: tô nền xanh nhạt) — đổi nền sang `style_visited`
func set_visited(on: bool) -> void:
	var style := style_visited if on else _style_normal
	if style != null:
		add_theme_stylebox_override("panel", style)


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
