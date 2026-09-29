class_name HowToUseToolTutorial
extends BaseTutorial

## ============================================================================
## HowToUseToolTutorial: Dạy dùng 2 nút CÔNG CỤ (thanh hành động) —
## QUAY LẠI (undo) và GỢI Ý (hint) — mỗi nút 3 lượt mỗi màn.
## Bàn 3×3 không tường. Bước 1 giới thiệu · bước 2 demo undo · bước 3 demo hint
## · bước 4 luyện tập (tự đi + tự bấm 2 nút) · bước 5 chúc mừng.
## ============================================================================

@export var board_tutorial: BoardTutorial = null
@export var lbl_hud_tools: Label = null
@export var btn_undo: BaseButton = null
@export var btn_hint: BaseButton = null
@export var lbl_undo_count: Label = null
@export var lbl_hint_count: Label = null

const START_POS := Vector2i(0, 0)
const FINISH_POS := Vector2i(2, 2)
const TOOL_USES := 3

var _current_cell: Vector2i = START_POS
var _visited_cells: Array[Vector2i] = []
var _undo_left: int = TOOL_USES
var _hint_left: int = TOOL_USES
var _demo_running: bool = false


func _init_tutorial() -> void:
	tutorial_id = "how_to_use_tool"
	if board_tutorial != null:
		board_tutorial.setup_tutorial(
			3, 3,
			{
				Vector2i(0, 0): "S",
				Vector2i(1, 0): "", Vector2i(2, 0): "",
				Vector2i(0, 1): "", Vector2i(1, 1): "", Vector2i(2, 1): "",
				Vector2i(0, 2): "", Vector2i(1, 2): "",
				Vector2i(2, 2): "F",
			},
			[],
			true,
			START_POS,
			FINISH_POS
		)
		if not board_tutorial.cell_step_attempted.is_connected(_on_cell_step_attempted):
			board_tutorial.cell_step_attempted.connect(_on_cell_step_attempted)
	_reset_path()
	_update_tools(false)


func _get_default_steps() -> Array:
	return [
		{
			"message_key": "STR_TUT_TOOL_01",
			"fallback_text": "Thanh công cụ có 2 nút: QUAY LẠI và GỢI Ý — mỗi nút dùng được 3 lượt mỗi màn. Cùng xem cách dùng nhé!",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_TOOL_02",
			"fallback_text": "Ví dụ: đi 1 bước rồi nhấn QUAY LẠI — con trỏ tự lùi về ô cũ.",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_TOOL_03",
			"fallback_text": "Ví dụ: nhấn GỢI Ý — ô nên đi tiếp sẽ sáng lên.",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_TOOL_04",
			"fallback_text": "Giờ tự thử — đi tới F, dùng QUAY LẠI và GỢI Ý khi cần nhé!",
			"advance_mode": "AUTO",
			"required_action": "DRAG_PATH",
		},
		{
			"message_key": "STR_TUT_TOOL_05",
			"fallback_text": "Tuyệt! Bạn đã nắm được 2 công cụ rồi.",
			"advance_mode": "MANUAL",
		},
	]


func _reset_path() -> void:
	_visited_cells = [START_POS]
	_current_cell = START_POS
	if board_tutorial != null:
		board_tutorial.set_path(_visited_cells)
		board_tutorial.set_player_cell(START_POS, false)


func _on_step_entered(index: int, _data: Dictionary) -> void:
	_demo_running = false
	match index:
		1:
			_start_undo_demo()
		2:
			_start_hint_demo()
		3:
			_start_practice()


# ============================================================================
# Công cụ — trạng thái chung (HUD + huy hiệu lượt + khoá nút khi hết lượt)
# ============================================================================

func _update_tools(animated: bool = true) -> void:
	if lbl_undo_count != null:
		lbl_undo_count.text = str(_undo_left)
	if lbl_hint_count != null:
		lbl_hint_count.text = str(_hint_left)
	if btn_undo != null:
		btn_undo.disabled = _undo_left <= 0
	if btn_hint != null:
		btn_hint.disabled = _hint_left <= 0
	if lbl_hud_tools == null:
		return
	var fmt := str(tr("STR_TUT_TOOL_HUD"))
	if fmt == "STR_TUT_TOOL_HUD":
		fmt = "Quay lại: {0} lượt · Gợi ý: {1} lượt"
	lbl_hud_tools.text = fmt.format([_undo_left, _hint_left])
	if not animated:
		return
	UIAnim.play_pop_in(lbl_hud_tools, 0.0, 0.88, 0.2)


