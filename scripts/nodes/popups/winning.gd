class_name WinningPopup
extends BasePopup
## ============================================================================
## Popup: Kết quả màn chơi (nodes/popups/winning.tscn)
## Bố cục (cùng ngôn ngữ với Game Over / Qua tầng):
##   1. 3 sao lớn (sao đạt nảy lên lần lượt) + "MÀN n"
##   2. 3 thẻ nhiệm vụ (sao đạt / chưa đạt + tên ngắn)
##   3. Thẻ 3 cột: Thời gian · Bước · Đâm tường
##   4. Nút: Chơi lại · Màn kế tiếp (hoặc "Chọn chương" khi hết chương)
##
## Dữ liệu: open({ level, time, steps_used, steps_max, wall_hits, stars,
##                 missions: [{title, done, status}], next_available })
## `WinningChallengePopup` kế thừa popup này (cùng bố cục, đổi tiêu đề + nút "TRỞ VỀ").
## Popup Daily (winning_daily) là scene riêng, KHÔNG dùng lớp này.
## ============================================================================

signal replay_requested
signal next_requested

const COUNT := 3
const COLOR_DONE := Color(0.69, 0.478, 0.039, 1)
const COLOR_FAIL := Color(0.478, 0.529, 0.58, 1)
const STAR_DELAY := 0.25
const STAR_STEP := 0.22

## Art sao — gán trong `winning.tscn` + `winning_challenge.tscn` (ExtResource)
@export var star_full: Texture2D = null
@export var star_empty: Texture2D = null

## Node binding: khai `node_paths` + `NodePath` trong `winning.tscn` / `winning_challenge.tscn`
@export var label_level: Label = null
@export var hero1: TextureRect = null
@export var hero2: TextureRect = null
@export var hero3: TextureRect = null
@export var m1_star: TextureRect = null
@export var m1_name: Label = null
@export var m2_star: TextureRect = null
@export var m2_name: Label = null
@export var m3_star: TextureRect = null
@export var m3_name: Label = null
@export var value_time: Label = null
@export var value_steps: Label = null
@export var value_walls: Label = null
@export var label_next: Label = null


func _on_open() -> void:
	if data.is_empty():
		return
	var level := maxi(int(data.get("level", data.get("floor", 1))), 1)
	label_level.text = tr("STR_WL_LEVEL").format([level])

	_set_stars(int(data.get("stars", 0)))
	_fill_missions(data.get("missions", []))

	var secs := maxi(int(round(float(data.get("time", 0.0)))), 0)
	value_time.text = "%02d:%02d" % [secs / 60, secs % 60]
	value_steps.text = "%d/%d" % [int(data.get("steps_used", 0)), int(data.get("steps_max", 0))]
	value_walls.text = str(int(data.get("wall_hits", 0)))

	# Hết chương (hoặc chương kế chưa mở) -> nút đổi thành "CHỌN CHƯƠNG"
	label_next.text = TranslationServer.translate(
		"STR_BTN_NEXT_LEVEL" if bool(data.get("next_available", true))
		else "STR_CHAPTER_SCREEN_TITLE")


## Sao lớn: sao đạt nảy lên lần lượt, mỗi lần có tiếng pop + chuông cao dần
func _set_stars(earned_stars: int) -> void:
	var earned := clampi(earned_stars, 0, COUNT)
	var heroes: Array[TextureRect] = [hero1, hero2, hero3]
	for i in COUNT:
		var h := heroes[i]
		var on := i < earned
		h.texture = star_full if on else star_empty
		h.modulate = Color(1, 1, 1, 1) if on else Color(1, 1, 1, 0.75)
		h.pivot_offset = h.size * 0.5
		if on:
			h.scale = Vector2.ONE * 0.4
			h.modulate.a = 0.0
			_pop_star(h, i)


func _pop_star(star: TextureRect, index: int) -> void:
	var tw := create_tween()
	tw.tween_interval(STAR_DELAY + STAR_STEP * float(index))
	tw.tween_callback(func() -> void:
		star.modulate.a = 1.0
		_star_pop(index))
	tw.tween_property(star, "scale", Vector2(1.15, 1.15), 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(star, "scale", Vector2.ONE, 0.12)


## 3 thẻ nhiệm vụ: sao đạt (vàng) / chưa đạt (xám) + tên
func _fill_missions(missions: Variant) -> void:
	var rows: Array = missions if missions is Array else []
	var stars: Array[TextureRect] = [m1_star, m2_star, m3_star]
	var names: Array[Label] = [m1_name, m2_name, m3_name]
	for i in COUNT:
		var row: Dictionary = rows[i] if i < rows.size() and rows[i] is Dictionary else {}
		var ok := bool(row.get("done", false))
		stars[i].texture = star_full if ok else star_empty
		if row.has("title"):
			names[i].text = str(row.get("title"))
		names[i].add_theme_color_override(&"font_color", COLOR_DONE if ok else COLOR_FAIL)


## Tiếng "pop" + chuông cao dần mỗi khi một ngôi sao nảy lên
func _star_pop(index: int) -> void:
	Sfx.play(Sfx.STAR_POP)
	Sfx.star_pop(index)


func _on_replay_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	replay_requested.emit()
	close()


func _on_next_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	next_requested.emit()
	close()
