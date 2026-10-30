class_name ChapterGateNode
extends Node2D
## ============================================================================
## Node: ChapterGateNode — CỔNG VÒM nằm TRÊN ĐƯỜNG giữa màn cuối chương này và màn đầu chương kế
## (nodes/main/chapter_gate.tscn). Art lấy từ `gate-open.svg` → spritesheet 30 khung
## (`assets/images-png/level_selector/gate_sheet.png`, tạo bằng `gen/gen_gate_sheet.py`):
##   khung 0  = cổng ĐÓNG + ổ khoá · khung 29 = cổng MỞ, thấy ánh sáng bên trong.
##
## · LOCKED — chưa đủ sao: ổ khoá + "8/24" (bấm ⇒ `play_reject()` lắc + đỏ nhẹ, KHÔNG mở popup)
## · READY  — đủ sao: ổ khoá + "MỞ" (ổ khoá rung nhẹ; bấm ⇒ `pressed` ⇒ LevelSection mở khoá luôn)
## · OPEN   — đã mở: khung cuối
## `play_open()` : ổ khoá bật mở + rơi → 2 cánh trượt ra → ánh sáng; kèm quầng sáng, vòng sáng và tia lấp lánh.
## `play_reject()`: lắc ngang tắt dần + nháy đỏ + rung máy (từ chối).
## Bấm ⇒ `pressed(chapter_id)` (chương PHÍA TRÊN cổng). Nhãn "CHƯƠNG n" nằm ngay DƯỚI cửa.
## ============================================================================

signal pressed(chapter_id: int)
signal opened

enum State { LOCKED, READY, OPEN }

const INK := Color("0F3B5F")  # keep-code: màu vẽ thủ công của component (không thuộc theme tĩnh)
const GOLD := Color("ECAD2E")  # keep-code: màu vẽ thủ công của component (không thuộc theme tĩnh)
const GLOW := Color("FFD66B")  # keep-code: màu vẽ thủ công của component (không thuộc theme tĩnh)
const FRAMES := 30
const OPEN_SECONDS := 1.4
## Thời gian chờ thêm sau khi cửa mở xong để quầng sáng kịp lan rồi mới sang bước kế
const OPEN_HOLD := 0.35
## Cổng cao ~96 px, rộng ~86 px (khớp nút màn)
const DOOR_W := 78.0
const DOOR_H := 94.0
const BASE_DROP := 10.0
const LABEL_Y := 56.0

@export var hit: Button = null
@export var visual: Node2D = null
@export var art: Sprite2D = null
@export var overlay: Node2D = null
@export var sparks: CPUParticles2D = null

var chapter_id := 0
var _state := State.LOCKED
var _own := 0
var _need := 0
var _open_t := 0.0     # 0 = đóng · 1 = mở hết (theo khung hình)
var _glow := 0.0       # độ sáng quầng sau cổng
var _ring := 0.0       # vòng sáng lan ra (0..1)
var _busy := false
var _show_open_word := false   # true = đủ Sao (hiện "MỞ" thay vì "8/24") — nhớ lại để chữ không đổi giữa lúc mờ dần
var _tween: Tween = null
var _idle: Tween = null


func _ready() -> void:
	# Dây `Hit.pressed` (nút bấm) + `Overlay.draw` (vẽ chữ/quầng) khai trong nodes/main/chapter_gate.tscn
	_setup_sparks()
	_apply_frame()


func setup(p_chapter_id: int, own: int, need: int, state: State) -> void:
	chapter_id = p_chapter_id
	_own = own
	_need = need
	_state = state
	_show_open_word = state == State.READY
	_open_t = 1.0 if state == State.OPEN else 0.0
	_glow = 0.25 if state == State.OPEN else 0.0
	_apply_frame()
	_update_idle()
	queue_redraw()
	if overlay != null:
		overlay.queue_redraw()


