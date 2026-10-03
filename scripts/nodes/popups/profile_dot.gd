class_name EditProfileDot
extends TextureButton
## ============================================================================
## Chấm phân trang của popup DIỆN MẠO HỒ SƠ (nodes/popups/profile_dot.tscn)
## Trước đây chấm được tạo bằng code (`TextureButton.new()`) — nay là SCENE riêng.
## Bấm được để nhảy tới trang tương ứng; chấm ĐANG XEM thì khoá lại.
## ============================================================================

const DOT_ACTIVE := preload("res://assets/images-png/profiler/page_dot_on.png")
const DOT_INACTIVE := preload("res://assets/images-png/profiler/page_dot_off.png")


func set_current(on: bool) -> void:
	var tex: Texture2D = DOT_ACTIVE if on else DOT_INACTIVE
	texture_normal = tex
	texture_pressed = DOT_ACTIVE
	texture_hover = DOT_INACTIVE if on else DOT_ACTIVE
	texture_focused = tex
	texture_disabled = tex
	disabled = on


## Chấm này có đang là trang đang xem không (dùng cho test/đồng bộ trạng thái)
func is_current() -> bool:
	return disabled
