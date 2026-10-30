class_name HowToPlayWallBuilderTutorial
extends BaseTutorial

## ============================================================================
## HowToPlayWallBuilderTutorial: Chế độ Xây Tường (Planning.md §3.8)
## Dùng BoardTutorial: bàn 2×2, 2 đoạn tường NGANG cần được neo bởi anchor.
## Người chơi kéo neo để bật tường, rồi bấm GỬI BÀI.
## Kế thừa BaseTutorial (SOLID - SRP & DIP).
## ============================================================================

@export var board_tutorial: BoardTutorial = null
@export var lbl_hud_counter: Label = null
@export var btn_submit: Button = null

@export var TARGET_COUNT := 2

var _built_count: int = 0
var _demo_tween: Tween = null


func _init_tutorial() -> void:
	tutorial_id = "how_to_play_wall_builder"
	if board_tutorial != null:
		# Bàn 2×2 không có S/F, số trên ô = số tường cần dựng quanh nó
		board_tutorial.setup_tutorial(
			2, 2,
			{
				Vector2i(0, 0): "1",
				Vector2i(1, 0): "1",
				Vector2i(0, 1): "1",
				Vector2i(1, 1): "1"
			},
			[],
			false,    # không hiển thị cursor (Wall Builder không đi)
			Vector2i(0, 0),
			Vector2i(1, 1),
			true      # bật anchors
		)
		# Dây `wall_toggled → _on_wall_toggled` khai trong `.tscn` (cùng scene)
	_update_wall_counter()


func _get_default_steps() -> Array:
	return [
		{
			"message_key": "STR_TUT_WB_01",
			"fallback_text": "Chế độ Xây Tường: bạn được xây các đoạn tường trên bàn!",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_WB_02",
			"fallback_text": "Mỗi ô có số cho biết cần bao nhiêu đoạn tường bao quanh nó.",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_WB_03",
			"fallback_text": "Nhấn vào góc neo (anchor) giữa các ô để bật/tắt đoạn tường.",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_WB_04",
			"fallback_text": "Mục tiêu: làm cho số tường thực tế khớp với số trên mỗi ô.",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_WB_05",
			"fallback_text": "Giờ hãy xây đúng 2 đoạn tường sao cho mỗi ô có đúng 1 cạnh tường!",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_WB_06",
			"fallback_text": "Chính xác! Mọi con số đã khớp hết rồi.",
			"advance_mode": "MANUAL",
		}
	]


func _on_step_entered(index: int, _data: Dictionary) -> void:
	_stop_all_demos()
	match index:
		1:
			_clear_board_extras()
			_show_cell_wall_example()
		2:
			_start_wall_demo()
		3:
			_clear_board_extras()
			_start_counter_demo()
		4:
			_clear_board_extras()


## Bước 2: tô sáng 2 ô mẫu + preview "tường đứt đoạn" — minh hoạ tường ô đó cần có
func _show_cell_wall_example() -> void:
	if board_tutorial == null:
		return
	for pos in [Vector2i(0, 0), Vector2i(1, 0)]:
		var cell := board_tutorial.get_cell(pos)
		if cell != null:
			cell.set_focused(true)
			cell.pulse()
	board_tutorial.show_dashed_wall(true, Vector2i(0, 1))
	board_tutorial.show_dashed_wall(true, Vector2i(1, 1))


## Bước 3: ví dụ dựng tường — con trỏ rê neo cho cả 2 đoạn mẫu rồi lặp lại
func _start_wall_demo() -> void:
	if board_tutorial == null:
		return
	board_tutorial.show_dashed_wall(true, Vector2i(0, 1))
	board_tutorial.show_dashed_wall(true, Vector2i(1, 1))
	_run_wall_demo_cycle()


