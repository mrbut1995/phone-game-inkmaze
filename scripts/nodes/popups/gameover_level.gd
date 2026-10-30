class_name GameOverLevelPopup
extends BasePopup
## ============================================================================
## Popup: Thua cuộc ở Play / Level Mode (nodes/popups/gameover_level.tscn)
## Bố cục "BẢN ĐỒ ĐƯỜNG ĐI":
##   1. Thẻ đường đi : đoạn đã đi / còn lại + % hoàn thành + thời gian · số lần đâm
##   2. 3 thẻ nhiệm vụ : sao đầy/rỗng + tên
##   3. Thẻ bút chì   : hàng bút (bút vừa gãy có nhãn −1) + "n/max" + đếm ngược hồi bút
##   4. Nút: Về Menu (xám) · Chơi lại (xanh)
##
## Hiệu ứng mở (kiểu THUA): băng keo rơi "bịch" + giấy rung + loé đỏ + tro rơi -> đường đi chạy tới ✕
##   -> % đếm lên -> 3 nhiệm vụ (sao đạt nảy, sao hụt rung) -> bút chì GÃY (−1) -> nút, "Chơi lại" thở nhẹ.
##
## HỒI SINH đã chuyển sang popup Retry (hiện trước popup này) -> KHÔNG còn ở đây.
## Lượt (bút) đã bị trừ TRƯỚC khi popup này mở (UIController._charge_life_cost).
## Popup chỉ HIỂN THỊ + chặn "Chơi lại" khi hết bút.
##
## Dữ liệu: open({ progress, wall_hits, time, stars, missions:[{title,done}], guided, reason })
## ============================================================================

signal retry_requested
signal menu_requested
## ĐÃ BỎ (Hồi sinh nằm ở popup Retry). Giữ khai báo, KHÔNG BAO GIỜ phát, để các
## nơi cũ còn `connect(...revive_requested...)` không lỗi. Xoá khi dọn code.
signal revive_requested

@export var COUNT := 3
@export var star_full: Texture2D = null
@export var star_empty: Texture2D = null

const COLOR_MISSION_OK := Color("B07A0A")  # keep-code: màu/art hiệu ứng runtime — không thuộc theme tĩnh
const COLOR_MISSION_FAIL := Color("7A8794")  # keep-code: màu/art hiệu ứng runtime — không thuộc theme tĩnh

@export var label_title: Label = null
@export var path: GameOverPath = null
@export var label_percent: Label = null
@export var label_walked: Label = null
@export var label_stats: Label = null
@export var label_count: Label = null
@export var pencils: RetryPencils = null
@export var btn_menu: BaseButton = null
@export var btn_retry: BaseButton = null
@export var row1_star: TextureRect = null
@export var row1_name: Label = null
@export var row2_star: TextureRect = null
@export var row2_name: Label = null
@export var row3_star: TextureRect = null
@export var row3_name: Label = null

## Node hiệu ứng — khai `node_paths` trong .tscn
@export var fx_tape: Control = null
@export var fx_shake_a: Control = null	# Panel/Art
@export var fx_shake_b: Control = null	# Panel/Content
@export var fx_path_card: Control = null
@export var fx_missions: Control = null	# HBox chứa M1..M3
@export var fx_pencil_card: Control = null
@export var fx_buttons: Control = null
@export var fx_rays: Control = null
@export var fx_soft: Control = null
@export var fx_ash: CPUParticles2D = null

const GLOW_RED := Color(1.0, 0.33, 0.28, 1.0)  # keep-code: màu/art hiệu ứng runtime — không thuộc theme tĩnh

var _charged := false
var _tweens: Array[Tween] = []
var _tape_rest := Vector2.ZERO
var _tape_rot := 0.0
var _tape_saved := false
var _rest_a := Vector2.ZERO
var _rest_b := Vector2.ZERO
var _rest_saved := false


