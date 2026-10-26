class_name NextFloorPopup
extends BasePopup
## ============================================================================
## Popup: QUA TẦNG của DUNGEON (nodes/popups/next_floor.tscn)
## Bố cục (cùng ngôn ngữ với Game Over Dungeon):
##   1. Đầu: "TẦNG n" (xanh)
##   2. Thước tầng (NextFloorRuler): tầng vừa qua · SẮP VÀO tầng kế · kỷ lục TUẦN/THÁNG
##   3. Thẻ điểm CỘNG DỒN: Cơ bản +a · Đi nhanh +b · Hoàn hảo +c ──── Tổng (dòng bằng 0 tự ẩn)
##   4. Thẻ thưởng bước đi "+N" (có hiệu ứng "bonus_pop"; N = 0 thì ẩn)
##   5. Nút: Về Menu · Vào tầng kế
##
## Hiệu ứng mở: băng keo rơi → "TẦNG n" nảy + HÀO QUANG + PHÁO HOA (to dần theo thành tích:
##   thường = 2 quả · bằng/phá kỷ lục TUẦN = 4 quả + pháo giấy · bằng/phá kỷ lục THÁNG = 8 quả + quả chốt + hào quang 3 lớp)
##   → thước tầng: ghim chạy tới tầng vừa qua rồi nét đứt dài tới tầng kế → thẻ điểm: từng dòng trượt vào,
##   số đếm lên, TỔNG nảy + lấp lánh → thẻ thưởng bước "+N" nảy + lấp lánh → nút (nút Vào tầng "thở" mời bấm).
##
## Dữ liệu (GameController._complete_floor): floor, next_floor, bonus_steps|steps_bonus,
##   base_score, move_bonus, perfect_bonus, total_score|score, best_floor_week?, best_floor_month?
## Signal giữ nguyên tên cũ để UIController nối như trước:
##   rest_requested  -> _emit_home      enter_requested -> _emit_continue
## ============================================================================

signal rest_requested
signal enter_requested

const COUNT_TIME := 0.6
const HALO_ALPHA := 0.65
const COUNT := 3
## Màu hào quang vàng ấm (nhân với màu ảnh fx_glow_*.png) — chỉnh tại đây
const GLOW_COLOR := Color(1.0, 0.84, 0.45, 1.0)
const RING_COLOR := Color(1.0, 0.8, 0.25, 1.0)
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

## Node binding: khai `node_paths` + `NodePath` trong `next_floor.tscn`
@export var label_floor: Label = null
@export var ruler: NextFloorRuler = null
@export var row_move: Control = null
@export var row_perfect: Control = null
@export var value_base: Label = null
@export var value_move: Label = null
@export var value_perfect: Label = null
@export var value_total: Label = null
@export var bonus_card: Control = null
@export var value_bonus: Label = null
@export var go_label: Label = null
@export var fx_anim: AnimationPlayer = null
## Node hiệu ứng — khai `node_paths` trong .tscn
@export var fx_tape: Control = null
@export var fx_header: Control = null
@export var fx_ruler_card: Control = null
@export var fx_score_rows: Control = null
@export var fx_buttons: Control = null
@export var btn_enter: Control = null
@export var fx_rays: Control = null
@export var fx_rays2: Control = null
@export var fx_rays3: Control = null
@export var fx_soft: Control = null
@export var fx_confetti: CPUParticles2D = null
@export var fx_fireworks: Control = null

var _tweens: Array[Tween] = []
var _tape_rest := Vector2.ZERO
var _tape_rot := 0.0
var _tape_saved := false
var _earned := 1	# bậc ăn mừng 1..3 (dùng chung code hào quang/pháo với winning)
var _halo_k := 1.0
var _halo_layers: Array[Control] = []


