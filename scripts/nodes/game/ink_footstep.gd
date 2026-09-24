class_name InkFootstep
extends Control
## ============================================================================
## Vệt mực "bước chân" khi nhân vật đi qua một ô (nodes/game/ink_footstep.tscn)
##
## Trước đây bàn tự dựng bằng `Control.new()` + `TextureRect.new()` — nay là
## SCENE riêng: cỡ 36×36 · con "Mark" bám kín · alpha mờ 0.45.
## Bàn chỉ việc: `footstep.setup(tâm_ô, texture_ngòi_bút, màu_mực)` rồi tween.
## ============================================================================

const SIZE := Vector2(18, 18)
const ALPHA := 0.45

@onready var mark: TextureRect = $Mark


## Đặt vệt mực tại TÂM ô `pos` với texture + màu mực của ngòi bút đang dùng
func setup(pos: Vector2, cursor_tex: Texture2D, ink: Color) -> void:
	position = pos - SIZE * 0.5
	size = SIZE
	pivot_offset = SIZE * 0.5
	if cursor_tex != null:
		mark.texture = cursor_tex
	mark.modulate = Color(ink.r, ink.g, ink.b, ALPHA)
