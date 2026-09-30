class_name BaseTutorial
extends Control

## ============================================================================
## BaseTutorial: Node nền tảng cho mọi Tutorial Scene tương tác.
##   - Backdrop mờ + Spotlight (NinePatchRect, art `tutorial_spotlight.svg`)
##   - DialogBubble giấy ô ly + HandPointer (art `tutorial_pointer.svg`)
##   - Thanh điều hướng: chấm tiến độ (● ● ○ ○), Tiếp tục, Bỏ qua
##   - Khay BoardHost chứa bàn cờ mini của từng bài
##   - Phản hồi thử lại vô hạn, rung khi sai, pháo giấy khi đúng
##
## TOÀN BỘ node/hình dáng khai trong `nodes/tutorials/base_tutorial.tscn`; script chỉ
## bind qua `@export` (NODE) và điều khiển. KHÔNG `new()`/`draw_*` trong code.
##
## HIỆU ỨNG (dùng `UIAnim` của game): mở bài có hoạt cảnh (nền tối hiện dần · thẻ thoại
## trượt lên · bàn mini + từng ô nở ra so le), đổi bước có fade nhẹ, vòng sáng TRƯỢT sang
## mục tiêu mới rồi "thở", đúng thì pháo giấy nhỏ + chữ nổi, sai thì nháy đỏ + rung.
## ============================================================================

signal step_changed(step_idx: int)
signal tutorial_completed(tutorial_id: String)
signal tutorial_skipped(tutorial_id: String, all: bool)

@export var tutorial_id: String = ""
## Blueprint steps: Mảng resource chỉnh trong Inspector, mỗi phần tử là BlueprintStep.
@export var blueprint_steps: Array[BlueprintStep] = []
var current_step_index: int = 0
var steps_data: Array = []
var is_active: bool = false

# --- NODE (bind trong .tscn) -------------------------------------------------
@export var backdrop: ColorRect = null
@export var spotlight: NinePatchRect = null
@export var board_host: Control = null
@export var dialog_bubble: Control = null
@export var lbl_title: Label = null
@export var dots_container: HBoxContainer = null
@export var lbl_message: Label = null
@export var nav_bar: Control = null
@export var btn_skip_all: BaseButton = null
@export var btn_skip: BaseButton = null
@export var btn_next: BaseButton = null
@export var toast_label: Label = null
@export var anim_player: AnimationPlayer = null

var _auto_timer: SceneTreeTimer = null
var _spotlight_rect: Rect2 = Rect2()
var _spotlight_cell: Vector2i = Vector2i(-1, -1)
var _spotlight_node: Control = null
var _has_spotlight: bool = false

## --- HIỆU ỨNG (animation) ---------------------------------------------------
## Trễ giữa 2 ô bàn mini khi chạy hoạt cảnh mở bài
const CELL_ENTER_STAGGER := 0.045
## Thời lượng các hiệu ứng UI khai trong `base_tutorial.tscn` (khớp track của animation)
const TEXT_OUT_SECONDS := 0.1
const TOAST_IN_SECONDS := 0.22
const SPOTLIGHT_IN_SECONDS := 0.22
const SPOTLIGHT_OUT_SECONDS := 0.18
var _fx_spotlight: Tween = null
var _fx_toast: Tween = null
var _fx_message: Tween = null
var _entrance_played := false
## Số thứ tự lần toast gần nhất — timer mờ toast cũ không được tắt toast mới
var _toast_seq := 0
## Dữ liệu chờ của TextOutTimer / ToastTimer (thay cho bind trong code — dây khai trong .tscn)
var _pending_msg := ""
var _pending_title := ""
var _pending_toast_seq := 0

