class_name DungeonPill
extends Button
## ============================================================================
## Node: DungeonPill — nút DUNGEON nổi (floating) góc dưới-trái bản đồ Main
## (nodes/main/dungeon_pill.tscn). Thay thẻ ModeCard "Dungeon" cũ.
## Hiện: icon lâu đài · "DUNGEON" · "Tầng N" (kỷ lục). Bấm ⇒ tín hiệu `pressed` (Main lo vào chế độ).
## Dùng lại khoá chữ có sẵn: STR_MODE_DUNGEON_TITLE · STR_MODECARD_FLOOR_VAL.
## ============================================================================

@export var icon_tex: TextureRect = null
@export var lbl_title: Label = null
@export var lbl_floor: Label = null


## `best_floor` = tầng kỷ lục (Archivement.stat_value("dungeon_best_floor"))
func setup(best_floor: int) -> void:
	if lbl_title != null:
		lbl_title.text = tr("STR_MODE_DUNGEON_TITLE").to_upper()
	if lbl_floor != null:
		lbl_floor.text = tr("STR_MODECARD_FLOOR_VAL").format([best_floor])
