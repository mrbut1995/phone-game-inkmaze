extends Control
## ============================================================================
## View: Điểm neo góc (Anchor) tại giao điểm lưới.
## Người chơi kéo nối 2 Anchor kề nhau để tạo/bật/tắt "Tường Nghi Ngờ".
## ============================================================================

signal anchor_tapped(anchor_id: int)

@export var anchor_id: int = -1

const SELECTED_MODULATE := Color(1.8, 1.4, 0.4, 1.0)
const NORMAL_MODULATE := Color(1.0, 1.0, 1.0, 1.0)

@onready var _button: TextureButton = $TextureButton


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
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.4, 1.4), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
