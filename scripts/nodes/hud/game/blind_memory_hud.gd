class_name BlindMemoryHUD
extends GameHUD
## ============================================================================
## HUD Blind Memory: KHÔNG có thẻ THỬ THÁCH — chỉ THỜI GIAN + thẻ nhắc GHI NHỚ.
## Pha ghi nhớ (hiện tường + đếm ngược 3-2-1-GO!) do popup lo:
##   scripts/nodes/popups/memory_countdown.gd — xem GameController._start_memorize_phase().
## ============================================================================


func _on_update(ctx: Dictionary) -> void:
	# Dòng nhỏ cuối thẻ ghi nhớ: chế độ đang chơi (CHẾ ĐỘ: NORMAL / HARDCORE)
	set_label_text(get_node_or_null("Content/ModeInformation/Note/Phase"), str(ctx.get("extra", "")))