## AnimationPlayer phụ của scene (mỗi nhóm hiệu ứng 1 player để không tranh nhau):
## DialogAnim (chữ thoại) · TitleAnim (tiêu đề) · ToastAnim · SpotlightAnim
@onready var anim_dialog: AnimationPlayer = get_node_or_null("DialogAnim")
@onready var anim_title: AnimationPlayer = get_node_or_null("TitleAnim")
## Hẹn giờ chờ hiệu ứng UI — Timer khai trong `base_tutorial.tscn` (dây `timeout` cũng ở đó)
@onready var _text_out_timer: Timer = get_node_or_null("TextOutTimer")
@onready var _toast_timer: Timer = get_node_or_null("ToastTimer")
@onready var _spot_in_timer: Timer = get_node_or_null("SpotlightInTimer")
@onready var _spot_out_timer: Timer = get_node_or_null("SpotlightOutTimer")
@onready var anim_toast: AnimationPlayer = get_node_or_null("ToastAnim")
@onready var anim_spotlight: AnimationPlayer = get_node_or_null("SpotlightAnim")


func _play_anim_on(player: AnimationPlayer, anim_name: StringName) -> bool:
	if player == null or not player.has_animation(anim_name):
		return false
	player.play(anim_name)
	return true


func _ready() -> void:
	# Dây `Spotlight.resized → _on_spotlight_resized` khai trong `base_tutorial.tscn` (cùng scene)
	_init_tutorial()
	# Ưu tiên 1: blueprint_steps được gán trong editor
	if steps_data.is_empty() and blueprint_steps.size() > 0:
		setup_steps(blueprint_steps)
	# Ưu tiên 2: fallback từ code — mỗi tutorial con override _get_default_steps()
	if steps_data.is_empty():
		var defaults := _get_default_steps()
		if defaults.size() > 0:
			setup_steps(defaults)
	_wire_button_effects()
	play_entrance()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_refresh_overlay_positions.call_deferred()


func _refresh_overlay_positions() -> void:
	if not is_inside_tree():
		return
	if _has_spotlight:
		_apply_spotlight()
	# KHÔNG đụng vào hoạt cảnh con trỏ ở đây!
	# Trước đây hàm này gọi `_update_cursor_demonstration()` ⇒ mỗi sự kiện resize lại
	# `stop_cursor_animation()` (bước không khai báo pointer_drag/pointer_tap) hoặc
	# khởi động lại drag (bước có khai báo) ⇒ con trỏ ĐỨNG HÌNH suốt lúc kéo cửa sổ.
	# Demo con trỏ tự chạy vòng lặp riêng (blueprint loop hoặc chu kỳ của script bài học),
	# bàn tutorial có kích thước thiết kế cố định nên không cần đặt lại vị trí.


## Override trong scene con để nạp steps riêng
func _init_tutorial() -> void:
	pass


## Override để cung cấp steps mặc định từ code khi editor chưa set blueprint_steps.
## Trả về Array[BlueprintStep] hoặc Array[Dictionary].
## Editor blueprint_steps luôn được ưu tiên hơn kết quả của hàm này.
func _get_default_steps() -> Array:
	return []


## Gắn hiệu ứng nhấn nảy cho 3 nút điều hướng (giống mọi nút khác trong game)
func _wire_button_effects() -> void:
	for btn in [btn_skip_all, btn_skip, btn_next]:
		var base_button := btn as BaseButton
		if base_button != null:
			UIAnim.attach_press_bounce(base_button)


## Hoạt cảnh MỞ BÀI: nền tối hiện dần · thẻ thoại trượt lên · bàn mini + từng ô nở ra so le
func play_entrance() -> void:
	Sfx.play(Sfx.PAGE_TURN)
	if anim_player != null and anim_player.has_animation("play_entrance"):
		anim_player.play("play_entrance")
	else:
		if backdrop != null:
			backdrop.modulate.a = 0.0
			backdrop.create_tween().tween_property(backdrop, "modulate:a", 1.0, 0.24)
		var bubble := dialog_bubble as Control
		if bubble != null and not (bubble.get_parent() is Container):
			UIAnim.play_slide_in(bubble, Vector2(0, 42), 0.06, 0.32)
		if board_host != null:
			UIAnim.play_pop_in(board_host, 0.05, 0.94, 0.3)
	var delay := 0.0
	for cell in board_cells():
		cell.play_entrance(0.12 + delay)
		delay += CELL_ENTER_STAGGER
	_entrance_played = true


