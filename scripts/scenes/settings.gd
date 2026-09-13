class_name SettingsScene
extends BaseScene
## ============================================================================
## View Controller: Màn hình Cài đặt (Settings)
## Bám theo mockup mockup/settings_screen.svg:
##   1. Âm thanh        : slider Nhạc nền (BGM) + Hiệu ứng (SFX)
##   2. Bàn cờ          : 3 tuỳ chọn bật/tắt (Haptic, auto-mark, glow path)
##   3. Ngôn ngữ & lưu trữ: dropdown chọn ngôn ngữ (mở popup), chip cloud, player ID
##   4. Hỗ trợ          : xem hướng dẫn, khôi phục cài đặt mặc định
##   5. Chân trang      : câu quote + con dấu phiên bản
## Cài đặt lưu qua SettingManager (/root) nên không tham chiếu autoload trực tiếp.
## ============================================================================

signal guide_requested

const PLAYER_ID_PLACEHOLDER := "#NM-8924-VN"

@onready var btn_back: TextureButton = $TopBar/Back
@onready var bgm_slider: HSlider = $Panel/Content/Audio/BgmRow/Slider
@onready var bgm_value: Label = $Panel/Content/Audio/BgmRow/Value
@onready var sfx_slider: HSlider = $Panel/Content/Audio/SfxRow/Slider
@onready var sfx_value: Label = $Panel/Content/Audio/SfxRow/Value
@onready var chk_haptic: TextureButton = $Panel/Content/Board/HapticRow/Check
@onready var chk_auto_mark: TextureButton = $Panel/Content/Board/AutoMarkRow/Check
@onready var chk_glow: TextureButton = $Panel/Content/Board/GlowRow/Check
@onready var btn_language: TextureButton = $Panel/Content/Language/LangRow/LangButton
@onready var lbl_language: Label = $Panel/Content/Language/LangRow/LangButton/LangValue
@onready var lbl_player_id: Label = $Panel/Content/Language/PlayerRow/PlayerIdValue
@onready var btn_guide: TextureButton = $Panel/Content/Actions/Guide
@onready var btn_reset: TextureButton = $Panel/Content/Actions/Reset
@onready var lbl_version: Label = $Panel/Content/Footer/Stamp/Label

## Chặn ghi ngược khi đang đồng bộ UI từ SettingManager
var _syncing := false


func _ready() -> void:
	if btn_back != null:
		btn_back.pressed.connect(_on_back_pressed)

	if bgm_slider != null:
		bgm_slider.value_changed.connect(_on_volume_changed.bind("music", bgm_value))
	if sfx_slider != null:
		sfx_slider.value_changed.connect(_on_volume_changed.bind("sfx", sfx_value))

	# TextureButton toggle: toggled(toggled_on) + bind khoá cài đặt tương ứng
	for pair in [
		[chk_haptic, "vibration"],
		[chk_auto_mark, "auto_mark_safe"],
		[chk_glow, "glow_path"],
	]:
		var check: TextureButton = pair[0]
		if check != null:
			check.toggled.connect(_on_toggle_changed.bind(str(pair[1])))

	if btn_language != null:
		btn_language.pressed.connect(_on_language_pressed)
	if btn_guide != null:
		btn_guide.pressed.connect(_on_guide_pressed)
	if btn_reset != null:
		btn_reset.pressed.connect(_on_reset_pressed)

	_sync_from_settings()


# ---------------------------------------------------------------------------
# Đồng bộ UI <-> SettingManager
# ---------------------------------------------------------------------------
func _sm() -> Node:
	return get_node_or_null("/root/SettingManager")