## Nhấn nút "ảo" trong demo: đổi art sang trạng thái pressed rồi trả lại
func _flash_tool_button(btn: BaseButton) -> void:
	var tb := btn as TextureButton
	if tb == null or tb.disabled:
		return
	var normal_tex := tb.texture_normal
	var pressed_tex := tb.texture_pressed
	if pressed_tex == null:
		return
	tb.texture_normal = pressed_tex
	UIAnim.play_pop_in(tb, 0.0, 0.92, 0.14)
	get_tree().create_timer(0.18).timeout.connect(func() -> void:
		if is_instance_valid(tb):
			tb.texture_normal = normal_tex
	)


## Tâm nút theo toạ độ trong BoardHost (để thả chữ nổi "-1" đúng chỗ)
func _button_center(btn: Control) -> Vector2:
	if btn == null or board_host == null:
		return Vector2.ZERO
	return btn.global_position + btn.size * 0.5 - board_host.global_position


# ============================================================================
# Bước 2: demo QUAY LẠI — đi 1 bước rồi lùi về, huy hiệu 3 → 2
# ============================================================================

func _start_undo_demo() -> void:
	if board_tutorial == null:
		return
	_demo_running = true
	_run_undo_demo_cycle()


func _run_undo_demo_cycle() -> void:
	if not _demo_running or current_step_index != 1 or not is_inside_tree():
		return
	_reset_path()
	_undo_left = TOOL_USES
	_hint_left = TOOL_USES
	_update_tools(false)
	# Đi mẫu 1 bước: S → (0,1)
	get_tree().create_timer(0.45).timeout.connect(func() -> void:
		if not _demo_running or current_step_index != 1: return
		_visited_cells = [START_POS, Vector2i(0, 1)]
		_current_cell = Vector2i(0, 1)
		board_tutorial.set_path(_visited_cells)
		board_tutorial.set_player_cell(_current_cell, true)
		var c := board_tutorial.get_cell(_current_cell)
		if c != null:
			c.play_step()
	)
	# Nhấn QUAY LẠI (huy hiệu 3 → 2)
	get_tree().create_timer(1.7).timeout.connect(func() -> void:
		if not _demo_running or current_step_index != 1: return
		_flash_tool_button(btn_undo)
		_undo_left = TOOL_USES - 1
		_update_tools(true)
		spawn_board_text("-1", _button_center(btn_undo) + Vector2(0, -30), Color(0.78, 0.22, 0.22))
	)
	# Lùi lại ô cũ
	get_tree().create_timer(2.4).timeout.connect(func() -> void:
		if not _demo_running or current_step_index != 1: return
		_visited_cells = [START_POS]
		_current_cell = START_POS
		board_tutorial.set_path(_visited_cells)
		board_tutorial.set_player_cell(START_POS, true)
	)
	# Trả huy hiệu về 3 cho vòng lặp sau
	get_tree().create_timer(4.0).timeout.connect(func() -> void:
		if not _demo_running or current_step_index != 1: return
		_undo_left = TOOL_USES
		_update_tools(true)
	)
	get_tree().create_timer(4.7).timeout.connect(_run_undo_demo_cycle)


# ============================================================================
# Bước 3: demo GỢI Ý — nhấn nút, ô kế tiếp sáng nhịp 3 lần
# ============================================================================

func _start_hint_demo() -> void:
	if board_tutorial == null:
		return
	_demo_running = true
	_run_hint_demo_cycle()