## Danh sách ô bàn mini của bài này (dùng cho hiệu ứng so le) — con của BoardHost
func board_cells() -> Array[MazeCell]:
	var out: Array[MazeCell] = []
	if board_host == null:
		return out
	for child in board_host.find_children("*", "MazeCell", true, false):
		out.append(child as MazeCell)
	return out


func get_board_tutorial() -> BoardTutorial:
	if board_host == null:
		return null
	return board_host.find_child("BoardTutorial", true, false) as BoardTutorial


func get_board_cell(coord: Vector2i) -> MazeCell:
	var bt := get_board_tutorial()
	if bt != null:
		return bt.get_cell(coord)
	for cell in board_cells():
		if cell.grid_pos == coord:
			return cell
	return null


func _cell_to_board_pos(coord: Vector2i) -> Vector2:
	var cell := get_board_cell(coord)
	if cell != null and board_host != null:
		return cell.get_global_rect().get_center() - board_host.global_position
	return Vector2.ZERO


## Pháo giấy nhỏ khi thắng bài: từng ô sáng lên so le
func play_cells_win() -> void:
	var delay := 0.0
	for cell in board_cells():
		cell.play_win(delay)
		delay += 0.05


## Chữ nổi trên bàn mini ("+2" · "✓"…) — `board_pos` theo toạ độ TRONG BoardHost
func spawn_board_text(text: String, board_pos: Vector2, color := Color(0.133, 0.298, 0.427)) -> void:
	if board_host == null:
		return
	UIAnim.spawn_floating_text(board_host, text, board_pos, color)


## Nháy đỏ 1 node rồi trả lại màu cũ (tường · HUD…)
## (GIỮ tween) Node đích bất kỳ do nơi gọi truyền vào lúc chạy — không khai trước được trong scene.
func flash_fail(target: Control) -> void:
	if target == null:
		return
	var old := target.modulate
	target.modulate = Color(1.0, 0.45, 0.42, old.a)
	target.create_tween().tween_property(target, "modulate", old, 0.4)


## Đổi nội dung thẻ thoại kèm nhịp fade nhẹ (cha là Control nên dời vị trí được)
## Hiệu ứng chữ khai trong `base_tutorial.tscn` (DialogAnim/TitleAnim); mã đây chỉ
## canh nhịp (chờ fade xong mới đổi chữ) và chạy fallback tween nếu scene thiếu player.
func _animate_step_text(new_msg: String, new_title: String) -> void:
	if _fx_message != null and _fx_message.is_valid():
		_fx_message.kill()
	var was_visible := _entrance_played and lbl_message.modulate.a > 0.3
	if was_visible and _play_anim_on(anim_dialog, &"text_out"):
		# Chờ chữ mờ xong mới đổi nội dung — Timer khai trong `base_tutorial.tscn`
		_pending_msg = new_msg
		_pending_title = new_title
		if _text_out_timer != null:
			_text_out_timer.start()
		else:
			# Fallback khi scene thiếu TextOutTimer
			get_tree().create_timer(TEXT_OUT_SECONDS).timeout.connect(_apply_step_text_and_slide.bind(new_msg, new_title))
		return
	if was_visible:
		# Fallback khi scene thiếu DialogAnim
		_fx_message = lbl_message.create_tween()
		_fx_message.tween_property(lbl_message, "modulate:a", 0.0, 0.1)
		_fx_message.tween_callback(func() -> void:
			lbl_message.text = new_msg
			lbl_message.position = Vector2.ZERO
			if lbl_title.text != new_title:
				lbl_title.text = new_title
				UIAnim.play_pop_in(lbl_title, 0.0, 0.88, 0.24)
			_fx_message = UIAnim.play_slide_in(lbl_message, Vector2(0, 10), 0.0, 0.22)
		)
		return
	# Lần đầu hoặc đang ẩn: set text ngay rồi cho chữ trượt lên
	lbl_message.text = new_msg
	lbl_message.position = Vector2.ZERO
	lbl_title.text = new_title
	if not _play_anim_on(anim_title, &"title_pop"):
		UIAnim.play_pop_in(lbl_title, 0.0, 0.88, 0.24)
	if not _play_anim_on(anim_dialog, &"text_in_first"):
		_fx_message = UIAnim.play_slide_in(lbl_message, Vector2(0, 10), 0.06, 0.24)


