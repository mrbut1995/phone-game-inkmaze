class_name LevelMapNode
extends Node2D
## ============================================================================
## LevelMapNode — Một nút level trên bản đồ road map
## Hiển thị số màn, trạng thái (locked/normal/current/done/skipped) và 3 sao level
## ============================================================================

signal pressed(level_id: int)

enum State {
	LOCKED,    ## Chưa mở khoá
	NORMAL,    ## Đã mở, chưa chơi
	CURRENT,   ## Màn tiếp theo cần chơi (highlight)
	DONE,      ## Đã hoàn thành (có sao)
	SKIPPED,   ## Đã bỏ qua
}

const TEXTURE_LOCKED  := preload("res://assets/images/level_selector/level_node_locked.svg")
const TEXTURE_NORMAL  := preload("res://assets/images/level_selector/level_node_normal.svg")
const TEXTURE_CURRENT := preload("res://assets/images/level_selector/level_node_current.svg")
const TEXTURE_DONE    := preload("res://assets/images/level_selector/level_node_done.svg")
const TEXTURE_SKIPPED := preload("res://assets/images/level_selector/level_node_skipped.svg")

const STAR_HIGHLIGHT  := preload("res://assets/images/common/star_highlight.svg")
const STAR_EMPTY      := preload("res://assets/images/common/star_empty.svg")
const STAR_LOCKED     := preload("res://assets/images/common/star_locked.svg")

## Kích thước hiển thị mục tiêu (px): rộng 76, cao 94
const TARGET_WIDTH  := 76.0
const TARGET_HEIGHT := 94.0
const NODE_SIZE     := 76.0

var level_id: int = 0
var state: State = State.LOCKED

var _touch_start_pos := Vector2.ZERO
var _is_touching := false

@onready var _sprite: Sprite2D       = $Sprite2D
@onready var _label: Label           = $Label
@onready var _stars_box: HBoxContainer = $Stars
@onready var _star1: TextureRect     = $Stars/Star1
@onready var _star2: TextureRect     = $Stars/Star2
@onready var _star3: TextureRect     = $Stars/Star3
@onready var _button: Button         = $HitButton
@onready var _area: Area2D           = $TouchArea
@onready var _anim: AnimationPlayer  = $AnimationPlayer


func _ready() -> void:
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if _button != null:
		_button.pressed.connect(_on_button_pressed)
	if _area != null:
		_area.input_event.connect(_on_touch)


## Thiết lập node với dữ liệu từ LevelMap
func setup(p_level_id: int, p_state: State, stars: int = 0) -> void:
	level_id = p_level_id
	state = p_state

	# 1. Texture nền card theo trạng thái
	match state:
		State.LOCKED:
			_sprite.texture = TEXTURE_LOCKED
		State.NORMAL:
			_sprite.texture = TEXTURE_NORMAL
		State.CURRENT:
			_sprite.texture = TEXTURE_CURRENT
		State.DONE:
			_sprite.texture = TEXTURE_DONE
		State.SKIPPED:
			_sprite.texture = TEXTURE_SKIPPED

	# Đảm bảo hiển thị đúng kích thước mục tiêu 76x94 px
	if _sprite.texture != null:
		var tex_size := _sprite.texture.get_size()
		if tex_size.x > 0.0 and tex_size.y > 0.0:
			_sprite.scale = Vector2(TARGET_WIDTH / tex_size.x, TARGET_HEIGHT / tex_size.y)

	# 2. Nhãn số màn
	if state == State.LOCKED or state == State.SKIPPED:
		_label.visible = false
	else:
		_label.visible = true
		_label.text = str(level_id)

	# Màu chữ
	match state:
		State.CURRENT:
			_label.modulate = Color(0.85, 0.26, 0.26, 1.0)  # red accent
		_:
			_label.modulate = Color(0.13, 0.18, 0.23, 1.0)

	# 3. Hiển thị 3 ngôi sao level
	if state == State.LOCKED:
		# Màn khóa: ẩn hàng sao để làm nổi bật icon ổ khóa
		_stars_box.visible = false
	else:
		_stars_box.visible = true
		# Cập nhật từng ngôi sao theo số sao đạt được
		_star1.texture = STAR_HIGHLIGHT if stars >= 1 else STAR_EMPTY
		_star2.texture = STAR_HIGHLIGHT if stars >= 2 else STAR_EMPTY
		_star3.texture = STAR_HIGHLIGHT if stars >= 3 else STAR_EMPTY

	# 4. Trạng thái tương tác nút bấm
	var is_interactable := (state != State.LOCKED)
	if _button != null:
		_button.disabled = not is_interactable
	if _area != null:
		_area.input_pickable = is_interactable

	# Animation pop-in khi xuất hiện
	_play_enter_anim()

	# Pulse nhẹ cho màn CURRENT
	if state == State.CURRENT and _anim != null and _anim.has_animation(&"pulse"):
		_anim.play(&"pulse")


func _play_enter_anim() -> void:
	if _anim != null and _anim.has_animation(&"pop_in"):
		_anim.play(&"pop_in")
	else:
		scale = Vector2(0.6, 0.6)
		var tw := create_tween()
		tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(self, "scale", Vector2.ONE, 0.25)


## Bấm qua HitButton (chuột hoặc touch)
func _on_button_pressed() -> void:
	if state == State.LOCKED:
		return
	_trigger_press()


## Fallback bấm qua Area2D
func _on_touch(_viewport: Node, event: InputEvent, _shape: int) -> void:
	if state == State.LOCKED:
		return
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_is_touching = true
			_touch_start_pos = st.position
		elif _is_touching:
			_is_touching = false
			if st.position.distance_to(_touch_start_pos) < 18.0:
				_trigger_press()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_is_touching = true
				_touch_start_pos = mb.position
			elif _is_touching:
				_is_touching = false
				if mb.position.distance_to(_touch_start_pos) < 18.0:
					_trigger_press()


func _trigger_press() -> void:
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2(0.88, 0.88), 0.08)
	tw.tween_property(self, "scale", Vector2.ONE, 0.16)
	pressed.emit(level_id)
