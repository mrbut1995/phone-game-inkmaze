class_name SplashScene
extends BaseScene
## ============================================================================
## View Controller: Màn hình Splash (scenes/splash.tscn)
## - Hoạt ảnh xuất hiện logo Mực & Giấy (Ink bloom, nét vẽ bút chì phác thảo).
## - Tự động đếm giờ hoặc nhận chạm màn hình để chuyển sang Title Scene.
## - Chuyển cảnh mượt mà bằng hiệu ứng lật trang sổ tay & fade giấy ngà.
## ============================================================================

const UIAnim := preload("res://scripts/utils/ui_anim.gd")
const SCENE_TITLE := "res://scenes/title.tscn"

@onready var studio_label: Label = $Panel/StudioLabel
@onready var logo_container: Control = $Panel/LogoContainer
@onready var logo: TextureRect = $Panel/LogoContainer/Logo
@onready var pencil: TextureRect = $Panel/LogoContainer/Pencil
@onready var title_label: Label = $Panel/Title
@onready var tagline_label: Label = $Panel/Tagline
@onready var stamp_label: Label = $Panel/Stamp/Label
@onready var touch_button: TextureButton = $TouchButton
@onready var fade_overlay: ColorRect = $FadeOverlay

var _pencil_tween: Tween = null
var _transitioning: bool = false


func _ready() -> void:
	_refresh_stamp()
	if touch_button != null:
		touch_button.pressed.connect(_on_touch_pressed)
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
		_goto_title()
		return

	# Khởi tạo trạng thái ẩn ban đầu
	if studio_label != null:
		studio_label.modulate.a = 0.0
	if logo_container != null:
		logo_container.pivot_offset = logo_container.size * 0.5
		logo_container.scale = Vector2(0.3, 0.3)
		logo_container.modulate.a = 0.0
	if title_label != null:
		title_label.modulate.a = 0.0
	if tagline_label != null:
		tagline_label.modulate.a = 0.0
	if fade_overlay != null:
		fade_overlay.visible = false
		fade_overlay.modulate.a = 0.0

	# 1. Studio label hiện nhẹ
	if studio_label != null:
		var tw_studio := create_tween()
		tw_studio.tween_property(studio_label, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 2. Logo bung nở với hiệu ứng nét mực & đàn hồi
	if logo_container != null:
		var tw_logo := create_tween().set_parallel(true)
		tw_logo.tween_property(logo_container, "scale", Vector2.ONE, 0.55).set_delay(0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw_logo.tween_property(logo_container, "modulate:a", 1.0, 0.4).set_delay(0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 3. Ngòi bút chì vẽ phác thảo quanh logo
	if pencil != null:
		pencil.pivot_offset = Vector2(0, pencil.size.y)
		_pencil_tween = create_tween().set_loops()
		_pencil_tween.tween_property(pencil, "rotation_degrees", 16.0, 0.38).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_pencil_tween.tween_property(pencil, "rotation_degrees", -12.0, 0.38).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# 4. Tiêu đề và khẩu hiệu xuất hiện
	if title_label != null:
		UIAnim.play_pop_in(title_label, 0.45, 0.88, 0.35)
	if tagline_label != null:
		UIAnim.play_slide_in(tagline_label, Vector2(0, 15), 0.65, 0.3)

	# 5. Tự động chuyển cảnh sau 2.2 giây
	var tw_timer := create_tween()
	tw_timer.tween_interval(2.2)
	tw_timer.tween_callback(Callable(self, "_on_touch_pressed"))


func _on_touch_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	if _pencil_tween != null and _pencil_tween.is_valid():
		_pencil_tween.kill()

	Sfx.play(Sfx.PAGE_TURN)

	if DisplayServer.get_name() == "headless":
		_goto_title()
		return

	# Hiệu ứng chuyển cảnh mượt mà: Fade overlay giấy ngà che phủ rồi nạp Title Scene
	if fade_overlay != null:
		fade_overlay.visible = true
		fade_overlay.modulate.a = 0.0
		var tw_out := create_tween()
		tw_out.tween_property(fade_overlay, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_out.tween_callback(Callable(self, "_goto_title"))
	else:
		_goto_title()


func _goto_title() -> void:
	var sm := get_node_or_null("/root/SceneManager")
	if sm != null and sm.has_method("change_scene_instant"):
		sm.call("change_scene_instant", SCENE_TITLE, false)
	else:
		get_tree().change_scene_to_file(SCENE_TITLE)
