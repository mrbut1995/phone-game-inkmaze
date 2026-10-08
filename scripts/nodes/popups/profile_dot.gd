class_name EditProfileDot
extends TextureButton
## ============================================================================
## Chấm phân trang của popup DIỆN MẠO HỒ SƠ (nodes/popups/profile_dot.tscn)
## Trước đây chấm được tạo bằng code (`TextureButton.new()`) — nay là SCENE riêng.
## Bấm được để nhảy tới trang tương ứng; chấm ĐANG XEM thì khoá lại.
## ============================================================================

## Art chấm — gán trong `profile_dot.tscn` (ExtResource)
@export var dot_active: Texture2D = null
@export var dot_inactive: Texture2D = null


func set_current(on: bool) -> void:
	var tex: Texture2D = dot_active if on else dot_inactive
	texture_normal = tex
	texture_pressed = dot_active
	texture_hover = dot_inactive if on else dot_active
	texture_focused = tex
	texture_disabled = tex
	disabled = on


## Chấm này có đang là trang đang xem không (dùng cho test/đồng bộ trạng thái)
func is_current() -> bool:
	return disabled
