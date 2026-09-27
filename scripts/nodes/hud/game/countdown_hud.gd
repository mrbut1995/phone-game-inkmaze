class_name CountdownHUD
extends GameHUD
## ============================================================================
## HUD Countdown Cost.
##
## 2026-09-27 — theo yêu cầu "chỉ hiện thứ cần thiết": HUD này CHỈ hiện **NGÂN SÁCH CÒN**
## ("12 / 15").  Đã gỡ khỏi HUD: TIÊU TỐN · GIÁ CƯỚC + chip rẻ/đắt · dải phân đoạn ngân sách ·
## đồng hồ THỜI GIAN (node `Time` của bản DỌC để `visible = false`, bản NGANG đã xoá khỏi scene).
## Giá cước từng ô vẫn hiện NGAY TRÊN Ô của bàn cờ (số trên ô = chi phí bước).
## ============================================================================

## NGÂN SÁCH CÒN — số dư (`Content/ModeInformation/Sheet/Budget/Value`)
@export var budget_value_node : Label
## Tổng ngân sách của màn (`…/Sheet/Budget/Max`)
@export var budget_max_label : Label


func _on_update(ctx: Dictionary) -> void:
	var mode := ctx.get("mode", null) as CountdownCostGameMode
	if mode == null:
		return
	var total: int = maxi(mode.initial_steps, 1)
	var left: int = clampi(int(ctx.get("steps_remaining", 0)), 0, total)
	set_label_text(budget_value_node, "%02d" % left)
	set_label_text(budget_max_label, "/ %d" % total)
