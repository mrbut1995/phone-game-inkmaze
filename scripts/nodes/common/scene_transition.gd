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
##
## TOÀN BỘ NODE GIAO DIỆN ĐƯỢC KHAI BÁO SẴN trong scenes/loading.tscn —
## script KHÔNG tạo node lúc chạy, chỉ bật/tắt + tween:
##   Loading (CanvasLayer, layer 128)
##   └── TransitionRoot
##       ├── InputBlocker    (chặn input khi đang chuyển cảnh)
##       ├── PaperPage       (trang giấy lật) + PaperBg / ShadowLeft / ShadowRight / Watermark
##       ├── InkCircleDrawer (vẽ vết mực loang - nối signal `draw` trong _ready)
##       └── FadeRect        (lớp mờ dần)
## ============================================================================

signal transition_started(style: String)
signal scene_swapped
signal transition_finished(style: String)

const COLOR_PAPER := Color(0.965, 0.945, 0.915, 1.0)          # Nền giấy ngà
const COLOR_INK := Color(0.133, 0.298, 0.427, 1.0)            # Lam mực đậm InkMaze

const DURATION_PAGE_IN := 0.22
const DURATION_PAGE_OUT := 0.22
const DURATION_INK := 0.24
const DURATION_FADE := 0.18

## Đường dẫn node giao diện trong scenes/loading.tscn (không đổi tên nếu không sửa scene)
const NODE_TRANSITION_ROOT := "TransitionRoot"
const NODE_BLOCKER := "TransitionRoot/InputBlocker"
const NODE_PAPER_PAGE := "TransitionRoot/PaperPage"
const NODE_PAPER_BG := "TransitionRoot/PaperPage/PaperBg"
const NODE_SHADOW_LEFT := "TransitionRoot/PaperPage/ShadowLeft"
const NODE_SHADOW_RIGHT := "TransitionRoot/PaperPage/ShadowRight"
const NODE_WATERMARK := "TransitionRoot/PaperPage/Watermark"
const NODE_INK_DRAWER := "TransitionRoot/InkCircleDrawer"
const NODE_FADE_RECT := "TransitionRoot/FadeRect"

var _is_busy := false

# Node giao diện lấy từ scenes/loading.tscn (KHÔNG sinh bằng code)
var _ui_ready := false
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
	_ui_ready = _bind_nodes()
	if not _ui_ready:
		push_error("[SceneTransition] Thieu node giao dien — hay instantiate scenes/loading.tscn thay vi SceneTransition.new()")
	elif not _ink_circle_drawer.draw.is_connected(_on_ink_draw):
		_ink_circle_drawer.draw.connect(_on_ink_draw)
	_reset_all()


## Lấy các node giao diện đã khai báo trong scenes/loading.tscn.
## `false` = scene thieu node (ví dụ ai đó gọi SceneTransition.new() trực tiếp).
func _bind_nodes() -> bool:
	_root_control = get_node_or_null(NODE_TRANSITION_ROOT) as Control
	_blocker = get_node_or_null(NODE_BLOCKER) as Control
	_paper_page = get_node_or_null(NODE_PAPER_PAGE) as Control
	_page_bg = get_node_or_null(NODE_PAPER_BG) as ColorRect
	_page_shadow_left = get_node_or_null(NODE_SHADOW_LEFT) as TextureRect
	_page_shadow_right = get_node_or_null(NODE_SHADOW_RIGHT) as TextureRect
	_watermark = get_node_or_null(NODE_WATERMARK) as TextureRect
	_ink_circle_drawer = get_node_or_null(NODE_INK_DRAWER) as Control
	_fade_rect = get_node_or_null(NODE_FADE_RECT) as ColorRect
	return _blocker != null and _paper_page != null and _ink_circle_drawer != null and _fade_rect != null


## Các node giao diện đã sẵn sàng (scene loading.tscn đã được dùng)
func has_ui() -> bool:
	return _ui_ready


func is_busy() -> bool:
	return _is_busy


## API chuyển cảnh chính: chạy hiệu ứng -> gọi callback đổi scene -> chạy hiệu ứng hé mở
func play_transition(target_path: String, change_callback: Callable, style := "page_turn_forward") -> void:
	if _is_busy:
		push_warning("[SceneTransition] Dang trong qua trinh chuyen canh, bo qua.")
		return

	# Không có node giao diện -> đổi cảnh tức thì (không chặn luồng game/test)
	if not _ui_ready:
		if change_callback.is_valid():
			change_callback.call()
		scene_swapped.emit()
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
	var w := _get_screen_size().x

	_paper_page.visible = true

	# Cấu hình bóng đổ mép trang giấy (bóng nằm sẵn 2 bên trang trong loading.tscn)
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
# Trợ giúp
# ---------------------------------------------------------------------------
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


func _wait_frames(count: int) -> void:
	var tree := get_tree()
	if tree == null:
		return
	for i in count:
		await tree.process_frame
