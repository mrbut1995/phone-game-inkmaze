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
## Hiệu ứng mở (≈2s, chỉ dùng tween + 1 CPUParticles2D mỗi sao lớn — không thêm ảnh):
##   băng keo rơi xuống → HÀO QUANG (tia sáng xoay + quầng mềm thở) bật lên sau ngôi sao đầu →
##   sao lớn nảy + xoay + vòng sóng + toé lấp lánh → PHÁO HOA nổ rải khắp popup, tia rơi vương vãi
##   (ăn mừng theo số sao: 1★ = 2 quả nhỏ · 2★ = 4 quả + pháo giấy · 3★ = 8 quả 2 đợt + quả chốt lớn
##   + hào quang bùng sáng + pháo giấy dày) → thẻ nhiệm vụ hiện lần lượt
##   (sao nhiệm vụ đạt nảy) → thẻ Thời gian/Bước/Đâm tường hiện + số chạy đếm lên → nút hiện.
##   Đủ 3 sao: các sao lớn "thở" nhẹ liên tục. Tween huỷ khi đóng popup.
## `WinningChallengePopup` kế thừa popup này (cùng bố cục, đổi tiêu đề + nút "TRỞ VỀ").
## Popup Daily (winning_daily) là scene riêng, KHÔNG dùng lớp này.
## ============================================================================

signal replay_requested
signal next_requested

const COUNT := 3
const COLOR_DONE := Color(0.69, 0.478, 0.039, 1)  # keep-code: màu/art hiệu ứng runtime — không thuộc theme tĩnh
const COLOR_FAIL := Color(0.478, 0.529, 0.58, 1)  # keep-code: màu/art hiệu ứng runtime — không thuộc theme tĩnh
const STAR_DELAY := 0.45
const STAR_STEP := 0.24
const COUNT_TIME := 0.7
## Màu hào quang vàng ấm (nhân với màu ảnh fx_glow_*.png) — chỉnh tại đây
const GLOW_COLOR := Color(1.0, 0.84, 0.45, 1.0)  # keep-code: màu/art hiệu ứng runtime — không thuộc theme tĩnh
const RING_COLOR := Color(1.0, 0.8, 0.25, 1.0)  # keep-code: màu/art hiệu ứng runtime — không thuộc theme tĩnh
const SPARK_PX := 18.0
const CONFETTI_PX := 12.0
const FW_PX := 22.0
## Vị trí nổ pháo (toạ độ trong Panel 478×562)
const FW_POS: Array[Vector2] = [
	Vector2(239, 190), Vector2(105, 140), Vector2(375, 140), Vector2(62, 290),
	Vector2(416, 290), Vector2(239, 105), Vector2(150, 250), Vector2(330, 250)]
const FW_COLORS: Array[Color] = [
	Color(1.0, 0.82, 0.25), Color(1.0, 0.45, 0.7), Color(0.35, 0.85, 1.0),
	Color(0.55, 0.95, 0.4), Color(1.0, 0.55, 0.2)]
## Kịch bản ăn mừng: [vị trí, trễ(s), màu, số tia, lực nổ]
const PLAN_1: Array = [[1, 0.0, 0, 18, 0.7], [2, 0.25, 4, 18, 0.7]]
const PLAN_2: Array = [[1, 0.0, 0, 26, 0.9], [2, 0.2, 1, 26, 0.9], [0, 0.45, 2, 30, 1.0], [5, 0.7, 3, 26, 0.9]]
const PLAN_3: Array = [
	[0, 0.0, 0, 44, 1.15], [1, 0.2, 1, 36, 1.0], [2, 0.35, 2, 36, 1.0], [3, 0.6, 3, 32, 1.0],
	[4, 0.7, 4, 32, 1.0], [5, 0.95, 0, 40, 1.1], [6, 1.15, 1, 32, 1.0], [7, 1.3, 2, 32, 1.0],
	[0, 1.7, 0, 64, 1.45]]
