class_name WinningPopup
extends BasePopup
## ============================================================================
## Popup: Kết quả màn chơi (nodes/popups/winning.tscn) - mockup popup_win_level.svg
## Dữ liệu nhận qua open({ level, grid, time, steps_used, steps_max, wall_hits, score, stars })
## ============================================================================

signal replay_requested
signal next_requested

const STAR_FULL := preload("res://assets/images-png/common/star_highlight.png")
const STAR_EMPTY := preload("res://assets/images-png/common/star_empty.png")

## Node binding: khai `node_paths` + `NodePath` trong `winning.tscn` (xem `chapters_layout`)
@export var stars_row: Control = null
@export var label_subtitle: Label = null
@export var label_next: Label = null
@export var value_time: Label = null
@export var value_steps: Label = null
@export var value_walls: Label = null
@export var value_score: Label = null
@export var stamp_title: Label = null
@export var stamp_sub: Label = null
## Hiệu ứng riêng của popup (animation "stars") — node tên `FxAnim` vì popup đã có sẵn
## `AnimationPlayer` của base.tscn (hiệu ứng mở/đóng) — không được trùng tên.
@export var fx_anim: AnimationPlayer = null


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

	var target_score := int(data.get("score", 0))
	if DisplayServer.get_name() != "headless" and target_score > 0:
		value_score.text = tr("STR_SCORE_FORMAT").format([0])
		# (GIỮ tween) Đếm số = NỘI SUY DỮ LIỆU (điểm lúc chạy) + format text mỗi khung hình
		var tw_s := create_tween()
		tw_s.tween_method(func(v: float) -> void:
			if is_instance_valid(value_score):
				value_score.text = tr("STR_SCORE_FORMAT").format([_thousands(int(round(v)))])
		, 0.0, float(target_score), 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		value_score.text = tr("STR_SCORE_FORMAT").format([_thousands(target_score)])

	_set_stars(int(data.get("stars", 0)))
	_fill_stamp(int(data.get("stars", 0)), data.get("missions", null))
	# Dây 2 nút (Chơi lại / Màn kế) khai trong `winning.tscn` (cùng scene)
	# Hết chương (hoặc chương kế chưa mở) -> nút đổi thành "CHỌN CHƯƠNG" (bấm ra màn Chọn Chương)
	label_next.text = TranslationServer.translate(
		"STR_BTN_NEXT_LEVEL" if bool(data.get("next_available", true))
		else "STR_CHAPTER_SCREEN_TITLE")


## Con dấu đỏ ở góc phải: "n / m NHIỆM VỤ" + "★ ĐẠT n SAO ★" (mockup popup_win_level.svg)
func _fill_stamp(stars: int, missions: Variant) -> void:
	var done := 0
	var total := 0
	var rows: Array = []
	if missions is Array:
		rows = missions as Array
	for row in rows:
		total += 1
		if row is Dictionary and bool((row as Dictionary).get("done", false)):
			done += 1
	stamp_title.text = tr("STR_WIN_STAMP_TITLE").format([done, total])
	stamp_sub.text = tr("STR_WIN_STAMP_SUB").format([stars])


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


## Tô sáng số sao đạt được và phóng nhẹ từng ngôi sao theo nhịp (animation "stars" trong scene)
func _set_stars(stars: int) -> void:
	if stars_row == null:
		return
	var children := stars_row.get_children()
	var earned_count := 0
	for i in children.size():
		var star := children[i] as TextureRect
		if star == null:
			continue
		var earned := i < stars
		star.texture = STAR_FULL if earned else STAR_EMPTY
		star.modulate = Color(1, 1, 1, 1) if earned else Color(1, 1, 1, 0.75)
		if not earned:
			continue
		earned_count += 1
		star.pivot_offset = star.size * 0.5
		star.scale = Vector2.ONE * 0.4
	if earned_count == 0:
		return
	# Chỉ BẬT track của sao ĐẠT được: track 0/1/2 = Star1/2/3 (scale), track 3/4/5 = tiếng "pop"
	var anim := fx_anim.get_animation(&"stars") if fx_anim != null else null
	if anim == null:
		# Fallback khi scene thiếu FxAnim/animation
		for i in earned_count:
			var star_fb := children[i] as TextureRect
			if star_fb == null:
				continue
			var tw := create_tween()
			tw.tween_interval(0.25 + i * 0.22)
			tw.tween_property(star_fb, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_callback(_star_pop)
		return
	for t in anim.get_track_count():
		anim.track_set_enabled(t, (t % 3) < earned_count)
	fx_anim.play(&"stars")


## Tiếng "pop" mỗi lần một ngôi sao nảy lên — gọi từ method track của animation "stars"
func _star_pop() -> void:
	Sfx.play(Sfx.STAR_POP)


## Tiếng "chuông" cao dần khi 3 sao hiện — 3 Timer autostart khai trong `winning.tscn`
## (mỗi dây `[connection]` bind sẵn chỉ số sao qua `binds`)
func _on_star_tone(index: int) -> void:
	Sfx.star_pop(index)


func _on_replay_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	replay_requested.emit()
	close()


func _on_next_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	next_requested.emit()
	close()
