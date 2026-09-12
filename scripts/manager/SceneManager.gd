extends Node
## ============================================================================
## Manager: SceneManager - Điều hướng giữa các scene + SFX "lật trang".
## - Tự phát sfx_page_turn khi chuyển màn (đúng chất sổ tay giấy).
## - Ghi lịch sử vào ScreenManager để phục vụ nút Back trên Android.
## ============================================================================

signal scene_changing(path: String, previous_path: String)

const SCENE_MAIN := "res://scenes/main.tscn"
const SCENE_LEVELS := "res://scenes/levels.tscn"
const SCENE_GAME := "res://scenes/game.tscn"
const SCENE_DAILY := "res://scenes/daily.tscn"
const SCENE_SETTINGS := "res://scenes/settings.tscn"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


# ---------------------------------------------------------------------------
# API chính
# ---------------------------------------------------------------------------
func change_scene(path: String, record_history := true) -> void:
	if path.is_empty() or not ResourceLoader.exists(path):
		push_warning("[SceneManager] Scene không tồn tại: %s" % path)
		return

	var previous := current_scene_path()
	if record_history and not previous.is_empty() and previous != path:
		var screen: Variant = get_node_or_null("/root/ScreenManager")
		if screen != null and screen.has_method("push_history"):
			screen.call("push_history", previous)

	_play_page_turn()
	scene_changing.emit(path, previous)
	get_tree().change_scene_to_file(path)


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


func _play_page_turn() -> void:
	Sfx.play(Sfx.PAGE_TURN)