## Mở cửa có animation (khung 0 → 29) + hiệu ứng. Xong phát `opened`.
func play_open() -> void:
	if _tween != null:
		_tween.kill()
	_stop_idle()
	_state = State.OPEN
	_busy = true
	_open_t = 0.0
	_glow = 0.0
	_ring = 0.0
	_apply_frame()
	_tween = create_tween()
	_tween.tween_method(_set_open_t, 0.0, 1.0, OPEN_SECONDS)
	# Quầng sáng bừng lên lúc 2 cánh cửa bắt đầu hé (~60% thời gian) rồi lắng lại
	_tween.parallel().tween_method(_set_glow, 0.0, 1.0, OPEN_SECONDS * 0.35).set_delay(OPEN_SECONDS * 0.55)
	_tween.parallel().tween_method(_set_ring, 0.0, 1.0, OPEN_SECONDS * 0.6).set_delay(OPEN_SECONDS * 0.55)
	_tween.parallel().tween_callback(_burst_sparks).set_delay(OPEN_SECONDS * 0.58)
	_tween.tween_method(_set_glow, 1.0, 0.25, OPEN_HOLD)
	_tween.tween_callback(func() -> void:
		_busy = false
		opened.emit())


## Từ chối (chưa đủ Sao): lắc ngang tắt dần + nháy đỏ + rung máy
func play_reject() -> void:
	if _busy or visual == null:
		return
	_busy = true
	_stop_idle()
	if _tween != null:
		_tween.kill()
	Input.vibrate_handheld(45)
	_tween = create_tween()
	_tween.tween_method(_set_shake, 0.0, 1.0, 0.45)
	_tween.parallel().tween_property(visual, "modulate", Color(1.0, 0.62, 0.62), 0.08)
	_tween.parallel().tween_property(visual, "modulate", Color.WHITE, 0.3).set_delay(0.12)
	_tween.tween_callback(func() -> void:
		visual.position = Vector2.ZERO  # keep-code: pose hoạt cảnh runtime (tween)
		visual.rotation = 0.0  # keep-code: pose hoạt cảnh runtime (tween)
		visual.modulate = Color.WHITE  # keep-code: màu theo dữ liệu (runtime)
		_busy = false
		_update_idle())


func is_busy() -> bool:
	return _busy


func _set_shake(p: float) -> void:
	var decay := 1.0 - p
	var wave := sin(p * TAU * 4.0)
	visual.position = Vector2(wave * 7.0 * decay, 0.0)
	visual.rotation = wave * 0.05 * decay


func _set_open_t(value: float) -> void:
	_open_t = value
	_apply_frame()
	if overlay != null:
		overlay.queue_redraw()


func _set_glow(value: float) -> void:
	_glow = value
	queue_redraw()


func _set_ring(value: float) -> void:
	_ring = value
	queue_redraw()


func _apply_frame() -> void:
	if art != null:
		art.frame = clampi(roundi(_open_t * float(FRAMES - 1)), 0, FRAMES - 1)


func _on_hit_pressed() -> void:
	if _busy:
		return
	Sfx.play(Sfx.BTN_CLICK)
	pressed.emit(chapter_id)


## Đủ Sao nhưng chưa mở: ổ khoá "rung nhẹ" mời bấm (vòng lặp nhỏ, tắt khi bắt đầu mở/từ chối)
func _update_idle() -> void:
	_stop_idle()
	if _state != State.READY or visual == null or not is_inside_tree():
		return
	_idle = create_tween().set_loops()
	_idle.tween_property(visual, "scale", Vector2(1.04, 1.04), 0.7).set_trans(Tween.TRANS_SINE)
	_idle.tween_property(visual, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_SINE)


func _stop_idle() -> void:
	if _idle != null:
		_idle.kill()
		_idle = null
	if visual != null:
		visual.scale = Vector2.ONE  # keep-code: pose hoạt cảnh runtime (tween)


