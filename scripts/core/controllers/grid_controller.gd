class_name GridController
extends Node
## ============================================================================
## Controller: Cầu nối giữa Model/GameMode và View (board.gd).
## - Nhận gesture input từ View: handle_drag_updated / handle_anchor_connected.
## - Thẩm định tính hợp lệ của nước đi và chướng ngại vật qua GameMode Strategy.
## - Quản lý AnchorController cho logic Tường Nghi Ngờ.
## - Quản lý UndoController và HintController.
## - Emit signal cho GameController: step_consumed / wall_hit / reached_end.
## ============================================================================

signal step_consumed(cost: int, hit_hazard: bool)
signal wall_hit
signal reached_end
## Hết đường đi (mode tự báo qua is_dead_end) -> GameController mở popup thua
signal dead_end

var maze: MazeData = null
#var view: Control = null

@export var board_view : BoardView = null
@export var anchor_controller: AnchorController = null
@export var undo_controller: UndoController = null
@export var hint_controller: HintController = null
@export var game_mode_controller: GameModeController = null

var current_pos: Vector2i = Vector2i.ZERO
var path: Array[Vector2i] = []
var _visited_edges: Dictionary = {}

## Cạnh vừa đâm (để hồi sinh ở Level Mode hiện lại đúng đoạn tường đó)
var last_hazard_from: Vector2i = Vector2i(-1, -1)
var last_hazard_to: Vector2i = Vector2i(-1, -1)
var last_hazard_type := ""

func set_maze(p_maze: MazeData) -> void:
	maze = p_maze
	current_pos = maze.get_start()
	path = [current_pos]
	_visited_edges.clear()
	if anchor_controller != null:
		anchor_controller.reset()
	if undo_controller != null:
		undo_controller.reset()
	# LƯU Ý: KHÔNG gọi game_mode.on_grid_setup() ở đây — lúc này board chưa được dựng lại theo
	# maze mới (setup_maze chạy sau), nên mọi thay đổi lên tường/ô sẽ bị ghi đè.
	# GameController._start_floor() gọi on_grid_setup() SAU khi board đã setup xong.


# ---------------------------------------------------------------------------
# Handlers nhận signal từ View
# ---------------------------------------------------------------------------
func handle_cell_pressed(pos: Vector2i) -> void:
	if board_view != null and board_view.has_method("highlight_real_walls_of_cell"):
		board_view.call("highlight_real_walls_of_cell", pos)


func handle_drag_updated(pos: Vector2i) -> void:
	try_move_to(pos)


func handle_anchor_connected(corner_a: Vector2i, corner_b: Vector2i) -> void:
	if anchor_controller == null:
		return
	var mode: BaseGameMode = game_mode_controller.game_mode if game_mode_controller != null else null
	var edge := AnchorController.get_edge_between(corner_a, corner_b)
	# Luật của chế độ: đoạn đã KHOÁ (Wall Builder — đoạn do Gợi ý mở) hoặc khe không cho vẽ
	# (viền ngoài board) thì bỏ qua, không đổi trạng thái.
	if not edge.is_empty() and mode != null:
		var blocked_h := bool(edge[0])
		var blocked_lattice: Vector2i = edge[1]
		if mode.is_wall_locked(blocked_h, blocked_lattice) \
				or not mode.can_draw_wall(blocked_h, blocked_lattice, maze):
			return
	if not anchor_controller.handle_anchor_connection(corner_a, corner_b):
		return
	if not edge.is_empty() and mode != null:
		var toggled_h := bool(edge[0])
		var toggled_lattice: Vector2i = edge[1]
		mode.on_wall_toggled(toggled_h, toggled_lattice,
			anchor_controller.is_suspected(toggled_h, toggled_lattice))
		# Chế độ có phản hồi theo SỐ TRÊN Ô (Wall Builder: ô đủ tường sáng nền xanh) -> vẽ lại
		if mode.has_method("is_cell_satisfied") and board_view != null \
				and board_view.has_method("refresh_cell_texts"):
			board_view.call("refresh_cell_texts")
	if mode != null and mode.check_completion(current_pos, maze, anchor_controller):
		reached_end.emit()


func _on_suspected_wall_toggled(is_h: bool, lattice: Vector2i, active: bool) -> void:
	if board_view != null and board_view.has_method("set_suspected_wall"):
		board_view.call("set_suspected_wall", is_h, lattice, active)


