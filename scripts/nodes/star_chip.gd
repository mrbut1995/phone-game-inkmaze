class_name StarChip
extends Control
## ============================================================================
## Node: StarChip — tổng "Sao" trên thanh trên của Main Screen.
## Nguồn số: GameManager.total_stars() (cùng số dùng mở khoá chương — §12.3).
## ============================================================================

@onready var value_label: Label = $Value


func set_value(amount: int) -> void:
	if value_label != null:
		value_label.text = Shop.thousands(amount)
