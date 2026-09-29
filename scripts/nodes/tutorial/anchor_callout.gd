class_name AnchorCallout
extends Control
## ============================================================================
## AnchorCallout: Vòng tròn đánh số tại 1 ĐIỂM NEO trên bàn tutorial.
## Wall Builder (bước 3): hiện "1" ở neo bắt đầu và "2" ở neo kéo tới để người
## chơi biết CHẠM vào đâu — vòng tự "nở" ra rồi phập phồng nhẹ cho dễ thấy.
## ============================================================================

@onready var _num: Label = $Num

var _fx: Tween = null
var _pulse: Tween = null


func set_number(n: int) -> void:
	if _num != null:
		_num.text = str(n)


## Hiện vòng tại tâm `center` (toạ độ TRONG bàn) kèm hiệu ứng nở + nhịp "thở"
func show_at(center: Vector2) -> void:
	var half := size
	if half.x <= 0.0:
		half = custom_minimum_size
	position = center - half * 0.5
	pivot_offset = half * 0.5
	visible = true
	_kill_tweens()
	scale = Vector2(0.55, 0.55)
	modulate.a = 0.0
	_fx = create_tween()
	_fx.tween_property(self, "modulate:a", 1.0, 0.18)
	_fx.parallel().tween_property(self, "scale", Vector2.ONE, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_fx.tween_callback(_start_pulse)


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
