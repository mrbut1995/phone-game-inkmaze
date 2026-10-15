extends Node
## ============================================================================
## Manager: ScreenManager - Lịch sử điều hướng màn hình.
## - Dùng cho nút Back cứng trên Android / phím Esc (ui_cancel).
## - SceneManager tự đẩy màn hiện tại vào đây trước khi chuyển màn.
## ============================================================================

signal history_changed(size: int)

const MAX_HISTORY := 16

var _history: Array[String] = []
## Chống xử lý 2 lần cho CÙNG một lần bấm Back (Android vừa phát
## NOTIFICATION_WM_GO_BACK_REQUEST, vừa có phím Key::BACK)
var _back_busy := false


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
	# Phím Esc (desktop) / ui_cancel: quay lại màn trước nếu có lịch sử
	if not event.is_action_pressed("ui_cancel"):
		return
	if _handle_back(false):
		get_viewport().set_input_as_handled()


## Nút Back cứng Android: engine KHÔNG phát `ui_cancel` mà gửi notification này cho mọi
## node (xem Window::_propagate_window_notification). Project đặt
## `application/config/quit_on_go_back=false` nên app không tự thoát — điều hướng ở đây.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_handle_back(true)


## Một chỗ DUY NHẤT quyết định điều hướng Back. Trả về true nếu đã xử lý xong.
## `allow_quit` = true chỉ cho luồng Back hệ thống Android (ở màn chính thì thoát app);
## phím Esc trên desktop giữ nguyên hành vi cũ (không thoát app).
func _handle_back(allow_quit: bool) -> bool:
	if _back_busy:
		return false
	_back_busy = true
	call_deferred("_clear_back_busy")

	# Popup đang mở: đóng popup trên cùng, KHÔNG đổi màn hình
	var popup_manager: Node = get_node_or_null("/root/PopupManager")
	if popup_manager != null and popup_manager.has_method("has_open") \
			and bool(popup_manager.call("has_open")):
		var top_popup: Variant = popup_manager.call("top") if popup_manager.has_method("top") else null
		if top_popup != null and bool(top_popup.get("close_on_back")) \
				and popup_manager.has_method("close_top"):
			popup_manager.call("close_top")
		return true

	# Còn lịch sử ⇒ lùi về màn trước
	if go_back():
		return true

	# Hết lịch sử: về màn chính (SceneManager.go_back() tự fallback, KHÔNG ghi thêm lịch sử);
	# đang ở màn chính thì thoát app (chỉ luồng Back hệ thống Android)
	var scene_manager: Node = get_node_or_null("/root/SceneManager")
	if scene_manager == null:
		return false
	if not bool(scene_manager.call("is_main_scene")):
		scene_manager.call("go_back")
		return true
	if allow_quit:
		_quit_app()
	return true


func _clear_back_busy() -> void:
	_back_busy = false


## Thoát app (Android): lưu dữ liệu trước rồi mới thoát
func _quit_app() -> void:
	var save: Node = get_node_or_null("/root/SaveManager")
	if save != null and save.has_method("flush"):
		save.call("flush")
	get_tree().quit()
