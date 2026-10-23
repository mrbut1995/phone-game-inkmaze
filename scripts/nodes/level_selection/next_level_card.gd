class_name NextLevelCard
extends Control
## ============================================================================
## Component: THẺ CHÂN MÀN "MÀN TIẾP THEO" (nodes/level_selection/next_level_card.tscn)
##
## Thay nút "TIẾP TỤC MÀN n" cũ ở bản DỌC: ô số màn (vàng) · tiêu đề · 3 sao đã đạt của
## màn đó · nút CHƠI (xanh 3D).
##
## Khi chương đã xong (`chapter_cleared()`), thẻ đổi sang "HOÀN THÀNH CHƯƠNG" và nút thành
## "CHƯƠNG TIẾP ›" (ẩn nếu không còn chương nào để sang).
##
## Widget CHỈ hiển thị + phát signal; màn Chọn màn quyết định vào màn hay đổi chương.
## Hoạt ảnh `PulseAnim/pulse` (khai trong scene) làm nút CHƠI "thở".
## ============================================================================

## Bấm CHƠI (màn Chọn màn giữ logic `_on_continue_pressed()` cũ)
signal play_requested
## Chương đã xong + còn chương kế ⇒ bấm "CHƯƠNG TIẾP ›"
signal next_chapter_requested

@export_group("Node binding")
@export var badge_label: Label = null
@export var title_label: Label = null
@export var level_label: Label = null
## 3 icon Sao của màn tiếp theo (khai riêng từng node để bind chắc chắn trong .tscn)
@export var star_1: TextureRect = null
@export var star_2: TextureRect = null
@export var star_3: TextureRect = null
@export var star_full: Texture2D = null
@export var star_empty: Texture2D = null
@export var btn_play: BaseButton = null
@export var lbl_play: Label = null
@export var pulse_anim: AnimationPlayer = null

var level_id: int = 0
var cleared := false

var _stars_earned := 0
var _has_next := true


func _ready() -> void:
	_connect_locale_signal()


## Đổi ngôn ngữ (hoặc bảng dịch nạp XONG sau `_ready` của màn) ⇒ viết lại 3 nhãn.
## Cần thiết vì màn có thể `_ready()` trước khi `LocalizationManager` nạp xong bảng dịch.
func _connect_locale_signal() -> void:
	var loc: Node = get_node_or_null("/root/LocalizationManager")
	if loc != null and loc.has_signal("locale_changed") \
			and not loc.is_connected("locale_changed", _on_locale_changed):
		loc.connect("locale_changed", _on_locale_changed)


func _on_locale_changed(_locale: String) -> void:
	_apply_texts()


## `stars_earned` = số Sao đã đạt của màn tiếp theo (0..3)
func setup(p_level_id: int, stars_earned: int, p_cleared: bool, p_has_next: bool) -> void:
	level_id = p_level_id
	cleared = p_cleared
	_stars_earned = stars_earned
	_has_next = p_has_next
	if badge_label != null:
		badge_label.text = str(level_id)
	_apply_texts()
	var star_list: Array[TextureRect] = [star_1, star_2, star_3]
	for i in star_list.size():
		var star := star_list[i]
		if star == null:
			continue
		var filled := i < stars_earned
		star.texture = star_full if filled else star_empty
		star.visible = not cleared
	if btn_play != null:
		btn_play.visible = not cleared or _has_next
	_update_pulse()


## Viết lại 3 nhãn theo ngôn ngữ hiện tại
func _apply_texts() -> void:
	if title_label != null:
		title_label.text = tr("STR_CHAPTER_DONE_TITLE") if cleared else tr("STR_LEVEL_NEXT_CARD_TITLE")
	if level_label != null:
		level_label.text = tr("STR_LEVEL_TITLE_FORMAT").format([level_id])
		level_label.visible = not cleared
	if lbl_play != null:
		lbl_play.text = tr("STR_CHAPTER_GO_NEXT") if cleared else tr("STR_LEVEL_PLAY")


## Nút CHƠI "thở" (giữ tên player/animation cũ để `UIAnim.play_layout_anim` chạy được)
func _update_pulse() -> void:
	if pulse_anim == null or btn_play == null:
		return
	if not cleared:
		if pulse_anim.has_animation(&"pulse") and not pulse_anim.is_playing():
			pulse_anim.play(&"pulse")
	elif pulse_anim.is_playing():
		pulse_anim.stop()


func _on_play_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	if cleared:
		next_chapter_requested.emit()
	else:
		play_requested.emit()
