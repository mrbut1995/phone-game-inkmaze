class_name PlayerCursor
extends Control
## ============================================================================
## View: Con trỏ người chơi (Player Cursor / Runner Avatar)
## Quản lý animation chạy sống động theo phong cách Sổ tay & Mực:
##   - Nhún nhảy hình cung (Hop / Arc) khi di chuyển giữa các ô.
##   - Co giãn (Squash & Stretch) tạo nhịp bước chân chạy tự nhiên.
##   - Nghiêng người theo quán tính bước chạy (Tilt / Lean).
##   - Bonk / Recoil khi va chạm tường vô hình (nảy lùi & lắc lư).
##   - Nhảy múa ăn mừng (Celebration) khi tới đích F (xoay 360 độ).
##   - Rơi nhẹ vào ván mới (Spawn Drop) tại ô xuất phát S.
##   - Nhịp thở & cựa quậy sinh động khi đứng yên (Idle).
## ============================================================================

signal run_finished()
signal celebration_finished()

@onready var icon: TextureRect = $Icon

var _move_tween: Tween = null
var _idle_tween: Tween = null
var _is_running: bool = false
var _is_celebrating: bool = false


func _ready() -> void:
	pivot_offset = size * 0.5
	start_idle()


## Đổi icon con trỏ theo NGÒI BÚT đang dùng (bảng PenSkin) — Board gọi khi dựng ván /
## khi người chơi đổi bút ở Cửa hàng (ThemeManager.skin_changed).
func apply_pen(pen_id: String) -> void:
	var tex := PenSkin.cursor_texture(pen_id)
	if tex != null and icon != null:
		icon.texture = tex


## Hoạt ảnh thở nhẹ kết hợp cựa quậy tự nhiên khi đứng yên
func start_idle() -> void:
	if _is_running or _is_celebrating:
		return
	if _idle_tween != null and _idle_tween.is_valid():
		_idle_tween.kill()

	_idle_tween = create_tween().set_loops()
	# Chu kỳ 1: Nhịp thở phập phồng nhẹ
	_idle_tween.tween_property(self, "scale", Vector2(1.06, 0.95), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.tween_property(self, "scale", Vector2(0.96, 1.05), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	## Chu kỳ 2: Nhún nhẹ như đang tập trung quan sát mê cung
	#_idle_tween.tween_property(self, "rotation_degrees", 4.5, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	#_idle_tween.tween_property(self, "rotation_degrees", -4.5, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	#_idle_tween.tween_property(self, "rotation_degrees", 0.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	#_idle_tween.tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


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


## Hoạt ảnh Bonk / Recoil khi va vào tường vô hình
func play_bonk_recoil(recoil_dir: Vector2 = Vector2.ZERO) -> void:
	if _idle_tween != null and _idle_tween.is_valid():
		_idle_tween.kill()
	if _move_tween != null and _move_tween.is_valid():
		_move_tween.kill()

	_is_running = true
	var base_pos := position
	var push_back := recoil_dir.normalized() * 16.0
	if push_back.is_zero_approx():
		push_back = Vector2(0, -14.0)

	var tw := create_tween().set_parallel(false)
	# 1. Bị dội ngược lại và co rúm (Squash)
	var sub1 := tw.chain().set_parallel(true)
	sub1.tween_property(self, "position", base_pos + push_back, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	sub1.tween_property(self, "scale", Vector2(1.35, 0.7), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	sub1.tween_property(self, "rotation_degrees", -12.0 if push_back.x >= 0 else 12.0, 0.08)

	# 2. Lắc lư giật mình
	var sub2 := tw.chain().set_parallel(true)
	sub2.tween_property(self, "position", base_pos, 0.14).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	sub2.tween_property(self, "scale", Vector2(0.88, 1.15), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	sub2.tween_property(self, "rotation_degrees", 8.0 if push_back.x >= 0 else -8.0, 0.1)

	# 3. Trở lại cân bằng
	var sub3 := tw.chain().set_parallel(true)
	sub3.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	sub3.tween_property(self, "rotation_degrees", 0.0, 0.12)

	tw.chain().tween_callback(func() -> void:
		_is_running = false
		rotation = 0.0
		scale = Vector2.ONE
		start_idle()
	)


## Hoạt ảnh Nhảy múa ăn mừng (Celebration) khi tới ô Finish F
func play_celebration() -> void:
	if _idle_tween != null and _idle_tween.is_valid():
		_idle_tween.kill()
	if _move_tween != null and _move_tween.is_valid():
		_move_tween.kill()

	_is_celebrating = true
	var base_pos := position
	var jump_up := base_pos - Vector2(0, 32.0)

	var tw := create_tween().set_parallel(false)
	# 1. Nhún đà (Pre-jump squash)
	tw.chain().tween_property(self, "scale", Vector2(1.3, 0.7), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	## 2. Nhảy bổng lên xoay 360 độ (Takeoff & Spin)
	#var sub_spin := tw.chain().set_parallel(true)
	#sub_spin.tween_property(self, "position", jump_up, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	#sub_spin.tween_property(self, "scale", Vector2(0.9, 1.3), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	#sub_spin.tween_property(self, "rotation_degrees", 360.0, 0.26).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
#
	## 3. Tiếp đất ăn mừng
	#var sub_land := tw.chain().set_parallel(true)
	#sub_land.tween_property(self, "position", base_pos, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	#sub_land.tween_property(self, "scale", Vector2(1.35, 0.75), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# 4. Nảy nhẹ phục hồi
	var sub_settle := tw.chain().set_parallel(true)
	sub_settle.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tw.chain().tween_callback(func() -> void:
		_is_celebrating = false
		rotation = 0.0
		scale = Vector2.ONE
		celebration_finished.emit()
		start_idle()
	)


## Hoạt ảnh Rơi nhẹ từ trên xuống (Spawn Drop) khi bắt đầu ván mới tại ô S
func play_spawn_drop(target_pos: Vector2) -> void:
	if _idle_tween != null and _idle_tween.is_valid():
		_idle_tween.kill()

	position = target_pos - Vector2(0, 42.0)
	scale = Vector2(0.7, 1.35)
	modulate.a = 0.0

	var tw := create_tween().set_parallel(false)
	var sub1 := tw.chain().set_parallel(true)
	sub1.tween_property(self, "position", target_pos, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	sub1.tween_property(self, "modulate:a", 1.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	sub1.tween_property(self, "scale", Vector2(1.3, 0.75), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	var sub2 := tw.chain().set_parallel(true)
	sub2.tween_property(self, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tw.chain().tween_callback(func() -> void:
		scale = Vector2.ONE
		rotation = 0.0
		start_idle()
	)
