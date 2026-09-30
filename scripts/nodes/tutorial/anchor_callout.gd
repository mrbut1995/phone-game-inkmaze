class_name AnchorCallout
extends Control
## Vòng đánh số tại neo trên bàn tutorial — "nở" ra rồi phập phồng khi hiện.

@onready var _num: Label = $Num

var _fx: Tween = null
var _pulse: Tween = null


func set_number(n: int) -> void:
	if _num != null:
		_num.text = str(n)


## Hiện vòng tại tâm `center` (toạ độ TRONG bàn) kèm hiệu ứng nở + nhịp "thở"
func show_at(center: Vector2) -> void:
	_center_on(center)
	visible = true
	_kill_tweens()
	scale = Vector2(0.55, 0.55)
	modulate.a = 0.0
	_fx = create_tween()
	_fx.tween_property(self, "modulate:a", 1.0, 0.18)
	_fx.parallel().tween_property(self, "scale", Vector2.ONE, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_fx.tween_callback(_start_pulse)


## Dời vòng sang tâm mới — KHÔNG phát lại hiệu ứng nở (dùng khi lưới tính lại: đổi cỡ cửa sổ)
func move_to(center: Vector2) -> void:
	_center_on(center)


## Đặt tâm vòng theo cỡ thật của node; chưa có cỡ thì lấy cỡ tối thiểu khai trong scene
func _center_on(center: Vector2) -> void:
	var half := size
	if half.x <= 0.0:
		half = custom_minimum_size
	position = center - half * 0.5
	pivot_offset = half * 0.5


func hide_callout() -> void:
	_kill_tweens()
	visible = false
	scale = Vector2.ONE
	modulate.a = 1.0


## Phập phồng nhẹ quanh cỡ gốc — chỉ chạy khi vòng đang hiện
func _start_pulse() -> void:
	if not visible:
		return
	if _pulse != null and _pulse.is_valid():
		_pulse.kill()
	_pulse = create_tween().set_loops()
	_pulse.tween_property(self, "scale", Vector2(1.12, 1.12), 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse.tween_property(self, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _kill_tweens() -> void:
	if _fx != null and _fx.is_valid():
		_fx.kill()
	_fx = null
	if _pulse != null and _pulse.is_valid():
		_pulse.kill()
	_pulse = null
