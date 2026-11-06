class_name ChapterGateNode
extends Node2D
const LocalizationManagerScript := preload("res://scripts/autoload/LocalizationManager.gd")
## ============================================================================
## ChapterGateNode — CỔNG chương trên bản đồ đường liền
## (nodes/main/chapter_gate.tscn · script: scripts/ui/widgets/main/chapter_gate.gd) — `LevelMap._build_gate` dựng rồi gọi `setup()`.
##
## ART KHÔNG CÓ CHỮ: bìa sổ (art `lv_gate_*`) chỉ vẽ khung nhãn + viên thuốc tiến độ trống.
## Chữ "CHƯƠNG" · số chương · "own/need" là 3 `Label` nằm trong node `Body/Cover` và được ghi
## bằng script (`_apply_texts`) nên dịch được, đổi số được, không phải xuất lại art.
##
## Quy ước của project: CẤU HÌNH TĨNH nằm trong `chapter_gate.tscn` — node con, texture theo
## trạng thái, animation (`open` · `pulse` · `RESET`) và dây signal khai trong scene;
## script chỉ bind bằng `@export` rồi nhận dữ liệu qua `setup()`.
##
## Trạng thái (đổi qua `setup`):
##   LOCKED → bìa đóng, dây thun + ổ khoá; tiến độ "own/need" màu navy
##   READY  → như LOCKED nhưng đủ Sao: tiến độ màu xanh + "thở" (`pulse`) nhắc người chơi bấm
##   OPEN   → cổng đã mở (art `lv_gate_open`, không còn chữ), nút bị `disabled`
##
## Mở cổng (`play_open`): đổi sang `Body/Sheet` (spritesheet `lv_gate_open_sheet`, 7×6 khung,
## 12 khung/giây) và AnimationPlayer `open` chạy 3 việc CÙNG LÚC: nhảy `Sheet.frame`, co/nhấc
## `Cover` (cả 3 chữ) đúng theo bìa trong art, ẩn chữ khi bìa lật qua gáy sổ. Các key của `Cover`
## đặt ĐÚNG tại thời điểm từng khung hình (nhảy bậc) nên chữ không bao giờ lệch khỏi bìa.
## ============================================================================

## Người chơi bấm cổng (LOCKED / READY) — LevelMap chuyển thành popup mở khoá hoặc `reject_gate`
## Scene contract
## Exports:  body, button, sheet, cover, lbl_chapter, lbl_number, lbl_progress, anim, tex_open, key_chapter, fallback_chapter, fit_width_chapter, fit_width_number, fit_width_progress, color_progress_locked, color_progress_ready
## Emits:    pressed, opened
## Handlers wired in scene: _on_anim_finished, _on_button_hover_changed, _on_button_press_changed, _on_button_pressed
## Subscribes in code (EventBus/Model): loc

signal pressed(chapter_id: int)
## Animation mở cổng xong (cổng đã chuyển sang OPEN)
signal opened

enum State {
	LOCKED,  ## Chưa đủ Sao
	READY,   ## Đủ Sao nhưng chưa mở
	OPEN,    ## Đã mở
}

## Node con — bind bằng `@export` trong `chapter_gate.tscn`
@export_group("Node binding")
@export var body: Node2D = null
@export var button: TextureButton2D = null
## Spritesheet mở cổng (chỉ hiện trong lúc `open` chạy)
@export var sheet: Sprite2D = null
## Gốc của 3 chữ — đặt tại GÁY SỔ để co/nhấc theo bìa
@export var cover: Node2D = null
@export var lbl_chapter: Label = null
@export var lbl_number: Label = null
@export var lbl_progress: Label = null
@export var anim: AnimationPlayer = null

@export_group("Art")
## Art cổng ĐÃ MỞ — gán trong scene
@export var tex_open: Texture2D = null

@export_group("Chữ trên bìa")
## Khoá dịch của chữ "CHƯƠNG"; chưa có bản dịch thì dùng `fallback_chapter`
@export var key_chapter := "STR_CHAPTER_GATE_LABEL"
@export var fallback_chapter := "CHƯƠNG"
@export_range(6, 40, 1) var size_chapter := 11
@export_range(6, 60, 1) var size_number := 24
@export_range(6, 40, 1) var size_progress := 15
## Bề rộng tối đa (px) — chữ dài hơn thì tự thu nhỏ cho vừa khung giấy / viên thuốc
@export var fit_width_chapter := 50.0
@export var fit_width_number := 46.0
@export var fit_width_progress := 46.0
@export var color_progress_locked := Color(0.0863, 0.2745, 0.3882, 1.0)
@export var color_progress_ready := Color(0.2431, 0.5608, 0.1137, 1.0)

