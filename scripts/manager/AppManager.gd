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


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	is_mobile = OS.has_feature("mobile")


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
