class_name GameOverPopup
extends BasePopup
## ============================================================================
## Popup: Thua cuộc ở DUNGEON (nodes/popups/gameover.tscn)
## Bố cục:
##   1. Đầu: "Bạn thua ở TẦNG n" + nhãn lý do + dòng gợi ý kỷ lục
##   2. Thước kỷ lục (GameOverRuler): tầng vừa thua · kỷ lục TUẦN · kỷ lục THÁNG
##   3. Thẻ 3 cột: Đã đi trong tầng · Đâm tường · Điểm
##   4. Thẻ bút chì (bút vừa gãy có nhãn −1) + đếm ngược hồi bút
##   5. Nút: Về Menu · Chơi lại
##
## Hiệu ứng mở (kiểu THUA — nặng, tối, không pháo): băng keo rơi "bịch" + rung giấy + loé đỏ + bụi tro rơi →
##   "TẦNG n" đập xuống → thước: đoạn đỏ + ghim ✕ chạy tới tầng thua → số liệu đếm lên → bút chì GÃY (rung, rắc, −1)
##   → nút hiện, nút "Chơi lại" thở nhẹ mời bấm. Tween huỷ khi đóng popup.
##
## HỒI SINH đã chuyển sang popup Retry (hiện trước popup này) -> KHÔNG còn ở đây.
## Lượt (bút) đã bị trừ TRƯỚC khi popup này mở (UIController._charge_life_cost).
## Dữ liệu: open({ floor, progress, wall_hits, score, steps_left, steps_max,
##                 best_floor_week?, best_floor_month?, guided? })
## ============================================================================

signal retry_requested
signal menu_requested
## ĐÃ BỎ (Hồi sinh nằm ở popup Retry). Giữ khai báo, KHÔNG BAO GIỜ phát, để các
## nơi cũ còn `connect(...revive_requested...)` không lỗi. Xoá khi dọn code.
signal revive_requested

## Node binding: khai `node_paths` + `NodePath` trong `gameover.tscn`
@export var label_floor: Label = null
@export var label_reason: Label = null
@export var label_hint: Label = null
@export var ruler: GameOverRuler = null
@export var value_progress: Label = null
@export var value_walls: Label = null
@export var value_score: Label = null
@export var pencils: RetryPencils = null
@export var label_count: Label = null
@export var btn_menu: BaseButton = null
@export var btn_retry: BaseButton = null
## Node hiệu ứng — khai `node_paths` trong .tscn
@export var fx_tape: Control = null
@export var fx_shake_a: Control = null	# Panel/Art
@export var fx_shake_b: Control = null	# Panel/Content
@export var fx_header: Control = null
@export var fx_ruler_card: Control = null
@export var fx_stats: Control = null
@export var fx_pencil_card: Control = null
@export var fx_buttons: Control = null
@export var fx_rays: Control = null
@export var fx_soft: Control = null
@export var fx_ash: CPUParticles2D = null

const GLOW_RED := Color(1.0, 0.33, 0.28, 1.0)  # keep-code: màu/art hiệu ứng runtime — không thuộc theme tĩnh
const COUNT_TIME := 0.6

var _tweens: Array[Tween] = []
var _tape_rest := Vector2.ZERO
var _tape_rot := 0.0
var _tape_saved := false
var _rest_a := Vector2.ZERO
var _rest_b := Vector2.ZERO
var _rest_saved := false

var _charged := false


func _on_open() -> void:
	_kill_tweens()
	_hide_for_intro()
	var floor_no := maxi(int(data.get("floor", 1)), 1)
	var progress := clampi(int(round(float(data.get("progress", 0.0)))), 0, 100)
	label_floor.text = tr("STR_GO_FLOOR").format([floor_no])
	label_reason.text = tr("STR_GO_REASON_STEPS")  # keep-code: chữ theo dữ liệu ván chơi (runtime)
	value_progress.text = "%d%%" % progress
	value_walls.text = str(int(data.get("wall_hits", 0)))
	value_score.text = _fmt_int(int(data.get("score", 0)))

	# Kỷ lục: ưu tiên số trong `data`, thiếu thì hỏi GameManager (đã gồm cả tầng vừa thua)
	var week := _record("week")
	var month := _record("month")
	ruler.set_data(floor_no, week, month, tr("STR_GO_YOU"), tr("STR_GO_WEEK"), tr("STR_GO_MONTH"))
	_refresh_hint(floor_no, week, month)

	# Bút
	_charged = _will_charge_life()
	_connect_life_signal()
	_refresh_pencils()

	if btn_menu != null:
		btn_menu.visible = not bool(data.get("guided", false))

	_play_intro(progress, int(data.get("wall_hits", 0)), int(data.get("score", 0)))


