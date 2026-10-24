class_name SplashScene
extends BaseScene
## ============================================================================
## View Controller: Màn hình Splash (scenes/splash.tscn)
## - Hoạt ảnh xuất hiện logo Mực & Giấy (Ink bloom, nét vẽ bút chì phác thảo).
## - HIỆN TRƯỚC TIÊN khi mở app, hiển thị THANH TIẾN TRÌNH NẠP của `LoadingManager`
##   (nạp bảng dịch/hồ sơ/danh hiệu/event + preload scene chạy nền trong lúc Splash đang hiện).
## - Chỉ chuyển sang Title khi nạp XONG (và đã đủ thời gian tối thiểu để thấy logo + thanh nạp);
##   chạm màn hình thì chuyển sớm ngay khi nạp xong.
## - Chuyển cảnh mượt mà bằng hiệu ứng lật trang sổ tay & fade giấy ngà.
## ============================================================================

const UIAnim := preload("res://scripts/utils/ui_anim.gd")
const SCENE_TITLE := "res://scenes/title.tscn"

## Giữ Splash tối thiểu bao lâu (giây) để người chơi kịp thấy logo + thanh nạp
const MIN_DISPLAY_SEC := 1.2

## Node UI của màn nằm trong BỐ CỤC đang hiển thị (`Portrait` / `Landscape` — 2 hướng dùng
## CÙNG tên node). Các node đã BIND SẴN bằng `@export` trong `scenes/layout/<hướng>/splash.tscn`
## ⇒ code đọc qua `layout.<tên>`, KHÔNG tra đường dẫn; thêm/đổi node chỉ cần sửa scene + export.
var layout: SplashLayout = null

var _pencil_tween: Tween = null
var _transitioning: bool = false
## Nạp nền đã xong chưa (chờ LoadingManager) — chưa xong thì KHÔNG sang màn kế tiếp
var _loading_done := false
## Người chơi đã chạm / hết giờ tự chuyển trong lúc còn đang nạp
var _advance_pending := false
## Mốc thời gian bắt đầu màn Splash (để giữ đủ MIN_DISPLAY_SEC)
var _started_ms := 0


## Ngòi bút chì phác họa quanh logo — animation "pencil_idle" (loop) khai trong layout
## `scenes/layout/<hướng>/splash.tscn` (node `PencilAnim`). Trả về false nếu scene thiếu.
func _play_pencil_idle() -> bool:
	var player := layout.get_node_or_null("PencilAnim") as AnimationPlayer
	if player == null or not player.has_animation(&"pencil_idle"):
		return false
	player.play(&"pencil_idle")
	return true


## Gắn node của layout đang hiển thị (2 layout giữ CÙNG đường dẫn node)
func _bind_refs() -> void:
	layout = active_layout() as SplashLayout
	if layout == null:
		push_warning("splash: bố cục chưa gắn SplashLayout — thiếu binding trong scenes/layout/<hướng>/splash.tscn")


func _ready() -> void:
	_started_ms = Time.get_ticks_msec()
	_bind_refs()
	_refresh_stamp()
	# Dây `pressed → _on_touch_pressed` khai trong `scenes/splash.tscn` (guard chỉ nối lại nếu mất)
	ensure_signal(layout.touch_button, &"pressed", &"_on_touch_pressed")
	_bind_loading()
	_setup_animations()


## Thanh tiến trình nạp: theo dõi `LoadingManager` (xem scripts/manager/LoadingManager.gd).
## Splash hiện ra trước, hoạt ảnh + thanh nạp chạy trong lúc nạp nền;
## nạp xong mới cho phép sang Title.
func _bind_loading() -> void:
	var loading := _loading_manager()
	if loading == null or bool(loading.call("is_loading_done")):
		# Nạp đã xong trước khi Splash kịp hiện (test/headless) ⇒ không có gì để hiện
		_loading_done = true
		_set_loading_progress(1.0)
		_set_loading_box_visible(false)
		return
	if not loading.is_connected("progress_changed", _on_loading_progress):
		loading.connect("progress_changed", _on_loading_progress)
	if not loading.is_connected("loading_finished", _on_loading_finished):
		loading.connect("loading_finished", _on_loading_finished)
	_on_loading_progress(float(loading.call("progress")), "")
	loading.call("start")


func _loading_manager() -> Node:
	return get_node_or_null("/root/LoadingManager")


func _on_loading_progress(value: float, _label: String) -> void:
	_set_loading_progress(value)


## Cập nhật thanh + nhãn tiến trình (0..1)
func _set_loading_progress(value: float) -> void:
	if layout.loading_bar != null:
		layout.loading_bar.value = clampf(value, 0.0, 1.0)
	_update_loading_text(value)


func _on_loading_finished() -> void:
	_loading_done = true
	_set_loading_progress(1.0)
	if _advance_pending:
		_advance_to_title()
		return
	# Chưa ai chạm: giữ Splash đủ lâu để thấy logo + thanh nạp rồi tự sang Title
	await _wait_min_display()
	if not _transitioning and not _advance_pending:
		_advance_to_title()


## Chữ trên thanh nạp: CHỈ hiện chữ đã dịch khi bảng dịch đã nạp xong (bước đầu của
## LoadingManager) — trước đó hiện phần trăm (không phụ thuộc ngôn ngữ) để không lộ khoá thô.
func _update_loading_text(value: float) -> void:
	if layout.loading_label == null:
		return
	var percent := roundi(clampf(value, 0.0, 1.0) * 100.0)
	var loc := get_node_or_null("/root/LocalizationManager")
	var translated := loc != null and bool(loc.call("is_ready"))
	layout.loading_label.text = (tr("STR_LOADING_PROGRESS").format([percent])
		if translated else "%d%%" % percent)


