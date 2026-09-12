extends Node
## ============================================================================
## Manager: ScreenManager - Lịch sử điều hướng màn hình.
## - Dùng cho nút Back cứng trên Android / phím Esc (ui_cancel).
## - SceneManager tự đẩy màn hiện tại vào đây trước khi chuyển màn.
## ============================================================================

signal history_changed(size: int)

const MAX_HISTORY := 16

var _history: Array[String] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func push_history(path: String) -> void:
	if path.is_empty():
		return
	if not _history.is_empty() and _history.back() == path:
		return
	_history.append(path)
	while _history.size() > MAX_HISTORY:
		_history.pop_front()
	history_changed.emit(_history.size())


func pop_history() -> String:
	if _history.is_empty():
		return ""
	var path: String = _history.pop_back()
	history_changed.emit(_history.size())
	return path


func can_go_back() -> bool:
	return not _history.is_empty()


func clear_history() -> void:
	_history.clear()
	history_changed.emit(0)


## Quay lại màn trước đó (nếu có). Trả về true nếu đã chuyển màn.
func go_back() -> bool:
	if not can_go_back():
		return false
	var path := pop_history()
	var scene_manager: Variant = get_node_or_null("/root/SceneManager")
	if scene_manager != null and scene_manager.has_method("change_scene"):
		scene_manager.call("change_scene", path, false)
	else:
		get_tree().change_scene_to_file(path)
	return true


func _unhandled_input(event: InputEvent) -> void:
	# Nút Back Android / Esc: quay lại màn trước nếu có lịch sử
	if not event.is_action_pressed("ui_cancel"):
		return
	if go_back():
		get_viewport().set_input_as_handled()
