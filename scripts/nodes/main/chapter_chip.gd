class_name ChapterChip
extends Control
## ============================================================================
## Node: ChapterChip — chip nhỏ "‹ CHƯƠNG 2 ›" nằm giữa-trên bản đồ màn Main
## (nodes/main/chapter_chip.tscn). Thay cho hàng TAB chương của màn Levels cũ.
##
## · Bấm ‹ / › ⇒ phát `prev_requested` / `next_requested`; LevelSection quyết định đổi chương
##   (chương khoá ⇒ mở khung "chương đang khoá").
## · Mũi tên bị mờ khi không còn chương ở phía đó.
## · `hint_next` = chương đã xong ⇒ mũi tên › nhún nhẹ (animation `next_hint` trong scene).
## Script chỉ chọn animation + đổ dữ liệu (hiệu ứng nằm trong scene).
## ============================================================================

signal prev_requested
signal next_requested

@export var lbl_title: Label = null
@export var btn_prev: BaseButton = null
@export var btn_next: BaseButton = null
@export var anim: AnimationPlayer = null
## Độ mờ của mũi tên khi không bấm được
@export_range(0.0, 1.0, 0.05) var disabled_alpha := 0.3


## `chapter_id` hiện ở nhãn · `has_prev/has_next` = còn chương hai bên · `hint_next` = gợi ý sang chương tiếp
func setup(chapter_id: int, has_prev: bool, has_next: bool, hint_next := false) -> void:
	if lbl_title != null:
		lbl_title.text = tr("STR_MAIN_CHAPTER_CHIP").format([chapter_id])
	_set_arrow(btn_prev, has_prev)
	_set_arrow(btn_next, has_next)
	_update_hint(hint_next and has_next)


func _set_arrow(button: BaseButton, enabled: bool) -> void:
	if button == null:
		return
	button.disabled = not enabled
	button.modulate.a = 1.0 if enabled else disabled_alpha


func _update_hint(on: bool) -> void:
	if anim == null or not anim.has_animation(&"next_hint"):
		return
	if on:
		if anim.current_animation != &"next_hint":
			anim.play(&"next_hint")
	elif anim.is_playing():
		anim.stop()
		if anim.has_animation(&"RESET"):
			anim.play(&"RESET")
			anim.advance(0.0)


func _on_prev_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	prev_requested.emit()


func _on_next_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	next_requested.emit()