func _set_loading_box_visible(shown: bool) -> void:
	if layout.loading_box != null:
		layout.loading_box.visible = shown


func _wait_min_display() -> void:
	var elapsed := float(Time.get_ticks_msec() - _started_ms) / 1000.0
	var remaining := MIN_DISPLAY_SEC - elapsed
	if remaining <= 0.0:
		return
	await get_tree().create_timer(remaining).timeout


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
		# Đổi scene NGAY trong `_ready` sẽ gọi `root.remove_child()` lúc root đang bận
		# thêm scene ⇒ lỗi "Parent node is busy adding/removing children". Hoãn 1 nhịp.
		_goto_title.call_deferred()
		return

	if layout.anim_player != null and layout.anim_player.has_animation("play_entrance"):
		# Đặt các pivot cơ bản
		if layout.logo_container != null:
			layout.logo_container.pivot_offset = layout.logo_container.size * 0.5
		layout.anim_player.play("play_entrance")
		
		# Ngòi bút chì vẽ phác thảo quanh logo — animation "pencil_idle" (loop) của layout
		if layout.pencil != null:
			layout.pencil.pivot_offset = Vector2(0, layout.pencil.size.y)
			if not _play_pencil_idle():
				# Fallback khi layout thiếu PencilAnim
				_pencil_tween = create_tween().set_loops()
				_pencil_tween.tween_property(layout.pencil, "rotation_degrees", 16.0, 0.38).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				_pencil_tween.tween_property(layout.pencil, "rotation_degrees", -12.0, 0.38).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		# Fallback khi layout thiếu animation "play_entrance"
		# Khởi tạo trạng thái ẩn ban đầu (Fallback)
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
			if not _play_pencil_idle():
				# Fallback khi layout thiếu PencilAnim
				_pencil_tween = create_tween().set_loops()
				_pencil_tween.tween_property(layout.pencil, "rotation_degrees", 16.0, 0.38).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				_pencil_tween.tween_property(layout.pencil, "rotation_degrees", -12.0, 0.38).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		# 4. Tiêu đề và khẩu hiệu xuất hiện
		if layout.title_label != null:
			UIAnim.play_pop_in(layout.title_label, 0.45, 0.88, 0.35)
		if layout.tagline_label != null:
			UIAnim.play_slide_in(layout.tagline_label, Vector2(0, 15), 0.65, 0.3)

	# Tự chuyển cảnh: `_on_loading_finished()` giữ Splash đủ MIN_DISPLAY_SEC rồi sang Title.
	# Timer `AutoAdvanceTimer` (2,2 s) khai trong `scenes/splash.tscn` là lưới an toàn:
	# nạp lâu hơn 2,2 s thì nó đặt `_advance_pending`, chuyển ngay khi nạp xong.


## Người chơi chạm màn hình (hoặc Timer lưới an toàn): chuyển sớm — nhưng vẫn phải chờ nạp xong
func _on_touch_pressed() -> void:
	if _transitioning:
		return
	if not _loading_done:
		_advance_pending = true
		return
	_advance_to_title()


## Chạy hoạt ảnh thoát rồi sang màn Title (chỉ gọi được 1 lần)
func _advance_to_title() -> void:
	if _transitioning:
		return
	_transitioning = true
	if _pencil_tween != null and _pencil_tween.is_valid():
		_pencil_tween.kill()
	var pencil_anim := layout.get_node_or_null("PencilAnim") as AnimationPlayer
	if pencil_anim != null:
		pencil_anim.stop()

	Sfx.play(Sfx.PAGE_TURN)

	if DisplayServer.get_name() == "headless":
		_goto_title()
		return

	# Hiệu ứng chuyển cảnh mượt mà — animation "play_exit" của layout;
	# dây `animation_finished → _on_exit_animation_finished` khai trong `scenes/splash.tscn`
	if layout.anim_player != null and layout.anim_player.has_animation("play_exit"):
		if not layout.anim_player.animation_finished.is_connected(_on_exit_animation_finished):
			# Guard: chỉ nối lại khi dây trong .tscn bị mất (layout đổi cấu trúc)
			layout.anim_player.animation_finished.connect(_on_exit_animation_finished)
		layout.anim_player.play("play_exit")
	else:
		# Fallback khi layout thiếu animation "play_exit"
		if layout.fade_overlay != null:
			layout.fade_overlay.visible = true
			layout.fade_overlay.modulate.a = 0.0
			var tw_out := create_tween()
			tw_out.tween_property(layout.fade_overlay, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw_out.tween_callback(Callable(self, "_goto_title"))
		else:
			_goto_title()


## Hết animation "play_exit" (dây khai trong `scenes/splash.tscn`) → sang màn Tiêu đề
func _on_exit_animation_finished(anim_name: StringName) -> void:
	if anim_name == &"play_exit":
		_goto_title()


func _goto_title() -> void:
	var sm := get_node_or_null("/root/SceneManager")
	if sm != null and sm.has_method("change_scene_instant"):
		sm.call("change_scene_instant", SCENE_TITLE, false)
	else:
		get_tree().change_scene_to_file(SCENE_TITLE)
