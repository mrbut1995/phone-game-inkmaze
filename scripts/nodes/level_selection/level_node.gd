class_name LevelMapNode
extends Node2D
## ============================================================================
## LevelMapNode — Một nút màn chơi trên bản đồ (road map)
## Nút là một KHỐI GIẤY NỔI dùng `TextureButton2D` (art 4 trạng thái: thường · rê ·
## nhấn · khoá) nên bấm có cảm giác; số màn + 3 sao là node con nằm trong nút.
##
## Quy ước của project: CẤU HÌNH TĨNH nằm trong `level_node.tscn` — node con, texture
## theo trạng thái, animation (`pop_in` · `pulse` · `press`) và dây signal
## (`Button.pressed`, `AnimationPlayer.animation_finished`) đều khai trong scene;
## script chỉ bind bằng `@export` rồi nhận dữ liệu qua `setup()`.
##
## Trạng thái (đổi qua `setup`):
##   LOCKED  → `Button.disabled = true` (art xám) + hiện ổ khoá, ẩn số/sao
##   CURRENT → hiện vòng `Halo` nét đứt đỏ + "thở" (`pulse`)
##   DONE    → hiện số + sao đã đạt
##   SKIPPED → ẩn số (chỉ còn sao trống) để nhấc người chơi quay lại
##   NORMAL  → nút thường
## ============================================================================

signal pressed(level_id: int)

enum State {
	LOCKED,    ## Chưa mở khoá
	NORMAL,    ## Đã mở, chưa chơi
	CURRENT,   ## Màn tiếp theo cần chơi (highlight)
	DONE,      ## Đã hoàn thành (có sao)
	SKIPPED,   ## Đã bỏ qua
}

const STAR_HIGHLIGHT := preload("res://assets/images/common/star_highlight.svg")
const STAR_EMPTY     := preload("res://assets/images/common/star_empty.svg")

## Màu số màn theo trạng thái (màn đang chơi nhấn bằng đỏ mực, còn lại mực xanh đậm)
const COLOR_NUMBER_CURRENT := Color(0.85, 0.26, 0.26, 1.0)
const COLOR_NUMBER_NORMAL  := Color(0.13, 0.18, 0.23, 1.0)
## Art vẽ ở 2× (224px) nên node vẽ ở scale 0.5 ⇒ nút hiển thị 112px (lòng nút 96px)
const ART_SCALE := Vector2(0.5, 0.5)

## Node con — bind bằng `@export` trong `level_node.tscn`
@export var button: TextureButton2D = null
@export var halo: Sprite2D = null
@export var label: Label = null
@export var stars_box: HBoxContainer = null
@export var star1: TextureRect = null
@export var star2: TextureRect = null
@export var star3: TextureRect = null
@export var lock_icon: Sprite2D = null
@export var anim: AnimationPlayer = null

var level_id: int = 0
var state: State = State.LOCKED


## Thiết lập node với dữ liệu từ LevelMap
func setup(p_level_id: int, p_state: State, stars: int = 0) -> void:
	level_id = p_level_id
	state = p_state
	_apply_state_look()
	_apply_number()
	_apply_stars(stars)
	_play_enter_anim()
	if state == State.CURRENT:
		play_pulse()


## Dáng nút theo trạng thái: khoá thì tắt tương tác + hiện ổ khoá; màn đang chơi có vòng sáng
func _apply_state_look() -> void:
	if button != null:
		button.disabled = state == State.LOCKED
	if halo != null:
		halo.visible = state == State.CURRENT
	if lock_icon != null:
		lock_icon.visible = state == State.LOCKED


## Số màn (màn khoá / đã bỏ qua thì ẩn số)
func _apply_number() -> void:
	if label == null:
		return
	var show_number := state != State.LOCKED and state != State.SKIPPED
	label.visible = show_number
	if show_number:
		label.text = str(level_id)
	label.modulate = COLOR_NUMBER_CURRENT if state == State.CURRENT else COLOR_NUMBER_NORMAL


## 3 sao của màn (màn khoá ẩn cả hàng sao)
func _apply_stars(stars: int) -> void:
	if stars_box == null:
		return
	stars_box.visible = state != State.LOCKED
	if not stars_box.visible:
		return
	if star1 != null:
		star1.texture = STAR_HIGHLIGHT if stars >= 1 else STAR_EMPTY
	if star2 != null:
		star2.texture = STAR_HIGHLIGHT if stars >= 2 else STAR_EMPTY
	if star3 != null:
		star3.texture = STAR_HIGHLIGHT if stars >= 3 else STAR_EMPTY


## "Thở" cho màn tiếp theo (animation `pulse` khai trong .tscn)
func play_pulse() -> void:
	if anim != null and anim.has_animation(&"pulse"):
		anim.play(&"pulse")


func _play_enter_anim() -> void:
	if anim != null and anim.has_animation(&"pop_in"):
		anim.play(&"pop_in")


## Nút phát `pressed` (dây nối khai trong .tscn) — màn khoá đã bị `disabled` chặn
func _on_button_pressed() -> void:
	if state == State.LOCKED:
		return
	pressed.emit(level_id)
	if anim != null and anim.has_animation(&"press"):
		anim.play(&"press")


## Hết animation bấm thì trả lại hiệu ứng "thở" cho màn đang chơi
func _on_anim_finished(anim_name: StringName) -> void:
	if anim_name == &"press" and state == State.CURRENT:
		play_pulse()
