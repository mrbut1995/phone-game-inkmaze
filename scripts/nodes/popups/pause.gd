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
	_bind_slider(slider_music, "music", label_music)
	_bind_slider(slider_sfx, "sfx", label_sfx)
	_bind_toggle(check_haptic, "vibration")
	_bind_toggle(check_safe, "auto_mark_safe")
	_refresh_progress()
	_syncing = false

	bind_button("Panel/Content/ResumeBtn", _on_resume_pressed)
	bind_button("Panel/Content/RestartBtn", _on_restart_pressed)
	bind_button("Panel/Content/MenuBtn", _on_menu_pressed)


## Nối một slider với SettingManager (kind: master / music / sfx)
func _bind_slider(slider: HSlider, kind: String, value_label: Label) -> void:
	if slider == null:
		return
	var settings := _settings()
	var current := float(settings.call("get_volume", kind)) if settings != null else slider.value
	slider.value = current
	_update_percent(value_label, current)
	slider.value_changed.connect(func(v: float) -> void:
		if _syncing:
			return
		if settings != null:
			settings.call("set_volume", kind, v)
		_update_percent(value_label, v)
		Sfx.play(Sfx.SLIDER_TICK, 0.05)
	)


## Nối một checkbox với một khoá trong SettingManager
func _bind_toggle(button: TextureButton, key: String) -> void:
	if button == null:
		return
	var settings := _settings()
	if settings != null:
		button.button_pressed = bool(settings.call("get_setting", key, false))
	button.toggled.connect(func(pressed: bool) -> void:
		if _syncing:
			return
		if settings != null:
			settings.call("set_setting", key, pressed)
		Sfx.play(Sfx.CHECKBOX, 0.05)
	)


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