func _sync_from_settings() -> void:
	_syncing = true
	var sm := _sm()
	if sm != null:
		if bgm_slider != null:
			bgm_slider.value = float(sm.get("music_volume"))
		if sfx_slider != null:
			sfx_slider.value = float(sm.get("sfx_volume"))
		if chk_haptic != null:
			chk_haptic.button_pressed = bool(sm.get("vibration"))
		if chk_auto_mark != null:
			chk_auto_mark.button_pressed = bool(sm.get("auto_mark_safe"))
		if chk_glow != null:
			chk_glow.button_pressed = bool(sm.get("glow_path"))
	_update_volume_labels()
	_refresh_language()
	_refresh_version()
	_syncing = false


func _update_volume_labels() -> void:
	if bgm_value != null and bgm_slider != null:
		bgm_value.text = _to_percent(bgm_slider.value)
	if sfx_value != null and sfx_slider != null:
		sfx_value.text = _to_percent(sfx_slider.value)


func _to_percent(value: float) -> String:
	return "%d%%" % roundi(value * 100.0)


func _refresh_language() -> void:
	if lbl_language != null:
		lbl_language.text = Loc.display_name(Loc.current())


func _refresh_version() -> void:
	if lbl_version != null:
		var app := get_node_or_null("/root/AppManager")
		var version := "1.0.0"
		if app != null:
			version = str(app.call("get_version"))
		lbl_version.text = tr("STR_SETTINGS_VERSION").format([version])
	if lbl_player_id != null:
		lbl_player_id.text = PLAYER_ID_PLACEHOLDER


# ---------------------------------------------------------------------------
# Âm thanh
# ---------------------------------------------------------------------------
func _on_volume_changed(value: float, kind: String, label: Label) -> void:
	_update_volume_labels()
	if _syncing:
		return
	var sm := _sm()
	if sm != null:
		sm.call("set_volume", kind, value)
	if label != null:
		label.text = _to_percent(value)
	# SFX: tiếng thước kẻ trượt khi kéo thanh âm lượng
	Sfx.play(Sfx.SLIDER_TICK)


# ---------------------------------------------------------------------------
# Tuỳ chọn bật/tắt
# ---------------------------------------------------------------------------
func _on_toggle_changed(toggled_on: bool, key: String) -> void:
	if _syncing:
		return
	var sm := _sm()
	if sm != null:
		sm.call("set_setting", key, toggled_on)
	# SFX: tiếng bút bi vẽ dấu tích
	Sfx.play(Sfx.CHECKBOX)


# ---------------------------------------------------------------------------
# Ngôn ngữ
# ---------------------------------------------------------------------------
func _on_language_pressed() -> void:
	Sfx.play(Sfx.BTN_WOOD_TAP)
	# Popup được PopupManager tạo khi mở và xoá khi đóng
	var popup := Popups.open(Popups.LANGUAGE)
	if popup == null:
		return
	if not popup.is_connected("locale_applied", _on_locale_applied):
		popup.connect("locale_applied", _on_locale_applied)


func _on_locale_applied(_code: String) -> void:
	_refresh_language()


# ---------------------------------------------------------------------------
# Hỗ trợ & khôi phục mặc định
# ---------------------------------------------------------------------------
func _on_guide_pressed() -> void:
	Sfx.play(Sfx.BTN_WOOD_TAP)
	# TODO: mở màn "Hướng dẫn & 9 bộ luật chơi" khi có scene tương ứng
	push_warning("[Settings] Chưa có scene hướng dẫn - cần bổ sung sau.")
	guide_requested.emit()


func _on_reset_pressed() -> void:
	var sm := _sm()
	if sm != null:
		sm.call("reset_to_defaults")
	# SFX: tiếng "cộp" con dấu khi khôi phục mặc định
	Sfx.play(Sfx.STAMP_IMPACT)
	_sync_from_settings()


# ---------------------------------------------------------------------------
# Điều hướng
# ---------------------------------------------------------------------------
func _on_back_pressed() -> void:
	Sfx.play(Sfx.BTN_WOOD_TAP)
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("go_to_main_menu"):
		gm.call("go_to_main_menu")
	else:
		Nav.goto_main()
