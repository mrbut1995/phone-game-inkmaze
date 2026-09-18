class_name TitleScene
extends BaseScene
## ============================================================================
## View Controller: Màn hình Tiêu đề (scenes/title.tscn)
## - Hoạt ảnh bồng bềnh logo InkMaze & bút chì phác thảo.
## - Nút/vùng "CHẠM ĐỂ BẮT ĐẦU" (Tap to Start) thở nhịp nhàng thu hút sự chú ý.
## - Chuyển cảnh sang màn hình chính (Main Screen) bằng âm thanh lật trang sổ tay.
## ============================================================================

const UIAnim := preload("res://scripts/utils/ui_anim.gd")
const SCENE_MAIN := "res://scenes/main.tscn"

var logo_container: Control = null
var logo: TextureRect = null
var pencil: TextureRect = null
var title_label: Label = null
var subtitle_label: Label = null
var tap_container: Control = null
var play_icon: TextureRect = null
var tap_label: Label = null
var stamp_label: Label = null
var touch_button: TextureButton = null
var fade_overlay: ColorRect = null

var _pencil_tween: Tween = null
var _pulse_tween: Tween = null
var _transitioning: bool = false


## Gắn node của layout đang hiển thị (2 layout giữ CÙNG đường dẫn node)
func _bind_refs() -> void:
	logo_container = ui_path("Panel/LogoContainer") as Control
	logo = ui_path("Panel/LogoContainer/Logo") as TextureRect
	pencil = ui_path("Panel/LogoContainer/Pencil") as TextureRect
	title_label = ui_path("Panel/Title") as Label
	subtitle_label = ui_path("Panel/Subtitle") as Label
	tap_container = ui_path("Panel/TapContainer") as Control
	play_icon = ui_path("Panel/TapContainer/PlayIcon") as TextureRect
	tap_label = ui_path("Panel/TapContainer/TapLabel") as Label
	stamp_label = ui_path("Panel/Stamp/Label") as Label
	touch_button = ui_path("TouchButton") as TextureButton
	fade_overlay = ui_path("FadeOverlay") as ColorRect


func _ready() -> void:
	_bind_refs()
	_refresh_stamp()
	if touch_button != null:
		touch_button.pressed.connect(_on_start_pressed)
	_setup_animations()


func _refresh_stamp() -> void:
	if stamp_label == null:
		return
	var app := get_node_or_null("/root/AppManager")
	var version := "1.0.0"
	if app != null:
		version = str(app.call("get_version"))
	stamp_label.text = tr("STR_SETTINGS_VERSION").format([version])


func _setup_animations() -> void:
	if DisplayServer.get_name() == "headless":
		return

	# Hiệu ứng hé mở từ trang giấy trắng/ngà sau khi chuyển từ Splash sang
	if fade_overlay != null:
		fade_overlay.visible = true
		fade_overlay.modulate.a = 1.0
		var tw_in := create_tween()
		tw_in.tween_property(fade_overlay, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_in.tween_callback(func() -> void: fade_overlay.visible = false)

	# 1. Logo bồng bềnh nhẹ nhàng
	if logo_container != null:
		UIAnim.play_float_idle(logo_container, 7.0, 2.5)

	# 2. Ngòi bút chì phác họa nhẹ quanh logo
	if pencil != null:
		pencil.pivot_offset = Vector2(0, pencil.size.y)
		_pencil_tween = create_tween().set_loops()
		_pencil_tween.tween_property(pencil, "rotation_degrees", 14.0, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_pencil_tween.tween_property(pencil, "rotation_degrees", -10.0, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# 3. Tiêu đề nảy nhẹ
	if title_label != null:
		UIAnim.play_pop_in(title_label, 0.08, 0.92, 0.3)
	if subtitle_label != null:
		UIAnim.play_slide_in(subtitle_label, Vector2(0, 15), 0.15, 0.28)

	# 4. "CHẠM ĐỂ BẮT ĐẦU" nhịp thở nhấp nhô liên tục
	if tap_container != null:
		_pulse_tween = UIAnim.play_pulse(tap_container, 1.06, 1.4)


func _on_start_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true

	if _pencil_tween != null and _pencil_tween.is_valid():
		_pencil_tween.kill()
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()

	Sfx.play(Sfx.PAGE_TURN)

	if DisplayServer.get_name() == "headless":
		_goto_main()
		return

	# Hiệu ứng nảy xúc giác cho nút chạm bắt đầu
	if tap_container != null:
		tap_container.pivot_offset = tap_container.size * 0.5
		var tw_tap := create_tween()
		tw_tap.tween_property(tap_container, "scale", Vector2(1.18, 0.88), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_tap.tween_property(tap_container, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Mờ sang trang giấy ngà rồi chuyển vào Main Menu
	if fade_overlay != null:
		fade_overlay.visible = true
		fade_overlay.modulate.a = 0.0
		var tw_out := create_tween()
		tw_out.tween_property(fade_overlay, "modulate:a", 1.0, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_out.tween_callback(Callable(self, "_goto_main"))
	else:
		_goto_main()


func _goto_main() -> void:
	var sm := get_node_or_null("/root/SceneManager")
	if sm != null and sm.has_method("goto_main"):
		sm.call("goto_main")
	else:
		get_tree().change_scene_to_file(SCENE_MAIN)
