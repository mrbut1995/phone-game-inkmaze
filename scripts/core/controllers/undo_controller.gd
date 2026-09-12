class_name UndoController
extends RefCounted
## ============================================================================
## Controller: Quản lý Undo / Hoàn tác bước đi và tường nghi ngờ.
## ============================================================================

signal undo_performed(action_type: String, data: Dictionary)

var _history: Array[Dictionary] = []


func reset() -> void:
	_history.clear()


func record_move(from_pos: Vector2i, to_pos: Vector2i, step_cost: int) -> void:
	_history.append({
		"type": "move",
		"from": from_pos,
		"to": to_pos,
		"cost": step_cost
	})


func record_wall(is_h: bool, lattice: Vector2i, prev_state: bool) -> void:
	_history.append({
		"type": "wall",
		"is_h": is_h,
		"lattice": lattice,
		"prev_state": prev_state
	})


func can_undo() -> bool:
	return not _history.is_empty()


func pop_last_action() -> Dictionary:
	if _history.is_empty():
		return {}
	var action: Dictionary = _history.pop_back()
	undo_performed.emit(action.get("type", ""), action)
	return action
