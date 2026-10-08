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
## Nhấn giữ / rê chuột: art nút tự vẽ độ lệch (pressed chìm, hover nâng) nên số màn +
## hàng sao + ổ khoá + vòng halo được TRÔI THEO cùng độ lệch — nội dung dính vào nút.
## ============================================================================

signal pressed(level_id: int)

enum State {
	LOCKED,    ## Chưa mở khoá
	NORMAL,    ## Đã mở, chưa chơi
	CURRENT,   ## Màn tiếp theo cần chơi (highlight)
	DONE,      ## Đã hoàn thành (có sao)
	SKIPPED,   ## Đã bỏ qua
}

## Art sao — gán trong `level_node.tscn` (ExtResource; dùng bản `-png` chuẩn dự án)
@export var star_highlight: Texture2D = null
@export var star_empty: Texture2D = null

## Màu số màn theo trạng thái (màn đang chơi nhấn bằng đỏ mực, còn lại mực xanh đậm)
@export var color_number_current := Color(0.85, 0.26, 0.26, 1.0)
@export var color_number_normal := Color(0.13, 0.18, 0.23, 1.0)

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
	label.modulate = color_number_current if state == State.CURRENT else color_number_normal


## 3 sao của màn (màn khoá ẩn cả hàng sao)
func _apply_stars(stars: int) -> void:
	if stars_box == null:
		return
	stars_box.visible = state != State.LOCKED
	if not stars_box.visible:
		return
	if star1 != null:
		star1.texture = star_highlight if stars >= 1 else star_empty
	if star2 != null:
		star2.texture = star_highlight if stars >= 2 else star_empty
	if star3 != null:
		star3.texture = star_highlight if stars >= 3 else star_empty


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


# ---------------------------------------------------------------------------
# Nội dung trôi theo nút (không "float" khi nhấn / rê)
# ---------------------------------------------------------------------------
## Art nút vẽ sẵn độ lệch: pressed chìm 4px thiết kế = 2px hiển thị; hover nâng 2px
## thiết kế = 1px. Bù đúng chừng đó cho các node nội dung (số màn · hàng sao · ổ khoá ·
## vòng halo) để chúng dính chặt vào mặt nút.
@export_group("Nội dung trôi theo nút")
@export_range(0.0, 12.0, 0.5) var content_press_sink := 2.0
@export_range(-6.0, 6.0, 0.5) var content_hover_lift := -1.0
@export_range(0.01, 0.5, 0.01) var content_follow_sec := 0.08

var _button_down := false
var _button_hovered := false
var _content_base: Dictionary = {}
var _content_tween: Tween = null


## `Body/Button` phát khi trạng thái nhấn giữ đổi (dây nối khai trong .tscn)
func _on_button_press_changed(is_down: bool) -> void:
	_button_down = is_down
	_follow_button_art()


## `Body/Button` phát khi trạng thái rê chuột đổi (dây nối khai trong .tscn)
func _on_button_hover_changed(is_hovered: bool) -> void:
	_button_hovered = is_hovered
	_follow_button_art()


## Trôi các node nội dung theo đúng trạng thái hiển thị của art nút (pressed > hover > thường)
func _follow_button_art() -> void:
	var target := 0.0
	if _button_down:
		target = content_press_sink
	elif _button_hovered:
		target = content_hover_lift
	if _content_base.is_empty():
		for node in _content_nodes():
			_content_base[node] = node.get("position")
	if _content_tween != null and _content_tween.is_valid():
		_content_tween.kill()
	if not is_inside_tree():
		return
	_content_tween = create_tween().set_parallel(true)
	_content_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	for node in _content_nodes():
		var base: Vector2 = _content_base[node]
		_content_tween.tween_property(node, "position", base + Vector2(0.0, target), content_follow_sec)


## Các node là "nội dung mặt nút" (mọi thứ TRỪ art nút): halo · số · hàng sao · ổ khoá
func _content_nodes() -> Array[Node]:
	var out: Array[Node] = []
	if halo != null:
		out.append(halo)
	if label != null:
		out.append(label)
	if stars_box != null:
		out.append(stars_box)
	if lock_icon != null:
		out.append(lock_icon)
	return out
