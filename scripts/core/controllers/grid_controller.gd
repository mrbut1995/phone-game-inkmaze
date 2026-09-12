class_name GridController
extends RefCounted
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

var maze: MazeData = null
var view: Control = null
var anchor_controller: AnchorController = null
var undo_controller: UndoController = null
var hint_controller: HintController = null
var game_mode: BaseGameMode = null

var current_pos: Vector2i = Vector2i.ZERO
var path: Array[Vector2i] = []
var _visited_edges: Dictionary = {}


func _init(
	p_view: Control = null,
	p_anchor_controller: AnchorController = null,
	p_mode: BaseGameMode = null,
	p_undo_controller: UndoController = null,
	p_hint_controller: HintController = null
) -> void:
	view = p_view
	anchor_controller = p_anchor_controller if p_anchor_controller != null else AnchorController.new()
	undo_controller = p_undo_controller if p_undo_controller != null else UndoController.new()
	hint_controller = p_hint_controller if p_hint_controller != null else HintController.new()
	game_mode = p_mode if p_mode != null else DungeonGameMode.new()

	anchor_controller.suspected_wall_toggled.connect(_on_suspected_wall_toggled)


func set_game_mode(p_mode: BaseGameMode) -> void:
	game_mode = p_mode


func set_maze(p_maze: MazeData) -> void:
	maze = p_maze
	current_pos = maze.get_start()
	path = [current_pos]
	_visited_edges.clear()
	if anchor_controller != null:
		anchor_controller.reset()
	if undo_controller != null:
		undo_controller.reset()
	if game_mode != null and view != null:
		game_mode.on_grid_setup(view, maze)


# ---------------------------------------------------------------------------
# Handlers nhận signal từ View
# ---------------------------------------------------------------------------
func handle_cell_pressed(pos: Vector2i) -> void:
	if view != null and view.has_method("highlight_real_walls_of_cell"):
		view.call("highlight_real_walls_of_cell", pos)


func handle_drag_updated(pos: Vector2i) -> void:
	try_move_to(pos)


func handle_anchor_connected(corner_a: Vector2i, corner_b: Vector2i) -> void:
	if anchor_controller != null:
		anchor_controller.handle_anchor_connection(corner_a, corner_b)
		if game_mode != null and game_mode.check_completion(current_pos, maze, anchor_controller):
			reached_end.emit()


func _on_suspected_wall_toggled(is_h: bool, lattice: Vector2i, active: bool) -> void:
	if view != null and view.has_method("set_suspected_wall"):
		view.call("set_suspected_wall", is_h, lattice, active)


# ---------------------------------------------------------------------------
# Logic di chuyển theo GameMode Strategy
# ---------------------------------------------------------------------------
func try_move_to(pos: Vector2i) -> void:
	if maze == null or view == null or game_mode == null:
		return
	if not maze.is_in_bounds(pos):
		return
	if pos == current_pos:
		return
	if not _is_adjacent(current_pos, pos):
		return

	var step_cost := game_mode.get_step_cost(current_pos, pos, maze)
	var eval_result := game_mode.evaluate_move(current_pos, pos, maze)

	if eval_result.get("is_hazard", false):
		var hazard_type: String = eval_result.get("hazard_type", "wall")
		var from_cell: Vector2i = current_pos
		current_pos = maze.get_start()
		path = [current_pos]

		step_consumed.emit(step_cost, true)
		wall_hit.emit()

		if hazard_type == "mine":
			var mine_pos: Vector2i = eval_result.get("pos", pos)
			if view.has_method("show_mine_hit"):
				view.call("show_mine_hit", mine_pos)
		else:
			if view.has_method("show_wall_hit"):
				view.call("show_wall_hit", from_cell, pos)

		if view.has_method("reset_to_start"):
			view.call("reset_to_start")
	elif eval_result.get("allowed", false):
		var prev_pos := current_pos
		_record_edge(current_pos, pos)
		current_pos = pos
		path.append(pos)

		if undo_controller != null:
			undo_controller.record_move(prev_pos, pos, step_cost)

		if view.has_method("move_cursor_to"):
			view.call("move_cursor_to", pos)
		if view.has_method("set_moving_path"):
			view.call("set_moving_path", path)

		game_mode.on_player_moved(view, pos, maze)
		step_consumed.emit(step_cost, false)

		if game_mode.check_completion(current_pos, maze, anchor_controller):
			reached_end.emit()


# ---------------------------------------------------------------------------
# Undo & Hint Support
# ---------------------------------------------------------------------------
func undo_last_move() -> bool:
	if undo_controller == null or not undo_controller.can_undo():
		return false

	var action := undo_controller.pop_last_action()
	if action.get("type", "") == "move":
		var target_pos: Vector2i = action.get("from", maze.get_start())
		current_pos = target_pos
		if path.size() > 1:
			path.pop_back()
		if view != null:
			if view.has_method("move_cursor_to"):
				view.call("move_cursor_to", current_pos)
			if view.has_method("set_moving_path"):
				view.call("set_moving_path", path)
		return true
	return false


func give_hint() -> void:
	if hint_controller == null or maze == null or view == null:
		return
	var next_cell := hint_controller.get_next_step_hint(maze, current_pos)
	if next_cell != current_pos:
		if view.has_method("pulse_cell"):
			view.call("pulse_cell", next_cell)
	else:
		var wall_info := hint_controller.reveal_one_invisible_wall(maze)
		if not wall_info.is_empty() and view.has_method("reveal_wall_segment"):
			view.call("reveal_wall_segment", wall_info.is_h, wall_info.lattice)


func _record_edge(a: Vector2i, b: Vector2i) -> void:
	var key := _edge_key(a, b)
	if not _visited_edges.has(key):
		_visited_edges[key] = true
		if view != null and view.has_method("show_history_edge"):
			view.call("show_history_edge", a, b)


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