func _on_close() -> void:
	_kill_tweens()
	if fx_ash != null:
		fx_ash.emitting = false
	var gm := _game_manager()
	if gm != null and gm.has_signal("life_changed") \
			and gm.is_connected("life_changed", _on_life_changed):  # keep-code: nối/ngắt AUTOLOAD GameManager (không phải node tĩnh)
		gm.disconnect("life_changed", _on_life_changed)  # keep-code: nối/ngắt AUTOLOAD GameManager (không phải node tĩnh)


# ---------------------------------------------------------------------------
# Hiệu ứng mở
# ---------------------------------------------------------------------------
## Ẩn sẵn các phần sẽ hiện dần (gọi đồng bộ để không nháy 1 khung)
func _hide_for_intro() -> void:
	for n: Control in [fx_tape, fx_header, fx_ruler_card, fx_stats, fx_pencil_card, fx_buttons, fx_rays, fx_soft]:
		if n != null:
			n.modulate.a = 0.0
	if ruler != null:
		ruler.progress = 0.0
	if fx_ash != null:
		fx_ash.emitting = false
	if _rest_saved:
		fx_shake_a.position = _rest_a
		fx_shake_b.position = _rest_b


func _play_intro(progress: int, walls: int, score: int) -> void:
	# chờ 1 khung để layout xong (size/pivot chính xác)
	await get_tree().process_frame
	if not is_inside_tree():
		return
	if not _rest_saved and fx_shake_a != null and fx_shake_b != null:
		_rest_a = fx_shake_a.position
		_rest_b = fx_shake_b.position
		_rest_saved = true
	_intro_tape()

	# băng keo chạm giấy (~0.4s): rung + loé đỏ + tro rơi
	var tl := _track(create_tween())
	tl.tween_interval(0.4)
	tl.tween_callback(func() -> void:
		Sfx.play(Sfx.BTN_WOOD_TAP)
		_shake(7.0, 0.4)
		_red_flash()
		if fx_ash != null:
			_size_ash()
			fx_ash.restart()
			fx_ash.emitting = true)

	# "TẦNG n" đập xuống
	fx_header.pivot_offset = Vector2(60.0, fx_header.size.y * 0.5)
	fx_header.scale = Vector2.ONE * 1.5  # keep-code: pose hoạt cảnh runtime (tween)
	var th := _track(create_tween())
	th.tween_interval(0.55)
	th.tween_property(fx_header, "modulate:a", 1.0, 0.08)
	th.parallel().tween_property(fx_header, "scale", Vector2.ONE, 0.2) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	th.tween_callback(func() -> void:
		Sfx.play(Sfx.BTN_WOOD_TAP)
		_shake(4.0, 0.25))

	# thước: thẻ hiện -> đoạn đỏ + ghim ✕ chạy tới tầng thua -> thẻ nảy khi tới
	var t_r := 1.0
	_fade_in(fx_ruler_card, t_r, 0.95)
	var tr_ := _track(create_tween())
	tr_.tween_interval(t_r + 0.25)
	tr_.tween_property(ruler, "progress", 1.0, 0.9) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tr_.tween_callback(func() -> void:
		_shake(3.0, 0.2)
		fx_ruler_card.pivot_offset = fx_ruler_card.size * 0.5)
	tr_.tween_property(fx_ruler_card, "scale", Vector2(1.03, 1.03), 0.08)
	tr_.tween_property(fx_ruler_card, "scale", Vector2.ONE, 0.12)

	# số liệu đếm lên
	var t_s := t_r + 1.4
	_fade_in(fx_stats, t_s, 0.95)
	value_progress.text = "0%"  # keep-code: chữ theo dữ liệu ván chơi (runtime)
	value_walls.text = "0"  # keep-code: chữ theo dữ liệu ván chơi (runtime)
	value_score.text = "0"  # keep-code: chữ theo dữ liệu ván chơi (runtime)
	var tc := _track(create_tween())
	tc.tween_interval(t_s + 0.1)
	tc.tween_method(_count_progress, 0.0, float(progress), COUNT_TIME) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tc.parallel().tween_method(_count_walls, 0.0, float(walls), COUNT_TIME) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tc.parallel().tween_method(_count_score, 0.0, float(score), COUNT_TIME + 0.2) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# bút chì GÃY
	var t_p := t_s + 0.7
	_fade_in(fx_pencil_card, t_p, 0.95)
	if pencils != null and _charged:
		pencils.play_lost_effect(t_p + 0.3)

	# nút: hiện; "Chơi lại" thở nhẹ mời bấm
	var t_b := t_p + 0.5
	_fade_in(fx_buttons, t_b, 0.9)
	if btn_retry != null and _can_play():
		btn_retry.pivot_offset = btn_retry.size * 0.5
		var tp := _track(create_tween())
		tp.tween_interval(t_b + 0.5)
		tp.tween_callback(func() -> void:
			var loop := _track(create_tween().set_loops())
			loop.tween_property(btn_retry, "scale", Vector2(1.05, 1.05), 0.7) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			loop.tween_property(btn_retry, "scale", Vector2.ONE, 0.7) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT))


