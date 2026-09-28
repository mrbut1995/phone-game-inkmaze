class_name HowToPlaySumPathTutorial
extends BaseTutorial

## ============================================================================
## HowToPlaySumPathTutorial: Chế độ Tính Tổng (Planning.md §3.7)
## Bàn mini 3×3: mỗi ô có điểm 1..4 (khai sẵn trong `.tscn`),
## mini HUD hiện Tổng hiện tại / Mục tiêu (= 8). S tại (0,0), F tại (2,2).
## ============================================================================

## 9 ô của bàn 3×3 (tra theo `grid_pos`) — bind trong .tscn
@export var cells: Array[TutorialCell] = []
## Nét đường đi (child của BoardHost) — bind trong .tscn
@export var path_line: Line2D = null
## Nhãn mini HUD "Tổng: … | Mục tiêu: = 8" — bind trong .tscn
@export var lbl_hud_sum: Label = null

var _current_cell: Vector2i = Vector2i(0, 0)
var _is_dragging: bool = false
var _visited_cells: Array[Vector2i] = []
var _current_sum: int = 2
## Số đang HIỆN trên HUD (để cuộn số thay vì đổi phựt)
var _displayed_sum: int = 2

const CELL_SIZE := 76.0
const CELL_GAP := 8.0
const BOARD_ORIGIN := Vector2(85, 140)
## Điểm của từng ô — PHẢI khớp con số hiện trên `.tscn`
const CELL_VALUES: Dictionary = {
	Vector2i(0, 0): 2, Vector2i(1, 0): 1, Vector2i(2, 0): 3,
	Vector2i(0, 1): 4, Vector2i(1, 1): 2, Vector2i(2, 1): 1,
	Vector2i(0, 2): 1, Vector2i(1, 2): 3, Vector2i(2, 2): 2,
}
const START_POS := Vector2i(0, 0)
const FINISH_POS := Vector2i(2, 2)
const TARGET_SUM := 8


func _init_tutorial() -> void:
	tutorial_id = "how_to_play_sum_path"

	var steps: Array = [
		{
			"message_key": "STR_TUT_SUM_01",
			"fallback_text": "Ở đây, con số là ĐIỂM của ô — không liên quan gì tới tường cả.",
			"advance_mode": "MANUAL",
			"spotlight_rect": Rect2(BOARD_ORIGIN, Vector2(CELL_SIZE, CELL_SIZE))
		},
		{
			"message_key": "STR_TUT_SUM_02",
			"fallback_text": "Tổng điểm đường đi của bạn phải khớp đúng điều kiện mục tiêu (= 8).",
			"advance_mode": "MANUAL",
			"spotlight_rect": Rect2(Vector2(85, 90), Vector2(CELL_SIZE * 3 + CELL_GAP * 2, 40))
		},
		{
			"message_key": "STR_TUT_SUM_03",
			"fallback_text": "Mỗi ô chỉ tính điểm 1 LẦN, dù bạn có đi qua lại nhiều lần.",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_SUM_04",
			"fallback_text": "Giờ bạn hãy tìm đường từ S tới F sao cho tổng điểm = 8 nhé!",
			"advance_mode": "AUTO",
			"required_action": "DRAG_PATH"
		},
		{
			"message_key": "STR_TUT_SUM_05",
			"fallback_text": "Chuẩn không cần chỉnh!",
			"advance_mode": "MANUAL",
		}
	]
	setup_steps(steps)


func _reset_path() -> void:
	_visited_cells = [START_POS]
	_current_cell = START_POS
	_current_sum = int(CELL_VALUES[START_POS])
	_displayed_sum = _current_sum
	_update_hud(false)
	_refresh_path_line()


