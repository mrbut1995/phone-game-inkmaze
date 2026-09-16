extends Node
## ============================================================================
## Manager: PopupManager - Quản lý vòng đời popup cho toàn bộ game.
##
## Nguyên tắc:
##   - Popup KHÔNG instance sẵn trong scene. Manager TẠO khi mở và XOÁ khi đóng.
##   - Popup được gắn vào node "Popups" của scene hiện tại (scenes/base.tscn).
##     Nếu scene không có node này, manager tự tạo một Control full-screen.
##   - Mở nhiều popup được: popup mở sau nằm trên, đóng theo thứ tự ngược lại.
##   - Nút Back (ui_cancel) đóng popup trên cùng thay vì thoát màn hình.
## ============================================================================

signal popup_opened(id: String)
signal popup_closed(id: String)

## Id -> scene của các popup có sẵn trong game
const POPUPS := {
	"win": "res://nodes/popups/winning.tscn",
	"win_daily": "res://nodes/popups/winning_daily.tscn",
	"game_over": "res://nodes/popups/gameover.tscn",
	"game_over_level": "res://nodes/popups/gameover_level.tscn",
	"next_floor": "res://nodes/popups/next_floor.tscn",
	"pause": "res://nodes/popups/pause.tscn",
	"language": "res://nodes/popups/language.tscn",
	"memory_countdown": "res://nodes/popups/memory_countdown.tscn",
}

const HOST_NAME := "Popups"

var _stack: Array[BasePopup] = []
var _host: Control = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


# --- API mở popup -----------------------------------------------------------

## Mở popup theo id định nghĩa trong POPUPS. Trả về node popup (null nếu lỗi).
func open_popup(id: String, data: Dictionary = {}) -> BasePopup:
	if not POPUPS.has(id):
		push_warning("PopupManager: khong co popup id '%s'" % id)
		return null
	var existing := get_popup(id)
	if existing != null:
		# Đã mở: đưa lên trên cùng và cập nhật dữ liệu mới
		existing.move_to_front()
		existing.call("open", data)
		return existing
	return open_path(POPUPS[id], data, id)


## Mở popup từ đường dẫn scene (dùng cho popup ngoài danh sách POPUPS).
func open_path(path: String, data: Dictionary = {}, id: String = "") -> BasePopup:
	var packed: PackedScene = load(path)
	if packed == null:
		push_error("PopupManager: khong load duoc popup '%s'" % path)
		return null
	var popup := packed.instantiate() as BasePopup
	if popup == null:
		push_error("PopupManager: '%s' khong phai BasePopup" % path)
		return null

	if id == "":
		id = path.get_file().get_basename()
	popup.popup_id = id
	# Popup luôn nhận input kể cả khi cây scene bị tạm dừng (pause menu)
	popup.process_mode = Node.PROCESS_MODE_ALWAYS

	var host := get_host()
	host.add_child(popup)
	_stack.append(popup)
	popup.closed.connect(_on_popup_closed.bind(popup))
	popup.opened.connect(func() -> void: popup_opened.emit(id))
	popup.open(data)
	return popup


# --- API đóng popup ---------------------------------------------------------

## Đóng một popup cụ thể.
func close_popup(popup: BasePopup) -> void:
	if popup != null and is_instance_valid(popup):
		popup.call("close")


## Đóng popup trên cùng. Trả về true nếu đã đóng.
func close_top() -> bool:
	var popup := top()
	if popup == null:
		return false
	popup.call("close")
	return true


## Đóng tất cả popup đang mở.
func close_all() -> void:
	for popup in _stack.duplicate():
		if is_instance_valid(popup):
			popup.call("close")


## Đóng popup theo id. Trả về true nếu có popup được đóng.
func close_id(id: String) -> bool:
	var popup := get_popup(id)
	if popup == null:
		return false
	popup.call("close")
	return true


# --- Truy vấn ---------------------------------------------------------------

## Popup trên cùng (null nếu không có popup nào).
func top() -> BasePopup:
	_clean_stack()
	return _stack.back() if not _stack.is_empty() else null


## Popup đang mở theo id.
func get_popup(id: String) -> BasePopup:
	_clean_stack()
	for popup in _stack:
		if popup.popup_id == id:
			return popup
	return null


func has_open() -> bool:
	_clean_stack()
	return not _stack.is_empty()


func is_open(id: String) -> bool:
	return get_popup(id) != null


## Node chứa popup của scene hiện tại (scenes/base.tscn -> "Popups").
func get_host() -> Control:
	if _host != null and is_instance_valid(_host):
		return _host

	var scene := get_tree().current_scene
	if scene == null:
		scene = get_tree().root

	_host = scene.find_child(HOST_NAME, true, false) as Control
	if _host == null:
		# Scene không có sẵn node Popups -> tự tạo lớp phủ full-screen
		_host = Control.new()
		_host.name = HOST_NAME
		_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
		scene.add_child(_host)
	return _host


# --- Nội bộ -----------------------------------------------------------------

func _on_popup_closed(popup: BasePopup) -> void:
	_stack.erase(popup)
	popup_closed.emit(popup.popup_id)


func _clean_stack() -> void:
	for i in range(_stack.size() - 1, -1, -1):
		if not is_instance_valid(_stack[i]):
			_stack.remove_at(i)


func _unhandled_input(event: InputEvent) -> void:
	# Back Android / Esc: đóng popup trên cùng trước khi xử lý điều hướng màn hình
	if not event.is_action_pressed("ui_cancel"):
		return
	if not has_open():
		return
	if (top() as BasePopup).close_on_back:
		close_top()
		get_viewport().set_input_as_handled()