## Hạt tro ~7–16px bất kể kích thước ảnh fx_sparkle
func _size_ash() -> void:
	if fx_ash.texture == null:
		return
	var w := float(maxi(fx_ash.texture.get_width(), 1))
	fx_ash.scale_amount_min = 7.0 / w
	fx_ash.scale_amount_max = 16.0 / w


func _count_progress(v: float) -> void:
	value_progress.text = "%d%%" % int(round(v))


func _count_walls(v: float) -> void:
	value_walls.text = str(int(round(v)))


func _count_score(v: float) -> void:
	value_score.text = _fmt_int(int(round(v)))


## Giấy rung (Art + Content cùng rung), biên độ giảm dần
func _shake(amp: float, dur: float) -> void:
	if not _rest_saved:
		return
	var tw := _track(create_tween())
	tw.tween_method(_shake_step.bind(amp), 0.0, 1.0, dur)
	tw.tween_callback(func() -> void:
		fx_shake_a.position = _rest_a
		fx_shake_b.position = _rest_b)


func _shake_step(t: float, amp: float) -> void:
	var off := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * amp * (1.0 - t)
	fx_shake_a.position = _rest_a + off
	fx_shake_b.position = _rest_b + off


## Loé đỏ cảnh báo sau chữ "TẦNG n" + tia sáng đỏ mờ xoay chậm; quầng đập nhịp như tim
func _red_flash() -> void:
	if fx_soft == null or fx_rays == null:
		return
	for n: Control in [fx_soft, fx_rays]:
		n.pivot_offset = n.size * 0.5
		n.modulate = Color(GLOW_RED.r, GLOW_RED.g, GLOW_RED.b, 0.0)
	fx_soft.scale = Vector2.ONE * 0.6  # keep-code: pose hoạt cảnh runtime (tween)
	fx_rays.scale = Vector2.ONE * 0.7  # keep-code: pose hoạt cảnh runtime (tween)
	var tw := _track(create_tween().set_parallel(true))
	tw.tween_property(fx_soft, "modulate:a", 0.85, 0.12)
	tw.tween_property(fx_soft, "scale", Vector2.ONE * 1.2, 0.4) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(fx_rays, "modulate:a", 0.28, 0.5)
	tw.tween_property(fx_rays, "scale", Vector2.ONE, 0.6) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var rot := _track(create_tween().set_loops())
	rot.tween_property(fx_rays, "rotation", -TAU, 40.0).from(0.0)
	var beat := _track(create_tween().set_loops())
	beat.tween_interval(0.5)
	beat.tween_property(fx_soft, "modulate:a", 0.3, 0.45) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	beat.tween_property(fx_soft, "modulate:a", 0.6, 0.35) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


## Băng keo tiêu đề rơi "bịch" (nảy ngắn) rồi đứng yên
func _intro_tape() -> void:
	if fx_tape == null:
		return
	if not _tape_saved:
		_tape_rest = fx_tape.position
		_tape_rot = fx_tape.rotation
		_tape_saved = true
	fx_tape.position = _tape_rest + Vector2(0, -90)
	fx_tape.rotation = _tape_rot + 0.1
	fx_tape.modulate.a = 0.0
	var tw := _track(create_tween().set_parallel(true))
	tw.tween_property(fx_tape, "position", _tape_rest, 0.4) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_property(fx_tape, "modulate:a", 1.0, 0.12)
	tw.tween_property(fx_tape, "rotation", _tape_rot, 0.5) \
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
# Kỷ lục
# ---------------------------------------------------------------------------
func _record(kind: String) -> int:
	var best := int(data.get("best_floor_%s" % kind, -1))
	if best >= 0:
		return best
	var gm := _game_manager()
	if gm != null and gm.has_method("best_floor"):
		return int(gm.call("best_floor", kind))
	return 0


