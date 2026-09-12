class_name PlayerCursor
extends Control
## ============================================================================
## View: Con trỏ người chơi (Player Cursor / Runner Avatar)
## Quản lý animation chạy sống động:
##   - Nhún nhảy hình cung (Hop / Arc) khi di chuyển giữa các ô.
##   - Co giãn (Squash & Stretch) tạo nhịp bước chân chạy tự nhiên.
##   - Nghiêng người theo quán tính bước chạy (Tilt / Lean).
##   - Nhịp thở nhẹ (Idle breathing/pulse) khi đứng yên.
## ============================================================================

signal run_finished()

@onready var icon: TextureRect = $Icon

var _move_tween: Tween = null
var _idle_tween: Tween = null
var _is_running: bool = false


func _ready() -> void:
	pivot_offset = size * 0.5
	start_idle()


## Hoạt ảnh thở nhẹ khi đứng yên
func start_idle() -> void:
	if _is_running:
		return
	if _idle_tween != null and _idle_tween.is_valid():
		_idle_tween.kill()

	_idle_tween = create_tween().set_loops()
	_idle_tween.tween_property(self, "scale", Vector2(1.06, 1.06), 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.tween_property(self, "scale", Vector2(0.96, 0.96), 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Thực hiện animation chạy từ vị trí hiện tại đến target_pos
func run_to(target_pos: Vector2, move_dir: Vector2 = Vector2.ZERO, duration: float = 0.16) -> void:
	if _idle_tween != null and _idle_tween.is_valid():
		_idle_tween.kill()
	if _move_tween != null and _move_tween.is_valid():
		_move_tween.kill()

	_is_running = true
	var start_pos := position
	var hop_height := 14.0 # Độ nhấc chân khi chạy

	# Tính góc nghiêng theo hướng chạy
	var tilt_angle := 0.0
	if move_dir.x > 0.1:
		tilt_angle = deg_to_rad(14.0)
	elif move_dir.x < -0.1:
		tilt_angle = deg_to_rad(-14.0)
	elif move_dir.y > 0.1:
		tilt_angle = deg_to_rad(4.0)
	elif move_dir.y < -0.1:
		tilt_angle = deg_to_rad(-4.0)

	_move_tween = create_tween().set_parallel(false)

	# Giai đoạn 1: Bứt tốc (Takeoff) - Nhảy lên và stretch theo hướng chạy
	var t1 := duration * 0.38
	var half_way := start_pos.lerp(target_pos, 0.5) - Vector2(0, hop_height)

	var sub_tw := _move_tween.chain().set_parallel(true)
	sub_tw.tween_property(self, "position", half_way, t1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	sub_tw.tween_property(self, "scale", Vector2(0.82, 1.24), t1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	sub_tw.tween_property(self, "rotation", tilt_angle, t1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Giai đoạn 2: Tiếp đất (Land & Squash)
	var t2 := duration * 0.44
	var sub_tw2 := _move_tween.chain().set_parallel(true)
	sub_tw2.tween_property(self, "position", target_pos, t2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	sub_tw2.tween_property(self, "scale", Vector2(1.24, 0.82), t2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	sub_tw2.tween_property(self, "rotation", 0.0, t2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Giai đoạn 3: Phục hồi cân bằng (Settle)
	var t3 := duration * 0.18
	var sub_tw3 := _move_tween.chain().set_parallel(true)
	sub_tw3.tween_property(self, "scale", Vector2(1.0, 1.0), t3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Kết thúc bước chạy
	_move_tween.chain().tween_callback(Callable(self, "_on_run_completed"))


func _on_run_completed() -> void:
	_is_running = false
	rotation = 0.0
	scale = Vector2.ONE
	run_finished.emit()
	start_idle()
