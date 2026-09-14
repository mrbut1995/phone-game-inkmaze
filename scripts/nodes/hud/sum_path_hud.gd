class_name SumPathHUD
extends BaseHUD
## HUD Sum Path: THỜI GIAN + TỔNG HIỆN TẠI + TOÁN TỬ (<, >, =) + MỤC TIÊU.
## Panel TOÁN TỬ nằm GIỮA panel TỔNG và panel MỤC TIÊU (dạng "12 = 23").
## Thay cho thẻ THỬ THÁCH của HUD mặc định.


func _on_update(ctx: Dictionary) -> void:
	var mode := ctx.get("mode", null) as SumPathGameMode
	if mode == null:
		return
	set_label_text(get_node_or_null("Sum/Value"), str(mode.current_sum))
	set_label_text(get_node_or_null("Operator/Value"), mode.operator)
	set_label_text(get_node_or_null("Target/Value"), str(mode.target_val))
