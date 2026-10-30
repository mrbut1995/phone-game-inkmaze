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

@export_group("Large variant")
## Biến thể LỚN dùng ở màn Main (cao hơn, icon/số/nút `+` to hơn) — bật trong `.tscn`
@export var large := false
@export var large_height := 46.0
@export var large_width_scale := 1.3
@export var large_icon_width := 32.0
@export var large_value_font := 22
@export var large_plus_size := 32.0
@export var large_plus_font := 18

@onready var value_label: Label = $Content/Value
@onready var plus_button: Button = $Content/Plus


func _ready() -> void:
	# Nút `+` (`Content/Plus`) nối `pressed` trong nodes/main/coin_chip.tscn
	if large:
		_apply_large()
	var wallet := Svc.archivement()
	if wallet != null and wallet.has_signal("progress_changed") \
			and not wallet.is_connected("progress_changed", _on_wallet_changed):  # keep-code: signal của AUTOLOAD / node sinh lúc chạy — không phải node tĩnh
		wallet.connect("progress_changed", _on_wallet_changed)  # keep-code: signal của AUTOLOAD / node sinh lúc chạy — không phải node tĩnh
	set_value(Shop.coins())


func _apply_large() -> void:
	var icon := get_node_or_null("Content/Icon") as Control
	custom_minimum_size = Vector2(custom_minimum_size.x * large_width_scale, large_height)
	if icon != null:
		icon.custom_minimum_size.x = large_icon_width
	if value_label != null:
		value_label.add_theme_font_size_override("font_size", large_value_font)
	if plus_button != null:
		plus_button.custom_minimum_size = Vector2(large_plus_size, large_plus_size)
		plus_button.add_theme_font_size_override("font_size", large_plus_font)


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
