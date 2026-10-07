class_name MazeAnchor
extends Control
## ============================================================================
## View: Điểm neo góc (Anchor) tại giao điểm lưới.
## Người chơi kéo nối 2 Anchor kề nhau để tạo/bật/tắt "Tường Nghi Ngờ".
##
## Board chỉ gọi method (`set_anchor_size` · `play_entrance` · `set_selected` · `pulse`) —
## neo tự lo phần trình bày (tâm xoay · hiệu ứng) nên bên ngoài KHÔNG cần chạm node con.
## ============================================================================

signal anchor_tapped(anchor_id: int)

@export var anchor_id: int = -1

@export var SELECTED_MODULATE := Color(1.8, 1.4, 0.4, 1.0)
@export var NORMAL_MODULATE := Color(1.0, 1.0, 1.0, 1.0)

@onready var _button: TextureButton = $TextureButton
## AnimationPlayer của `anchor.tscn` — các dáng nở/chọn/nhấn khai trong scene,
## code chỉ set pose đầu + gọi play (kèm fallback tween nếu scene thiếu).
@onready var _anim: AnimationPlayer = get_node_or_null("AnimationPlayer")
## Hẹn giờ so le khi neo hiện ra — Timer khai trong `anchor.tscn` (dây `timeout` cũng ở đó);
## code chỉ đặt `wait_time` (theo toạ độ góc do Board tính) rồi `start()`.
@onready var _entrance_timer: Timer = get_node_or_null("EntranceTimer")


func _play_anim(anim_name: StringName) -> bool:
	if _anim == null or not _anim.has_animation(anim_name):
		return false
	_anim.play(anim_name)
	return true


## Đặt cỡ neo (Board tính theo số ô) — neo tự lo TÂM XOAY cho hiệu ứng
func set_anchor_size(side: float) -> void:
	size = Vector2(side, side)
	pivot_offset = size * 0.5


## Hiệu ứng xuất hiện khi vào màn — Board gọi cho từng neo, `delay` theo toạ độ góc
func play_entrance(delay: float) -> void:
	pivot_offset = size * 0.5
	scale = Vector2.ZERO
	if _anim != null and _anim.has_animation(&"entrance"):
		if delay > 0.0:
			if _entrance_timer != null:
				_entrance_timer.wait_time = delay
				_entrance_timer.start()
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


func _ready() -> void:
	# Anchor KHÔNG được "ăn" sự kiện chuột/cảm ứng: Board cần nhận trọn cú NHẤN + KÉO
	# để vẽ đường gợi ý (hint line) nối 2 anchor rồi tạo Tường Nghi Ngờ.
	# Ô Cell cũng nhường sự kiện y hệt (cell.gd::_ready) nên kéo vẽ đường đi mới chạy được.
	if _button != null:
		_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_button_pressed() -> void:
	anchor_tapped.emit(anchor_id)


func set_selected(active: bool) -> void:
	if _button == null:
		_button = $TextureButton
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
			if _button != null:
				_button.modulate = NORMAL_MODULATE
			return
	# Fallback khi scene thiếu AnimationPlayer
	var tw := create_tween().set_parallel(true)
	if active:
		tw.tween_property(self, "scale", Vector2(1.35, 1.35), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if _button != null:
			tw.tween_property(_button, "modulate", SELECTED_MODULATE, 0.1)
	else:
		tw.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if _button != null:
			tw.tween_property(_button, "modulate", NORMAL_MODULATE, 0.12)


func pulse() -> void:
	pivot_offset = size * 0.5
	if _play_anim(&"pulse"):
		return
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.4, 1.4), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