@export_group("Mở cổng")
## Tốc độ phát animation `open` (1.0 = nguyên bản 3,5 giây; 2.0 ≈ 1,75 giây)
@export_range(0.5, 4.0, 0.1) var open_speed := 2.0

@export_group("Nội dung trôi theo nút")
## Art nút vẽ sẵn độ lệch: pressed chìm 10 đơn vị thiết kế = 5px hiển thị; hover nâng 3 = 1.5px.
## Bù đúng chừng đó cho `Cover` để chữ dính chặt vào bìa.
@export_range(0.0, 12.0, 0.5) var content_press_sink := 5.0
@export_range(-6.0, 6.0, 0.5) var content_hover_lift := -1.5
@export_range(0.01, 0.5, 0.01) var content_follow_sec := 0.08

var chapter_id: int = 0
var own: int = 0
var need: int = 0
var state: State = State.LOCKED

var _opening := false
var _skin_default: Array[Texture2D] = []
var _cover_base := Vector2.ZERO
var _button_down := false
var _button_hovered := false
var _content_tween: Tween = null


func _ready() -> void:
	if cover != null:
		_cover_base = cover.position
	_connect_locale_signal()


## Thiết lập cổng với dữ liệu từ LevelMap (`p_own` = Sao đang có, `p_need` = Sao cần)
func setup(p_chapter: int, p_own: int, p_need: int, p_state: State) -> void:
	chapter_id = p_chapter
	own = p_own
	need = p_need
	state = p_state
	_opening = false
	_apply_state_look()
	_apply_texts()


# ---------------------------------------------------------------------------
# Chữ — toàn bộ chữ trên cổng được ghi ở đây
# ---------------------------------------------------------------------------
func _apply_texts() -> void:
	if lbl_chapter != null:
		lbl_chapter.text = _tr_or(key_chapter, fallback_chapter)
		_fit_font(lbl_chapter, size_chapter, fit_width_chapter)
	if lbl_number != null:
		lbl_number.text = str(chapter_id)
		_fit_font(lbl_number, size_number, fit_width_number)
	if lbl_progress != null:
		lbl_progress.text = "%d/%d" % [own, need]
		_fit_font(lbl_progress, size_progress, fit_width_progress)
		var ready := state == State.READY
		lbl_progress.add_theme_color_override("font_color", color_progress_ready if ready else color_progress_locked)


## Dịch theo khoá; chưa có bản dịch (Godot trả lại chính khoá) thì dùng chữ dự phòng
func _tr_or(key: String, fallback: String) -> String:
	var text := TranslationServer.translate(key)
	return fallback if text == key else text


## Thu nhỏ cỡ chữ cho vừa `max_width` (nhãn dịch sang ngôn ngữ khác có thể dài hơn "CHƯƠNG")
func _fit_font(label: Label, base_size: int, max_width: float) -> void:
	var font: Font = label.get_theme_font(&"font")
	var font_px := base_size
	if font != null:
		while font_px > 7 and font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_px).x > max_width:
			font_px -= 1
	label.add_theme_font_size_override(&"font_size", font_px)


## Đổi ngôn ngữ ⇒ viết lại chữ
func _connect_locale_signal() -> void:
	var loc: Node = Svc.loc() as LocalizationManagerScript
	if loc != null and loc.has_signal("locale_changed") \
			and not loc.locale_changed.is_connected(_on_locale_changed):  # keep-code: signal của AUTOLOAD / node sinh lúc chạy — không phải node tĩnh
		loc.locale_changed.connect(_on_locale_changed)  # EXCEPTION(R3-keep): signal của AUTOLOAD / node sinh lúc chạy — không phải node tĩnh


func _on_locale_changed(_locale: String) -> void:
	_apply_texts()


