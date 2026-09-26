class_name LevelCard
extends Control
## ============================================================================
## Component: Thẻ chọn màn chơi (Level Card)
## Quản lý trạng thái Khóa / Mở / Đã hoàn thành và số sao đánh giá (0-3 sao).
## ============================================================================

signal selected(level_id: int)

const STAR_FULL := preload("res://assets/images/common/star_highlight.svg")
const STAR_EMPTY := preload("res://assets/images/common/star_empty.svg")
const UIAnim := preload("res://scripts/utils/ui_anim.gd")

@export var level_id: int = 1
@export var is_locked: bool = false
@export var rating: int = 0
@export var is_done: bool = false
## Chương của màn (hiện trên thẻ kiểu "1-3") + vị trí trong chương
@export var chapter: int = 1
@export var index_in_chapter: int = 0

@export var panel_btn: NinePatchButton 
@export var level_lbl: Label 
@export var lock_icon: TextureRect 
@export var stamp_done: TextureRect 

@export var star1: TextureRect
@export var star2: TextureRect 
@export var star3: TextureRect 


func _ready() -> void:
	if panel_btn != null:
		panel_btn.pressed.connect(_on_pressed)
		if not is_locked:
			UIAnim.attach_press_bounce(panel_btn)
	update_visuals()


func setup(p_level_id: int, p_is_locked: bool, p_rating: int, p_is_done: bool,
		p_chapter: int = 1, p_index_in_chapter: int = 0) -> void:
	level_id = p_level_id
	is_locked = p_is_locked
	rating = p_rating
	is_done = p_is_done
	chapter = maxi(p_chapter, 1)
	index_in_chapter = p_index_in_chapter
	update_visuals()


func update_visuals() -> void:
	if level_lbl != null:
		# Màn đánh số theo chương (1-1, 1-2...) - nhiều hơn 9 màn vẫn hiện đúng
		var shown := index_in_chapter if index_in_chapter > 0 else level_id
		level_lbl.text = "%d-%d" % [maxi(chapter, 1), shown]
		level_lbl.visible = not is_locked

	if lock_icon != null:
		lock_icon.visible = is_locked

	if panel_btn != null:
		panel_btn.disabled = is_locked

	if stamp_done != null:
		stamp_done.visible = is_done

	# Cập nhật số sao
	if star1 != null:
		star1.texture = STAR_FULL if rating >= 1 else STAR_EMPTY
		star1.visible = not is_locked
	if star2 != null:
		star2.texture = STAR_FULL if rating >= 2 else STAR_EMPTY
		star2.visible = not is_locked
	if star3 != null:
		star3.texture = STAR_FULL if rating >= 3 else STAR_EMPTY
		star3.visible = not is_locked


func _on_pressed() -> void:
	if not is_locked:
		# SFX: bấm bút bi khi chọn màn chơi
		Sfx.play(Sfx.BTN_CLICK)
		selected.emit(level_id)
