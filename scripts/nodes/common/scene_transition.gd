class_name SceneTransition
extends CanvasLayer
## ============================================================================
## Component: SceneTransition - Lớp phủ hiệu ứng chuyển cảnh toàn cục.
## Tái hiện phong cách "Sổ tay & Mực" (Ink & Paper):
##   - page_turn_forward  : lật sang trang tiếp theo (từ phải sang trái + bóng đổ)
##   - page_turn_backward : lật ngược lại trang trước (từ trái sang phải)
##   - ink_circle         : vết mực loang mở rộng che phủ rồi hé mở bàn cờ
##   - paper_fade         : chuyển cảnh mờ dần trên nền giấy nhám
##   - none               : chuyển cảnh tức thì (dùng cho tests hoặc khi tắt anim)
## ============================================================================

signal transition_started(style: String)
signal scene_swapped
signal transition_finished(style: String)

const COLOR_PAPER := Color(0.965, 0.945, 0.915, 1.0)          # Nền giấy ngà
const COLOR_INK := Color(0.133, 0.298, 0.427, 1.0)            # Lam mực đậm InkMaze
const COLOR_SHADOW := Color(0.12, 0.1, 0.08, 0.38)            # Bóng đổ mép gáy giấy

const DURATION_PAGE_IN := 0.22
const DURATION_PAGE_OUT := 0.22
const DURATION_INK := 0.24
const DURATION_FADE := 0.18

var _is_busy := false

# Các node giao diện dựng động
var _root_control: Control
var _blocker: Control
var _paper_page: Control
var _page_bg: ColorRect
var _page_shadow_left: TextureRect
var _page_shadow_right: TextureRect
var _watermark: TextureRect
var _ink_circle_drawer: Control
var _fade_rect: ColorRect

# Dữ liệu vẽ vết mực
var _ink_radius := 0.0
var _ink_max_radius := 1400.0


func _init() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	_build_ui()
	_reset_all()


func is_busy() -> bool:
	return _is_busy


## API chuyển cảnh chính: chạy hiệu ứng -> gọi callback đổi scene -> chạy hiệu ứng hé mở
func play_transition(target_path: String, change_callback: Callable, style := "page_turn_forward") -> void:
	if _is_busy:
		push_warning("[SceneTransition] Dang trong qua trinh chuyen canh, bo qua.")
		return

	_is_busy = true
	_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	transition_started.emit(style)

	match style:
		"page_turn_forward":
			await _run_page_turn(target_path, change_callback, true)
		"page_turn_backward":
			await _run_page_turn(target_path, change_callback, false)
		"ink_circle":
			await _run_ink_circle(target_path, change_callback)
		"paper_fade":
			await _run_paper_fade(target_path, change_callback)
		_:
			# Chuyển cảnh tức thì (không hiệu ứng)
			if change_callback.is_valid():
				change_callback.call()
			scene_swapped.emit()

	_reset_all()
	_blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_is_busy = false
	transition_finished.emit(style)


# ---------------------------------------------------------------------------
# Các hiệu ứng chuyển cảnh
# ---------------------------------------------------------------------------

## Hiệu ứng lật trang sổ tay
func _run_page_turn(target_path: String, change_callback: Callable, forward: bool) -> void:
	var vp_size := _get_screen_size()
	var w := vp_size.x
	var h := vp_size.y

	_paper_page.visible = true
	_paper_page.size = Vector2(w, h)
	_page_bg.size = Vector2(w, h)
	_watermark.position = (Vector2(w, h) - _watermark.size) * 0.5

	# Cấu hình bóng đổ mép trang giấy
	_page_shadow_left.visible = forward
	_page_shadow_right.visible = not forward

	var start_x: float = w if forward else -w
	var end_x: float = -w if forward else w

	_paper_page.position = Vector2(start_x, 0.0)

	# Phase 1: Trang giấy lướt vào che kín màn hình
	var tw_in := create_tween()
	tw_in.tween_property(_paper_page, "position:x", 0.0, DURATION_PAGE_IN).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tw_in.finished

	# Phase 2: Thực hiện đổi scene
	if change_callback.is_valid():
		change_callback.call()
	scene_swapped.emit()
	await _wait_frames(2)

	# Phase 3: Trang giấy lướt tiếp ra ngoài để hé mở scene mới
	var tw_out := create_tween()
	tw_out.tween_property(_paper_page, "position:x", end_x, DURATION_PAGE_OUT).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tw_out.finished


## Hiệu ứng vết mực tròn loang ra (Ink Circle Bloom)
func _run_ink_circle(target_path: String, change_callback: Callable) -> void:
	var vp_size := _get_screen_size()
	_ink_max_radius = vp_size.length() * 0.65
	_ink_circle_drawer.visible = true
	_ink_circle_drawer.modulate.a = 1.0
	_ink_radius = 0.0

	# Phase 1: Mực loang từ tâm che phủ màn hình
	var tw_in := create_tween()
	tw_in.tween_method(_set_ink_radius, 0.0, _ink_max_radius, DURATION_INK).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw_in.finished

	# Phase 2: Đổi scene
	if change_callback.is_valid():
		change_callback.call()
	scene_swapped.emit()
	await _wait_frames(2)

	# Phase 3: Mực tan biến mờ dần hé lộ màn chơi
	var tw_out := create_tween()
	tw_out.set_parallel(true)
	tw_out.tween_property(_ink_circle_drawer, "modulate:a", 0.0, DURATION_PAGE_OUT).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw_out.tween_method(_set_ink_radius, _ink_max_radius, _ink_max_radius * 1.3, DURATION_PAGE_OUT).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw_out.finished


