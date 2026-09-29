class_name DungeonHUD
extends BaseHUD
## HUD Dungeon Mode (endless): THỜI GIAN + SỐ BƯỚC + TẦNG.
## Đây là chế độ DUY NHẤT có bộ đếm bước còn lại (xem Design.md — quy ước "Số bước").

## Số bước còn lại (`Content/ModeInformation/Control/Step/Value` — bản NGANG gom trong `Control`)
@export var step_value_node : Label
## Số tầng hiện tại (`Content/ModeInformation/Control/Floor/Value`)
@export var floor_value_node : Label


func _on_update(ctx: Dictionary) -> void:
	set_label_text(step_value_node, str(maxi(int(ctx.get("steps_remaining", 0)), 0)))
	set_label_text(floor_value_node, "%02d" % maxi(int(ctx.get("floor_number", 1)), 1))