func _run_hint_demo_cycle() -> void:
	if not _demo_running or current_step_index != 2 or not is_inside_tree():
		return
	_reset_path()
	_undo_left = TOOL_USES
	_hint_left = TOOL_USES
	_update_tools(false)
	# Nhấn GỢI Ý (huy hiệu 3 → 2)
	get_tree().create_timer(0.5).timeout.connect(func() -> void:
		if not _demo_running or current_step_index != 2: return
		_flash_tool_button(btn_hint)
		_hint_left = TOOL_USES - 1
		_update_tools(true)
		spawn_board_text("-1", _button_center(btn_hint) + Vector2(0, -30), Color(0.78, 0.22, 0.22))
	)
	# Ô kế tiếp sáng lên 3 nhịp
	for i in 3:
		var at := 1.1 + 0.62 * i
		get_tree().create_timer(at).timeout.connect(func() -> void:
			if not _demo_running or current_step_index != 2: return
			_pulse_hint_cell(Vector2i(1, 0))
		)
	# Trả huy hiệu về 3 cho vòng lặp sau
	get_tree().create_timer(3.4).timeout.connect(func() -> void:
		if not _demo_running or current_step_index != 2: return
		_hint_left = TOOL_USES
		_update_tools(true)
	)
	get_tree().create_timer(4.2).timeout.connect(_run_hint_demo_cycle)


func _pulse_hint_cell(pos: Vector2i) -> void:
	if board_tutorial == null:
		return
	board_tutorial.pulse_cell(pos)
	spawn_board_text("?", board_tutorial.get_cell_center(pos), Color(0.13, 0.3, 0.43))


# ============================================================================
# Bước 4: luyện tập — người chơi tự đi và tự dùng 2 nút
# ============================================================================

func _start_practice() -> void:
	_reset_path()
	_undo_left = TOOL_USES
	_hint_left = TOOL_USES
	_update_tools(true)


func _on_cell_step_attempted(next: Vector2i) -> void:
	if current_step_index != 3:
		return
	_try_step_to(next)


func _try_step_to(next: Vector2i) -> void:
	var diff: Vector2i = next - _current_cell
	if absi(diff.x) + absi(diff.y) != 1:
		show_fail_feedback("STR_TUT_MOVE_FAIL_01", "Chỉ đi được sang ô NGAY BÊN CẠNH!")
		return

	_current_cell = next
	_visited_cells.append(next)
	if board_tutorial != null:
		board_tutorial.set_path(_visited_cells)
		board_tutorial.set_player_cell(next, true)
		var c := board_tutorial.get_cell(next)
		if c != null:
			c.play_step()

	if next == FINISH_POS:
		play_cells_win()
		if board_tutorial != null:
			spawn_board_text("✓", board_tutorial.get_cell_center(next))
		show_success_feedback("STR_TUT_TOOL_05", "Tuyệt! Bạn đã nắm được 2 công cụ rồi.")
		show_step(4)


func _on_undo_pressed() -> void:
	if current_step_index != 3 or _undo_left <= 0:
		return
	# Chưa đi bước nào ⇒ không có gì để lùi (và KHÔNG trừ lượt — giống game thật)
	if _visited_cells.size() <= 1:
		show_fail_feedback("STR_TUT_TOOL_FAIL_UNDO", "Chưa có bước nào để quay lại!")
		return
	_undo_left -= 1
	_visited_cells.remove_at(_visited_cells.size() - 1)
	_current_cell = _visited_cells[_visited_cells.size() - 1]
	if board_tutorial != null:
		board_tutorial.set_path(_visited_cells)
		board_tutorial.set_player_cell(_current_cell, true)
	_update_tools(true)


func _on_hint_pressed() -> void:
	if current_step_index != 3 or _hint_left <= 0:
		return
	var next := _next_hint_cell()
	if next == Vector2i(-1, -1):
		return
	_hint_left -= 1
	_pulse_hint_cell(next)
	_update_tools(true)


## Ô đúng kế tiếp theo đường ngắn nhất (bàn 3×3 TRỐNG: đi ngang trước, rồi dọc)
func _next_hint_cell() -> Vector2i:
	if _current_cell == FINISH_POS:
		return Vector2i(-1, -1)
	var diff := FINISH_POS - _current_cell
	if diff.x != 0:
		return _current_cell + Vector2i(signi(diff.x), 0)
	return _current_cell + Vector2i(0, signi(diff.y))
