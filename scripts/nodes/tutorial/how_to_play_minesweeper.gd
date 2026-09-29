class_name HowToPlayMinesweeperTutorial
extends BaseTutorial

## ============================================================================
## HowToPlayMinesweeperTutorial: Chế độ Mìn (Planning.md §3.5)
## Dùng BoardTutorial: bàn 3×3, S (0,0), F (2,2), Mìn tại (1,0) và (0,2).
## ============================================================================

@export var board_tutorial: BoardTutorial = null

const MINES: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 2)]

var _current_cell: Vector2i = Vector2i(0, 0)
var _visited_cells: Array[Vector2i] = []


func _init_tutorial() -> void:
	tutorial_id = "how_to_play_minesweeper"
	if board_tutorial != null:
		board_tutorial.setup_tutorial(
			3, 3,
			{
				Vector2i(0, 0): "S",
				Vector2i(1, 0): "0",
				Vector2i(2, 0): "1",
				Vector2i(0, 1): "2",
				Vector2i(1, 1): "2",
				Vector2i(2, 1): "1",
				Vector2i(0, 2): "0",
				Vector2i(1, 2): "1",
				Vector2i(2, 2): "F"
			},
			[],
			true,
			Vector2i(0, 0),
			Vector2i(2, 2)
		)
		if not board_tutorial.cell_step_attempted.is_connected(_on_cell_step_attempted):
			board_tutorial.cell_step_attempted.connect(_on_cell_step_attempted)
	_reset_path()


func _get_default_steps() -> Array:
	return [
		{
			"message_key": "STR_TUT_MINE_01",
			"fallback_text": "Ở chế độ này, con số là SỐ MÌN trong 8 ô xung quanh!",
			"advance_mode": "MANUAL",
			"spotlight_cell": Vector2i(0, 1)
		},
		{
			"message_key": "STR_TUT_MINE_02",
			"fallback_text": "Đạp trúng ô có mìn ẩn là THUA NGAY LẬP TỨC.",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_MINE_03",
			"fallback_text": "Giờ hãy dẫn đường từ S tới F — nhớ suy luận từ số để né mìn nhé!",
			"advance_mode": "AUTO",
			"required_action": "DRAG_PATH"
		},
		{
			"message_key": "STR_TUT_MINE_04",
			"fallback_text": "Chuẩn luôn! Bạn né được hết mìn.",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_MINE_05",
			"fallback_text": "Bàn Minesweeper thật luôn có ít nhất 1 đường an toàn — hãy suy luận từ số!",
			"advance_mode": "MANUAL",
		}
	]


func _reset_path() -> void:
	_visited_cells = [Vector2i(0, 0)]
	_current_cell = Vector2i(0, 0)
	if board_tutorial != null:
		board_tutorial.set_path(_visited_cells)
		board_tutorial.set_player_cell(Vector2i(0, 0), false)
		for m in MINES:
			var cell := board_tutorial.get_cell(m)
			if cell != null:
				cell.set_bomb(false)


func _on_step_entered(index: int, _data: Dictionary) -> void:
	if index == 2:
		_reset_path()


func _on_cell_step_attempted(next: Vector2i) -> void:
	if current_step_index != 2:
		return
	_try_step_to(next)


func _try_step_to(next: Vector2i) -> void:
	var diff: Vector2i = next - _current_cell
	if absi(diff.x) + absi(diff.y) != 1:
		show_fail_feedback("STR_TUT_MOVE_FAIL_01", "Chỉ đi được sang ô NGAY BÊN CẠNH!")
		return

	# Kiểm tra đạp mìn
	if MINES.has(next):
		show_fail_feedback("STR_TUT_MINE_FAIL_01", "Đây là ô có mìn rồi! Hãy nhìn lại các số lân cận.")
		if board_tutorial != null:
			var mine_cell := board_tutorial.get_cell(next)
			if mine_cell != null:
				mine_cell.set_bomb(true)
				mine_cell.play_fail()
			spawn_board_text("!", board_tutorial.get_cell_center(next), Color(0.85, 0.33, 0.31))
		return

	_current_cell = next
	_visited_cells.append(next)
	if board_tutorial != null:
		board_tutorial.set_path(_visited_cells)
		board_tutorial.set_player_cell(next, true)
		var c := board_tutorial.get_cell(next)
		if c != null:
			c.play_step()

	if next == Vector2i(2, 2):
		play_cells_win()
		if board_tutorial != null:
			spawn_board_text("✓", board_tutorial.get_cell_center(next))
		show_success_feedback("STR_TUT_MINE_04", "Chuẩn luôn! Bạn né được hết mìn.")
		show_step(3)
