class_name LevelCard
extends Control
## ============================================================================
## Component: Thẻ chọn màn chơi (Level Card)
## Quản lý trạng thái Khóa / Mở / Đã hoàn thành và số sao đánh giá (0-3 sao).
##
## HAI SCENE THEO HƯỚNG (cùng script này):
##   · `nodes/level_selection/level_card.tscn`           → bản DỌC (thẻ đứng 290x350, lưới 3x3 phủ kín)
##   · `nodes/level_selection/level_card_landscape.tscn` → bản NGANG (thẻ 360x265 như mockup
##     `mockup/level_selection_landscape.svg`): thêm trạng thái **MÀN TIẾP** (viền cam + hào quang
##     nét đứt + ruy băng NEW + nhãn/màu cam) và **sao xám** cho thẻ KHÓA.
##     Scene dọc KHÔNG bind các node/art đó ⇒ giữ nguyên như trước.
## ============================================================================

signal selected(level_id: int)

const STAR_FULL := preload("res://assets/images-png/common/star_highlight.png")
const STAR_EMPTY := preload("res://assets/images-png/common/star_empty.png")
const UIAnim := preload("res://scripts/utils/ui_anim.gd")
## Màu nhấn của thẻ "MÀN TIẾP" (mockup bản ngang: viền cam #C4843A)
const NEXT_COLOR := Color(0.76862746, 0.51764709, 0.22745098, 1)

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

## --- Trạng thái "MÀN TIẾP" + thẻ khóa bản NGANG (chỉ scene ngang bind) ---------------------
## Art thẻ cho trạng thái "MÀN TIẾP" (viền cam) — khai trong `level_card_landscape.tscn`
@export var next_card_normal: Texture2D = null
@export var next_card_pressed: Texture2D = null
## Hào quang nét đứt + ruy băng NEW quanh thẻ (chỉ có ở scene NGANG)
@export var next_halo: Control = null
@export var next_ribbon: Control = null
## Nhãn nhỏ trên thẻ ("MÀN") — đổi thành "MÀN TIẾP" khi là thẻ nổi bật
@export var prefix_lbl: Label = null
## Vạch kẻ giữa thẻ + art nét đứt CAM của thẻ "MÀN TIẾP" (2 hướng đều có)
@export var seperator: Control = null
@export var next_seperator: Texture2D = null
## Art sao XÁM cho thẻ KHÓA: có thì thẻ khóa hiện 3 sao xám thay vì ẩn hết
@export var locked_star_art: Texture2D = null

## Có phải thẻ "MÀN TIẾP" (thẻ nổi bật của mockup bản ngang) không
var is_next := false

## Art gốc của nút (lấy lúc `_ready` để trả lại khi KHÔNG phải thẻ "MÀN TIẾP")
var _base_tex_normal: Texture2D = null
var _base_tex_pressed: Texture2D = null
var _base_tex_seperator: Texture2D = null


func _ready() -> void:
	if panel_btn != null:
		_base_tex_normal = panel_btn.texture_normal
		_base_tex_pressed = panel_btn.texture_pressed
	if seperator != null:
		_base_tex_seperator = seperator.get("texture") as Texture2D
	# Dây `Panel.pressed → _on_pressed` khai trong `.tscn` (cùng scene)
	if panel_btn != null and not is_locked:
		UIAnim.attach_press_bounce(panel_btn)
	update_visuals()


func setup(p_level_id: int, p_is_locked: bool, p_rating: int, p_is_done: bool,
		p_chapter: int = 1, p_index_in_chapter: int = 0, p_is_next: bool = false) -> void:
	level_id = p_level_id
	is_locked = p_is_locked
	rating = p_rating
	is_done = p_is_done
	chapter = maxi(p_chapter, 1)
	index_in_chapter = p_index_in_chapter
	is_next = p_is_next
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

	# Cập nhật số sao. Thẻ KHÓA: scene nào khai `locked_star_art` thì hiện 3 sao XÁM,
	# không khai (bản dọc) thì ẩn hết như trước.
	var locked_art: Texture2D = locked_star_art if is_locked else null
	var stars: Array[TextureRect] = [star1, star2, star3]
	for i in stars.size():
		var star := stars[i]
		if star == null:
			continue
		star.visible = not is_locked or locked_art != null
		if locked_art != null:
			star.texture = locked_art
		else:
			star.texture = STAR_FULL if rating >= i + 1 else STAR_EMPTY

	# Thẻ "MÀN TIẾP" (chỉ khi scene có hào quang/ruy băng ⇒ bản ngang):
	# art viền cam + hào quang + ruy băng NEW + nhãn/màu cam.
	var show_next := is_next and not is_locked and (next_halo != null or next_ribbon != null)
	if prefix_lbl != null:
		prefix_lbl.text = tr("STR_LEVEL_NEXT") if show_next else tr("STR_LEVEL_PREFIX")
	if next_halo != null:
		next_halo.visible = show_next
	if next_ribbon != null:
		next_ribbon.visible = show_next
	if panel_btn != null and next_card_normal != null:
		panel_btn.texture_normal = next_card_normal if show_next else _base_tex_normal
		panel_btn.texture_hover = next_card_normal if show_next else _base_tex_normal
		var pressed_art: Texture2D = next_card_pressed if next_card_pressed != null else next_card_normal
		panel_btn.texture_pressed = pressed_art if show_next else _base_tex_pressed
	# Vạch kẻ giữa thẻ: nét đứt CAM khi là thẻ "MÀN TIẾP"
	if seperator != null and next_seperator != null:
		seperator.set("texture", next_seperator if show_next else _base_tex_seperator)
	if prefix_lbl != null:
		if show_next:
			prefix_lbl.add_theme_color_override("font_color", NEXT_COLOR)
		else:
			prefix_lbl.remove_theme_color_override("font_color")
	if level_lbl != null:
		if show_next:
			level_lbl.add_theme_color_override("font_color", NEXT_COLOR)
		else:
			level_lbl.remove_theme_color_override("font_color")


func _on_pressed() -> void:
	if not is_locked:
		# SFX: bấm bút bi khi chọn màn chơi
		Sfx.play(Sfx.BTN_CLICK)
		selected.emit(level_id)
