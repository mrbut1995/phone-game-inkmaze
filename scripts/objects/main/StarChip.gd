class_name StarChip
extends Control
## ============================================================================
## Node: StarChip — tổng "Sao" trên thanh trên của Main Screen.
## Nguồn số: GameManager.total_stars() (cùng số dùng mở khoá chương — §12.3).
## ============================================================================

## Scene contract
## Exports:  (none)
## Emits:    (none)
## Handlers wired in scene: (none)
## Subscribes in code (EventBus/Model): (none)

@onready var value_label: Label = $Value


func set_value(amount: int) -> void:
	if value_label != null:
		value_label.text = Shop.thousands(amount)
