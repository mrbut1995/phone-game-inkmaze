class_name LimitedButton
extends TextureButton
## ============================================================================
## Nút có badge số lượt còn lại (`PanelLimit` + `Label` là CON của nút — khai trong scene
## action_bar.tscn, dùng cho Skip · Hoàn tác · Gợi ý).
##
## Nhờ vậy `ActionBar` chỉ gọi `set_remaining(left)` — nút tự lo chữ trên badge + trạng thái
## khoá của chính mình, bên ngoài KHÔNG phải `find_child("PanelLimit")` rồi sửa node con.
## ============================================================================

## Node binding: khai `node_paths` + NodePath cho TỪNG nút (Skip/Undo/Hint) trong
## `nodes/hud/portrait/game/action_bar.tscn` + `nodes/hud/landscape/game/action_bar.tscn`
@export var panel_limit: Control = null
@export var limit_label: Label = null


## Cập nhật số dư toàn tài khoản và khoá nút khi đã dùng hết.
func set_remaining(left: int) -> void:
	disabled = left <= 0
	if panel_limit == null:
		return
	panel_limit.visible = true
	if limit_label != null:
		limit_label.text = str(maxi(left, 0))