func _run_wall_demo_cycle() -> void:
	if current_step_index != 2 or not is_inside_tree() or board_tutorial == null:
		return

	# Nhịp 1: vòng "1 → 2" tại cặp neo rồi con trỏ rê dựng đoạn thứ nhất (0,1)→(1,1)
	board_tutorial.show_anchor_callouts(Vector2i(0, 1), Vector2i(1, 1))

	_demo_tween = create_tween()
	_demo_tween.tween_interval(0.8)
	_demo_tween.tween_callback(func() -> void:
		if current_step_index != 2 or board_tutorial == null: return
		board_tutorial.play_wall_demo_drag(true, Vector2i(0, 1), 0.55)
	)

	# Nhịp 2: chuyển vòng sang cặp neo kế (1,1)→(2,1) rồi dựng đoạn thứ hai
	_demo_tween.tween_interval(1.3)
	_demo_tween.tween_callback(func() -> void:
		if current_step_index != 2 or board_tutorial == null: return
		board_tutorial.hide_anchor_callouts()
		board_tutorial.show_anchor_callouts(Vector2i(1, 1), Vector2i(2, 1))
	)
	_demo_tween.tween_interval(0.7)
	_demo_tween.tween_callback(func() -> void:
		if current_step_index != 2 or board_tutorial == null: return
		board_tutorial.play_wall_demo_drag(true, Vector2i(1, 1), 0.55)
	)

	# Đủ 2 đoạn ⇒ cất vòng đánh số + mọi ô sáng "đã khớp số" như trong ván thật
	_demo_tween.tween_interval(1.1)
	_demo_tween.tween_callback(func() -> void:
		if current_step_index != 2 or board_tutorial == null: return
		board_tutorial.hide_anchor_callouts()
		for y in 2:
			for x in 2:
				var cell := board_tutorial.get_cell(Vector2i(x, y))
				if cell != null:
					cell.set_satisfied(true)
	)

	# Ngắm thành quả rồi trả bàn về trạng thái đầu để lặp lại
	_demo_tween.tween_interval(1.1)
	_demo_tween.tween_callback(func() -> void:
		if current_step_index != 2: return
		_reset_wall_demo_state()
	)
	_demo_tween.tween_interval(1.6)
	_demo_tween.tween_callback(_run_wall_demo_cycle)


func _reset_wall_demo_state() -> void:
	if board_tutorial == null:
		return
	for k: String in board_tutorial.get_built_wall_keys().duplicate():
		var parts := k.split(",")
		if parts.size() == 3:
			board_tutorial.toggle_wall(parts[0] == "h", Vector2i(int(parts[1]), int(parts[2])))
	for y in 2:
		for x in 2:
			var cell := board_tutorial.get_cell(Vector2i(x, y))
			if cell != null:
				cell.set_satisfied(false)
	board_tutorial.clear_dashed_walls()
	board_tutorial.show_dashed_wall(true, Vector2i(0, 1))
	board_tutorial.show_dashed_wall(true, Vector2i(1, 1))
	board_tutorial.stop_cursor_animation()
	board_tutorial.hide_anchor_callouts()


## Bước 4: "Khung đếm cho biết cần vẽ bao nhiêu đoạn" — demo vẽ 2 đoạn & khung đếm nhảy theo
func _start_counter_demo() -> void:
	if board_tutorial == null:
		return
	_run_counter_demo_cycle()


func _run_counter_demo_cycle() -> void:
	if current_step_index != 3 or not is_inside_tree() or board_tutorial == null:
		return

	# Đoạn 1 → khung đếm nhảy 1/2; đoạn 2 → 2/2
	board_tutorial.play_wall_demo_drag(true, Vector2i(0, 1), 0.55)

	_demo_tween = create_tween()
	_demo_tween.tween_interval(0.9)
	_demo_tween.tween_callback(func() -> void:
		if current_step_index != 3: return
		_spawn_counter_gain()
	)
	_demo_tween.tween_interval(0.5)
	_demo_tween.tween_callback(func() -> void:
		if current_step_index != 3 or board_tutorial == null: return
		board_tutorial.play_wall_demo_drag(true, Vector2i(1, 1), 0.55)
	)
	_demo_tween.tween_interval(0.95)
	_demo_tween.tween_callback(func() -> void:
		if current_step_index != 3: return
		_spawn_counter_gain()
	)

	# Đủ 2 đoạn ⇒ mọi ô sáng "đã khớp số"
	_demo_tween.tween_interval(0.35)
	_demo_tween.tween_callback(func() -> void:
		if current_step_index != 3 or board_tutorial == null: return
		for y in 2:
			for x in 2:
				var cell := board_tutorial.get_cell(Vector2i(x, y))
				if cell != null:
					cell.set_satisfied(true)
	)

	# Trả khung đếm về 0/2 rồi lặp lại
	_demo_tween.tween_interval(1.6)
	_demo_tween.tween_callback(func() -> void:
		if current_step_index != 3: return
		_reset_counter_demo_state()
	)
	_demo_tween.tween_interval(1.6)
	_demo_tween.tween_callback(_run_counter_demo_cycle)


