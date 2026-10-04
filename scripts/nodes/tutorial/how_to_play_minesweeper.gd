class_name HowToPlayMinesweeperTutorial
extends BaseInteractivePathTutorial

## ============================================================================
## HowToPlayMinesweeperTutorial: Chế độ Mìn (Planning.md §3.5)
## Dùng BoardTutorial: bàn 3×3, S (0,0), F (2,2), Mìn tại (1,0) và (0,2).
## Kế thừa BaseInteractivePathTutorial (SOLID - OCP/SRP).
## ============================================================================

const START_POS := Vector2i(0, 0)
const FINISH_POS := Vector2i(2, 2)
const MINES: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 2)]


func _init_tutorial() -> void:
	tutorial_id = "how_to_play_minesweeper"
	_start_cell = START_POS
	_goal_cell = FINISH_POS
	if board_tutorial != null:
		board_tutorial.setup_tutorial(
			3, 3,
			{
				START_POS: "S",
				Vector2i(1, 0): "0",
				Vector2i(2, 0): "1",
				Vector2i(0, 1): "2",
				Vector2i(1, 1): "2",
				Vector2i(2, 1): "1",
				Vector2i(0, 2): "0",
				Vector2i(1, 2): "1",
				FINISH_POS: "F"
			},
			[],
			true,
			START_POS,
			FINISH_POS
		)
	reset_path()


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


func reset_path(start_pos: Vector2i = _start_cell, update_board: bool = true) -> void:
	super.reset_path(start_pos, update_board)
	if board_tutorial != null:
		for m in MINES:
			var cell := board_tutorial.get_cell(m)
			if cell != null:
				cell.set_bomb(false)


func _on_step_entered(index: int, _data: Dictionary) -> void:
	if index == 2:
		reset_path()


func _is_input_allowed_at_step(step_idx: int) -> bool:
	return step_idx == 2


func _can_step_to(_from_cell: Vector2i, to_cell: Vector2i) -> bool:
	if MINES.has(to_cell):
		show_fail_feedback("STR_TUT_MINE_FAIL_01", "Đây là ô có mìn rồi! Hãy nhìn lại các số lân cận.")
		if board_tutorial != null:
			var mine_cell := board_tutorial.get_cell(to_cell)
			if mine_cell != null:
				mine_cell.set_bomb(true)
				mine_cell.play_fail()
			spawn_board_text("!", board_tutorial.get_cell_center(to_cell), Color(0.85, 0.33, 0.31))
		return false
	return true


func _on_goal_reached(next: Vector2i) -> void:
	play_cells_win()
	if board_tutorial != null:
		spawn_board_text("✓", board_tutorial.get_cell_center(next))
	show_success_feedback("STR_TUT_MINE_04", "Chuẩn luôn! Bạn né được hết mìn.")
	show_step(3)
