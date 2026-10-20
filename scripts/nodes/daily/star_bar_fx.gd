class_name StarBarFx
extends Control
## ============================================================================
## Hiệu ứng TRANG TRÍ của thanh Sao tháng (scripts/nodes/daily/star_bar_fx.gd + nodes/daily/star_bar_fx.tscn)
##
## Màn Daily tự instance node này làm CON của thanh `TextureProgressBar` (phủ kín thanh), gồm:
##   · `Tip`   — quầng sáng + tia lấp lánh ở ĐẦU phần đã đạt (nhịp thở liên tục)
##   · `Sheen` — dải sáng xiên quét qua phần đã đạt, lặp định kỳ
## Mọi chuyển động nằm trong AnimationPlayer `Anim` (animation `idle`, lặp) của scene.
## Script chỉ nhận `set_fraction(0..1)` để đặt vị trí đầu thanh + độ rộng vùng quét.
## ============================================================================

@export var tip: Control = null
@export var sheen_clip: Control = null
@export var sheen: Control = null
@export var anim: AnimationPlayer = null
## 0..1 — vị trí dải sáng trên vùng đã đạt (AnimationPlayer animate thuộc tính này)
@export_range(0.0, 1.0, 0.001) var sheen_t := 1.0: set = _set_sheen_t

var _fraction := 0.0


func _ready() -> void:
	resized.connect(_layout)
	_layout()
	if anim != null and anim.has_animation(&"idle"):
		anim.play(&"idle")


## `fraction` = phần thanh đã đầy (0..1)
func set_fraction(fraction: float) -> void:
	_fraction = clampf(fraction, 0.0, 1.0)
	_layout()


func _layout() -> void:
	var filled := size.x * _fraction
	if tip != null:
		tip.position = Vector2(filled, size.y * 0.5)
		tip.visible = _fraction > 0.01
	if sheen_clip != null:
		sheen_clip.position = Vector2.ZERO
		sheen_clip.size = Vector2(filled, size.y)
		sheen_clip.visible = _fraction > 0.01
	if sheen != null:
		sheen.size = Vector2(clampf(size.x * 0.14, 28.0, 64.0), size.y)
	_set_sheen_t(sheen_t)


func _set_sheen_t(value: float) -> void:
	sheen_t = clampf(value, 0.0, 1.0)
	if sheen == null or sheen_clip == null:
		return
	sheen.position = Vector2(lerpf(-sheen.size.x, sheen_clip.size.x, sheen_t), 0.0)
