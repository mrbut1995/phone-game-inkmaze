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

@onready var value_label: Label = $Content/Value
@onready var plus_button: Button = $Content/Plus


func _ready() -> void:
	if plus_button != null:
		plus_button.pressed.connect(_on_plus_pressed)
	var game_manager := get_node_or_null("/root/GameManager")
	if game_manager != null and game_manager.has_signal("life_changed") \
			and not game_manager.is_connected("life_changed", _on_life_changed):
		game_manager.connect("life_changed", _on_life_changed)
	refresh()


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
