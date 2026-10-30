class_name AchThumb
extends TextureButton
## ============================================================================
## Ảnh thu nhỏ tròn trong dải điều hướng của Sổ tay (nodes/achievements/thumb.tscn).
## Viền màu theo trạng thái (đang làm / đã nhận / chờ nhận / khoá) + icon danh hiệu.
## Thumb đang xem = to hơn + có vầng sáng (Halo). Bấm ⇒ phát `pressed` (màn tự nhảy trang).
## ============================================================================

@export var icon_lock: Texture2D = null
@export var halo: Control = null
@export var ring: Control = null
@export var face: Control = null
@export var icon: TextureRect = null

@export var SIZE_IDLE := Vector2(46, 46)
@export var SIZE_SELECTED := Vector2(56, 56)
## 0 = mặt thumb đặc màu trạng thái (giống huy hiệu thẻ); 0.88 = mặt gần trắng — dùng nếu icon là nét TỐI
@export_range(0.0, 1.0) var FACE_LIGHTEN := 0.0
@export var COLOR_CLAIMED := Color(0.18039216, 0.49019608, 0.19607843, 1)
@export var COLOR_CLAIMABLE := Color(0.8509804, 0.46666667, 0.023529412, 1)
@export var COLOR_PROGRESS := Color(0.23921569, 0.5137255, 0.68235296, 1)
@export var COLOR_LOCKED := Color(0.7294118, 0.78039217, 0.8117647, 1)    # #BAC7CF

## Chỉ số của danh hiệu trong danh sách (màn gán khi cập nhật thumb)
var entry_index := 0


func setup(entry: Dictionary, index: int, selected: bool) -> void:
	entry_index = index
	var hidden := bool(entry.get("secret_hidden", false))
	var color := COLOR_PROGRESS
	if hidden:
		color = COLOR_LOCKED
	elif bool(entry.get("claimed", false)):
		color = COLOR_CLAIMED
	elif bool(entry.get("claimable", false)):
		color = COLOR_CLAIMABLE

	ring.modulate = color
	face.modulate = color.lerp(Color.WHITE, FACE_LIGHTEN)
	icon.texture = icon_lock if hidden else entry.get("icon", null)
	icon.modulate = Color.WHITE  # keep-code: hoạt cảnh/trạng thái runtime (tween)
	set_selected(selected)


func set_selected(on: bool) -> void:
	custom_minimum_size = SIZE_SELECTED if on else SIZE_IDLE
	if halo != null:
		halo.visible = on
