class_name CoinChip
extends Control
## ============================================================================
## Node: CoinChip — ví "Xu Mực" dùng chung trên thanh trên của mọi màn hình.
## Icon giọt mực vàng + số Xu + nút `+` (mặc định mở Cửa hàng).
##
## Chip TỰ cập nhật số dư (nghe `ArchivementManager.progress_changed`) nên màn
## hình không phải nối dây thủ công. `navigate_on_plus = false` dành cho màn
## Cửa hàng, nơi nút `+` chỉ chuyển sang tab NẠP XU.
## ============================================================================

signal plus_pressed

@export var navigate_on_plus := true

@onready var value_label: Label = $Content/Value
@onready var plus_button: Button = $Content/Plus


func _ready() -> void:
	if plus_button != null:
		plus_button.pressed.connect(_on_plus_pressed)
	var wallet := get_node_or_null("/root/ArchivementManager")
	if wallet != null and wallet.has_signal("progress_changed") \
			and not wallet.is_connected("progress_changed", _on_wallet_changed):
		wallet.connect("progress_changed", _on_wallet_changed)
	set_value(Shop.coins())


func set_value(amount: int) -> void:
	if value_label != null:
		value_label.text = Shop.thousands(amount)


func _on_wallet_changed() -> void:
	set_value(Shop.coins())


func _on_plus_pressed() -> void:
	if navigate_on_plus:
		Sfx.play(Sfx.BTN_CLICK)
		Nav.goto_shop()
	plus_pressed.emit()
