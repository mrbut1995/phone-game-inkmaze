class_name ChallengeHUD
extends LevelHUD
## ============================================================================
## HUD CHALLENGE MODE (2026-10): khối THỜI GIAN của HUD hiển thị TRẠNG THÁI THỬ THÁCH
## thay vì đồng hồ ván (theo yêu cầu "update lại text trên Time Head, value, Sub Value"):
##   Head  = tên luật (ĐẾM NGƯỢC · GIỚI HẠN BƯỚC · TỪNG BƯỚC · KHÔNG GỢI Ý · ...)
##   Value = số chính (giây còn lại / số bước đã đi / số lượt quay đầu còn lại)
##   Sub   = chú thích nhỏ ("CÒN LẠI" · "/20 BƯỚC" · "DÙNG GỢI Ý = THUA" · ...)
##
## Dữ liệu do GameController gửi trong `ctx["challenge"]` (xem `_challenge_hud_ctx()`);
## chữ nghĩa do `ChallengeGameMode.hud_state()` lo. Khi CẬN KỀ thất bại (info["low"])
## số chính chuyển ĐỎ để cảnh báo người chơi.
## ============================================================================

const COLOR_WARN := Color(0.85, 0.2, 0.2)

## Node binding: khai `node_paths` + `NodePath` trong `challenge_hud.tscn` (2 bản dọc/ngang)
@export var head_node: Label = null


func _on_update(ctx: Dictionary) -> void:
	var info: Dictionary = ctx.get("challenge", {})
	if info.is_empty():
		return
	set_label_text(head_node, str(info.get("head", "")))
	var value := str(info.get("value", ""))
	var sub := str(info.get("sub", ""))
	# Bản NGANG không có node Sub -> ghép chú thích vào sau số chính (không mất thông tin)
	if sub_value_node == null and not sub.is_empty():
		value = "%s %s" % [value, sub]
	set_label_text(time_value_node, value)
	if time_value_node != null:
		time_value_node.modulate = COLOR_WARN if bool(info.get("low", false)) else Color.WHITE
	if sub_value_node != null:
		sub_value_node.visible = not sub.is_empty()
		if not sub.is_empty():
			set_label_text(sub_value_node, sub)
