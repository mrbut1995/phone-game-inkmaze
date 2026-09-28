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

var _auto_timer: SceneTreeTimer = null
var _spotlight_rect: Rect2 = Rect2()
var _spotlight_cell: Vector2i = Vector2i(-1, -1)
var _spotlight_node: Control = null
var _has_spotlight: bool = false

## --- HIỆU ỨNG (animation) ---------------------------------------------------
## Trễ giữa 2 ô bàn mini khi chạy hoạt cảnh mở bài
const CELL_ENTER_STAGGER := 0.045
var _fx_spotlight: Tween = null
var _fx_toast: Tween = null
var _fx_message: Tween = null
var _entrance_played := false


func _ready() -> void:
	if spotlight != null and not spotlight.resized.is_connected(_on_spotlight_resized):
		spotlight.resized.connect(_on_spotlight_resized)
	_init_tutorial()
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
	if steps_data.size() > 0 and current_step_index < steps_data.size():
		var data: Dictionary = steps_data[current_step_index]
		_update_cursor_demonstration(data)


## Override trong scene con để nạp steps riêng
func _init_tutorial() -> void:
	pass


## Gắn hiệu ứng nhấn nảy cho 3 nút điều hướng (giống mọi nút khác trong game)
func _wire_button_effects() -> void:
	for btn in [btn_skip_all, btn_skip, btn_next]:
		var base_button := btn as BaseButton
		if base_button != null:
			UIAnim.attach_press_bounce(base_button)


## Hoạt cảnh MỞ BÀI: nền tối hiện dần · thẻ thoại trượt lên · bàn mini + từng ô nở ra so le
func play_entrance() -> void:
	Sfx.play(Sfx.PAGE_TURN)
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
func flash_fail(target: Control) -> void:
	if target == null:
		return
	var old := target.modulate
	target.modulate = Color(1.0, 0.45, 0.42, old.a)
	target.create_tween().tween_property(target, "modulate", old, 0.4)


## Đổi nội dung thẻ thoại kèm nhịp fade nhẹ (cha là Container nên không dời vị trí)
func _animate_step_text() -> void:
	if _fx_message != null and _fx_message.is_valid():
		_fx_message.kill()
	_fx_message = UIAnim.play_fade_in(lbl_message, 0.0, 0.18)
	UIAnim.play_pop_in(lbl_title, 0.0, 0.94, 0.2)


func setup_steps(p_steps: Array) -> void:
	steps_data = p_steps
	current_step_index = 0
	_update_dots()
	if steps_data.size() > 0:
		show_step(0)


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

	var data: Dictionary = steps_data[index]
	var msg_key: String = data.get("message_key", "")
	var tr_msg := tr(msg_key)
	if tr_msg == msg_key and data.has("fallback_text"):
		lbl_message.text = data["fallback_text"]
	else:
		lbl_message.text = tr_msg

	var title_key: String = data.get("title_key", "STR_TUT_COMMON_TITLE")
	lbl_title.text = tr(title_key)
	_animate_step_text()
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
	shake_node(dialog_bubble, 0.25, 8.0)
	if backdrop != null:
		backdrop.color = Color(0.98, 0.88, 0.88, 1.0)
		backdrop.create_tween().tween_property(backdrop, "color", Color(0.969, 0.957, 0.937, 1.0), 0.45)


func show_success_feedback(key: String = "", fallback_text: String = "") -> void:
	Sfx.play(Sfx.STAR_POP)
	_show_toast(key, fallback_text, Color("#4CAE4C"), 0.95)


## Toast phản hồi: nở ra → giữ → mờ dần (1 tween duy nhất, không tranh thuộc tính)
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
	_fx_toast = toast_label.create_tween()
	_fx_toast.tween_property(toast_label, "modulate:a", 1.0, 0.16)
	_fx_toast.parallel().tween_property(toast_label, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_fx_toast.tween_interval(hold)
	_fx_toast.tween_property(toast_label, "modulate:a", 0.0, 0.3)


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
	if _spotlight_cell != Vector2i(-1, -1):
		var cell := get_board_cell(_spotlight_cell)
		if cell != null:
			var grect := cell.get_global_rect()
			var lpos := grect.position - global_position
			target = Rect2(lpos - Vector2(4, 4), grect.size + Vector2(8, 8))
		else:
			target = Rect2(_board_to_overlay(_spotlight_rect.position), _spotlight_rect.size)
	elif _spotlight_node != null and is_instance_valid(_spotlight_node):
		var grect := _spotlight_node.get_global_rect()
		var lpos := grect.position - global_position
		target = Rect2(lpos - Vector2(4, 4), grect.size + Vector2(8, 8))
	else:
		target = Rect2(_board_to_overlay(_spotlight_rect.position), _spotlight_rect.size)

	var was_visible := spotlight.visible
	spotlight.visible = true
	spotlight.scale = Vector2.ONE
	if was_visible:
		spotlight.modulate.a = 1.0
		var tw := spotlight.create_tween()
		tw.set_parallel(true)
		tw.tween_property(spotlight, "position", target.position, 0.26).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(spotlight, "size", target.size, 0.26).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		spotlight.position = target.position
		spotlight.size = target.size
		spotlight.modulate.a = 0.0
		spotlight.create_tween().tween_property(spotlight, "modulate:a", 1.0, 0.22)
	_start_spotlight_pulse()


## Mờ dần rồi ẩn vòng sáng (chỉ ẩn khi step mới vẫn KHÔNG có mục tiêu)
func _hide_spotlight() -> void:
	if spotlight == null or not spotlight.visible:
		return
	var tw := spotlight.create_tween()
	tw.tween_property(spotlight, "modulate:a", 0.0, 0.18)
	tw.tween_callback(func() -> void:
		if is_instance_valid(spotlight) and not _has_spotlight:
			spotlight.visible = false
	)


## Vòng sáng "thở" nhẹ (scale) để mắt bám vào mục tiêu — chỉ chạy 1 vòng lặp
func _start_spotlight_pulse() -> void:
	if _fx_spotlight != null and _fx_spotlight.is_valid():
		return
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