## Dòng gợi ý dưới nhãn lý do. Kỷ lục được ghi ngay khi VÀO tầng, nên best >= tầng thua:
## best == tầng thua nghĩa là bạn đang giữ kỷ lục kỳ đó.
func _refresh_hint(floor_no: int, week: int, month: int) -> void:
	if label_hint == null:
		return
	if month <= 0:
		label_hint.text = ""  # keep-code: chữ theo dữ liệu ván chơi (runtime)
		label_hint.visible = false  # keep-code: trạng thái theo dữ liệu (runtime)
		return
	label_hint.visible = true  # keep-code: trạng thái theo dữ liệu (runtime)
	if floor_no >= month:
		label_hint.text = tr("STR_GO_REC_MONTH_HOLD")  # keep-code: chữ theo dữ liệu ván chơi (runtime)
	elif week > 0 and floor_no >= week:
		label_hint.text = tr("STR_GO_REC_WEEK_HOLD").format([month - floor_no])
	else:
		label_hint.text = tr("STR_GO_REC_REMAIN").format([month - floor_no])


## 1240 -> "1.240"
static func _fmt_int(value: int) -> String:
	var s := str(absi(value))
	var out := ""
	for i in s.length():
		if i > 0 and (s.length() - i) % 3 == 0:
			out += "."
		out += s[i]
	return ("-" if value < 0 else "") + out


# ---------------------------------------------------------------------------
# Bút chì (đọc từ GameManager)
# ---------------------------------------------------------------------------
func _game_manager() -> Node:
	return get_node_or_null("/root/GameManager")


## Ván này có bị trừ bút không? Khớp UIController._charge_life_cost (guided / debug_run miễn).
func _will_charge_life() -> bool:
	if bool(data.get("guided", false)):
		return false
	var gm := _game_manager()
	if gm != null and bool(gm.get("debug_run")):
		return false
	return true


func _connect_life_signal() -> void:
	var gm := _game_manager()
	if gm != null and gm.has_signal("life_changed") \
			and not gm.is_connected("life_changed", _on_life_changed):  # keep-code: nối/ngắt AUTOLOAD GameManager (không phải node tĩnh)
		gm.connect("life_changed", _on_life_changed)  # keep-code: nối/ngắt AUTOLOAD GameManager (không phải node tĩnh)


func _on_life_changed(_lives: int, _max: int) -> void:
	_refresh_pencils()


func _can_play() -> bool:
	if not _will_charge_life():
		return true
	var gm := _game_manager()
	if gm != null and gm.has_method("can_start_run"):
		return bool(gm.call("can_start_run"))
	return true


func _refresh_pencils() -> void:
	var gm := _game_manager()
	var lives := 0
	var maximum := 5
	var next_unix := 0.0
	if gm != null:
		if gm.has_method("lives_left"):
			lives = int(gm.call("lives_left"))
		if gm.has_method("max_lives"):
			maximum = int(gm.call("max_lives"))
		if gm.has_method("seconds_to_next_life"):
			var wait := int(gm.call("seconds_to_next_life"))
			if wait > 0:
				next_unix = Time.get_unix_time_from_system() + float(wait)
	# Bút vừa gãy = ô trống đầu tiên (đã bị trừ trước khi popup mở)
	var lost := lives if _charged else -1
	pencils.set_state(lives, maximum, next_unix, false, lost)
	label_count.text = "%d/%d" % [lives, maximum]
	if btn_retry != null:
		btn_retry.modulate = Color.WHITE if _can_play() else Color(0.72, 0.72, 0.72, 1.0)


# ---------------------------------------------------------------------------
# Nút bấm
# ---------------------------------------------------------------------------
func _on_retry_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	# GameController._on_retry_requested KHÔNG kiểm tra bút -> chặn ở đây
	if not _can_play():
		var gm := _game_manager()
		if gm != null and gm.has_method("open_out_of_life_popup"):
			gm.call("open_out_of_life_popup")
		return
	retry_requested.emit()
	close()


func _on_menu_pressed() -> void:
	Sfx.play(Sfx.BTN_WOOD_TAP)
	menu_requested.emit()
	close()