func _on_open() -> void:
	_kill_tweens()
	_hide_for_intro()
	# Tiêu đề riêng theo LÝ DO thua (giữ như bản cũ)
	match str(data.get("reason", "")):
		"dead_end":
			label_title.text = tr("STR_GAME_OVER_NO_PATH")  # keep-code: chữ theo dữ liệu ván chơi (runtime)
		"revisit":
			label_title.text = tr("STR_GAME_OVER_REVISIT")  # keep-code: chữ theo dữ liệu ván chơi (runtime)
		"out_of_submits":
			label_title.text = tr("STR_GAME_OVER_OUT_OF_SUBMITS")  # keep-code: chữ theo dữ liệu ván chơi (runtime)

	# 1. Đường đi
	var progress := clampi(int(data.get("progress", 0)), 0, 100)
	path.set_progress(progress / 100.0)
	label_percent.text = "%d%%" % progress
	label_walked.text = tr("STR_GO_WALKED")  # keep-code: chữ theo dữ liệu ván chơi (runtime)
	label_stats.text = tr("STR_GO_STATS").format([_format_time(data.get("time", 0)), int(data.get("wall_hits", 0))])

	# 2. Nhiệm vụ
	var rows: Array = data.get("missions", [])
	var stars: Array[TextureRect] = [row1_star, row2_star, row3_star]
	var names: Array[Label] = [row1_name, row2_name, row3_name]
	for i in COUNT:
		var row: Dictionary = rows[i] if i < rows.size() else {}
		var ok := bool(row.get("done", false))
		stars[i].texture = star_full if ok else star_empty
		if row.has("title"):
			names[i].text = str(row.get("title"))
		names[i].add_theme_color_override("font_color", COLOR_MISSION_OK if ok else COLOR_MISSION_FAIL)

	# 3. Bút
	_charged = _will_charge_life()
	_connect_life_signal()
	_refresh_pencils()

	# 4. Luồng học lần đầu: không cho "Về Menu"
	if btn_menu != null:
		btn_menu.visible = not bool(data.get("guided", false))

	_play_intro(progress)


func _on_close() -> void:
	_kill_tweens()
	if fx_ash != null:
		fx_ash.emitting = false
	var gm := _game_manager()
	if gm != null and gm.has_signal("life_changed") \
			and gm.is_connected("life_changed", _on_life_changed):  # keep-code: nối/ngắt AUTOLOAD GameManager (không phải node tĩnh)
		gm.disconnect("life_changed", _on_life_changed)  # keep-code: nối/ngắt AUTOLOAD GameManager (không phải node tĩnh)


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
	# Hết bút: làm mờ nút Chơi lại (bấm vẫn mở popup Hết bút)
	if btn_retry != null:
		btn_retry.modulate = Color.WHITE if _can_play() else Color(0.72, 0.72, 0.72, 1.0)


## 84 -> "01:24". Chấp nhận số giây (int/float) hoặc chuỗi đã định dạng sẵn.
func _format_time(value: Variant) -> String:
	if value is String:
		return value
	var total := int(value)
	return "%02d:%02d" % [total / 60, total % 60]


# ---------------------------------------------------------------------------
# Hiệu ứng mở
# ---------------------------------------------------------------------------
## Ẩn sẵn các phần sẽ hiện dần (gọi đồng bộ để không nháy 1 khung)
func _hide_for_intro() -> void:
	var nodes: Array[Control] = [fx_tape, fx_path_card, fx_pencil_card, fx_buttons, fx_rays, fx_soft]
	for n in nodes:
		if n != null:
			n.modulate.a = 0.0
	if fx_missions != null:
		for m in fx_missions.get_children():
			(m as Control).modulate.a = 0.0
	if path != null:
		path.anim = 0.0
	if fx_ash != null:
		fx_ash.emitting = false
	if _rest_saved:
		fx_shake_a.position = _rest_a
		fx_shake_b.position = _rest_b


