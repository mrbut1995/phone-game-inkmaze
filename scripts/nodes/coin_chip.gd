class_name CoinChip
extends Control
## ============================================================================
## Node: CoinChip — ví "Xu Mực" trên thanh trên của Main Screen.
## Icon giọt mực vàng + số Xu + nút `+` (mở Cửa hàng).
## ============================================================================

signal plus_pressed

@onready var value_label: Label = $Content/Value
@onready var plus_button: Button = $Content/Plus


func _ready() -> void:
	if plus_button != null:
		plus_button.pressed.connect(func() -> void: plus_pressed.emit())


func set_value(amount: int) -> void:
	if value_label != null:
		value_label.text = Shop.thousands(amount)
