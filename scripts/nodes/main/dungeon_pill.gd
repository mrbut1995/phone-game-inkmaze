class_name DungeonPill
extends Button
## ============================================================================
## Node: DungeonPill — nút DUNGEON nổi góc dưới-trái bản đồ Main (kiểu M: vé giấy đục lỗ).
## ART (thay theme = thay file cùng tên + cùng kích thước logic, xem tools gen_dungeon_m.py):
##   assets/images-png/dungeon/dungeon_ticket.png (488×172 = 244×86) · dungeon_ticket_pressed.png · dungeon_icon.png (100×100 = 50×50)
## Bấm ⇒ tín hiệu `pressed` (Main lo vào chế độ). Chữ: STR_MODE_DUNGEON_TITLE · STR_MODECARD_FLOOR_VAL.
## ============================================================================

const ART_DIR := "res://assets/images-png/dungeon/"
const SIZE := Vector2(244, 86)
const MARGIN := 12.0
const PRESS_SHIFT := Vector2(2, 3)  # khớp độ lún của dungeon_ticket_pressed

@export var icon_tex: TextureRect = null
@export var lbl_title: Label = null
@export var lbl_floor: Label = null
@export var art: TextureRect = null
@export var content: Control = null

var _tex_up: Texture2D = null
var _tex_down: Texture2D = null


func _ready() -> void:
	# Neo góc dưới-trái, bất kể offset cũ trong level_section.tscn
	anchor_left = 0.0
	anchor_right = 0.0
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_left = MARGIN
	offset_right = MARGIN + SIZE.x
	offset_top = -MARGIN - SIZE.y
	offset_bottom = -MARGIN
	custom_minimum_size = SIZE
	if art != null:
		_tex_up = art.texture
	var down_path := ART_DIR + "dungeon_ticket_pressed.png"
	if ResourceLoader.exists(down_path):
		_tex_down = load(down_path) as Texture2D
	button_down.connect(_set_pressed_look.bind(true))
	button_up.connect(_set_pressed_look.bind(false))
	mouse_exited.connect(_set_pressed_look.bind(false))


func _set_pressed_look(down: bool) -> void:
	if art != null and _tex_down != null and _tex_up != null:
		art.texture = _tex_down if down else _tex_up
	if content != null:
		content.position = PRESS_SHIFT if down else Vector2.ZERO


## `best_floor` = tầng kỷ lục (Archivement.stat_value("dungeon_best_floor"))
func setup(best_floor: int) -> void:
	if lbl_title != null:
		lbl_title.text = tr("STR_MODE_DUNGEON_TITLE").to_upper()
	if lbl_floor != null:
		lbl_floor.text = tr("STR_MODECARD_FLOOR_VAL").format([best_floor])