# ---------------------------------------------------------------------------
# Hiệu ứng
# ---------------------------------------------------------------------------
func _setup_sparks() -> void:
	if sparks == null:
		return
	var tex := GradientTexture2D.new()
	tex.width = 14
	tex.height = 14
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color(1, 0.95, 0.7, 1), Color(1, 0.8, 0.3, 0.9), Color(1, 0.7, 0.2, 0)])
	grad.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	tex.gradient = grad
	sparks.texture = tex
	sparks.position = Vector2(0, -4)  # keep-code: pose hoạt cảnh runtime (tween)
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	fade.offsets = PackedFloat32Array([0.4, 1.0])
	sparks.color_ramp = fade


func _burst_sparks() -> void:
	if sparks != null:
		sparks.restart()
		sparks.emitting = true


## Quầng sáng + vòng sáng nằm SAU cổng (vẽ ở node gốc, dưới Sprite)
func _draw() -> void:
	if _glow > 0.01:
		var c := Vector2(0, -2)
		for k in 7:
			var f := float(k) / 7.0
			var r := DOOR_W * (0.55 + f * 0.75)
			draw_circle(c, r, Color(GLOW.r, GLOW.g, GLOW.b, 0.20 * _glow * (1.0 - f)))
		# Tia sáng toả ra từ cửa (chỉ khi đang bừng sáng, cổng đã mở yên tĩnh thì chỉ còn quầng)
		for i in (8 if _glow > 0.45 else 0):
			var a := -PI * 0.5 + (float(i) - 3.5) * 0.34
			var d := Vector2(cos(a), sin(a))
			draw_line(c + d * DOOR_W * 0.55, c + d * DOOR_W * (0.8 + 0.5 * _glow),
				Color(GLOW.r, GLOW.g, GLOW.b, 0.55 * _glow), 3.0, true)
	if _ring > 0.0 and _ring < 1.0:
		draw_arc(Vector2(0, -2), DOOR_W * (0.55 + _ring * 0.95), 0.0, TAU, 48,
			Color(GLOW.r, GLOW.g, GLOW.b, 0.7 * (1.0 - _ring)), 4.0 * (1.0 - _ring) + 1.0, true)
	_draw_chapter_label()


## Chữ "8/24" / "MỞ" đè lên cánh cửa (mờ dần khi ổ khoá rơi) — vẽ trong `Overlay` (nằm TRÊN Sprite)
func _draw_overlay() -> void:
	var fade := clampf(1.0 - _open_t * 3.5, 0.0, 1.0)
	if fade <= 0.0 or overlay == null:
		return
	var font := ThemeDB.fallback_font
	var text := tr("STR_MAIN_GATE_OPEN") if _show_open_word or _need <= 0 else "%d/%d" % [_own, _need]
	var pos := Vector2(-DOOR_W * 0.5, 38.0)
	var col := Color(1, 1, 1, fade)
	var edge := Color(0.239, 0.137, 0.078, fade)   # nâu #3D2314 như viền cổng
	overlay.draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, DOOR_W, 16, 6, edge)
	overlay.draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, DOOR_W, 16, col)


## Nhãn "CHƯƠNG n" ngay DƯỚI cửa
func _draw_chapter_label() -> void:
	if chapter_id <= 0:
		return
	var text := tr("STR_MAIN_CHAPTER_CHIP").format([chapter_id])
	var font := ThemeDB.fallback_font
	var box := Rect2(Vector2(-44.0, LABEL_Y), Vector2(88.0, 24.0))
	var sb := StyleBoxFlat.new()  # keep-code: stylebox của hiệu ứng vẽ runtime
	sb.bg_color = Color(1, 1, 1, 1)
	sb.border_color = Color("E4DCC6")
	sb.set_border_width_all(2)  # keep-code: stylebox của hiệu ứng vẽ runtime
	sb.set_corner_radius_all(12)  # keep-code: stylebox của hiệu ứng vẽ runtime
	draw_style_box(sb, box)
	draw_string(font, box.position + Vector2(0, 17.0), text, HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 14, INK)
	draw_string(font, box.position + Vector2(0.7, 17.0), text, HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 14, INK)
