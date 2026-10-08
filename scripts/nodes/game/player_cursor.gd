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

## Node binding: khai `node_paths` + NodePath trong `player_cursor.tscn`
@export var icon: TextureRect = null
## AnimationPlayer của CHÍNH scene này (`player_cursor.tscn`) — mọi dáng chạy/nhảy/va chạm
## (scale · rotation · modulate · Icon offset) khai trong scene; code chỉ điều khiển `position`
## vì vị trí phụ thuộc toạ độ bàn cờ tính lúc chạy (xem chú thích ở các hàm bên dưới).
@export var anim: AnimationPlayer = null

## Độ dài chuẩn của animation "hop_*" — khi `duration` khác thì đổi `speed_scale` theo tỉ lệ
@export var HOP_LENGTH := 0.16

var _move_tween: Tween = null
var _demo_tween: Tween = null
var _is_running: bool = false
var _is_celebrating: bool = false
var _is_demoing: bool = false


func _ready() -> void:
	pivot_offset = size * 0.5
	# Dây `animation_finished → _on_anim_finished` khai trong `player_cursor.tscn` (cùng scene)
	start_idle()


## Chạy 1 animation của player (đặt lại speed về 1 trừ khi truyền tốc độ khác).
## Trả về false nếu scene thiếu animation đó (fallback: không chạy hiệu ứng).
func _play_anim(anim_name: StringName, speed: float = 1.0) -> bool:
	if anim == null or not anim.has_animation(anim_name):
		return false
	# Đổi animation khi cú RƠI VÀO VÁN (`spawn_drop`) còn dang dở: animation mới (idle/hop/bonk/
	# demo…) KHÔNG đụng tới `Icon:position` ⇒ Icon kẹt lơ lửng ở -42px (bút "lệch hẳn bên trên").
	# Nhả Icon về đúng chỗ trước khi chạy animation mới.
	if anim_name != &"spawn_drop" and anim.current_animation == &"spawn_drop" and icon != null:
		icon.position = Vector2.ZERO
	anim.speed_scale = speed
	anim.play(anim_name)
	return true


func _stop_anim() -> void:
	if anim != null:
		anim.stop()


func _kill_move_tween() -> void:
	if _move_tween != null and _move_tween.is_valid():
		_move_tween.kill()
	_move_tween = null


func _kill_demo_tween() -> void:
	if _demo_tween != null and _demo_tween.is_valid():
		_demo_tween.kill()
	_demo_tween = null


## Xong 1 animation one-shot: reset dáng + phát tín hiệu + về lại nhịp thở
func _on_anim_finished(anim_name: StringName) -> void:
	match anim_name:
		&"celebrate":
			_is_celebrating = false
			rotation = 0.0
			scale = Vector2.ONE
			celebration_finished.emit()
			start_idle()
		&"spawn_drop":
			start_idle()
		&"bonk_left", &"bonk_right":
			_is_running = false
			rotation = 0.0
			scale = Vector2.ONE
			start_idle()


## Đổi icon con trỏ theo NGÒI BÚT đang dùng (bảng PenSkin) — Board gọi khi dựng ván /
## khi người chơi đổi bút ở Cửa hàng (ThemeManager.skin_changed).
func apply_pen(pen_id: String) -> void:
	var tex := PenSkin.cursor_texture(pen_id)
	if tex != null and icon != null:
		icon.texture = tex


## Hiện hoặc ẩn con trỏ (khi ẩn sẽ tạm dừng hoạt cảnh)
func set_cursor_visible(on: bool) -> void:
	visible = on
	if not on:
		stop_demo()
		_stop_anim()
	else:
		if not _is_running and not _is_celebrating and not _is_demoing:
			start_idle()


