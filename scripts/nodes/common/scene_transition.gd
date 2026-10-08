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

@export var color_ink := Color(0.133, 0.298, 0.427, 1.0)      # Lam mực đậm InkMaze

@export_group("Thời lượng hiệu ứng (giây)")
@export_range(0.05, 1.5, 0.01) var duration_page_in := 0.22
@export_range(0.05, 1.5, 0.01) var duration_page_out := 0.22
@export_range(0.05, 1.5, 0.01) var duration_ink := 0.24
@export_range(0.05, 1.5, 0.01) var duration_fade := 0.18

var _is_busy := false

## Node giao diện KHAI SẴN trong scenes/loading.tscn — bind trong CHÍNH scene đó
## (KHÔNG sinh bằng code; `SceneTransition.new()` trần thì các export này null).
## Node binding: khai `node_paths` + NodePath trong `scenes/loading.tscn`
var _ui_ready := false
@export var transition_root: Control = null
@export var blocker: Control = null
@export var paper_page: Control = null
@export var page_bg: ColorRect = null
@export var page_shadow_left: TextureRect = null
@export var page_shadow_right: TextureRect = null
@export var watermark: TextureRect = null
@export var ink_circle_drawer: Control = null
@export var fade_rect: ColorRect = null

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
	# Dây `InkCircleDrawer.draw → _on_ink_draw` khai trong scenes/loading.tscn (cùng scene)
	_reset_all()


## Kiểm tra các node giao diện đã khai báo trong scenes/loading.tscn (bind trong scene).
## `false` = scene thieu node (ví dụ ai đó gọi SceneTransition.new() trực tiếp).
func _bind_nodes() -> bool:
	return blocker != null and paper_page != null and ink_circle_drawer != null and fade_rect != null


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
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
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
	blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_is_busy = false
	transition_finished.emit(style)


# ---------------------------------------------------------------------------
# Các hiệu ứng chuyển cảnh
# ---------------------------------------------------------------------------

## Hiệu ứng lật trang sổ tay
## (GIỮ tween) Toạ độ trang giấy tính theo BỀ RỘNG MÀN HÌNH lúc chạy (start/end = ±w) nên
## không thể bake thành track tĩnh; node/hình dáng đã khai sẵn trong `scenes/loading.tscn`.
func _run_page_turn(target_path: String, change_callback: Callable, forward: bool) -> void:
	var w := _get_screen_size().x

	paper_page.visible = true

	# Cấu hình bóng đổ mép trang giấy (bóng nằm sẵn 2 bên trang trong loading.tscn)
	page_shadow_left.visible = forward
	page_shadow_right.visible = not forward

	var start_x: float = w if forward else -w
	var end_x: float = -w if forward else w

	paper_page.position = Vector2(start_x, 0.0)

	# Phase 1: Trang giấy lướt vào che kín màn hình
	var tw_in := create_tween()
	tw_in.tween_property(paper_page, "position:x", 0.0, duration_page_in).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tw_in.finished

	# Phase 2: Thực hiện đổi scene
	if change_callback.is_valid():
		change_callback.call()
	scene_swapped.emit()
	await _wait_frames(2)

	# Phase 3: Trang giấy lướt tiếp ra ngoài để hé mở scene mới
	var tw_out := create_tween()
	tw_out.tween_property(paper_page, "position:x", end_x, duration_page_out).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tw_out.finished


## Hiệu ứng vết mực tròn loang ra (Ink Circle Bloom)
## (GIỮ tween) Bán kính mực = ĐƯỜNG CHÉO màn hình lúc chạy; vệt mực vẽ bằng `_draw()
## theo biến `_ink_radius` (không phải thuộc tính node) nên không có track để khai.
func _run_ink_circle(target_path: String, change_callback: Callable) -> void:
	var vp_size := _get_screen_size()
	_ink_max_radius = vp_size.length() * 0.65
	ink_circle_drawer.visible = true
	ink_circle_drawer.modulate.a = 1.0
	_ink_radius = 0.0

	# Phase 1: Mực loang từ tâm che phủ màn hình
	var tw_in := create_tween()
	tw_in.tween_method(_set_ink_radius, 0.0, _ink_max_radius, duration_ink).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw_in.finished

	# Phase 2: Đổi scene
	if change_callback.is_valid():
		change_callback.call()
	scene_swapped.emit()
	await _wait_frames(2)

	# Phase 3: Mực tan biến mờ dần hé lộ màn chơi
	var tw_out := create_tween()
	tw_out.set_parallel(true)
	tw_out.tween_property(ink_circle_drawer, "modulate:a", 0.0, duration_page_out).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw_out.tween_method(_set_ink_radius, _ink_max_radius, _ink_max_radius * 1.3, duration_page_out).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw_out.finished


## Hiệu ứng mờ dần (Paper Fade)
## (GIỮ tween) Đây là hiệu ứng ĐIỀU NHỊP: đổi scene nằm GIỮA 2 chặng (mờ vào → đổi → mờ ra),
## code phải `await` đúng nhịp nên giữ tween thay vì tách animation rời.
func _run_paper_fade(target_path: String, change_callback: Callable) -> void:
	fade_rect.visible = true
	fade_rect.modulate.a = 0.0

	var tw_in := create_tween()
	tw_in.tween_property(fade_rect, "modulate:a", 1.0, duration_fade).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw_in.finished

	if change_callback.is_valid():
		change_callback.call()
	scene_swapped.emit()
	await _wait_frames(2)

	var tw_out := create_tween()
	tw_out.tween_property(fade_rect, "modulate:a", 0.0, duration_fade).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw_out.finished


# ---------------------------------------------------------------------------
# Trợ giúp
# ---------------------------------------------------------------------------
func _reset_all() -> void:
	if paper_page != null:
		paper_page.visible = false
	if ink_circle_drawer != null:
		ink_circle_drawer.visible = false
		_ink_radius = 0.0
	if fade_rect != null:
		fade_rect.visible = false
	if blocker != null:
		blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _set_ink_radius(r: float) -> void:
	_ink_radius = r
	if ink_circle_drawer != null:
		ink_circle_drawer.queue_redraw()


func _on_ink_draw() -> void:
	if _ink_radius <= 0.0 or not ink_circle_drawer.visible:
		return
	var center := _get_screen_size() * 0.5
	ink_circle_drawer.draw_circle(center, _ink_radius, color_ink)


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