## TextOutTimer kêu (chữ cũ đã mờ xong) → đổi sang nội dung bước mới.
## Dây `timeout → _on_text_out_done` khai trong `base_tutorial.tscn`.
func _on_text_out_done() -> void:
	_apply_step_text_and_slide(_pending_msg, _pending_title)


## Sau khi fade chữ cũ xong: đổi nội dung, pop tiêu đề (nếu đổi) + cho chữ trượt lên
func _apply_step_text_and_slide(new_msg: String, new_title: String) -> void:
	if lbl_message == null or not is_instance_valid(lbl_message):
		return
	lbl_message.text = new_msg
	lbl_message.position = Vector2.ZERO
	if lbl_title.text != new_title:
		lbl_title.text = new_title
		if not _play_anim_on(anim_title, &"title_pop"):
			UIAnim.play_pop_in(lbl_title, 0.0, 0.88, 0.24)
	if not _play_anim_on(anim_dialog, &"text_in"):
		_fx_message = UIAnim.play_slide_in(lbl_message, Vector2(0, 10), 0.0, 0.22)


func setup_steps(p_steps: Array) -> void:
	steps_data = []
	for step in p_steps:
		if step is BlueprintStep:
			steps_data.append(step.to_dictionary())
		elif step is Dictionary:
			steps_data.append(step.duplicate(true))
	current_step_index = 0
	_update_dots()
	if steps_data.size() > 0:
		show_step(0)


func _normalize_step_data(data: Dictionary) -> Dictionary:
	var out: Dictionary = data.duplicate(true)
	if data.has("spotlight_node") and data["spotlight_node"] is NodePath:
		var path: NodePath = data["spotlight_node"]
		if not path.is_empty():
			out["spotlight_node"] = get_node_or_null(path)
	if data.has("pointer_drag") and data["pointer_drag"] is Dictionary:
		var drag: Dictionary = data["pointer_drag"]
		if drag.has("from_cell") and drag.has("to_cell"):
			out["pointer_drag"] = drag.duplicate(true)
	return out


func _update_dots() -> void:
	if dots_container == null:
		return
	var dots := dots_container.get_children()
	for i in dots.size():
		var dot := dots[i] as Label
		if dot == null:
			continue
		dot.visible = i < steps_data.size()
		dot.text = "●"
		dot.add_theme_color_override(
			"font_color",
			Color("#2A2E33") if i == current_step_index else Color("#D4D8DD")
		)
		dot.scale = Vector2.ONE
		dot.modulate = Color.WHITE
		# Chấm đang ở bước hiện tại nảy lên cho dễ thấy
		if i == current_step_index and i < steps_data.size():
			UIAnim.play_pop_in(dot, 0.0, 0.55, 0.22)


func show_step(index: int) -> void:
	if index < 0 or index >= steps_data.size():
		return
	current_step_index = index
	_update_dots()

	var data: Dictionary = _normalize_step_data(steps_data[index])
	var msg_key: String = data.get("message_key", "")
	var tr_msg := tr(msg_key)
	if tr_msg == msg_key and data.has("fallback_text"):
		tr_msg = data["fallback_text"]
	var title_key: String = data.get("title_key", "STR_TUT_COMMON_TITLE")
	_animate_step_text(tr_msg, tr(title_key))
	if _entrance_played:
		Sfx.play(Sfx.BTN_WOOD_TAP)

	var advance_mode: String = data.get("advance_mode", "MANUAL")
	var is_last := (current_step_index == steps_data.size() - 1)
	btn_next.visible = (advance_mode == "MANUAL" or is_last)
	btn_next.text = tr("STR_TUT_COMMON_FINISH") if is_last else tr("STR_TUT_COMMON_NEXT")

	# Spotlight: trượt sang mục tiêu mới rồi "thở" nhẹ
	if data.has("spotlight_cell"):
		_has_spotlight = true
		_spotlight_cell = data["spotlight_cell"]
		_spotlight_node = null
	elif data.has("spotlight_node"):
		_has_spotlight = true
		_spotlight_node = data["spotlight_node"]
		_spotlight_cell = Vector2i(-1, -1)
	elif data.has("spotlight_rect"):
		_has_spotlight = true
		_spotlight_rect = data["spotlight_rect"]
		_spotlight_cell = Vector2i(-1, -1)
		_spotlight_node = null
	else:
		_has_spotlight = false
		_spotlight_cell = Vector2i(-1, -1)
		_spotlight_node = null
	_apply_spotlight()

	# Cursor demo animation via BoardTutorial
	_update_cursor_demonstration(data)

	# Auto advance if requested
	if data.has("auto_delay") and advance_mode == "AUTO":
		var delay: float = float(data["auto_delay"])
		get_tree().create_timer(delay).timeout.connect(func() -> void:
			if current_step_index == index and is_inside_tree():
				next_step()
		)

	step_changed.emit(current_step_index)
	_on_step_entered(index, data)


