extends Node
## ============================================================================
## Manager: MusicManager - Phát soundtrack nền theo chủ đề đang dùng.
##
## Mục tiêu:
## - Dùng 1 AudioStreamPlayer toàn cục cho BGM (không bị reset khi đổi scene).
## - Đồng bộ âm lượng với SettingManager.music_volume.
## - Áp profile theo theme (Shop/ThemeManager) + theo context scene
##   (menu/gameplay/credits) để soundtrack có "chất" riêng.
## ============================================================================

signal soundtrack_changed(track_path: String, theme_id: String, context_name: String)

const DEFAULT_SOUNDTRACK := "res://assets/soundtrack/Wallpaper.mp3"
const DEFAULT_THEME := "theme_gride_4ly"

const SCENE_GAME := "res://scenes/game.tscn"
const SCENE_DAILY := "res://scenes/daily.tscn"
const SCENE_CREDIT := "res://scenes/credit.tscn"

const CONTEXT_PROFILE := {
	"menu": {"pitch": 1.0, "gain_db": 0.0},
	"gameplay": {"pitch": 1.03, "gain_db": -1.25},
	"credits": {"pitch": 0.95, "gain_db": 0.8},
}

const THEME_PROFILE := {
	"theme_gride_4ly": {"pitch": 1.0, "gain_db": 0.0},
	"theme_blackboard": {"pitch": 0.9, "gain_db": -2.2},
	"theme_campus": {"pitch": 1.02, "gain_db": 0.2},
	"theme_bullet": {"pitch": 1.01, "gain_db": 0.1},
	"theme_tech_grid": {"pitch": 1.06, "gain_db": -0.4},
	"theme_kraft": {"pitch": 0.96, "gain_db": 0.6},
	"theme_pastel_caro": {"pitch": 1.08, "gain_db": 0.8},
	"theme_exam": {"pitch": 1.02, "gain_db": -0.2},
}

var _player: AudioStreamPlayer = null
var _music_gain := 0.8
var _theme_id := DEFAULT_THEME
var _context_name := "menu"
var _track_path := ""
var _warned: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_player()
	_bind_setting_manager()
	_bind_theme_manager()
	_bind_scene_manager()
	call_deferred("_refresh_runtime_state")


# ---------------------------------------------------------------------------
# API cho scene/UI
# ---------------------------------------------------------------------------
func set_context(context_name: String, restart := false) -> void:
	var next_context := context_name if CONTEXT_PROFILE.has(context_name) else "menu"
	var changed := next_context != _context_name
	_context_name = next_context
	if changed or restart:
		_refresh_soundtrack(restart)
	else:
		_apply_mix()


func context_name() -> String:
	return _context_name


func current_theme_id() -> String:
	return _theme_id


func current_track_path() -> String:
	return _track_path


func current_track_name() -> String:
	return _track_path.get_file().get_basename() if not _track_path.is_empty() else ""


# ---------------------------------------------------------------------------
# Runtime wiring
# ---------------------------------------------------------------------------
func _refresh_runtime_state() -> void:
	_bind_setting_manager()
	_bind_theme_manager()
	_bind_scene_manager()
	_theme_id = _detect_theme_id()
	_music_gain = _read_music_gain()
	_context_name = _scene_to_context(_current_scene_path())
	_refresh_soundtrack(false)


func _bind_setting_manager() -> void:
	var settings: Variant = get_node_or_null("/root/SettingManager")
	if settings == null or not settings.has_signal("volume_changed"):
		return
	var cb := Callable(self, "_on_volume_changed")
	if not settings.is_connected("volume_changed", cb):
		settings.connect("volume_changed", cb)


func _bind_theme_manager() -> void:
	var themes: Variant = get_node_or_null("/root/ThemeManager")
	if themes == null or not themes.has_signal("skin_changed"):
		return
	var cb := Callable(self, "_on_skin_changed")
	if not themes.is_connected("skin_changed", cb):
		themes.connect("skin_changed", cb)


func _bind_scene_manager() -> void:
	var scenes: Variant = get_node_or_null("/root/SceneManager")
	if scenes == null or not scenes.has_signal("scene_changed"):
		return
	var cb := Callable(self, "_on_scene_changed")
	if not scenes.is_connected("scene_changed", cb):
		scenes.connect("scene_changed", cb)


func _ensure_player() -> void:
	if _player != null and is_instance_valid(_player):
		return
	_player = AudioStreamPlayer.new()
	_player.name = "BgmPlayer"
	_player.bus = "Master"
	_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_player)


