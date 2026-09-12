extends Node
## ============================================================================
## Manager: SettingManager - Cài đặt người chơi (âm lượng, rung, ngôn ngữ).
## - Lưu bền tại: user://settings.cfg
## - Volume "master" được áp trực tiếp lên bus Master của AudioServer;
##   SfxManager tự nhân thêm volume riêng của kênh "sfx".
## ============================================================================

signal setting_changed(key: String, value: Variant)
signal volume_changed(kind: String, value: float)

const CONFIG_PATH := "user://settings.cfg"
const SECTION_AUDIO := "audio"
const SECTION_GAME := "game"
const SECTION_LOCALE := "locale"

var master_volume := 1.0
var sfx_volume := 1.0
var music_volume := 0.8
var vibration := true
var locale := "vi"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	apply_master_volume()


# ---------------------------------------------------------------------------
# API chung
# ---------------------------------------------------------------------------
func get_setting(key: String, default_value: Variant = null) -> Variant:
	if key in self:
		return get(key)
	return default_value


func set_setting(key: String, value: Variant, autosave := true) -> void:
	if not (key in self):
		push_warning("[SettingManager] Không có setting tên '%s'" % key)
		return
	set(key, value)
	setting_changed.emit(key, value)
	if key.ends_with("_volume"):
		apply_master_volume()
		volume_changed.emit(key.trim_suffix("_volume"), float(value))
	if autosave:
		save()


func set_volume(kind: String, value: float) -> void:
	var v := clampf(value, 0.0, 1.0)
	match kind:
		"master":
			master_volume = v
			apply_master_volume()
		"sfx":
			sfx_volume = v
		"music":
			music_volume = v
		_:
			push_warning("[SettingManager] Kênh âm lượng không hợp lệ: %s" % kind)
			return
	setting_changed.emit(kind + "_volume", v)
	volume_changed.emit(kind, v)
	save()


func get_volume(kind: String) -> float:
	match kind:
		"master":
			return master_volume
		"sfx":
			return sfx_volume
		"music":
			return music_volume
	return 1.0


## Bus Master (index 0) nhận đúng volume "master" từ cài đặt
func apply_master_volume() -> void:
	AudioServer.set_bus_mute(0, master_volume <= 0.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(master_volume, 0.0001)))


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION_AUDIO, "master_volume", master_volume)
	cfg.set_value(SECTION_AUDIO, "sfx_volume", sfx_volume)
	cfg.set_value(SECTION_AUDIO, "music_volume", music_volume)
	cfg.set_value(SECTION_GAME, "vibration", vibration)
	cfg.set_value(SECTION_LOCALE, "locale", locale)
	var err := cfg.save(CONFIG_PATH)
	if err != OK:
		push_warning("[SettingManager] Không lưu được %s (mã lỗi %d)" % [CONFIG_PATH, err])


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return
	master_volume = float(cfg.get_value(SECTION_AUDIO, "master_volume", master_volume))
	sfx_volume = float(cfg.get_value(SECTION_AUDIO, "sfx_volume", sfx_volume))
	music_volume = float(cfg.get_value(SECTION_AUDIO, "music_volume", music_volume))
	vibration = bool(cfg.get_value(SECTION_GAME, "vibration", vibration))
	locale = str(cfg.get_value(SECTION_LOCALE, "locale", locale))