func _reset_counter_demo_state() -> void:
	if board_tutorial == null:
		return
	for k: String in board_tutorial.get_built_wall_keys().duplicate():
		var parts := k.split(",")
		if parts.size() == 3:
			board_tutorial.toggle_wall(parts[0] == "h", Vector2i(int(parts[1]), int(parts[2])))
	for y in 2:
		for x in 2:
			var cell := board_tutorial.get_cell(Vector2i(x, y))
			if cell != null:
				cell.set_satisfied(false)
	board_tutorial.stop_cursor_animation()


## Chữ "+1" bay lên từ khung đếm — nối "vừa vẽ 1 đoạn" với con số trong khung
func _spawn_counter_gain() -> void:
	if lbl_hud_counter == null:
		return
	var panel := lbl_hud_counter.get_parent() as Control
	if panel == null:
		return
	spawn_board_text("+1", panel.position + panel.size * 0.5, Color(0.18, 0.49, 0.2))


func _stop_all_demos() -> void:
	if _demo_tween != null and _demo_tween.is_valid():
		_demo_tween.kill()
		_demo_tween = null
	if board_tutorial != null:
		board_tutorial.cancel_wall_demo()


func complete_tutorial() -> void:
	_stop_all_demos()
	super.complete_tutorial()


func skip_tutorial() -> void:
	_stop_all_demos()
	super.skip_tutorial()


func skip_all_tutorials() -> void:
	_stop_all_demos()
	super.skip_all_tutorials()


## Dọn tường demo + preview + highlight (dùng trước bước giải thích HUD / thực hành)
func _clear_board_extras() -> void:
	if board_tutorial != null:
		for k: String in board_tutorial.get_built_wall_keys().duplicate():
			var parts := k.split(",")
			if parts.size() == 3:
				board_tutorial.toggle_wall(parts[0] == "h", Vector2i(int(parts[1]), int(parts[2])))
		board_tutorial.clear_dashed_walls()
		for y in 2:
			for x in 2:
				var cell := board_tutorial.get_cell(Vector2i(x, y))
				if cell != null:
					cell.set_focused(false)
					cell.set_satisfied(false)
	_built_count = 0
	_update_wall_counter()


func _on_wall_toggled(_wall_key: String, _active: bool) -> void:
	if board_tutorial == null:
		return
	_built_count = board_tutorial.get_built_wall_keys().size()
	_update_wall_counter()


func _update_wall_counter() -> void:
	if lbl_hud_counter == null:
		return
	var fmt := str(tr("STR_TUT_WB_COUNTER_FORMAT"))
	if fmt == "STR_TUT_WB_COUNTER_FORMAT":
		fmt = "Đã vẽ: {0} / {1} đoạn"
	lbl_hud_counter.text = fmt.format([_built_count, TARGET_COUNT])
	var full := _built_count >= TARGET_COUNT
	lbl_hud_counter.add_theme_color_override("font_color",
		Color(0.18, 0.49, 0.2) if full else Color(0.18, 0.22, 0.26))
	UIAnim.play_pop_in(lbl_hud_counter, 0.0, 0.66 if full else 0.9, 0.3 if full else 0.22)


func _on_submit_pressed() -> void:
	if current_step_index < 4 or board_tutorial == null:
		return

	if _built_count == TARGET_COUNT:
		Sfx.play(Sfx.STAMP_IMPACT)
		play_cells_win()
		show_success_feedback("STR_TUT_WB_06", "Chính xác! Mọi con số đã khớp hết rồi.")
		show_step(5)
	else:
		show_fail_feedback("STR_TUT_WB_FAIL_01", "Chưa khớp hết — hãy kiểm tra lại các ô!")
		shake_node(board_tutorial, 0.3, 10.0)
		flash_fail(lbl_hud_counter)
