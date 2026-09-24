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

## Node UI của màn nằm trong BỐ CỤC đang hiển thị (`Portrait` / `Landscape` — 2 hướng dùng
## CÙNG tên node). Các node đã BIND SẴN bằng `@export` trong `scenes/layout/<hướng>/splash.tscn`
## ⇒ code đọc qua `layout.<tên>`, KHÔNG tra đường dẫn; thêm/đổi node chỉ cần sửa scene + export.
var layout: SplashLayout = null

var _pencil_tween: Tween = null
var _transitioning: bool = false


## Gắn node của layout đang hiển thị (2 layout giữ CÙNG đường dẫn node)
func _bind_refs() -> void:
	layout = active_layout() as SplashLayout
	if layout == null:
		push_warning("splash: bố cục chưa gắn SplashLayout — thiếu binding trong scenes/layout/<hướng>/splash.tscn")


func _ready() -> void:
	_bind_refs()
	_refresh_stamp()
	if layout.touch_button != null:
		layout.touch_button.pressed.connect(_on_touch_pressed)
	_setup_animations()


func _refresh_stamp() -> void:
	if layout.stamp_label == null:
		return
	var app := get_node_or_null("/root/AppManager")
	var version := "1.0.0"
	if app != null:
		version = str(app.call("get_version"))
	layout.stamp_label.text = tr("STR_SETTINGS_VERSION").format([version])


func _setup_animations() -> void:
	if DisplayServer.get_name() == "headless":
		_goto_title()
		return

	# Khởi tạo trạng thái ẩn ban đầu
	if layout.studio_label != null:
		layout.studio_label.modulate.a = 0.0
	if layout.logo_container != null:
		layout.logo_container.pivot_offset = layout.logo_container.size * 0.5
		layout.logo_container.scale = Vector2(0.3, 0.3)
		layout.logo_container.modulate.a = 0.0
	if layout.title_label != null:
		layout.title_label.modulate.a = 0.0
	if layout.tagline_label != null:
		layout.tagline_label.modulate.a = 0.0
	if layout.fade_overlay != null:
		layout.fade_overlay.visible = false
		layout.fade_overlay.modulate.a = 0.0

	# 1. Studio label hiện nhẹ
	if layout.studio_label != null:
		var tw_studio := create_tween()
		tw_studio.tween_property(layout.studio_label, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 2. Logo bung nở với hiệu ứng nét mực & đàn hồi
	if layout.logo_container != null:
		var tw_logo := create_tween().set_parallel(true)
		tw_logo.tween_property(layout.logo_container, "scale", Vector2.ONE, 0.55).set_delay(0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw_logo.tween_property(layout.logo_container, "modulate:a", 1.0, 0.4).set_delay(0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 3. Ngòi bút chì vẽ phác thảo quanh logo
	if layout.pencil != null:
		layout.pencil.pivot_offset = Vector2(0, layout.pencil.size.y)
		_pencil_tween = create_tween().set_loops()
		_pencil_tween.tween_property(layout.pencil, "rotation_degrees", 16.0, 0.38).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_pencil_tween.tween_property(layout.pencil, "rotation_degrees", -12.0, 0.38).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# 4. Tiêu đề và khẩu hiệu xuất hiện
	if layout.title_label != null:
		UIAnim.play_pop_in(layout.title_label, 0.45, 0.88, 0.35)
	if layout.tagline_label != null:
		UIAnim.play_slide_in(layout.tagline_label, Vector2(0, 15), 0.65, 0.3)

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
	if layout.fade_overlay != null:
		layout.fade_overlay.visible = true
		layout.fade_overlay.modulate.a = 0.0
		var tw_out := create_tween()
		tw_out.tween_property(layout.fade_overlay, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_out.tween_callback(Callable(self, "_goto_title"))
	else:
		_goto_title()


func _goto_title() -> void:
	var sm := get_node_or_null("/root/SceneManager")
	if sm != null and sm.has_method("change_scene_instant"):
		sm.call("change_scene_instant", SCENE_TITLE, false)
	else:
		get_tree().change_scene_to_file(SCENE_TITLE)