# ---------------------------------------------------------------------------
# Soundtrack profile
# ---------------------------------------------------------------------------
func _refresh_soundtrack(restart: bool) -> void:
	if _player == null:
		return
	var next_track := _resolve_track_path()
	var stream_changed := _player.stream == null or next_track != _track_path

	if stream_changed:
		var stream := _load_loop_stream(next_track)
		if stream == null:
			return
		_player.stream = stream
		_track_path = next_track
		restart = true

	if restart and _player.stream != null:
		_player.play(0.0)
		soundtrack_changed.emit(_track_path, _theme_id, _context_name)
	elif _player.stream != null and not _player.playing and _music_gain > 0.0:
		_player.play()

	_apply_mix()


func _resolve_track_path() -> String:
	if _context_name == "credits":
		return DEFAULT_SOUNDTRACK
	var shop: Variant = get_node_or_null("/root/ShopManager")
	if shop != null and shop.has_method("item"):
		var data: Variant = shop.call("item", _theme_id)
		if data is Dictionary and data.has("soundtrack"):
			var custom_path := str(data.get("soundtrack", ""))
			if not custom_path.is_empty() and ResourceLoader.exists(custom_path):
				return custom_path
	return DEFAULT_SOUNDTRACK


func _load_loop_stream(path: String) -> AudioStream:
	if path.is_empty() or not ResourceLoader.exists(path):
		_warn_once("missing_" + path, "[MusicManager] Thiếu soundtrack: %s" % path)
		return null
	var stream := load(path) as AudioStream
	if stream == null:
		_warn_once("load_" + path, "[MusicManager] Không load được soundtrack: %s" % path)
		return null
	var looped: AudioStream = stream.duplicate()
	if looped is AudioStreamWAV:
		(looped as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif looped is AudioStreamMP3:
		(looped as AudioStreamMP3).loop = true
	elif looped is AudioStreamOggVorbis:
		(looped as AudioStreamOggVorbis).loop = true
	return looped


func _apply_mix() -> void:
	if _player == null:
		return
	var context_mix: Dictionary = CONTEXT_PROFILE.get(_context_name, CONTEXT_PROFILE["menu"])
	var theme_mix: Dictionary = THEME_PROFILE.get(_theme_id, {})
	var pitch := float(context_mix.get("pitch", 1.0)) * float(theme_mix.get("pitch", 1.0))
	var extra_db := float(context_mix.get("gain_db", 0.0)) + float(theme_mix.get("gain_db", 0.0))
	var base_db := -80.0 if _music_gain <= 0.0 else linear_to_db(maxf(_music_gain, 0.0001))
	_player.pitch_scale = clampf(pitch, 0.7, 1.4)
	_player.volume_db = clampf(base_db + extra_db, -80.0, 6.0)
	_player.stream_paused = _music_gain <= 0.0
	if _music_gain > 0.0 and _player.stream != null and not _player.playing:
		_player.play()


# ---------------------------------------------------------------------------
# Nguồn dữ liệu
# ---------------------------------------------------------------------------
func _read_music_gain() -> float:
	var settings: Variant = get_node_or_null("/root/SettingManager")
	if settings == null:
		return _music_gain
	return clampf(float(settings.get("music_volume")), 0.0, 1.0)


func _detect_theme_id() -> String:
	var themes: Variant = get_node_or_null("/root/ThemeManager")
	if themes != null and themes.has_method("theme_id"):
		var selected := str(themes.call("theme_id"))
		if not selected.is_empty():
			return selected
	var shop: Variant = get_node_or_null("/root/ShopManager")
	if shop != null:
		var fallback := str(shop.get("equipped_theme"))
		if not fallback.is_empty():
			return fallback
	return DEFAULT_THEME


func _current_scene_path() -> String:
	var scene_manager: Variant = get_node_or_null("/root/SceneManager")
	if scene_manager != null and scene_manager.has_method("current_scene_path"):
		return str(scene_manager.call("current_scene_path"))
	var scene := get_tree().current_scene
	return scene.scene_file_path if scene != null else ""


func _scene_to_context(path: String) -> String:
	if path == SCENE_GAME or path == SCENE_DAILY:
		return "gameplay"
	if path == SCENE_CREDIT:
		return "credits"
	return "menu"


# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
func _on_volume_changed(kind: String, value: float) -> void:
	if kind != "music":
		return
	_music_gain = clampf(value, 0.0, 1.0)
	_apply_mix()


func _on_skin_changed(theme_id: String, _pen_id: String) -> void:
	_theme_id = theme_id if not theme_id.is_empty() else DEFAULT_THEME
	_refresh_soundtrack(false)


func _on_scene_changed(path: String) -> void:
	var context := _scene_to_context(path)
	set_context(context, context == "credits")


func _warn_once(key: String, message: String) -> void:
	if _warned.has(key):
		return
	_warned[key] = true
	push_warning(message)
