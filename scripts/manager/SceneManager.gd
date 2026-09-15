extends Node
## ============================================================================
## Manager: SceneManager - Điều hướng giữa các scene + Animation chuyển cảnh
## phong cách "Sổ tay giấy & Mực" (Page Turn, Ink Bloom) + SFX lật trang.
## - Tự phát sfx_page_turn khi chuyển màn (đúng chất sổ tay giấy).
## - Ghi lịch sử vào ScreenManager để phục vụ nút Back trên Android.
## - Lớp phủ SceneTransition độc lập trên CanvasLayer chặn input khi đang đổi scene.
## ============================================================================

signal scene_changing(path: String, previous_path: String)
signal scene_changed(path: String)

const SCENE_MAIN := "res://scenes/main.tscn"
const SCENE_LEVELS := "res://scenes/levels.tscn"
const SCENE_GAME := "res://scenes/game.tscn"
const SCENE_DAILY := "res://scenes/daily.tscn"
const SCENE_SETTINGS := "res://scenes/settings.tscn"
const SCENE_DEBUG := "res://scenes/debug.tscn"
## Sổ tay thành tựu (danh hiệu) — xem scripts/scenes/archivement.gd
const SCENE_ARCHIVEMENT := "res://scenes/archivement.tscn"
## Bảng xếp hạng — xem scripts/scenes/ranking.gd
const SCENE_RANKING := "res://scenes/ranking.tscn"
## Màn CHỌN CHƯƠNG — xem scripts/scenes/chapters.gd
const SCENE_CHAPTERS := "res://scenes/chapters.tscn"
## Lớp phủ chuyển cảnh: node giao diện (trang giấy, mực loang, fade, chặn input)
## được khai báo SẴN trong scene này — xem scripts/nodes/common/scene_transition.gd
const SCENE_LOADING := "res://scenes/loading.tscn"
const LoadingScene := preload("res://scenes/loading.tscn")

var transition: CanvasLayer = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_init_transition()


func _init_transition() -> void:
	if transition != null:
		return
	transition = LoadingScene.instantiate() as CanvasLayer
	if transition == null:
		push_error("[SceneManager] Khong tao duoc %s" % SCENE_LOADING)
		return
	transition.name = "Loading"
	add_child(transition)


# ---------------------------------------------------------------------------
# API chính
# ---------------------------------------------------------------------------
func change_scene(path: String, record_history := true, style := "auto") -> void:
	if path.is_empty() or not ResourceLoader.exists(path):
		push_warning("[SceneManager] Scene không tồn tại: %s" % path)
		return

	if transition != null and transition.has_method("is_busy") and bool(transition.call("is_busy")):
		push_warning("[SceneManager] Đang có chuyển cảnh đang diễn ra, bỏ qua yêu cầu mới.")
		return

	var previous := current_scene_path()
	if record_history and not previous.is_empty() and previous != path:
		var screen: Variant = get_node_or_null("/root/ScreenManager")
		if screen != null and screen.has_method("push_history"):
			screen.call("push_history", previous)

	# Tự động xác định hiệu ứng nếu chọn "auto"
	var resolved_style := style
	if resolved_style == "auto":
		if not record_history:
			resolved_style = "page_turn_backward"
		elif path == SCENE_GAME:
			resolved_style = "ink_circle"
		else:
			resolved_style = "page_turn_forward"

	_play_transition_sfx(resolved_style)
	scene_changing.emit(path, previous)

	# Nếu chạy trong môi trường headless/test không cần frame render hoặc transition bị tắt
	var is_headless := DisplayServer.get_name() == "headless"
	if is_headless or transition == null or resolved_style == "none":
		get_tree().change_scene_to_file(path)
		scene_changed.emit(path)
		return

	# Chạy hiệu ứng mượt mà qua SceneTransition
	transition.call(
		"play_transition",
		path,
		func() -> void:
			get_tree().change_scene_to_file(path)
			scene_changed.emit(path),
		resolved_style
	)


## Đổi scene tức thì không cần hiệu ứng (dành cho test hoặc reset nhanh)
func change_scene_instant(path: String, record_history := true) -> void:
	change_scene(path, record_history, "none")


func is_transitioning() -> bool:
	return transition != null and transition.has_method("is_busy") and bool(transition.call("is_busy"))


func current_scene_path() -> String:
	var scene := get_tree().current_scene
	return scene.scene_file_path if scene != null else ""


func reload_current_scene() -> void:
	var path := current_scene_path()
	if not path.is_empty():
		change_scene(path, false)


# ---------------------------------------------------------------------------
# Lối tắt cho từng màn
# ---------------------------------------------------------------------------
func goto_main() -> void:
	change_scene(SCENE_MAIN)


func goto_levels() -> void:
	change_scene(SCENE_LEVELS)


func goto_game() -> void:
	change_scene(SCENE_GAME)


func goto_daily() -> void:
	change_scene(SCENE_DAILY)


func goto_settings() -> void:
	change_scene(SCENE_SETTINGS)


func goto_archivement() -> void:
	change_scene(SCENE_ARCHIVEMENT)


func goto_ranking() -> void:
	change_scene(SCENE_RANKING)


func goto_chapters() -> void:
	change_scene(SCENE_CHAPTERS)


func goto_debug() -> void:
	change_scene(SCENE_DEBUG)


func is_debug_scene() -> bool:
	return current_scene_path() == SCENE_DEBUG


func _play_transition_sfx(style: String) -> void:
	if style == "ink_circle":
		Sfx.play(Sfx.BTN_CLICK)
	else:
		Sfx.play(Sfx.PAGE_TURN)
