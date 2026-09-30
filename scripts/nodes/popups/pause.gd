class_name PausePopup
extends BasePopup
## ============================================================================
## Popup: Tạm dừng ván chơi (nodes/popups/pause.tscn)
## Mockup: mockup/popup_settings.svg
## - Chỉnh âm lượng BGM/SFX và 2 tuỳ chọn bàn cờ, đồng bộ thẳng với SettingManager
## - Hiển thị tiến độ hiện tại (tầng / số bước còn lại) từ dữ liệu truyền vào
## ============================================================================

signal resume_requested
signal restart_requested
signal menu_requested

@onready var slider_music: HSlider = piece("MusicSlider")
@onready var slider_sfx: HSlider = piece("SfxSlider")
@onready var label_music: Label = piece("MusicValue")
@onready var label_sfx: Label = piece("SfxValue")
@onready var check_haptic: TextureButton = piece("HapticCheck")
@onready var check_safe: TextureButton = piece("SafeCheck")

var _syncing := false


func _on_open() -> void:
	_syncing = true
	_init_slider(slider_music, "music", label_music)
	_init_slider(slider_sfx, "sfx", label_sfx)
	_init_toggle(check_haptic, "vibration")
	_init_toggle(check_safe, "auto_mark_safe")
	_refresh_progress()
	_syncing = false

	# Dây 3 nút (Tiếp tục / Chơi lại / Menu) + 2 slider + 2 checkbox khai trong `pause.tscn`


## Nạp giá trị âm lượng hiện tại của SettingManager vào slider
## (dây `value_changed` khai trong `pause.tscn` — cùng scene)
func _init_slider(slider: HSlider, kind: String, value_label: Label) -> void:
	if slider == null:
		return
	var settings := _settings()
	var current := float(settings.call("get_volume", kind)) if settings != null else slider.value
	slider.value = current
	_update_percent(value_label, current)


## Nạp trạng thái hiện tại của SettingManager vào checkbox (dây `toggled` khai trong `pause.tscn`)
func _init_toggle(button: TextureButton, key: String) -> void:
	if button == null:
		return
	var settings := _settings()
	if settings != null:
		button.button_pressed = bool(settings.call("get_setting", key, false))


func _on_music_value_changed(v: float) -> void:
	_apply_volume("music", v, label_music)


func _on_sfx_value_changed(v: float) -> void:
	_apply_volume("sfx", v, label_sfx)


## Ghi âm lượng vào SettingManager + cập nhật nhãn phần trăm (bỏ qua khi đang nạp giá trị)
func _apply_volume(kind: String, v: float, value_label: Label) -> void:
	if _syncing:
		return
	var settings := _settings()
	if settings != null:
		settings.call("set_volume", kind, v)
	_update_percent(value_label, v)
	Sfx.play(Sfx.SLIDER_TICK, 0.05)


func _on_haptic_toggled(pressed: bool) -> void:
	_apply_toggle("vibration", pressed)


func _on_safe_toggled(pressed: bool) -> void:
	_apply_toggle("auto_mark_safe", pressed)


## Ghi tuỳ chọn vào SettingManager (bỏ qua khi đang nạp trạng thái)
func _apply_toggle(key: String, pressed: bool) -> void:
	if _syncing:
		return
	var settings := _settings()
	if settings != null:
		settings.call("set_setting", key, pressed)
	Sfx.play(Sfx.CHECKBOX, 0.05)


func _update_percent(label: Label, value: float) -> void:
	if label != null:
		label.text = "%d%%" % int(round(value * 100.0))


## Thẻ tiến độ: tầng hiện tại + số bước còn lại
func _refresh_progress() -> void:
	var floor := int(data.get("floor", 1))
	var steps_left := int(data.get("steps_left", 0))
	var steps_max := int(data.get("steps_max", 0))
	var mode_name := str(data.get("mode_name", "DUNGEON")).to_upper()

	var value_floor := piece("InfoBox/ProgressValue") as Label
	if value_floor != null:
		value_floor.text = "%s %02d • %s" % [tr("STR_FLOOR_NUM").format([""]).strip_edges(), floor, mode_name]

	var value_steps := piece("InfoBox/StepsValue") as Label
	if value_steps != null:
		value_steps.text = "%d / %d" % [steps_left, steps_max]


func _settings() -> Node:
	return get_node_or_null("/root/SettingManager")


func _on_resume_pressed() -> void:
	Sfx.play(Sfx.BTN_WOOD_TAP)
	resume_requested.emit()
	close()


func _on_restart_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	restart_requested.emit()
	close()


func _on_menu_pressed() -> void:
	Sfx.play(Sfx.BTN_WOOD_TAP)
	menu_requested.emit()
	close()


## Back / Esc khi đang tạm dừng = tiếp tục chơi
func _on_close() -> void:
	resume_requested.emit()