# ---------------------------------------------------------------------------
# Logic di chuyển theo GameMode Strategy
# ---------------------------------------------------------------------------
func try_move_to(pos: Vector2i) -> void:
	if maze == null or board_view == null or game_mode_controller.game_mode == null:
		return
	if not maze.is_in_bounds(pos):
		return
	if not maze.is_cell_active(pos):
		return      # ô ngoài board (polyomino): không tính là nước đi, không hazard
	if pos == current_pos:
		return
	if not _is_adjacent(current_pos, pos):
		return

	var step_cost := game_mode_controller.game_mode.get_step_cost(current_pos, pos, maze)
	var eval_result := game_mode_controller.game_mode.evaluate_move(current_pos, pos, maze)

	if eval_result.get("is_hazard", false):
		var hazard_type: String = eval_result.get("hazard_type", "wall")
		var from_cell: Vector2i = current_pos
		# Nhớ cạnh vừa đâm để hồi sinh có thể hiện lại đoạn tường đó
		last_hazard_from = from_cell
		last_hazard_to = pos
		last_hazard_type = hazard_type

		# Chế độ thua-ngay (Play/Fog hardcore...): giữ nguyên vị trí + vệt đường đã vẽ.
		# Mặc định các chế độ khác đưa nhân vật về điểm S; riêng Minesweeper
		# (`respawn_on_hazard = false`) nổ tại chỗ, người chơi đứng nguyên ô hiện tại.
		var instant_over: bool = game_mode_controller.game_mode.instant_game_over_on_hazard
		var respawn: bool = game_mode_controller.game_mode.respawn_on_hazard and not instant_over
		if respawn:
			current_pos = maze.get_start()
			path = [current_pos]

		step_consumed.emit(step_cost, true)
		wall_hit.emit()

		if hazard_type == "mine":
			var mine_pos: Vector2i = eval_result.get("pos", pos)
			if board_view.has_method("show_mine_hit"):
				board_view.call("show_mine_hit", mine_pos)
		elif hazard_type == "revisit":
			# One Stroke: đạp lên ô ĐÃ ĐI = thua ngay, KHÔNG vẽ thêm đoạn tường gãy
			if board_view.has_method("pulse_cell"):
				board_view.call("pulse_cell", pos)
		else:
			if board_view.has_method("show_wall_hit"):
				board_view.call("show_wall_hit", from_cell, pos)

		if respawn and board_view.has_method("reset_to_start"):
			board_view.call("reset_to_start")
		if respawn:
			# Mode có trạng thái hiển thị theo vị trí (Fog of War) cập nhật lại quanh ô S
			game_mode_controller.game_mode.on_respawned(board_view, current_pos, maze)
	elif eval_result.get("allowed", false):
		var prev_pos := current_pos
		_record_edge(current_pos, pos)
		current_pos = pos
		path.append(pos)

		if undo_controller != null:
			undo_controller.record_move(prev_pos, pos, step_cost)

		if board_view.has_method("move_cursor_to"):
			board_view.call("move_cursor_to", pos)
		if board_view.has_method("set_moving_path"):
			board_view.call("set_moving_path", path)

		game_mode_controller.game_mode.on_player_moved(board_view, pos, maze)
		step_consumed.emit(step_cost, false)

		if game_mode_controller.game_mode.check_completion(current_pos, maze, anchor_controller):
			reached_end.emit()
		elif game_mode_controller.game_mode.is_dead_end(current_pos, maze):
			dead_end.emit()
	else:
		# Nước đi hợp lệ về hình học nhưng bị LUẬT của mode chặn (VD One Stroke còn ô trống
		# nên chưa được chạm F) -> mode tự phản hồi (hiện chữ nổi cảnh báo...)
		game_mode_controller.game_mode.on_move_blocked(
			board_view, current_pos, pos, str(eval_result.get("reason", "")))


# ---------------------------------------------------------------------------
# Undo & Hint Support
# ---------------------------------------------------------------------------
func undo_last_move() -> bool:
	if undo_controller == null or not undo_controller.can_undo():
		return false

	var action := undo_controller.pop_last_action()
	if action.get("type", "") == "move":
		var target_pos: Vector2i = action.get("from", maze.get_start())
		var left_pos: Vector2i = action.get("to", target_pos)
		current_pos = target_pos
		if path.size() > 1:
			path.pop_back()
		if board_view != null:
			if board_view.has_method("move_cursor_to"):
				board_view.call("move_cursor_to", current_pos)
			if board_view.has_method("set_moving_path"):
				board_view.call("set_moving_path", path)
		# Mode có trạng thái riêng thì lùi theo (VD Fading Ink hồi lại mực đã phai)
		if game_mode_controller != null and game_mode_controller.game_mode != null:
			game_mode_controller.game_mode.on_move_undone(board_view, left_pos, target_pos, maze)
		return true
	return false


## Hiện lại đúng đoạn tường vừa đâm (gọi sau khi người chơi hồi sinh ở Level Mode).
## Trả về true nếu có đoạn tường được hiện lại.
func reveal_last_hazard_wall() -> bool:
	if last_hazard_type != "wall" or board_view == null:
		return false
	if last_hazard_from == Vector2i(-1, -1) or last_hazard_to == Vector2i(-1, -1):
		return false
	if not board_view.has_method("show_wall_hit"):
		return false
	board_view.call("show_wall_hit", last_hazard_from, last_hazard_to)
	return true


func give_hint() -> void:
	if hint_controller == null or maze == null or board_view == null:
		return
	# Mode có luật riêng cho hint (One Stroke: phải là bước của MỘT lời giải phủ kín)
	var mode: BaseGameMode = game_mode_controller.game_mode if game_mode_controller != null else null
	var next_cell := Vector2i(-1, -1)
	if mode != null:
		next_cell = mode.hint_next_cell(maze, current_pos)
	if next_cell == Vector2i(-1, -1):
		next_cell = hint_controller.get_next_step_hint(maze, current_pos)
	if next_cell != current_pos:
		if board_view.has_method("pulse_cell"):
			board_view.call("pulse_cell", next_cell)
	else:
		var wall_info := hint_controller.reveal_one_invisible_wall(maze)
		if not wall_info.is_empty() and board_view.has_method("reveal_wall_segment"):
			board_view.call("reveal_wall_segment", wall_info.is_h, wall_info.lattice)


func _record_edge(a: Vector2i, b: Vector2i) -> void:
	var key := _edge_key(a, b)
	if not _visited_edges.has(key):
		_visited_edges[key] = true
		if board_view != null and board_view.has_method("show_history_edge"):
			board_view.call("show_history_edge", a, b)


func _is_adjacent(a: Vector2i, b: Vector2i) -> bool:
	var d := (a - b).abs()
	return d.x + d.y == 1


func _edge_key(a: Vector2i, b: Vector2i) -> String:
	var lo: Vector2i
	var hi: Vector2i
	if a.x < b.x or (a.x == b.x and a.y < b.y):
		lo = a
		hi = b
	else:
		lo = b
		hi = a
	return "%d,%d->%d,%d" % [lo.x, lo.y, hi.x, hi.y]
