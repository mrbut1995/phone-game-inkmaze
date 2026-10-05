## ============================================================================
## ButtonPressEffect — Thêm hiệu ứng scale bounce khi nhấn bất kỳ BaseButton.
##
## CÁCH DÙNG:
##   Gắn script này lên 1 Button/TextureButton nào bạn muốn có hiệu ứng,
##   hoặc gọi `ButtonPressEffect.apply(button)` từ code GDScript khác.
##
## GIÁ TRỊ MẶC ĐỊNH (có thể chỉnh trong Inspector):
##   press_scale   = Vector2(0.88, 0.88)   — scale khi nhấn xuống
##   release_scale = Vector2(1.04, 1.04)   — overshoot khi nhả ra
##   duration      = 0.10                  — thời gian mỗi phase (giây)
## ============================================================================
@tool
class_name ButtonPressEffect
extends Node

# ── Cấu hình ──────────────────────────────────────────────────────────────
## Scale khi nút đang bị nhấn (squish)
@export var press_scale: Vector2 = Vector2(0.88, 0.88)
## Scale overshoot sau khi nhả (bounce back)
@export var release_scale: Vector2 = Vector2(1.04, 1.04)
## Thời gian của mỗi pha chuyển động (giây)
@export var duration: float = 0.10

# ── Internal ───────────────────────────────────────────────────────────────
var _tween: Tween = null
var _button: BaseButton = null


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_button = get_parent() as BaseButton
	if _button == null:
		push_warning("ButtonPressEffect: parent is not a BaseButton — skipping.")
		return
	_button.button_down.connect(_on_button_down)
	_button.button_up.connect(_on_button_up)


func _on_button_down() -> void:
	_kill_tween()
	_tween = _button.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(_button, "scale", press_scale, duration * 0.8)


func _on_button_up() -> void:
	_kill_tween()
	_tween = _button.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_tween.tween_property(_button, "scale", release_scale, duration)
	_tween.tween_property(_button, "scale", Vector2.ONE, duration * 0.7)


func _kill_tween() -> void:
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = null


# ── Static helper ──────────────────────────────────────────────────────────
## Gọi hàm tĩnh này để gắn hiệu ứng vào 1 button từ code bên ngoài:
##   ButtonPressEffect.apply(my_button)
##   ButtonPressEffect.apply(my_button, Vector2(0.9, 0.9), 0.08)
static func apply(
	button: BaseButton,
	p_press_scale: Vector2 = Vector2(0.88, 0.88),
	p_duration: float = 0.10
) -> ButtonPressEffect:
	if button == null or not is_instance_valid(button):
		return null
	# Tránh gắn 2 lần
	for child in button.get_children():
		if child is ButtonPressEffect:
			return child as ButtonPressEffect
	var effect := ButtonPressEffect.new()
	effect.press_scale = p_press_scale
	effect.duration = p_duration
	button.add_child(effect)
	return effect
