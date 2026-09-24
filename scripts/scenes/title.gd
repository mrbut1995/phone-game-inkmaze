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

## Node UI của màn nằm trong BỐ CỤC đang hiển thị (`Portrait` / `Landscape` — 2 hướng dùng
## CÙNG tên node). Các node đã BIND SẴN bằng `@export` trong `scenes/layout/<hướng>/title.tscn`
## ⇒ code đọc qua `layout.<tên>`, KHÔNG tra đường dẫn; thêm/đổi node chỉ cần sửa scene + export.
var layout: TitleLayout = null

var _pencil_tween: Tween = null
var _pulse_tween: Tween = null
var _transitioning: bool = false


## Gắn node của layout đang hiển thị (2 layout giữ CÙNG đường dẫn node)
func _bind_refs() -> void:
	layout = active_layout() as TitleLayout
	if layout == null:
		push_warning("title: bố cục chưa gắn TitleLayout — thiếu binding trong scenes/layout/<hướng>/title.tscn")


func _ready() -> void:
	_bind_refs()
	_refresh_stamp()
	if layout.touch_button != null:
		layout.touch_button.pressed.connect(_on_start_pressed)
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
		return

	# Hiệu ứng hé mở từ trang giấy trắng/ngà sau khi chuyển từ Splash sang
	if layout.fade_overlay != null:
		layout.fade_overlay.visible = true
		layout.fade_overlay.modulate.a = 1.0
		var tw_in := create_tween()
		tw_in.tween_property(layout.fade_overlay, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_in.tween_callback(func() -> void: layout.fade_overlay.visible = false)

	# 1. Logo bồng bềnh nhẹ nhàng
	if layout.logo_container != null:
		UIAnim.play_float_idle(layout.logo_container, 7.0, 2.5)

	# 2. Ngòi bút chì phác họa nhẹ quanh logo
	if layout.pencil != null:
		layout.pencil.pivot_offset = Vector2(0, layout.pencil.size.y)
		_pencil_tween = create_tween().set_loops()
		_pencil_tween.tween_property(layout.pencil, "rotation_degrees", 14.0, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_pencil_tween.tween_property(layout.pencil, "rotation_degrees", -10.0, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# 3. Tiêu đề nảy nhẹ
	if layout.title_label != null:
		UIAnim.play_pop_in(layout.title_label, 0.08, 0.92, 0.3)
	if layout.subtitle_label != null:
		UIAnim.play_slide_in(layout.subtitle_label, Vector2(0, 15), 0.15, 0.28)

	# 4. "CHẠM ĐỂ BẮT ĐẦU" nhịp thở nhấp nhô liên tục
	if layout.tap_container != null:
		_pulse_tween = UIAnim.play_pulse(layout.tap_container, 1.06, 1.4)


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
	if layout.tap_container != null:
		layout.tap_container.pivot_offset = layout.tap_container.size * 0.5
		var tw_tap := create_tween()
		tw_tap.tween_property(layout.tap_container, "scale", Vector2(1.18, 0.88), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_tap.tween_property(layout.tap_container, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Mờ sang trang giấy ngà rồi chuyển vào Main Menu
	if layout.fade_overlay != null:
		layout.fade_overlay.visible = true
		layout.fade_overlay.modulate.a = 0.0
		var tw_out := create_tween()
		tw_out.tween_property(layout.fade_overlay, "modulate:a", 1.0, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_out.tween_callback(Callable(self, "_goto_main"))
	else:
		_goto_main()


func _goto_main() -> void:
	var sm := get_node_or_null("/root/SceneManager")
	if sm != null and sm.has_method("goto_main"):
		sm.call("goto_main")
	else:
		get_tree().change_scene_to_file(SCENE_MAIN)