## Hoạt ảnh trình diễn kéo từ from_pos sang to_pos (lặp lại, dùng cho tutorial)
## (GIỮ tween) Toạ độ from/to là dữ liệu lưới tính lúc chạy nên phần di chuyển ở lại code.
func play_demo_drag(from_pos: Vector2, to_pos: Vector2, duration: float = 0.6) -> void:
	_kill_move_tween()
	_kill_demo_tween()
	_stop_anim()
	_is_running = false

	_is_demoing = true
	visible = true
	position = from_pos
	modulate.a = 1.0
	rotation = 0.0
	scale = Vector2.ONE

	var move_dir := (to_pos - from_pos).normalized()
	var tilt_angle := 0.0
	if move_dir.x > 0.1:
		tilt_angle = deg_to_rad(14.0)
	elif move_dir.x < -0.1:
		tilt_angle = deg_to_rad(-14.0)

	# Giai đoạn 1: Nhảy lên trước khi di chuyển (sequential)
	_demo_tween = create_tween().set_loops()
	_demo_tween.tween_property(self, "position", from_pos, 0.05)
	_demo_tween.tween_property(self, "modulate:a", 1.0, 0.1)
	_demo_tween.tween_property(self, "scale", Vector2(1.15, 0.85), 0.12)

	# Giai đoạn 2: Di chuyển song song (vị trí + scale + xoay cùng lúc)
	# Dùng .parallel() trên từng tweener — KHÔNG dùng set_parallel(true) toàn cục
	_demo_tween.tween_property(self, "position", to_pos, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_demo_tween.parallel().tween_property(self, "scale", Vector2.ONE, duration * 0.5)
	_demo_tween.parallel().tween_property(self, "rotation", tilt_angle, duration * 0.4)

	# Giai đoạn 3: Đổ xuống khi chạm đích (song song)
	_demo_tween.tween_property(self, "scale", Vector2(1.18, 0.82), 0.1)
	_demo_tween.parallel().tween_property(self, "rotation", 0.0, 0.1)

	# Giai đoạn 4: Fade out và nghỉ
	_demo_tween.tween_interval(0.2)
	_demo_tween.tween_property(self, "modulate:a", 0.0, 0.18)
	_demo_tween.tween_interval(0.25)


## Hoạt ảnh trình diễn chạm / gõ (tap) tại vị trí — nhịp gõ lặp nằm trong animation "demo_tap"
func play_demo_tap(target_pos: Vector2 = Vector2.ZERO) -> void:
	_kill_move_tween()
	_kill_demo_tween()
	_stop_anim()
	_is_running = false

	_is_demoing = true
	visible = true
	if target_pos != Vector2.ZERO:
		position = target_pos
	modulate.a = 1.0
	_play_anim(&"demo_tap")


## Trình diễn cursor đi qua nhiều ô theo thứ tự (dùng cho demo full-path, lặp)
## (GIỮ tween) Danh sách toạ độ là dữ liệu lưới tính lúc chạy — xem chú thích ở play_demo_drag.
func play_demo_path(positions: Array[Vector2], dur_per_step: float = 0.5) -> void:
	_kill_move_tween()
	_kill_demo_tween()
	_stop_anim()
	_is_running = false
	if positions.size() < 2:
		return

	_is_demoing = true
	visible = true

	_demo_tween = create_tween().set_loops()
	# Hiện tại vị trí đầu
	_demo_tween.tween_property(self, "position", positions[0], 0.0)
	_demo_tween.tween_property(self, "modulate:a", 0.0, 0.0)
	_demo_tween.tween_property(self, "scale", Vector2.ONE, 0.0)
	_demo_tween.tween_property(self, "rotation", 0.0, 0.0)
	_demo_tween.tween_property(self, "modulate:a", 1.0, 0.14)

	for i in range(1, positions.size()):
		var from_p: Vector2 = positions[i - 1]
		var to_p: Vector2 = positions[i]
		var dir := (to_p - from_p).normalized()
		var tilt := 0.0
		if dir.x > 0.1:
			tilt = deg_to_rad(12.0)
		elif dir.x < -0.1:
			tilt = deg_to_rad(-12.0)
		# Pre-hop squash
		_demo_tween.tween_property(self, "scale", Vector2(1.14, 0.86), 0.07)
		# Di chuyển sang ô tiếp theo (song song: vị trí + scale + nghiêng)
		_demo_tween.tween_property(self, "position", to_p, dur_per_step).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_demo_tween.parallel().tween_property(self, "scale", Vector2.ONE, dur_per_step)
		_demo_tween.parallel().tween_property(self, "rotation", tilt, dur_per_step * 0.45)
		# Đổ xuống khi chạm đích
		_demo_tween.tween_property(self, "scale", Vector2(1.18, 0.82), 0.08)
		_demo_tween.parallel().tween_property(self, "rotation", 0.0, 0.1)
		_demo_tween.tween_property(self, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Dừng ở đích rồi fade out, vòng lặp lại từ đầu
	_demo_tween.tween_interval(0.5)
	_demo_tween.tween_property(self, "modulate:a", 0.0, 0.22)
	_demo_tween.tween_interval(0.35)


## Trình diễn thử đi đè lên ô đã đi: di chuyển nửa đường rồi nảy lại (1 chu kỳ, không lặp)
## (GIỮ tween) Toạ độ tính lúc chạy — xem chú thích ở play_demo_drag.
func play_demo_fail_attempt(from_pos: Vector2, midway_pos: Vector2, recoil_dir: Vector2) -> void:
	_kill_move_tween()
	_kill_demo_tween()
	_stop_anim()
	_is_running = false

	_is_demoing = true
	visible = true
	position = from_pos
	modulate.a = 1.0
	scale = Vector2.ONE
	rotation = 0.0

	var push := recoil_dir.normalized() * 12.0

	_demo_tween = create_tween()
	# Squash chuẩn bị bước
	_demo_tween.tween_property(self, "scale", Vector2(1.12, 0.88), 0.08)
	# Di chuyển nửa đường về phía ô bị cấm
	_demo_tween.tween_property(self, "position", midway_pos, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_demo_tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.18)
	# Va chạm: squash mạnh + bị đẩy ngược
	_demo_tween.tween_property(self, "scale", Vector2(1.38, 0.68), 0.07)
	_demo_tween.parallel().tween_property(self, "position", midway_pos + push, 0.07)
	# Nảy đàn hồi về vị trí ban đầu
	_demo_tween.tween_property(self, "position", from_pos, 0.22).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_demo_tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Nghỉ rồi fade out (tutorial script tự lặp lại chu kỳ tiếp)
	_demo_tween.tween_interval(0.55)
	_demo_tween.tween_property(self, "modulate:a", 0.0, 0.2)
	_demo_tween.tween_callback(func() -> void:
		_is_demoing = false
		start_idle()
	)


## Trình diễn RÊ 1 lần từ from_pos → to_pos (Wall Builder: rê neo) — không lặp.
## (GIỮ tween) Toạ độ neo tính lúc chạy — xem chú thích ở play_demo_drag.
## Trượt thẳng bằng TRANS_SINE/EASE_IN_OUT để khớp nhịp với đường kéo của bàn.
func play_demo_slide(from_pos: Vector2, to_pos: Vector2, duration := 0.55) -> void:
	_kill_move_tween()
	_kill_demo_tween()
	_stop_anim()
	_is_running = false

	_is_demoing = true
	visible = true
	modulate.a = 1.0
	rotation = 0.0
	scale = Vector2.ONE
	position = from_pos

	_demo_tween = create_tween()
	_demo_tween.tween_property(self, "position", to_pos, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_demo_tween.parallel().tween_property(self, "scale", Vector2(0.92, 1.08), duration * 0.5)
	# Chạm đích: nén nhẹ rồi phục hồi
	_demo_tween.tween_property(self, "scale", Vector2(1.12, 0.88), 0.08)
	_demo_tween.tween_property(self, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_demo_tween.tween_callback(func() -> void:
		_is_demoing = false
		start_idle()
	)


## Dừng hoạt ảnh demo và đưa về trạng thái bình thường
func stop_demo() -> void:
	_kill_demo_tween()
	_is_demoing = false
	rotation = 0.0
	scale = Vector2.ONE
	modulate.a = 1.0
	# Nhả offset Icon (nếu cú rơi spawn_drop đang dở — xem chú thích `_play_anim`)
	if icon != null:
		icon.position = Vector2.ZERO
	start_idle()


## Nhịp thở khi đứng yên — animation "idle" (loop) trong player_cursor.tscn
func start_idle() -> void:
	if _is_running or _is_celebrating or _is_demoing:
		return
	_play_anim(&"idle")


## Bước chạy 1 ô: VỊ TRÍ do tween dưới đây lo (toạ độ bàn cờ tính lúc chạy);
## dáng nhảy (stretch → squash → nghiêng người) nằm trong animation "hop_*" của scene.
func run_to(target_pos: Vector2, move_dir: Vector2 = Vector2.ZERO, duration: float = 0.16) -> void:
	_kill_move_tween()
	_is_running = true
	var start_pos := position
	var hop_height := 14.0 # Độ nhấc chân khi chạy

	var t1 := duration * 0.38
	var half_way := start_pos.lerp(target_pos, 0.5) - Vector2(0, hop_height)

	_move_tween = create_tween().set_parallel(false)
	_move_tween.tween_property(self, "position", half_way, t1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_move_tween.tween_property(self, "position", target_pos, duration * 0.44).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# Giai đoạn phục hồi cân bằng (0.18) — chờ animation kết thúc rồi mới báo xong
	_move_tween.tween_interval(duration * 0.18)
	_move_tween.tween_callback(Callable(self, "_on_run_completed"))

	_play_anim(_hop_anim_for(move_dir), HOP_LENGTH / maxf(duration, 0.01))


## Đặt con trỏ về vị trí đích NGAY LẬP TỨC (không nhún), dọn mọi tween di chuyển/
## trình diễn đang chạy. Dùng khi nét vẽ đã cập nhật tức thì: đầu bút PHẢI trùng cuối
## nét ngay theo, không được trễ nhịp hop 0.16s (lỗi "bút không nằm ở cuối nét").
func snap_to(target_pos: Vector2) -> void:
	_kill_move_tween()
	_kill_demo_tween()
	_is_running = false
	_is_demoing = false
	position = target_pos
	rotation = 0.0
	scale = Vector2.ONE
	modulate.a = 1.0
	# Nhả luôn offset Icon (phòng khi cú rơi spawn_drop bị cắt giữa chừng hoặc scene thiếu
	# AnimationPlayer — xem chú thích `_play_anim`)
	if icon != null:
		icon.position = Vector2.ZERO
	_stop_anim()
	start_idle()


## Chọn biến thể dáng nhảy theo hướng đi (nghiêng người theo quán tính)
func _hop_anim_for(move_dir: Vector2) -> StringName:
	if move_dir.x > 0.1:
		return &"hop_right"
	if move_dir.x < -0.1:
		return &"hop_left"
	if move_dir.y > 0.1:
		return &"hop_down"
	if move_dir.y < -0.1:
		return &"hop_up"
	return &"hop_neutral"


func _on_run_completed() -> void:
	_is_running = false
	rotation = 0.0
	scale = Vector2.ONE
	run_finished.emit()
	start_idle()


## Hoạt ảnh Bonk / Recoil khi va vào tường vô hình: VỊ TRÍ lùi theo hướng va chạm (tween),
## dáng co rúm + lắc lư nằm trong animation "bonk_left"/"bonk_right" của scene.
func play_bonk_recoil(recoil_dir: Vector2 = Vector2.ZERO) -> void:
	_kill_move_tween()
	_is_running = true
	var base_pos := position
	var push_back := recoil_dir.normalized() * 16.0
	if push_back.is_zero_approx():
		push_back = Vector2(0, -14.0)

	_move_tween = create_tween()
	_move_tween.tween_property(self, "position", base_pos + push_back, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_move_tween.tween_property(self, "position", base_pos, 0.14).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	if not _play_anim(&"bonk_left" if push_back.x >= 0.0 else &"bonk_right"):
		_is_running = false


## Hoạt ảnh Nhảy múa ăn mừng (Celebration) khi tới ô Finish F — dáng nén → nảy phục hồi
## nằm trong animation "celebrate" của scene; code chỉ chờ xong để phát tín hiệu.
func play_celebration() -> void:
	_kill_move_tween()
	_is_celebrating = true
	if not _play_anim(&"celebrate"):
		_is_celebrating = false
		rotation = 0.0
		scale = Vector2.ONE
		celebration_finished.emit()
		start_idle()


## Rơi nhẹ vào ván mới tại ô S — animation "spawn_drop" (Icon rơi từ trên + stretch) trong scene.
##
## LƯU Ý: animation chỉ đụng ĐỘ CAO CỦA ICON CON (`Icon:position`) — KHÔNG đụng `position`
## của node gốc: lúc mới vào màn, bàn cờ còn đang được gắn vào bố cục (khung giấy đổi vài
## frame) nên gốc luôn do Board đặt theo bố cục.
func play_spawn_drop(_target_pos: Vector2) -> void:
	_kill_move_tween()
	if icon != null:
		icon.position = Vector2(0.0, -42.0)
	scale = Vector2(0.7, 1.35)
	modulate.a = 0.0
	if not _play_anim(&"spawn_drop"):
		if icon != null:
			icon.position = Vector2.ZERO
		scale = Vector2.ONE
		modulate.a = 1.0
		start_idle()