const CONFETTI_BY_STARS: Array[int] = [0, 0, 24, 80]

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
## Node hiệu ứng mở — khai `node_paths` trong .tscn
@export var fx_tape: Control = null
@export var fx_missions: Control = null
@export var fx_stats: Control = null
@export var fx_buttons: Control = null
## Hào quang nằm trong Panel/Art (dưới băng keo, trên giấy) quanh sao giữa (ảnh: effects/fx_glow_rays.png — 512px, tia vàng nhạt, xoay, effects/fx_glow_soft.png thở)
@export var fx_rays: Control = null
@export var fx_soft: Control = null
## Lớp tia thứ 2 (đủ ≥2 sao) và thứ 3 (3 sao) — xoay ngược chiều, lệch góc → nhiều tia hơn
@export var fx_rays2: Control = null
@export var fx_rays3: Control = null
## Pháo giấy rơi khi đủ 3 sao (ảnh: effects/fx_confetti.png)
@export var fx_confetti: CPUParticles2D = null
## Pháo hoa: Control chứa các ô FW1..FW8 (mỗi ô có `Spark` CPUParticles2D + `Flash` TextureRect)
@export var fx_fireworks: Control = null

var _tweens: Array[Tween] = []
var _tape_rest := Vector2.ZERO
var _tape_rot := 0.0
var _tape_saved := false
var _steps_max := 0
var _earned := 0
var _halo_k := 1.0
var _halo_layers: Array[Control] = []


func _on_open() -> void:
	if data.is_empty():
		return
	_kill_tweens()
	_hide_for_intro()
	var level := maxi(int(data.get("level", data.get("floor", 1))), 1)
	label_level.text = tr("STR_WL_LEVEL").format([level])

	var earned := clampi(int(data.get("stars", 0)), 0, COUNT)
	var rows: Array = data.get("missions", []) if data.get("missions", []) is Array else []
	_earned = earned
	_reset_fx()
	_set_stars(earned)
	_fill_missions(rows)

	var secs := maxi(int(round(float(data.get("time", 0.0)))), 0)
	var used := int(data.get("steps_used", 0))
	var maxs := int(data.get("steps_max", 0))
	var walls := int(data.get("wall_hits", 0))
	value_time.text = "%02d:%02d" % [secs / 60, secs % 60]
	value_steps.text = "%d/%d" % [used, maxs]
	value_walls.text = str(walls)

	# Hết chương (hoặc chương kế chưa mở) -> nút đổi thành "CHỌN CHƯƠNG"
	label_next.text = TranslationServer.translate(
		"STR_BTN_NEXT_LEVEL" if bool(data.get("next_available", true))
		else "STR_CHAPTER_SCREEN_TITLE")

	_play_intro(earned, rows, secs, used, maxs, walls)


## Ẩn sẵn các phần sẽ hiện dần (gọi đồng bộ để không bị nháy 1 khung trước khi tween chạy)
func _hide_for_intro() -> void:
	for n: Control in [fx_tape, label_level, fx_stats, fx_buttons]:
		if n != null:
			n.modulate.a = 0.0
	if fx_missions != null:
		for c in fx_missions.get_children():
			if c is Control:
				(c as Control).modulate.a = 0.0


