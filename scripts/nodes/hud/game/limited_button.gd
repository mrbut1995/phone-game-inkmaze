class_name LimitedButton
extends TextureButton
## ============================================================================
## Nút có BADGE GIỚI HẠN LƯỢT (`PanelLimit` + `Label` là CON của nút — khai trong scene
## `nodes/hud/<hướng>/game/action_bar.tscn`, dùng cho nút HOÀN TÁC · GỢI Ý).
##
## Nhờ vậy `ActionBar` chỉ gọi `set_limit(left, max_uses)` — nút tự lo chữ trên badge + trạng thái
## khoá của chính mình, bên ngoài KHÔNG phải `find_child("PanelLimit")` rồi sửa node con.
## ============================================================================

## Cập nhật badge + khoá nút. `max_uses <= 0` = màn không giới hạn lượt ⇒ ẩn badge, không khoá.
func set_limit(left: int, max_uses: int) -> void:
	var limited := max_uses > 0
	disabled = limited and left <= 0
	var panel := get_node_or_null("PanelLimit") as Control
	if panel == null:
		return
	panel.visible = limited
	var label := panel.get_node_or_null("Label") as Label
	if label != null:
		label.text = str(maxi(left, 0))