## HUD mini: cuộn số về tổng mới (`animate` = false khi reset) + nảy lên khi khớp mục tiêu
func _update_hud(animate := true) -> void:
	if lbl_hud_sum == null:
		return
	var matched := _current_sum == TARGET_SUM
	lbl_hud_sum.add_theme_color_override(
		"font_color", Color("#4CAE4C") if matched else Color("#2D6EA3")
	)
	var template := str(tr("STR_TUT_SUM_HUD_FORMAT"))
	if animate and _displayed_sum != _current_sum:
		# Tách tiền tố/hậu tố quanh {0} để cuộn số vẫn đúng theo ngôn ngữ đang chọn
		var index := template.find("{0}")
		var prefix := template.substr(0, index) if index >= 0 else ""
		var suffix := template.substr(index + 3).replace("{1}", str(TARGET_SUM)) if index >= 0 else ""
		UIAnim.animate_counter(lbl_hud_sum, _displayed_sum, _current_sum, 0.28, prefix, suffix)
	else:
		lbl_hud_sum.text = template.format([_current_sum, TARGET_SUM])
	_displayed_sum = _current_sum
	if animate and matched:
		UIAnim.play_pop_in(lbl_hud_sum, 0.0, 0.9, 0.26)
		Sfx.play(Sfx.CHECKBOX)


func _refresh_path_line() -> void:
	if path_line == null:
		return
	path_line.clear_points()
	for cell_pos in _visited_cells:
		path_line.add_point(_cell_center(cell_pos))


func _cell_center(coord: Vector2i) -> Vector2:
	for c in cells:
		if c.grid_pos == coord:
			return c.position + c.size * 0.5
	return Vector2.ZERO


func _cell_node(coord: Vector2i) -> TutorialCell:
	for c in cells:
		if c.grid_pos == coord:
			return c
	return null


func _on_step_entered(index: int, _data: Dictionary) -> void:
	if index == 3:
		_reset_path()


func _gui_input(event: InputEvent) -> void:
	if current_step_index != 3:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if _cell_at(mb.global_position) == _current_cell:
					_is_dragging = true
			else:
				_is_dragging = false
	elif event is InputEventMouseMotion and _is_dragging:
		var mm := event as InputEventMouseMotion
		var next := _cell_at(mm.global_position)
		if next != Vector2i(-1, -1) and next != _current_cell:
			_try_step_to(next)


## Tra ô theo toạ độ TOÀN CỤC (BoardHost nằm ở đâu cũng đúng)
func _cell_at(global_pos: Vector2) -> Vector2i:
	for c in cells:
		if c.get_global_rect().has_point(global_pos):
			return c.grid_pos
	return Vector2i(-1, -1)


func _try_step_to(next: Vector2i) -> void:
	var diff: Vector2i = next - _current_cell
	if absi(diff.x) + absi(diff.y) != 1:
		show_fail_feedback("STR_TUT_MOVE_FAIL_01", "Chỉ đi được sang ô NGAY BÊN CẠNH!")
		return

	_current_cell = next
	_visited_cells.append(next)
	var gain := int(CELL_VALUES.get(next, 0))
	_current_sum += gain
	_update_hud()
	_refresh_path_line()
	_mark_cell(next, gain)

	if next == FINISH_POS:
		_is_dragging = false
		if _current_sum == TARGET_SUM:
			play_cells_win()
			spawn_board_text("✓", _cell_center(next))
			show_success_feedback("STR_TUT_SUM_05", "Chuẩn không cần chỉnh!")
			show_step(4)
		else:
			show_fail_feedback("STR_TUT_SUM_FAIL_01", "Tổng chưa đúng (= %d thay vì = %d), hãy thử lại!" % [_current_sum, TARGET_SUM])
			get_tree().create_timer(1.2).timeout.connect(func() -> void:
				if is_inside_tree() and current_step_index == 3:
					_reset_path()
			)


## Ô vừa đi qua: nhún + chữ "+điểm" bay lên + tiếng chấm bút
func _mark_cell(coord: Vector2i, gain: int) -> void:
	var cell := _cell_node(coord)
	if cell != null:
		cell.play_step()
	Sfx.play(Sfx.CELL_STEP)
	if gain > 0:
		spawn_board_text("+%d" % gain, _cell_center(coord), Color(0.298, 0.682, 0.298))