# ---------------------------------------------------------------------------
# Dáng cổng theo trạng thái
# ---------------------------------------------------------------------------
func _apply_state_look() -> void:
	var is_open := state == State.OPEN
	if _content_tween != null and _content_tween.is_valid():
		_content_tween.kill()
	if button != null:
		if _skin_default.is_empty():
			_skin_default = [button.texture_normal, button.texture_hover,
				button.texture_pressed, button.texture_disabled]
		if is_open and tex_open != null:
			button.texture_normal = tex_open
			button.texture_hover = tex_open
			button.texture_pressed = tex_open
			button.texture_disabled = tex_open
		elif not _skin_default.is_empty():
			button.texture_normal = _skin_default[0]
			button.texture_hover = _skin_default[1]
			button.texture_pressed = _skin_default[2]
			button.texture_disabled = _skin_default[3]
		button.disabled = is_open
		button.visible = true
	if sheet != null:
		sheet.visible = false
		sheet.frame = 0
	if cover != null:
		cover.visible = not is_open
		cover.scale = Vector2.ONE
		cover.position = _cover_base
	if body != null:
		body.scale = Vector2.ONE
		body.position = Vector2.ZERO
		body.modulate = Color.WHITE
	if anim != null and anim.current_animation == &"pulse" and state != State.READY:
		anim.stop()
	if state == State.READY:
		play_pulse()


## "Thở" cho cổng ĐỦ SAO (animation `pulse` khai trong .tscn)
func play_pulse() -> void:
	if anim != null and anim.has_animation(&"pulse"):
		anim.play(&"pulse")


# ---------------------------------------------------------------------------
# Mở cổng: ổ khoá mở + rơi → dây thun tuột → bìa lật sang trái → sao bung (art trong spritesheet)
# ---------------------------------------------------------------------------
func play_open() -> void:
	if state == State.OPEN or _opening:
		opened.emit.call_deferred()   # LevelMap `await gate.opened` ngay sau khi gọi — phát trễ 1 nhịp cho kịp
		return
	_opening = true
	if anim != null:
		anim.stop()
	if _content_tween != null and _content_tween.is_valid():
		_content_tween.kill()
	if body != null:
		body.scale = Vector2.ONE
	if cover != null:
		cover.position = _cover_base
	if button != null:
		button.disabled = true
	if anim != null and anim.has_animation(&"open"):
		anim.play(&"open", -1.0, open_speed)
	else:
		_finish_open()


func _finish_open() -> void:
	_opening = false
	state = State.OPEN
	_apply_state_look()
	_apply_texts()
	opened.emit()


## Cổng bị từ chối (chưa đủ Sao): lắc ngang + nháy đỏ (art không đổi)
func play_reject() -> void:
	if body == null or _opening or state == State.OPEN:
		return
	body.position = Vector2.ZERO
	body.modulate = Color(1.0, 0.55, 0.5, 1.0)
	var shake := create_tween()
	for dx in [-5.0, 5.0, -4.0, 4.0, -2.0, 0.0]:
		shake.tween_property(body, "position:x", dx, 0.05)
	var flash := create_tween()
	flash.tween_property(body, "modulate", Color.WHITE, 0.3)


# ---------------------------------------------------------------------------
# Dây signal khai trong .tscn
# ---------------------------------------------------------------------------
func _on_button_pressed() -> void:
	if state == State.OPEN or _opening:
		return
	pressed.emit(chapter_id)


func _on_anim_finished(anim_name: StringName) -> void:
	if anim_name == &"open":
		_finish_open()


## `Body/Button` phát khi trạng thái nhấn giữ đổi
func _on_button_press_changed(is_down: bool) -> void:
	_button_down = is_down
	_follow_button_art()


## `Body/Button` phát khi trạng thái rê chuột đổi
func _on_button_hover_changed(is_hovered: bool) -> void:
	_button_hovered = is_hovered
	_follow_button_art()


## Trôi `Cover` (3 chữ) theo đúng trạng thái hiển thị của art nút (pressed > hover > thường)
func _follow_button_art() -> void:
	if cover == null or _opening:
		return
	var target := 0.0
	if _button_down:
		target = content_press_sink
	elif _button_hovered:
		target = content_hover_lift
	if _content_tween != null and _content_tween.is_valid():
		_content_tween.kill()
	if not is_inside_tree():
		return
	_content_tween = create_tween()
	_content_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_content_tween.tween_property(cover, "position", _cover_base + Vector2(0.0, target), content_follow_sec)