## Hiệu ứng mờ dần (Paper Fade)
func _run_paper_fade(target_path: String, change_callback: Callable) -> void:
	_fade_rect.visible = true
	_fade_rect.modulate.a = 0.0

	var tw_in := create_tween()
	tw_in.tween_property(_fade_rect, "modulate:a", 1.0, DURATION_FADE).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw_in.finished

	if change_callback.is_valid():
		change_callback.call()
	scene_swapped.emit()
	await _wait_frames(2)

	var tw_out := create_tween()
	tw_out.tween_property(_fade_rect, "modulate:a", 0.0, DURATION_FADE).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw_out.finished


# ---------------------------------------------------------------------------
# Xây dựng giao diện tĩnh & trợ giúp
# ---------------------------------------------------------------------------
func _build_ui() -> void:
	_root_control = Control.new()
	_root_control.name = "TransitionRoot"
	_root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root_control)

	_blocker = Control.new()
	_blocker.name = "InputBlocker"
	_blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
	_blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root_control.add_child(_blocker)

	# 1. Trang giấy lật
	_paper_page = Control.new()
	_paper_page.name = "PaperPage"
	_paper_page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root_control.add_child(_paper_page)

	_page_bg = ColorRect.new()
	_page_bg.name = "PaperBg"
	_page_bg.color = COLOR_PAPER
	_page_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paper_page.add_child(_page_bg)

	# Bóng mép trái (cho lật xuôi)
	_page_shadow_left = TextureRect.new()
	_page_shadow_left.name = "ShadowLeft"
	_page_shadow_left.size = Vector2(70, 1920)
	_page_shadow_left.position = Vector2(-70, 0)
	_page_shadow_left.texture = _create_gradient_texture(COLOR_SHADOW, Color(0, 0, 0, 0))
	_page_shadow_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paper_page.add_child(_page_shadow_left)

	# Bóng mép phải (cho lật ngược)
	_page_shadow_right = TextureRect.new()
	_page_shadow_right.name = "ShadowRight"
	_page_shadow_right.size = Vector2(70, 1920)
	_page_shadow_right.position = Vector2(1080, 0)
	_page_shadow_right.texture = _create_gradient_texture(Color(0, 0, 0, 0), COLOR_SHADOW)
	_page_shadow_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paper_page.add_child(_page_shadow_right)

	# Logo/dấu mờ InkMaze giữa trang giấy
	_watermark = TextureRect.new()
	_watermark.name = "Watermark"
	_watermark.size = Vector2(320, 320)
	_watermark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_watermark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_watermark.modulate = Color(0.133, 0.298, 0.427, 0.15)
	var logo_tex := load("res://icon.svg") as Texture2D
	if logo_tex != null:
		_watermark.texture = logo_tex
	_watermark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paper_page.add_child(_watermark)

	# 2. Vết mực tròn
	_ink_circle_drawer = Control.new()
	_ink_circle_drawer.name = "InkCircleDrawer"
	_ink_circle_drawer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ink_circle_drawer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ink_circle_drawer.draw.connect(_on_ink_draw)
	_root_control.add_child(_ink_circle_drawer)

	# 3. Lớp phủ Fade giấy
	_fade_rect = ColorRect.new()
	_fade_rect.name = "FadeRect"
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.color = COLOR_PAPER
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root_control.add_child(_fade_rect)


func _reset_all() -> void:
	if _paper_page != null:
		_paper_page.visible = false
	if _ink_circle_drawer != null:
		_ink_circle_drawer.visible = false
		_ink_radius = 0.0
	if _fade_rect != null:
		_fade_rect.visible = false
	if _blocker != null:
		_blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _set_ink_radius(r: float) -> void:
	_ink_radius = r
	if _ink_circle_drawer != null:
		_ink_circle_drawer.queue_redraw()


func _on_ink_draw() -> void:
	if _ink_radius <= 0.0 or not _ink_circle_drawer.visible:
		return
	var center := _get_screen_size() * 0.5
	_ink_circle_drawer.draw_circle(center, _ink_radius, COLOR_INK)


func _get_screen_size() -> Vector2:
	var vp := get_viewport()
	if vp != null:
		var rect := vp.get_visible_rect()
		if rect.size.x > 0 and rect.size.y > 0:
			return rect.size
	return Vector2(1080, 1920)


func _create_gradient_texture(color_from: Color, color_to: Color) -> GradientTexture2D:
	var grad := Gradient.new()
	grad.colors = PackedColorArray([color_from, color_to])
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.width = 64
	tex.height = 64
	tex.fill_from = Vector2(0.0, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	return tex


func _wait_frames(count: int) -> void:
	var tree := get_tree()
	if tree == null:
		return
	for i in count:
		await tree.process_frame
