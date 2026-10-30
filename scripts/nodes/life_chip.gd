class_name LifeChip
extends Control
## ============================================================================
## Node: LifeChip — LƯỢT CHƠI (life) trên thanh trên của các màn hình.
## Trái tim + "còn/tối đa" + nút `+` (chỉ hiện khi CHƯA đầy lượt, mở Cửa hàng).
##
## Chip TỰ cập nhật (nghe `GameManager.life_changed`) nên màn hình không phải nối dây.
## `navigate_on_plus = false` dành cho màn Cửa hàng (đang ở Shop thì không mở lại Shop).
## ============================================================================

signal plus_pressed

@export var navigate_on_plus := true
## Hiện "3/5" thay vì chỉ số lượt còn lại
@export var show_max := true
## Ẩn nút `+` khi đã đầy lượt (mặc định: đúng — chỉ hiện khi còn thiếu lượt)
@export var hide_plus_when_full := true

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
	# Nút `+` (`Content/Plus`) nối `pressed` trong nodes/main/life_chip.tscn
	if large:
		_apply_large()
	var game_manager := Svc.game()
	if game_manager != null and game_manager.has_signal("life_changed") \
			and not game_manager.is_connected("life_changed", _on_life_changed):  # keep-code: signal của AUTOLOAD / node sinh lúc chạy — không phải node tĩnh
		game_manager.connect("life_changed", _on_life_changed)  # keep-code: signal của AUTOLOAD / node sinh lúc chạy — không phải node tĩnh
	refresh()


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


## Đọc lại số lượt từ GameManager
func refresh() -> void:
	set_values(Life.count(), Life.max_count())


func set_values(current: int, maximum: int) -> void:
	if value_label != null:
		value_label.text = ("%d/%d" % [current, maximum]) if show_max else str(current)
	if plus_button != null and hide_plus_when_full:
		plus_button.visible = current < maximum


func _on_life_changed(current: int, maximum: int) -> void:
	set_values(current, maximum)


func _on_plus_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	plus_pressed.emit()
	if navigate_on_plus:
		Nav.goto_shop()