func _on_open() -> void:
	_kill_tweens()
	_hide_for_intro()
	var floor_no := maxi(int(data.get("floor", data.get("level", 1))), 1)
	var next_no := maxi(int(data.get("next_floor", floor_no + 1)), floor_no + 1)
	label_floor.text = tr("STR_GO_FLOOR").format([floor_no])
	go_label.text = tr("STR_NF_ENTER").format([next_no])

	var week := _record("week")
	var month := _record("month")
	ruler.set_data(floor_no, next_no, week, month,
		tr("STR_GO_YOU"), tr("STR_NF_NEXT"), tr("STR_GO_WEEK"), tr("STR_GO_MONTH"))

	var base_pts := int(data.get("base_score", 0))
	var move_pts := int(data.get("move_bonus", 0))
	var perfect_pts := int(data.get("perfect_bonus", 0))
	value_base.text = _fmt_signed(base_pts)
	value_move.text = _fmt_signed(move_pts)
	value_perfect.text = _fmt_signed(perfect_pts)
	# Khoản bằng 0 thì ẩn cho gọn
	row_move.visible = move_pts != 0
	row_perfect.visible = perfect_pts != 0
	value_total.text = _fmt_int(int(data.get("total_score", data.get("score", 0))))

	var bonus := int(data.get("bonus_steps", data.get("steps_bonus", 0)))
	value_bonus.text = "+%d" % bonus
	bonus_card.visible = bonus > 0

	# Bậc ăn mừng theo thành tích: thường / bằng-phá kỷ lục tuần / bằng-phá kỷ lục tháng
	_earned = 1
	if month > 0 and floor_no >= month:
		_earned = 3
	elif week > 0 and floor_no >= week:
		_earned = 2
	_reset_fx()
	_play_intro(floor_no, next_no, bonus, base_pts, move_pts, perfect_pts,
		int(data.get("total_score", data.get("score", 0))))


func _on_close() -> void:
	_kill_tweens()


func _play_bonus_pop(bonus: int) -> void:
	if bonus <= 0 or fx_anim == null or not is_inside_tree():
		return
	value_bonus.pivot_offset = value_bonus.size * 0.5
	if fx_anim.has_animation(&"bonus_pop"):
		fx_anim.play(&"bonus_pop")


# ---------------------------------------------------------------------------
# Hiệu ứng mở
# ---------------------------------------------------------------------------
## Ẩn sẵn các phần sẽ hiện dần (gọi đồng bộ để không nháy 1 khung)
func _hide_for_intro() -> void:
	for n: Control in [fx_tape, fx_header, fx_ruler_card, bonus_card, fx_buttons]:
		if n != null:
			n.modulate.a = 0.0
	if fx_score_rows != null:
		for c in fx_score_rows.get_children():
			if c is Control:
				(c as Control).modulate.a = 0.0
	if ruler != null:
		ruler.progress = 0.0


func _play_intro(floor_no: int, next_no: int, bonus: int, base_pts: int, move_pts: int,
		perfect_pts: int, total: int) -> void:
	# chờ 1 khung để layout xong (size/pivot chính xác)
	await get_tree().process_frame
	if not is_inside_tree():
		return
	_intro_tape()

	# "TẦNG n" nảy + hào quang + pháo hoa
	fx_header.pivot_offset = Vector2(60.0, fx_header.size.y * 0.5)
	fx_header.scale = Vector2.ONE * 0.6
	var th := _track(create_tween())
	th.tween_interval(0.25)
	th.tween_callback(func() -> void:
		fx_header.modulate.a = 1.0
		Sfx.play(Sfx.STAR_POP)
		Sfx.star_pop(_earned - 1)
		_start_halo()
		_celebrate())
	th.tween_property(fx_header, "scale", Vector2(1.18, 1.18), 0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	th.tween_property(fx_header, "scale", Vector2.ONE, 0.14)

	# thước tầng: thẻ hiện -> ghim chạy -> nét đứt dài tới tầng kế
	var t_ruler := 0.7
	_fade_in(fx_ruler_card, t_ruler, 0.95)
	var tr_ := _track(create_tween())
	tr_.tween_interval(t_ruler + 0.2)
	tr_.tween_property(ruler, "progress", 1.0, 1.0) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	# thẻ điểm cộng dồn: từng dòng trượt vào + số đếm lên; TỔNG nảy
	var t := t_ruler + 0.9
	var rows := fx_score_rows.get_children()
	var value_of := {
		"RowBase": [value_base, base_pts], "RowMove": [value_move, move_pts],
		"RowPerfect": [value_perfect, perfect_pts]}
	for r in rows:
		var row := r as Control
		if row == null or not row.visible:
			continue
		row.pivot_offset = Vector2(0.0, row.size.y * 0.5)
		var fade := _track(create_tween().set_parallel(true))
		fade.tween_interval(t)
		fade.chain().tween_property(row, "modulate:a", 1.0, 0.2)
		var rname := str(row.name)
		if value_of.has(rname):
			var pair: Array = value_of[rname]
			var lbl := pair[0] as Label
			var target: int = pair[1]
			lbl.text = _fmt_signed(0)
			var tc := _track(create_tween())
			tc.tween_interval(t + 0.05)
			tc.tween_method(_count_signed.bind(lbl), 0.0, float(target), COUNT_TIME) \
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			t += 0.28
		elif rname == "RowTotal":
			value_total.text = _fmt_int(0)
			value_total.pivot_offset = value_total.size * 0.5
			var tt := _track(create_tween())
			tt.tween_interval(t + 0.1)
			tt.tween_method(_count_int.bind(value_total), 0.0, float(total), COUNT_TIME + 0.2) \
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tt.tween_callback(func() -> void:
				Sfx.play(Sfx.STAR_POP)
				_burst(value_total, 14))
			tt.tween_property(value_total, "scale", Vector2(1.3, 1.3), 0.14) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tt.tween_property(value_total, "scale", Vector2.ONE, 0.12)
			t += COUNT_TIME + 0.5
		else:
			t += 0.1

	# thẻ thưởng bước đi: hiện + "bonus_pop" + lấp lánh
	if bonus > 0:
		_fade_in(bonus_card, t, 0.9)
		var tb := _track(create_tween())
		tb.tween_interval(t + 0.2)
		tb.tween_callback(func() -> void:
			Sfx.play(Sfx.STAR_POP)
			Sfx.star_pop(2)
			_burst(value_bonus, 12)
			_play_bonus_pop(bonus))
		t += 0.5

	# nút: hiện; nút "Vào tầng" thở nhẹ mời bấm
	_fade_in(fx_buttons, t, 0.9)
	if btn_enter != null:
		btn_enter.pivot_offset = btn_enter.size * 0.5
		var tp := _track(create_tween())
		tp.tween_interval(t + 0.5)
		tp.tween_callback(func() -> void:
			var loop := _track(create_tween().set_loops())
			loop.tween_property(btn_enter, "scale", Vector2(1.05, 1.05), 0.6) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			loop.tween_property(btn_enter, "scale", Vector2.ONE, 0.6) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT))


