class_name DungeonPill
extends Button
## ============================================================================
## Node: DungeonPill — nút DUNGEON nổi góc dưới-trái bản đồ Main (kiểu M: vé giấy đục lỗ).
## Bố cục + art khai trong `.tscn` (`nodes/main/dungeon_pill.tscn`); ở đây chỉ xử lý runtime:
## đổi art khi nhấn, đẩy nội dung xuống theo độ lún của vé, và điền chữ theo dữ liệu.
##
## ART (đổi theme = thay file cùng tên + cùng cỡ logic, xem `tools/gen_dungeon_m.py`):
##   `assets/images-png/dungeon/dungeon_ticket.png` (488×172 = 244×86) · `dungeon_ticket_pressed.png`
##   · `dungeon_icon.png` (100×100 = 50×50)
## Bấm ⇒ tín hiệu `pressed` (Main lo vào chế độ). Chữ: STR_MODE_DUNGEON_TITLE · STR_MODECARD_FLOOR_VAL.
## ============================================================================

## Độ lún của nội dung khi nhấn — khớp phần vé bị ấn xuống trong `dungeon_ticket_pressed.png`
const PRESS_SHIFT := Vector2(2, 3)

@export var icon_tex: TextureRect = null
@export var lbl_title: Label = null
@export var lbl_floor: Label = null
@export var art: TextureRect = null
@export var content: Control = null
## Art lúc NHẤN (surface của vé lún xuống) — khai trong scene
@export var art_pressed: Texture2D = null

var _tex_up: Texture2D = null


func _ready() -> void:
	if art != null:
		_tex_up = art.texture


## Nhấn / nhả / rời nút ⇒ đổi art + độ lún (signal khai trong `dungeon_pill.tscn`)
func _on_button_down() -> void:
	_set_pressed_look(true)


func _on_button_up() -> void:
	_set_pressed_look(false)


func _on_pointer_exited() -> void:
	_set_pressed_look(false)


func _set_pressed_look(down: bool) -> void:
	if art != null and art_pressed != null and _tex_up != null:
		art.texture = art_pressed if down else _tex_up
	if content != null:
		content.position = PRESS_SHIFT if down else Vector2.ZERO


## `best_floor` = tầng kỷ lục (Achievement.stat_value("dungeon_best_floor"))
func setup(best_floor: int) -> void:
	if lbl_title != null:
		lbl_title.text = tr("STR_MODE_DUNGEON_TITLE").to_upper()
	if lbl_floor != null:
		lbl_floor.text = tr("STR_MODECARD_FLOOR_VAL").format([best_floor])
