class_name DungeonHUD
extends GameHUD
## HUD Dungeon Mode (endless): THỜI GIAN + SỐ BƯỚC + TẦNG.
## Đây là chế độ DUY NHẤT có bộ đếm bước còn lại (xem Design.md — quy ước "Số bước").


func _on_update(ctx: Dictionary) -> void:
	set_label_text(get_node_or_null("Content/ModeInformation/Step/Value"), str(maxi(int(ctx.get("steps_remaining", 0)), 0)))
	set_label_text(get_node_or_null("Content/ModeInformation/Floor/Value"), "%02d" % maxi(int(ctx.get("floor_number", 1)), 1))
