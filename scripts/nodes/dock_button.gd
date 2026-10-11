class_name DockButton
extends Button
## ============================================================================
## Node: DockButton — 1 nút trong dock chức năng dưới cùng (Cửa hàng · Xếp hạng ·
## Danh hiệu · Luật chơi). Art: `btn_menu_utility_*` (9-slice StyleBoxTexture).
##
## Chấm đỏ "có thứ chưa nhận" hiện khi `set_badge(n>0)`.
## ============================================================================

@onready var icon_rect: TextureRect = $Icon
@onready var label: Label = $Label
@onready var badge: Panel = $Badge
@onready var badge_label: Label = $Badge/BadgeLabel


func _ready() -> void:
	if badge != null:
		badge.visible = false


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