## Hook cho scene con xử lý khi vào step
func _on_step_entered(_index: int, _data: Dictionary) -> void:
	pass


func next_step() -> void:
	if current_step_index < steps_data.size() - 1:
		show_step(current_step_index + 1)
	else:
		complete_tutorial()


func prev_step() -> void:
	if current_step_index > 0:
		show_step(current_step_index - 1)


func complete_tutorial() -> void:
	stop_cursor_animation()
	tutorial_completed.emit(tutorial_id)


func skip_tutorial() -> void:
	stop_cursor_animation()
	tutorial_skipped.emit(tutorial_id, false)


func skip_all_tutorials() -> void:
	stop_cursor_animation()
	tutorial_skipped.emit(tutorial_id, true)


func show_fail_feedback(key: String, fallback_text: String = "") -> void:
	Sfx.play(Sfx.WALL_HIT)
	_show_toast(key, fallback_text, Color("#D9534F"), 1.3)
	# Rung thẻ thoại + loang đỏ nhẹ ở nền (như vết mực)
	if anim_player != null and anim_player.has_animation("fail_feedback"):
		anim_player.play("fail_feedback")
	else:
		shake_node(dialog_bubble, 0.25, 8.0)
		if backdrop != null:
			backdrop.color = Color(0.98, 0.88, 0.88, 1.0)
			backdrop.create_tween().tween_property(backdrop, "color", Color(0.969, 0.957, 0.937, 1.0), 0.45)


func show_success_feedback(key: String = "", fallback_text: String = "") -> void:
	Sfx.play(Sfx.STAR_POP)
	_show_toast(key, fallback_text, Color("#4CAE4C"), 0.95)


