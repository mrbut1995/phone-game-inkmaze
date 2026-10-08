class_name MazeAnchor
extends Control
## ============================================================================
## View: Điểm neo góc (Anchor) tại giao điểm lưới.
## Người chơi kéo nối 2 Anchor kề nhau để tạo/bật/tắt "Tường Nghi Ngờ".
##
## Board chỉ gọi method (`set_anchor_size` · `play_entrance` · `set_selected` · `pulse`) —
## neo tự lo phần trình bày (tâm xoay · hiệu ứng) nên bên ngoài KHÔNG cần chạm node con.
##
## LƯU Ý SỰ KIỆN CHUỘT: neo KHÔNG được "ăn" nhấn/kéo — Board phải nhận trọn cú NHẤN + KÉO
## để vẽ đường gợi ý (hint line) nối 2 neo rồi tạo Tường Nghi Ngờ; `mouse_filter = 2` (IGNORE)
## khai SẴN trong `anchor.tscn` cho CẢ root lẫn TextureButton (ô Cell cũng nhường y hệt).
## MỌI tham số (node · hiệu ứng · màu) chỉnh TRONG `anchor.tscn` — script chỉ `@export`.
## ============================================================================

signal anchor_tapped(anchor_id: int)

@export var anchor_id: int = -1

@export var SELECTED_MODULATE := Color(1.8, 1.4, 0.4, 1.0)
@export var NORMAL_MODULATE := Color(1.0, 1.0, 1.0, 1.0)

## Node binding: khai `node_paths` + NodePath trong `anchor.tscn`
@export var button: TextureButton = null
## AnimationPlayer của `anchor.tscn` — các dáng nở/chọn/nhấn khai trong scene,
## code chỉ set pose đầu + gọi play (kèm fallback tween nếu scene thiếu).
@export var anim: AnimationPlayer = null
## Hẹn giờ so le khi neo hiện ra — Timer khai trong `anchor.tscn` (dây `timeout` cũng ở đó);
## code chỉ đặt `wait_time` (theo toạ độ góc do Board tính) rồi `start()`.
@export var entrance_timer: Timer = null


func _play_anim(anim_name: StringName) -> bool:
	if anim == null or not anim.has_animation(anim_name):
		return false
	anim.play(anim_name)
	return true


## Đặt cỡ neo (Board tính theo số ô) — neo tự lo TÂM XOAY cho hiệu ứng
func set_anchor_size(side: float) -> void:
	size = Vector2(side, side)
	pivot_offset = size * 0.5


## Hiệu ứng xuất hiện khi vào màn — Board gọi cho từng neo, `delay` theo toạ độ góc
func play_entrance(delay: float) -> void:
	pivot_offset = size * 0.5
	scale = Vector2.ZERO
	if anim != null and anim.has_animation(&"entrance"):
		if delay > 0.0:
			if entrance_timer != null:
				entrance_timer.wait_time = delay
				entrance_timer.start()
			else:
				# Fallback khi scene thiếu EntranceTimer (dây thật khai trong anchor.tscn)
				get_tree().create_timer(delay).timeout.connect(_play_entrance_now)
		else:
			_play_entrance_now()
		return
	# Fallback khi scene thiếu AnimationPlayer
	var tw := create_tween()
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _play_entrance_now() -> void:
	_play_anim(&"entrance")


func _on_button_pressed() -> void:
	anchor_tapped.emit(anchor_id)


func set_selected(active: bool) -> void:
	if active:
		if _play_anim(&"selected"):
			return
	else:
		# Chỉ chạy animation thu nhỏ khi neo ĐANG ở trạng thái chọn (scale lớn);
		# nếu đang là dáng thường thì trả về ngay, tránh "giật" do animation ép key gốc.
		if scale.x > 1.01:
			if _play_anim(&"unselected"):
				return
		else:
			scale = Vector2.ONE
			if button != null:
				button.modulate = NORMAL_MODULATE
			return
	# Fallback khi scene thiếu AnimationPlayer
	var tw := create_tween().set_parallel(true)
	if active:
		tw.tween_property(self, "scale", Vector2(1.35, 1.35), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if button != null:
			tw.tween_property(button, "modulate", SELECTED_MODULATE, 0.1)
	else:
		tw.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if button != null:
			tw.tween_property(button, "modulate", NORMAL_MODULATE, 0.12)


func pulse() -> void:
	pivot_offset = size * 0.5
	if _play_anim(&"pulse"):
		return
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.4, 1.4), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
