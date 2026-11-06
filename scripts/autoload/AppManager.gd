extends Node
## ============================================================================
## Manager: AppManager - Vòng đời ứng dụng (quan trọng trên Android).
## - Phát signal app_paused / app_resumed khi app bị ẩn / mở lại.
## - Thông tin phiên bản + tiện ích thoát game.
## ============================================================================

signal app_paused
signal app_resumed

var is_mobile := false
var is_paused := false

var _orient_check_accum := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	is_mobile = OS.has_feature("mobile")


## Trên Android, cửa sổ game có thể LỆCH HƯỚNG so với màn hình đang hiển thị
## (màn hình bị xoay bằng khoá xoay / adb mà cảm biến không đổi, hoặc app mở lúc
## máy đang xoay): khi đó game vẽ một canvas khác hướng => nội dung bị cắt, popup
## trôi ra ngoài vùng nhìn thấy, màn loading không phủ đúng. Tự phát hiện & đồng bộ lại.
func _process(delta: float) -> void:
	if not is_mobile:
		return
	_orient_check_accum += delta
	if _orient_check_accum < 0.5:
		return
	_orient_check_accum = 0.0
	sync_window_orientation()


## Ép cửa sổ theo kích thước MÀN HÌNH THẬT khi hai bên lệch hướng.
## Trả về true nếu vừa phát hiện lệch (đã yêu cầu đồng bộ).
func sync_window_orientation() -> bool:
	var win := DisplayServer.window_get_size()
	var scr := DisplayServer.screen_get_size()
	if win.x <= 0 or win.y <= 0 or scr.x <= 0 or scr.y <= 0:
		return false
	if (win.x > win.y) == (scr.x > scr.y):
		return false
	DisplayServer.window_set_size(scr)
	return true


func get_version() -> String:
	var version := str(ProjectSettings.get_setting("application/config/version", ""))
	return version if not version.is_empty() else "1.0.0"


func quit_app() -> void:
	get_tree().quit()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			if not is_paused:
				is_paused = true
				app_paused.emit()
		NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN:
			if is_paused:
				is_paused = false
				app_resumed.emit()