func _play_intro(progress: int) -> void:
	await get_tree().process_frame
	if not is_inside_tree():
		return
	if not _rest_saved and fx_shake_a != null and fx_shake_b != null:
		_rest_a = fx_shake_a.position
		_rest_b = fx_shake_b.position
		_rest_saved = true
	_intro_tape()

	# băng keo chạm giấy (~0.3s): rung + loé đỏ + tro rơi
	var tl := _track(create_tween())
	tl.tween_interval(0.3)
	tl.tween_callback(func() -> void:
		Sfx.play(Sfx.BTN_WOOD_TAP)
		_shake(7.0, 0.4)
		_red_flash()
		if fx_ash != null:
			_size_ash()
			fx_ash.restart()
			fx_ash.emitting = true)

	# thẻ đường đi: hiện -> nét xanh chạy tới điểm thua (✕) -> % đếm lên -> giật nhẹ
	var t_p := 0.5
	_fade_in(fx_path_card, t_p, 0.95)
	label_percent.text = "0%"  # keep-code: chữ theo dữ liệu ván chơi (runtime)
	var tr_ := _track(create_tween())
	tr_.tween_interval(t_p + 0.15)
	tr_.tween_property(path, "anim", 1.0, 0.8) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tr_.tween_callback(func() -> void:
		Sfx.play(Sfx.BTN_WOOD_TAP)
		_shake(3.0, 0.2))
	var tc := _track(create_tween())
	tc.tween_interval(t_p + 0.15)
	tc.tween_method(_count_percent, 0.0, float(progress), 0.8) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# 3 nhiệm vụ: lần lượt hiện; sao đạt nảy "tinh", sao hụt rung nhẹ
	var t_m := t_p + 0.9
	var rows: Array = data.get("missions", [])
	var cards := fx_missions.get_children()
	var stars: Array[TextureRect] = [row1_star, row2_star, row3_star]
	for i in cards.size():
		var card := cards[i] as Control
		_fade_in(card, t_m, 0.9)
		var ok := i < rows.size() and bool((rows[i] as Dictionary).get("done", false))
		var star := stars[i]
		var ts := _track(create_tween())
		ts.tween_interval(t_m + 0.15)
		star.pivot_offset = star.size * 0.5
		if ok:
			ts.tween_callback(func() -> void:
				Sfx.play(Sfx.STAR_POP)
				star.scale = Vector2.ONE * 0.3)  # keep-code: pose hoạt cảnh runtime (tween)
			ts.tween_property(star, "scale", Vector2(1.4, 1.4), 0.14) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			ts.tween_property(star, "scale", Vector2.ONE, 0.1)
		else:
			for r in [-0.3, 0.3, -0.2, 0.0]:
				ts.tween_property(star, "rotation", float(r), 0.05)
		t_m += 0.16

	# bút chì GÃY
	var t_l := t_m + 0.15
	_fade_in(fx_pencil_card, t_l, 0.95)
	if pencils != null and _charged:
		pencils.play_lost_effect(t_l + 0.25)

	# nút: hiện; "Chơi lại" thở nhẹ mời bấm
	var t_b := t_l + 0.4
	_fade_in(fx_buttons, t_b, 0.9)
	if btn_retry != null and _can_play():
		btn_retry.pivot_offset = btn_retry.size * 0.5
		var tp := _track(create_tween())
		tp.tween_interval(t_b + 0.4)
		tp.tween_callback(func() -> void:
			var loop := _track(create_tween().set_loops())
			loop.tween_property(btn_retry, "scale", Vector2(1.05, 1.05), 0.7) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			loop.tween_property(btn_retry, "scale", Vector2.ONE, 0.7) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT))


func _count_percent(v: float) -> void:
	label_percent.text = "%d%%" % int(round(v))


## Hạt tro ~7–16px bất kể kích thước ảnh fx_sparkle
func _size_ash() -> void:
	if fx_ash.texture == null:
		return
	var w := float(maxi(fx_ash.texture.get_width(), 1))
	fx_ash.scale_amount_min = 7.0 / w
	fx_ash.scale_amount_max = 16.0 / w


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