## Toast phản hồi: nở ra → giữ → mờ dần — animation "toast_in"/"toast_out" của scene
## (`ToastAnim`); mã chỉ canh nhịp giữ rồi mới chạy "toast_out".
func _show_toast(key: String, fallback_text: String, color: Color, hold: float) -> void:
	if toast_label == null:
		return
	var text := tr(key)
	if text == key:
		text = fallback_text if not fallback_text.is_empty() else "✓"
	toast_label.text = text
	toast_label.add_theme_color_override("font_color", color)
	if _fx_toast != null and _fx_toast.is_valid():
		_fx_toast.kill()
	toast_label.pivot_offset = toast_label.size * 0.5
	toast_label.scale = Vector2(0.86, 0.86)
	toast_label.modulate.a = 0.0
	_toast_seq += 1
	var seq := _toast_seq
	if _play_anim_on(anim_toast, &"toast_in"):
		# Giữ chữ toast `hold` giây rồi mới mờ — Timer khai trong `base_tutorial.tscn`
		_pending_toast_seq = seq
		if _toast_timer != null:
			_toast_timer.wait_time = TOAST_IN_SECONDS + hold
			_toast_timer.start()
		else:
			# Fallback khi scene thiếu ToastTimer
			get_tree().create_timer(TOAST_IN_SECONDS + hold).timeout.connect(_fade_toast_after.bind(seq))
		return
	# Fallback khi scene thiếu ToastAnim: một tween duy nhất như trước
	_fx_toast = toast_label.create_tween()
	_fx_toast.tween_property(toast_label, "modulate:a", 1.0, 0.16)
	_fx_toast.parallel().tween_property(toast_label, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_fx_toast.tween_interval(hold)
	_fx_toast.tween_property(toast_label, "modulate:a", 0.0, 0.3)


## Mờ toast SAU khi giữ xong — bỏ qua nếu đã có toast mới hơn chen vào
func _fade_toast_after(seq: int) -> void:
	if seq != _toast_seq or toast_label == null or not is_instance_valid(toast_label):
		return
	if not _play_anim_on(anim_toast, &"toast_out"):
		var tw := toast_label.create_tween()
		tw.tween_property(toast_label, "modulate:a", 0.0, 0.3)


## ToastTimer kêu (giữ chữ xong) → mờ toast. Dây khai trong `base_tutorial.tscn`.
func _on_toast_hold_done() -> void:
	_fade_toast_after(_pending_toast_seq)


## (GIỮ tween) Biên độ rung ngẫu nhiên theo tham số truyền vào lúc chạy (không bake được).
func shake_node(target: Node, duration: float = 0.25, amplitude: float = 8.0) -> void:
	if target == null or not (target is Control):
		return
	var ctrl: Control = target as Control
	var original_pos := ctrl.position
	var tween := create_tween()
	var steps := 4
	var step_time := duration / float(steps)
	for i in range(steps):
		var offset := Vector2(randf_range(-amplitude, amplitude), randf_range(-2, 2))
		tween.tween_property(ctrl, "position", original_pos + offset, step_time)
	tween.tween_property(ctrl, "position", original_pos, step_time)


## Toạ độ ghi trong dữ liệu step là toạ độ TRONG BoardHost; lớp phủ (Spotlight/HandPointer)
## là con của node gốc (BaseTutorial Control) → cần cộng vị trí THỰC của BoardHost so với gốc.
## Dùng global_position để đúng bất kể anchor/layout_mode của BoardHost.
func _board_to_overlay(p: Vector2) -> Vector2:
	if board_host == null:
		return p
	# Lấy top-left thực của BoardHost theo toạ độ GLOBAL, rồi chuyển về toạ độ LOCAL của BaseTutorial
	var board_global_tl := board_host.global_position
	var self_global_tl  := global_position
	var board_local_tl  := board_global_tl - self_global_tl
	return board_local_tl + p


## Đặt vòng sáng theo `spotlight_cell`, `spotlight_node` hoặc `spotlight_rect`
func _apply_spotlight() -> void:
	if spotlight == null:
		return
	if not _has_spotlight:
		_hide_spotlight()
		return

	var target: Rect2
	const CELL_SIZE_ANCHORING = Vector2(46,46)
	const CELL_SIZE_CENTERING = (CELL_SIZE_ANCHORING + Vector2(8,8))  / 2
	if _spotlight_cell != Vector2i(-1, -1):
		var cell := get_board_cell(_spotlight_cell)
		if cell != null:
			var grect := cell.get_global_rect()
			var lpos := grect.position - global_position
			target = Rect2(lpos - CELL_SIZE_CENTERING, grect.size + CELL_SIZE_ANCHORING)
		else:
			target = Rect2(_board_to_overlay(_spotlight_rect.position), _spotlight_rect.size)
	elif _spotlight_node != null and is_instance_valid(_spotlight_node):
		var grect := _spotlight_node.get_global_rect()
		var lpos := grect.position - global_position
		target = Rect2(lpos - Vector2(28, 28), grect.size + Vector2(46, 46))
	else:
		target = Rect2(_board_to_overlay(_spotlight_rect.position), _spotlight_rect.size)

	var was_visible := spotlight.visible
	spotlight.visible = true
	spotlight.scale = Vector2.ONE
	if was_visible:
		# Dừng MỌI hoạt cảnh cũ của vòng sáng (đang "thở" hoặc đang mờ dần) trước khi
		# trượt sang target mới — nếu để fade-out cũ chạy tiếp thì alpha sẽ bị kéo về 0.
		if anim_spotlight != null:
			anim_spotlight.stop()
		spotlight.modulate.a = 1.0
		# Dừng pulse cũ (fallback tween) để scale không giật khi vòng sáng trượt sang target mới
		if _fx_spotlight != null and _fx_spotlight.is_valid():
			_fx_spotlight.kill()
			_fx_spotlight = null
		# (GIỮ tween) Vòng sáng TRƯỢT sang rect mục tiêu tính từ ô/bàn lúc chạy (position+size động)
		var tw := spotlight.create_tween()
		tw.set_parallel(true)
		tw.tween_property(spotlight, "position", target.position, 0.26).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(spotlight, "size", target.size, 0.26).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.set_parallel(false)
		tw.tween_callback(func() -> void: _start_spotlight_pulse())
	else:
		spotlight.position = target.position
		spotlight.size = target.size
		spotlight.modulate.a = 0.0
		if _play_anim_on(anim_spotlight, &"spotlight_in"):
			if _spot_in_timer != null:
				_spot_in_timer.start()
			else:
				# Fallback khi scene thiếu SpotlightInTimer
				get_tree().create_timer(SPOTLIGHT_IN_SECONDS).timeout.connect(_start_spotlight_pulse)
		else:
			# Fallback khi scene thiếu SpotlightAnim
			spotlight.create_tween().tween_property(spotlight, "modulate:a", 1.0, 0.22)
			_start_spotlight_pulse()


## Mờ dần rồi ẩn vòng sáng (chỉ ẩn khi step mới vẫn KHÔNG có mục tiêu)
func _hide_spotlight() -> void:
	if spotlight == null or not spotlight.visible:
		return
	if _play_anim_on(anim_spotlight, &"spotlight_out"):
		if _spot_out_timer != null:
			_spot_out_timer.start()
		else:
			# Fallback khi scene thiếu SpotlightOutTimer
			get_tree().create_timer(SPOTLIGHT_OUT_SECONDS).timeout.connect(_hide_spotlight_if_unused)
		return
	# Fallback khi scene thiếu SpotlightAnim
	var tw := spotlight.create_tween()
	tw.tween_property(spotlight, "modulate:a", 0.0, 0.18)
	tw.tween_callback(_hide_spotlight_if_unused)


func _hide_spotlight_if_unused() -> void:
	if is_instance_valid(spotlight) and not _has_spotlight:
		spotlight.visible = false


## Vòng sáng "thở" nhẹ (scale) để mắt bám vào mục tiêu — animation loop "spotlight_pulse"
func _start_spotlight_pulse() -> void:
	if anim_spotlight != null and anim_spotlight.current_animation == &"spotlight_pulse" \
			and anim_spotlight.is_playing():
		return
	if _fx_spotlight != null and _fx_spotlight.is_valid():
		return
	if _play_anim_on(anim_spotlight, &"spotlight_pulse"):
		return
	# Fallback khi scene thiếu SpotlightAnim
	_fx_spotlight = spotlight.create_tween().set_loops()
	_fx_spotlight.tween_property(spotlight, "scale", Vector2(1.06, 1.06), 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_fx_spotlight.tween_property(spotlight, "scale", Vector2.ONE, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_spotlight_resized() -> void:
	if spotlight != null:
		spotlight.pivot_offset = spotlight.size * 0.5


func _update_cursor_demonstration(data: Dictionary) -> void:
	var bt := get_board_tutorial()
	if bt == null:
		return
	if data.has("pointer_drag"):
		var drag_info: Dictionary = data["pointer_drag"]
		var from_cell: Vector2i = drag_info.get("from_cell", Vector2i(-1, -1))
		var to_cell: Vector2i = drag_info.get("to_cell", Vector2i(-1, -1))
		var dur: float = float(drag_info.get("duration", 0.6))
		if from_cell != Vector2i(-1, -1) and to_cell != Vector2i(-1, -1):
			bt.animate_cursor_drag(from_cell, to_cell, dur)
		else:
			bt.stop_cursor_animation()
	elif data.has("pointer_tap"):
		var tap_info = data["pointer_tap"]
		if tap_info is Vector2i:
			bt.animate_cursor_tap(tap_info)
		else:
			bt.stop_cursor_animation()
	else:
		bt.stop_cursor_animation()


func stop_cursor_animation() -> void:
	var bt := get_board_tutorial()
	if bt != null:
		bt.stop_cursor_animation()