func _on_close() -> void:
	_kill_tweens()


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
		h.rotation = 0.0  # keep-code: pose hoạt cảnh runtime (tween)
		if on:
			h.scale = Vector2.ONE * 0.3  # keep-code: pose hoạt cảnh runtime (tween)
			h.rotation_degrees = -30.0  # keep-code: pose hoạt cảnh runtime (tween)
			h.modulate.a = 0.0
			_pop_star(h, i, i == earned - 1 and earned == COUNT)
		else:
			h.scale = Vector2.ONE * 0.85  # keep-code: pose hoạt cảnh runtime (tween)
			h.modulate.a = 0.0
			var tw := _track(create_tween())
			tw.tween_interval(STAR_DELAY)
			tw.tween_property(h, "modulate:a", 0.75, 0.25)
			tw.parallel().tween_property(h, "scale", Vector2.ONE, 0.25) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _pop_star(star: TextureRect, index: int, is_last_of_three: bool) -> void:
	var tw := _track(create_tween())
	tw.tween_interval(STAR_DELAY + STAR_STEP * float(index))
	tw.tween_callback(func() -> void:
		star.modulate.a = 1.0
		_star_pop(index)
		_ring(star)
		_burst(star, 16 if is_last_of_three else 9)
		if index == 0:
			_start_halo()
		if index == _earned - 1:
			_celebrate())
	tw.tween_property(star, "scale", Vector2(1.25, 1.25), 0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(star, "rotation_degrees", 0.0, 0.3) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(star, "scale", Vector2.ONE, 0.14)
	if is_last_of_three:
		tw.tween_callback(_start_idle)


## Toé lấp lánh quanh sao (node `Burst` con của mỗi sao lớn, texture = fx_sparkle.png)
func _burst(star: Control, amount: int) -> void:
	var b := star.get_node_or_null("Burst") as CPUParticles2D
	if b == null:
		return
	b.position = star.size * 0.5
	b.amount = amount
	if b.texture != null:
		var k := SPARK_PX / float(maxi(b.texture.get_width(), 1))
		b.scale_amount_min = k * 0.6
		b.scale_amount_max = k * 1.4
	b.restart()
	b.emitting = true


## Vòng sóng toả ra từ sao (node `Ring` con của mỗi sao lớn, texture = fx_ring.png)
func _ring(star: Control) -> void:
	var r := star.get_node_or_null("Ring") as Control
	if r == null:
		return
	r.pivot_offset = r.size * 0.5
	r.scale = Vector2.ONE * 0.7  # keep-code: pose hoạt cảnh runtime (tween)
	r.modulate = Color(RING_COLOR.r, RING_COLOR.g, RING_COLOR.b, 0.9)
	var tw := _track(create_tween().set_parallel(true))
	tw.tween_property(r, "scale", Vector2.ONE * 2.6, 0.55) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(r, "modulate:a", 0.0, 0.55)


## Ẩn hào quang + dừng pháo giấy trước mỗi lần mở
func _reset_fx() -> void:
	_halo_layers.clear()
	for n: Control in [fx_rays, fx_rays2, fx_rays3, fx_soft]:
		if n != null:
			n.modulate.a = 0.0
	if fx_confetti != null:
		fx_confetti.emitting = false


## HÀO QUANG theo số sao — càng nhiều sao càng TO, SÁNG và NHIỀU TIA:
##   1★: 1 lớp tia nhỏ · 2★: 2 lớp (xoay ngược, lệch góc) · 3★: 3 lớp, lớp thứ 3 to hơn + quầng mềm lớn
const HALO_K: Array[float] = [0.0, 0.7, 1.05, 1.45]
## [node, nhân kích thước, chu kỳ xoay (s, âm = ngược chiều), góc lệch ban đầu (độ), nhân độ sáng]
func _halo_plan() -> Array:
	var p: Array = [[fx_rays, 1.0, 20.0, 0.0, 1.0]]
	if _earned >= 2:
		p.append([fx_rays2, 0.88, -28.0, 11.0, 0.85])
	if _earned >= 3:
		p.append([fx_rays3, 1.3, 44.0, 22.0, 0.7])
	return p


func _start_halo() -> void:
	if fx_rays == null or fx_soft == null or _earned <= 0:
		return
	var k: float = HALO_K[clampi(_earned, 0, COUNT)]
	_halo_k = k
	_halo_layers.clear()
	for n: Control in [fx_rays, fx_rays2, fx_rays3, fx_soft]:
		if n != null:
			n.pivot_offset = n.size * 0.5
			n.modulate = Color(GLOW_COLOR.r, GLOW_COLOR.g, GLOW_COLOR.b, 0.0)
			n.scale = Vector2.ONE * 0.3  # keep-code: pose hoạt cảnh runtime (tween)

	for entry: Array in _halo_plan():
		var n := entry[0] as Control
		if n == null:
			continue
		var mult: float = entry[1]
		var period: float = entry[2]
		var a0: float = entry[4]
		_halo_layers.append(n)
		n.rotation = deg_to_rad(float(entry[3]))
		var tin := _track(create_tween().set_parallel(true))
		tin.tween_property(n, "modulate:a", 0.95 * a0, 0.5)
		tin.tween_property(n, "scale", Vector2.ONE * k * mult, 0.65) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		# xoay liên tục (âm = ngược chiều)
		var rot := _track(create_tween().set_loops())
		rot.tween_property(n, "rotation", n.rotation + signf(period) * TAU, absf(period))
		# nhấp nháy nhẹ
		var flick := _track(create_tween().set_loops())
		flick.tween_interval(0.7)
		flick.tween_property(n, "modulate:a", 0.65 * a0, 1.1 + 0.2 * float(_halo_layers.size())) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		flick.tween_property(n, "modulate:a", 1.0 * a0, 1.1 + 0.2 * float(_halo_layers.size())) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# quầng mềm: to dần theo sao + "thở"
	var ks := k * (1.0 + 0.1 * float(_earned - 1))
	var ts := _track(create_tween().set_parallel(true))
	ts.tween_property(fx_soft, "modulate:a", 0.95, 0.4)
	ts.tween_property(fx_soft, "scale", Vector2.ONE * ks, 0.5) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var breathe := _track(create_tween().set_loops())
	breathe.tween_interval(0.6)
	breathe.tween_property(fx_soft, "scale", Vector2.ONE * ks * 1.12, 0.9) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	breathe.tween_property(fx_soft, "scale", Vector2.ONE * ks, 0.9) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## ĂN MỪNG theo số sao: 1★ nhẹ · 2★ vừa · 3★ rực rỡ
func _celebrate() -> void:
	if _earned <= 0 or fx_fireworks == null:
		return
	var plan: Array = PLAN_1 if _earned == 1 else (PLAN_2 if _earned == 2 else PLAN_3)
	var slots := fx_fireworks.get_child_count()
	if slots <= 0:
		return
	var tw := _track(create_tween().set_parallel(true))
	for i in plan.size():
		var e: Array = plan[i]
		tw.tween_callback(_firework.bind(i % slots, FW_POS[e[0]], FW_COLORS[e[2]], e[3], e[4])) \
			.set_delay(float(e[1]))
	var conf: int = CONFETTI_BY_STARS[_earned]
	if conf > 0:
		tw.tween_callback(_confetti.bind(conf)).set_delay(0.0)
		if _earned == COUNT:
			tw.tween_callback(_confetti.bind(conf)).set_delay(1.1)
			tw.tween_callback(_halo_pulse).set_delay(1.7)


## Một quả pháo: quầng sáng chớp + tia lấp lánh toả tròn, chậm dần rồi rơi xuống (gravity)
func _firework(slot: int, pos: Vector2, color: Color, amount: int, power: float) -> void:
	var fw := fx_fireworks.get_child(slot) as Control
	if fw == null:
		return
	fw.position = pos
	var b := fw.get_node_or_null("Spark") as CPUParticles2D
	if b != null:
		b.color = color
		b.amount = amount
		b.initial_velocity_min = 130.0 * power
		b.initial_velocity_max = 250.0 * power
		if b.texture != null:
			var k := FW_PX * power / float(maxi(b.texture.get_width(), 1))
			b.scale_amount_min = k * 0.6
			b.scale_amount_max = k * 1.3
		b.restart()
		b.emitting = true
	var f := fw.get_node_or_null("Flash") as Control
	if f != null:
		f.pivot_offset = f.size * 0.5
		f.scale = Vector2.ONE * 0.3  # keep-code: pose hoạt cảnh runtime (tween)
		f.modulate = Color(color.r, color.g, color.b, 0.9)
		var tw := _track(create_tween().set_parallel(true))
		tw.tween_property(f, "scale", Vector2.ONE * (1.2 * power), 0.4) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(f, "modulate:a", 0.0, 0.4)


## Quả chốt (3★): mọi lớp tia bùng to rồi dịu lại
func _halo_pulse() -> void:
	if fx_soft == null or _halo_layers.is_empty():
		return
	for entry: Array in _halo_plan():
		var n := entry[0] as Control
		if n == null:
			continue
		var base := Vector2.ONE * _halo_k * float(entry[1])
		var tw := _track(create_tween())
		tw.tween_property(n, "scale", base * 1.3, 0.25) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(n, "scale", base, 0.8) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Pháo giấy rơi từ trên xuống
func _confetti(amount: int) -> void:
	if fx_confetti == null:
		return
	fx_confetti.amount = amount
	if fx_confetti.texture != null:
		var k := CONFETTI_PX / float(maxi(fx_confetti.texture.get_width(), 1))
		fx_confetti.scale_amount_min = k * 0.7
		fx_confetti.scale_amount_max = k * 1.3
	var parent := fx_confetti.get_parent() as Control
	if parent != null:
		fx_confetti.position = Vector2(parent.size.x * 0.5, -24.0)
	fx_confetti.restart()
	fx_confetti.emitting = true


## Đủ 3 sao: 3 sao lớn "thở" nhẹ liên tục (lệch pha nhau)
func _start_idle() -> void:
	var heroes: Array[TextureRect] = [hero1, hero2, hero3]
	for i in COUNT:
		var tw := _track(create_tween().set_loops())
		tw.tween_interval(0.15 * float(i))
		tw.tween_property(heroes[i], "scale", Vector2(1.07, 1.07), 0.7) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(heroes[i], "scale", Vector2.ONE, 0.7) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Chuỗi hiệu ứng mở: băng keo → tiêu đề → (sao lớn: xem `_set_stars`) → nhiệm vụ → thống kê → nút
func _play_intro(earned: int, rows: Array, secs: int, used: int, maxs: int, walls: int) -> void:
	# chờ 1 khung để layout xong (size/pivot chính xác)
	await get_tree().process_frame
	if not is_inside_tree():
		return
	_intro_tape()

	label_level.pivot_offset = label_level.size * 0.5
	label_level.modulate.a = 0.0
	label_level.scale = Vector2.ONE * 0.8  # keep-code: pose hoạt cảnh runtime (tween)
	var tl := _track(create_tween())
	tl.tween_interval(0.3)
	tl.tween_property(label_level, "modulate:a", 1.0, 0.2)
	tl.parallel().tween_property(label_level, "scale", Vector2.ONE, 0.3) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var t0 := STAR_DELAY + STAR_STEP * float(maxi(earned, 1)) + 0.35

	# thẻ nhiệm vụ: hiện lần lượt; nhiệm vụ đạt -> sao nhỏ nảy
	var m_stars: Array[TextureRect] = [m1_star, m2_star, m3_star]
	var cards := fx_missions.get_children()
	for i in cards.size():
		var c := cards[i] as Control
		if c == null:
			continue
		c.pivot_offset = c.size * 0.5
		c.modulate.a = 0.0
		c.scale = Vector2.ONE * 0.85  # keep-code: pose hoạt cảnh runtime (tween)
		var tw := _track(create_tween())
		tw.tween_interval(t0 + 0.1 * float(i))
		tw.tween_property(c, "modulate:a", 1.0, 0.18)
		tw.parallel().tween_property(c, "scale", Vector2.ONE, 0.26) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		var done := i < rows.size() and rows[i] is Dictionary and bool(rows[i].get("done", false))
		if done and i < m_stars.size():
			var s := m_stars[i]
			s.pivot_offset = s.size * 0.5
			s.scale = Vector2.ONE * 0.2  # keep-code: pose hoạt cảnh runtime (tween)
			tw.tween_property(s, "scale", Vector2(1.3, 1.3), 0.16) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(s, "scale", Vector2.ONE, 0.1)

	# thống kê: thẻ hiện + số chạy đếm lên
	var t1 := t0 + 0.1 * float(cards.size()) + 0.15
	_fade_in(fx_stats, t1, 0.95)
	value_time.text = "00:00"  # keep-code: chữ theo dữ liệu ván chơi (runtime)
	value_steps.text = "0/%d" % maxs
	value_walls.text = "0"  # keep-code: chữ theo dữ liệu ván chơi (runtime)
	_steps_max = maxs
	var tc := _track(create_tween())
	tc.tween_interval(t1 + 0.1)
	tc.tween_method(_count_time, 0.0, float(secs), COUNT_TIME) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tc.parallel().tween_method(_count_steps, 0.0, float(used), COUNT_TIME) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tc.parallel().tween_method(_count_walls, 0.0, float(walls), COUNT_TIME) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# nút
	_fade_in(fx_buttons, t1 + 0.35, 0.9)


func _count_time(v: float) -> void:
	var s := int(round(v))
	value_time.text = "%02d:%02d" % [s / 60, s % 60]


func _count_steps(v: float) -> void:
	value_steps.text = "%d/%d" % [int(round(v)), _steps_max]


func _count_walls(v: float) -> void:
	value_walls.text = str(int(round(v)))


## Băng keo tiêu đề rơi xuống + lắc nhẹ rồi đứng yên
func _intro_tape() -> void:
	if fx_tape == null:
		return
	if not _tape_saved:
		_tape_rest = fx_tape.position
		_tape_rot = fx_tape.rotation
		_tape_saved = true
	fx_tape.position = _tape_rest + Vector2(0, -70)
	fx_tape.rotation = _tape_rot - 0.14
	fx_tape.modulate.a = 0.0
	var tw := _track(create_tween().set_parallel(true))
	tw.tween_property(fx_tape, "position", _tape_rest, 0.42) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_property(fx_tape, "modulate:a", 1.0, 0.15)
	tw.tween_property(fx_tape, "rotation", _tape_rot, 0.6) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _fade_in(node: Control, delay: float, from_scale: float) -> void:
	if node == null:
		return
	node.pivot_offset = node.size * 0.5
	node.modulate.a = 0.0
	node.scale = Vector2.ONE * from_scale
	var tw := _track(create_tween())
	tw.tween_interval(delay)
	tw.tween_property(node, "modulate:a", 1.0, 0.2)
	tw.parallel().tween_property(node, "scale", Vector2.ONE, 0.26) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _track(tw: Tween) -> Tween:
	_tweens.append(tw)
	return tw


func _kill_tweens() -> void:
	for t in _tweens:
		if t != null and t.is_valid():
			t.kill()
	_tweens.clear()


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
