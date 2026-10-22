class_name WinningLevelPopup
extends BasePopup
## ============================================================================
## Popup: THẮNG MÀN ở chế độ màn chơi (nodes/popups/winning_level.tscn)
## Bố cục (cùng ngôn ngữ với Game Over / Qua tầng):
##   1. 3 sao lớn (sao đạt nảy lên lần lượt) + "MÀN n"
##   2. 3 thẻ nhiệm vụ (sao đạt / chưa đạt + tên ngắn)
##   3. Thẻ 3 cột: Thời gian · Bước · Đâm tường
##   4. Nút: Chơi lại · Màn kế tiếp (hoặc "Chọn chương" khi hết chương)
##
## Dữ liệu (GameController._complete_floor): level|floor, stars, missions: [{title, done, status}],
##   time, steps_used, steps_max, wall_hits, next_available
## Signal giữ tên cũ để UIController nối như trước:
##   next_requested -> _emit_continue      replay_requested -> _emit_retry
##
## Popup thắng cũ (winning.tscn / WinningPopup) KHÔNG bị đụng tới — winning_daily vẫn dùng nó.
## ============================================================================

signal next_requested
signal replay_requested

const COUNT := 3
const COLOR_DONE := Color(0.69, 0.478, 0.039, 1)
const COLOR_FAIL := Color(0.478, 0.529, 0.58, 1)
const STAR_DELAY := 0.25
const STAR_STEP := 0.22

## Art sao — gán trong `winning_level.tscn` (ExtResource)
@export var star_full: Texture2D = null
@export var star_empty: Texture2D = null

## Node binding: khai `node_paths` + `NodePath` trong `winning_level.tscn`
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
	var level := maxi(int(data.get("level", data.get("floor", 1))), 1)
	label_level.text = tr("STR_WL_LEVEL").format([level])

	# --- Sao lớn: sao đạt nảy lên lần lượt ---------------------------------
	var earned := clampi(int(data.get("stars", 0)), 0, COUNT)
	var heroes: Array[TextureRect] = [hero1, hero2, hero3]
	for i in COUNT:
		var h := heroes[i]
		var on := i < earned
		h.texture = star_full if on else star_empty
		h.pivot_offset = h.size * 0.5
		if on:
			h.scale = Vector2(0.4, 0.4)
			h.modulate.a = 0.0
			_pop_star(h, STAR_DELAY + STAR_STEP * float(i))

	# --- 3 thẻ nhiệm vụ ------------------------------------------------------
	var rows: Array = data.get("missions", [])
	var stars: Array[TextureRect] = [m1_star, m2_star, m3_star]
	var names: Array[Label] = [m1_name, m2_name, m3_name]
	for i in COUNT:
		var row: Dictionary = rows[i] if i < rows.size() else {}
		var ok := bool(row.get("done", false))
		stars[i].texture = star_full if ok else star_empty
		if row.has("title"):
			names[i].text = str(row.get("title"))
		names[i].add_theme_color_override(&"font_color", COLOR_DONE if ok else COLOR_FAIL)

	# --- Số liệu -------------------------------------------------------------
	var secs := maxi(int(round(float(data.get("time", 0.0)))), 0)
	value_time.text = "%02d:%02d" % [secs / 60, secs % 60]
	value_steps.text = "%d/%d" % [int(data.get("steps_used", 0)), int(data.get("steps_max", 0))]
	value_walls.text = str(int(data.get("wall_hits", 0)))

	# --- Nút chính: hết chương (hoặc chương sau chưa mở) -> "CHỌN CHƯƠNG" ------
	label_next.text = tr("STR_WL_NEXT") if bool(data.get("next_available", true)) else tr("STR_WL_CHAPTERS")


func _pop_star(star: TextureRect, delay: float) -> void:
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.tween_callback(func() -> void:
		star.modulate.a = 1.0
		Sfx.play(Sfx.LEVEL_WIN))
	tw.tween_property(star, "scale", Vector2(1.15, 1.15), 0.18) \
		.from(Vector2(0.4, 0.4)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(star, "scale", Vector2.ONE, 0.12)


func _on_next_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	next_requested.emit()
	close()


func _on_replay_pressed() -> void:
	Sfx.play(Sfx.BTN_WOOD_TAP)
	replay_requested.emit()
	close()
