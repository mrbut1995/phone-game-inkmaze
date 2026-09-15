class_name WinningPopup
extends BasePopup
## ============================================================================
## Popup: Kết quả màn chơi (nodes/popups/winning.tscn) - mockup popup_win_level.svg
## Dữ liệu nhận qua open({ level, grid, time, steps_used, steps_max, wall_hits, score, stars })
## ============================================================================

signal replay_requested
signal next_requested

const STAR_FULL := preload("res://assets/images/common/star_highlight.svg")
const STAR_EMPTY := preload("res://assets/images/common/star_empty.svg")

@onready var stars_row: Control = piece("Stars")
@onready var label_subtitle: Label = piece("Subtitle")
@onready var value_time: Label = piece("StatValue1")
@onready var value_steps: Label = piece("StatValue2")
@onready var value_walls: Label = piece("StatValue3")
@onready var value_score: Label = piece("TotalValue")


func _on_open() -> void:
	if data.is_empty():
		return
	label_subtitle.text = tr("STR_RESULT_SUBTITLE").format([
		int(data.get("level", 1)),
		str(data.get("grid", "5×5")),
	])

	var seconds := float(data.get("time", 0.0))
	value_time.text = "%02d:%02ds" % [int(seconds) / 60, int(seconds) % 60]

	var used := int(data.get("steps_used", 0))
	var max_steps := int(data.get("steps_max", 0))
	value_steps.text = tr("STR_STEPS_LEFT_FORMAT").format([used, max_steps, maxi(max_steps - used, 0)])

	var hits := int(data.get("wall_hits", 0))
	value_walls.text = tr("STR_WALL_HITS_FORMAT").format([hits, tr("STR_PERFECT_TAG")]) if hits == 0 \
		else tr("STR_WALL_HITS_FORMAT").format([hits, ""]).strip_edges()
	value_walls.theme_type_variation = &"PopupStatValueGood" if hits == 0 else &"PopupStatValueBad"

	value_score.text = tr("STR_SCORE_FORMAT").format([_thousands(int(data.get("score", 0)))])

	_set_stars(int(data.get("stars", 0)))
	bind_button("Panel/Content/ReplayBtn", _on_replay_pressed)
	bind_button("Panel/Content/NextBtn", _on_next_pressed)


## 2850 -> "2,850" cho khớp mockup
static func _thousands(value: int) -> String:
	var digits := str(absi(value))
	var out := ""
	var count := 0
	for i in range(digits.length() - 1, -1, -1):
		out = digits[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return ("-" if value < 0 else "") + out


## Tô sáng số sao đạt được và phóng nhẹ từng ngôi sao theo nhịp
func _set_stars(stars: int) -> void:
	if stars_row == null:
		return
	var children := stars_row.get_children()
	for i in children.size():
		var star := children[i] as TextureRect
		if star == null:
			continue
		var earned := i < stars
		star.texture = STAR_FULL if earned else STAR_EMPTY
		star.modulate = Color(1, 1, 1, 1) if earned else Color(1, 1, 1, 0.75)
		if not earned:
			continue
		star.pivot_offset = star.size * 0.5
		star.scale = Vector2.ONE * 0.4
		var tw := create_tween()
		tw.tween_interval(0.25 + i * 0.22)
		tw.tween_property(star, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func() -> void: Sfx.play(Sfx.STAR_POP))


func _on_replay_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	replay_requested.emit()
	close()


func _on_next_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	next_requested.emit()
	close()
