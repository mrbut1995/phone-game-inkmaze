class_name DockButton
extends Button
## ============================================================================
## Node: DockButton — 1 nút trong dock chức năng dưới cùng (Cửa hàng · Xếp hạng ·
## Thử thách · Danh hiệu). Art (StyleBoxTexture 9-slice) do SCENE dùng cung cấp;
## màu viền chữ + icon + nhãn dịch đặt trong `.tscn` của từng layout.
##
## Chấm đỏ "có thứ chưa nhận" hiện khi `set_badge(n>0)`.
## ============================================================================

## Icon trắng của nút (nạp từ `.tscn` của màn dùng)
@export var icon_texture: Texture2D = null
## Khoá dịch cho nhãn dưới icon (`&""` = giữ chữ có sẵn trong scene)
@export var label_key: StringName = &""
## Màu viền chữ (= màu đáy 3D của nút) để nhãn đọc rõ trên nền màu
@export var outline_color := Color(0, 0, 0, 0.35)

@onready var icon_rect: TextureRect = $Icon
@onready var label: Label = $Label
@onready var badge: Panel = $Badge
@onready var badge_label: Label = $Badge/BadgeLabel


func _ready() -> void:
	if icon_texture != null and icon_rect != null:
		icon_rect.texture = icon_texture
	if label != null:
		label.add_theme_color_override("font_outline_color", outline_color)
		if label_key != &"":
			label.text = tr(String(label_key))
	if badge != null:
		badge.visible = false  # keep-code: trạng thái theo dữ liệu (runtime)


## Gán icon + nhãn (nhãn đã dịch từ ngoài truyền vào)
func setup(icon_tex: Texture2D, text: String) -> void:
	if icon_rect != null:
		icon_rect.texture = icon_tex
	if label != null:
		label.text = text


## Chấm đỏ thông báo (0 = ẩn)
func set_badge(count: int) -> void:
	if badge == null:
		return
	badge.visible = count > 0
	if badge_label != null:
		badge_label.text = str(count)
