class_name LimitedButton
extends TextureButton
## ============================================================================
## Nút có BADGE GIỚI HẠN LƯỢT (`PanelLimit` + `Label` là CON của nút — khai trong scene
## `nodes/hud/<hướng>/game/action_bar.tscn`, dùng cho nút HOÀN TÁC · GỢI Ý).
##
## Nhờ vậy `ActionBar` chỉ gọi `set_limit(left, max_uses)` — nút tự lo chữ trên badge + trạng thái
## khoá của chính mình, bên ngoài KHÔNG phải `find_child("PanelLimit")` rồi sửa node con.
## ============================================================================

## Node binding: khai `node_paths` + NodePath cho TỪNG nút (Undo/Hint) trong
## `nodes/hud/portrait/game/action_bar.tscn` + `nodes/hud/landscape/game/action_bar.tscn`
@export var panel_limit: Control = null
@export var limit_label: Label = null


## Cập nhật badge + khoá nút. `max_uses <= 0` = màn không giới hạn lượt ⇒ ẩn badge, không khoá.
func set_limit(left: int, max_uses: int) -> void:
	var limited := max_uses > 0
	disabled = limited and left <= 0
	if panel_limit == null:
		return
	panel_limit.visible = limited
	if limit_label != null:
		limit_label.text = str(maxi(left, 0))
