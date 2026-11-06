## SafeArea — Autoload singleton
## Đọc vùng an toàn màn hình từ DisplayServer và cung cấp cho toàn ứng dụng.
## Dùng để đẩy UI lên khỏi thanh điều hướng hệ thống / vùng notch trên Android.
extends Node

## Phát khi safe area thay đổi (xoay màn hình, cửa sổ thay đổi kích thước...)
signal changed(insets: Rect2i)

## Insets hiện tại: x=left, y=top, width=right, height=bottom
var insets: Rect2i = Rect2i()

## Lề dưới (pixel màn hình thực) mà UI cần nhường cho thanh điều hướng hệ thống
var bottom: int = 0
## Lề trên (pixel màn hình thực) mà UI cần nhường cho notch
var top: int = 0
## Lề trái
var left: int = 0
## Lề phải
var right: int = 0

var _last_safe: Rect2i = Rect2i(-1, -1, -1, -1)
## Số frame còn lại cần poll (để bắt inset ban đầu trên Android)
var _poll_frames: int = 10


func _ready() -> void:
	_refresh()
	# Lắng nghe thay đổi kích thước cửa sổ (xoay màn hình, multi-window...)
	var win := get_window()
	if win:
		win.size_changed.connect(_on_window_size_changed)
	# Poll vài frame đầu để bắt inset Android khởi động chậm
	set_process(_poll_frames > 0)


func _process(_delta: float) -> void:
	_refresh()
	_poll_frames -= 1
	if _poll_frames <= 0:
		set_process(false)


func _on_window_size_changed() -> void:
	_refresh()


func _refresh() -> void:
	var win: Window = get_window()
	if win == null:
		return
	var safe := _read_insets(win)
	if safe == _last_safe:
		return
	_last_safe = safe

	left   = safe.position.x
	top    = safe.position.y
	right  = safe.size.x
	bottom = safe.size.y

	insets = safe
	changed.emit(insets)


## Đọc vùng an toàn của MÀN HÌNH và quy về insets (x=left, y=top, width=right, height=bottom).
## Trả về Rect2i() khi không có vùng an toàn cần bù (desktop, cửa sổ không phủ kín màn…).
func _read_insets(win: Window) -> Rect2i:
	# Chỉ Android/iOS mới có vùng an toàn thực sự (notch, thanh điều hướng).
	# Trên desktop `get_display_safe_area()` trả về work-area (đã trừ taskbar) — KHÔNG
	# phải inset của UI nên bỏ qua để tránh đẩy UI lên sai.
	if not OS.has_feature("mobile"):
		return Rect2i()

	var screen_idx := win.current_screen
	if screen_idx < 0:
		screen_idx = DisplayServer.get_primary_screen()
	var screen_size := DisplayServer.screen_get_size(screen_idx)
	if screen_size.x <= 0 or screen_size.y <= 0:
		return Rect2i()

	var safe := DisplayServer.get_display_safe_area()
	if safe.size.x <= 0 or safe.size.y <= 0:
		return Rect2i()

	# Cửa sổ phải phủ kín màn hình thì mới quy đổi được safe area (màn hình chờ của app).
	if absi(win.size.x - screen_size.x) > 2 or absi(win.size.y - screen_size.y) > 2:
		return Rect2i()

	return Rect2i(
		maxi(safe.position.x, 0),
		maxi(safe.position.y, 0),
		maxi(screen_size.x - safe.end.x, 0),
		maxi(screen_size.y - safe.end.y, 0)
	)


## Trả về bottom inset đã nhân tỉ lệ canvas stretch (đơn vị UI pixel Godot).
## Dùng trực tiếp để set `custom_minimum_size` hoặc offset cho node Control.
func bottom_ui() -> float:
	var vp := get_viewport()
	var win := get_window()
	if vp == null or win == null or win.size.y == 0:
		return float(bottom)
	# canvas_items stretch: viewport design size / window physical size
	var scale_y := float(vp.size.y) / float(win.size.y)
	return float(bottom) * scale_y


## Trả về top inset đã nhân tỉ lệ canvas stretch (đơn vị UI pixel Godot).
func top_ui() -> float:
	var vp := get_viewport()
	var win := get_window()
	if vp == null or win == null or win.size.y == 0:
		return float(top)
	var scale_y := float(vp.size.y) / float(win.size.y)
	return float(top) * scale_y