func _count_signed(v: float, label: Label) -> void:
	label.text = _fmt_signed(int(round(v)))


func _count_int(v: float, label: Label) -> void:
	label.text = _fmt_int(int(round(v)))


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
const HALO_K: Array[float] = [0.0, 0.6, 0.85, 1.1]
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
			n.scale = Vector2.ONE * 0.3

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
		tin.tween_property(n, "modulate:a", HALO_ALPHA * a0, 0.5)
		tin.tween_property(n, "scale", Vector2.ONE * k * mult, 0.65) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		# xoay liên tục (âm = ngược chiều)
		var rot := _track(create_tween().set_loops())
		rot.tween_property(n, "rotation", n.rotation + signf(period) * TAU, absf(period))
		# nhấp nháy nhẹ
		var flick := _track(create_tween().set_loops())
		flick.tween_interval(0.7)
		flick.tween_property(n, "modulate:a", HALO_ALPHA * 0.7 * a0, 1.1 + 0.2 * float(_halo_layers.size())) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		flick.tween_property(n, "modulate:a", HALO_ALPHA * a0, 1.1 + 0.2 * float(_halo_layers.size())) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# quầng mềm: to dần theo sao + "thở"
	var ks := k * (1.0 + 0.1 * float(_earned - 1))
	var ts := _track(create_tween().set_parallel(true))
	ts.tween_property(fx_soft, "modulate:a", 0.8, 0.4)
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
		f.scale = Vector2.ONE * 0.3
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


# ---------------------------------------------------------------------------
# Kỷ lục (cho thước tầng)
# ---------------------------------------------------------------------------
func _record(kind: String) -> int:
	var best := int(data.get("best_floor_%s" % kind, -1))
	if best >= 0:
		return best
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("best_floor"):
		return int(gm.call("best_floor", kind))
	return 0


## 1240 -> "1.240"
static func _fmt_int(value: int) -> String:
	var s := str(absi(value))
	var out := ""
	for i in s.length():
		if i > 0 and (s.length() - i) % 3 == 0:
			out += "."
		out += s[i]
	return ("-" if value < 0 else "") + out


## 200 -> "+200"
static func _fmt_signed(value: int) -> String:
	return ("+" if value >= 0 else "-") + _fmt_int(absi(value))


# ---------------------------------------------------------------------------
# Nút (nối trong next_floor.tscn)
# ---------------------------------------------------------------------------
func _on_rest_pressed() -> void:
	Sfx.play(Sfx.BTN_WOOD_TAP)
	rest_requested.emit()
	close()


func _on_enter_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	enter_requested.emit()
	close()
