class_name SettingsToggleStamp
extends TextureRect
## ============================================================================
## SettingsToggleStamp — TEM trạng thái BẬT / TẮT nằm ở góc ô công tắc (màn Cài đặt)
## Tem tự đổi hình theo `button.toggled` (✓ đỏ khi bật · gạch xám khi tắt). Art + nút gán trong scene.
## ============================================================================

## Nút công tắc (mặc định = node cha)
@export var button: BaseButton = null
@export var tex_on: Texture2D = null
@export var tex_off: Texture2D = null


func _ready() -> void:
	if button == null:
		button = get_parent() as BaseButton
	if button != null and not button.toggled.is_connected(_refresh):
		button.toggled.connect(_refresh)
	_refresh(button != null and button.button_pressed)


func _refresh(on: bool) -> void:
	texture = tex_on if on else tex_off
